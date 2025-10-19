# ChatKit Architecture Overview

ChatKit combines three layers to deliver conversational AI experiences on Apple platforms:

1. **NeuronKit orchestration** – manages sessions, capability manifests, and tool execution policies.
2. **ConvoUI presentation** – renders chat timelines, interactive cards, and system status in SwiftUI/UIKit.
3. **ChatKit adapter layer** – glues application code to NeuronKit and ConvoUI, handling persistence, analytics hooks, and theming defaults.

```
┌───────────────────────────────────────┐
│           Application Layer          │
│  (Your app, custom tools/UI modules) │
└───────────────────────────────────────┘
              │
              ▼
┌───────────────────────────────────────┐
│           ChatKit Adapter             │
│  - Runtime configuration              │
│  - Session lifecycle helpers          │
│  - Theme + policy defaults            │
└───────────────────────────────────────┘
              │
              ▼
┌─────────────┬────────────┬───────────┐
│  NeuronKit  │  ConvoUI   │  Convstore│
│  Orchestration│ Rendering│  Storage  │
└─────────────┴────────────┴───────────┘
              │
              ▼
┌───────────────────────────────────────┐
│        AI providers / tool APIs       │
└───────────────────────────────────────┘
```

## Key Concepts

- **Session**: ties messages, participants, and policies together.
- **Capability manifest**: declarative tool list enforced by NeuronKit.
- **Message store**: Convstore provides snapshots and delta updates.
- **Adapter hooks**: interception points for analytics and custom UX reactions.

## Data Flow

1. App starts a session through the adapter.
2. NeuronKit evaluates incoming events against the manifest.
3. Convstore persists state, notifies the adapter, and feeds ConvoUI components.
4. ConvoUI renders the timeline, quick replies, status banners, and media.
5. Tool invocations and AI responses loop back into NeuronKit for continued orchestration.

## Next Steps

- See `docs/architecture/runtime-lifecycle.md` for lifecycle diagrams.
- Visit `docs/how-to/customize-ui.md` to theme ChatKit for your brand.
- Review `docs/reference/` (coming soon) for API-level detail.
