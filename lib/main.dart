import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'providers/business_card_provider.dart';
import 'providers/subscription_provider.dart';
import 'providers/portfolio_provider.dart';
import 'providers/resume_provider.dart';
import 'providers/credential_provider.dart';
import 'screens/home_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProStackApp());
}

class ProStackApp extends StatelessWidget {
  const ProStackApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (context) => BusinessCardProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => SubscriptionProvider()..initialize(),
        ),
        ChangeNotifierProvider(
          create: (context) => PortfolioProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => ResumeProvider(),
        ),
        ChangeNotifierProvider(
          create: (context) => CredentialProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'ProStack',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          primaryColor: const Color(0xFF1976D2),
          useMaterial3: true,
          appBarTheme: const AppBarTheme(
            centerTitle: true,
            elevation: 0,
            backgroundColor: Color(0xFF1976D2),
            foregroundColor: Colors.white,
          ),
          cardTheme: CardThemeData(
            elevation: 2,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1976D2),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 12,
              ),
            ),
          ),
          floatingActionButtonTheme: const FloatingActionButtonThemeData(
            backgroundColor: Color(0xFF1976D2),
            foregroundColor: Colors.white,
          ),
        ),
        home: const HomeScreen(),
      ),
    );
  }
}