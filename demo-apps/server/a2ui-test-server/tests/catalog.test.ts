/**
 * Catalog negotiation tests (A2UI v0.8)
 */

import { describe, it, expect } from 'vitest';
import { selectCatalog, STANDARD_CATALOG_ID } from '../src/constants/catalog.js';

describe('selectCatalog', () => {
  it('should return STANDARD_CATALOG_ID when client supports it', () => {
    const result = selectCatalog({
      supportedCatalogIds: [STANDARD_CATALOG_ID],
    });
    expect(result).toBe(STANDARD_CATALOG_ID);
  });

  it('should return STANDARD_CATALOG_ID when capabilities is undefined', () => {
    const result = selectCatalog(undefined);
    expect(result).toBe(STANDARD_CATALOG_ID);
  });

  it('should return STANDARD_CATALOG_ID when supportedCatalogIds is empty', () => {
    const result = selectCatalog({ supportedCatalogIds: [] });
    expect(result).toBe(STANDARD_CATALOG_ID);
  });

  it('should return first supported catalog when standard not in list', () => {
    const customCatalog = 'https://example.com/custom-catalog.json';
    const result = selectCatalog({
      supportedCatalogIds: [customCatalog, 'https://other.com/catalog.json'],
    });
    expect(result).toBe(customCatalog);
  });
});
