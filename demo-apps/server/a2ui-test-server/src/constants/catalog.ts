/**
 * A2UI v0.8 Catalog constants and negotiation
 * https://a2ui.org/specification/v0.8-a2ui/#21-catalog-negotiation
 */

/** Standard catalog ID for A2UI v0.8 (official spec) */
export const STANDARD_CATALOG_ID =
  'https://github.com/google/A2UI/blob/main/specification/v0_8/json/standard_catalog_definition.json';

/** Client capabilities from A2UI request metadata */
export interface A2UIClientCapabilities {
  supportedCatalogIds?: string[];
  inlineCatalogs?: unknown[];
}

/**
 * Select catalog ID based on client capabilities.
 * Per spec: if client supports standard catalog, use it; otherwise fallback to first supported or default.
 */
export function selectCatalog(
  capabilities?: A2UIClientCapabilities | null
): string {
  const supported = capabilities?.supportedCatalogIds ?? [];
  if (supported.includes(STANDARD_CATALOG_ID)) {
    return STANDARD_CATALOG_ID;
  }
  if (supported.length > 0) {
    return supported[0];
  }
  return STANDARD_CATALOG_ID;
}
