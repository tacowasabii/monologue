import { json } from './http';
import { upstashKv } from './redis';
import { ShareStore } from './store';

/** 짧거나 없는 비밀값으로는 요청 제한 해시가 브루트포스에 뚫릴 수 있어 서비스를 켜지 않는다 */
const MIN_RATE_LIMIT_SECRET_LENGTH = 32;

let cached: ShareStore | undefined;

export function shareStore(): ShareStore {
  if (!cached) {
    const rateLimitSecret = process.env.SHARE_RATE_LIMIT_SECRET;
    if (!rateLimitSecret || rateLimitSecret.length < MIN_RATE_LIMIT_SECRET_LENGTH) {
      throw new Error('SHARE_RATE_LIMIT_SECRET 환경 변수가 없거나 너무 짧습니다');
    }
    cached = new ShareStore(upstashKv(), { rateLimitSecret });
  }
  return cached;
}

/** 저장소를 만들 수 없으면(환경 변수 없음) 503으로 답한다 */
export async function withStore(run: (store: ShareStore) => Promise<Response>): Promise<Response> {
  let store: ShareStore;
  try {
    store = shareStore();
  } catch {
    return json(503, { error: 'unavailable' });
  }
  return run(store);
}

/** 올리기 제한에 쓸 접속 주소. Vercel은 x-forwarded-for 첫 값에 실제 주소를 준다 */
export function clientKey(request: Request, clientAddress: () => string): string {
  const forwarded = request.headers.get('x-forwarded-for')?.split(',')[0]?.trim();
  if (forwarded) return forwarded;
  try {
    return clientAddress();
  } catch {
    return 'unknown';
  }
}
