/**
 * SSE stream parser for LLM chat completion responses
 */

import { getErrorMessage } from '../../utils/helpers.js';
import { logger } from '../../utils/logger.js';
import type { ChatCompletionChunk } from './types.js';

/**
 * Parse OpenAI-compatible SSE stream and yield ChatCompletionChunk
 */
export async function* parseSSEStream(
  body: ReadableStream<Uint8Array>
): AsyncGenerator<ChatCompletionChunk> {
  const reader = body.getReader();
  const decoder = new TextDecoder();
  let buffer = '';
  let chunkCount = 0;

  try {
    while (true) {
      const { done, value } = await reader.read();
      if (done) {
        logger.debug({ chunkCount }, 'Finished parsing SSE stream');
        break;
      }

      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split('\n');
      buffer = lines.pop() || '';

      for (const line of lines) {
        if (line.startsWith('data: ')) {
          const data = line.slice(6);
          if (data === '[DONE]') {
            logger.debug('Received [DONE] marker from SSE stream');
            continue;
          }

          try {
            const chunk = JSON.parse(data) as ChatCompletionChunk;
            chunkCount++;
            yield chunk;
          } catch (error) {
            logger.warn(
              { line, error: getErrorMessage(error) },
              'Failed to parse SSE chunk'
            );
          }
        }
      }
    }
  } catch (error) {
    logger.error(
      {
        error: getErrorMessage(error),
        stack: error instanceof Error ? error.stack : undefined,
        chunkCount,
      },
      'Error while parsing SSE stream'
    );
    throw error;
  } finally {
    reader.releaseLock();
  }
}
