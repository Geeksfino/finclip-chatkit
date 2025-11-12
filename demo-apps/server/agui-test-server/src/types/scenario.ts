/**
 * Scenario Definition Types
 */

import type { BaseEvent } from '@ag-ui/core';

export interface ScenarioTrigger {
  userMessage?: string; // Regex pattern or "*" for any
  toolResult?: string;  // Tool name pattern
}

export interface ScenarioTurn {
  trigger: ScenarioTrigger;
  events: BaseEvent[];
  delayMs?: number;
}

export interface Scenario {
  id: string;
  name: string;
  description?: string;
  turns: ScenarioTurn[];
}

export interface ScenarioRegistry {
  [scenarioId: string]: Scenario;
}
