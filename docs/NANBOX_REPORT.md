# Lua 5.1 NaNboxing 改造与验证技术报告

生成时间：自动生成（请以本地运行时间为准）

## 背景与目标
- 将 PUC Lua 5.1（解释器）改造为 NaNboxed TValue（8 字节），降低内存占用、改善数据结构访问的缓存命中。
- 以默认开关（`LUA_NANBOX`）启用通道/脚手架；支持真实 8 字节布局（`LUA_NANBOX_LAYOUT`）与严格检查（`LUA_NANBOX_STRICT`）。
- 建立完善的单元测试（Lua 与 C API）、接入官方 lua-tests（v5-1-3），并提供系统化基准测试与自动化报告。

## 实现概览
- 访问器集中化：`src/lnanbox.h` 提供 tv_type/tv_get*/tv_set*；区分“盒装 NaN”和“算术 NaN”。
- 算术热路径优化：`ttisnumber(o) → tv_isnumber_fast(o)`，`nvalue(o) → o->box.n`（在 NaNbox 布局下直取）。
- deadkey 指针保持：仅改标签，保留 payload，避免 next/pairs 出错。
- 表键写入统一：`setobj(L, key2tval(mp), key)`；NaNbox 布局运行时初始化 dummynode。
- 构建与测试：`build.sh` 集成 Lua/C API 单测与官方 lua-tests；CI 覆盖 Linux/Windows（子集）。

## 正确性验证
- Lua 单测：类型/表/元方法/协程/GC 专项（barrier/weak/step/upvalue/env/finalizer 等）— NaNbox 严格模式全通过。
- C API 单测：lightuserdata/topointer/xmove/table setget 等路径—NaNbox 布局 roundtrip 一致。
- 官方 lua-tests（v5-1-3）：Windows/MSYS 跑稳定子集；Linux 全量（CI）。

## 基准方法与指标
- 入口：`bash bench/bench_report.sh`（自动构建 baseline 与 NaNbox(strict)，生成 `bench/report.md` 并注入本文）。
- 指标：
  - time：`os.clock()`
  - mem_no_gc：结束时未完整收集的活跃堆增量（KB）
  - mem_full_gc：结束后 `collectgarbage("collect")` 的活跃堆增量（KB）
  - mem_peak：运行中采样峰值（部分基准）
- 基准集合：table_stress（峰值采样）、luau:table-ops/function-calls、luajit:mandelbrot/fannkuchredux、shootout:binarytrees/nbody/spectralnorm。

## 自动化基准报告（脚本注入）

以下表格由 `bash bench/bench_report.sh` 自动生成：

<!-- BENCH_REPORT_START -->

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

<!-- BENCH_REPORT_END -->

## 结论概述
- 内存：数据结构访问型场景内存显著下降（如 table-ops `mem_no_gc` 约降 50%；table_stress 峰值/尾部均降低）。
- 性能：
  - 数据结构访问型：时间相近或略优（缓存友好、对象体更小）。
  - 算术密集型：可能略慢（类型判别/位操作成本），但经“快判 + 直取值”已降低开销。

## 复现
- 本仓库测试：`bash build.sh`
- NaNbox 严格：`LUA_NANBOX_LAYOUT=1 LUA_NANBOX_STRICT=1 bash build.sh`
- 官方测试：Windows（子集）/Linux（全量）— `OFFICIAL_TESTS=1 bash build.sh`
- 基准报告：`bash bench/bench_report.sh`（生成 `bench/report.md` 并注入本文）

## 后续工作
- 进一步剔除 VM 算术指令中的非必要类型分支。
- 扩展基准（fasta/k-nucleotide/regex-dna 等）与 CI 的统计（中位/p95/方差）。
- 将 CSV/MD 持久化为 artifacts，长期跟踪回归与收益。
