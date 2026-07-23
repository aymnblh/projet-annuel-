import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart'; 
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'firebase_options.dart';
import 'views/auth_screen.dart';
import 'views/splash_screen.dart'; // IMPORTANT : Laissez-le si le fichier existe
import 'services/notification_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

// NOUVEAUX IMPORTS
import 'providers/user_provider.dart';
import 'providers/product_provider.dart';
import 'providers/theme_provider.dart';
import 'providers/app_mode_provider.dart'; // NEW
import 'utils/app_theme.dart';
import 'views/responsive_layout.dart';
import 'views/layouts/mobile_layout.dart';
import 'views/layouts/web_layout.dart';
import 'views/layouts/rental_mobile_layout.dart'; // NEW
import 'views/mode_selection_screen.dart'; // NEW
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'views/deep_link_product_loader.dart';

// VARIABLE GLOBALE POUR CHANGER LA LANGUE
final ValueNotifier<String> languageNotifier = ValueNotifier<String>('fr'); // FR uniquement
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    print("Info: Fichier .env introuvable.");
  }

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await NotificationService().init();
  
  await FirebaseMessaging.instance.subscribeToTopic('news');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // 1. D'abord on retourne les PROVIDERS
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ProductProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AppModeProvider()), // NEW
      ],
      // 2. Ensuite le ValueListenableBuilder pour langue + Consumer pour Theme
      child: ValueListenableBuilder<String>(
        valueListenable: languageNotifier,
        builder: (context, lang, child) {
           return Consumer<ThemeProvider>(
             builder: (context, themeProvider, _) {
               return MaterialApp(
                  navigatorKey: navigatorKey,
                  title: '1Click',
                  debugShowCheckedModeBanner: false,
                  
                  locale: Locale(lang),
                  supportedLocales: const [Locale('fr')],
                  localizationsDelegates: const [
                    GlobalMaterialLocalizations.delegate,
                    GlobalWidgetsLocalizations.delegate,
                    GlobalCupertinoLocalizations.delegate,
                  ],

                  theme: AppTheme.lightTheme, // UTILISATION DE NOTRE NOUVEAU THEME
                  darkTheme: AppTheme.darkTheme, // MODE SOMBRE
                  themeMode: themeProvider.themeMode, // MODE ACTIF

                  home: const AuthWrapper(), 
               );
             }
           );
        },
      ),
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  @override
  void initState() {
    super.initState();
    // Au démarrage, on peut déclencher le chargement des infos user si déjà connecté
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        Provider.of<UserProvider>(context, listen: false).fetchUserData();
      }
    });
    _initDeepLinks();
  }

  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();
    
    // Handle initial link (when app is opened from a deep link)
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleDeepLink(initialUri);
      }
    } catch (e) {
      debugPrint('Error getting initial link: $e');
    }
    
    // Handle links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (uri) {
        _handleDeepLink(uri);
      },
      onError: (err) {
        debugPrint('Deep link stream error: $err');
      },
    );
  }

  void _handleDeepLink(Uri uri) {
    debugPrint('Deep link received: $uri');
    
    // Handle oneclick://product/{id}
    if (uri.scheme == 'oneclick' && uri.pathSegments.isNotEmpty) {
      if (uri.pathSegments[0] == 'product' && uri.pathSegments.length > 1) {
        final productId = uri.pathSegments[1];
        debugPrint('Opening product: $productId');
        
        // Navigate to product details
        navigatorKey.currentState?.push(
          MaterialPageRoute(
            builder: (_) => DeepLinkProductLoader(productId: productId),
          ),
        );
        
        // Track analytics
        try {
          // TODO: Add analytics tracking
          // AnalyticsService.logEvent('deep_link_opened', {'product_id': productId});
        } catch (e) {
          debugPrint('Analytics error: $e');
        }
      } else {
        debugPrint('Unknown deep link path: ${uri.path}');
      }
    } else {
      debugPrint('Unknown deep link scheme: ${uri.scheme}');
    }
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF0F172A))));
        }
        
        if (snapshot.hasData && snapshot.data != null) {
          // S'assurer que les données sont chargées si elles manquent
          final userProvider = Provider.of<UserProvider>(context, listen: false);
          if (userProvider.userData == null && !userProvider.isLoading) {
             WidgetsBinding.instance.addPostFrameCallback((_) {
                userProvider.fetchUserData();
             });
          }

          // Route based on app mode (buy vs rent)
          return Consumer<AppModeProvider>(
            builder: (context, modeProvider, _) {
              // Still loading from SharedPreferences
              if (!modeProvider.isLoaded) {
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(color: Color(0xFF0F172A)),
                  ),
                );
              }
              // First time: show mode selection screen
              if (modeProvider.isFirstTime) {
                return const ModeSelectionScreen();
              }
              // Returning user: go to their last-used mode
              return ResponsiveLayout(
                mobileBody: modeProvider.isRentMode
                    ? const RentalMobileLayout()
                    : const MobileLayout(),
                desktopBody: const WebLayout(),
              );
            },
          );
        } else {
          // NON CONNECTÉ => Login
          return const AuthScreen();
        }
      },
    );
  }
}
