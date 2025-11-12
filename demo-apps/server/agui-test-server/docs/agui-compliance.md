# AG-UI Compliance Fix: TEXT_MESSAGE Lifecycle

## Problem
The LLM agent was emitting only `TEXT_MESSAGE_CHUNK` events without proper lifecycle markers, causing the NeuronKit adapter to treat each token as a separate complete message.

## Root Cause
- **Server**: `LLMAgent` generated one `messageId` but only yielded `TEXT_MESSAGE_CHUNK` events
- **Client**: `AGUI_Adapter.handleTextChunk()` auto-finalized messages when no prior state existed, assuming standalone chunks
- **Result**: Each token became a separate message with different `canonicalId`, breaking streaming

## Solution

### Server-Side Changes (`src/agents/llm.ts`)
Added proper AG-UI text message lifecycle:

1. **TEXT_MESSAGE_START** - Emitted before first content chunk
   ```typescript
   const startEvt: TextMessageStartEvent = {
     type: EventType.TEXT_MESSAGE_START,
     messageId,
     role: 'assistant',
   };
   yield startEvt;
   ```

2. **TEXT_MESSAGE_CHUNK** - Continues as before (multiple chunks with same messageId)
   ```typescript
   const chunkEvt: TextMessageChunkEvent = {
     type: EventType.TEXT_MESSAGE_CHUNK,
     messageId,
     delta: delta.content,
   };
   yield chunkEvt;
   ```

3. **TEXT_MESSAGE_END** - Emitted after all chunks complete
   ```typescript
   const endEvt: TextMessageEndEvent = {
     type: EventType.TEXT_MESSAGE_END,
     messageId,
   };
   yield endEvt;
   ```

### Client-Side Changes (`neuronkit/Sources/network/AGUI_Adapter.swift`)
Removed auto-finalization of chunk-only messages:

**Before:**
```swift
// Finalize immediately if this chunk was standalone (no start/end events expected).
if existingState == nil {
  finalizeStreamingMessage(...)
}
```

**After:**
```swift
// Don't auto-finalize chunks - wait for explicit TEXT_MESSAGE_END or timeout
// This ensures proper AG-UI compliance where START/CHUNK/END bracket the stream
```

## Event Sequence (Compliant)

```
RUN_STARTED
  ↓
TEXT_MESSAGE_START (messageId: "msg_123", role: "assistant")
  ↓
TEXT_MESSAGE_CHUNK (messageId: "msg_123", delta: "Hello")
TEXT_MESSAGE_CHUNK (messageId: "msg_123", delta: " world")
TEXT_MESSAGE_CHUNK (messageId: "msg_123", delta: "!")
  ↓
TEXT_MESSAGE_END (messageId: "msg_123")
  ↓
RUN_FINISHED
```

## Benefits

1. **Full AG-UI Compliance**: Follows the standard text message lifecycle pattern
2. **Proper Streaming**: All chunks share the same `canonicalId` in the adapter
3. **Single Message**: `handleMessages()` receives exactly one complete message
4. **Real-time Display**: `handleStreamingChunk()` still emits tokens immediately for UI
5. **Backward Compatible**: Client tolerates servers that still emit chunk-only streams

## Testing

```bash
# Start server
cd compliance-servers/agui-test-server
npm run dev

# Test client
cd neuronkit/examples/ag-ui_sse
LOCAL_DEPS=1 swift run ag-ui_sse --url http://localhost:3000 --message "Count from 1 to 5"
```

Expected output:
```
Assistant: 1, 2, 3, 4, 5
```

Not:
```
A: 1
A: ,
A:  2
...
```

## Related Files
- Server: `compliance-servers/agui-test-server/src/agents/llm.ts`
- Client: `neuronkit/Sources/network/AGUI_Adapter.swift`
- CLI Example: `neuronkit/examples/ag-ui_sse/Sources/ConsoleConvoUIAdapter.swift`
