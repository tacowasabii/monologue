import type { APIRoute } from 'astro';
import { handleDelete, handleGet } from '../../../lib/share/handlers';
import { withStore } from '../../../lib/share/instance';

export const prerender = false;

export const GET: APIRoute = ({ params }) => withStore((store) => handleGet(params.id ?? '', store));

export const DELETE: APIRoute = ({ params, request }) =>
  withStore((store) => handleDelete(params.id ?? '', request, store));
