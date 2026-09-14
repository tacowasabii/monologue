# 릴리스 빌드(R8)용 규칙.
#
# ML Kit은 매니페스트에 적힌 이름으로 구성 요소(Registrar)를 찾아 인자 없는 생성자를 리플렉션으로 만든다.
# R8은 이 생성자를 쓰는 곳을 못 찾아 지워 버리고, 그러면 ML Kit이 초기화되지 않아
# InputImage.fromFilePath에서 NullPointerException이 나서 모든 사진의 글자 인식이 실패한다
# (디버그 빌드에서는 멀쩡하고 릴리스에서만 생긴다. 2026-09-14 에뮬레이터에서 재현).
-keep class * implements com.google.firebase.components.ComponentRegistrar {
    public <init>();
}
-keep class com.google.mlkit.common.internal.CommonComponentRegistrar { <init>(); }
-keep class com.google.mlkit.vision.common.internal.VisionCommonRegistrar { <init>(); }
-keep class com.google.mlkit.vision.text.internal.TextRegistrar { <init>(); }
