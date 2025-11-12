export interface ServerConfig {
  port: number;
  host: string;
  name: string;
  version: string;
  corsOrigin: string;
  sessionTimeout: number;
}

export interface MCPSession {
  sessionId: string;
  createdAt: Date;
  lastActivity: Date;
}

export interface ToolScenario {
  id: string;
  name: string;
  description: string;
  tool: string;
  params: Record<string, unknown>;
  expected?: {
    mimeType?: string;
    uriPrefix?: string;
    hasMetadata?: boolean;
  };
}

export interface HealthStatus {
  status: 'ok' | 'error';
  timestamp: string;
  uptime: number;
  sessions: number;
  version: string;
}
