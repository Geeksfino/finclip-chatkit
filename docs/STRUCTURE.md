# Documentation Structure

## Current Organization

```
docs/
├── README.md                    # Main index with dual-language navigation
├── getting-started.md            # Language-specific quick starts
├── quick-start.md               # Minimal skeleton templates
│
├── guides/                      # Language-specific comprehensive guides
│   ├── developer-guide.md        # Swift comprehensive guide
│   └── objective-c-guide.md      # Objective-C comprehensive guide
│
├── api-levels.md                # Shared: High-level vs low-level APIs
├── component-embedding.md       # Shared: Embedding scenarios
│
├── integration-guide.md         # Package managers, installation
├── build-tooling.md             # Makefile, XcodeGen
├── remote-dependencies.md       # Remote binary dependencies
│
├── how-to/
│   └── customize-ui.md          # UI customization
│
├── architecture/
│   └── overview.md              # Framework architecture
│
├── troubleshooting.md           # Common issues
│
└── archive/                     # Historical/temporary files
    ├── summaries/               # Old summary documents
    └── llmtxt/                  # Legacy content
```

## Key Principles

1. **Language Separation**: Swift and Objective-C guides are separate
2. **Shared Concepts**: API levels, component embedding are shared
3. **Clear Paths**: Dual learning paths from main README
4. **No Redundancy**: Each concept documented once, referenced elsewhere
5. **Comprehensive ObjC**: Full Objective-C support throughout

