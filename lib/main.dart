import 'package:deck_note/providers/auth_provider.dart';
import 'package:deck_note/providers/todo_provider.dart';
import 'package:deck_note/screens/splash_screen.dart';
import 'package:deck_note/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  /// Tests and screenshots pass fakes (and a [home]); the real app passes
  /// nothing and talks to Firebase.
  final AuthProvider? auth;
  final TodoProvider? todos;
  final Widget? home;

  const MyApp({super.key, this.auth, this.todos, this.home});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(
          create: (_) => auth ?? AuthProvider(),
        ),
        ChangeNotifierProvider<TodoProvider>(
          create: (_) => todos ?? TodoProvider(),
        ),
      ],
      child: MaterialApp(
        title: 'DecXNote',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.dark(),
        home: home ?? const SplashScreen(),
      ),
    );
  }
}
