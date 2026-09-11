# 모노로그 — 설계

작성일: 2026-09-11 · 상태: 승인됨

## 목적

연기용 독백 대본을 캡처해서 사진첩에 흩어두는 대신, 사진을 올리면 텍스트를 인식해 한곳에 모아 검색·열람할 수 있는 모바일 앱.
아이폰·갤럭시 모두 지원하고 App Store·Google Play에 출시한다.

## 결정 사항

| 항목 | 결정 |
|---|---|
| 저장 | 기기 로컬만. 로그인·서버·네트워크 통신 없음 |
| 텍스트 인식 | 기기 내 처리. Android: Google ML Kit Text Recognition v2 한글 모델(Kotlin에서 직접 호출). iOS: Apple Vision `VNRecognizeTextRequest`(ko-KR, en-US). 두 플랫폼 모두 `MethodChannel('monologue/ocr')`로 줄 목록(text, top, left, height)을 돌려주고 Dart의 `groupLines`가 문단으로 묶는다 |
| 인식 방식 변경 (2026-09-11) | 처음엔 Flutter 플러그인 `google_mlkit_text_recognition`을 썼으나, ML Kit iOS에 arm64 시뮬레이터 바이너리가 없어 iOS 26 시뮬레이터(arm64 전용)에서 빌드·실행 불가, 플러그인이 SPM 미지원(향후 Flutter에서 오류 예정)이라 사용자 결정으로 iOS는 Vision으로 교체. 플러그인이 있으면 iOS에 ML Kit pod이 딸려오므로 플러그인을 제거하고 양쪽을 네이티브 채널로 구현 |
| 여러 장 | 여러 장을 한 대본으로 합침. 사용자가 순서 조정 |
| 입력 | 사진첩 다중 선택 + 카메라 촬영(연속 여러 장) |
| 앱 이름 / 번들 ID | 모노로그 / `com.tacowasabii.monologue` |
| UI 언어 | 한국어만 |
| 플랫폼 | iOS 16.0+ (Vision 한글 인식 최소), Android minSdk = `flutter.minSdkVersion` |
| 스택 | Flutter 3.47.3, Dart 3.13, drift + drift_flutter + sqlite3, google_mlkit_text_recognition, image_picker |

## 데이터 모델

`Scripts` 테이블
- `id` int PK
- `title` text, 필수 (기본값: 본문 첫 줄 앞 20자)
- `work` text? 작품명 · `character` text? 인물
- `gender` enum: 무관 / 남 / 여 (기본 무관)
- `ageRange` enum: 무관 / 10대 / 20대 / 30대 / 40대 / 50대 이상 (기본 무관)
- `status` enum: 연습 전 / 연습 중 / 다 외움 (기본 연습 전)
- `favorite` bool (기본 false)
- `body` text, 필수
- `createdAt`, `updatedAt` datetime

`ScriptTags` 테이블 — (`scriptId`, `tag`) 복합 PK. 분위기 태그는 자유 입력, 기존 태그 자동완성.

`ScriptImages` 테이블 — `id`, `scriptId`, `fileName`, `position`. 이미지 파일은 앱 지원 디렉터리 `images/`에 복사해 보관(사진첩 원본이 지워져도 유지). 대본 삭제 시 이미지 파일도 삭제.

## 화면

1. **목록** — 최근 수정순. 상단 검색(제목·작품명·인물·본문 부분 일치, `LIKE`). 필터 칩: 성별, 나이대, 태그, 연습 상태, 즐겨찾기. 항목: 제목, 작품명·인물, 태그, 상태, 별. FAB "대본 추가".
2. **대본 보기** — 제목·메타 정보, 본문을 큰 글씨로. 글자 크기 조절(설정에 저장). 즐겨찾기·상태 바로 변경. "원본 보기"로 캡처 이미지 넘겨보기. 편집·삭제(확인 대화상자).
3. **추가/편집** — 새 대본: 사진 선택 → 순서 정렬 → 인식 → 편집. 편집 화면: 제목, 작품명, 인물, 성별, 나이대, 태그, 상태, 본문(여러 줄 텍스트). 기존 대본 편집에서도 사진 추가 인식 가능(본문 끝에 이어붙임).
4. **설정** — 백업 내보내기, 백업에서 복원, 개인정보처리방침 링크, 앱 버전.

## 인식 흐름

1. `image_picker`로 사진첩 다중 선택 또는 카메라 촬영. 촬영은 "한 장 더 찍기"로 반복.
2. 순서 정렬 화면: 썸네일 목록, 드래그로 순서 변경, 개별 삭제.
3. 각 이미지를 ML Kit(Korean script)로 인식. 진행률 표시.
4. 텍스트 조립 규칙(순수 함수 `assembleText`):
   - 인식 블록을 위→아래 순서로 정렬.
   - 블록 안의 줄은 이어붙인다. 한 줄 끝과 다음 줄 사이에 공백 하나(줄 끝이 이미 공백·하이픈이 아닐 때).
   - 블록 사이는 빈 줄 하나(`\n\n`).
   - 이미지 사이도 빈 줄 하나.
   - 앞뒤 공백 제거, 연속 빈 줄은 하나로.
5. 결과를 편집 화면 본문에 채움. 인식 결과가 비면 "글자를 찾지 못했어요" 안내 후 직접 입력 가능.

## 백업

- 내보내기: `monologue-backup-YYYYMMDD.zip` = `backup.json`(버전, 대본·태그·이미지 메타) + `images/*`. 시스템 공유 시트로 전달.
- 복원: 파일 선택 → 형식·버전 검증 → 확인 대화상자("현재 대본에 추가됩니다") → 대본을 새 id로 추가(기존 데이터 유지, 덮어쓰지 않음).
- 잘못된 파일이면 오류 안내 후 아무것도 바꾸지 않음(트랜잭션).

## 권한·개인정보

- iOS `Info.plist`: `NSCameraUsageDescription`, `NSPhotoLibraryUsageDescription` 한국어 문구.
- Android: 카메라는 `image_picker`가 시스템 카메라 앱 사용, 사진 선택은 Photo Picker 사용 → 별도 저장소 권한 없음.
- 개인정보처리방침: tacowasabii.vercel.app `/monologue/privacy` 페이지. 내용: 수집·전송하는 데이터 없음, 모든 데이터 기기 내 저장, 텍스트 인식 기기 내 처리.

## 출시 준비

- 앱 아이콘(iOS·Android 적응형), 스플래시는 기본.
- iOS: 번들 ID, 표시 이름 "모노로그", 버전 1.0.0(1). Android: applicationId, 앱 이름, 릴리스 서명 키 생성(키 파일은 저장소 밖 보관).
- 스토어 등록 문구·스크린샷 초안.
- 계정 가입(Apple Developer $99/년, Google Play Console $25 1회)과 제출은 사용자가 계정을 만든 뒤 진행. Google Play 개인 계정의 비공개 테스트 요구사항은 그 시점 정책을 확인.

## 오류 처리

- 권한 거부: 설정 앱 열기 안내.
- 인식 실패(예외): 해당 이미지만 실패 표시, 나머지는 계속. 전부 실패하면 직접 입력으로.
- DB 쓰기는 대본+태그+이미지 한 트랜잭션. 이미지 파일 복사 실패 시 롤백하고 복사된 파일 정리.

## 테스트

- 단위: `assembleText` 규칙, 검색·필터 쿼리(in-memory drift), 대본 저장/삭제 시 이미지 정리, 백업→복원 왕복(내용 동일, id 새로 부여), 잘못된 백업 파일 거부.
- 위젯: 목록 검색·필터, 편집 화면 저장 검증(본문 비면 저장 불가).
- 수동/통합: 한글 대본 캡처 샘플로 iOS 시뮬레이터·Android 에뮬레이터에서 실제 인식 확인.

## 범위 밖

클라우드 동기화, 로그인, 사진 자르기, 녹음·암기 도우미, 다국어 UI, 태블릿 전용 레이아웃.
