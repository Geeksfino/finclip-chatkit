import pino from 'pino';

const isPretty = process.env.LOG_PRETTY === 'true';

export const logger = pino({
  level: process.env.LOG_LEVEL || 'info',
  transport: isPretty
    ? {
        target: 'pino-pretty',
        options: {
          colorize: true,
          translateTime: 'HH:MM:ss',
          ignore: 'pid,hostname',
        },
      }
    : undefined,
});
