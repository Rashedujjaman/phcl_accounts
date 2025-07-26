# Theme Management System

## Overview
The PHCL Accounts app includes a comprehensive theme management system that supports:
- **System Theme**: Automatically follows device theme settings (default)
- **Light Theme**: Custom light color scheme optimized for the app
- **Dark Theme**: Custom dark color scheme optimized for the app
- **Persistent Storage**: Theme preferences are saved and restored between app sessions

## Features

### 🎨 **Custom Color Schemes**
- **Material 3 Design**: Uses the latest Material Design 3 color system
- **Consistent Colors**: All components use the same color scheme across the app
- **Optimized Contrast**: Colors are carefully chosen for optimal readability

### 🔄 **Theme Switching**
- **Quick Toggle**: Switch between light and dark with a simple toggle
- **Advanced Picker**: Access a detailed theme selection dialog
- **System Sync**: Automatically adapts to system theme changes

### 💾 **Persistence**
- **SharedPreferences**: Theme choice is saved locally
- **Auto-Restore**: Your theme preference is remembered between app launches

## Usage

### Basic Theme Toggle
Users can quickly toggle between light and dark themes using the switch in Settings:

```dart
// The switch automatically handles theme toggling
Switch(
  value: themeProvider.isDarkMode(context),
  onChanged: (value) => themeProvider.toggleTheme(context),
)
```

### Advanced Theme Selection
Access the full theme picker for more options:

```dart
// Show the advanced theme picker dialog
showThemePicker(context);
```

### Programmatic Theme Management

#### Get Current Theme Status
```dart
final themeProvider = Provider.of<ThemeProvider>(context);

// Check if dark mode is active
bool isDark = themeProvider.isDarkMode(context);

// Get theme mode
ThemeMode currentMode = themeProvider.themeMode;

// Get theme status text
String status = themeProvider.getThemeStatusText(context);
```

#### Set Specific Theme
```dart
// Set to light theme
await themeProvider.setThemeMode(ThemeMode.light);

// Set to dark theme
await themeProvider.setThemeMode(ThemeMode.dark);

// Reset to system theme
await themeProvider.resetToSystemTheme();
```

#### Toggle Theme
```dart
// Toggle between light and dark
await themeProvider.toggleTheme(context);
```

## Color Scheme

### Light Theme Colors
- **Primary**: Blue (#2196F3)
- **Secondary**: Teal (#03DAC6)
- **Surface**: Very Light Grey (#FAFAFA)
- **Background**: White (#FFFFFF)

### Dark Theme Colors
- **Primary**: Light Blue (#90CAF9)
- **Secondary**: Light Teal (#4DB6AC)
- **Surface**: Very Dark Grey (#121212)
- **Background**: Dark Grey (#1E1E1E)

## Implementation Details

### File Structure
```
lib/core/theme/
├── app_themes.dart          # Theme definitions and color schemes
├── theme_provider.dart      # Theme state management
└── widgets/
    └── theme_picker_dialog.dart  # Advanced theme picker UI
```

### Integration Points
1. **main.dart**: Theme system initialization and MaterialApp configuration
2. **settings_page.dart**: User interface for theme controls
3. **All UI Components**: Automatically use theme colors through `Theme.of(context)`

### Dependencies
- `provider`: State management for theme changes
- `shared_preferences`: Persistent theme storage
- `flutter/material`: Material Design 3 theming system

## Customization

### Adding New Colors
To add new colors to the theme, update the ColorScheme in `app_themes.dart`:

```dart
const ColorScheme lightColorScheme = ColorScheme(
  // ... existing colors
  tertiary: Color(0xFF9C27B0), // Add new colors here
  // ... rest of colors
);
```

### Modifying Component Themes
Update specific component themes in the ThemeData:

```dart
// Example: Customize button theme
elevatedButtonTheme: ElevatedButtonThemeData(
  style: ElevatedButton.styleFrom(
    backgroundColor: lightColorScheme.primary,
    // ... other properties
  ),
),
```

### Adding New Theme Options
To add new theme variants:
1. Create new ColorScheme definitions in `app_themes.dart`
2. Add the new theme to ThemeMode enum handling
3. Update the theme picker dialog to include the new option

## Best Practices

### Using Theme Colors in Widgets
Always use theme colors instead of hardcoded colors:

```dart
// ✅ Good - Uses theme colors
Container(
  color: Theme.of(context).colorScheme.surface,
  child: Text(
    'Hello',
    style: TextStyle(
      color: Theme.of(context).colorScheme.onSurface,
    ),
  ),
)

// ❌ Bad - Hardcoded colors
Container(
  color: Colors.white,
  child: Text(
    'Hello',
    style: TextStyle(color: Colors.black),
  ),
)
```

### Responsive Theme Changes
Listen to theme changes using Consumer or context.watch:

```dart
// Option 1: Consumer
Consumer<ThemeProvider>(
  builder: (context, themeProvider, child) {
    return MyWidget(isDark: themeProvider.isDarkMode(context));
  },
)

// Option 2: Context.watch
Widget build(BuildContext context) {
  final themeProvider = context.watch<ThemeProvider>();
  return MyWidget(isDark: themeProvider.isDarkMode(context));
}
```

### Testing Themes
Test your UI in both light and dark themes:
1. Use the theme toggle in settings
2. Test with system theme changes
3. Verify color contrast and readability
4. Ensure all components respect the theme

## Troubleshooting

### Theme Not Persisting
- Check if SharedPreferences is properly initialized
- Verify theme provider initialization in main.dart

### Colors Not Updating
- Ensure you're using `Theme.of(context).colorScheme` instead of hardcoded colors
- Check if widgets are wrapped in Consumer or using context.watch

### System Theme Not Working
- Verify ThemeMode.system is set correctly
- Check if device supports theme changes
- Test on different platforms (iOS/Android)
