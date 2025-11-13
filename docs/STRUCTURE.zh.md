# 文档结构

## 当前组织

```
docs/
├── README.md                    # 主索引，双语导航
├── getting-started.md            # 特定语言的快速开始
├── quick-start.md               # 最小化骨架模板
│
├── guides/                      # 特定语言的全面指南
│   ├── developer-guide.md        # Swift 全面指南
│   └── objective-c-guide.md      # Objective-C 全面指南
│
├── api-levels.md                # 共享：高级 API 与低级 API
├── component-embedding.md       # 共享：嵌入场景
│
├── integration-guide.md         # 包管理器、安装
├── build-tooling.md             # Makefile、XcodeGen
├── remote-dependencies.md       # 远程二进制依赖
│
├── how-to/
│   └── customize-ui.md          # UI 自定义
│
├── architecture/
│   └── overview.md              # 框架架构
│
├── troubleshooting.md           # 常见问题
│
└── archive/                     # 历史/临时文件
    ├── summaries/               # 旧摘要文档
    └── llmtxt/                  # 遗留内容
```

## 关键原则

1. **语言分离**：Swift 和 Objective-C 指南是分开的
2. **共享概念**：API 层级、组件嵌入是共享的
3. **清晰路径**：从主 README 提供双学习路径
4. **无冗余**：每个概念仅文档化一次，在其他地方引用
5. **全面的 ObjC**：整个项目全面支持 Objective-C
