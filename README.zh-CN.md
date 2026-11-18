# Project Harness

Project Harness 是一个供 AI 助手使用的 skill，用于接入新旧项目、梳理相互冲突的记录、交接工作，以及核对发布版本和回退条件。支持中英文项目。[English guide](README.md)

## 怎么用

| 你可以说 | 应该得到什么 |
|---|---|
| “把这个项目按我的方式管理起来。” | 在根目录建立或补齐 `HARNESS.md`，写下项目特有约定，链接现有资料。 |
| “接着做上次的下载优化。” | 直接从项目入口找到任务并继续。接入只做一次。 |
| “同事拿的是周五的代码，帮我交接。” | 对照同事将拿到的版本，指出哪些本机记录还没交过去，以及会影响什么。 |
| “能退回加查重之前那一版吗？今天新增的任务还能用吗？” | 找到对应的版本和部署依据，说明旧程序能否读取和继续处理新增数据。 |

同事拿到共享项目后可以直接阅读 `HARNESS.md`。在 README 里链接它，或在交接时告诉对方位置。需求、任务和部署结果各自在原有记录中维护。

## 安装当前源码

下载[主分支 ZIP](https://github.com/BurnLikeIce/codex-project-harness/archive/refs/heads/master.zip)，或克隆本仓库。将其中的 `skills/project-harness` 文件夹复制到应用的个人技能目录。本机 Codex 和 Cursor 均支持 `~/.agents/skills/project-harness/SKILL.md`。已有固定安装路径时，更新那一份即可。准备使用时在应用中启用，在新会话中点名 `project-harness` 即可试用。历史正式版本见 [GitHub Releases](https://github.com/BurnLikeIce/codex-project-harness/releases)。

## 旧项目与版本管理

接入会保留团队的 `AGENTS.md`、已有协作说明、未提交内容和旧协议中声明的资料路径。选择实际使用的需求、任务和发布资料加入入口，项目约定直接用普通 Markdown 维护。

内置 PowerShell 和 POSIX 脚本支持[接入和链接检查](skills/project-harness/references/update-existing-project.md)，也能[只读比较交接版本](skills/project-harness/references/coordination.md)。打包、部署、回退继续使用各项目的维护入口。具体见[版本和恢复说明](skills/project-harness/references/git-release.md)。

## 开发验证

运行 `tests/run-tests.ps1` 和 `sh tests/run-tests.sh`。两套测试覆盖接入、文件保留和 Git 交接比较。应用对 skill 的选择及真实部署效果须分别核实。

社区项目。[MIT 许可证](LICENSE)。
