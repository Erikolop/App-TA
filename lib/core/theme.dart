import 'package:material_ui/material_ui.dart';
import 'package:google_fonts/google_fonts.dart';

/// SmartGrow design tokens — "The Calm Control Room"
/// Single burnt-orange accent, warm canvas, flat-by-default surfaces.
abstract class AppColors {
  // Primary accent — selection, active state, primary action only
  static const Color accent = Color(0xFFE2491A);
  static const Color accentDeep = Color(0xFFC83415);

  // Surface hierarchy
  static const Color canvas = Color(0xFFF6F6F5); // page background
  static const Color surface = Color(0xFFFFFFFF); // cards & panels
  static const Color navBar = Color(0xFF1B1B1B); // bottom nav background

  // Text
  static const Color textPrimary = Color(0xFF1B1B1B);
  static const Color textSecondary = Color(0xFF5F5E5F);

  // Borders & inactive
  static const Color divider = Color(0xFFE8E8E6);
  static const Color tabUnselected = Color(0xFFEDEDE9);

  // On-accent text
  static const Color onAccent = Color(0xFFFFFFFF);
}

abstract class AppRadius {
  static const double card = 16;
  static const double compact = 8;
  static const Radius cardRadius = Radius.circular(card);
  static const BorderRadius cardBorderRadius = BorderRadius.all(cardRadius);
  static BorderRadius get pill => BorderRadius.circular(999);
}

abstract class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double base = 16;
  static const double lg = 24;
  static const double xl = 32;
}

ThemeData buildTheme({bool dark = false}) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.accent,
    brightness: dark ? Brightness.dark : Brightness.light,
    primary: AppColors.accent,
    onPrimary: AppColors.onAccent,
    surface: dark ? const Color(0xFF1E1E1E) : AppColors.surface,
    onSurface: dark ? Colors.white : AppColors.textPrimary,
  );

  final base = dark ? ThemeData.dark(useMaterial3: true) : ThemeData.light(useMaterial3: true);
  final tt = _textTheme(dark);

  return base.copyWith(
    colorScheme: colorScheme,
    scaffoldBackgroundColor: dark ? const Color(0xFF121212) : AppColors.canvas,
    textTheme: tt,
    primaryTextTheme: tt,

    // AppBar
    appBarTheme: AppBarTheme(
      backgroundColor: dark ? const Color(0xFF1E1E1E) : AppColors.surface,
      foregroundColor: dark ? Colors.white : AppColors.textPrimary,
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: GoogleFonts.inter(
        fontSize: 20,
        fontWeight: FontWeight.w600,
        color: dark ? Colors.white : AppColors.textPrimary,
      ),
    ),

    // Bottom nav — always dark-anchored
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.navBar,
      indicatorColor: AppColors.accent,
      iconTheme: WidgetStateProperty.resolveWith((states) {
        return IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.onAccent
              : Colors.white.withValues(alpha: 0.7),
          size: 22,
        );
      }),
      labelTextStyle: WidgetStateProperty.resolveWith((states) {
        return GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          color: states.contains(WidgetState.selected)
              ? AppColors.onAccent
              : Colors.white.withValues(alpha: 0.7),
        );
      }),
      labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      height: 64,
    ),

    // Cards — white surface, thin border, no shadow
    cardTheme: CardThemeData(
      color: dark ? const Color(0xFF2A2A2A) : AppColors.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: AppRadius.cardBorderRadius,
        side: BorderSide(
          color: dark ? Colors.white12 : AppColors.divider,
          width: 1,
        ),
      ),
      margin: EdgeInsets.zero,
    ),

    // Chips — pill shape
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: AppRadius.pill),
      showCheckmark: false,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.base,
        vertical: AppSpacing.sm,
      ),
      selectedColor: AppColors.accent,
      secondarySelectedColor: AppColors.accent,
      labelPadding: EdgeInsets.zero,
    ),

    // Divider
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),
  );
}

TextTheme _textTheme(bool dark) {
  final ink = dark ? Colors.white : AppColors.textPrimary;
  final subtle = dark ? Colors.white60 : AppColors.textSecondary;

  return TextTheme(
    // Display (26 / 600)
    displayLarge: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w600, color: ink),
    // Section heading (20 / 600)
    headlineMedium: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w600, color: ink),
    // Screen / card title (16 / 500)
    titleMedium: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: ink),
    // Card secondary label (14 / 500)
    titleSmall: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: ink),
    // Body (12 / 400)
    bodySmall: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: subtle),
    // Caption (10 / 400)
    labelSmall: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w400, color: subtle),
    // Metric / sensor reading (26 / 600)
    bodyLarge: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w600, color: ink),
  );
}
