/**
 * JSONL Encoder Tests
 */

import { describe, it, expect } from 'vitest';
import { JSONLEncoder } from '../src/streaming/jsonl-encoder.js';
import type { A2UIMessage } from '../src/types/a2ui.js';

describe('JSONLEncoder', () => {
  const encoder = new JSONLEncoder();

  it('should encode surfaceUpdate message', () => {
    const message: A2UIMessage = {
      surfaceUpdate: {
        surfaceId: 'main',
        components: [
          {
            id: 'root',
            component: {
              Column: {
                children: {
                  explicitList: ['text1'],
                },
              },
            },
          },
        ],
      },
    };

    const encoded = encoder.encode(message);
    expect(encoded).toContain('data: ');
    expect(encoded).toContain('surfaceUpdate');
    expect(encoded).toContain('surfaceId');
    expect(encoded).toContain('main');
  });

  it('should encode dataModelUpdate message', () => {
    const message: A2UIMessage = {
      dataModelUpdate: {
        surfaceId: 'main',
        contents: [
          {
            key: 'value',
            valueString: 'test',
          },
        ],
      },
    };

    const encoded = encoder.encode(message);
    expect(encoded).toContain('data: ');
    expect(encoded).toContain('dataModelUpdate');
    expect(encoded).toContain('value');
  });

  it('should encode beginRendering message', () => {
    const message: A2UIMessage = {
      beginRendering: {
        surfaceId: 'main',
        root: 'root',
      },
    };

    const encoded = encoder.encode(message);
    expect(encoded).toContain('data: ');
    expect(encoded).toContain('beginRendering');
    expect(encoded).toContain('root');
  });

  it('should encode deleteSurface message', () => {
    const message: A2UIMessage = {
      deleteSurface: {
        surfaceId: 'main',
      },
    };

    const encoded = encoder.encode(message);
    expect(encoded).toContain('data: ');
    expect(encoded).toContain('deleteSurface');
  });

  it('should return correct content type', () => {
    const contentType = encoder.getContentType();
    expect(contentType).toBe('text/event-stream; charset=utf-8');
  });

  it('should create SSE comment', () => {
    const comment = JSONLEncoder.comment('heartbeat');
    expect(comment).toBe(': heartbeat\n\n');
  });

  it('should create SSE retry directive', () => {
    const retry = JSONLEncoder.retry(3000);
    expect(retry).toBe('retry: 3000\n\n');
  });

  it('should create SSE event with type', () => {
    const message: A2UIMessage = {
      beginRendering: {
        surfaceId: 'main',
        root: 'root',
      },
    };

    const event = JSONLEncoder.event('a2ui', message);
    expect(event).toContain('event: a2ui');
    expect(event).toContain('data: ');
    expect(event).toContain('beginRendering');
  });
});
