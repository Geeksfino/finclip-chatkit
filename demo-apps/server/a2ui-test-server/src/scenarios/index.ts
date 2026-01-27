/**
 * Scenario loader and registry
 */

import { readFileSync } from 'fs';
import { join, dirname } from 'path';
import { fileURLToPath } from 'url';
import type { Scenario } from '../types/scenario.js';
import { logger } from '../utils/logger.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

/**
 * Load a scenario from JSON file
 */
export function loadScenario(scenarioId: string, scenarioDir: string): Scenario | null {
  try {
    const filePath = join(scenarioDir, `${scenarioId}.json`);
    const fileContent = readFileSync(filePath, 'utf-8');
    const scenario = JSON.parse(fileContent) as Scenario;
    
    logger.debug({ scenarioId, filePath }, 'Loaded scenario');
    return scenario;
  } catch (error) {
    logger.error(
      { scenarioId, error: error instanceof Error ? error.message : 'Unknown error' },
      'Failed to load scenario'
    );
    return null;
  }
}

/**
 * Load all scenarios from directory
 */
export function loadAllScenarios(scenarioDir: string): Map<string, Scenario> {
  const scenarios = new Map<string, Scenario>();
  
  try {
    const scenarioFiles = [
      'simple-ui',
      'form-ui',
      'interactive-ui',
    ];

    for (const scenarioId of scenarioFiles) {
      const scenario = loadScenario(scenarioId, scenarioDir);
      if (scenario) {
        scenarios.set(scenario.id, scenario);
      }
    }

    logger.info({ count: scenarios.size }, 'Loaded all scenarios');
  } catch (error) {
    logger.error(
      { error: error instanceof Error ? error.message : 'Unknown error' },
      'Failed to load scenarios'
    );
  }

  return scenarios;
}

/**
 * Get default scenario directory
 */
export function getDefaultScenarioDir(): string {
  return join(__dirname, '..', 'scenarios');
}
