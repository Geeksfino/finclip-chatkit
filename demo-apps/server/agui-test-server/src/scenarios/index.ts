/**
 * Scenario Registry
 */

import type { Scenario, ScenarioRegistry } from '../types/scenario.js';
import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import { logger } from '../utils/logger.js';

const __dirname = dirname(fileURLToPath(import.meta.url));

function loadScenario(filename: string): Scenario {
  const path = join(__dirname, filename);
  const content = readFileSync(path, 'utf-8');
  return JSON.parse(content);
}

export function loadScenarios(): ScenarioRegistry {
  const scenarios: ScenarioRegistry = {};

  try {
    scenarios['simple-chat'] = loadScenario('simple-chat.json');
    scenarios['tool-call'] = loadScenario('tool-call.json');
    scenarios['error-handling'] = loadScenario('error-handling.json');

    logger.info(
      { count: Object.keys(scenarios).length },
      'Loaded scenarios'
    );
  } catch (error) {
    logger.error({ error }, 'Failed to load scenarios');
  }

  return scenarios;
}

export function getScenario(scenarioId: string): Scenario | undefined {
  const scenarios = loadScenarios();
  return scenarios[scenarioId];
}

export function listScenarios(): Scenario[] {
  const scenarios = loadScenarios();
  return Object.values(scenarios);
}
