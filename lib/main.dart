import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'services/storage_service.dart';
import 'services/usage_service.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/history_screen.dart';
import 'screens/scan_screen.dart';
import 'screens/settings_screen.dart';
import 'screens/onboarding_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await StorageService.init();
  await UsageService.init();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);

  runApp(const ContextifyApp());
}

class ContextifyApp extends StatefulWidget {
  const ContextifyApp({super.key});

  @override
  State<ContextifyApp> createState() => _ContextifyAppState();
}

class _ContextifyAppState extends State<ContextifyApp> {
  late ThemeMode _themeMode;
  late bool _showOnboarding;

  @override
  void initState() {
    super.initState();
    _themeMode = StorageService.getThemeMode();
    _showOnboarding = !StorageService.isOnboardingComplete();
  }

  void _setThemeMode(ThemeMode mode) {
    setState(() => _themeMode = mode);
  }

  void _completeOnboarding() {
    setState(() => _showOnboarding = false);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Contextify',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _themeMode,
      home: _showOnboarding
          ? OnboardingScreen(onComplete: _completeOnboarding)
          : MainShell(
              onThemeChanged: _setThemeMode,
              currentThemeMode: _themeMode,
            ),
    );
  }
}

class MainShell extends StatefulWidget {
  final ValueChanged<ThemeMode> onThemeChanged;
  final ThemeMode currentThemeMode;

  const MainShell({
    super.key,
    required this.onThemeChanged,
    required this.currentThemeMode,
  });

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> with TickerProviderStateMixin {
  int _currentIndex = 0;
  late final List<Widget> _screens;
  late final List<AnimationController> _fadeControllers;
  late final List<Animation<double>> _fadeAnimations;

  @override
  void initState() {
    super.initState();
    _screens = [
      const HomeScreen(),
      const ScanScreen(),
      const HistoryScreen(),
      SettingsScreen(
        onThemeChanged: widget.onThemeChanged,
        currentThemeMode: widget.currentThemeMode,
      ),
    ];

    _fadeControllers = List.generate(
      4,
      (i) => AnimationController(
        duration: const Duration(milliseconds: 300),
        vsync: this,
      ),
    );

    _fadeAnimations = _fadeControllers
        .map((c) => CurvedAnimation(parent: c, curve: Curves.easeOutCubic))
        .toList();

    _fadeControllers[0].value = 1.0;
  }

  @override
  void didUpdateWidget(MainShell oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentThemeMode != widget.currentThemeMode) {
      _screens[3] = SettingsScreen(
        onThemeChanged: widget.onThemeChanged,
        currentThemeMode: widget.currentThemeMode,
      );
    }
  }

  @override
  void dispose() {
    for (final c in _fadeControllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _onDestinationSelected(int index) {
    if (index == _currentIndex) return;
    _fadeControllers[_currentIndex].reverse();
    setState(() => _currentIndex = index);
    _fadeControllers[index].forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: List.generate(4, (i) {
          return Offstage(
            offstage: _currentIndex != i,
            child: FadeTransition(
              opacity: _fadeAnimations[i],
              child: _screens[i],
            ),
          );
        }),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: _onDestinationSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.manage_search_outlined),
            selectedIcon: Icon(Icons.manage_search_rounded),
            label: 'Decode',
          ),
          NavigationDestination(
            icon: Icon(Icons.document_scanner_outlined),
            selectedIcon: Icon(Icons.document_scanner_rounded),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings_rounded),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}
