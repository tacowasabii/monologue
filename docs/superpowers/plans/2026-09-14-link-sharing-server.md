# 대본 링크 공유 — 서버·웹 보기 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 기존 웹사이트(`tacowasabii.vercel.app`)에 대본 공유 API, 공유 대본 웹 보기 페이지, 앱 링크 인증 파일을 붙이고 배포한다.

**Architecture:** Astro 사이트에 `@astrojs/vercel` 어댑터를 넣어 공유 경로만 요청 때 실행하고(`prerender = false`), 나머지 페이지는 지금처럼 정적으로 둔다. 저장·검사·권한 로직은 `src/lib/monologue-share/`의 순수 TypeScript로 두고 `Kv` 인터페이스 뒤에 Upstash Redis를 숨겨, 테스트는 메모리 가짜 Kv로 돌린다.

**Tech Stack:** Astro 7.3.2, `@astrojs/vercel` 11.0.10, `@upstash/redis` 1.38.4, Vitest 5, Vercel CLI 59(Hobby 팀 `tacowasabiis-projects`, 프로젝트 `tacowasabii`).

**Spec:** `/Users/tacowasabii/orca/workspaces/monologue/hagfish/docs/superpowers/specs/2026-09-14-link-sharing-design.md`

**작업 저장소:** `/Users/tacowasabii/website` (git 원격 없음. 커밋은 로컬에만, 배포는 `vercel --prod`)

## Global Constraints

- 링크 주소: `https://tacowasabii.vercel.app/monologue/s/<ID>`
- API: `POST /api/monologue/shares`, `GET /api/monologue/shares/<ID>`, `DELETE /api/monologue/shares/<ID>`(헤더 `Authorization: Bearer <deleteToken>`)
- ID: 난수 16바이트 base64url, 정규식 `^[A-Za-z0-9_-]{22}$`. 삭제 비밀값: 난수 32바이트 base64url, 서버에는 SHA-256 hex만 저장.
- Redis 키: `monologue:share:<ID>`(값 JSON, `EX 604800`), `monologue:rl:<sha256(IP)>:<floor(유닉스 초 / 3600)>`(`EX 3600`)
- 올리기 제한: 1시간에 20개. 가져오기·삭제는 제한 없음.
- 입력 한도: `body` 공백 제외 1자 이상·100,000자 이하, `note` 20,000자 이하, `work` 200자 이하, `tags` 20개 이하·각 30자 이하, 요청 본문 256KB 이하. 형식 오류는 `400`, 한도 초과는 `413`.
- `gender` ∈ `any|male|female`, `ageRange` ∈ `any|teens|twenties|thirties|forties|fiftiesPlus`
- 모든 API 응답과 웹 보기 페이지: `Cache-Control: no-store`, `X-Robots-Tag: noindex`
- 앱 링크: 팀 ID `3996SU7HLL`, 번들·패키지 `com.tacowasabii.monologue`, 업로드 키 SHA-256 `6C:DB:D3:4B:C1:76:8C:D6:86:36:09:CE:4F:FC:00:7A:51:7D:85:13:0F:19:81:D3:50:B4:EB:80:BF:F5:37:C6`
- 웹 보기 "앱에서 열기"는 `monologue://s/<ID>`
- 기존 페이지(`/`, `/monologue`, `/monologue/privacy`)는 정적으로 남아야 한다.
- 커밋 메시지 끝에 `Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>`
- 비밀값(Upstash 토큰 등)은 출력하거나 커밋하지 않는다.

## File Structure

| 파일 | 책임 |
|---|---|
| `astro.config.mjs` (수정) | Vercel 어댑터 |
| `package.json` (수정) | 어댑터·Redis 의존성 |
| `vercel.json` (새로) | 함수 지역, AASA Content-Type |
| `src/lib/monologue-share/tokens.ts` | ID·비밀값 생성, 해시, 비교 |
| `src/lib/monologue-share/validate.ts` | 올리기 입력 검사 |
| `src/lib/monologue-share/store.ts` | `Kv` 인터페이스, 저장·조회·삭제·올리기 제한 |
| `src/lib/monologue-share/http.ts` | JSON 응답, 공통 헤더, 링크 주소 |
| `src/lib/monologue-share/handlers.ts` | 요청 → 응답(Astro와 무관, 테스트 대상) |
| `src/lib/monologue-share/dialogue.ts` | 앱 `parseDialogue`의 TypeScript 이식(웹 보기용) |
| `src/lib/monologue-share/redis.ts` | Upstash로 만든 `Kv` |
| `src/lib/monologue-share/instance.ts` | 요청마다 쓸 `ShareStore`, 환경 변수 없을 때 `503` |
| `src/lib/monologue-share/site.ts` | 신고 이메일, 스토어 주소, 데이터 지역 기록 |
| `src/pages/api/monologue/shares/index.ts` | `POST` |
| `src/pages/api/monologue/shares/[id].ts` | `GET`, `DELETE` |
| `src/pages/monologue/s/[id].astro` | 웹 보기 페이지 |
| `public/.well-known/apple-app-site-association` | iOS 앱 링크 |
| `public/.well-known/assetlinks.json` | Android 앱 링크 |
| `tests/monologue-share.test.ts` | 로직·핸들러 테스트 |
| `tests/build.test.ts` (수정) | 빌드 출력 경로 `dist/client`, 인증 파일·정적 페이지 확인 |

---

### Task 1: Vercel 어댑터로 바꾸고 기존 빌드 테스트 살리기

**Files:**
- Modify: `package.json`
- Modify: `astro.config.mjs`
- Modify: `tests/build.test.ts:5-7`

**Interfaces:**
- Produces: `astro build`가 정적 파일을 `dist/client/`에, 함수를 `.vercel/output/`에 만든다. 이후 태스크의 빌드 테스트는 `dist/client/`를 읽는다.

- [ ] **Step 1: 의존성 설치**

```bash
cd /Users/tacowasabii/website
npm install @astrojs/vercel@11.0.10 @upstash/redis@1.38.4
```

Expected: `package.json` `dependencies`에 두 패키지가 추가된다.

- [ ] **Step 2: 빌드 테스트가 새 경로를 보게 먼저 고친다(아직 실패해야 함)**

`tests/build.test.ts` 5~7행을 다음으로 바꾼다.

```ts
// Vercel 어댑터를 쓰면 정적 파일은 dist/client에 나온다
const DIST = new URL('../dist/client/index.html', import.meta.url);
const html = () => {
  if (!existsSync(DIST)) throw new Error('dist/client/index.html 없음 — `npm test`로 빌드 후 실행하세요');
```

Run: `npm test`
Expected: FAIL — `dist/client/index.html 없음` (아직 어댑터가 없어 `dist/index.html`에 빌드된다)

- [ ] **Step 3: 어댑터 설정**

`astro.config.mjs` 전체:

```js
import { defineConfig } from 'astro/config';
import vercel from '@astrojs/vercel';

export default defineConfig({
  site: 'https://tacowasabii.vercel.app',
  // 공유 API와 공유 대본 페이지만 요청 때 실행하고 나머지는 정적으로 만든다
  adapter: vercel(),
});
```

- [ ] **Step 4: 통과 확인**

Run: `rm -rf dist .vercel/output && npm test`
Expected: 빌드 로그에 `adapter: @astrojs/vercel`, 테스트 12개 PASS. `ls dist/client/monologue/privacy/index.html` 존재.

- [ ] **Step 5: 커밋**

```bash
git add package.json package-lock.json astro.config.mjs tests/build.test.ts
git commit -m "build: use the Vercel adapter so share routes can run on request

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 2: ID·비밀값과 입력 검사

**Files:**
- Create: `src/lib/monologue-share/tokens.ts`
- Create: `src/lib/monologue-share/validate.ts`
- Test: `tests/monologue-share.test.ts`

**Interfaces:**
- Produces:
  - `newShareId(): string`, `newDeleteToken(): string`, `sha256Hex(value: string): string`, `isShareId(value: string): boolean`, `tokenMatches(token: string, expectedHash: string): boolean`
  - `type Gender = 'any'|'male'|'female'`, `type AgeRange = 'any'|'teens'|'twenties'|'thirties'|'forties'|'fiftiesPlus'`
  - `interface ShareInput { v: 1; work: string|null; dialogue: boolean; body: string; gender: Gender; ageRange: AgeRange; tags: string[]; note: string|null }`
  - `LIMITS = { bodyChars: 100_000, noteChars: 20_000, workChars: 200, tags: 20, tagChars: 30, requestBytes: 262_144 }`
  - `parseShareInput(raw: unknown): { ok: true; value: ShareInput } | { ok: false; status: 400 | 413; error: string }`

- [ ] **Step 1: 실패하는 테스트 작성**

`tests/monologue-share.test.ts`:

```ts
import { describe, expect, it } from 'vitest';
import { isShareId, newDeleteToken, newShareId, sha256Hex, tokenMatches } from '../src/lib/monologue-share/tokens';
import { LIMITS, parseShareInput } from '../src/lib/monologue-share/validate';

const validInput = () => ({
  v: 1,
  work: '새벽 세 시의 부엌',
  dialogue: true,
  body: '엄마: 이 시간에 뭐 하는 거야?\n수아: 물 마시러 나왔어.',
  gender: 'female',
  ageRange: 'thirties',
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

describe('parseShareInput', () => {
  it('올바른 입력은 그대로 받고, 빈 작품명·노트는 null로 둔다', () => {
    const result = parseShareInput({ ...validInput(), work: '  ', note: '' });
    expect(result).toEqual({ ok: true, value: { ...validInput(), work: null, note: null } });
  });

  it('객체가 아니거나 버전·본문·형식이 틀리면 400', () => {
    expect(parseShareInput('x')).toMatchObject({ ok: false, status: 400 });
    expect(parseShareInput({ ...validInput(), v: 2 })).toMatchObject({ ok: false, status: 400 });
    expect(parseShareInput({ ...validInput(), body: '   ' })).toMatchObject({ ok: false, status: 400 });
    expect(parseShareInput({ ...validInput(), gender: 'other' })).toMatchObject({ ok: false, status: 400 });
    expect(parseShareInput({ ...validInput(), ageRange: 'fifties' })).toMatchObject({ ok: false, status: 400 });
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
```

- [ ] **Step 2: 실패 확인**

Run: `npx vitest run tests/monologue-share.test.ts`
Expected: FAIL — `Cannot find module '../src/lib/monologue-share/tokens'`

- [ ] **Step 3: 구현**

`src/lib/monologue-share/tokens.ts`:

```ts
import { createHash, randomBytes, timingSafeEqual } from 'node:crypto';

const SHARE_ID_PATTERN = /^[A-Za-z0-9_-]{22}$/;

/** 짐작할 수 없는 링크 ID(16바이트 → base64url 22자) */
export const newShareId = () => randomBytes(16).toString('base64url');

/** 보낸 사람만 가진 삭제 비밀값(32바이트) */
export const newDeleteToken = () => randomBytes(32).toString('base64url');

export const sha256Hex = (value: string) => createHash('sha256').update(value).digest('hex');

export const isShareId = (value: string) => SHARE_ID_PATTERN.test(value);

/** 비밀값을 해시해 저장된 해시와 일정한 시간에 비교한다 */
export function tokenMatches(token: string, expectedHash: string): boolean {
  const actual = Buffer.from(sha256Hex(token), 'hex');
  const expected = Buffer.from(expectedHash, 'hex');
  return actual.length === expected.length && timingSafeEqual(actual, expected);
}
```

`src/lib/monologue-share/validate.ts`:

```ts
const GENDERS = ['any', 'male', 'female'] as const;
const AGE_RANGES = ['any', 'teens', 'twenties', 'thirties', 'forties', 'fiftiesPlus'] as const;

export type Gender = (typeof GENDERS)[number];
export type AgeRange = (typeof AGE_RANGES)[number];

export interface ShareInput {
  v: 1;
  work: string | null;
  dialogue: boolean;
  body: string;
  gender: Gender;
  ageRange: AgeRange;
  tags: string[];
  note: string | null;
}

export const LIMITS = {
  bodyChars: 100_000,
  noteChars: 20_000,
  workChars: 200,
  tags: 20,
  tagChars: 30,
  requestBytes: 256 * 1024,
} as const;

export type ParsedShareInput =
  | { ok: true; value: ShareInput }
  | { ok: false; status: 400 | 413; error: string };

/** 한글 한 글자를 1자로 센다 */
const chars = (value: string) => [...value].length;

export function parseShareInput(raw: unknown): ParsedShareInput {
  const bad = (error: string): ParsedShareInput => ({ ok: false, status: 400, error });
  const tooLarge = (error: string): ParsedShareInput => ({ ok: false, status: 413, error });

  if (typeof raw !== 'object' || raw === null || Array.isArray(raw)) return bad('object');
  const r = raw as Record<string, unknown>;
  if (r.v !== 1) return bad('v');

  if (typeof r.body !== 'string' || r.body.trim() === '') return bad('body');
  if (chars(r.body) > LIMITS.bodyChars) return tooLarge('body');

  const work = r.work ?? null;
  if (work !== null && typeof work !== 'string') return bad('work');
  if (work !== null && chars(work) > LIMITS.workChars) return tooLarge('work');

  const note = r.note ?? null;
  if (note !== null && typeof note !== 'string') return bad('note');
  if (note !== null && chars(note) > LIMITS.noteChars) return tooLarge('note');

  if (typeof r.dialogue !== 'boolean') return bad('dialogue');
  if (!GENDERS.includes(r.gender as Gender)) return bad('gender');
  if (!AGE_RANGES.includes(r.ageRange as AgeRange)) return bad('ageRange');

  if (!Array.isArray(r.tags) || !r.tags.every((t) => typeof t === 'string')) return bad('tags');
  const tags = r.tags as string[];
  if (tags.length > LIMITS.tags || tags.some((t) => chars(t) > LIMITS.tagChars)) return tooLarge('tags');

  const blankToNull = (value: string | null) => (value === null || value.trim() === '' ? null : value);
  return {
    ok: true,
    value: {
      v: 1,
      work: blankToNull(work),
      dialogue: r.dialogue,
      body: r.body,
      gender: r.gender as Gender,
      ageRange: r.ageRange as AgeRange,
      tags,
      note: blankToNull(note),
    },
  };
}
```

- [ ] **Step 4: 통과 확인**

Run: `npx vitest run tests/monologue-share.test.ts`
Expected: PASS (5 tests)

- [ ] **Step 5: 커밋**

```bash
git add src/lib/monologue-share/tokens.ts src/lib/monologue-share/validate.ts tests/monologue-share.test.ts
git commit -m "feat(monologue-share): share ids, delete tokens and input validation

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 3: 저장·조회·삭제·올리기 제한

**Files:**
- Create: `src/lib/monologue-share/store.ts`
- Test: `tests/monologue-share.test.ts` (추가)

**Interfaces:**
- Consumes: Task 2의 `newShareId`, `newDeleteToken`, `sha256Hex`, `isShareId`, `tokenMatches`, `ShareInput`
- Produces:
  - `interface Kv { get(key: string): Promise<string|null>; set(key: string, value: string, ttlSeconds: number): Promise<void>; del(key: string): Promise<void>; incr(key: string, ttlSeconds: number): Promise<number> }`
  - `SHARE_TTL_SECONDS = 604800`, `UPLOADS_PER_HOUR = 20`
  - `interface PublicShare extends ShareInput { createdAt: string; expiresAt: string }`
  - `interface CreatedShare { id: string; deleteToken: string; expiresAt: string }`
  - `class RateLimitedError extends Error`
  - `class ShareStore { constructor(kv: Kv, now?: () => number); create(input: ShareInput, clientKey: string): Promise<CreatedShare>; get(id: string): Promise<PublicShare|null>; delete(id: string, token: string): Promise<'deleted'|'forbidden'|'missing'> }`

- [ ] **Step 1: 실패하는 테스트 추가**

`tests/monologue-share.test.ts` 맨 위 import에 추가:

```ts
import { RateLimitedError, SHARE_TTL_SECONDS, ShareStore, UPLOADS_PER_HOUR, type Kv } from '../src/lib/monologue-share/store';
import type { ShareInput } from '../src/lib/monologue-share/validate';
```

파일 끝에 추가:

```ts
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
  gender: 'male',
  ageRange: 'twenties',
  tags: ['고전'],
  note: '고뇌',
});

describe('ShareStore', () => {
  const start = Date.UTC(2026, 8, 14, 12, 0, 0);

  it('올린 대본을 7일 동안 돌려주고, 삭제 비밀값의 해시는 내보내지 않는다', async () => {
    let now = start;
    const kv = new FakeKv(() => now);
    const store = new ShareStore(kv, () => now);
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
    const store = new ShareStore(kv, () => start);
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
    const store = new ShareStore(kv, () => now);
    for (let i = 0; i < UPLOADS_PER_HOUR; i++) await store.create(input(), '203.0.113.7');
    await expect(store.create(input(), '203.0.113.7')).rejects.toBeInstanceOf(RateLimitedError);
    await expect(store.create(input(), '198.51.100.1')).resolves.toBeTruthy();

    now = start + 3600 * 1000;
    await expect(store.create(input(), '203.0.113.7')).resolves.toBeTruthy();
    expect([...kv.data.keys()].some((k) => k.includes('203.0.113.7'))).toBe(false);
  });
});
```

- [ ] **Step 2: 실패 확인**

Run: `npx vitest run tests/monologue-share.test.ts`
Expected: FAIL — `Cannot find module '../src/lib/monologue-share/store'`

- [ ] **Step 3: 구현**

`src/lib/monologue-share/store.ts`:

```ts
import { isShareId, newDeleteToken, newShareId, sha256Hex, tokenMatches } from './tokens';
import type { ShareInput } from './validate';

export const SHARE_TTL_SECONDS = 7 * 24 * 60 * 60;
export const UPLOADS_PER_HOUR = 20;

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

export class ShareStore {
  constructor(
    private readonly kv: Kv,
    private readonly now: () => number = Date.now,
  ) {}

  async create(input: ShareInput, clientKey: string): Promise<CreatedShare> {
    // IP는 해시로만 쓰고 1시간 뒤 사라지는 카운터 키에만 남긴다
    const hour = Math.floor(this.now() / 1000 / 3600);
    const count = await this.kv.incr(`monologue:rl:${sha256Hex(clientKey)}:${hour}`, 3600);
    if (count > UPLOADS_PER_HOUR) throw new RateLimitedError();

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
```

- [ ] **Step 4: 통과 확인**

Run: `npx vitest run tests/monologue-share.test.ts`
Expected: PASS (8 tests)

- [ ] **Step 5: 커밋**

```bash
git add src/lib/monologue-share/store.ts tests/monologue-share.test.ts
git commit -m "feat(monologue-share): store shares for seven days with upload limits

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 4: 요청 핸들러와 대화 대본 나누기

**Files:**
- Create: `src/lib/monologue-share/http.ts`
- Create: `src/lib/monologue-share/handlers.ts`
- Create: `src/lib/monologue-share/dialogue.ts`
- Test: `tests/monologue-share.test.ts` (추가)

**Interfaces:**
- Consumes: Task 2 `parseShareInput`, `LIMITS`; Task 3 `ShareStore`, `RateLimitedError`
- Produces:
  - `json(status: number, body?: unknown): Response`, `shareUrl(id: string): string`, `appOpenUrl(id: string): string`, `NO_STORE_HEADERS: Record<string, string>`
  - `handleCreate(request: Request, store: ShareStore, clientKey: string): Promise<Response>`
  - `handleGet(id: string, store: ShareStore): Promise<Response>`
  - `handleDelete(id: string, request: Request, store: ShareStore): Promise<Response>`
  - `interface DialogueLine { speaker: string|null; text: string; direction: boolean }`, `parseDialogue(body: string): DialogueLine[]`

- [ ] **Step 1: 실패하는 테스트 추가**

import에 추가:

```ts
import { parseDialogue } from '../src/lib/monologue-share/dialogue';
import { handleCreate, handleDelete, handleGet } from '../src/lib/monologue-share/handlers';
```

파일 끝에 추가:

```ts
describe('handlers', () => {
  const now = Date.UTC(2026, 8, 14, 12, 0, 0);
  const newStore = () => new ShareStore(new FakeKv(() => now), () => now);
  const post = (body: string, headers: Record<string, string> = {}) =>
    new Request('https://tacowasabii.vercel.app/api/monologue/shares', {
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
    expect(body.url).toBe(`https://tacowasabii.vercel.app/monologue/s/${body.id}`);

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
    const broken = new ShareStore({
      get: () => Promise.reject(new Error('down')),
      set: () => Promise.reject(new Error('down')),
      del: () => Promise.reject(new Error('down')),
      incr: () => Promise.reject(new Error('down')),
    });
    expect((await handleGet('A'.repeat(22), broken)).status).toBe(503);
    expect((await handleCreate(post(JSON.stringify(input())), broken, 'ip')).status).toBe(503);
  });

  it('삭제는 Bearer 비밀값이 맞으면 204, 틀리면 403, 없으면 404', async () => {
    const store = newStore();
    const res = await handleCreate(post(JSON.stringify(input())), store, 'ip');
    const { id, deleteToken } = (await res.json()) as { id: string; deleteToken: string };
    const del = (token: string) =>
      new Request(`https://tacowasabii.vercel.app/api/monologue/shares/${id}`, {
        method: 'DELETE',
        headers: { Authorization: `Bearer ${token}` },
      });
    expect((await handleDelete(id, del('nope'), store)).status).toBe(403);
    const ok = await handleDelete(id, del(deleteToken), store);
    expect(ok.status).toBe(204);
    expect(await ok.text()).toBe('');
    expect((await handleDelete(id, del(deleteToken), store)).status).toBe(404);
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
```

- [ ] **Step 2: 실패 확인**

Run: `npx vitest run tests/monologue-share.test.ts`
Expected: FAIL — `Cannot find module '../src/lib/monologue-share/dialogue'`

- [ ] **Step 3: 구현**

`src/lib/monologue-share/http.ts`:

```ts
export const SITE_ORIGIN = 'https://tacowasabii.vercel.app';

/** 지운 링크가 캐시에 남지 않고 검색 엔진에 실리지 않게 한다 */
export const NO_STORE_HEADERS: Record<string, string> = {
  'Cache-Control': 'no-store',
  'X-Robots-Tag': 'noindex',
};

export function json(status: number, body?: unknown): Response {
  if (body === undefined) return new Response(null, { status, headers: NO_STORE_HEADERS });
  return new Response(JSON.stringify(body), {
    status,
    headers: { ...NO_STORE_HEADERS, 'Content-Type': 'application/json; charset=utf-8' },
  });
}

export const shareUrl = (id: string) => `${SITE_ORIGIN}/monologue/s/${id}`;

/** 웹 보기의 "앱에서 열기". 같은 사이트 안의 링크로는 Universal Link가 앱을 열지 않아 앱 전용 주소를 쓴다 */
export const appOpenUrl = (id: string) => `monologue://s/${id}`;
```

`src/lib/monologue-share/handlers.ts`:

```ts
import { json, shareUrl } from './http';
import { RateLimitedError, type ShareStore } from './store';
import { LIMITS, parseShareInput } from './validate';

export async function handleCreate(request: Request, store: ShareStore, clientKey: string): Promise<Response> {
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
```

`src/lib/monologue-share/dialogue.ts`:

```ts
/** 앱의 lib/domain/dialogue.dart parseDialogue를 옮긴 것. 규칙을 바꾸면 양쪽을 함께 바꾼다. */
export interface DialogueLine {
  speaker: string | null;
  text: string;
  direction: boolean;
}

// 이름은 1~12자, 콜론은 반각·전각 모두
const speakerLine = /^([^:：]{1,12}?)\s*[:：]\s*(.*)$/;
const digitsOnly = /^\d+$/;

function splitSpeaker(line: string): [string, string] | null {
  const m = speakerLine.exec(line);
  if (!m) return null;
  const name = m[1].trim();
  if (name === '' || digitsOnly.test(name) || name.toLowerCase().startsWith('http')) return null;
  return [name, m[2].trim()];
}

export function parseDialogue(body: string): DialogueLine[] {
  const out: DialogueLine[] = [];
  let current: string | null = null;
  let joinable = false;

  const appendToLast = (line: string) => {
    const last = out[out.length - 1];
    last.text = last.text === '' ? line : `${last.text}\n${line}`;
  };

  for (const raw of body.split('\n')) {
    const line = raw.trim();
    if (line === '') {
      current = null;
      joinable = false;
      continue;
    }
    if (line.startsWith('(') && line.endsWith(')')) {
      out.push({ speaker: null, text: line, direction: true });
      joinable = false;
      continue;
    }
    const split = splitSpeaker(line);
    if (split) {
      current = split[0];
      out.push({ speaker: split[0], text: split[1], direction: false });
    } else if (joinable) {
      appendToLast(line);
    } else if (current !== null) {
      out.push({ speaker: current, text: line, direction: false });
    } else {
      out.push({ speaker: null, text: line, direction: true });
    }
    joinable = true;
  }
  return out;
}
```

- [ ] **Step 4: 통과 확인**

Run: `npx vitest run tests/monologue-share.test.ts`
Expected: PASS (15 tests). `parseDialogue` 두 번째 테스트가 실패하면 앱의 `test/domain/dialogue_test.dart`에서 같은 입력의 기대값을 확인하고, 앱 규칙과 다르게 이식한 부분을 고친다(테스트 기대값을 앱과 다르게 바꾸지 않는다).

- [ ] **Step 5: 커밋**

```bash
git add src/lib/monologue-share/http.ts src/lib/monologue-share/handlers.ts src/lib/monologue-share/dialogue.ts tests/monologue-share.test.ts
git commit -m "feat(monologue-share): request handlers and dialogue parsing for the web view

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 5: API 경로, 웹 보기 페이지, 앱 링크 인증 파일

**Files:**
- Create: `src/lib/monologue-share/redis.ts`
- Create: `src/lib/monologue-share/instance.ts`
- Create: `src/lib/monologue-share/site.ts`
- Create: `src/pages/api/monologue/shares/index.ts`
- Create: `src/pages/api/monologue/shares/[id].ts`
- Create: `src/pages/monologue/s/[id].astro`
- Create: `public/.well-known/apple-app-site-association`
- Create: `public/.well-known/assetlinks.json`
- Create: `vercel.json`
- Modify: `tests/build.test.ts` (끝에 추가)

**Interfaces:**
- Consumes: Task 3 `ShareStore`, `Kv`, `PublicShare`; Task 4 `handleCreate`, `handleGet`, `handleDelete`, `json`, `shareUrl`, `appOpenUrl`, `NO_STORE_HEADERS`, `parseDialogue`
- Produces: 배포하면 동작하는 `/api/monologue/shares`, `/api/monologue/shares/<ID>`, `/monologue/s/<ID>`, `/.well-known/*`

- [ ] **Step 1: 빌드 테스트에 기대를 먼저 추가**

`tests/build.test.ts` 끝에 추가:

```ts
describe('monologue share build output', () => {
  const clientFile = (path: string) => new URL(`../dist/client/${path}`, import.meta.url);

  it('앱 링크 인증 파일이 정적으로 나온다', () => {
    const aasa = JSON.parse(readFileSync(clientFile('.well-known/apple-app-site-association'), 'utf8'));
    expect(aasa.applinks.details[0].appIDs).toEqual(['3996SU7HLL.com.tacowasabii.monologue']);
    expect(aasa.applinks.details[0].components).toEqual([{ '/': '/monologue/s/*' }]);
    const links = JSON.parse(readFileSync(clientFile('.well-known/assetlinks.json'), 'utf8'));
    expect(links[0].target.package_name).toBe('com.tacowasabii.monologue');
    expect(links[0].target.sha256_cert_fingerprints).toContain(
      '6C:DB:D3:4B:C1:76:8C:D6:86:36:09:CE:4F:FC:00:7A:51:7D:85:13:0F:19:81:D3:50:B4:EB:80:BF:F5:37:C6',
    );
  });

  it('공유 대본 페이지는 정적으로 만들지 않고, 소개·개인정보 페이지는 정적으로 남는다', () => {
    expect(existsSync(clientFile('monologue/index.html'))).toBe(true);
    expect(existsSync(clientFile('monologue/privacy/index.html'))).toBe(true);
    expect(existsSync(clientFile('monologue/s'))).toBe(false);
  });
});
```

Run: `npm test`
Expected: FAIL — `.well-known/apple-app-site-association` 파일 없음(ENOENT)

- [ ] **Step 2: 앱 링크 인증 파일과 vercel.json**

`public/.well-known/apple-app-site-association` (확장자 없음):

```json
{
  "applinks": {
    "details": [
      {
        "appIDs": ["3996SU7HLL.com.tacowasabii.monologue"],
        "components": [{ "/": "/monologue/s/*" }]
      }
    ]
  }
}
```

`public/.well-known/assetlinks.json`:

```json
[
  {
    "relation": ["delegate_permission/common.handle_all_urls"],
    "target": {
      "namespace": "android_app",
      "package_name": "com.tacowasabii.monologue",
      "sha256_cert_fingerprints": [
        "6C:DB:D3:4B:C1:76:8C:D6:86:36:09:CE:4F:FC:00:7A:51:7D:85:13:0F:19:81:D3:50:B4:EB:80:BF:F5:37:C6"
      ]
    }
  }
]
```

`vercel.json`:

```json
{
  "$schema": "https://openapi.vercel.sh/vercel.json",
  "regions": ["icn1"],
  "headers": [
    {
      "source": "/.well-known/apple-app-site-association",
      "headers": [{ "key": "Content-Type", "value": "application/json" }]
    }
  ]
}
```

- [ ] **Step 3: Redis Kv, 저장소 인스턴스, 사이트 정보**

`src/lib/monologue-share/redis.ts`:

```ts
import { Redis } from '@upstash/redis';
import type { Kv } from './store';

/** Vercel Marketplace로 연결한 Upstash Redis. 환경 변수 이름은 설치 방식에 따라 둘 중 하나로 들어온다 */
export function upstashKv(env: Record<string, string | undefined> = process.env): Kv {
  const url = env.UPSTASH_REDIS_REST_URL ?? env.KV_REST_API_URL;
  const token = env.UPSTASH_REDIS_REST_TOKEN ?? env.KV_REST_API_TOKEN;
  if (!url || !token) throw new Error('Upstash Redis 환경 변수가 없습니다');
  // 값은 우리가 직접 JSON으로 다루므로 자동 변환을 끈다
  const redis = new Redis({ url, token, automaticDeserialization: false });
  return {
    get: (key) => redis.get<string>(key),
    set: async (key, value, ttlSeconds) => {
      await redis.set(key, value, { ex: ttlSeconds });
    },
    del: async (key) => {
      await redis.del(key);
    },
    incr: async (key, ttlSeconds) => {
      const count = await redis.incr(key);
      if (count === 1) await redis.expire(key, ttlSeconds);
      return count;
    },
  };
}
```

`src/lib/monologue-share/instance.ts`:

```ts
import { json } from './http';
import { upstashKv } from './redis';
import { ShareStore } from './store';

let cached: ShareStore | undefined;

export function shareStore(): ShareStore {
  cached ??= new ShareStore(upstashKv());
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
```

`src/lib/monologue-share/site.ts`:

```ts
/** 문제 링크 신고를 받을 주소. Play Console·App Store Connect에 등록한 개발자 연락처 이메일과 같게 둔다 */
export const REPORT_EMAIL = 'cloud-tech@naver.com';

/** 스토어에 올라가면 주소를 넣는다. null이면 웹 보기에서 "곧 출시돼요"를 보여 준다 */
export const STORE_LINKS: { appStore: string | null; googlePlay: string | null } = {
  appStore: null,
  googlePlay: null,
};
```

`REPORT_EMAIL`은 공개 페이지에 실린다. 이 태스크를 실행하기 전에 컨트롤러(메인 세션)가 사용자에게 공개할 연락처 이메일을 확인받고, 다른 주소를 받으면 그 값으로 바꾼다.

- [ ] **Step 4: API 경로**

`src/pages/api/monologue/shares/index.ts`:

```ts
import type { APIRoute } from 'astro';
import { handleCreate } from '../../../../lib/monologue-share/handlers';
import { clientKey, withStore } from '../../../../lib/monologue-share/instance';

export const prerender = false;

export const POST: APIRoute = ({ request, clientAddress }) =>
  withStore((store) => handleCreate(request, store, clientKey(request, () => clientAddress)));
```

`src/pages/api/monologue/shares/[id].ts`:

```ts
import type { APIRoute } from 'astro';
import { handleDelete, handleGet } from '../../../../lib/monologue-share/handlers';
import { withStore } from '../../../../lib/monologue-share/instance';

export const prerender = false;

export const GET: APIRoute = ({ params }) => withStore((store) => handleGet(params.id ?? '', store));

export const DELETE: APIRoute = ({ params, request }) =>
  withStore((store) => handleDelete(params.id ?? '', request, store));
```

- [ ] **Step 5: 웹 보기 페이지**

`src/pages/monologue/s/[id].astro`:

```astro
---
import { parseDialogue } from '../../../lib/monologue-share/dialogue';
import { appOpenUrl, NO_STORE_HEADERS } from '../../../lib/monologue-share/http';
import { shareStore } from '../../../lib/monologue-share/instance';
import { REPORT_EMAIL, STORE_LINKS } from '../../../lib/monologue-share/site';
import type { PublicShare } from '../../../lib/monologue-share/store';

export const prerender = false;

const id = Astro.params.id ?? '';
let share: PublicShare | null = null;
let unavailable = false;
try {
  share = await shareStore().get(id);
} catch {
  unavailable = true;
}
for (const [key, value] of Object.entries(NO_STORE_HEADERS)) Astro.response.headers.set(key, value);
if (!share) Astro.response.status = unavailable ? 503 : 404;

const firstLine = (body: string) => body.split('\n').map((l) => l.trim()).find((l) => l !== '') ?? '';
const title = share ? (share.work ?? firstLine(share.body)) : '모노로그';
const genderLabel = { any: null, male: '남', female: '여' } as const;
const ageLabel = { any: null, teens: '10대', twenties: '20대', thirties: '30대', forties: '40대', fiftiesPlus: '50대 이상' } as const;
const labels = share
  ? [genderLabel[share.gender], ageLabel[share.ageRange], ...share.tags.map((t) => `#${t}`)].filter((l): l is string => l !== null)
  : [];
const daysLeft = share ? Math.max(1, Math.ceil((Date.parse(share.expiresAt) - Date.now()) / 86_400_000)) : 0;
const lines = share?.dialogue ? parseDialogue(share.body) : [];
const description = '모노로그로 받은 대본 · 7일 뒤 사라져요';
---

<html lang="ko">
  <head>
    <meta charset="utf-8" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="color-scheme" content="light dark" />
    <meta name="robots" content="noindex" />
    <title>{share ? `${title} · 모노로그` : '사라진 링크 · 모노로그'}</title>
    <meta property="og:type" content="website" />
    <meta property="og:title" content={share ? title : '사라진 링크'} />
    <meta property="og:description" content={description} />
    <link rel="stylesheet" href="https://cdn.jsdelivr.net/gh/orioncactus/pretendard@v1.3.9/dist/web/variable/pretendardvariable-dynamic-subset.min.css" />
  </head>
  <body>
    <main>
      <p class="eyebrow">모노로그로 받은 대본</p>
      {share ? (
        <>
          <h1>{title}</h1>
          {labels.length > 0 && <p class="labels">{labels.map((l) => <span>{l}</span>)}</p>}
          <p class="muted">{daysLeft}일 뒤 이 링크가 사라져요</p>
          <div class="actions">
            <a class="primary" href={appOpenUrl(id)}>앱에서 열기</a>
            {STORE_LINKS.appStore && <a href={STORE_LINKS.appStore}>App Store</a>}
            {STORE_LINKS.googlePlay && <a href={STORE_LINKS.googlePlay}>Google Play</a>}
            {!STORE_LINKS.appStore && !STORE_LINKS.googlePlay && <span class="soon">App Store · Google Play 곧 출시돼요</span>}
          </div>
          {share.note && (
            <section class="note">
              <h2>노트</h2>
              <p class="pre">{share.note}</p>
            </section>
          )}
          <section class="script">
            {share.dialogue ? (
              lines.map((l) =>
                l.direction ? (
                  <p class="direction pre">{l.text}</p>
                ) : (
                  <div class="line">
                    <p class="speaker">{l.speaker}</p>
                    <p class="pre">{l.text}</p>
                  </div>
                ),
              )
            ) : (
              <p class="pre">{share.body}</p>
            )}
          </section>
        </>
      ) : (
        <>
          <h1>{unavailable ? '잠시 뒤 다시 열어 주세요' : '사라진 링크예요'}</h1>
          <p class="muted">
            {unavailable ? '지금 대본을 불러올 수 없어요.' : '7일이 지나 사라졌거나 보낸 사람이 지운 링크예요.'}
          </p>
        </>
      )}
      <footer>
        <a href="/monologue">모노로그 소개</a>
        <a href="/monologue/privacy">개인정보처리방침</a>
        <span>문제가 있는 링크 신고: <a href={`mailto:${REPORT_EMAIL}`}>{REPORT_EMAIL}</a></span>
      </footer>
    </main>
  </body>
</html>

<style is:global>
  :root {
    --bg: #f6f5f2;
    --fg: #1b1b1c;
    --muted: #6d6c69;
    --line: #e6e4df;
    --accent: #7a4b5c;
    --accent-soft: #f1e6ea;
  }
  @media (prefers-color-scheme: dark) {
    :root {
      --bg: #111213;
      --fg: #ececeb;
      --muted: #9b9a97;
      --line: #2a2b2e;
      --accent: #d9a7b8;
      --accent-soft: #2c2226;
    }
  }
  body {
    margin: 0;
    background: var(--bg);
    color: var(--fg);
    font-family: 'Pretendard Variable', Pretendard, -apple-system, BlinkMacSystemFont, system-ui, 'Apple SD Gothic Neo', 'Noto Sans KR', sans-serif;
    line-height: 1.75;
    -webkit-font-smoothing: antialiased;
    word-break: keep-all;
  }
  main {
    max-width: 680px;
    margin: 0 auto;
    padding: 48px 20px 96px;
  }
  .eyebrow {
    margin: 0;
    color: var(--accent);
    font-weight: 600;
  }
  h1 {
    margin: 4px 0 0;
    font-size: clamp(26px, 5vw, 34px);
    letter-spacing: -0.02em;
    line-height: 1.3;
  }
  h2 {
    margin: 0 0 6px;
    font-size: 15px;
    color: var(--accent);
  }
  .muted {
    color: var(--muted);
    margin: 6px 0 0;
  }
  .labels {
    display: flex;
    flex-wrap: wrap;
    gap: 6px;
    margin: 14px 0 0;
  }
  .labels span {
    padding: 2px 10px;
    border-radius: 999px;
    background: var(--accent-soft);
    color: var(--accent);
    font-size: 14px;
    font-weight: 600;
  }
  .actions {
    display: flex;
    flex-wrap: wrap;
    align-items: center;
    gap: 10px;
    margin: 22px 0 0;
  }
  .actions a {
    padding: 10px 18px;
    border-radius: 999px;
    border: 1px solid var(--line);
    color: var(--fg);
    text-decoration: none;
    font-weight: 600;
  }
  .actions a.primary {
    background: var(--accent);
    border-color: var(--accent);
    color: #fff;
  }
  .soon {
    color: var(--muted);
    font-size: 14px;
  }
  .note {
    margin: 28px 0 0;
    padding: 16px 18px;
    border: 1px solid var(--line);
    border-radius: 18px;
  }
  .script {
    margin: 32px 0 0;
    font-size: 18px;
  }
  .pre {
    white-space: pre-wrap;
    margin: 0;
  }
  .line {
    margin: 0 0 16px;
  }
  .speaker {
    margin: 0;
    font-size: 14px;
    font-weight: 700;
    color: var(--accent);
  }
  .direction {
    margin: 0 0 16px;
    color: var(--muted);
    font-size: 15px;
  }
  footer {
    display: flex;
    flex-wrap: wrap;
    gap: 8px 16px;
    margin-top: 56px;
    font-size: 13px;
    color: var(--muted);
  }
  footer a {
    color: var(--muted);
  }
</style>
```

- [ ] **Step 6: 빌드와 전체 테스트**

Run: `rm -rf dist .vercel/output && npm test`
Expected: 빌드 성공, `tests/build.test.ts`(새 2개 포함)와 `tests/monologue-share.test.ts` 모두 PASS. `ls .vercel/output/functions`에 `_render.func`가 있다.

- [ ] **Step 7: 커밋**

```bash
git add public/.well-known vercel.json src/lib/monologue-share src/pages/api src/pages/monologue/s tests/build.test.ts
git commit -m "feat(monologue-share): share API routes, web view page and app link files

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

---

### Task 6: Upstash Redis 연결, 배포, 실제 주소 확인

**Files:**
- Modify: `src/lib/monologue-share/site.ts` (데이터 지역 기록 추가)

**Interfaces:**
- Consumes: Task 5 전체
- Produces: 운영 중인 공유 API. `SHARE_DATA_LOCATION`(앱 계획의 개인정보처리방침 태스크가 읽는다)

- [ ] **Step 1: Upstash Redis 설치(무료 요금제)**

```bash
cd /Users/tacowasabii/website
vercel install upstash
```

프롬프트가 나오면: 제품 **Upstash for Redis**, 요금제 **Free**, 이름 `monologue-share`, 지역은 서울과 가장 가까운 선택지(도쿄 `ap-northeast-1`이 있으면 그것), 연결할 프로젝트 `tacowasabii`, 환경 Production·Preview. 브라우저에서 약관 동의를 요구하면 멈추고 컨트롤러에게 알린다(사용자가 브라우저에서 동의해야 한다).

- [ ] **Step 2: 환경 변수 이름 확인(값은 출력하지 않는다)**

```bash
vercel env ls production 2>&1 | grep -E "UPSTASH_REDIS_REST_(URL|TOKEN)|KV_REST_API_(URL|TOKEN)" | awk '{print $1}'
```

Expected: `UPSTASH_REDIS_REST_URL`·`UPSTASH_REDIS_REST_TOKEN` 또는 `KV_REST_API_URL`·`KV_REST_API_TOKEN` 두 줄. 둘 다 없으면 `redis.ts`가 읽는 이름과 실제 이름을 맞춘다.

- [ ] **Step 3: 데이터 지역 기록**

Upstash 설치 출력(또는 `vercel integration list`/Upstash 대시보드)에서 확인한 지역을 `src/lib/monologue-share/site.ts` 끝에 추가한다. 예: 도쿄를 골랐다면

```ts
/** 개인정보처리방침의 국외 이전 항목에 쓴다. 저장소를 옮기면 함께 고친다 */
export const SHARE_DATA_LOCATION = {
  functions: { company: 'Vercel Inc.', country: '미국 법인, 서울(icn1) 지역에서 실행' },
  storage: { company: 'Upstash, Inc.', country: '미국 법인, 일본 도쿄(ap-northeast-1) 지역에 저장' },
} as const;
```

실제로 고른 지역 이름으로 `storage.country`를 적는다.

- [ ] **Step 4: 배포**

```bash
rm -rf dist .vercel/output && npm test && vercel --prod --yes
```

Expected: 테스트 통과, 배포 `● Ready`.

- [ ] **Step 5: 실제 주소 확인**

```bash
BASE=https://tacowasabii.vercel.app
curl -s -o /dev/null -w "privacy %{http_code}\n" $BASE/monologue/privacy
curl -sI $BASE/.well-known/apple-app-site-association | grep -iE "^HTTP|content-type"
curl -s $BASE/.well-known/assetlinks.json | python3 -c "import sys,json; print('assetlinks', json.load(sys.stdin)[0]['target']['package_name'])"
RES=$(curl -s -X POST $BASE/api/monologue/shares -H 'Content-Type: application/json' \
  -d '{"v":1,"work":"배포 확인","dialogue":true,"body":"민수: 안녕\n지영: 반가워","gender":"any","ageRange":"any","tags":["확인"],"note":null}')
ID=$(echo "$RES" | python3 -c "import sys,json; print(json.load(sys.stdin)['id'])")
TOKEN=$(echo "$RES" | python3 -c "import sys,json; print(json.load(sys.stdin)['deleteToken'])")
curl -s -o /dev/null -w "get %{http_code}\n" $BASE/api/monologue/shares/$ID
curl -s $BASE/monologue/s/$ID | grep -oE "<h1>[^<]*</h1>|monologue://s/[A-Za-z0-9_-]+|noindex" | sort -u
curl -sI $BASE/monologue/s/$ID | grep -iE "^HTTP|cache-control|x-robots-tag"
curl -s -o /dev/null -w "delete %{http_code}\n" -X DELETE $BASE/api/monologue/shares/$ID -H "Authorization: Bearer $TOKEN"
curl -s -o /dev/null -w "after delete %{http_code}\n" $BASE/api/monologue/shares/$ID
curl -s -o /dev/null -w "gone page %{http_code}\n" $BASE/monologue/s/$ID
```

Expected:
- `privacy 200`
- AASA `HTTP/2 200`, `content-type: application/json`
- `assetlinks com.tacowasabii.monologue`
- `get 200`, 페이지에 `<h1>배포 확인</h1>`, `monologue://s/<ID>`, `noindex`; 헤더 `cache-control: no-store`, `x-robots-tag: noindex`
- `delete 204`, `after delete 404`, `gone page 404`

AASA의 `content-type`이 `application/json`이 아니면(어댑터 출력이 `vercel.json` 헤더를 무시한 경우) 이렇게 바꾼다.

1. `public/.well-known/apple-app-site-association`을 지운다.
2. `src/pages/api/aasa.ts`를 만든다.

```ts
import type { APIRoute } from 'astro';

export const prerender = false;

export const AASA = {
  applinks: {
    details: [{ appIDs: ['3996SU7HLL.com.tacowasabii.monologue'], components: [{ '/': '/monologue/s/*' }] }],
  },
};

export const GET: APIRoute = () =>
  new Response(JSON.stringify(AASA), { headers: { 'Content-Type': 'application/json' } });
```

3. `vercel.json`의 `headers`를 지우고 `"rewrites": [{ "source": "/.well-known/apple-app-site-association", "destination": "/api/aasa" }]`를 넣는다.
4. `tests/build.test.ts`의 AASA 검사를 `import { AASA } from '../src/pages/api/aasa';`로 바꿔 `AASA.applinks.details[0]`의 `appIDs`, `components`를 확인한다.
5. Step 4~5를 다시 한다.

어느 확인이든 기대와 다르고 바로 고칠 수 없으면 `vercel rollback --yes`로 이전 배포로 되돌리고 컨트롤러에게 알린다.

- [ ] **Step 6: 커밋**

```bash
git add src/lib/monologue-share/site.ts
git commit -m "feat(monologue-share): record where shared scripts are stored

Co-Authored-By: Claude Opus 5 (1M context) <noreply@anthropic.com>"
```

- [ ] **Step 7: 스크래치 정리**

```bash
rm -rf /private/tmp/claude-501/-Users-tacowasabii-orca-workspaces-monologue-hagfish/8dfd8a5e-41fb-47f5-881c-a962679f6085/scratchpad/site-spike
```

---

## 나중에 할 일(이 계획 범위 밖, 앱 계획이 처리)

- Play 앱 서명 키 SHA-256을 받으면 `public/.well-known/assetlinks.json`의 `sha256_cert_fingerprints`에 두 번째 값으로 추가하고, `tests/build.test.ts`에 그 값을 기대하는 줄을 추가한 뒤 배포한다.
- 스토어 주소가 생기면 `STORE_LINKS`를 채우고 배포한다.
