/**
 * A2UI Unit Tests
 * Covers: extractA2UIForwardedProps, createA2UICustomEvent, streamA2UIPayloads, A2UIAgent
 */

import { describe, it, expect, vi, beforeEach, afterEach } from 'vitest';
import { EventType } from '@ag-ui/core';
import {
  extractA2UIForwardedProps,
  createA2UICustomEvent,
} from '../src/a2ui/utils.js';
import { streamA2UIPayloads } from '../src/a2ui/index.js';
import { A2UIAgent } from '../src/agents/a2ui.js';
import type { RunAgentInput } from '@ag-ui/core';
import { CUSTOM_EVENT_NAMES } from '../src/constants.js';

describe('extractA2UIForwardedProps', () => {
  it('should return empty object for null/undefined', () => {
    expect(extractA2UIForwardedProps(null)).toEqual({});
    expect(extractA2UIForwardedProps(undefined)).toEqual({});
  });

  it('should return empty object for non-object', () => {
    expect(extractA2UIForwardedProps('string')).toEqual({});
    expect(extractA2UIForwardedProps(123)).toEqual({});
  });

  it('should extract a2uiClientCapabilities as metadata', () => {
    const caps = { supportedCatalogIds: ['a2ui-v1'] };
    const result = extractA2UIForwardedProps({
      a2uiClientCapabilities: caps,
    });
    expect(result.metadata).toEqual({ a2uiClientCapabilities: caps });
  });

  it('should extract surfaceId when string', () => {
    const result = extractA2UIForwardedProps({ surfaceId: 'custom-surface' });
    expect(result.surfaceId).toBe('custom-surface');
  });

  it('should ignore non-string surfaceId', () => {
    const result = extractA2UIForwardedProps({ surfaceId: 123 });
    expect(result.surfaceId).toBeUndefined();
  });

  it('should extract both metadata and surfaceId', () => {
    const result = extractA2UIForwardedProps({
      a2uiClientCapabilities: { foo: 1 },
      surfaceId: 'main',
    });
    expect(result.metadata).toEqual({ a2uiClientCapabilities: { foo: 1 } });
    expect(result.surfaceId).toBe('main');
  });
});

describe('createA2UICustomEvent', () => {
  it('should create CUSTOM event with correct name', () => {
    const evt = createA2UICustomEvent('thread-1', {
      type: 'surfaceUpdate',
      payload: { surfaceId: 'main', components: [] },
    });
    expect(evt.type).toBe(EventType.CUSTOM);
    expect(evt.name).toBe(CUSTOM_EVENT_NAMES.A2UI);
  });

  it('should include sessionId and a2uiPayloads', () => {
    const payload = { type: 'beginRendering' as const, payload: { surfaceId: 'main', root: 'comp-1' } };
    const evt = createA2UICustomEvent('thread-xyz', payload);
    expect((evt as any).value).toEqual({
      sessionId: 'thread-xyz',
      a2uiPayloads: [payload],
    });
  });
});

describe('streamA2UIPayloads', () => {
  const originalFetch = globalThis.fetch;

  beforeEach(() => {
    vi.stubGlobal(
      'fetch',
      vi.fn((url: string, opts?: RequestInit) => {
        const body = opts?.body as string;
        const parsed = body ? JSON.parse(body) : {};
        const message = parsed?.message?.prompt?.text ?? '';
        const surfaceId = parsed?.metadata?.surfaceId ?? 'main';

        const jsonl =
          `data: {"surfaceUpdate":{"surfaceId":"${surfaceId}","components":[]}}\n` +
          `data: {"dataModelUpdate":{"surfaceId":"${surfaceId}","data":{}}}\n` +
          `data: {"beginRendering":{"surfaceId":"${surfaceId}","root":"root-1"}}\n`;

        const stream = new ReadableStream({
          start(controller) {
            controller.enqueue(new TextEncoder().encode(jsonl));
            controller.close();
          },
        });

        return Promise.resolve(
          new Response(stream, {
            status: 200,
            headers: { 'Content-Type': 'application/json' },
          })
        );
      })
    );
  });

  afterEach(() => {
    vi.stubGlobal('fetch', originalFetch);
  });

  it('should yield A2UIPayloadWire for each valid message', async () => {
    const payloads: unknown[] = [];
    for await (const p of streamA2UIPayloads(
      'http://localhost:3200',
      { message: 'hello', threadId: 't1', runId: 'r1' },
      5000
    )) {
      payloads.push(p);
    }

    expect(payloads.length).toBe(3);
    expect(payloads[0]).toEqual({
      type: 'surfaceUpdate',
      payload: { surfaceId: 'main', components: [] },
    });
    expect(payloads[1]).toEqual({
      type: 'dataModelUpdate',
      payload: { surfaceId: 'main', data: {} },
    });
    expect(payloads[2]).toEqual({
      type: 'beginRendering',
      payload: { surfaceId: 'main', root: 'root-1' },
    });
  });

  it('should use DEFAULT_SURFACE_ID when not provided', async () => {
    const payloads: unknown[] = [];
    for await (const p of streamA2UIPayloads(
      'http://localhost:3200',
      { message: 'test' },
      5000
    )) {
      payloads.push(p);
    }
    expect((payloads[0] as any).payload.surfaceId).toBe('main');
  });

  it('should throw on non-2xx response', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(() =>
        Promise.resolve(new Response('Server Error', { status: 500 }))
      )
    );

    await expect(
      (async () => {
        for await (const _ of streamA2UIPayloads(
          'http://localhost:3200',
          { message: 'x' },
          5000
        )) {
          // consume
        }
      })()
    ).rejects.toThrow(/A2UI server error 500/);
  });
});

describe('A2UIAgent', () => {
  const originalFetch = globalThis.fetch;

  beforeEach(() => {
    const jsonl =
      'data: {"surfaceUpdate":{"surfaceId":"main","components":[]}}\n' +
      'data: {"beginRendering":{"surfaceId":"main","root":"root-1"}}\n';

    vi.stubGlobal(
      'fetch',
      vi.fn(() =>
        Promise.resolve(
          new Response(new ReadableStream({
            start(c) {
              c.enqueue(new TextEncoder().encode(jsonl));
              c.close();
            },
          }), { status: 200 })
        )
      )
    );
  });

  afterEach(() => {
    vi.stubGlobal('fetch', originalFetch);
  });

  it('should yield RUN_STARTED, CUSTOM (a2ui), RUN_FINISHED', async () => {
    const agent = new A2UIAgent({
      serverUrl: 'http://localhost:3200',
      timeoutMs: 5000,
    });

    const input: RunAgentInput = {
      threadId: 'thread-1',
      runId: 'run-1',
      messages: [{ id: 'm1', role: 'user', content: 'show form' }],
      tools: [],
      context: [],
      state: null,
      forwardedProps: null,
    };

    const events: { type: string; name?: string }[] = [];
    for await (const e of agent.run(input)) {
      events.push({ type: e.type, name: (e as any).name });
    }

    expect(events[0]?.type).toBe(EventType.RUN_STARTED);
    expect(events[events.length - 1]?.type).toBe(EventType.RUN_FINISHED);

    const customEvents = events.filter((e) => e.type === EventType.CUSTOM && e.name === CUSTOM_EVENT_NAMES.A2UI);
    expect(customEvents.length).toBe(2);
  });

  it('should use last user message as prompt', async () => {
    const agent = new A2UIAgent({
      serverUrl: 'http://localhost:3200',
      timeoutMs: 5000,
    });

    const input: RunAgentInput = {
      threadId: 't',
      runId: 'r',
      messages: [
        { id: 'm0', role: 'user', content: 'first' },
        { id: 'm1', role: 'assistant', content: 'reply' },
        { id: 'm2', role: 'user', content: 'last message' },
      ],
      tools: [],
      context: [],
      state: null,
      forwardedProps: null,
    };

    let fetchBody: string | undefined;
    vi.stubGlobal(
      'fetch',
      vi.fn((_url: string, opts?: RequestInit) => {
        fetchBody = opts?.body as string;
        const jsonl = 'data: {"beginRendering":{"surfaceId":"main","root":"r1"}}\n';
        return Promise.resolve(
          new Response(new ReadableStream({
            start(c) {
              c.enqueue(new TextEncoder().encode(jsonl));
              c.close();
            },
          }), { status: 200 })
        );
      })
    );

    const events: unknown[] = [];
    for await (const e of agent.run(input)) {
      events.push(e);
    }

    const parsed = JSON.parse(fetchBody ?? '{}');
    expect(parsed.message?.prompt?.text).toBe('last message');
  });

  it('should yield RUN_ERROR when proxy fails', async () => {
    vi.stubGlobal(
      'fetch',
      vi.fn(() => Promise.reject(new Error('Network error')))
    );

    const agent = new A2UIAgent({
      serverUrl: 'http://invalid',
      timeoutMs: 100,
    });

    const input: RunAgentInput = {
      threadId: 't',
      runId: 'r',
      messages: [{ id: 'm1', role: 'user', content: 'x' }],
      tools: [],
      context: [],
      state: null,
      forwardedProps: null,
    };

    const events: { type: string; message?: string }[] = [];
    for await (const e of agent.run(input)) {
      events.push({ type: e.type, message: (e as any).message });
    }

    const errorEvt = events.find((e) => e.type === EventType.RUN_ERROR);
    expect(errorEvt).toBeDefined();
    expect(errorEvt?.message).toContain('Network error');
  });

  it('should pass forwardedProps to proxy', async () => {
    let capturedBody: Record<string, unknown> = {};
    vi.stubGlobal(
      'fetch',
      vi.fn((_url: string, opts?: RequestInit) => {
        capturedBody = JSON.parse((opts?.body as string) ?? '{}');
        const jsonl = 'data: {"beginRendering":{"surfaceId":"custom","root":"r1"}}\n';
        return Promise.resolve(
          new Response(new ReadableStream({
            start(c) {
              c.enqueue(new TextEncoder().encode(jsonl));
              c.close();
            },
          }), { status: 200 })
        );
      })
    );

    const agent = new A2UIAgent({
      serverUrl: 'http://localhost:3200',
      timeoutMs: 5000,
    });

    const input: RunAgentInput = {
      threadId: 't',
      runId: 'r',
      messages: [{ id: 'm1', role: 'user', content: 'x' }],
      tools: [],
      context: [],
      state: null,
      forwardedProps: {
        surfaceId: 'custom',
        a2uiClientCapabilities: { supportedCatalogIds: ['v1'] },
      },
    };

    for await (const _ of agent.run(input)) {
      // consume
    }

    expect(capturedBody.metadata).toMatchObject({
      surfaceId: 'custom',
      a2uiClientCapabilities: { supportedCatalogIds: ['v1'] },
    });
  });
});
