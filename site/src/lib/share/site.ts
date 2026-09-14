/** 문제 링크 신고를 받을 주소. Play Console·App Store Connect에 등록한 개발자 연락처 이메일과 같게 둔다 */
export const REPORT_EMAIL = 'godseoril812@gmail.com';

/** 스토어에 올라가면 주소를 넣는다. null이면 웹 보기에서 "곧 출시돼요"를 보여 준다 */
export const STORE_LINKS: { appStore: string | null; googlePlay: string | null } = {
  appStore: null,
  googlePlay: null,
};

/** 개인정보처리방침의 국외 이전 항목에 쓴다. 저장소를 옮기면 함께 고친다 */
export const SHARE_DATA_LOCATION = {
  functions: { company: 'Vercel Inc.', country: '미국 법인, 서울(icn1) 지역에서 실행' },
  storage: { company: 'Upstash, Inc.', country: '미국 법인, 일본 도쿄(hnd1) 지역에 저장' },
} as const;
