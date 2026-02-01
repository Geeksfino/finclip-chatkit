/**
 * Tool conversion utilities for LLM agent
 */

import type { Tool } from '@ag-ui/core';
import type { OpenAITool } from '../../mcp/types.js';
import { getErrorMessage } from '../../utils/helpers.js';
import { logger } from '../../utils/logger.js';
import type { ToolConversionResult } from './types.js';

export function sanitizeToolName(name: string, usedNames: Set<string>): string {
  const pattern = /[^a-zA-Z0-9_-]/g;
  const baseCandidate = name.replace(pattern, '_');
  const base = baseCandidate.length > 0 ? baseCandidate : 'tool';

  let finalName = base;
  let counter = 1;
  while (usedNames.has(finalName)) {
    counter++;
    finalName = `${base}_${counter}`;
  }

  usedNames.add(finalName);
  return finalName;
}

export function convertTools(tools: Tool[]): ToolConversionResult {
  const usedNames = new Set<string>();
  const sanitizedToOriginal = new Map<string, string>();
  const originalToSanitized = new Map<string, string>();

  const converted: OpenAITool[] = tools.map((tool, index) => {
    try {
      const sanitizedName = sanitizeToolName(tool.name, usedNames);
      sanitizedToOriginal.set(sanitizedName, tool.name);
      originalToSanitized.set(tool.name, sanitizedName);

      if (sanitizedName !== tool.name) {
        logger.debug(
          { originalName: tool.name, sanitizedName },
          'Sanitized tool name to comply with provider requirements'
        );
      }

      return {
        type: 'function' as const,
        function: {
          name: sanitizedName,
          description: tool.description,
          parameters: tool.parameters,
        },
      };
    } catch (error) {
      logger.error(
        {
          toolIndex: index,
          toolName: tool.name,
          error: getErrorMessage(error),
        },
        'Error converting tool to OpenAI format'
      );
      throw error;
    }
  });

  return {
    tools: converted,
    sanitizedToOriginal,
    originalToSanitized,
  };
}
