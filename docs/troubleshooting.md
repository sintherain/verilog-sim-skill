# Troubleshooting & Error Reference

> 报错参考库：从「仿真输出」到「根因与修法」的速查表。
> 用法：看到报错后，用**关键词**在该表定位条目 → 读根因 → 按修法改**源文件** → 重跑同名 tb。
> 条目按其来源标注（见文末缩写表；完整链接见 [references.md](references.md)）。

## 定位指引：报错发生在哪个阶段？

| 看到的报错/现象 | 阶段 | 看哪一层 |
|-----------------|------|----------|
| `syntax error near ...`、`parse error` | 编译（词法/语法） | §1 |
| `Unable to bind`、`multiple drivers`、`Unknown module type` | 编译（语义） | §2 |
| `warning: Width mismatch` 等 warning | 编译（静态检查） | §3 |
| `infinite loop detected`、`x` 值、挂起、`TEST FAILED` | 仿真运行 | §4 |
| `%Warning-XXX`（Verilator） | 编译/lint | §5 |
| `$fatal`/`TEST FAILED`/VCD 校验失败 | 自检工作流 | §6 |

---

## §1 语法/解析错误（`syntax error`）

| 报错关键词（可 grep） | 根因 | 修法 | 来源 |
|------------------------|------|------|------|
| `syntax error near 'endmodule'` `near 'end'` | 括号/`begin`-`end` 不匹配、漏 `;` | 数 begin/end 配对数；检查每条语句结尾；少掉的 `;` 常报在下一行 | [CS] |
| `syntax error`（工程用了 SystemVerilog 写法） | 默认 Verilog-2001 模式；或 iverilog 尚不支持的 SV 特性 | `iverilog -g2012`；仍报错则改写成可综合/受支持写法 | [C] |
| `Syntax error in variable list` | 标识符与关键字撞名（`ref`、`step`、`wait`、`always`…） | 重命名信号/变量 | [E] |
| 中文引号/全角标点导致的 `syntax error` | 编辑器自动转换出全角字符 | 用 `Notepad++`/VS Code 显示保留字符；统一半角 | [CS] |
| `missing instance name in instantiation` | 实例化时忘了给实例起名 | `alu u_alu (.a(...));` 中补 `u_alu` | [KS] |

---

## §2 语义/声明错误（能通过词法、绑定失败）

| 报错关键词 | 根因 | 修法 | 来源 |
|------------|------|------|------|
| `Unable to bind wire/reg/memory 'x' in 'module'` | 信号未声明（iverilog 不会全自动建隐式网络） | 在模块开头显式声明；`-Wall` 可提前暴露隐式网络 | [C] |
| `Unknown module type: x` | 模块名拼错/文件没参与编译/实例化名与定义名不一致 | 核对 module 名；把该文件加进编译命令；`-s` 指定顶层 | [E][C] |
| `net 'a' has multiple drivers` | `wire a` 被多个 `assign`/端口同时驱动 | 只留一个驱动源；其余改 `reg`+过程块或改线网名 | [CS] |
| `port ... has width X but width Y` / `truncating` | 端口声明与连接线宽不一致 | 显式补零 `{1'b0, a}` 或改声明；区分 sign-extension 与 zero-extension | [E][CS] |
| `x is not a constant` `reference to x is not a constant` | 变量用在需要参数/常量处（位宽、数组大小、generate 条件） | 改成 `localparam`/`parameter`；运行期值不能定静态尺寸 | [E][SO] |
| `MSB/LSB mismatch`（部分版本） | 端口方向与位序反了 | 检查 `[3:0]` vs `[0:3]`，用 `[MSB:LSB]` 惯例 | [KS] |
| `error: v is not an lvalue` | 对 `wire` 做过程赋值（`always` 里 `= wire`） | wire 只能 `assign`；过程块里声明为 `reg` | [CS] |

---

## §3 编译警告（不阻止编译，但常是潜在 bug）

| 报错关键词 | 根因 | 修法 | 来源 |
|------------|------|------|------|
| `Width mismatch` / `truncating` | 高位被静默截断（`assign y[3:0]=x[7:0]`） | 有意时显式截位/说明；无意时改位宽或扩临时变量 | [CS] |
| `Some designs have no timescale declared` | 模块缺 `timescale 或全局精度不一致 | 每个文件顶部统一 `` `timescale 1ns/1ps ` | [C] |
| `warning: is not a constant`（敏感表） | `always @(a or b)` 敏感表不完整 | 用 `always @(*)`/`@*` | [Ub] |
| `implicit wire` / `inferred latch`（Verilator 对应 LATCH） | 组合块未覆盖所有分支 → 意外锁存 | 分支前赋默认值；每个 `if` 都要有 `else` | [C][V] |
| `Unused signal/port` | 信号没接/没用到 | 检查是否漏连端口（常与"输出恒 x"同源） | [KS][V] |
| `sensitivity-entire-array`（iverilog 特定类别） | 数组信号敏感表未覆盖整个数组 | 用 `@(*)` 或列出全部下标 | [Ub] |

---

## §4 仿真运行时异常（最隐蔽——很多 bug 不报错，只表现异常）

先给结论：**iverilog 不"理解"你的设计意图，它只执行 IEEE 1364 语义**。缺 `else`、时序竞争这类问题它通常不报错，而是让信号保持 `x`、多跳一拍或永远跑不完——答案在波形/输出里，不在报错里。[CS]

| 现象 | 根因 | 修法 | 来源 |
|------|------|------|------|
| `infinite loop detected at time 0`（vvp 终止） | 组合环路/零延迟循环（`assign a=b; assign b=a;`） | 打断环路，或加 `#1` 延迟/状态机 | [CS] |
| 仿真跑不完、光标闪烁不退出 | tb 漏 `$finish`/`$stop`，或 tb 里 忙循环无 `#delay` | 加 `$finish`；tb 加 watchdog（`#20000 $fatal(...)`）；等待死循环加超时 | [E][C] |
| 输出全是 `x` | 寄存器未初始化、无复位、端口悬空 | 复位所有状态；`$display` 前给初值；检查每个输入是否驱动 | [C][CS] |
| `x` 出现在某个时刻之后 | 找到**首个 x 出现时间点**，回溯它依赖的信号 | 用 `vcd_checker.py` 看时间线；修数据通路的未初始化源 | [E] |
| counter 多计/少计一拍 | tb 在时钟边沿同拍驱动输入（竞态）或采样边沿错 | 用无竞争 cycle() 模式：负沿或周期中段驱动，更新沿之后采样 | [E] |
| `$fatal` `TEST FAILED` | 自检比对失败 | 读 FAIL 行拿输入/输出/期望；波形跳转该时刻；分类见 skill §6 | [E] |
| `$finish called at ...` 但结果不对 | 详见 signed/unsigned 理解错误 | 4 位 `1000` 是 8 无符号 or -8 有符号；明确解释并在报告中说明 | [E][C] |
| `VCD info: dumpfile opened` 后无波形 | `$dumpvars` 层次/模块名写错 | `$dumpvars(0, <顶层名>)`；确认顶层与实例名一致 | [E] |

---

## §5 Verilator（可选 lint/快速仿真工具）

Verilator 报错带稳定编号，可直接映射：[官方 warnings.rst](https://github.com/verilator/verilator/blob/master/docs/guide/warnings.rst)（V）

| 编号/模式 | 根因 | 修法 |
|-----------|------|------|
| `%Warning-WIDTH` | 位宽不匹配 | 与 §3 Width mismatch 相同 |
| `%Warning-UNOPTFLAT` | 组合逻辑有反馈环 | 检查 latch/循环赋值；时序逻辑需用寄存器打断 |
| `%Warning-PINMISSING` | 实例化端口漏连 | 补上或 `/* verilator lint_off PINMISSING */` |
| `%Warning-IMPLICIT` | 隐式声明网络 | 显式声明；`--lint-only` 提早发现 |
| `%Warning-ALWCOMBORDER` | `always_comb` 内赋值顺序问题 | 先赋默认值再条件覆盖 |
| `%Warning-INITIALDLY` | 可综合代码用 `#delay` | RTL 中去掉延迟；仅 tb 允许 |
| `%Warning-CASEINCOMPLETE` | case 未覆盖所有分支 | 加 `default` |
| `%Warning-TIMESCALEMOD` | 无 timescale/精度不一致 | 同 §3 |
| `%Error-UNSUPPORTED` / `UNSUPPORTED: Delay statements` | 用了 Verilator 不支持的构造（`#10`、fork-join、real…） | RTL 改写为可综合；tb 部分用 iverilog |
| `%Error: ... UNSIGNED` 等转换 | signed/unsigned 混用 | 显式 `$signed()`/`$unsigned()` |

---

## §6 自检与工作流（skill 自身的判断信号）

| 信号 | 含义 | 下一步 |
|------|------|--------|
| `TEST PASSED` | tb 自检通过 | 进入报告环节 |
| `TEST FAILED: N case(s)` | 有 N 条未通过 | 逐条看 FAIL 行 → skill §6 分类定位 |
| `vvp` 退出码非 0 | 自检失败或运行错误 | 用于 CI/回归判定 |
| VCD 校验器 `WARNING: signal not found` | 信号层次名与 `signals.json` 不符 | 用 `vcd_checker.py wave.vcd`（不给 `--signals`）列出全部信号再改配置 |
| 校验器报告 `timescale: unknown` | 部分仿真器把 `$timescale` 与值分两行写 | 已在本仓库修复；不影响校验结论 |

---

## §7 工具与平台（发行/安装相关内容）

- `fatal: detected dubious ownership in repository ...`：仓库位于不记录 ownership 的文件系统（Windows 挂载盘）。修法：`git config --global --add safe.directory <repo>`；或每次命令注入 `GIT_CONFIG_COUNT=1 ...` 环境变量。[E]
- GTKWave 打不开（Windows）：GTK 应用需经 MSYS2 终端或 `scripts/gtkwave_open.sh` 启动，勿在纯 `cmd` 里直接双击。[E]
- 路径含空格/中文：所有工具命令用双引号包裹路径。[E]

---

## 缩写与来源

| 缩写 | 来源 | 链接 |
|------|------|------|
| [C] | ChipVerify — Troubleshooting & Debugging Guide（开源 EDA 工具故障排查指南） | https://chipverify.com/rtl-synthesis/troubleshooting-and-debugging-guide |
| [CS] | CSDN — iverilog 错误调试方法汇总（中文实战；"四层报错"框架） | https://blog.csdn.net/weixin_35257663/article/details/157778199 |
| [V] | Verilator 官方 warnings.rst（编号化报错参考） | https://github.com/verilator/verilator/blob/master/docs/guide/warnings.rst |
| [Ub] | iverilog manpage（Ubuntu，含 warning 类别说明） | https://manpages.ubuntu.com/manpages/questing/man1/iverilog.1.html |
| [KS] | 金泽大学实验课 FAQ — Verilog よくある Error/Warning 集 | http://exp1gw.ec.t.kanazawa-u.ac.jp/PCIF-2/faq.html |
| [SO] | Stack Overflow — 具体报错问答（如 "Signal not a constant"） | https://stackoverflow.com/posts/74434666/revisions |
| [E] | 本仓库实测踩坑（模板/脚本开发期间复现并修复） | 见 CHANGELOG 与 examples/ |

> 维护提示：新增条目时保持"关键词 → 根因 → 修法 → 来源"四列；优先选能在本仓库示例中复现的条目（可进 examples/buggy/ 做回归测试）。
> 扩展阅读：HDLBits 的 "Finding bugs in code" 系列练习（带 bug 代码集，适合做 fixtures）：https://hdlbits.01xz.net/ ; MPSU 课程 Common mistakes.md（Git 仓库）: https://git-chips.miet.ru/MPSU/APS/src/commit/71cb2f3099a1be75746b3403b9a285556907503b/Basic%20Verilog%20structures/Common%20mistakes.md