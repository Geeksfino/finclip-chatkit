/**
 * HTTP-based MCP Client Transport
 *
 * MCP over Streamable HTTP requires the first request to be "initialize" (no session ID).
 * The server then returns mcp-session-id in the response header; all subsequent requests
 * must include that header. This transport ensures we send initialize first when we don't
 * yet have a session.
 */

import type { Transport } from '@modelcontextprotocol/sdk/shared/transport.js';
import type { JSONRPCMessage, JSONRPCRequest } from '@modelcontextprotocol/sdk/types.js';
import { logger } from '../utils/logger.js';
import { getErrorMessage } from '../utils/helpers.js';

const PACKAGE_NAME = 'agui-test-server';
const PACKAGE_VERSION = '1.0.0';

function isJSONRPCRequest(message: JSONRPCMessage): message is JSONRPCRequest {
  return 'method' in message;
}

function isInitializeRequest(message: JSONRPCMessage): boolean {
  return isJSONRPCRequest(message) && message.method === 'initialize';
}

/** Build the MCP initialize request (must be first request to establish session). */
function buildInitializeRequest(): Record<string, unknown> {
  return {
    jsonrpc: '2.0',
    id: 0,
    method: 'initialize',
    params: {
      protocolVersion: '2024-11-05',
      capabilities: {},
      clientInfo: { name: PACKAGE_NAME, version: PACKAGE_VERSION },
    },
  };
}

export interface HTTPClientTransportConfig {
  url: string;
  headers?: Record<string, string>;
  timeout?: number;
}

export class HTTPClientTransport implements Transport {
  private url: string;
  private headers: Record<string, string>;
  private timeout: number;
  private _sessionId: string | null = null;
  private abortController?: AbortController;

  onclose?: () => void;
  onerror?: (error: Error) => void;
  onmessage?: (message: JSONRPCMessage) => void;

  constructor(config: HTTPClientTransportConfig) {
    this.url = config.url;
    this.headers = config.headers || {};
    this.timeout = config.timeout || 30000;
  }

  async start(): Promise<void> {
    logger.debug({ url: this.url }, 'MCP HTTP transport ready');
  }

  /**
   * Send the MCP initialize request (no mcp-session-id) and store the session ID from the response.
   * Called automatically before the first non-initialize request when we don't have a session yet.
   */
  private async sendInitialize(): Promise<void> {
    const body = buildInitializeRequest();
    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      Accept: 'application/json',
      ...this.headers,
    };

    logger.debug({ url: this.url }, 'Sending MCP initialize request to establish session');

    const response = await fetch(this.url, {
      method: 'POST',
      headers,
      body: JSON.stringify(body),
    });

    let sessionId = response.headers.get('mcp-session-id') ?? response.headers.get('Mcp-Session-Id');
    if (!sessionId && response.ok) {
      const text = await response.text();
      try {
        const data = JSON.parse(text) as { result?: { sessionId?: string }; sessionId?: string };
        sessionId = data?.result?.sessionId ?? data?.sessionId ?? null;
      } catch {
        // ignore
      }
    }
    const sid: string | null =
      typeof sessionId === 'string' && sessionId !== '' ? sessionId : null;
    if (sid) {
      this._sessionId = sid;
      logger.info({ sessionId: sid }, 'MCP session established via HTTP (initialize)');
    }

    if (!response.ok) {
      const errorText = await response.text();
      throw new Error(`HTTP ${response.status}: ${response.statusText} - ${errorText}`);
    }
  }

  async send(message: JSONRPCMessage): Promise<void> {
    // MCP Streamable HTTP: first request must be "initialize" (no mcp-session-id).
    // If we don't have a session yet and this message is not initialize, send initialize first.
    if (!this._sessionId && !isInitializeRequest(message)) {
      await this.sendInitialize();
    }

    const headers: Record<string, string> = {
      'Content-Type': 'application/json',
      Accept: 'application/json, text/event-stream',
      ...this.headers,
    };

    if (this._sessionId) {
      headers['mcp-session-id'] = this._sessionId;
    }

    const abortController = new AbortController();
    this.abortController = abortController;
    const timeoutId = setTimeout(() => abortController.abort(), this.timeout);

    try {
      const method = isJSONRPCRequest(message) ? message.method : undefined;
      const id = 'id' in message ? message.id : undefined;

      logger.debug(
        { url: this.url, method, id, hasSessionId: !!this._sessionId },
        'Sending HTTP request to MCP server'
      );

      const response = await fetch(this.url, {
        method: 'POST',
        headers,
        body: JSON.stringify(message),
        signal: abortController.signal,
      });

      clearTimeout(timeoutId);

      let sessionId = response.headers.get('mcp-session-id') ?? response.headers.get('Mcp-Session-Id');
      if (!sessionId && !this._sessionId && response.ok) {
        const rawText = await response.clone().text();
        try {
          const data = JSON.parse(rawText) as { result?: { sessionId?: string }; sessionId?: string };
          sessionId = data?.result?.sessionId ?? data?.sessionId ?? null;
        } catch {
          // ignore
        }
      }
      const sid: string | null =
        typeof sessionId === 'string' && sessionId !== '' ? sessionId : null;
      if (sid && !this._sessionId) {
        this._sessionId = sid;
        logger.info({ sessionId: sid }, 'MCP session established via HTTP');
      }

      if (!response.ok) {
        const errorText = await response.text();
        throw new Error(`HTTP ${response.status}: ${response.statusText} - ${errorText}`);
      }

      const contentType = response.headers.get('content-type') || '';
      let responseData: JSONRPCMessage;

      if (contentType.includes('text/event-stream')) {
        const text = await response.text();
        const dataLines = text
          .split('\n')
          .filter((line) => line.startsWith('data: '))
          .map((line) => line.substring(6));

        if (dataLines.length > 0) {
          const jsonString = dataLines.join('\n');
          responseData = JSON.parse(jsonString);
          if (!this._sessionId) {
            try {
              const d = responseData as { result?: { sessionId?: string }; sessionId?: string };
              const sid = d?.result?.sessionId ?? d?.sessionId;
              if (sid) {
                this._sessionId = sid;
                logger.info({ sessionId: sid }, 'MCP session established via SSE response body');
              }
            } catch {
              // ignore
            }
          }
        } else if (text.trim() === '') {
          return;
        } else {
          throw new Error('Failed to parse SSE response: no data lines found');
        }
      } else {
        const text = await response.text();
        if (text.trim() === '') {
          return;
        }
        responseData = JSON.parse(text);
      }

      if (this.onmessage) {
        this.onmessage(responseData);
      }
    } catch (error) {
      clearTimeout(timeoutId);
      const method = isJSONRPCRequest(message) ? message.method : undefined;
      logger.error(
        { url: this.url, method, error: getErrorMessage(error) },
        'HTTP request to MCP server failed'
      );
      if (this.onerror) {
        this.onerror(error as Error);
      }
      throw error;
    }
  }

  async close(): Promise<void> {
    if (this.abortController) {
      this.abortController.abort();
    }

    if (this._sessionId) {
      try {
        await fetch(this.url, {
          method: 'DELETE',
          headers: { 'mcp-session-id': this._sessionId, ...this.headers },
        });
      } catch {
        // ignore
      }
      this._sessionId = null;
    }

    if (this.onclose) {
      this.onclose();
    }
  }
}
