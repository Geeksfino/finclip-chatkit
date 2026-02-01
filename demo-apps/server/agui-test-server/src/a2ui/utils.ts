/**
 * A2UI shared utilities - forwardedProps extraction, event helpers
 */

import { EventType } from '@ag-ui/core';
import type { BaseEvent } from '@ag-ui/core';
import { CUSTOM_EVENT_NAMES } from '../constants.js';
import type { A2UIPayloadWire } from '../types/agui.js';

export interface A2UIForwardedProps {
  metadata?: { a2uiClientCapabilities?: unknown };
  surfaceId?: string;
}

/**
 * Extract metadata and surfaceId from RunAgentInput.forwardedProps for A2UI requests
 */
export function extractA2UIForwardedProps(forwardedProps: unknown): A2UIForwardedProps {
  const fp = forwardedProps as Record<string, unknown> | null | undefined;
  if (!fp) return {};

  const metadata =
    fp.a2uiClientCapabilities != null
      ? { a2uiClientCapabilities: fp.a2uiClientCapabilities }
      : undefined;
  const surfaceId =
    typeof fp.surfaceId === 'string' ? fp.surfaceId : undefined;

  return { metadata, surfaceId };
}

/**
 * Create CUSTOM (a2ui) event for AG-UI stream
 */
export function createA2UICustomEvent(
  threadId: string,
  payload: A2UIPayloadWire
): BaseEvent {
  return {
    type: EventType.CUSTOM,
    name: CUSTOM_EVENT_NAMES.A2UI,
    value: {
      sessionId: threadId,
      a2uiPayloads: [payload],
    },
  } as BaseEvent;
}
