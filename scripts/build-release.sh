#!/usr/bin/env bash
# 출시용 AAB와 테스트 APK를 만들어 main 체크아웃의 releases/<pubspec 버전>/에 모으고 BUILD.txt를 쓴다.
# worktree에서 실행해도 결과는 main 체크아웃(~/monologue)의 releases/에 들어간다. 규칙은 CLAUDE.md "출시 파일 보관".
#
#   scripts/build-release.sh [--overwrite] [--allow-dirty] ["바뀐 점 한 줄"]
#
# RELEASES_DIR를 주면 그 폴더 아래에 만든다(스크립트를 시험할 때).
set -euo pipefail

usage() { echo '사용법: scripts/build-release.sh [--overwrite] [--allow-dirty] ["바뀐 점 한 줄"]'; }

overwrite=false
allow_dirty=false
note=""
while [[ $# -gt 0 ]]; do
  case "$1" in
    --overwrite) overwrite=true ;;
    --allow-dirty) allow_dirty=true ;;
    -h | --help) usage; exit 0 ;;
    -*) usage >&2; exit 1 ;;
    *) note="$1" ;;
  esac
  shift
done

root=$(git rev-parse --show-toplevel)
cd "$root"
# 첫 번째 worktree가 main 체크아웃이다
main=$(git worktree list --porcelain | awk 'NR == 1 { print $2 }')

version=$(awk '/^version:/ { print $2 }' pubspec.yaml)
build=${version##*+}
dir="${RELEASES_DIR:-$main/releases}/$version"

if [[ "$allow_dirty" != true ]] && ! git diff --quiet HEAD; then
  echo "커밋하지 않은 변경이 있어요. BUILD.txt의 커밋과 파일이 달라지니 커밋한 뒤 실행하세요(그래도 만들려면 --allow-dirty)." >&2
  exit 1
fi
if [[ -f "$dir/app-release.aab" && "$overwrite" != true ]]; then
  echo "$dir 에 이미 AAB가 있어요." >&2
  echo "이 AAB를 Play에 올렸다면 같은 versionCode는 다시 올릴 수 없으니 pubspec.yaml의 빌드 번호를 먼저 올리세요." >&2
  echo "올리지 않았고 다시 만들려면 --overwrite를 붙이세요." >&2
  exit 1
fi

keys="$HOME/.monologue-keys/key.properties"
jbr="/Applications/Android Studio.app/Contents/jbr/Contents/Home/bin"
if [[ ! -f "$keys" ]]; then
  echo "$keys 가 없어요. 업로드 키 없이는 출시 빌드를 서명할 수 없어요." >&2
  exit 1
fi
# 서명 설정을 잠깐 넣었다가 끝나면(실패해도) 지운다. 이미 있으면(직접 연결해 둔 경우) 건드리지 않는다
placed_key=false
if [[ ! -e android/key.properties ]]; then
  cp "$keys" android/key.properties
  placed_key=true
fi
cleanup() {
  if [[ "$placed_key" == true ]]; then
    rm -f android/key.properties
  fi
}
trap cleanup EXIT

flutter build appbundle --release
flutter build apk --release --split-per-abi

mkdir -p "$dir"
cp build/app/outputs/bundle/release/app-release.aab "$dir/app-release.aab"
cp build/app/outputs/flutter-apk/app-arm64-v8a-release.apk "$dir/monologue-android-test.apk"

sha() { shasum -a 256 "$1" | cut -d' ' -f1; }
cert=$("$jbr/keytool" -printcert -jarfile "$dir/app-release.aab" | awk '/SHA256:/ && !v { v = $2 } END { print v }' | tr -d ':' | tr 'A-F' 'a-f')
if [[ "$root" == "$main" ]]; then
  where="main 체크아웃"
else
  where="$(basename "$root") worktree"
fi
commit="$(git branch --show-current) $(git log -1 --format='%h (%s)')"
if ! git diff --quiet HEAD; then
  commit="$commit + 커밋하지 않은 변경"
fi

{
  echo "모노로그 $version"
  echo
  echo "app-release.aab             Play 업로드용. versionCode $build. $(date '+%Y-%m-%d %H:%M') ${where}에서 빌드"
  # --split-per-abi는 arm64 APK의 versionCode 앞에 2를 붙인다(2000 + 빌드 번호)
  echo "monologue-android-test.apk  monologue.ink 테스트 APK(arm64). versionCode $((2000 + build))"
  echo "코드 기준: $commit"
  if [[ -n "$note" ]]; then
    echo "바뀐 점: $note"
  fi
  echo "서명: 업로드 키 (~/.monologue-keys), 인증서 SHA-256 $cert"
  echo
  echo "SHA-256"
  echo "$(sha "$dir/app-release.aab")  app-release.aab"
  echo "$(sha "$dir/monologue-android-test.apk")  monologue-android-test.apk"
} > "$dir/BUILD.txt"

echo
cat "$dir/BUILD.txt"
echo
echo "사이트 테스트 APK를 바꾸려면: cp \"$dir/monologue-android-test.apk\" \"$main/site/public/downloads/\" 한 뒤 사이트를 배포하세요(CLAUDE.md \"테스트 APK\")."
