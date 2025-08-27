#!/usr/bin/env bash
set -euo pipefail

# Portable build-and-test script for Lua 5.1.5

root_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$root_dir"

uname_s=$(uname -s 2>/dev/null || echo unknown)
case "$uname_s" in
  MINGW*|MSYS*) target=mingw; exe=.exe ;;
  Darwin)       target=macosx; exe="" ;;
  Linux)        target=linux; exe="" ;;
  *)            target=posix; exe="" ;;
esac

jobs=1
if command -v nproc >/dev/null 2>&1; then
  jobs=$(nproc)
elif [[ "$uname_s" == Darwin ]] && command -v sysctl >/dev/null 2>&1; then
  jobs=$(sysctl -n hw.ncpu 2>/dev/null || echo 1)
fi

echo "[info] Detected platform: $uname_s -> make target: $target"

LUA_BIN=""

EXTRA_FLAGS=""
if [[ "${LUA_NANBOX_LAYOUT:-}" != "" ]]; then EXTRA_FLAGS+=" -DLUA_NANBOX_LAYOUT"; fi
if [[ "${LUA_NANBOX_STRICT:-}" != "" ]]; then EXTRA_FLAGS+=" -DLUA_NANBOX_STRICT"; fi

CC_BIN="${CC:-gcc}"

if command -v make >/dev/null 2>&1; then
  echo "[build] Cleaning previous artifacts..."
  (cd src && make clean >/dev/null 2>&1 || true)

  echo "[build] Building with make ($target)..."
  make "$target" -j"$jobs" MYCFLAGS="-DLUA_NANBOX${EXTRA_FLAGS} ${SAN_FLAGS:-}"
  LUA_BIN="src/lua$exe"
else
  echo "[warn] 'make' not found. Falling back to direct gcc build (interpreter only)."
  if ! command -v gcc >/dev/null 2>&1; then
    echo "[error] gcc not found; install build tools or run from MSYS2/MinGW, Linux, or macOS with dev tools." >&2
    exit 1
  fi
  mkdir -p build
  out="build/lua$exe"
  echo "[build] ${CC_BIN} -O2 -I./src -DLUA_ANSI -DLUA_NANBOX${EXTRA_FLAGS} ${SAN_FLAGS:-} etc/all.c -o $out -lm"
  ${CC_BIN} -O2 -I./src -DLUA_ANSI -DLUA_NANBOX${EXTRA_FLAGS} ${SAN_FLAGS:-} etc/all.c -o "$out" -lm
  LUA_BIN="$out"
fi

if [[ ! -x "$LUA_BIN" ]]; then
  echo "[error] Lua binary not found at $LUA_BIN" >&2
  exit 1
fi
ABS_LUA_BIN="$root_dir/$LUA_BIN"

echo "[test] Lua version:"
"$LUA_BIN" -v || true

echo "[test] Running smoke test (hello.lua)..."
"$LUA_BIN" test/hello.lua

echo "[test] Running all tests in test/ (best-effort; skipping/xfailing known cases)..."
fail=0; count=0
declare -A EXPECT_FAIL
EXPECT_FAIL[readonly.lua]=1
shopt -s nullglob
for f in test/*.lua; do
  # Skip scripts that require CLI args or have special invocation semantics
  case "$(basename "$f")" in
    luac.lua) continue ;;
  esac
  count=$((count+1))
  printf '[test] %-30s ' "$(basename "$f")"
  if "$LUA_BIN" "$f" >/dev/null 2>&1; then
    echo "OK"
  else
    base="$(basename "$f")"
    if [[ -n "${EXPECT_FAIL[$base]:-}" ]]; then
      echo "XFAIL"  # expected failure (demonstration script)
    else
      echo "FAIL"; fail=$((fail+1))
    fi
  fi
done
shopt -u nullglob

echo "[summary] total: $count, failed: $fail"
if [[ $fail -ne 0 ]]; then
  echo "[summary] Some tests failed. See output above."
  exit 1
fi

echo "[done] Build and tests completed successfully."

echo "[capi] Building and running C API unit test..."
${CC_BIN} -O2 -I./src -DLUA_ANSI -DLUA_NANBOX${EXTRA_FLAGS} ${SAN_FLAGS:-} etc/all_nolua.c etc/capi_spec.c -o build/capi_spec.exe -lm
build/capi_spec.exe

# Run official Lua tests only when explicitly enabled: OFFICIAL_TESTS=1
if [[ "${OFFICIAL_TESTS:-}" == "1" ]]; then
TESTS_DIR="${LUA_OFFICIAL_TESTS_DIR:-external/lua-tests}"
if [[ -d "$TESTS_DIR" ]]; then
  echo "[official-tests] Detected: $TESTS_DIR"
  dll_ext="so"
  case "$uname_s" in
    MINGW*|MSYS*) dll_ext="dll" ;;
    Darwin) dll_ext="so" ;;
    Linux) dll_ext="so" ;;
  esac
  if [[ -f "$TESTS_DIR/ltests.c" ]]; then
    echo "[official-tests] Building ltests module..."
    if ${CC_BIN} -O2 -shared -fPIC -I./src -DLUA_ANSI ${SAN_FLAGS:-} "$TESTS_DIR"/ltests.c -o "build/ltests.${dll_ext}" -lm; then
      export LUA_CPATH="build/?.${dll_ext};${LUA_CPATH:-}"
      PRELOAD="-lltests"
    else
      echo "[official-tests] Build of ltests failed; continuing without it"
      PRELOAD=""
    fi
  else
    PRELOAD=""
  fi
  export LUA_PATH="$TESTS_DIR/?.lua;$TESTS_DIR/?/init.lua;./?.lua;${LUA_PATH:-}"

  run_file=""
  if [[ -f "$TESTS_DIR/all.lua" ]]; then run_file="$TESTS_DIR/all.lua"; fi
  if [[ -z "$run_file" && -f "$TESTS_DIR/main.lua" ]]; then run_file="$TESTS_DIR/main.lua"; fi

  if [[ -n "$run_file" ]]; then
    echo "[official-tests] Running: $run_file $PRELOAD (cwd=$TESTS_DIR)"
    case "$uname_s" in
      MINGW*|MSYS*)
        ok=1
        # ensure directories expected by attrib.lua exist
        mkdir -p "$TESTS_DIR/libs" "$TESTS_DIR/libs/P1" 2>/dev/null || true
        for f in gc.lua strings.lua literals.lua attrib.lua locals.lua constructs.lua code.lua nextvar.lua pm.lua api.lua vararg.lua closure.lua errors.lua math.lua sort.lua; do
          echo "[official-tests] running subset: $f"
          if ! (cd "$TESTS_DIR" && "$ABS_LUA_BIN" ${PRELOAD:+$PRELOAD} "$f"); then ok=0; break; fi
        done
        if [[ $ok -ne 1 ]]; then
          echo "[official-tests] Failure in official tests subset" >&2
          exit 1
        fi
        ;;
      *)
        if ! (cd "$TESTS_DIR" && "$ABS_LUA_BIN" ${PRELOAD:+$PRELOAD} "$(basename "$run_file")"); then
          echo "[official-tests] Failure in official tests" >&2
          exit 1
        fi
        ;;
    esac
  else
    echo "[official-tests] Runner not found (all.lua/main.lua). Skipping."
  fi
fi
fi
