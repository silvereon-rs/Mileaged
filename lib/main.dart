import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_shell.dart';
import 'profile_store.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await ProfileStore.load();
  } catch (_) {}
  runApp(const MileagedApp());
}

class MileagedApp extends StatefulWidget {
  const MileagedApp({super.key});

  @override
  State<MileagedApp> createState() => _MileagedAppState();
}

class _MileagedAppState extends State<MileagedApp> {
  Color _accentColor = const Color(0xFFEEFF5D);
  bool _isDarkMode = true;
  bool _useMetric = true;
  List<Color> _recentColors = [
    const Color(0xFFEEFF5D),
    const Color(0xFF92131A),
    const Color(0xFF007AFF),
  ];

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accentValue = prefs.getInt('accent_color');
      final isDarkMode = prefs.getBool('dark_mode');
      final useMetric = prefs.getBool('use_metric');
      final recentColorsStr = prefs.getStringList('recent_colors');

      setState(() {
        if (accentValue != null) _accentColor = Color(accentValue);
        if (isDarkMode != null) _isDarkMode = isDarkMode;
        if (useMetric != null) _useMetric = useMetric;
        if (recentColorsStr != null) {
          _recentColors = recentColorsStr.map((e) => Color(int.parse(e))).toList();
        }
      });
    } catch (_) {}
  }

  Future<void> _saveSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('accent_color', _accentColor.value);
      await prefs.setBool('dark_mode', _isDarkMode);
      await prefs.setBool('use_metric', _useMetric);
      await prefs.setStringList('recent_colors', _recentColors.map((e) => e.value.toString()).toList());
    } catch (_) {}
  }

  void _onAccentChanged(Color color) {
    setState(() {
      _accentColor = color;
    });
  }

  void _onAccentSaved(Color color) {
    setState(() {
      _accentColor = color;
      _recentColors.remove(color);
      _recentColors.insert(0, color);
      if (_recentColors.length > 3) _recentColors = _recentColors.sublist(0, 3);
    });
    _saveSettings();
  }

  @override
  Widget build(BuildContext context) {
    return AccentColorScope(
      accentColor: _accentColor,
      child: UnitScope(
        useMetric: _useMetric,
        child: MaterialApp(
          title: 'Mileaged',
          debugShowCheckedModeBanner: false,
          theme: _isDarkMode ? _buildDarkTheme() : _buildLightTheme(),
          home: AppShell(
            onAccentChanged: _onAccentChanged,
            onAccentSaved: _onAccentSaved,
            recentColors: _recentColors,
            isDarkMode: _isDarkMode,
            onToggleDarkMode: (v) {
              setState(() => _isDarkMode = v);
              _saveSettings();
            },
            useMetric: _useMetric,
            onToggleUnit: (v) {
              setState(() => _useMetric = v);
              _saveSettings();
            },

          ),
        ),
      ),
    );
  }

  ThemeData _buildLightTheme() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF2F2F7),
    colorScheme: ColorScheme.light(
      primary: _accentColor,
      secondary: _accentColor,
      surface: Colors.white,
      onSurface: const Color(0xFF1C1C1E),
      outline: const Color(0xFFE5E5EA),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFFF2F2F7),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF1C1C1E), width: 1.5)),
      labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
      hintStyle: const TextStyle(color: Color(0xFFC7C7CC)),
      prefixIconColor: const Color(0xFF8E8E93),
      suffixStyle: const TextStyle(color: Color(0xFF8E8E93)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: const Color(0xFF1C1C1E),
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF2F2F7),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(color: Color(0xFF1C1C1E), fontSize: 18, fontWeight: FontWeight.w600),
      iconTheme: IconThemeData(color: Color(0xFF1C1C1E)),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF1C1C1E),
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: const TextStyle(color: Color(0xFF1C1C1E), fontSize: 18, fontWeight: FontWeight.w600),
      contentTextStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
    ),
  );

  ThemeData _buildDarkTheme() => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF000000),
    colorScheme: ColorScheme.dark(
      primary: _accentColor,
      secondary: _accentColor,
      surface: const Color(0xFF1C1C1E),
      onSurface: Colors.white,
      outline: const Color(0xFF38383A),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1C1C1E),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      elevation: 0,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2E),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: _accentColor, width: 1.5)),
      labelStyle: const TextStyle(color: Color(0xFF8E8E93)),
      hintStyle: const TextStyle(color: Color(0xFF48484A)),
      prefixIconColor: const Color(0xFF8E8E93),
      suffixStyle: const TextStyle(color: Color(0xFF8E8E93)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF1C1C1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
      ),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFF000000),
      elevation: 0,
      centerTitle: true,
      titleTextStyle: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF2C2C2E),
      contentTextStyle: const TextStyle(color: Colors.white, fontSize: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      behavior: SnackBarBehavior.floating,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: const Color(0xFF1C1C1E),
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      titleTextStyle: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600),
      contentTextStyle: const TextStyle(color: Color(0xFF8E8E93), fontSize: 14),
    ),
  );
}
/// InheritedWidget to provide the accent color down the tree.
class AccentColorScope extends InheritedWidget {
  final Color accentColor;

  const AccentColorScope({
    super.key,
    required this.accentColor,
    required super.child,
  });

  static Color of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<AccentColorScope>();
    return scope?.accentColor ?? const Color(0xFFEEFF5D);
  }

  /// Returns white or dark based on accent luminance for content on accent bg.
  static Color onAccent(BuildContext context) {
    final accent = of(context);
    return accent.computeLuminance() > 0.5
        ? const Color(0xFF1C1C1E)
        : Colors.white;
  }

  @override
  bool updateShouldNotify(AccentColorScope oldWidget) => accentColor != oldWidget.accentColor;
}

class UnitScope extends InheritedWidget {
  final bool useMetric;

  const UnitScope({super.key, required this.useMetric, required super.child});

  static bool isMetric(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<UnitScope>()?.useMetric ?? true;
  }

  static String currency(BuildContext context) => '₹';

  static String mileageUnit(BuildContext context) => isMetric(context) ? 'km/l' : 'mpg';
  static String distanceUnit(BuildContext context) => isMetric(context) ? 'km' : 'mi';
  static String volumeUnit(BuildContext context) => isMetric(context) ? 'litres' : 'gal';
  static String volumeUnitShort(BuildContext context) => isMetric(context) ? 'L' : 'gal';

  /// Convert mileage from km/l to display unit
  static double mileage(BuildContext context, double kml) => isMetric(context) ? kml : kml * 2.35215;
  /// Convert distance from km to display unit
  static double distance(BuildContext context, double km) => isMetric(context) ? km : km * 0.621371;
  /// Convert volume from litres to display unit
  static double volume(BuildContext context, double litres) => isMetric(context) ? litres : litres * 0.264172;

  @override
  bool updateShouldNotify(UnitScope oldWidget) => useMetric != oldWidget.useMetric;
}