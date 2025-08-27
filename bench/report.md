# Lua NaNbox Benchmark Report

Generated: Wed Aug 27 18:09:51     2025

| Benchmark | Params | Impl | Time (s) | mem_no_gc (KB) | mem_full_gc (KB) | mem_peak (KB) |
|---|---|---:|---:|---:|---:|---:|
| table_stress | N=200000 R=200000 | baseline | 0.025000 | 23256.3 | 23256.3 | 27486.1 |
| table_stress | N=200000 R=200000 | nanbox | 0.026000 | 17111.9 | 17111.9 | 21333.1 |
| luajit:mandelbrot | N=1000 | baseline | 0.760 | 16.1 | 0.0 | - |
| luajit:mandelbrot | N=1000 | nanbox | 0.749 | 8.1 | 0.0 | - |
| luajit:fannkuchredux | N=10 | baseline | 12.767 | 33.5 | 0.0 | - |
| luajit:fannkuchredux | N=10 | nanbox | 13.301 | 24.4 | 0.0 | - |
| shootout:binarytrees | N=14 | baseline | 0.723 | 17729.4 | 1.3 | - |
| shootout:binarytrees | N=14 | nanbox | 0.742 | 14069.5 | 0.8 | - |
| shootout:nbody | steps=200000 | baseline | 0.452 | 0.8 | 0.8 | - |
| shootout:nbody | steps=200000 | nanbox | 0.554 | 0.4 | 0.4 | - |
| shootout:spectralnorm | N=100 | baseline | 0.020 | 46.2 | 0.8 | - |
| shootout:spectralnorm | N=100 | nanbox | 0.019 | 23.8 | 0.4 | - |
| luau:table-ops | N=200000 | baseline | 0.012 | 4096.2 | 0.0 | - |
| luau:table-ops | N=200000 | nanbox | 0.012 | 2048.2 | 0.0 | - |
| luau:function-calls | N=2000000 | baseline | 0.052 | 0.0 | 0.0 | - |
| luau:function-calls | N=2000000 | nanbox | 0.051 | 0.0 | 0.0 | - |

## Summary (speedup and memory deltas)

| Benchmark | Params | Baseline Time | NaNbox Time | Speedup (×) | Baseline mem_no_gc | NaNbox mem_no_gc | Δ no_gc (KB) | Baseline mem_full_gc | NaNbox mem_full_gc | Δ full_gc (KB) |
|---|---|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| shootout:binarytrees | N=14 | 0.723 | 0.742 | 0.974 | 17729.4 | 14069.5 | -3659.9 | 1.3 | 0.8 | -0.5 |
| luau:table-ops | N=200000 | 0.012 | 0.012 | 1.000 | 4096.2 | 2048.2 | -2048.0 | 0.0 | 0.0 | 0.0 |
| luajit:mandelbrot | N=1000 | 0.760 | 0.749 | 1.015 | 16.1 | 8.1 | -8.0 | 0.0 | 0.0 | 0.0 |
| luau:function-calls | N=2000000 | 0.052 | 0.051 | 1.020 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 |
| luau:function-calls | N=2000000 | 0.052 | 0.051 | 1.020 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 | 0.0 |
| shootout:spectralnorm | N=100 | 0.020 | 0.019 | 1.053 | 46.2 | 23.8 | -22.4 | 0.8 | 0.4 | -0.4 |
| luajit:fannkuchredux | N=10 | 12.767 | 13.301 | 0.960 | 33.5 | 24.4 | -9.1 | 0.0 | 0.0 | 0.0 |
| shootout:nbody | steps=200000 | 0.452 | 0.554 | 0.816 | 0.8 | 0.4 | -0.4 | 0.8 | 0.4 | -0.4 |
| shootout:spectralnorm | N=100 | 0.020 | 0.019 | 1.053 | 46.2 | 23.8 | -22.4 | 0.8 | 0.4 | -0.4 |
| table_stress | N=200000 R=200000 | 0.025 | 0.026 | 0.962 | 23256.3 | 17111.9 | -6144.4 | 23256.3 | 17111.9 | -6144.4 |
| shootout:nbody | steps=200000 | 0.452 | 0.554 | 0.816 | 0.8 | 0.4 | -0.4 | 0.8 | 0.4 | -0.4 |
| luajit:mandelbrot | N=1000 | 0.760 | 0.749 | 1.015 | 16.1 | 8.1 | -8.0 | 0.0 | 0.0 | 0.0 |
| table_stress | N=200000 R=200000 | 0.025 | 0.026 | 0.962 | 23256.3 | 17111.9 | -6144.4 | 23256.3 | 17111.9 | -6144.4 |
| luau:table-ops | N=200000 | 0.012 | 0.012 | 1.000 | 4096.2 | 2048.2 | -2048.0 | 0.0 | 0.0 | 0.0 |
| shootout:binarytrees | N=14 | 0.723 | 0.742 | 0.974 | 17729.4 | 14069.5 | -3659.9 | 1.3 | 0.8 | -0.5 |
| luajit:fannkuchredux | N=10 | 12.767 | 13.301 | 0.960 | 33.5 | 24.4 | -9.1 | 0.0 | 0.0 | 0.0 |
