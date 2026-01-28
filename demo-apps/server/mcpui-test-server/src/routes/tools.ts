/**
 * Tools List Endpoint
 */

import type { FastifyPluginAsync } from 'fastify';

export const toolsRoute: FastifyPluginAsync = async (fastify) => {
  fastify.get('/tools', async (_request, _reply) => {
    return {
      tools: [
        'showSimpleHtml',
        'showRawHtml',
        'showInteractiveForm',
        'showComplexLayout',
        'showAnimatedContent',
        'showResponsiveCard',
        'showExampleSite',
        'showCustomUrl',
        'showApiDocs',
        'showRemoteDomButton',
        'showRemoteDomForm',
        'showRemoteDomChart',
        'showRemoteDomWebComponents',
        'showWithPreferredSize',
        'showWithRenderData',
        'showResponsiveLayout',
        'showAsyncToolCall',
        'showProgressIndicator',
      ],
    };
  });
};
