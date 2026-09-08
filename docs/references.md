# References — 报错参考库来源

`docs/troubleshooting.md` 中条目的来源出处。维护规则：新增条目必须写明来源缩写；本文件按「官方 → 系统性教程 → 经验库 → 练习集」排列。

## 官方（工具维护者发布）

| 来源 | 内容 | 链接 |
|------|------|------|
| Verilator — Warnings and Errors（`warnings.rst`） | 唯一正式的**编号化**报错参考：每个 warning/error 有稳定编号（WIDTH、UNOPTFLAT、PINMISSING、IMPLICIT、ALWCOMBORDER、TIMESCALEMOD、CASEINCOMPLETE、UNSUPPORTED …）、解释与禁用方法 | https://github.com/verilator/verilator/blob/master/docs/guide/warnings.rst |
| iverilog manpage（Ubuntu 手册） | iverilog 命令行选项与部分 warning 类别（如 `sensitivity-entire-array`）的正式说明 | https://manpages.ubuntu.com/manpages/questing/man1/iverilog.1.html |
| Icarus Verilog 官网 | 工具首页/下载与基本文档 | https://iverilog.icarus.com/ |

## 系统性教程（结构化的排查指南）

| 来源 | 内容 | 链接 |
|------|------|------|
| ChipVerify — RTL Synthesis Troubleshooting & Debugging Guide | 按工具分类（Icarus/Verilator/Yosys/OpenSTA）的真实报错 + 含义 + 解法；含"增量剥离、最小复现、多工具交叉验证"等调试方法论；关联页面：Waveform Analysis with GTKWave、Simulation vs Reality | https://chipverify.com/rtl-synthesis/troubleshooting-and-debugging-guide |
| ChipVerify — 相关概念页（Simulation Timestep & Scheduling、Debugging Methodologies、Scoreboard & Reference Models） | 时间步/事件调度、调试方法论、参考模型设计 —— 与 skill 的自检设计直接相关 | https://chipverify.com/verification/simulation-timestep-scheduling |

## 经验库（教学/项目沉淀）

| 来源 | 内容 | 链接 |
|------|------|------|
| CSDN — iverilog 错误调试方法汇总 | 中文实战：提出"parse / 语义 / warning / runtime"四层报错框架；强调 iverilog 报错是谜面、答案在事件模型与日志细节里 | https://blog.csdn.net/weixin_35257663/article/details/157778199 |
| 金泽大学实验课 FAQ — Verilog よくある Error/Warning 集 | 大学教学场景逐条收集的常见报错问答（日语） | http://exp1gw.ec.t.kanazawa-u.ac.jp/PCIF-2/faq.html |
| MPSU APS 课程 Common mistakes.md | 公开 Git 仓库里的 Verilog 常见错误清单 | https://git-chips.miet.ru/MPSU/APS/src/commit/71cb2f3099a1be75746b3403b9a285556907503b/Basic%20Verilog%20structures/Common%20mistakes.md |
| Stack Overflow（按具体报错搜索） | 具体报错的高票答案，如 "Signal not a constant" | https://stackoverflow.com/questions/tagged/verilog |

## 练习/验证集（参考，不直接入库）

| 来源 | 内容 | 链接 |
|------|------|------|
| HDLBits — Finding bugs in code | 带 bug 的代码练习集；可作 skill 的 buggy 示例/回归测试素材 | https://hdlbits.01xz.net/ |
| ChipVerify — Icarus Verilog 入门教程 | 入门/波形分析配套 | https://chipverify.com/rtl-synthesis/icarus-verilog |

## 来源使用约定

- **引而不抄**：参考库条目是独立撰写的"关键词→根因→修法"摘要，来源仅作引用与致谢；
- **不做镜像**：不把整段网页文本复制进仓库（版权与维护成本）；需要深入时点击链接；
- **可复现优先**：新增条目如能在本仓库 `examples/` 中构造复现（如 `examples/buggy/`），优先入参考库并可进 CI。