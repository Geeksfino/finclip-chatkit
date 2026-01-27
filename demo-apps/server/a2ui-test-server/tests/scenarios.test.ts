/**
 * Scenario Loading Tests
 */

import { describe, it, expect } from 'vitest';
import { loadScenario, loadAllScenarios, getDefaultScenarioDir } from '../src/scenarios/index.js';

describe('Scenario Loading', () => {
  it('should load simple-ui scenario', () => {
    const scenarioDir = getDefaultScenarioDir();
    const scenario = loadScenario('simple-ui', scenarioDir);

    expect(scenario).not.toBeNull();
    expect(scenario?.id).toBe('simple-ui');
    expect(scenario?.name).toBe('Simple UI');
    expect(scenario?.turns.length).toBeGreaterThan(0);
  });

  it('should load form-ui scenario', () => {
    const scenarioDir = getDefaultScenarioDir();
    const scenario = loadScenario('form-ui', scenarioDir);

    expect(scenario).not.toBeNull();
    expect(scenario?.id).toBe('form-ui');
    expect(scenario?.name).toBe('Form UI');
  });

  it('should load interactive-ui scenario', () => {
    const scenarioDir = getDefaultScenarioDir();
    const scenario = loadScenario('interactive-ui', scenarioDir);

    expect(scenario).not.toBeNull();
    expect(scenario?.id).toBe('interactive-ui');
    expect(scenario?.name).toBe('Interactive UI');
  });

  it('should return null for non-existent scenario', () => {
    const scenarioDir = getDefaultScenarioDir();
    const scenario = loadScenario('non-existent', scenarioDir);

    expect(scenario).toBeNull();
  });

  it('should load all scenarios', () => {
    const scenarioDir = getDefaultScenarioDir();
    const scenarios = loadAllScenarios(scenarioDir);

    expect(scenarios.size).toBeGreaterThan(0);
    expect(scenarios.has('simple-ui')).toBe(true);
    expect(scenarios.has('form-ui')).toBe(true);
    expect(scenarios.has('interactive-ui')).toBe(true);
  });

  it('should have valid scenario structure', () => {
    const scenarioDir = getDefaultScenarioDir();
    const scenario = loadScenario('simple-ui', scenarioDir);

    expect(scenario).not.toBeNull();
    if (scenario) {
      expect(scenario.id).toBeDefined();
      expect(scenario.name).toBeDefined();
      expect(Array.isArray(scenario.turns)).toBe(true);

      if (scenario.turns.length > 0) {
        const turn = scenario.turns[0];
        expect(turn.trigger).toBeDefined();
        expect(Array.isArray(turn.messages)).toBe(true);
      }
    }
  });
});
