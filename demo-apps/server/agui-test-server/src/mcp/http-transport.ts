/**
 * HTTP-based MCP Client Transport
 */

import type { Transport } from '@modelcontextprotocol/sdk/shared/transport.js';
import type { JSONRPCMessage, JSONRPCRequest } from '@modelcontextprotocol/sdk/types.js';
import { logger } from '../utils/logger.js';
import { getErrorMessage } from '../utils/helpers.js';

function isJSONRPCRequest(message: JSONRPCMessage): message is JSONRPCRequest {
  return 'method' in message;
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
  private _sessionId?: string;
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

  async send(message: JSONRPCMessage): Promise<void> {
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

      const sessionId = response.headers.get('mcp-session-id');
      if (sessionId && !this._sessionId) {
        this._sessionId = sessionId;
        logger.info({ sessionId }, 'MCP session established via HTTP');
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
      this._sessionId = undefined;
    }

    if (this.onclose) {
      this.onclose();
    }
  }
}
