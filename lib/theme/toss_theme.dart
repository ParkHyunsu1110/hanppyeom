import 'package:flutter/material.dart';

/// 토스(Toss) 스타일 디자인 토큰.
///
/// 화이트 배경 + 그레이 면 + 블루 포인트 하나. 색상은 여기 정의된 값만 쓰고,
/// 화면에서 하드코딩하지 않는다(의미색 — 성공 green, 경고 red 등 — 은 예외).
abstract final class TossColors {
  const TossColors._();

  // Primary (blue)
  static const Color blue = Color(0xFF3182F6);
  static const Color bluePressed = Color(0xFF1B64DA);
  static const Color blueWeak = Color(0xFFE8F2FE);

  // Grayscale
  static const Color g900 = Color(0xFF191F28);
  static const Color g800 = Color(0xFF333D4B);
  static const Color g700 = Color(0xFF4E5968);
  static const Color g600 = Color(0xFF6B7684);
  static const Color g500 = Color(0xFF8B95A1);
  static const Color g400 = Color(0xFFB0B8C1);
  static const Color g300 = Color(0xFFD1D6DB);
  static const Color g200 = Color(0xFFE5E8EB);
  static const Color g100 = Color(0xFFF2F4F6);
  static const Color g50 = Color(0xFFF9FAFB);
  static const Color white = Color(0xFFFFFFFF);

  /// surfaceContainerHigh 용 중간 톤.
  static const Color surfaceHigh = Color(0xFFEDF0F3);

  // Semantic
  static const Color red = Color(0xFFF04452);
}

const String _fontFamily = 'Pretendard';

/// 앱 전역 토스 스타일 테마. `app.dart`에서 `theme: tossTheme()`로 사용한다.
ThemeData tossTheme() {
  final ColorScheme colorScheme =
      ColorScheme.fromSeed(
        seedColor: TossColors.blue,
        brightness: Brightness.light,
      ).copyWith(
        primary: TossColors.blue,
        onPrimary: TossColors.white,
        primaryContainer: TossColors.blueWeak,
        onPrimaryContainer: TossColors.bluePressed,
        surface: TossColors.white,
        onSurface: TossColors.g900,
        surfaceContainerLowest: TossColors.white,
        surfaceContainerLow: TossColors.g50,
        surfaceContainer: TossColors.g100,
        surfaceContainerHigh: TossColors.surfaceHigh,
        surfaceContainerHighest: TossColors.g200,
        onSurfaceVariant: TossColors.g600,
        outline: TossColors.g300,
        outlineVariant: TossColors.g200,
        error: TossColors.red,
        onError: TossColors.white,
      );

  // 헤딩은 굵게(700~800) + letterSpacing 살짝 음수, 본문은 g700/g800.
  // 폰트 크기는 지정하지 않고 기본 타이포그래피 크기에 병합된다.
  const TextTheme textTheme = TextTheme(
    displayLarge: TextStyle(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.6,
      color: TossColors.g900,
    ),
    displayMedium: TextStyle(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      color: TossColors.g900,
    ),
    displaySmall: TextStyle(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      color: TossColors.g900,
    ),
    headlineLarge: TextStyle(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      color: TossColors.g900,
    ),
    headlineMedium: TextStyle(
      fontWeight: FontWeight.w800,
      letterSpacing: -0.4,
      color: TossColors.g900,
    ),
    headlineSmall: TextStyle(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.4,
      color: TossColors.g900,
    ),
    titleLarge: TextStyle(
      fontWeight: FontWeight.w700,
      letterSpacing: -0.3,
      color: TossColors.g900,
    ),
    titleMedium: TextStyle(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: TossColors.g900,
    ),
    titleSmall: TextStyle(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.2,
      color: TossColors.g800,
    ),
    bodyLarge: TextStyle(fontWeight: FontWeight.w500, color: TossColors.g800),
    bodyMedium: TextStyle(fontWeight: FontWeight.w400, color: TossColors.g700),
    bodySmall: TextStyle(fontWeight: FontWeight.w400, color: TossColors.g600),
    labelLarge: TextStyle(
      fontWeight: FontWeight.w600,
      letterSpacing: -0.1,
      color: TossColors.g800,
    ),
    labelMedium: TextStyle(fontWeight: FontWeight.w500, color: TossColors.g600),
    labelSmall: TextStyle(fontWeight: FontWeight.w500, color: TossColors.g600),
  );

  OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: width <= 0
            ? BorderSide.none
            : BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    fontFamily: _fontFamily,
    scaffoldBackgroundColor: TossColors.white,
    textTheme: textTheme,
    appBarTheme: const AppBarThemeData(
      backgroundColor: TossColors.white,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      foregroundColor: TossColors.g900,
      iconTheme: IconThemeData(color: TossColors.g900),
      titleTextStyle: TextStyle(
        fontFamily: _fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: TossColors.g900,
      ),
    ),
    cardTheme: CardThemeData(
      color: TossColors.white,
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: TossColors.g200),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: TossColors.blue,
        foregroundColor: TossColors.white,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    // FilledButton.tonal 사용처와 어울리게 tonal 느낌(연블루 배경 + 블루 전경).
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: TossColors.blueWeak,
        foregroundColor: TossColors.blue,
        elevation: 0,
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: TossColors.blue,
        minimumSize: const Size.fromHeight(52),
        side: const BorderSide(color: TossColors.g300),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: TossColors.blue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        textStyle: const TextStyle(
          fontFamily: _fontFamily,
          fontWeight: FontWeight.w700,
        ),
      ),
    ),
    inputDecorationTheme: InputDecorationThemeData(
      filled: true,
      fillColor: TossColors.g50,
      hintStyle: const TextStyle(color: TossColors.g500),
      labelStyle: const TextStyle(color: TossColors.g500),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: inputBorder(TossColors.g200, 0),
      enabledBorder: inputBorder(TossColors.g200, 0),
      focusedBorder: inputBorder(TossColors.blue, 1.5),
      errorBorder: inputBorder(TossColors.red, 1.5),
      focusedErrorBorder: inputBorder(TossColors.red, 1.5),
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: ButtonStyle(
        backgroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? TossColors.white
              : TossColors.g100,
        ),
        foregroundColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? TossColors.g900
              : TossColors.g600,
        ),
        textStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            fontFamily: _fontFamily,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w700
                : FontWeight.w500,
          ),
        ),
        side: const WidgetStatePropertyAll(BorderSide(color: TossColors.g200)),
        shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: TossColors.blue,
      foregroundColor: TossColors.white,
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (states) => states.contains(WidgetState.selected)
            ? TossColors.blue
            : Colors.transparent,
      ),
      checkColor: const WidgetStatePropertyAll(TossColors.white),
      side: const BorderSide(color: TossColors.g300, width: 1.5),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: TossColors.g900,
      contentTextStyle: const TextStyle(
        fontFamily: _fontFamily,
        color: TossColors.white,
      ),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: const DividerThemeData(color: TossColors.g100, thickness: 1),
    listTileTheme: const ListTileThemeData(
      iconColor: TossColors.g600,
      titleTextStyle: TextStyle(
        fontFamily: _fontFamily,
        color: TossColors.g900,
        fontWeight: FontWeight.w600,
      ),
      subtitleTextStyle: TextStyle(
        fontFamily: _fontFamily,
        color: TossColors.g500,
      ),
    ),
  );
}
