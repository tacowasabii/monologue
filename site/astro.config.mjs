import { defineConfig } from 'astro/config';
import vercel from '@astrojs/vercel';

export default defineConfig({
  site: 'https://monologue.ink',
  // 공유 API와 공유 대본 페이지만 요청 때 실행하고 나머지는 정적으로 만든다
  adapter: vercel(),
  // 쿠키 로그인이나 폼이 없고 공유 API는 Bearer 삭제 비밀값으로 권한을 확인하므로, 앱·curl의 DELETE를 막는 Origin 검사를 끈다
  security: { checkOrigin: false },
});
