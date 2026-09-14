export interface ShareInput {
  v: 1;
  work: string | null;
  dialogue: boolean;
  body: string;
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

/**
 * 앱이 올린 대본을 검사한다. 모르는 칸은 저장하지 않는다.
 * 성별·나이대를 뺀 뒤에도 예전 앱은 gender·ageRange를 함께 보내므로, 거절하지 않고 버린다.
 */
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
      tags,
      note: blankToNull(note),
    },
  };
}
