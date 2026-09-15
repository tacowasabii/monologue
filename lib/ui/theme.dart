import 'package:flutter/material.dart';

import 'design/tokens.dart';

/// 제목과 대본 본문에 쓰는 명조체. 번들 폰트에 없는 글자는 시스템 글꼴로 대체된다.
const serifFamily = 'GowunBatang';

const brandPlum = Color(0xFF7A4B5C);

const _light = ColorScheme(
  brightness: Brightness.light,
  primary: brandPlum,
  onPrimary: Colors.white,
  primaryContainer: Color(0xFFF2E4E8),
  onPrimaryContainer: Color(0xFF4A2634),
  secondary: Color(0xFF86705F),
  onSecondary: Colors.white,
  secondaryContainer: Color(0xFFEFE6DC),
  onSecondaryContainer: Color(0xFF3E2F24),
  tertiary: Color(0xFFB07A2E),
  onTertiary: Colors.white,
  tertiaryContainer: Color(0xFFF6E7CC),
  onTertiaryContainer: Color(0xFF4A3210),
  error: Color(0xFFB3261E),
  onError: Colors.white,
  errorContainer: Color(0xFFF9DEDC),
  onErrorContainer: Color(0xFF410E0B),
  surface: Color(0xFFF7F3EE),
  onSurface: Color(0xFF241D20),
  onSurfaceVariant: Color(0xFF6F6468),
  surfaceContainerLowest: Color(0xFFFFFDFA),
  surfaceContainerLow: Color(0xFFF3EEE8),
  surfaceContainer: Color(0xFFEFE9E3),
  surfaceContainerHigh: Color(0xFFEAE3DC),
  surfaceContainerHighest: Color(0xFFE4DCD4),
  outline: Color(0xFFB5A9AD),
  outlineVariant: Color(0xFFE5DCD6),
  inverseSurface: Color(0xFF2E2629),
  onInverseSurface: Color(0xFFF7F0F1),
  inversePrimary: Color(0xFFE6B8C7),
  shadow: Color(0xFF2A1A20),
  scrim: Colors.black,
  surfaceTint: Colors.transparent,
);

const _dark = ColorScheme(
  brightness: Brightness.dark,
  primary: Color(0xFFE3B5C4),
  onPrimary: Color(0xFF45202E),
  primaryContainer: Color(0xFF5B3444),
  onPrimaryContainer: Color(0xFFF7DEE6),
  secondary: Color(0xFFD7C3B2),
  onSecondary: Color(0xFF3B2D22),
  secondaryContainer: Color(0xFF4A3D33),
  onSecondaryContainer: Color(0xFFF2E3D6),
  tertiary: Color(0xFFE2B774),
  onTertiary: Color(0xFF442C06),
  tertiaryContainer: Color(0xFF5E4214),
  onTertiaryContainer: Color(0xFFFCE3BC),
  error: Color(0xFFF2B8B5),
  onError: Color(0xFF601410),
  errorContainer: Color(0xFF8C1D18),
  onErrorContainer: Color(0xFFF9DEDC),
  surface: Color(0xFF171314),
  onSurface: Color(0xFFEEE6E8),
  onSurfaceVariant: Color(0xFFB4A8AD),
  surfaceContainerLowest: Color(0xFF211B1D),
  surfaceContainerLow: Color(0xFF1D1719),
  surfaceContainer: Color(0xFF241E20),
  surfaceContainerHigh: Color(0xFF2C2528),
  surfaceContainerHighest: Color(0xFF352D31),
  // 어두운 화면에서 고르지 않은 칩·입력칸 테두리가 배경에 묻히지 않을 만큼 밝게 둔다
  outline: Color(0xFF9A8D92),
  outlineVariant: Color(0xFF52474C),
  inverseSurface: Color(0xFFEEE6E8),
  onInverseSurface: Color(0xFF2E2629),
  inversePrimary: brandPlum,
  shadow: Colors.black,
  scrim: Colors.black,
  surfaceTint: Colors.transparent,
);

ThemeData buildTheme(Brightness brightness) {
  final scheme = brightness == Brightness.light ? _light : _dark;
  final base = ThemeData(colorScheme: scheme, useMaterial3: true);
  final text = base.textTheme;
  TextStyle serif(TextStyle? s, {double? size, FontWeight weight = FontWeight.w700}) =>
      (s ?? const TextStyle()).copyWith(
        fontFamily: serifFamily,
        fontSize: size,
        fontWeight: weight,
        letterSpacing: -0.2,
        color: scheme.onSurface,
      );
  final textTheme = text.copyWith(
    displaySmall: serif(text.displaySmall, size: 32),
    headlineMedium: serif(text.headlineMedium, size: 28),
    headlineSmall: serif(text.headlineSmall, size: 24),
    titleLarge: serif(text.titleLarge, size: 20),
    titleMedium: text.titleMedium?.copyWith(fontWeight: FontWeight.w600, letterSpacing: -0.1),
    labelLarge: text.labelLarge?.copyWith(fontWeight: FontWeight.w600, letterSpacing: 0),
    bodyLarge: text.bodyLarge?.copyWith(letterSpacing: -0.1),
    bodyMedium: text.bodyMedium?.copyWith(letterSpacing: -0.1),
  );
  final hairline = BorderSide(color: scheme.outlineVariant);
  final radius12 = BorderRadius.circular(AppRadius.small);
  final radius16 = BorderRadius.circular(AppRadius.medium);

  return base.copyWith(
    scaffoldBackgroundColor: scheme.surface,
    textTheme: textTheme,
    splashFactory: InkSparkle.splashFactory,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: serif(text.titleLarge, size: 19),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: scheme.onSurface),
    ),
    searchBarTheme: SearchBarThemeData(
      elevation: const WidgetStatePropertyAll(0),
      backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerLowest),
      surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
      overlayColor: const WidgetStatePropertyAll(Colors.transparent),
      side: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.focused) ? BorderSide(color: scheme.primary, width: 1.2) : hairline,
      ),
      shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: radius16)),
      constraints: const BoxConstraints(minHeight: 50),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(horizontal: 16)),
      textStyle: WidgetStatePropertyAll(text.bodyLarge?.copyWith(fontSize: 15, color: scheme.onSurface)),
      hintStyle: WidgetStatePropertyAll(text.bodyLarge?.copyWith(fontSize: 15, color: scheme.onSurfaceVariant)),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: Colors.transparent,
      side: hairline,
      shape: const StadiumBorder(),
      labelStyle: text.labelLarge?.copyWith(fontSize: 13, fontWeight: FontWeight.w500, color: scheme.onSurface),
      padding: const EdgeInsets.symmetric(horizontal: 6),
      labelPadding: const EdgeInsets.symmetric(horizontal: 4),
      showCheckmark: false,
      pressElevation: 0,
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: scheme.onSurface,
      foregroundColor: scheme.surface,
      elevation: 2,
      focusElevation: 2,
      hoverElevation: 3,
      highlightElevation: 3,
      shape: const StadiumBorder(),
      extendedTextStyle: text.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(64, 52),
        shape: RoundedRectangleBorder(borderRadius: radius16),
        textStyle: text.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(64, 48),
        foregroundColor: scheme.onSurface,
        side: BorderSide(color: scheme.outline.withValues(alpha: 0.6)),
        shape: RoundedRectangleBorder(borderRadius: radius16),
        textStyle: text.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        textStyle: text.labelLarge?.copyWith(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        visualDensity: VisualDensity.standard,
        side: WidgetStatePropertyAll(hairline),
        shape: WidgetStatePropertyAll(RoundedRectangleBorder(borderRadius: radius12)),
        // 고른 쪽은 칩과 같은 연한 자주 바탕 + 자주 글자(검은색·흰색으로 채우지 않는다)
        backgroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.primaryContainer : scheme.surfaceContainerLowest,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (s) => s.contains(WidgetState.selected) ? scheme.onPrimaryContainer : scheme.onSurfaceVariant,
        ),
        textStyle: WidgetStatePropertyAll(text.labelLarge?.copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerLowest,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      labelStyle: TextStyle(color: scheme.onSurfaceVariant),
      floatingLabelStyle: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600),
      hintStyle: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.7)),
      border: OutlineInputBorder(borderRadius: radius16, borderSide: hairline),
      enabledBorder: OutlineInputBorder(borderRadius: radius16, borderSide: hairline),
      focusedBorder: OutlineInputBorder(borderRadius: radius16, borderSide: BorderSide(color: scheme.primary, width: 1.4)),
      errorBorder: OutlineInputBorder(borderRadius: radius16, borderSide: BorderSide(color: scheme.error)),
      focusedErrorBorder: OutlineInputBorder(borderRadius: radius16, borderSide: BorderSide(color: scheme.error, width: 1.4)),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      margin: EdgeInsets.zero,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.large), side: hairline),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: scheme.onSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      titleTextStyle: text.bodyLarge?.copyWith(fontSize: 16, fontWeight: FontWeight.w500, color: scheme.onSurface),
      subtitleTextStyle: text.bodyMedium?.copyWith(fontSize: 13, color: scheme.onSurfaceVariant),
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant, thickness: 1, space: 1),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      surfaceTintColor: Colors.transparent,
      showDragHandle: true,
      dragHandleColor: scheme.outline.withValues(alpha: 0.5),
      dragHandleSize: const Size(36, 4),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.sheet))),
    ),
    dialogTheme: DialogThemeData(
      // 창이 뒤 화면과 같은 색이면 어두운 화면에서 경계가 흐려져 떠 보이지 않는다
      backgroundColor: brightness == Brightness.dark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.dialog)),
      titleTextStyle: serif(text.titleLarge, size: 20),
      contentTextStyle: text.bodyMedium?.copyWith(fontSize: 15, height: 1.55, color: scheme.onSurfaceVariant),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: scheme.surfaceContainerLowest,
      surfaceTintColor: Colors.transparent,
      elevation: 3,
      shadowColor: scheme.shadow.withValues(alpha: 0.25),
      shape: RoundedRectangleBorder(borderRadius: radius16, side: hairline),
      textStyle: text.bodyLarge?.copyWith(fontSize: 15, color: scheme.onSurface),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: text.bodyMedium?.copyWith(fontSize: 14, color: scheme.onInverseSurface),
      shape: RoundedRectangleBorder(borderRadius: radius12),
      elevation: 0,
    ),
    switchTheme: SwitchThemeData(
      trackOutlineColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.transparent : scheme.outline.withValues(alpha: 0.5),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: scheme.primary,
      linearTrackColor: scheme.primaryContainer,
      circularTrackColor: Colors.transparent,
    ),
    sliderTheme: SliderThemeData(
      activeTrackColor: scheme.primary,
      inactiveTrackColor: scheme.primaryContainer,
      thumbColor: scheme.primary,
    ),
  );
}

/// 즐겨찾기 별 색. 원색 노랑 대신 종이 톤에 맞는 금색.
Color favoriteColor(ColorScheme scheme) => scheme.tertiary;
