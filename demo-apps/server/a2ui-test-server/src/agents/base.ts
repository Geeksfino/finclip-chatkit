/**
 * Base Agent class for A2UI agents
 * Provides common functionality for all agent implementations
 */

import type { A2UIRequest, A2UIMessage } from '../types/a2ui.js';

/**
 * Base class for all A2UI agents
 */
export abstract class BaseAgent {
  /**
   * Generate a unique message ID
   */
  protected generateMessageId(): string {
    return `msg_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
  }

  /**
   * Generate a unique component ID
   */
  protected generateComponentId(prefix: string = 'comp'): string {
    return `${prefix}_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
  }

  /**
   * Generate a unique surface ID
   */
  protected generateSurfaceId(prefix: string = 'surface'): string {
    return `${prefix}_${Date.now()}_${Math.random().toString(36).substring(2, 9)}`;
  }

  /**
   * Delay execution (for streaming simulation)
   */
  protected delay(ms: number): Promise<void> {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }

  /**
   * Abstract method to run the agent
   * Must be implemented by subclasses
   */
  abstract run(input: A2UIRequest): AsyncGenerator<A2UIMessage>;
}
