/**
 * A2UI Protocol v0.8 Message Types
 * Based on https://a2ui.org/specification/v0.8-a2ui/
 */

/**
 * beginRendering message - Signals the client to perform initial render
 */
export interface BeginRenderingMessage {
  beginRendering: {
    surfaceId: string;
    root: string;
    catalogId?: string;
    styles?: Record<string, unknown>;
  };
}

/**
 * Component definition in surfaceUpdate
 */
export interface ComponentDefinition {
  id: string;
  component: {
    [componentType: string]: unknown; // Text, Button, Row, Column, Card, etc.
  };
}

/**
 * surfaceUpdate message - Adds or updates components within a surface
 */
export interface SurfaceUpdateMessage {
  surfaceUpdate: {
    surfaceId: string;
    components: ComponentDefinition[];
  };
}

/**
 * Data entry in dataModelUpdate contents
 */
export interface DataEntry {
  key: string;
  valueString?: string;
  valueNumber?: number;
  valueBoolean?: boolean;
  valueMap?: DataEntry[];
}

/**
 * dataModelUpdate message - Updates the data model for a surface
 */
export interface DataModelUpdateMessage {
  dataModelUpdate: {
    surfaceId: string;
    path?: string;
    contents: DataEntry[];
  };
}

/**
 * deleteSurface message - Removes a surface from the UI
 */
export interface DeleteSurfaceMessage {
  deleteSurface: {
    surfaceId: string;
  };
}

/**
 * Union type for all A2UI messages
 */
export type A2UIMessage =
  | BeginRenderingMessage
  | SurfaceUpdateMessage
  | DataModelUpdateMessage
  | DeleteSurfaceMessage;

/**
 * Client-to-server message types
 */

/**
 * userAction message - Sent when user interacts with a component
 */
export interface UserActionMessage {
  userAction: {
    name: string;
    surfaceId: string;
    sourceComponentId: string;
    timestamp: string; // ISO 8601
    context: Record<string, unknown>;
  };
}

/**
 * error message - Sent when client encounters an error
 */
export interface ErrorMessage {
  error: {
    message: string;
    [key: string]: unknown;
  };
}

/**
 * Client event message (must contain exactly one of userAction or error)
 */
export type ClientEventMessage = UserActionMessage | ErrorMessage;

/**
 * A2A Message request format (client → server)
 * Per https://a2ui.org/specification/v0.8-a2ui/ and A2A Extension
 */
export interface A2AMessageRequest {
  metadata?: {
    a2uiClientCapabilities?: {
      supportedCatalogIds?: string[];
      inlineCatalogs?: unknown[];
    };
    surfaceId?: string;
    threadId?: string;
    runId?: string;
  };
  message: {
    prompt: {
      text: string;
    };
  };
}

/**
 * Normalized agent input (internal, used by agents)
 * Extracted from A2AMessageRequest
 */
export interface NormalizedAgentInput {
  message: string;
  surfaceId: string;
  metadata?: {
    a2uiClientCapabilities?: {
      supportedCatalogIds?: string[];
      inlineCatalogs?: unknown[];
    };
  };
  threadId?: string;
  runId?: string;
}

/** @deprecated Use NormalizedAgentInput - kept for agent signatures */
export type A2UIRequest = NormalizedAgentInput;
