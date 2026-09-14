import { json, shareUrl } from './http';
import { RateLimitedError, type ShareStore } from './store';
import { LIMITS, parseShareInput } from './validate';

export async function handleCreate(request: Request, store: ShareStore, clientKey: string): Promise<Response> {
  const contentType = (request.headers.get('content-type') ?? '').toLowerCase();
  // no-cors 요청은 브라우저가 이 헤더를 못 만들게 막아 두기 때문에, 요구하는 것만으로 크로스 사이트 업로드를 막는다
  if (!contentType.startsWith('application/json')) return json(415, { error: 'content_type' });

  if (Number(request.headers.get('content-length') ?? '0') > LIMITS.requestBytes) return json(413, { error: 'too_large' });
  const text = await request.text();
  if (new TextEncoder().encode(text).length > LIMITS.requestBytes) return json(413, { error: 'too_large' });

  let raw: unknown;
  try {
    raw = JSON.parse(text);
  } catch {
    return json(400, { error: 'json' });
  }
  const parsed = parseShareInput(raw);
  if (!parsed.ok) return json(parsed.status, { error: parsed.error });

  try {
    const created = await store.create(parsed.value, clientKey);
    return json(201, { id: created.id, url: shareUrl(created.id), deleteToken: created.deleteToken, expiresAt: created.expiresAt });
  } catch (error) {
    if (error instanceof RateLimitedError) return json(429, { error: 'rate_limited' });
    return json(503, { error: 'unavailable' });
  }
}

export async function handleGet(id: string, store: ShareStore): Promise<Response> {
  try {
    const share = await store.get(id);
    return share ? json(200, share) : json(404, { error: 'not_found' });
  } catch {
    return json(503, { error: 'unavailable' });
  }
}

export async function handleDelete(id: string, request: Request, store: ShareStore): Promise<Response> {
  const auth = request.headers.get('authorization') ?? '';
  const token = auth.startsWith('Bearer ') ? auth.slice('Bearer '.length) : '';
  try {
    const result = await store.delete(id, token);
    if (result === 'deleted') return json(204);
    if (result === 'forbidden') return json(403, { error: 'forbidden' });
    return json(404, { error: 'not_found' });
  } catch {
    return json(503, { error: 'unavailable' });
  }
}
