import 'dart:async';

import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import './providers/app_state.dart';
import './routes/app_routes.dart';
import './services/notification_service.dart';
import './services/supabase_service.dart';
import './theme/app_theme.dart';
import './widgets/custom_error_widget.dart';
import 'core/app_export.dart';

void main() {
  // CRITICAL: Must be the very first call before any async work or plugin use.
  WidgetsFlutterBinding.ensureInitialized();

  runZonedGuarded(
    () async {
      bool hasShownError = false;

      // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
      ErrorWidget.builder = (FlutterErrorDetails details) {
        if (!hasShownError) {
          hasShownError = true;
          Future.delayed(const Duration(seconds: 5), () {
            hasShownError = false;
          });
          return CustomErrorWidget(errorDetails: details);
        }
        return const SizedBox.shrink();
      };

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        debugPrint('Flutter error caught: ${details.exceptionAsString()}');
      };

      // Initialize Supabase — wrapped in try/catch so a missing dart-define
      // in release builds does not crash the app before the UI renders.
      try {
        await SupabaseService.initialize();
      } catch (e) {
        debugPrint('Supabase init error (non-fatal): $e');
      }

      // Initialize notification service
      try {
        await NotificationService.instance.initialize();
        await NotificationService.instance.requestPermission();
      } catch (e) {
        debugPrint('NotificationService init error (non-fatal): $e');
      }

      // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
      ]);

      GoRouter.optionURLReflectsImperativeAPIs = true;
      runApp(const MyApp());
    },
    (Object error, StackTrace stack) {
      debugPrint('Uncaught error: $error\n$stack');
    },
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final AppState _appState;
  StreamSubscription<AuthState>? _authSubscription;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _appState = AppState();
    _initAuthListener();
    // Apply initial system UI overlay for light mode
    AppTheme.applySystemUI(ThemeMode.light);
  }

  void _initAuthListener() {
    // Guard against Supabase not being initialized (e.g. missing dart-define)
    try {
      _authSubscription = Supabase.instance.client.auth.onAuthStateChange
          .listen((data) async {
            final event = data.event;
            final session = data.session;

            debugPrint('Auth event: $event');

            if (event == AuthChangeEvent.signedIn && session != null) {
              if (!_appState.isLoggedIn) {
                await _appState.loginWithSupabase();
              }
              final userId = session.user.id;
              NotificationService.instance.subscribeToUserNotifications(
                userId,
                (notification) {
                  _appState.refreshUnreadNotificationCount();
                },
              );
              NotificationService.instance.subscribeToAdminBroadcasts((
                title,
                body,
              ) {
                _appState.refreshUnreadNotificationCount();
              });
              if (_initialized &&
                  appRouter.routerDelegate.currentConfiguration.uri
                          .toString() !=
                      AppRoutes.homeScreen) {
                final currentPath = appRouter
                    .routerDelegate
                    .currentConfiguration
                    .uri
                    .toString();
                if (currentPath == AppRoutes.initial ||
                    currentPath == AppRoutes.signUpLoginScreen ||
                    currentPath == AppRoutes.otpVerifyScreen) {
                  appRouter.go(AppRoutes.homeScreen);
                }
              }
            } else if (event == AuthChangeEvent.signedOut) {
              NotificationService.instance.unsubscribe();
              _appState.logout();
              final currentPath = appRouter
                  .routerDelegate
                  .currentConfiguration
                  .uri
                  .toString();
              if (!currentPath.startsWith('/admin') && _initialized) {
                appRouter.go(AppRoutes.signUpLoginScreen);
              }
            } else if (event == AuthChangeEvent.initialSession) {
              if (session != null && !_appState.isLoggedIn) {
                await _appState.loginWithSupabase();
              }
              _initialized = true;
            } else if (event == AuthChangeEvent.tokenRefreshed &&
                session != null) {
              if (!_appState.isLoggedIn) {
                await _appState.loginWithSupabase();
              }
            }
          });
    } catch (e) {
      debugPrint('Auth listener init error (Supabase not ready): $e');
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _appState,
      child: Sizer(
        builder: (context, orientation, screenType) {
          precacheImage(
            const AssetImage('assets/images/maintix-1787987681965.png'),
            context,
          );
          return Consumer<AppState>(
            builder: (context, appState, _) {
              AppTheme.applySystemUI(appState.themeMode);
              return MaterialApp.router(
                title: 'Maintix',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: appState.themeMode,
                // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
                builder: (context, child) {
                  return MediaQuery(
                    data: MediaQuery.of(
                      context,
                    ).copyWith(textScaler: TextScaler.linear(1.0)),
                    child: child!,
                  );
                },
                // 🚨 END CRITICAL SECTION
                debugShowCheckedModeBanner: false,
                routerConfig: appRouter,
              );
            },
          );
        },
      ),
    );
  }
}
