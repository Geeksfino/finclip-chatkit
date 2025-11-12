/**
 * Base Agent Interface
 */

import type { RunAgentInput, BaseEvent } from '@ag-ui/core';

/**
 * Core agent interface - all agents must implement this
 */
export interface AGUIAgent {
  /**
   * Run the agent with given input and yield AG-UI events
   */
  run(input: RunAgentInput): AsyncGenerator<BaseEvent>;
}

/**
 * Abstract base class with common utilities
 */
export abstract class BaseAgent implements AGUIAgent {
  abstract run(input: RunAgentInput): AsyncGenerator<BaseEvent>;

  /**
   * Helper to create a delay
   */
  protected async delay(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  /**
   * Helper to generate a unique message ID
   */
  protected generateMessageId(): string {
    return `msg_${Date.now()}_${Math.random().toString(36).substring(2, 10)}`;
  }

  /**
   * Helper to generate a unique tool call ID
   */
  protected generateToolCallId(): string {
    return `call_${Date.now()}_${Math.random().toString(36).substring(2, 10)}`;
  }
}
