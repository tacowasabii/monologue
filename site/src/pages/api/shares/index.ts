import type { APIRoute } from 'astro';
import { handleCreate } from '../../../lib/share/handlers';
import { clientKey, withStore } from '../../../lib/share/instance';

export const prerender = false;

export const POST: APIRoute = (context) =>
  withStore((store) => handleCreate(context.request, store, clientKey(context.request, () => context.clientAddress)));
