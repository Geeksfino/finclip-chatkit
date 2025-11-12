# AG-UI Test Server - Resilience Improvements

## Overview

This document describes the resilience improvements made to handle intermittent "fetch failed" errors when communicating with LLM providers (DeepSeek, LiteLLM).

## Problem Statement

The server was experiencing intermittent `TypeError: fetch failed` errors when calling the LLM API. These errors occurred randomly after successful requests, indicating transient network or API connectivity issues.

### Error Pattern
- **Error**: `TypeError: fetch failed`
- **Frequency**: Intermittent (not consistent)
- **Location**: `LLMAgent.run()` → fetch call to LLM API
- **Root Causes**:
  - Network timeouts (no response within default timeout)
  - API rate limiting (connection dropped without HTTP response)
  - Transient network connectivity issues
  - API service temporarily unavailable

## Solutions Implemented

### 1. Timeout Configuration

**Problem**: The original fetch call had no explicit timeout, relying on undici's default (unbounded).

**Solution**: Added explicit timeout using `AbortController`:
- Default: 30 seconds
- Configurable via `LLMConfig.timeoutMs`
- Aborts request if no response received within timeout

```typescript
const controller = new AbortController();
const timeoutId = setTimeout(() => controller.abort(), this.timeoutMs);
const response = await fetch(url, {
  ...options,
  signal: controller.signal,
});
```

**Benefits**:
- Fails fast on unresponsive APIs
- Prevents hanging requests
- Allows retry logic to kick in sooner

### 2. Retry Logic with Exponential Backoff

**Problem**: Single attempt meant any transient error resulted in immediate failure.

**Solution**: Implemented `fetchWithRetry()` method with exponential backoff:
- Default: 2 retries (3 total attempts)
- Delay: 1000ms base, multiplied by 2^attempt
  - Attempt 1: 1000ms
  - Attempt 2: 2000ms
  - Attempt 3: 4000ms (if configured)
- Configurable via `LLMConfig.maxRetries` and `LLMConfig.retryDelayMs`

```typescript
for (let attempt = 0; attempt <= this.maxRetries; attempt++) {
  try {
    return await fetch(url, options);
  } catch (error) {
    if (attempt < this.maxRetries) {
      const delayMs = this.retryDelayMs * Math.pow(2, attempt);
      await new Promise(resolve => setTimeout(resolve, delayMs));
    }
  }
}
```

**Benefits**:
- Handles transient failures automatically
- Exponential backoff prevents overwhelming the API
- Logged for debugging and monitoring

### 3. Enhanced Logging

**What's Logged**:
- Initial request with retry configuration
- Each retry attempt with delay and error details
- Final success or failure

**Example Log Output**:
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

## Configuration

### Environment Variables

Add to `.env` to customize retry behavior:

```env
# LLM Retry Configuration (optional)
LLM_MAX_RETRIES=2           # Number of retries (default: 2)
LLM_RETRY_DELAY_MS=1000     # Base retry delay in ms (default: 1000)
LLM_TIMEOUT_MS=30000        # Request timeout in ms (default: 30000)
```

### Programmatic Configuration

When creating an `LLMAgent`:

```typescript
new LLMAgent({
  endpoint: 'https://api.deepseek.com/v1',
  apiKey: 'sk-...',
  model: 'deepseek-chat',
  maxRetries: 2,           // Retry up to 2 times
  retryDelayMs: 1000,      // Start with 1 second delay
  timeoutMs: 30000,        // 30 second timeout per attempt
});
```

## Behavior

### Success Case
1. Request sent with 30s timeout
2. Response received within timeout
3. Processing continues normally

### Transient Failure Case
1. Request sent with 30s timeout
2. Timeout or connection error occurs
3. Wait 1 second, retry (attempt 2)
4. Response received on retry
5. Processing continues normally

### Persistent Failure Case
1. Request sent with 30s timeout
2. Timeout or connection error occurs
3. Wait 1 second, retry (attempt 2)
4. Timeout or connection error occurs again
5. Wait 2 seconds, retry (attempt 3)
6. Timeout or connection error occurs again
7. Error logged and propagated to client
8. Client receives `RunErrorEvent`

## Metrics & Monitoring

### What to Monitor

1. **Retry Rate**: How often retries are triggered
   - Healthy: < 5% of requests
   - Warning: 5-20% of requests
   - Critical: > 20% of requests

2. **Success Rate After Retry**: How many retries succeed
   - Healthy: > 90% succeed on first retry
   - Warning: 50-90% succeed on first retry
   - Critical: < 50% succeed on first retry

3. **Timeout Frequency**: How often timeouts occur
   - Indicates API latency issues
   - May require increasing `timeoutMs`

### Log Analysis

Search logs for retry indicators:
```bash
# Find all retry attempts
grep "Fetch failed, retrying" logs/*.log

# Count retries by error type
grep "Fetch failed, retrying" logs/*.log | grep -o "error: \"[^\"]*\"" | sort | uniq -c

# Find requests that failed after all retries
grep "Fetch failed after retries" logs/*.log
```

## Future Improvements

### 1. Circuit Breaker Pattern
Stop retrying if API is consistently failing:
```typescript
// After N consecutive failures, stop retrying for M seconds
if (consecutiveFailures > 5) {
  throw new CircuitBreakerOpenError();
}
```

### 2. Adaptive Timeout
Adjust timeout based on historical response times:
```typescript
// If 95th percentile response time is 20s, set timeout to 25s
const adaptiveTimeout = calculateP95ResponseTime() * 1.25;
```

### 3. Fallback to Scenario Mode
When LLM API is unavailable, fall back to emulated responses:
```typescript
if (circuitBreakerOpen) {
  logger.warn('LLM API unavailable, falling back to scenario mode');
  return new ScenarioAgent(scenario);
}
```

### 4. Connection Pooling
Reuse HTTP connections to reduce overhead:
```typescript
const agent = new http.Agent({ keepAlive: true, maxSockets: 10 });
fetch(url, { agent });
```

### 5. Metrics Collection
Track success rates, latencies, and retry patterns:
```typescript
metrics.recordRetry(attempt, delayMs, error);
metrics.recordSuccess(latencyMs);
metrics.recordFailure(error);
```

## Testing

### Manual Testing

1. **Test timeout handling**:
   ```bash
   # Start server with short timeout
   LLM_TIMEOUT_MS=100 pnpm run dev --use-llm
   # Should see timeout errors and retries
   ```

2. **Test retry logic**:
   ```bash
   # Start server with multiple retries
   LLM_MAX_RETRIES=3 pnpm run dev --use-llm
   # Make requests and observe retry logs
   ```

3. **Test with mock server**:
   ```bash
   # Use LiteLLM pointing to local mock server
   LITELLM_ENDPOINT=http://localhost:8000/v1 pnpm run dev --use-llm
   # Mock server can simulate failures/timeouts
   ```

### Automated Testing

See `tests/` directory for unit tests covering:
- `fetchWithRetry` with successful response
- `fetchWithRetry` with timeout
- `fetchWithRetry` with transient failures
- `fetchWithRetry` with persistent failures
- Exponential backoff calculation

## Rollout Plan

1. **Phase 1**: Deploy with default settings (2 retries, 1s base delay, 30s timeout)
2. **Phase 2**: Monitor metrics for 1 week
3. **Phase 3**: Adjust based on metrics (increase timeout if needed, etc.)
4. **Phase 4**: Implement circuit breaker if retry rate remains high

## References

- [MDN: AbortController](https://developer.mozilla.org/en-US/docs/Web/API/AbortController)
- [Exponential Backoff](https://en.wikipedia.org/wiki/Exponential_backoff)
- [Circuit Breaker Pattern](https://martinfowler.com/bliki/CircuitBreaker.html)
- [undici Documentation](https://undici.nodejs.org/)
