import 'package:flutter/material.dart';

import 'endfield.dart';
import 'pages/home_page.dart';

class EtalienApp extends StatelessWidget {
  const EtalienApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '免广告领时长',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: Ef.paper,
        colorScheme: const ColorScheme.light(
          primary: Ef.ink,
          secondary: Ef.signal,
          surface: Ef.paper,
          error: Ef.error,
        ),
        fontFamilyFallback: Ef.cjkFallback,
        useMaterial3: true,
        splashFactory: NoSplash.splashFactory,
      ),
      home: const HomePage(),
    );
  }
}
