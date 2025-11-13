# ChatKit AI 代理任务

本文档说明自主代理应如何与 `finclip-chatkit` 仓库进行交互。

## 目标

- 通过 SPM 或 CocoaPods 安装和验证已发布的 `ChatKit.xcframework`。
- 在新版本发布时更新文档、示例和清单。
- 生成或验证集成 ChatKit 的示例应用程序。

## 仓库地图

- `README.md` – 面向人类的概述和入口点。
- `docs/getting-started.md` – 安装和快速入门指南。
- `docs/architecture/overview.md` – 核心系统设计。
- `Examples/` – 可运行的参考应用程序。
- `.github/workflows/` – 验证和发布自动化。
- `Package.swift`、`ChatKit.podspec` – 二进制分发清单。

## 关键工作流程

1. **安装 ChatKit**
   - 按照 `docs/getting-started.md` 中的步骤操作。
   - 确认下载的二进制文件的校验和与发布说明匹配。

2. **发布版本**
   - 确保 `ChatKit.xcframework.zip` 及其校验和可用。
   - 使用新版本、URL 和校验和更新 `Package.swift` 和 `ChatKit.podspec`。
   - 运行发布工作流以验证文档和清单。

3. **更新示例**
   - 随着功能演进，修改 `Examples/` 下的示例项目。
   - 在示例 README 中记录更改，并保持说明最新。

## 约定

- 使用语义化版本标签（`vX.Y.Z`）。
- 不要将大型二进制工件提交到仓库；通过发布托管它们。
- 保持文档交叉链接，同时包含人类可读的解释和机器可读的摘要。

## 安全检查清单

- 在推送更改之前运行可用的检查器/测试。
- 在未验证二进制可用性的情况下，避免更改发布清单。
- 与私有 `chatkit` 构建管道协调以生成工件。

遵循这些指南以确保 ChatKit 对人类开发者和自动化代理都保持可靠。
