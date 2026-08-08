from __future__ import division

"""calc_PSD

Provide a function to extract signals from a VCD file produced by the simulation
and compute a simple PSD of the output signal sampled on rising clock edges.

Function:
  calc_psd_from_vcd(vcd_path, clk_name=None, in_name=None, out_name=None)

Returns a dict with keys: `t`, `u`, `v`, `f`, `spec_db`.

- `t`: array of times at rising clock edges (integer time units from VCD)
- `u`: input values converted to fractional range [-1, 1]
- `v`: output values (numeric)
- `f`: normalized frequency array for PSD (0..0.5)
- `spec_db`: PSD magnitude in dB (20*log10)

The function attempts to auto-detect signal names if `clk_name`, `in_name`,
or `out_name` are omitted (matching common suffixes `clock`, `clk`, `in`, `out`).
"""

import math
import numpy as np
from typing import Optional, Dict, Any


def _binstr_to_signed_int(binstr: str, width: int) -> int:
	if binstr == 'z' or binstr == 'x':
		return 0
	val = int(binstr, 2)
	if width > 0 and (val & (1 << (width - 1))):
		val -= (1 << width)
	return val


def _select_signal(varmap, prefer_suffixes):
	# varmap: id -> {'name': fullname, 'size': int}
	# prefer_suffixes: list of suffix strings to match
	for suf in prefer_suffixes:
		for vid, info in varmap.items():
			name = info['name']
			if name.endswith('.' + suf) or name.endswith('/' + suf) or name == suf or name.endswith(suf):
				return vid, info
	return None, None


def calc_psd_from_vcd(vcd_path: str,
					  clk_name: Optional[str] = None,
					  in_name: Optional[str] = None,
					  out_name: Optional[str] = None) -> Dict[str, Any]:
	"""Parse `vcd_path` and return sampled signals and PSD.

	`clk_name`, `in_name`, `out_name` may be provided to disambiguate signals.
	"""

	# Read file and parse header to map ids to variable names and sizes
	varmap = {}  # id -> {name, size}
	with open(vcd_path, 'r') as f:
		in_header = True
		for line in f:
			line = line.strip()
			if in_header:
				if line.startswith('$var'):
					# $var <type> <size> <id> <reference> $end
					parts = line.split()
					if len(parts) >= 5:
						size = int(parts[2])
						vid = parts[3]
						# reference may contain spaces; join until $end
						ref = ' '.join(parts[4:])
						if ref.endswith(' $end'):
							ref = ref[:-5].strip()
						varmap[vid] = {'name': ref, 'size': size}
				elif line.startswith('$enddefinitions'):
					in_header = False
					break

	# Auto-select ids if names not provided
	clk_id = None
	in_id = None
	out_id = None
	if clk_name:
		for vid, info in varmap.items():
			if info['name'].endswith(clk_name):
				clk_id = vid
				break
	if in_name:
		for vid, info in varmap.items():
			if info['name'].endswith(in_name):
				in_id = vid
				break
	if out_name:
		for vid, info in varmap.items():
			if info['name'].endswith(out_name):
				out_id = vid
				break

	# fallback heuristics
	def _clean(name):
		# remove array/index parts and make lowercase
		return name.split('[')[0].strip().lower()

	if clk_id is None:
		for vid, info in varmap.items():
			cn = _clean(info['name'])
			if 'clock' in cn or cn.endswith('clk'):
				clk_id = vid
				break
	if in_id is None:
		for vid, info in varmap.items():
			cn = _clean(info['name'])
			if cn == 'in' or cn.endswith('in') or 'input' in cn or cn.startswith('in '):
				in_id = vid
				in_info = info
				break
	else:
		in_info = varmap.get(in_id)
	if out_id is None:
		for vid, info in varmap.items():
			cn = _clean(info['name'])
			if cn == 'out' or cn.endswith('out') or 'output' in cn or cn.startswith('out '):
				out_id = vid
				out_info = info
				break
	else:
		out_info = varmap.get(out_id)

	if clk_id is None or in_id is None or out_id is None:
		raise ValueError('Could not auto-detect required signals in VCD. Provide names.')

	# Prepare event lists
	events = {clk_id: [], in_id: [], out_id: []}  # list of (time, int_value)
	last_vals = {clk_id: '0', in_id: None, out_id: None}

	with open(vcd_path, 'r') as f:
		current_time = 0
		in_header = True
		for line in f:
			line = line.strip()
			if in_header:
				if line.startswith('$enddefinitions'):
					in_header = False
				continue
			if not line:
				continue
			if line.startswith('#'):
				current_time = int(line[1:])
				continue
			# vector change: b1010 id
			if line.startswith('b'):
				tokens = line.split()
				if len(tokens) >= 2:
					binstr = tokens[0][1:]
					vid = tokens[1]
					if vid in events:
						width = varmap[vid]['size']
						val = _binstr_to_signed_int(binstr, width)
						events[vid].append((current_time, val))
						last_vals[vid] = binstr
				continue
			# single bit change: 1a or 0a
			if (line[0] in ('0', '1')) and len(line) >= 2:
				valch = line[0]
				vid = line[1:]
				if vid in events:
					val = 1 if valch == '1' else 0
					# record as int
					events[vid].append((current_time, val))
					last_vals[vid] = valch
				continue

	# Build rising edge times from clk events
	clk_events = sorted(events[clk_id], key=lambda x: x[0])
	rising_times = []
	prev = 0
	for t, v in clk_events:
		if prev == 0 and v == 1:
			rising_times.append(t)
		prev = v

	if not rising_times:
		raise ValueError('No rising clock edges found in VCD for detected clock signal.')

	# Helper to sample a signal's last value at or before time
	def sample_at(events_list, time):
		# events_list: list of (t,val) sorted ascending
		val = 0
		for t, v in events_list:
			if t <= time:
				val = v
			else:
				break
		return val

	in_events = sorted(events[in_id], key=lambda x: x[0])
	out_events = sorted(events[out_id], key=lambda x: x[0])

	t = []
	u = []
	v = []
	# determine input width for fractional conversion
	in_width = varmap[in_id]['size']
	max_pos = (1 << (in_width - 1)) - 1 if in_width > 1 else 1

	for rt in rising_times:
		t.append(rt)
		in_val = sample_at(in_events, rt)
		out_val = sample_at(out_events, rt)
		u.append(float(in_val) / float(max_pos) if max_pos != 0 else float(in_val))
		v.append(float(out_val))

	t = np.array(t)
	u = np.array(u)
	v = np.array(v)

	# Compute PSD of v using windowing and rfft
	N = len(v)
	if N < 4:
		raise ValueError('Not enough samples to compute PSD')
	window = np.hanning(N)
	spec = np.fft.rfft(v * window)
	# normalize by coherent gain of window
	cg = np.sum(window) / N
	spec = spec / (N * cg)
	mag = np.abs(spec)
	eps = 1e-12
	spec_db = 20.0 * np.log10(mag + eps)
	f = np.fft.rfftfreq(N, d=1.0)

	return {'t': t, 'u': u, 'v': v, 'f': f, 'spec_db': spec_db}


if __name__ == '__main__':
	import sys
	if len(sys.argv) < 2:
		print('Usage: python calc_PSD.py <path/to/file.vcd> [clk_name] [in_name] [out_name]')
		sys.exit(1)
	vcd = sys.argv[1]
	clk_name = sys.argv[2] if len(sys.argv) > 2 else None
	in_name = sys.argv[3] if len(sys.argv) > 3 else None
	out_name = sys.argv[4] if len(sys.argv) > 4 else None
	print(f'Running PSD on {vcd} (clk={clk_name}, in={in_name}, out={out_name})')
	res = calc_psd_from_vcd(vcd, clk_name=clk_name, in_name=in_name, out_name=out_name)
	print('Samples:', len(res['t']))
	# simple plot if matplotlib available
	try:
		import matplotlib.pyplot as plt
		plt.figure(figsize=(10, 3))
		plt.plot(res['t'], res['u'], label='u')
		plt.plot(res['t'], res['v'], label='v')
		plt.legend()
		plt.title('u and v sampled at rising edges')
		# save plot to post_processing folder
		import os
		out_dir = os.path.dirname(__file__)
		base = os.path.splitext(os.path.basename(sys.argv[1]))[0]
		uv_path = os.path.join(out_dir, f"{base}_uv.png")
		plt.tight_layout()
		plt.savefig(uv_path)
		print('Saved UV plot to', uv_path)
		plt.figure(figsize=(10, 4))
		plt.plot(res['f'], res['spec_db'])
		plt.xlabel('Normalized Frequency')
		plt.ylabel('dB')
		plt.title('Output PSD')
		psd_path = os.path.join(out_dir, f"{base}_psd.png")
		plt.tight_layout()
		plt.savefig(psd_path)
		print('Saved PSD plot to', psd_path)
	except Exception:
		pass
