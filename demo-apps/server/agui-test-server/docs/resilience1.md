# Fetch Resilience Implementation Summary

## Changes Made

### 1. Enhanced LLMConfig Interface
**File**: `src/agents/llm.ts`

Added three new optional configuration properties:
- `maxRetries?: number` - Number of retry attempts (default: 2)
- `retryDelayMs?: number` - Base delay between retries in milliseconds (default: 1000)
- `timeoutMs?: number` - Request timeout in milliseconds (default: 30000)

### 2. LLMAgent Constructor
**File**: `src/agents/llm.ts`

Added private fields to store retry configuration:
```typescript
private readonly maxRetries: number;
private readonly retryDelayMs: number;
private readonly timeoutMs: number;
```

Initialized with sensible defaults in constructor.

### 3. New fetchWithRetry Method
**File**: `src/agents/llm.ts`

Implemented `private async fetchWithRetry()` method that:
- Wraps the fetch call with automatic retry logic
- Uses `AbortController` for explicit timeout handling
- Implements exponential backoff: `delay = retryDelayMs * 2^attempt`
- Logs each retry attempt with details
- Returns response on success or throws error after all retries exhausted

**Retry Behavior**:
- Attempt 1: Immediate (0ms delay)
- Attempt 2: 1000ms delay
- Attempt 3: 2000ms delay
- Attempt 4: 4000ms delay (if maxRetries > 2)

### 4. Updated LLM API Call
**File**: `src/agents/llm.ts`

Changed from direct `fetch()` call to `this.fetchWithRetry()`:
- Added retry configuration to debug logs
- Now uses resilient fetch with timeout and retry logic

### 5. Agent Factory Configuration
**File**: `src/routes/agent-factory.ts`

Updated both `useLiteLLM()` and `useDeepseek()` functions to pass retry configuration:
```typescript
maxRetries: 2,
retryDelayMs: 1000,
timeoutMs: 30000,
```

## How It Works

### Success Case
```
Request → Response OK → Process → Done
```

### Transient Failure Case (Recovers)
```
Request → Timeout
  ↓
Wait 1s
  ↓
Request → Response OK → Process → Done
```

### Persistent Failure Case (All Retries Exhausted)
```
Request → Timeout
  ↓
Wait 1s
  ↓
Request → Timeout
  ↓
Wait 2s
  ↓
Request → Timeout
  ↓
Error: "Fetch failed after retries" → RunErrorEvent
```

## Logging Output

### Normal Request
```
INFO: Sending request to LLM API
  maxRetries: 2
  timeoutMs: 30000

INFO: Received successful response from LLM API
```

### Request with Retry
```
INFO: Sending request to LLM API
  maxRetries: 2
  timeoutMs: 30000

WARN: Fetch failed, retrying with exponential backoff
  attempt: 1
  maxRetries: 2
  delayMs: 1000
  error: "fetch failed"

INFO: Received successful response from LLM API
```

### Request that Fails After All Retries
```
INFO: Sending request to LLM API
  maxRetries: 2
  timeoutMs: 30000

WARN: Fetch failed, retrying with exponential backoff
  attempt: 1
  maxRetries: 2
  delayMs: 1000
  error: "fetch failed"

WARN: Fetch failed, retrying with exponential backoff
  attempt: 2
  maxRetries: 2
  delayMs: 2000
  error: "fetch failed"

ERROR: LLM agent error - detailed information
  errorMessage: "Fetch failed after retries"
  errorName: "Error"
```

## Testing

### Test the Retry Logic

1. **Start server**:
   ```bash
   pnpm run dev --use-llm
   ```

2. **Make a request** (via iOS app or curl):
   ```bash
   curl -X POST http://localhost:3000/agent \
     -H "Content-Type: application/json" \
     -d '{
       "threadId": "test-123",
       "runId": "run-456",
       "messages": [{"role": "user", "content": "Hello"}],
       "tools": []
     }'
   ```

3. **Observe logs**:
   - Successful requests: Single "Received successful response" log
   - Transient failures: "Fetch failed, retrying" logs followed by success
   - Persistent failures: Multiple retry logs followed by error

### Simulate Timeout

To test timeout behavior with a short timeout:
```bash
LLM_TIMEOUT_MS=100 pnpm run dev --use-llm
```

This will likely trigger timeouts and retries since 100ms is very short.

## Configuration

### Default Configuration (No Changes Needed)
- 2 retries (3 total attempts)
- 1 second base delay
- 30 second timeout per attempt

### Custom Configuration

Modify `src/routes/agent-factory.ts`:
```typescript
return new LLMAgent({
  endpoint: 'https://api.deepseek.com/v1',
  apiKey: config.deepseekApiKey,
  model: config.deepseekModel || 'deepseek-chat',
  maxRetries: 3,           // More retries for unreliable networks
  retryDelayMs: 2000,      // Longer initial delay
  timeoutMs: 45000,        // Longer timeout for slow APIs
});
```

## Impact on Error Handling

### Before
- Single fetch attempt
- Any network error → immediate failure
- Client receives error within 1-2 seconds

### After
- Up to 3 fetch attempts (default)
- Transient errors → automatic retry with backoff
- Client receives error only after all retries exhausted (up to ~3 seconds)
- Better success rate for transient failures

## Files Modified

1. `src/agents/llm.ts`
   - Added LLMConfig properties
   - Added retry configuration to constructor
   - Added fetchWithRetry method
   - Updated fetch call to use fetchWithRetry

2. `src/routes/agent-factory.ts`
   - Added retry configuration to useLiteLLM
   - Added retry configuration to useDeepseek

## Files Created

1. `RESILIENCE_IMPROVEMENTS.md` - Comprehensive documentation
2. `FETCH_RESILIENCE_SUMMARY.md` - This file

## Next Steps

1. **Deploy and Monitor**: Track retry rates and success metrics
2. **Adjust Timeouts**: If timeout errors persist, increase `timeoutMs`
3. **Circuit Breaker**: If retry rate remains high, implement circuit breaker
4. **Fallback Mode**: Consider falling back to scenario mode on repeated failures
