# Changelog

本项目遵循 [Keep a Changelog](https://keepachangelog.com/) 与 [Semantic Versioning](https://semver.org/)。

## [Unreleased]

### Added
- examples/buggy/ 带 BUG 案例集（undef_module / width_truncation / latch_inferred / tb_race_counter）：每案例含 bug 版 + 正确 tb + 修复版，CI 双断言（bug 版必败、修复版必过）。
- scripts/errmap.py + errmap.json：报错输出 → 参考库条目匹配（根因/修法/来源/复现路径），自带 --selftest（15 条全部自洽）；多编码日志读取（UTF-8/UTF-16/GBK）。
- scripts/run_sim.sh 集成 --errmap：编译或仿真失败时自动输出参考库建议。

### Fixed
- 时序测试基准里发现并记录新增关键字陷阱：`expect` 为 SystemVerilog 关键字（与 `ref` 同型），重命名为 exp_cnt；案例注释统一英文，规避写入链路的编码损坏。

### Added
- docs/troubleshooting.md 重写为「报错参考库」（约 40 条）：按 parse/语义/warning/运行时四阶段组织，每条含可 grep 关键词、根因、修法、来源；含 Verilator 编号报错节与自检信号节。
- docs/references.md：报错参考库来源清单（官方/教程/经验库/练习集），含来源使用约定。
- SKILL.md 编译节挂接参考库引用。

### Changed
- 明确核心定位为「仿真-调试闭环」：读源文件 → 推导接口/行为 → 编写/补全 testbench → 仿真 → 读取全部输出与报错 → 定位并修改源文件 → 同名 tb 复跑直至通过；SKILL.md 与 README 工作流同步重写。
- SKILL.md 新增：从源文件推导 testbench 的推理步骤、仿真诊断信息收集表（`$display`/`$fatal`/warning/`x`/`z`/挂起/退出码）、错误分类与最小化修改规则、修复报告格式。

### Added
- 开源仓库脚手架：MIT License、.gitignore、README、CONTRIBUTING、CHANGELOG、docs/。
- 跨平台工具探测脚本 `scripts/env_detect.py`（Windows/MSYS2/Cygwin、Linux distro、macOS/Homebrew、conda）。
- 通用自检式 testbench 生成器 `scripts/gen_testbench.py`（AST 白名单参考模型、边界/进位/零/负值用例、106+ case 规模）。
- 独立 VCD 校验器 `scripts/vcd_checker.py`（层级信号、id 别名处理、期望值比对、Markdown 报告、退出码）。
- 一键流程脚本 `scripts/run_sim.sh`、`scripts/ci_verify.sh`、`scripts/gtkwave_open.sh`、`scripts/wave_to_png.tcl`。
- 模板库：templates/tb_comb.v、tb_seq.v、tb_fsm.v、tb_counter.v（无竞争时序约定）。
- 示例工程：examples/alu（旗舰，108 case）、counter、fsm、seq。
- GitHub Actions CI（ubuntu，跑全部示例 + 脚本语法检查）。

### Fixed
- VCD 校验器：同一个 VCD id 在多 scope 声明（网线别名）导致信号丢失。
- VCD 校验器：`$timescale` 值跨行导致 timescale 未知。
- 自检 testbench 模板：修复了「清零计数」错位（posedge 同拍驱动输入竞争）与边沿漏检的经典 race。
- 模板标识符 `ref` 与 SystemVerilog 关键字冲突（重命名为 ref_cnt）。