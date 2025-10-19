# Finclip ChatKit

Finclip ChatKit is the public distribution for the Finclip conversational SDK. This repository hosts the published binary frameworks (SwiftPM and CocoaPods), extensive developer documentation, and runnable example applications. It also provides AI-friendly resources so autonomous agents can consume the SDK reliably.

## What You Will Find Here

- ✅ **Binary distribution manifests** for Swift Package Manager and CocoaPods that point to the published `ChatKit.xcframework` releases.
- 📚 **Documentation portal** under `docs/` with human- and agent-readable guides, architecture specs, API references, and task playbooks.
- 🧪 **Example apps** under `Examples/` demonstrating production-ready integrations, from minimal usage to full chat experiences.
- 🤖 **AI enablement content** that describes the conventions, tasks, and prompts an AI agent should follow when working with ChatKit.

## Getting Started

1. Read `docs/getting-started.md` for installation instructions and a quick-start walkthrough.
2. Explore `Examples/` to run the sample applications locally.
3. Review `docs/architecture/overview.md` to understand how ChatKit composes with NeuronKit and ConvoUI.
4. Follow the release workflow described in `.github/workflows/` when publishing new binary versions.

## Repository Layout

```text
README.md                 → Quick introduction and repo guide
Package.swift             → Swift Package manifest for the released XCFramework
ChatKit.podspec           → CocoaPods spec referencing the published binary
Examples/                 → Runnable sample applications and how-to guides
docs/                     → Full documentation set (overviews, how-to, reference, AI guides)
.github/workflows/        → Automation for validation and release publication
LICENSE                   → License for distribution (to be added)
```

## Contributing

Please open issues or pull requests with improvements to documentation, examples, or tooling. Use `docs/ai-agents/mission.md` when onboarding AI copilots so they follow the established conventions.

## Release Overview

Binary artifacts are produced by the private build pipeline in the main `chatkit` repository. Once a release is generated, synchronize this repository by:

- Creating a GitHub release tagged `vX.Y.Z` attaching `ChatKit.xcframework.zip` and checksum.
- Updating `Package.swift` and `ChatKit.podspec` to point at the new release URL/checksum.
- Publishing updated docs and examples reflecting the new capabilities.

Consult `.github/workflows/publish.yml` for the automated steps used to validate the manifests and documentation before publishing.
