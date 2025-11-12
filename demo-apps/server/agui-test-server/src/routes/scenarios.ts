/**
 * Scenario Management Endpoints
 */

import type { FastifyPluginAsync } from 'fastify';
import { listScenarios, getScenario } from '../scenarios/index.js';
import { ScenarioAgent } from '../agents/scenario.js';
import { SSEEncoder, streamEvents } from '../streaming/encoder.js';
import { generateRunId } from '../utils/validation.js';
import { loadConfig } from '../utils/config.js';
import { logger } from '../utils/logger.js';
import type { RunAgentInput } from '@ag-ui/core';

const config = loadConfig();

export const scenariosRoute: FastifyPluginAsync = async (fastify) => {
  // List all scenarios
  fastify.get('/scenarios', async (_request, _reply) => {
    const scenarios = listScenarios();
    return {
      scenarios: scenarios.map((s) => ({
        id: s.id,
        name: s.name,
        description: s.description,
        turnCount: s.turns.length,
      })),
    };
  });

  // Get scenario details
  fastify.get<{ Params: { id: string } }>(
    '/scenarios/:id',
    async (request, reply) => {
      const scenario = getScenario(request.params.id);
      if (!scenario) {
        return reply.status(404).send({ error: 'Scenario not found' });
      }
      return scenario;
    }
  );

  // Run a specific scenario
  fastify.post<{
    Params: { id: string };
    Body: Partial<RunAgentInput>;
  }>('/scenarios/:id', async (request, reply) => {
    const scenario = getScenario(request.params.id);
    if (!scenario) {
      return reply.status(404).send({ error: 'Scenario not found' });
    }

    const input: RunAgentInput = {
      threadId: request.body.threadId || `test_${Date.now()}`,
      runId: request.body.runId || generateRunId(),
      messages: request.body.messages || [],
      tools: request.body.tools || [],
      context: request.body.context || [],
      state: request.body.state || null,
      forwardedProps: request.body.forwardedProps || null,
    };

    logger.info(
      { scenarioId: scenario.id, threadId: input.threadId },
      'Running scenario via direct endpoint'
    );

    try {
      const encoder = new SSEEncoder(request.headers.accept);

      reply.raw.writeHead(200, {
        'Content-Type': encoder.getContentType(),
        'Cache-Control': 'no-cache',
        Connection: 'keep-alive',
      });

      reply.raw.write(SSEEncoder.retry(config.sseRetryMs));

      const agent = new ScenarioAgent(scenario, config.scenarioDelayMs);
      const events = agent.run(input);

      for await (const chunk of streamEvents(events, encoder)) {
        reply.raw.write(chunk);
      }

      reply.raw.end();
    } catch (error) {
      logger.error({ error, scenarioId: scenario.id }, 'Scenario execution failed');
      if (!reply.sent) {
        reply.status(500).send({
          error: 'Scenario execution failed',
          message: error instanceof Error ? error.message : 'Unknown error',
        });
      }
    }
  });
};
