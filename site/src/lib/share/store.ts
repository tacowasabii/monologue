import { normalizeClientKey } from './client-key';
import { hmacSha256Hex, isShareId, newDeleteToken, newShareId, sha256Hex, tokenMatches } from './tokens';
import type { ShareInput } from './validate';

export const SHARE_TTL_SECONDS = 7 * 24 * 60 * 60;
export const UPLOADS_PER_HOUR = 20;
/** Site-wide ceiling so a rotating-address attacker can't fill the free Upstash storage tier */
export const UPLOADS_PER_DAY = 100;
const HOUR_SECONDS = 60 * 60;
const DAY_SECONDS = 24 * HOUR_SECONDS;

/** 만료를 지원하는 키-값 저장소. 실제로는 Upstash Redis, 테스트에서는 메모리 */
export interface Kv {
  get(key: string): Promise<string | null>;
  set(key: string, value: string, ttlSeconds: number): Promise<void>;
  del(key: string): Promise<void>;
  /** 카운터를 1 올리고, 새로 만든 키면 만료를 건다. 올린 뒤 값을 준다. */
  incr(key: string, ttlSeconds: number): Promise<number>;
}

export interface PublicShare extends ShareInput {
  createdAt: string;
  expiresAt: string;
}

interface StoredShare extends PublicShare {
  deleteTokenHash: string;
}

export interface CreatedShare {
  id: string;
  deleteToken: string;
  expiresAt: string;
}

export class RateLimitedError extends Error {}

const shareKey = (id: string) => `monologue:share:${id}`;

export interface ShareStoreOptions {
  now?: () => number;
  /** Keys the per-client rate-limit hash (HMAC-SHA256) so it can't be reversed to the raw IP */
  rateLimitSecret: string;
}

export class ShareStore {
  private readonly kv: Kv;
  private readonly now: () => number;
  private readonly rateLimitSecret: string;

  constructor(kv: Kv, options: ShareStoreOptions) {
    this.kv = kv;
    this.now = options.now ?? Date.now;
    this.rateLimitSecret = options.rateLimitSecret;
  }

  async create(input: ShareInput, clientKey: string): Promise<CreatedShare> {
    // 클라이언트별 제한을 먼저 확인한다. 하루 전체 카운터를 먼저 올리면 한 클라이언트가 혼자
    // 계속 시도하는 것만으로 다른 모두의 하루 한도를 다 써버릴 수 있어, 순서를 이렇게 둔다.
    // IP는 정규화(/64) 후 비밀값으로 키가 걸린 해시로만 쓰고, 1시간 뒤 사라지는 카운터 키에만 남긴다
    const hour = Math.floor(this.now() / 1000 / HOUR_SECONDS);
    const normalizedKey = normalizeClientKey(clientKey);
    const clientHash = hmacSha256Hex(this.rateLimitSecret, normalizedKey);
    const count = await this.kv.incr(`monologue:rl:${clientHash}:${hour}`, HOUR_SECONDS);
    if (count > UPLOADS_PER_HOUR) throw new RateLimitedError();

    // 클라이언트별 제한을 통과한 요청만 하루 전체 카운터에 반영해, 로테이션하는 클라이언트가
    // 저장 공간을 다 채우지 못하게 한다
    const day = Math.floor(this.now() / 1000 / DAY_SECONDS);
    const globalCount = await this.kv.incr(`monologue:rl:global:${day}`, DAY_SECONDS);
    if (globalCount > UPLOADS_PER_DAY) throw new RateLimitedError();

    const id = newShareId();
    const deleteToken = newDeleteToken();
    const createdAt = new Date(this.now());
    const expiresAt = new Date(createdAt.getTime() + SHARE_TTL_SECONDS * 1000);
    const stored: StoredShare = {
      ...input,
      createdAt: createdAt.toISOString(),
      expiresAt: expiresAt.toISOString(),
      deleteTokenHash: sha256Hex(deleteToken),
    };
    await this.kv.set(shareKey(id), JSON.stringify(stored), SHARE_TTL_SECONDS);
    return { id, deleteToken, expiresAt: stored.expiresAt };
  }

  async get(id: string): Promise<PublicShare | null> {
    const stored = await this.read(id);
    if (!stored) return null;
    const { deleteTokenHash, ...share } = stored;
    void deleteTokenHash;
    return share;
  }

  async delete(id: string, token: string): Promise<'deleted' | 'forbidden' | 'missing'> {
    const stored = await this.read(id);
    if (!stored) return 'missing';
    if (!tokenMatches(token, stored.deleteTokenHash)) return 'forbidden';
    await this.kv.del(shareKey(id));
    return 'deleted';
  }

  private async read(id: string): Promise<StoredShare | null> {
    if (!isShareId(id)) return null;
    const raw = await this.kv.get(shareKey(id));
    return raw ? (JSON.parse(raw) as StoredShare) : null;
  }
}
