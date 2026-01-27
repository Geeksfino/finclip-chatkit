/**
 * Structured logger using Pino
 */

import pino, { type LoggerOptions } from 'pino';
import { loadConfig } from './config.js';

const config = loadConfig();

export const loggerOptions: LoggerOptions = {
  level: config.logLevel,
  transport: config.logPretty
    ? {
        target: 'pino-pretty',
        options: {
          colorize: true,
          translateTime: 'HH:MM:ss Z',
          ignore: 'pid,hostname',
        },
      }
    : undefined,
};

export const logger = pino(loggerOptions);
