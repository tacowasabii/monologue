import { describe, expect, it } from 'vitest';
import { normalizeClientKey } from '../src/lib/share/client-key';
import { isShareId, newDeleteToken, newShareId, sha256Hex, tokenMatches } from '../src/lib/share/tokens';
import { LIMITS, parseShareInput } from '../src/lib/share/validate';
import {
  RateLimitedError,
  SHARE_TTL_SECONDS,
  ShareStore,
  UPLOADS_PER_DAY,
  UPLOADS_PER_HOUR,
  type Kv,
} from '../src/lib/share/store';
import type { ShareInput } from '../src/lib/share/validate';
import { parseDialogue } from '../src/lib/share/dialogue';
import { handleCreate, handleDelete, handleGet } from '../src/lib/share/handlers';

/** 테스트에서만 쓰는 32자 이상의 더미 비밀값 */
const TEST_SECRET = 'test-rate-limit-secret-not-for-prod-use';

const validInput = () => ({
  v: 1,
  work: '새벽 세 시의 부엌',
  dialogue: true,
  body: '엄마: 이 시간에 뭐 하는 거야?\n수아: 물 마시러 나왔어.',
  tags: ['가족', '갈등'],
  note: null,
});

describe('tokens', () => {
  it('링크 ID는 22자 base64url이고 매번 다르다', () => {
    const a = newShareId();
    const b = newShareId();
    expect(a).toMatch(/^[A-Za-z0-9_-]{22}$/);
    expect(isShareId(a)).toBe(true);
    expect(a).not.toBe(b);
  });

  it('ID 모양이 아니면 거절한다', () => {
    expect(isShareId('short')).toBe(false);
    expect(isShareId('A'.repeat(21) + '/')).toBe(false);
    expect(isShareId('A'.repeat(23))).toBe(false);
  });

  it('삭제 비밀값은 해시로만 비교한다', () => {
    const token = newDeleteToken();
    expect(token.length).toBeGreaterThanOrEqual(43);
    const hash = sha256Hex(token);
    expect(tokenMatches(token, hash)).toBe(true);
    expect(tokenMatches(token + 'x', hash)).toBe(false);
    expect(tokenMatches(token, 'abc')).toBe(false);
  });
});

describe('normalizeClientKey', () => {
  it('IPv4는 그대로 둔다', () => {
    expect(normalizeClientKey('203.0.113.7')).toBe('203.0.113.7');
    expect(normalizeClientKey('198.51.100.1')).toBe('198.51.100.1');
  });

  it('같은 /64에 속한 IPv6 주소는 같은 키가 된다', () => {
    const a = normalizeClientKey('2001:db8:0:0:aaaa:bbbb:cccc:0001');
    const b = normalizeClientKey('2001:db8:0:0:1111:2222:3333:4444');
    expect(a).toBe(b);
  });

  it('다른 /64에 속한 IPv6 주소는 다른 키가 된다', () => {
    const a = normalizeClientKey('2001:db8:1::1');
    const b = normalizeClientKey('2001:db8:2::1');
    expect(a).not.toBe(b);
  });

  it('압축된 :: 표기를 펼쳐서 같은 /64로 인식한다', () => {
    const compressed = normalizeClientKey('2001:db8::1');
    const expanded = normalizeClientKey('2001:0db8:0000:0000:0000:0000:0000:0001');
    expect(compressed).toBe(expanded);
    expect(normalizeClientKey('::1')).toBe(normalizeClientKey('0000:0000:0000:0000:0000:0000:0000:0001'));
  });
});

describe('parseShareInput', () => {
  it('예전 앱이 함께 보내는 성별·나이대는 거절하지 않고 저장하지 않는다', () => {
    const result = parseShareInput({ ...validInput(), gender: 'female', ageRange: 'thirties' });
    expect(result).toEqual({ ok: true, value: validInput() });
  });

  it('올바른 입력은 그대로 받고, 빈 작품명·노트는 null로 둔다', () => {
    const result = parseShareInput({ ...validInput(), work: '  ', note: '' });
    expect(result).toEqual({ ok: true, value: { ...validInput(), work: null, note: null } });
  });

  it('객체가 아니거나 버전·본문·형식이 틀리면 400', () => {
    expect(parseShareInput('x')).toMatchObject({ ok: false, status: 400 });
    expect(parseShareInput({ ...validInput(), v: 2 })).toMatchObject({ ok: false, status: 400 });
    expect(parseShareInput({ ...validInput(), body: '   ' })).toMatchObject({ ok: false, status: 400 });
    expect(parseShareInput({ ...validInput(), dialogue: 'yes' })).toMatchObject({ ok: false, status: 400 });
    expect(parseShareInput({ ...validInput(), tags: [1] })).toMatchObject({ ok: false, status: 400 });
  });

  it('한도를 넘으면 413', () => {
    expect(parseShareInput({ ...validInput(), body: '가'.repeat(LIMITS.bodyChars) })).toMatchObject({ ok: true });
    expect(parseShareInput({ ...validInput(), body: '가'.repeat(LIMITS.bodyChars + 1) })).toMatchObject({ ok: false, status: 413 });
    expect(parseShareInput({ ...validInput(), note: '가'.repeat(LIMITS.noteChars + 1) })).toMatchObject({ ok: false, status: 413 });
    expect(parseShareInput({ ...validInput(), work: '가'.repeat(LIMITS.workChars + 1) })).toMatchObject({ ok: false, status: 413 });
    expect(parseShareInput({ ...validInput(), tags: Array.from({ length: 21 }, (_, i) => `t${i}`) })).toMatchObject({ ok: false, status: 413 });
    expect(parseShareInput({ ...validInput(), tags: ['가'.repeat(LIMITS.tagChars + 1)] })).toMatchObject({ ok: false, status: 413 });
  });
});

/** 만료를 흉내 내는 메모리 Kv */
export class FakeKv implements Kv {
  readonly data = new Map<string, { value: string; expiresAt: number }>();
  constructor(private readonly now: () => number) {}

  async get(key: string) {
    const entry = this.data.get(key);
    if (!entry || entry.expiresAt <= this.now()) return null;
    return entry.value;
  }

  async set(key: string, value: string, ttlSeconds: number) {
    this.data.set(key, { value, expiresAt: this.now() + ttlSeconds * 1000 });
  }

  async del(key: string) {
    this.data.delete(key);
  }

  async incr(key: string, ttlSeconds: number) {
    const current = await this.get(key);
    const count = (current ? Number(current) : 0) + 1;
    const expiresAt = current ? this.data.get(key)!.expiresAt : this.now() + ttlSeconds * 1000;
    this.data.set(key, { value: String(count), expiresAt });
    return count;
  }
}

const input = (): ShareInput => ({
  v: 1,
  work: '햄릿',
  dialogue: false,
  body: '사느냐 죽느냐',
  tags: ['고전'],
  note: '고뇌',
});

describe('ShareStore', () => {
  const start = Date.UTC(2026, 8, 14, 12, 0, 0);

  it('올린 대본을 7일 동안 돌려주고, 삭제 비밀값의 해시는 내보내지 않는다', async () => {
    let now = start;
    const kv = new FakeKv(() => now);
    const store = new ShareStore(kv, { now: () => now, rateLimitSecret: TEST_SECRET });
    const created = await store.create(input(), '203.0.113.7');

    expect(created.id).toMatch(/^[A-Za-z0-9_-]{22}$/);
    expect(created.expiresAt).toBe(new Date(start + SHARE_TTL_SECONDS * 1000).toISOString());
    const share = await store.get(created.id);
    expect(share).toEqual({ ...input(), createdAt: new Date(start).toISOString(), expiresAt: created.expiresAt });
    expect(JSON.stringify(share)).not.toContain('deleteTokenHash');
    expect([...kv.data.values()].some((e) => e.value.includes(created.deleteToken))).toBe(false);

    now = start + SHARE_TTL_SECONDS * 1000;
    expect(await store.get(created.id)).toBeNull();
  });

  it('비밀값이 맞을 때만 지운다', async () => {
    const kv = new FakeKv(() => start);
    const store = new ShareStore(kv, { now: () => start, rateLimitSecret: TEST_SECRET });
    const created = await store.create(input(), '203.0.113.7');

    expect(await store.delete(created.id, 'wrong')).toBe('forbidden');
    expect(await store.get(created.id)).not.toBeNull();
    expect(await store.delete(created.id, created.deleteToken)).toBe('deleted');
    expect(await store.get(created.id)).toBeNull();
    expect(await store.delete(created.id, created.deleteToken)).toBe('missing');
    expect(await store.get('not-an-id')).toBeNull();
  });

  it('같은 IP는 1시간에 20개까지만 올리고, 다음 시간에는 다시 올릴 수 있다', async () => {
    let now = start;
    const kv = new FakeKv(() => now);
    const store = new ShareStore(kv, { now: () => now, rateLimitSecret: TEST_SECRET });
    for (let i = 0; i < UPLOADS_PER_HOUR; i++) await store.create(input(), '203.0.113.7');
    await expect(store.create(input(), '203.0.113.7')).rejects.toBeInstanceOf(RateLimitedError);
    await expect(store.create(input(), '198.51.100.1')).resolves.toBeTruthy();

    now = start + 3600 * 1000;
    await expect(store.create(input(), '203.0.113.7')).resolves.toBeTruthy();
    expect([...kv.data.keys()].some((k) => k.includes('203.0.113.7'))).toBe(false);
    expect([...kv.data.keys()].some((k) => k.includes(sha256Hex('203.0.113.7')))).toBe(false);
  });

  it('같은 /64 안의 IPv6 주소를 돌려써도 1시간 제한을 우회할 수 없다', async () => {
    const kv = new FakeKv(() => start);
    const store = new ShareStore(kv, { now: () => start, rateLimitSecret: TEST_SECRET });
    for (let i = 0; i < UPLOADS_PER_HOUR; i++) {
      await store.create(input(), `2001:db8::${(i + 1).toString(16)}`);
    }
    await expect(store.create(input(), '2001:db8::ffff')).rejects.toBeInstanceOf(RateLimitedError);
  });

  it('하루 전체 업로드는 100개까지만 허용하고, 다음 날에는 다시 올릴 수 있다', async () => {
    let now = start;
    const kv = new FakeKv(() => now);
    const store = new ShareStore(kv, { now: () => now, rateLimitSecret: TEST_SECRET });
    for (let i = 0; i < UPLOADS_PER_DAY; i++) {
      await expect(store.create(input(), `198.51.100.${(i % 254) + 1}`)).resolves.toBeTruthy();
    }
    await expect(store.create(input(), '203.0.113.200')).rejects.toBeInstanceOf(RateLimitedError);

    now = start + 24 * 3600 * 1000;
    await expect(store.create(input(), '203.0.113.200')).resolves.toBeTruthy();
  });

  it('한 클라이언트가 계속 시도해도 전체 하루 카운터는 시간당 한도만큼만 올라간다', async () => {
    const kv = new FakeKv(() => start);
    const store = new ShareStore(kv, { now: () => start, rateLimitSecret: TEST_SECRET });

    // 클라이언트별 제한을 먼저 확인하므로, 25번 시도해도 하루 전체 카운터는 20까지만 올라간다
    for (let i = 0; i < 25; i++) {
      if (i < UPLOADS_PER_HOUR) {
        await expect(store.create(input(), '203.0.113.9')).resolves.toBeTruthy();
      } else {
        await expect(store.create(input(), '203.0.113.9')).rejects.toBeInstanceOf(RateLimitedError);
      }
    }
    const globalEntry = [...kv.data.entries()].find(([key]) => key.startsWith('monologue:rl:global:'));
    expect(globalEntry?.[1].value).toBe(String(UPLOADS_PER_HOUR));

    // 남은 하루 한도(100 - 20 = 80)는 다른 클라이언트가 그대로 쓸 수 있다
    for (let i = 0; i < UPLOADS_PER_DAY - UPLOADS_PER_HOUR; i++) {
      await expect(store.create(input(), `198.51.100.${i + 1}`)).resolves.toBeTruthy();
    }
    await expect(store.create(input(), '198.51.100.200')).rejects.toBeInstanceOf(RateLimitedError);
  });
});

describe('handlers', () => {
  const now = Date.UTC(2026, 8, 14, 12, 0, 0);
  const newStore = () => new ShareStore(new FakeKv(() => now), { now: () => now, rateLimitSecret: TEST_SECRET });
  const post = (body: string, headers: Record<string, string> = {}) =>
    new Request('https://monologue.ink/api/shares', {
      method: 'POST',
      headers: { 'Content-Type': 'application/json', ...headers },
      body,
    });

  it('올리면 201과 링크·비밀값을 주고, 가져오기는 대본을 준다', async () => {
    const store = newStore();
    const created = await handleCreate(post(JSON.stringify(input())), store, '203.0.113.7');
    expect(created.status).toBe(201);
    expect(created.headers.get('Cache-Control')).toBe('no-store');
    const body = (await created.json()) as { id: string; url: string; deleteToken: string; expiresAt: string };
    expect(body.url).toBe(`https://monologue.ink/s/${body.id}`);

    const fetched = await handleGet(body.id, store);
    expect(fetched.status).toBe(200);
    expect(fetched.headers.get('X-Robots-Tag')).toBe('noindex');
    expect(await fetched.json()).toMatchObject({ work: '햄릿', body: '사느냐 죽느냐', note: '고뇌' });
  });

  it('JSON이 아니면 400, 너무 크면 413, 제한을 넘으면 429', async () => {
    const store = newStore();
    expect((await handleCreate(post('{'), store, 'ip')).status).toBe(400);
    const huge = JSON.stringify({ ...input(), body: 'a'.repeat(270 * 1024) });
    expect((await handleCreate(post(huge), store, 'ip')).status).toBe(413);
    for (let i = 0; i < UPLOADS_PER_HOUR; i++) await handleCreate(post(JSON.stringify(input())), store, 'busy');
    expect((await handleCreate(post(JSON.stringify(input())), store, 'busy')).status).toBe(429);
  });

  it('없는 링크는 404, 저장소 오류는 503', async () => {
    expect((await handleGet('A'.repeat(22), newStore())).status).toBe(404);
    expect((await handleGet('bad', newStore())).status).toBe(404);
    const broken = new ShareStore(
      {
        get: () => Promise.reject(new Error('down')),
        set: () => Promise.reject(new Error('down')),
        del: () => Promise.reject(new Error('down')),
        incr: () => Promise.reject(new Error('down')),
      },
      { rateLimitSecret: TEST_SECRET },
    );
    expect((await handleGet('A'.repeat(22), broken)).status).toBe(503);
    expect((await handleCreate(post(JSON.stringify(input())), broken, 'ip')).status).toBe(503);
  });

  it('삭제는 Bearer 비밀값이 맞으면 204, 틀리면 403, 없으면 404', async () => {
    const store = newStore();
    const res = await handleCreate(post(JSON.stringify(input())), store, 'ip');
    const { id, deleteToken } = (await res.json()) as { id: string; deleteToken: string };
    const del = (token: string) =>
      new Request(`https://monologue.ink/api/shares/${id}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` },
      });
    expect((await handleDelete(id, del('nope'), store)).status).toBe(403);
    const ok = await handleDelete(id, del(deleteToken), store);
    expect(ok.status).toBe(204);
    expect(await ok.text()).toBe('');
    expect((await handleDelete(id, del(deleteToken), store)).status).toBe(404);
  });

  it('JSON이 아닌 Content-Type은 415, charset이 붙은 JSON은 통과한다', async () => {
    const store = newStore();
    const textPlain = await handleCreate(post(JSON.stringify(input()), { 'Content-Type': 'text/plain' }), store, 'ct-1');
    expect(textPlain.status).toBe(415);
    const noContentType = await handleCreate(post(JSON.stringify(input()), { 'Content-Type': '' }), store, 'ct-2');
    expect(noContentType.status).toBe(415);
    const withCharset = await handleCreate(
      post(JSON.stringify(input()), { 'Content-Type': 'application/json; charset=utf-8' }),
      store,
      'ct-3',
    );
    expect(withCharset.status).toBe(201);
  });
});

describe('parseDialogue (앱 lib/domain/dialogue.dart와 같은 규칙)', () => {
  it('이름: 대사, 이어지는 줄, 지문을 나눈다', () => {
    expect(parseDialogue('엄마: 이 시간에 뭐 해?\n수아: 물 마시러\n나왔어.\n(사이)\n다시 말하는 수아')).toEqual([
      { speaker: '엄마', text: '이 시간에 뭐 해?', direction: false },
      { speaker: '수아', text: '물 마시러\n나왔어.', direction: false },
      { speaker: null, text: '(사이)', direction: true },
      { speaker: '수아', text: '다시 말하는 수아', direction: false },
    ]);
  });

  it('빈 줄 뒤 이름 없는 줄은 지문, 숫자·http 이름은 대사로 보지 않는다', () => {
    expect(parseDialogue('민수: 안녕\n\n조명이 꺼진다\n12: 30\nhttp://x')).toEqual([
      { speaker: '민수', text: '안녕', direction: false },
      { speaker: null, text: '조명이 꺼진다\n12: 30\nhttp://x', direction: true },
    ]);
  });

  it('이름만 있는 줄은 다음 줄이 대사가 되고, 전각 콜론도 받는다', () => {
    expect(parseDialogue('니나：\n나는 갈매기')).toEqual([{ speaker: '니나', text: '나는 갈매기', direction: false }]);
  });
});
