import { createHash, createHmac, randomBytes, timingSafeEqual } from 'node:crypto';

const SHARE_ID_PATTERN = /^[A-Za-z0-9_-]{22}$/;

/** 짐작할 수 없는 링크 ID(16바이트 → base64url 22자) */
export const newShareId = () => randomBytes(16).toString('base64url');

/** 보낸 사람만 가진 삭제 비밀값(32바이트) */
export const newDeleteToken = () => randomBytes(32).toString('base64url');

export const sha256Hex = (value: string) => createHash('sha256').update(value).digest('hex');

/** Keyed hash so the rate-limit key can't be reversed to the raw client key (irreversible per the privacy policy) */
export const hmacSha256Hex = (secret: string, value: string) => createHmac('sha256', secret).update(value).digest('hex');

export const isShareId = (value: string) => SHARE_ID_PATTERN.test(value);

/** 비밀값을 해시해 저장된 해시와 일정한 시간에 비교한다 */
export function tokenMatches(token: string, expectedHash: string): boolean {
  const actual = Buffer.from(sha256Hex(token), 'hex');
  const expected = Buffer.from(expectedHash, 'hex');
  return actual.length === expected.length && timingSafeEqual(actual, expected);
}
