# ChatKit AI Agent Mission

This brief explains how autonomous agents should interact with the `finclip-chatkit` repository.

## Objectives

- Install and verify the released `ChatKit.xcframework` via SPM or CocoaPods.
- Update documentation, examples, and manifests when new releases ship.
- Produce or validate example applications that integrate ChatKit.

## Repository Map

- `README.md` – human overview and entry point.
- `docs/getting-started.md` – installation and quick start guide.
- `docs/architecture/overview.md` – core system design.
- `Examples/` – runnable reference apps.
- `.github/workflows/` – validation and release automation.
- `Package.swift`, `ChatKit.podspec` – binary distribution manifests.

## Key Workflows

1. **Install ChatKit**
   - Follow the steps in `docs/getting-started.md`.
   - Confirm checksums for downloaded binaries match the release notes.

2. **Publish Release**
   - Ensure `ChatKit.xcframework.zip` and its checksum are available.
   - Update `Package.swift` and `ChatKit.podspec` with the new version, URL, and checksum.
   - Run the publish workflow to validate documentation and manifests.

3. **Update Examples**
   - Modify the sample projects under `Examples/` as capabilities evolve.
   - Document changes in the example README(s) and keep instructions current.

## Conventions

- Use semantic version tags (`vX.Y.Z`).
- Do not commit large binary artifacts to the repository; host them via releases.
- Keep documentation cross-linked with both human-readable explanations and machine-readable summaries.

## Safety Checklist

- Run available linters/tests before pushing changes.
- Avoid altering release manifests without verifying binary availability.
- Coordinate with the private `chatkit` build pipeline for artifact generation.

Follow these guidelines to ensure ChatKit remains reliable for both human developers and automated agents.
