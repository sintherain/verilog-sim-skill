# buggy — 带 BUG 的案例集（调试闭环的练习场）

每个案例 = 一份"病源"（bug 版源码或 testbench）+ 一份正确写的 tb + 一份修复版，
**全部经本仓库 CI 验证**：bug 版必须按预期失败，修复版必须 `TEST PASSED`。
用途：练完整调试闭环（读源文件 → 写/补 tb → 仿真 → 读报错 → 改源文件 → 复跑），
也作为报错参考库 `docs/troubleshooting.md` 的可复现证据。

## 案例一览

| 案例 | 病种 | 病在哪里 | bug 版症状 | 修复版 |
|------|------|----------|------------|--------|
| `undef_module/` | 模块名拼写错误（Unknown module type） | 设计（实例化名 vs 模块定义名） | **编译失败**：`error: Unknown module type: sub_modulee` | `design_fixed.v` |
| `width_truncation/` | 位宽截断丢进位（**沉默 bug**，无任何报错） | 设计（4 位加法被截断） | 运行 FAIL：15+1 得 carry=0（期望 1） | `design_fixed.v` |
| `latch_inferred/` | 组合块分支未覆盖 → 意外锁存 | 设计（缺 `else`） | 运行 FAIL：sel=0 时输出保持旧值 | `design_fixed.v` |
| `tb_race_counter/` | testbench 参考值与检查不同步（off-by-one） | **tb**（设计是好的） | 运行 FAIL：count 恒比期望多 1 | `tb_fixed.v`（race-free cycle 模式） |

## 复现与练习

```bash
# 例：undef_module —— 先看编译报错，再对照修复
cd undef_module
iverilog -g2012 -s tb -o sim.vvp design.v tb.v    # -> error: Unknown module type
iverilog -g2012 -s tb -o sim.vvp design_fixed.v tb.v && vvp sim.vvp   # -> TEST PASSED

# 例：width_truncation —— 编译通过但结果错误（沉默 bug）
cd ../width_truncation
iverilog -g2012 -s tb -o sim.vvp design.v tb.v && vvp sim.vvp        # -> 2 FAIL
iverilog -g2012 -s tb -o sim.vvp design_fixed.v tb.v && vvp sim.vvp  # -> TEST PASSED
```

## 每个案例的验证约定（CI 双断言）

1. **bug 版必须失败**：编译类案例断言报错文本存在；运行类案例断言 `TEST PASSED` 不出现且退出码非 0。
2. **修复版必须通过**：同结构编译运行断言 `TEST PASSED`。

## 扩展

新增案例照此结构：`README.md`（症状/根因/修法讲解）+ bug 版文件 + `*_fixed.v` + 正确 tb，
脚本化断言加入 `scripts/ci_verify.sh` 的 buggy 回归段。
优先选 `docs/troubleshooting.md` 参考库中已有条目、且能在本仓库复现的病种。