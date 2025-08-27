#!/usr/bin/env bash
set -euo pipefail

RUNS=${RUNS:-15}
N=${N:-200000}
R=${R:-200000}

echo "[compare] Building baseline..."
bash ./build.sh >/dev/null
if [[ -s build/lua.exe ]]; then cp -f build/lua.exe build/lua_baseline.exe; else cp -f src/lua.exe build/lua_baseline.exe; fi

echo "[compare] Building NaNbox layout (strict)..."
LUA_NANBOX_LAYOUT=1 LUA_NANBOX_STRICT=1 bash ./build.sh >/dev/null
if [[ -s build/lua.exe ]]; then cp -f build/lua.exe build/lua_nanbox.exe; else cp -f src/lua.exe build/lua_nanbox.exe; fi

BASE=build/lua_baseline.exe
NANB=build/lua_nanbox.exe
[[ -x "$BASE" ]] || { echo "Baseline binary not found" >&2; exit 1; }
[[ -x "$NANB" ]] || { echo "NaNbox binary not found" >&2; exit 1; }

echo "[compare] Running table_stress.lua: RUNS=$RUNS N=$N R=$R"

run_suite() {
  local bin="$1"
  local tag="$2"
  local times=()
  local mems=()
  for ((i=1;i<=RUNS;i++)); do
    out=$("$bin" bench/table_stress.lua "$N" "$R" | tr -d '\r')
    t=$(echo "$out" | sed -n 's/.*time=\([0-9.]*\)s.*/\1/p')
    m=$(echo "$out" | sed -n 's/.*mem_peak=\([0-9.]*\)KB.*/\1/p')
    echo "[$tag] run $i: time=${t}s mem_peak=${m}KB"
    times+=("$t"); mems+=("$m")
  done
  tmp_times="./${tag}_times.txt"; tmp_mems="./${tag}_mems.txt"
  printf '%s\n' "${times[@]}" | sort -n > "$tmp_times"
  printf '%s\n' "${mems[@]}" | sort -n > "$tmp_mems"
  local count mid idx95
  count=$(wc -l < "$tmp_times")
  mid=$(( (count + 1) / 2 ))
  idx95=$(( (95 * count + 99) / 100 ))
  if (( idx95 < 1 )); then idx95=1; fi
  local p50 p95 m50 m95
  p50=$(awk -v m=$mid 'NR==m{print $1}' "$tmp_times")
  p95=$(awk -v k=$idx95 'NR==k{print $1}' "$tmp_times")
  m50=$(awk -v m=$mid 'NR==m{print $1}' "$tmp_mems")
  m95=$(awk -v k=$idx95 'NR==k{print $1}' "$tmp_mems")
  echo "[$tag] median_time=${p50}s p95_time=${p95}s median_mem=${m50}KB p95_mem=${m95}KB"
}

run_suite "$BASE" baseline
run_suite "$NANB" nanbox

echo "[compare] Running shootout benchmarks (single run each)"
"$BASE" bench/shootout/binarytrees.lua 14
"$NANB" bench/shootout/binarytrees.lua 14
"$BASE" bench/shootout/nbody.lua 200000
"$NANB" bench/shootout/nbody.lua 200000
"$BASE" bench/shootout/spectralnorm.lua 100
"$NANB" bench/shootout/spectralnorm.lua 100

echo "[compare] Running Luau-style microbenches"
"$BASE" bench/luau/table-ops.lua 200000
"$NANB" bench/luau/table-ops.lua 200000
"$BASE" bench/luau/function-calls.lua 2000000
"$NANB" bench/luau/function-calls.lua 2000000
