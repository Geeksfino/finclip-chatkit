# Smart-Gov 示例：远程依赖测试

此目录包含配置为测试 ChatKit 框架的 **远程 SPM（Swift Package Manager）** 和 **CocoaPods** 依赖的 **iLoveHK** 示例应用。

## 概述

Smart-Gov 示例已增强，包含：
- **Package.swift**：用于测试远程二进制依赖解析的 Swift Package Manager 清单
- **project.yml**：原生 iOS 应用的 XcodeGen 配置
- **Makefile**：全面的构建和测试目标

## 快速开始

### 运行所有依赖验证

```bash
make validate-deps
```

这将测试 SPM 和 CocoaPods 依赖解析：

```
🔍 正在验证远程依赖...

📦 SPM（Swift Package Manager）验证：
✅ Package.swift 存在且语法有效
✅ 找到 ChatKit 依赖 URL
✅ 找到版本约束（0.1.0）
✅ 找到 ChatKit 产品
✅ ChatKit XCFramework v0.1.0 可用

📦 CocoaPods 验证：
✅ 依赖验证完成
```

### 测试单个包管理器

#### SPM（Swift Package Manager）

```bash
make test-spm
```

**测试内容：**
- ✅ Package.swift 语法和结构
- ✅ ChatKit 远程依赖 URL 配置
- ✅ 版本约束（`from: "0.1.0"`）
- ✅ ChatKit 产品可用性
- ✅ ChatKit.xcframework.zip 的 GitHub 发布可用性

**预期输出：**
```
🧪 测试远程 SPM 依赖（ChatKit 二进制）...

✅ Package.swift 存在且语法有效

📦 验证 Package.swift 结构...
✅ 找到 ChatKit 依赖 URL
✅ 找到版本约束（0.1.0）
✅ 找到 ChatKit 产品

🔗 检查 ChatKit 发布可用性...
✅ ChatKit XCFramework v0.1.0 可用
```

#### CocoaPods

```bash
make test-cocoapods
```

**测试内容：**
- ✅ CocoaPods 安装
- ✅ Podfile 结构
- ✅ Pod 仓库配置
- ✅ ChatKit pod 规范可用性

## 可用的 Make 目标

### 构建和运行

| 目标 | 描述 |
|--------|-------------|
| `make generate` | 使用 XcodeGen 从 `project.yml` 生成 Xcode 项目 |
| `make open` | 打开生成的 Xcode 项目 |
| `make run` | 在 iOS 模拟器上构建和运行（需要本地 ChatKit.xcframework）|
| `make clean` | 清理构建产物和生成的文件 |
| `make uninstall` | 从模拟器中删除应用 |

### 依赖测试

| 目标 | 描述 |
|--------|-------------|
| `make test-spm` | 验证远程 SPM 依赖解析 |
| `make test-cocoapods` | 验证 CocoaPods 依赖解析 |
| `make validate-deps` | 运行所有依赖验证 |

### 信息

| 目标 | 描述 |
|--------|-------------|
| `make help` | 显示所有可用命令的帮助 |

## 项目结构

```
Smart-Gov/
├── App/                          # 应用源代码
│   ├── App/                      # 主应用入口点
│   ├── Coordinators/             # 会话协调逻辑
│   ├── Models/                   # 数据模型
│   ├── Network/                  # 网络适配器和模拟
│   ├── ViewControllers/          # UI 视图控制器
│   └── Resources/                # 资源、视频、固定数据
├── Package.swift                 # ✨ 新：用于远程测试的 SPM 清单
├── project.yml                   # XcodeGen 项目配置
├── Makefile                      # 构建和测试目标
└── README-REMOTE-DEPS.md         # 本文件
```

## 远程依赖配置

### SPM（Package.swift）

```swift
// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "iLoveHK-App",
    dependencies: [
        // 带有远程二进制 XCFramework 的 ChatKit
        .package(
            url: "https://github.com/Geeksfino/finclip-chatkit.git",
            from: "0.1.0"
        )
    ],
    targets: [
        .target(
            name: "iLoveHK-App",
            dependencies: [
                .product(name: "ChatKit", package: "finclip-chatkit")
            ],
            // ...
        )
    ]
)
```

**特性：**
- 指向远程 ChatKit 仓库
- 使用语义化版本控制（`from: "0.1.0"`）
- 自动从 GitHub 发布解析二进制 XCFramework
- 支持 iOS 和 macOS 目标（在 project.yml 中配置）

### CocoaPods（Podfile）

```ruby
platform :ios, '16.0'

target 'iLoveHK' do
  # 使用直接 podspec URL（"ChatKit" 名称在 CocoaPods trunk 上已被占用）
  pod 'ChatKit', :podspec => 'https://raw.githubusercontent.com/Geeksfino/finclip-chatkit/main/ChatKit.podspec'
end
```

> **注意**：所有依赖（NeuronKit、ConvoUI、SandboxSDK、convstore）都捆绑在 ChatKit XCFramework 中。

**特性：**
- 灵活的版本约束（`~> 0.1.0`）
- 运行 `make test-cocoapods` 时自动生成
- 指定所有捆绑的依赖

## 依赖解析流程

### SPM 流程

1. **包解析**
   ```bash
   swift package resolve --package-path .
   ```
   - 读取 Package.swift
   - 解析 `finclip-chatkit` 依赖
   - 从远程仓库下载 Package.swift

2. **二进制产物下载**
   - SPM 查询 GitHub 发布以获取下载 URL
   - 匹配二进制目标校验和
   - 从以下位置下载 ChatKit.xcframework.zip：
     ```
     https://github.com/Geeksfino/finclip-chatkit/releases/download/v0.1.0/ChatKit.xcframework.zip
     ```

3. **构建集成**
   - XCBuild 链接 ChatKit.xcframework
   - 嵌套框架（NeuronKit、ConvoUI 等）被嵌入
   - 应用代码签名

### CocoaPods 流程

1. **Pod 解析**
   ```bash
   pod install
   ```
   - 读取 Podfile
   - 查询 CocoaPods pod 规范
   - 解析依赖

2. **二进制下载**
   - 下载 ChatKit.xcframework
   - 下载 NeuronKit、ConvoUI、SandboxSDK、convstore
   - 放置在 `Pods/` 目录中

3. **工作区集成**
   - 创建包含应用和 Pods 目标的 `.xcworkspace`
   - 配置框架链接的构建设置

## 故障排除

### SPM 问题

**"Cannot find ChatKit in scope"（在作用域中找不到 ChatKit）**
- 确保 Package.swift 有正确的依赖：`finclip-chatkit`
- 验证包已发布到 GitHub
- 运行：`swift package update --package-path .`

**"Invalid checksum"（无效的校验和）**
- Package.swift 中的校验和必须与实际二进制匹配
- 新发布后更新校验和：
  ```bash
  swift package compute-checksum ChatKit.xcframework.zip
  ```

### CocoaPods 问题

**"The dependency mapping for target iLoveHK is missing"（目标 iLoveHK 的依赖映射缺失）**
- 运行：`pod install` 生成 Pods 工作区
- 确保 Podfile 语法正确

**"Cannot find pod ChatKit"（找不到 pod ChatKit）**
- CocoaPods 可能尚未发布 ChatKit
- 确保 `pod repo update` 成功完成

## 验证结果

### 最新运行 ✅

```
🔍 正在验证远程依赖...

📦 SPM（Swift Package Manager）验证：
✅ Package.swift 存在且语法有效
✅ 找到 ChatKit 依赖 URL
✅ 找到版本约束（0.1.0）
✅ 找到 ChatKit 产品
✅ ChatKit XCFramework v0.1.0 可用

📦 CocoaPods 验证：
✅ 依赖验证完成
```

## 下一步

1. **测试 SPM 解析**
   ```bash
   make test-spm
   ```

2. **测试 CocoaPods 解析**
   ```bash
   make test-cocoapods
   ```

3. **构建本地应用**（需要本地 ChatKit.xcframework）
   ```bash
   make run
   ```

4. **完整集成测试**
   - 更新 project.yml 以使用远程依赖
   - 在 Xcode 项目中配置 SPM 集成
   - 在设备和模拟器上测试

## 修改/添加的文件

- ✨ **Package.swift** - 新：用于远程二进制依赖测试的 SPM 清单
- 📝 **Makefile** - 增强：添加了 `test-spm`、`test-cocoapods`、`validate-deps` 目标
- 📄 **README-REMOTE-DEPS.md** - 新：本文档

## 相关文档

- [ChatKit 仓库](https://github.com/Geeksfino/finclip-chatkit)
- [Swift Package Manager 二进制目标](https://developer.apple.com/documentation/swift_packages/offering_binary_targets)
- [CocoaPods 官方文档](https://guides.cocoapods.org/)

## 参考

- **ChatKit v0.1.0**：https://github.com/Geeksfino/finclip-chatkit/releases/tag/v0.1.0
- **校验和**：`4c05da179daf5283b16f4b5617ee4f349d41d83b357938fa9373bf754c883782`
