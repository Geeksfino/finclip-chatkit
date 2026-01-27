/**
 * Scenario types for A2UI test scenarios
 */

import type { A2UIMessage } from './a2ui.js';

/**
 * Scenario turn trigger
 */
export interface ScenarioTrigger {
  userMessage?: string; // Regex pattern or "*" for any
}

/**
 * Scenario turn - defines a response to a user message
 */
export interface ScenarioTurn {
  trigger: ScenarioTrigger;
  messages: A2UIMessage[];
  delayMs?: number;
}

/**
 * Scenario definition
 */
export interface Scenario {
  id: string;
  name: string;
  description?: string;
  turns: ScenarioTurn[];
}
