/**
 * A2UI Proxy - Fetches JSONL stream from a2ui-test-server
 * Maps a2ui-test-server message format to A2UIPayloadWire
 */

import { A2UI_CONSTANTS } from '../constants.js';
import type { A2UIPayloadWire } from '../types/agui.js';
import { logger } from '../utils/logger.js';

const A2UI_MSG_KEYS = ['beginRendering', 'surfaceUpdate', 'dataModelUpdate', 'deleteSurface'] as const;

/**
 * Map a2ui-test-server message to A2UIPayloadWire
 * Input: { beginRendering: {...} } | { surfaceUpdate: {...} } | ...
 * Output: { type: "beginRendering", payload: {...} }
 */
function mapToA2UIPayloadWire(obj: Record<string, unknown>): A2UIPayloadWire | null {
  for (const key of A2UI_MSG_KEYS) {
    if (key in obj && typeof obj[key] === 'object') {
      return {
        type: key as A2UIPayloadWire['type'],
        payload: obj[key] as Record<string, unknown>,
      };
    }
  }
  return null;
}

/**
 * Parse JSONL SSE stream line
 * Lines: "data: {json}\n\n" or "retry: 3000\n\n"
 */
function parseJSONLLine(line: string): Record<string, unknown> | null {
  const trimmed = line.trim();
  if (!trimmed.startsWith('data: ')) return null;
  const jsonStr = trimmed.slice(6).trim();
  if (!jsonStr) return null;
  try {
    return JSON.parse(jsonStr) as Record<string, unknown>;
  } catch {
    return null;
  }
}

/**
 * Input for A2UI proxy - used to build A2A Message request body
 */
export interface A2UIProxyRequest {
  message: string;
  threadId?: string;
  runId?: string;
  surfaceId?: string;
  metadata?: Record<string, unknown>;
}

/**
 * Build A2A Message request body (A2UI v0.8 compliant)
 */
function buildA2AMessageBody(request: A2UIProxyRequest): Record<string, unknown> {
  const metadata: Record<string, unknown> = {
    ...(request.metadata ?? {}),
    surfaceId: request.surfaceId ?? A2UI_CONSTANTS.DEFAULT_SURFACE_ID,
  };
  if (request.threadId != null) metadata.threadId = request.threadId;
  if (request.runId != null) metadata.runId = request.runId;

  return {
    metadata: Object.keys(metadata).length > 0 ? metadata : undefined,
    message: {
      prompt: {
        text: request.message,
      },
    },
  };
}

/**
 * Stream A2UI payloads from a2ui-test-server
 * Sends A2A Message format (A2UI v0.8) and yields A2UIPayloadWire for each valid message
 */
export async function* streamA2UIPayloads(
  baseUrl: string,
  request: A2UIProxyRequest,
  timeoutMs: number
): AsyncGenerator<A2UIPayloadWire> {
  const url = `${baseUrl.replace(/\/$/, '')}${A2UI_CONSTANTS.AGENT_PATH}`;
  const controller = new AbortController();
  const timeoutId = setTimeout(() => controller.abort(), timeoutMs);
  const body = buildA2AMessageBody(request);

  try {
    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body),
      signal: controller.signal,
    });

    clearTimeout(timeoutId);

    if (!response.ok) {
      const text = await response.text();
      throw new Error(`A2UI server error ${response.status}: ${text}`);
    }

    const reader = response.body?.getReader();
    if (!reader) throw new Error('No response body');

    const decoder = new TextDecoder();
    let buffer = '';

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      buffer += decoder.decode(value, { stream: true });
      const lines = buffer.split('\n');
      buffer = lines.pop() || '';

      for (const line of lines) {
        if (line.startsWith('data: ')) {
          const obj = parseJSONLLine(line);
          if (obj) {
            const payload = mapToA2UIPayloadWire(obj);
            if (payload) {
              yield payload;
            } else {
              logger.debug({ obj }, 'A2UI: skip unmapped message');
            }
          }
        }
      }
    }

    if (buffer.trim().startsWith('data: ')) {
      const obj = parseJSONLLine(buffer);
      if (obj) {
        const payload = mapToA2UIPayloadWire(obj);
        if (payload) yield payload;
      }
    }
  } finally {
    clearTimeout(timeoutId);
  }
}
