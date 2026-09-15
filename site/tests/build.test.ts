import { existsSync, readFileSync } from 'node:fs';
import { describe, expect, it } from 'vitest';

const clientFile = (path: string) => new URL(`../dist/client/${path}`, import.meta.url);

describe('build output', () => {
  it('소개·개인정보 페이지는 정적으로 남고, 공유 대본 페이지는 정적으로 만들지 않는다', () => {
    expect(existsSync(clientFile('index.html'))).toBe(true);
    expect(existsSync(clientFile('privacy/index.html'))).toBe(true);
    expect(existsSync(clientFile('s'))).toBe(false);
  });

  it('링크 미리보기 이미지가 정적으로 나오고, 페이지는 절대 주소로 가리킨다', () => {
    expect(existsSync(clientFile('og-image.png'))).toBe(true);
    for (const page of ['index.html', 'privacy/index.html']) {
      expect(readFileSync(clientFile(page), 'utf8')).toContain('<meta property="og:image" content="https://monologue.ink/og-image.png"');
    }
  });

  it('앱 링크 인증 파일이 정적으로 나온다', () => {
    const aasa = JSON.parse(readFileSync(clientFile('.well-known/apple-app-site-association'), 'utf8'));
    expect(aasa.applinks.details[0].appIDs).toEqual(['3996SU7HLL.com.tacowasabii.monologue']);
    expect(aasa.applinks.details[0].components).toEqual([{ '/': '/s/*' }]);
    const links = JSON.parse(readFileSync(clientFile('.well-known/assetlinks.json'), 'utf8'));
    expect(links[0].target.package_name).toBe('com.tacowasabii.monologue');
    expect(links[0].target.sha256_cert_fingerprints).toContain(
      '6C:DB:D3:4B:C1:76:8C:D6:86:36:09:CE:4F:FC:00:7A:51:7D:85:13:0F:19:81:D3:50:B4:EB:80:BF:F5:37:C6',
    );
    expect(links[0].target.sha256_cert_fingerprints).toContain('8D:2C:88:60:7B:5B:F3:B7:C3:64:A5:E3:A2:1E:CC:67:7F:32:A7:23:65:BC:62:08:A7:F0:69:75:53:18:53:53');
  });

  it('Android 테스트 APK가 있으면 정적으로 나온다 (git-ignore된 파일이라 소스에 없으면 건너뛴다)', (ctx) => {
    const sourceApk = new URL('../public/downloads/monologue-android-test.apk', import.meta.url);
    if (!existsSync(sourceApk)) {
      ctx.skip('public/downloads/monologue-android-test.apk 없음 — git으로 관리하지 않는 파일이라 이 환경엔 복사돼 있지 않습니다');
      return;
    }
    expect(existsSync(clientFile('downloads/monologue-android-test.apk'))).toBe(true);
  });
});
