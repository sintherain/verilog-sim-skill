<a id="readme-top"></a>

<!-- PROJECT LOGO -->
<br />
<div align="center">
  <a href="https://github.com/sintherain/verilog-sim-skill">
    <img src="images/logo.png" alt="Logo" width="25%" height="auto">
  </a>

<h3 align="center">verilog-sim-skill</h3>

  <p align="center">
    一个全面的 Verilog 仿真与验证工具包，为 HDL 设计自动化测试平台生成、编译、仿真和波形分析。包含错误诊断、VCD 验证和环境检测工具，支持多个示例电路的正确实现和有缺陷设计的回归测试。该工具包已为 CI 就绪，支持跨平台且无外部依赖。
    <br />
    <a href="https://github.com/sintherain/verilog-sim-skill"><strong>探索文档 »</strong></a>
    <br />
  </p>

  <!-- PROJECT SHIELDS -->
[![贡献者][contributors-shield]][contributors-url]
[![复刻数][forks-shield]][forks-url]
[![星标数][stars-shield]][stars-url]
[![议题][issues-shield]][issues-url]
<!-- [![最新发布][release-shield]][release-url]
![发布日期][release-date-shield] -->
[![许可证][license-shield]][license-url]

  <p align="center">
    <a href="https://github.com/sintherain/verilog-sim-skill">查看演示</a>
    &middot;
    <a href="https://github.com/sintherain/verilog-sim-skill/issues/new?labels=bug&template=bug-report---.md">报告错误</a>
    &middot;
    <a href="https://github.com/sintherain/verilog-sim-skill/issues/new?labels=enhancement&template=feature-request---.md">请求功能</a>
  </p>
</div>



<!-- TABLE OF CONTENTS -->
<details>
  <summary>目录</summary>
  <ol>
    <li>
      <a href="#about-the-project">关于项目</a>
      <ul>
        <li><a href="#key-features">主要功能</a></li>
        <li><a href="#built-with">构建技术</a></li>
        <li><a href="#project-structure">项目结构</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">快速开始</a>
      <ul>
        <li><a href="#prerequisites">环境要求</a></li>
        <li><a href="#installation">安装</a></li>
        <li><a href="#configuration">配置</a></li>
      </ul>
    </li>
    <li><a href="#usage">使用指南</a></li>
    <li><a href="#roadmap">路线图</a></li>
    <li><a href="#contributing">贡献</a></li>
    <li><a href="#license">许可证</a></li>
    <li><a href="#contact">联系方式</a></li>
    <li><a href="#acknowledgments">致谢</a></li>
  </ol>
</details>



<!-- ABOUT THE PROJECT -->
## 📖 关于项目

本项目提供了一个全面的 Verilog 仿真与验证工具包，为 HDL 设计自动化测试平台生成、编译、仿真和波形分析。它包含错误诊断、VCD 验证和环境检测工具，支持多个示例电路的正确实现和有缺陷设计的回归测试。该工具包已为 CI 就绪，支持跨平台且无外部依赖。

### 主要功能

- **自动化测试平台生成**：基于 JSON 规格说明自动生成自检测试平台，包括激励内存文件和预期输出内存文件，支持边界值、随机用例和确定性测试用例。
- **跨平台仿真环境**：支持 Windows（MSYS2/MinGW）、macOS 和 Linux，自动检测 Icarus Verilog、GTKWave 和 Verilator 的安装路径和版本信息。
- **错误诊断与映射**：将仿真器错误输出与参考数据库进行匹配，自动提供根本原因、修复建议和源代码参考，支持多编码（UTF-8、UTF-16、GBK）。
- **VCD 波形验证**：解析 VCD 文件，跟踪信号值随时间的变化，生成人类可读的表格/报告，并与预期值进行自动比较。
- **CI/CD 回归测试**：验证所有示例的正确实现通过编译和仿真，同时确保已知有缺陷的设计按预期失败，适用于本地开发和 CI 管道。
- **零外部依赖**：仅使用 Icarus Verilog 和 Python 标准库，无需安装额外的 Python 包，非常适合 CI 管道和教育环境。

<p align="right">(<a href="#readme-top">返回顶部</a>)</p>



### 构建技术

本项目使用纯 Python 标准库和 Bash 脚本实现，无需任何外部依赖。

* [![Python][Python]][Python-url]
* [![Bash][Bash]][Bash-url]
* [![Icarus Verilog][Icarus-Verilog]][Icarus-Verilog-url]

<p align="right">(<a href="#readme-top">返回顶部</a>)</p>



### 📁 项目结构

<details>
<summary>点击展开项目结构</summary>

```
verilog-sim/
├── .gitattributes
├── .gitignore
├── LICENSE
├── scripts/
    ├── ci_verify.sh          # CI/CD 回归测试套件
    ├── env_detect.py         # 跨平台环境检测工具
    ├── errmap.json           # 错误模式参考数据库
    ├── errmap.py             # 错误诊断与映射工具
    ├── gen_testbench.py      # 自动化测试平台生成器
    ├── gtkwave_open.sh       # GTKWave 波形打开包装脚本
    ├── run_sim.sh            # 一键仿真工作流（入口文件）
    ├── vcd_checker.py        # VCD 波形解析与验证工具
    ├── wave_to_png.tcl       # 波形转 PNG 的 TCL 脚本
├── templates/
    ├── tb_comb.v             # 组合逻辑测试平台模板
    ├── tb_counter.v          # 计数器测试平台模板
    ├── tb_fsm.v              # 有限状态机测试平台模板
    ├── tb_seq.v              # 时序逻辑测试平台模板
├── examples/
    ├── alu/
        ├── alu.v             # ALU 设计文件
        ├── signals.json      # 信号配置文件
        ├── spec.json         # 测试规格说明
    ├── counter/
        ├── counter.v         # 计数器设计文件
        ├── tb_counter.v      # 计数器测试平台
    ├── fsm/
        ├── fsm.v             # FSM 设计文件
        ├── tb_fsm.v          # FSM 测试平台
    ├── seq/
        ├── seq_reg.v         # 时序寄存器设计文件
        ├── tb_seq.v          # 时序逻辑测试平台
    ├── buggy/
        ├── undef_module/     # 未定义模块错误示例
            ├── design.v
            ├── design_fixed.v
            ├── tb.v
        ├── width_truncation/ # 位宽截断错误示例
            ├── design.v
            ├── design_fixed.v
            ├── tb.v
        ├── latch_inferred/   # 意外锁存器示例
            ├── design.v
            ├── design_fixed.v
            ├── tb.v
        ├── tb_race_counter/  # 测试平台竞争条件示例
            ├── counter.v
            ├── tb.v
            ├── tb_fixed.v
├── docs/
```

</details>

<p align="right">(<a href="#readme-top">返回顶部</a>)</p>



<!-- GETTING STARTED -->
## 🚀 快速开始

以下是在本地设置项目的示例说明。按照这些简单步骤即可获得本地副本。

### 环境要求

- **Python 3.8+**
- **Icarus Verilog**（iverilog/vvp，版本 10.0 或更高版本推荐）
- **GTKWave**（可选，用于波形查看）
- **Verilator**（可选，用于额外的 lint 检查）

本项目**无需任何外部 Python 包**，仅使用标准库。

运行 `scripts/env_detect.py` 会自动检测 iverilog/vvp 是否已安装，缺失时会打印对应平台的安装命令。也可以直接按平台安装 Icarus Verilog（推荐 10.0 或更高版本）：

| 平台 | 安装命令 |
|---|---|
| Ubuntu / Debian | `sudo apt install iverilog` |
| Fedora | `sudo dnf install iverilog` |
| Arch | `sudo pacman -S iverilog` |
| macOS (Homebrew) | `brew install icarus-verilog` |
| Windows (MSYS2) | 在 MSYS2 shell 里：`pacman -S mingw-w64-ucrt-x86_64-iverilog` |
| Windows (免安装) | 下载 Win32 iverilog 发行版，并把 `iverilog` / `vvp` 加入 PATH |

### 安装

1. 克隆仓库：
   ```sh
   git clone https://github.com/sintherain/verilog-sim-skill.git
   cd verilog-sim-skill
   ```

2. 验证环境依赖：
   ```sh
   python3 scripts/env_detect.py
   ```
   如果没有安装 Icarus Verilog，该脚本会给出各平台的安装建议。

3. 运行 CI 验证套件，确认一切正常：
   ```sh
   bash scripts/ci_verify.sh
   ```

### 配置

项目通过 JSON 文件进行配置，无需修改代码。主要配置文件包括：

- **规格说明文件** (`spec.json`)：定义 DUT 的端口、操作符和测试用例生成参数
- **信号映射文件** (`signals.json`)：定义需要跟踪的 VCD 信号及其预期行为

环境变量配置：

| 变量 | 默认值 | 说明 |
|------|--------|------|
| `SIM_TOP` | `tb` | 仿真顶层模块名称 |
| `IVERILOG_PATH` | 自动检测 | iverilog 可执行文件路径 |
| `VVP_PATH` | 自动检测 | vvp 可执行文件路径 |

<p align="right">(<a href="#readme-top">返回顶部</a>)</p>



<!-- USAGE EXAMPLES -->
## 💻 使用指南

### 一键仿真工作流

使用 `run_sim.sh` 脚本可以自动完成编译、仿真和验证的完整流程：

```bash
# 基本用法：编译并仿真指定设计（需要给出源码文件）
bash scripts/run_sim.sh -d examples/counter examples/counter/counter.v examples/counter/tb_counter.v

# 使用自定义顶层模块（默认 tb）
SIM_TOP=my_tb bash scripts/run_sim.sh -d examples/counter examples/counter/counter.v examples/counter/tb_counter.v

# 仿真后自动进行 VCD 波形验证
bash scripts/run_sim.sh -d examples/counter examples/counter/counter.v examples/counter/tb_counter.v --check

# 编译失败时自动进行错误诊断映射
bash scripts/run_sim.sh -d examples/buggy/undef_module examples/buggy/undef_module/design.v examples/buggy/undef_module/tb.v --errmap
```

### 生成自动化测试平台

```bash
# 生成测试平台
python3 scripts/gen_testbench.py --spec examples/alu/spec.json \
    --workdir examples/alu \
    --out tb_alu.v
```

### VCD 波形验证

```bash
# 解析 VCD 文件并生成信号报告（第一个参数是 VCD 文件路径）
python3 scripts/vcd_checker.py dump.vcd --config signals.json

# 使用 Markdown 格式输出报告
python3 scripts/vcd_checker.py dump.vcd --config signals.json --report report.md
```

### 错误诊断与分析

```bash
# 从编译日志中分析错误
python3 scripts/errmap.py --log build.log

# 直接传入错误文本
python3 scripts/errmap.py --text "error: Unknown module type: foo"

# 从标准输入读取（管道）
cat build.log | python3 scripts/errmap.py

# JSON 格式输出（便于程序处理）
python3 scripts/errmap.py --log build.log --json
```

### 打开波形文件

```bash
# 跨平台打开 GTKWave
bash scripts/gtkwave_open.sh dump.vcd
```

### 运行 CI 回归测试

```bash
# 完整验证所有示例
bash scripts/ci_verify.sh
```

<p align="right">(<a href="#readme-top">返回顶部</a>)</p>



<!-- ROADMAP -->
## 🗺️ 路线图

- [x] 自动化测试平台生成（支持算术、位运算、比较、逻辑运算）
- [x] 跨平台环境检测（Windows/macOS/Linux）
- [x] 错误诊断与映射（支持多编码输入）
- [x] VCD 波形解析与验证
- [x] CI/CD 回归测试套件
- [x] 有缺陷设计的负向测试用例
- [ ] 支持 Verilator 仿真后端
- [ ] 波形转 PNG 图像输出增强
- [ ] 更多示例电路（如 FIFO、ALU 扩展）
- [ ] 支持 SystemVerilog 断言（SVA）
- [ ] 测试覆盖率报告

请参阅[开放议题](https://github.com/sintherain/verilog-sim-skill/issues)查看完整的功能提案列表（和已知问题）。

<p align="right">(<a href="#readme-top">返回顶部</a>)</p>



<!-- CONTRIBUTING -->
## 🤝 贡献

贡献是让开源社区成为如此令人惊叹的学习、灵感和创造场所的原因。我们**非常感谢**您的任何贡献。

如果您有改进建议，请复刻（fork）本仓库并创建拉取请求（Pull Request）。您也可以直接使用"enhancement"标签打开议题。
别忘了给项目点个星标！再次感谢！

1. 复刻（Fork）项目
2. 创建您的功能分支（`git checkout -b feature/AmazingFeature`）
3. 提交您的更改（`git commit -m 'Add some AmazingFeature'`）
4. 推送到分支（`git push origin feature/AmazingFeature`）
5. 打开一个拉取请求

<p align="right">(<a href="#readme-top">返回顶部</a>)</p>

### 主要贡献者：

<a href="https://github.com/sintherain/verilog-sim-skill/graphs/contributors">
  <img src="https://contrib.rocks/image?repo=sintherain/verilog-sim-skill" alt="contrib.rocks image" />
</a>



<!-- LICENSE -->
## 🎗 许可证

版权所有 © 2024-2025 [verilog-sim-skill][verilog-sim-skill]。<br />
根据 [MIT 许可证][license-url] 发布。

<p align="right">(<a href="#readme-top">返回顶部</a>)</p>



<!-- CONTACT -->
## 📧 联系方式

邮箱：2246977739@qq.com

项目链接：[https://github.com/sintherain/verilog-sim-skill](https://github.com/sintherain/verilog-sim-skill)

如果您有任何问题或建议，欢迎通过上述方式联系我们。

<p align="right">(<a href="#readme-top">返回顶部</a>)</p>



<!-- ACKNOWLEDGMENTS -->
## 🙏 致谢

- [Icarus Verilog](http://iverilog.icarus.com/) - 提供优秀的开源 Verilog 仿真器
- [GTKWave](http://gtkwave.sourceforge.net/) - 提供强大的波形查看工具
- [Verilator](https://www.veripool.org/verilator/) - 提供高性能的 Verilog 编译器
- [Best-README-Template](https://github.com/othneildrew/Best-README-Template) - 提供 README 模板参考
- [contrib.rocks](https://contrib.rocks/) - 生成贡献者头像

<p align="right">(<a href="#readme-top">返回顶部</a>)</p>



<!-- REFERENCE LINKS -->
[verilog-sim-skill]: https://github.com/sintherain/verilog-sim-skill

<!-- MARKDOWN LINKS & IMAGES -->
[contributors-shield]: https://img.shields.io/github/contributors/sintherain/verilog-sim-skill.svg?style=flat-round
[contributors-url]: https://github.com/sintherain/verilog-sim-skill/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/sintherain/verilog-sim-skill.svg?style=flat-round
[forks-url]: https://github.com/sintherain/verilog-sim-skill/network/members
[stars-shield]: https://img.shields.io/github/stars/sintherain/verilog-sim-skill.svg?style=flat-round
[stars-url]: https://github.com/sintherain/verilog-sim-skill/stargazers
[issues-shield]: https://img.shields.io/github/issues/sintherain/verilog-sim-skill.svg?style=flat-round
[issues-url]: https://github.com/sintherain/verilog-sim-skill/issues
[release-shield]: https://img.shields.io/github/v/release/sintherain/verilog-sim-skill?style=flat-round
[release-url]: https://github.com/sintherain/verilog-sim-skill/releases
[release-date-shield]: https://img.shields.io/github/release-date/sintherain/verilog-sim-skill?color=9cf&style=flat-round
[license-shield]: https://img.shields.io/github/license/sintherain/verilog-sim-skill.svg?style=flat-round
[license-url]: https://github.com/sintherain/verilog-sim-skill/blob/main/LICENSE

<!-- Tech Stack -->
[Python]: https://img.shields.io/badge/Python-3776AB?style=flat-round&logo=python&logoColor=white
[Python-url]: https://www.python.org/
[Bash]: https://img.shields.io/badge/Bash-4EAA25?style=flat-round&logo=gnubash&logoColor=white
[Bash-url]: https://www.gnu.org/software/bash/
[Icarus-Verilog]: https://img.shields.io/badge/Icarus_Verilog-000000?style=flat-round&logo=verilog&logoColor=white
[Icarus-Verilog-url]: http://iverilog.icarus.com/