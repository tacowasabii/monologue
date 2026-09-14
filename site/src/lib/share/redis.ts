import { Redis } from '@upstash/redis';
import type { Kv } from './store';

/** Vercel Marketplace로 연결한 Upstash Redis. 환경 변수 이름은 설치 방식에 따라 둘 중 하나로 들어온다 */
export function upstashKv(env: Record<string, string | undefined> = process.env): Kv {
  const url = env.UPSTASH_REDIS_REST_URL ?? env.KV_REST_API_URL;
  const token = env.UPSTASH_REDIS_REST_TOKEN ?? env.KV_REST_API_TOKEN;
  if (!url || !token) throw new Error('Upstash Redis 환경 변수가 없습니다');
  // 값은 우리가 직접 JSON으로 다루므로 자동 변환을 끈다. 네트워크 오류는 한 번만 재시도해 503이 느려지지 않게 한다
  const redis = new Redis({ url, token, automaticDeserialization: false, retry: { retries: 1 } });
  return {
    get: (key) => redis.get<string>(key),
    set: async (key, value, ttlSeconds) => {
      await redis.set(key, value, { ex: ttlSeconds });
    },
    del: async (key) => {
      await redis.del(key);
    },
    incr: async (key, ttlSeconds) => {
      // INCR과 EXPIRE(NX)를 한 파이프라인으로 보내 둘 사이에 크래시가 나도 키가 영원히 남지 않게 한다.
      // NX는 만료가 아직 안 걸린 키에만 적용돼, 재시도로 다시 걸려도 창이 밀리지 않는다.
      const [count] = await redis.pipeline().incr(key).expire(key, ttlSeconds, 'NX').exec<[number, 0 | 1]>();
      return count;
    },
  };
}
