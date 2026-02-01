/**
 * Health endpoint tests
 */

import { describe, it, expect } from 'vitest';
import Fastify from 'fastify';
import { healthRoute, setSessionCountGetter } from '../src/routes/health.js';

async function buildTestApp() {
  const app = Fastify();
  setSessionCountGetter(() => 2); // mock session count
  await app.register(healthRoute);
  return app;
}

describe('GET /health', () => {
  it('should return status ok', async () => {
    const app = await buildTestApp();
    const res = await app.inject({ method: 'GET', url: '/health' });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.payload);
    expect(body.status).toBe('ok');
  });

  it('should include timestamp, uptime, sessions, version', async () => {
    const app = await buildTestApp();
    const res = await app.inject({ method: 'GET', url: '/health' });
    const body = JSON.parse(res.payload);

    expect(body).toHaveProperty('timestamp');
    expect(body).toHaveProperty('uptime');
    expect(typeof body.uptime).toBe('number');
    expect(body.sessions).toBe(2);
    expect(body).toHaveProperty('version');
  });
});
