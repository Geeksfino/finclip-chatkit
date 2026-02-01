/**
 * Protocol and event name constants - single source of truth for maintainability
 */

import { createRequire } from 'node:module';

const require = createRequire(import.meta.url);
const pkg = require('../package.json') as { name: string; version: string };

/** Package name and version (from package.json) */
export const PACKAGE_NAME = pkg.name;
export const PACKAGE_VERSION = pkg.version;

/** AG-UI CUSTOM event names for extension payloads */
export const CUSTOM_EVENT_NAMES = {
  MCP_UI_RESOURCE: 'mcp-ui-resource',
  A2UI: 'a2ui',
} as const;

/** A2UI-related constants */
export const A2UI_CONSTANTS = {
  TOOL_NAME: 'generateA2UI',
  DEFAULT_SURFACE_ID: 'main',
  AGENT_PATH: '/agent',
} as const;
