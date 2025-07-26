import 'package:flutter/material.dart';

/// App theme definitions with custom color schemes
class AppThemes {
  // Private constructor to prevent instantiation
  AppThemes._();

  /// Light theme configuration
  static ThemeData get lightTheme {
    const ColorScheme lightColorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: Color(0xFF2196F3), // Blue
      onPrimary: Color(0xFFFFFFFF),
      secondary: Color(0xFF03DAC6), // Teal
      onSecondary: Color(0xFF000000),
      tertiary: Color(0xFF9C27B0), // Purple
      onTertiary: Color(0xFFFFFFFF),
      error: Color(0xFFFF5722), // Deep Orange
      onError: Color(0xFFFFFFFF),
      surface: Color(0xFFFAFAFA), // Very light grey
      onSurface: Color(0xFF212121),
      surfaceDim: Color(0xFFF5F5F5), // Light grey
      surfaceBright: Color(0xFFFFFFFF),
      surfaceContainerLowest: Color(0xFFFFFFFF),
      surfaceContainerLow: Color(0xFFF8F8F8),
      surfaceContainer: Color(0xFFF0F0F0),
      surfaceContainerHigh: Color(0xFFE8E8E8),
      surfaceContainerHighest: Color(0xFFE0E0E0),
      onSurfaceVariant: Color(0xFF757575),
      outline: Color(0xFFBDBDBD),
      outlineVariant: Color(0xFFE0E0E0),
      inverseSurface: Color(0xFF303030),
      onInverseSurface: Color(0xFFFFFFFF),
      inversePrimary: Color(0xFF90CAF9),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      surfaceTint: Color(0xFF2196F3),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: lightColorScheme,
      
      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: lightColorScheme.surface,
        foregroundColor: lightColorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: lightColorScheme.shadow.withOpacity(0.1),
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: lightColorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: lightColorScheme.surfaceContainer,
        shadowColor: lightColorScheme.shadow.withOpacity(0.1),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: lightColorScheme.primary,
          foregroundColor: lightColorScheme.onPrimary,
          elevation: 2,
          shadowColor: lightColorScheme.shadow.withOpacity(0.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: lightColorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: lightColorScheme.primary,
          side: BorderSide(color: lightColorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: lightColorScheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: lightColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: lightColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: lightColorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: lightColorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: lightColorScheme.surface,
        selectedItemColor: lightColorScheme.primary,
        unselectedItemColor: lightColorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Drawer theme
      drawerTheme: DrawerThemeData(
        backgroundColor: lightColorScheme.surface,
        surfaceTintColor: lightColorScheme.surfaceTint,
      ),

      // List tile theme
      listTileTheme: ListTileThemeData(
        tileColor: lightColorScheme.surface,
        selectedTileColor: lightColorScheme.primaryContainer,
        selectedColor: lightColorScheme.onPrimaryContainer,
        iconColor: lightColorScheme.onSurfaceVariant,
        textColor: lightColorScheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return lightColorScheme.primary;
          }
          return lightColorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return lightColorScheme.primaryContainer;
          }
          return lightColorScheme.surfaceContainerHighest;
        }),
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: lightColorScheme.primary,
        foregroundColor: lightColorScheme.onPrimary,
        elevation: 6,
        shape: const CircleBorder(),
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: lightColorScheme.surface,
        surfaceTintColor: lightColorScheme.surfaceTint,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: lightColorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: lightColorScheme.onInverseSurface),
        actionTextColor: lightColorScheme.inversePrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  /// Dark theme configuration
  static ThemeData get darkTheme {
    const ColorScheme darkColorScheme = ColorScheme(
      brightness: Brightness.dark,
      primary: Color(0xFF90CAF9), // Light Blue
      onPrimary: Color(0xFF0D47A1),
      secondary: Color(0xFF4DB6AC), // Light Teal
      onSecondary: Color(0xFF00251A),
      tertiary: Color(0xFFCE93D8), // Light Purple
      onTertiary: Color(0xFF4A148C),
      error: Color(0xFFFF8A65), // Light Deep Orange
      onError: Color(0xFF5D1049),
      surface: Color(0xFF121212), // Very dark grey
      onSurface: Color(0xFFE0E0E0),
      surfaceDim: Color(0xFF1E1E1E), // Dark grey
      surfaceBright: Color(0xFF2C2C2C),
      surfaceContainerLowest: Color(0xFF0F0F0F),
      surfaceContainerLow: Color(0xFF191919),
      surfaceContainer: Color(0xFF232323),
      surfaceContainerHigh: Color(0xFF2E2E2E),
      surfaceContainerHighest: Color(0xFF383838),
      onSurfaceVariant: Color(0xFFB0B0B0),
      outline: Color(0xFF616161),
      outlineVariant: Color(0xFF424242),
      inverseSurface: Color(0xFFE0E0E0),
      onInverseSurface: Color(0xFF1C1C1C),
      inversePrimary: Color(0xFF2196F3),
      shadow: Color(0xFF000000),
      scrim: Color(0xFF000000),
      surfaceTint: Color(0xFF90CAF9),
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: darkColorScheme,
      
      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: darkColorScheme.surface,
        foregroundColor: darkColorScheme.onSurface,
        elevation: 0,
        scrolledUnderElevation: 1,
        shadowColor: darkColorScheme.shadow.withOpacity(0.3),
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: darkColorScheme.onSurface,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card theme
      cardTheme: CardThemeData(
        color: darkColorScheme.surfaceContainer,
        shadowColor: darkColorScheme.shadow.withOpacity(0.3),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      // Elevated button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkColorScheme.primary,
          foregroundColor: darkColorScheme.onPrimary,
          elevation: 2,
          shadowColor: darkColorScheme.shadow.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Text button theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkColorScheme.primary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // Outlined button theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkColorScheme.primary,
          side: BorderSide(color: darkColorScheme.outline),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        ),
      ),

      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: darkColorScheme.surfaceContainerHigh,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: darkColorScheme.outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: darkColorScheme.outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: darkColorScheme.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: darkColorScheme.error),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Bottom navigation bar theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: darkColorScheme.surface,
        selectedItemColor: darkColorScheme.primary,
        unselectedItemColor: darkColorScheme.onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // Drawer theme
      drawerTheme: DrawerThemeData(
        backgroundColor: darkColorScheme.surface,
        surfaceTintColor: darkColorScheme.surfaceTint,
      ),

      // List tile theme
      listTileTheme: ListTileThemeData(
        tileColor: darkColorScheme.surface,
        selectedTileColor: darkColorScheme.primaryContainer,
        selectedColor: darkColorScheme.onPrimaryContainer,
        iconColor: darkColorScheme.onSurfaceVariant,
        textColor: darkColorScheme.onSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // Switch theme
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return darkColorScheme.primary;
          }
          return darkColorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return darkColorScheme.primaryContainer;
          }
          return darkColorScheme.surfaceContainerHighest;
        }),
      ),

      // Floating action button theme
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkColorScheme.primary,
        foregroundColor: darkColorScheme.onPrimary,
        elevation: 6,
        shape: const CircleBorder(),
      ),

      // Dialog theme
      dialogTheme: DialogThemeData(
        backgroundColor: darkColorScheme.surface,
        surfaceTintColor: darkColorScheme.surfaceTint,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Snackbar theme
      snackBarTheme: SnackBarThemeData(
        backgroundColor: darkColorScheme.inverseSurface,
        contentTextStyle: TextStyle(color: darkColorScheme.onInverseSurface),
        actionTextColor: darkColorScheme.inversePrimary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}
