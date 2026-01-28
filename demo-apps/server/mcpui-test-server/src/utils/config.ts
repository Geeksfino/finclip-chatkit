/**
 * Configuration loader for MCP-UI Test Server
 */

import { config as loadEnv } from 'dotenv';
import type { ServerConfig } from '../types/index.js';

loadEnv();

export function loadConfig(): ServerConfig {
  return {
    port: parseInt(process.env.PORT || '3100', 10),
    host: process.env.HOST || '0.0.0.0',
    name: process.env.SERVER_NAME || 'mcpui-test-server',
    version: process.env.SERVER_VERSION || '1.0.0',
    corsOrigin: process.env.CORS_ORIGIN || '*',
    sessionTimeout: parseInt(process.env.SESSION_TIMEOUT || '3600000', 10),
    logLevel: process.env.LOG_LEVEL || 'info',
    logPretty: process.env.LOG_PRETTY !== 'false', // Default to pretty logging
  };
}

// Export singleton config instance
export const config = loadConfig();
