export const SITE_ORIGIN = 'https://monologue.ink';

/** 카카오톡·문자 링크 미리보기 이미지. 미리보기 서버가 읽을 수 있게 절대 주소로 쓴다 */
export const OG_IMAGE = { url: `${SITE_ORIGIN}/og-image.png`, width: 1024, height: 500 } as const;

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

export const shareUrl = (id: string) => `${SITE_ORIGIN}/s/${id}`;

/** 웹 보기의 "앱에서 열기". 같은 사이트 안의 링크로는 Universal Link가 앱을 열지 않아 앱 전용 주소를 쓴다 */
export const appOpenUrl = (id: string) => `monologue://s/${id}`;
