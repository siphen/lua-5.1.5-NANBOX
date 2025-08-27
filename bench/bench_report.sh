#!/usr/bin/env bash
set -euo pipefail

# Generate a Markdown report comparing baseline vs NaNbox (strict) across benchmarks

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")"/.. && pwd)"
cd "$ROOT_DIR"

log() { echo "[report] $*"; }

build_one() {
  local tag="$1"; shift
  if [[ "$tag" == "baseline" ]]; then
    bash ./build.sh >/dev/null
  else
    LUA_NANBOX_LAYOUT=1 LUA_NANBOX_STRICT=1 bash ./build.sh >/dev/null
  fi
  local out="build/lua_${tag}.exe"
  if [[ -s build/lua.exe ]]; then cp -f build/lua.exe "$out"; else cp -f src/lua.exe "$out"; fi
  echo "$out"
}

BASE_BIN=$(build_one baseline)
NANB_BIN=$(build_one nanbox)

if [[ ! -x "$BASE_BIN" || ! -x "$NANB_BIN" ]]; then
  echo "[error] missing binaries" >&2; exit 1
fi

RESULTS_DIR="bench"
REPORT_MD="$RESULTS_DIR/report.md"
TMP_CSV="bench_result.csv"
rm -f "$TMP_CSV"

emit_csv() {
  local name="$1" params="$2" tag="$3" out="$4"
  # Parse common metrics: time=, mem_no_gc=, mem_full_gc=, mem_peak=
  local time mem_no mem_full mem_peak
  time=$(echo "$out" | sed -n 's/.*time=\([0-9.]*\)s.*/\1/p' | head -n1)
  mem_no=$(echo "$out" | sed -n 's/.*mem_no_gc=\([0-9.]*\)KB.*/\1/p' | head -n1)
  mem_full=$(echo "$out" | sed -n 's/.*mem_full_gc=\([0-9.]*\)KB.*/\1/p' | head -n1)
  mem_peak=$(echo "$out" | sed -n 's/.*mem_peak=\([0-9.]*\)KB.*/\1/p' | head -n1)
  echo "$name,$params,$tag,$time,${mem_no:-},${mem_full:-},${mem_peak:-}" >> "$TMP_CSV"
}

run_bench() {
  local name="$1" params="$2" base_cmd="$3" nanb_cmd="$4"
  log "running $name baseline..."
  local outb
  outb=$(eval "$base_cmd" | tr -d '\r')
  echo "$outb"
  emit_csv "$name" "$params" baseline "$outb"
  log "running $name nanbox..."
  local outn
  outn=$(eval "$nanb_cmd" | tr -d '\r')
  echo "$outn"
  emit_csv "$name" "$params" nanbox "$outn"
}

# Benchmarks list
run_bench "table_stress" "N=200000 R=200000" \
  "$BASE_BIN bench/table_stress.lua 200000 200000" \
  "$NANB_BIN bench/table_stress.lua 200000 200000"

run_bench "luajit:mandelbrot" "N=1000" \
  "$BASE_BIN bench/luajit/mandelbrot.lua 1000" \
  "$NANB_BIN bench/luajit/mandelbrot.lua 1000"

run_bench "luajit:fannkuchredux" "N=10" \
  "$BASE_BIN bench/luajit/fannkuchredux.lua 10" \
  "$NANB_BIN bench/luajit/fannkuchredux.lua 10"

run_bench "shootout:binarytrees" "N=14" \
  "$BASE_BIN bench/shootout/binarytrees.lua 14" \
  "$NANB_BIN bench/shootout/binarytrees.lua 14"

run_bench "shootout:nbody" "steps=200000" \
  "$BASE_BIN bench/shootout/nbody.lua 200000" \
  "$NANB_BIN bench/shootout/nbody.lua 200000"

run_bench "shootout:spectralnorm" "N=100" \
  "$BASE_BIN bench/shootout/spectralnorm.lua 100" \
  "$NANB_BIN bench/shootout/spectralnorm.lua 100"

run_bench "luau:table-ops" "N=200000" \
  "$BASE_BIN bench/luau/table-ops.lua 200000" \
  "$NANB_BIN bench/luau/table-ops.lua 200000"

run_bench "luau:function-calls" "N=2000000" \
  "$BASE_BIN bench/luau/function-calls.lua 2000000" \
  "$NANB_BIN bench/luau/function-calls.lua 2000000"

# Generate Markdown
log "generating $REPORT_MD"
{
  echo "# Lua NaNbox Benchmark Report"
  echo
  echo "Generated: $(date)"
  echo
  echo "| Benchmark | Params | Impl | Time (s) | mem_no_gc (KB) | mem_full_gc (KB) | mem_peak (KB) |"
  echo "|---|---|---:|---:|---:|---:|---:|"
  awk -F, '{printf "| %s | %s | %s | %s | %s | %s | %s |\n", $1,$2,$3,$4,$5,$6,($7==""?"-":$7)}' "$TMP_CSV"
  echo
  echo "## Summary (speedup and memory deltas)"
  echo
  echo "| Benchmark | Params | Baseline Time | NaNbox Time | Speedup (×) | Baseline mem_no_gc | NaNbox mem_no_gc | Δ no_gc (KB) | Baseline mem_full_gc | NaNbox mem_full_gc | Δ full_gc (KB) |"
  echo "|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|"
  awk -F, '
    {key=$1"|"$2; arr[key"|"$3]=$0}
    END{
      for (k in arr){
        split(k, kk, "|"); b=arr[kk[1]"|"kk[2]"|baseline"]; n=arr[kk[1]"|"kk[2]"|nanbox"]; if(b==""||n=="") continue;
        split(b, bb, ","); split(n, nn, ",");
        bt=bb[4]+0; nt=nn[4]+0; sp=(bt>0?bt/nt:0);
        bmno=(bb[5]==""?0:bb[5]+0); nmno=(nn[5]==""?0:nn[5]+0); dno=nmno-bmno;
        bmfull=(bb[6]==""?0:bb[6]+0); nmfull=(nn[6]==""?0:nn[6]+0); dfull=nmfull-bmfull;
        printf "| %s | %s | %.3f | %.3f | %.3f | %.1f | %.1f | %.1f | %.1f | %.1f | %.1f |\n",
          kk[1], kk[2], bt, nt, sp, bmno, nmno, dno, bmfull, nmfull, dfull;
      }
    }' "$TMP_CSV"
} > "$REPORT_MD"

log "done: $REPORT_MD"

# Inject into docs/NANBOX_REPORT.md between markers if present
DOC="docs/NANBOX_REPORT.md"
if [[ -f "$DOC" ]] && grep -q "<!-- BENCH_REPORT_START -->" "$DOC"; then
  log "updating $DOC with auto report"
  awk -v file="$REPORT_MD" '
    BEGIN{inject=0}
    $0=="<!-- BENCH_REPORT_START -->"{
      print; inject=1;
      c=0; while ((getline l < file)>0) { if (++c>1) print l } close(file);
      next
    }
    $0=="<!-- BENCH_REPORT_END -->"{ inject=0; print; next }
    inject==1 { next }
    { print }
  ' "$DOC" > "$DOC.tmp" && mv "$DOC.tmp" "$DOC"
fi
