/**
 * JWT Validation Middleware
 * Only active when REQUIRE_JWT env var is truthy.
 * Performs basic format validation and payload decoding (no signature verification).
 */

import { FastifyRequest, FastifyReply } from 'fastify';

export async function jwtMiddleware(request: FastifyRequest, reply: FastifyReply) {
  if (!process.env.REQUIRE_JWT) return;

  const auth = request.headers.authorization;
  if (!auth || !auth.startsWith('Bearer ')) {
    reply.code(401).send({ error: 'Missing or invalid Authorization header' });
    return;
  }

  const token = auth.substring(7);
  if (!token || !token.includes('.')) {
    reply.code(401).send({ error: 'Invalid JWT format' });
    return;
  }

  try {
    const payload = JSON.parse(Buffer.from(token.split('.')[1], 'base64').toString());
    if (!payload.sub) {
      reply.code(401).send({ error: 'JWT missing sub claim' });
      return;
    }
    (request as any).jwtPayload = payload;
  } catch {
    reply.code(401).send({ error: 'Failed to decode JWT' });
    return;
  }
}
