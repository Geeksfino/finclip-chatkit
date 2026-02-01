# AG-UI Test Server - Resilience (LLM Fetch)

## Overview

Handles intermittent "fetch failed" errors when communicating with LLM providers (DeepSeek, OpenAI, SiliconFlow, LiteLLM) via timeout, retry with exponential backoff, and structured logging.

## Configuration

### Environment Variables

```env
LLM_MAX_RETRIES=2           # Number of retries (default: 2)
LLM_RETRY_DELAY_MS=1000     # Base retry delay in ms (default: 1000)
LLM_TIMEOUT_MS=60000        # Request timeout in ms (default: 60000)
```

### Behavior

- **Timeout**: AbortController aborts request if no response within `LLM_TIMEOUT_MS`
- **Retry**: Up to `maxRetries` retries with exponential backoff (`delay = retryDelayMs * 2^attempt`)
- **Logging**: Each retry is logged; final success or failure is logged

## Related Files

- `src/agents/llm.ts` - `fetchWithRetry`, `LLMConfig`
- `src/routes/agent-factory.ts` - Passes retry config to LLMAgent
- `src/utils/config.ts` - Loads `LLM_*` env vars
