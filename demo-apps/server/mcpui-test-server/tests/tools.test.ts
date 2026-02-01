/**
 * Tools list endpoint tests
 */

import { describe, it, expect } from 'vitest';
import Fastify from 'fastify';
import { toolsRoute } from '../src/routes/tools.js';

describe('GET /tools', () => {
  it('should return tools array', async () => {
    const app = Fastify();
    await app.register(toolsRoute);

    const res = await app.inject({ method: 'GET', url: '/tools' });

    expect(res.statusCode).toBe(200);
    const body = JSON.parse(res.payload);
    expect(body).toHaveProperty('tools');
    expect(Array.isArray(body.tools)).toBe(true);
  });

  it('should include expected HTML tools', async () => {
    const app = Fastify();
    await app.register(toolsRoute);

    const res = await app.inject({ method: 'GET', url: '/tools' });
    const body = JSON.parse(res.payload);
    const tools: string[] = body.tools;

    expect(tools).toContain('showSimpleHtml');
    expect(tools).toContain('showRawHtml');
    expect(tools).toContain('showInteractiveForm');
    expect(tools).toContain('showComplexLayout');
  });
});
