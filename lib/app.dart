import 'package:material_ui/material_ui.dart';

import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';

class StupsApp extends StatefulWidget {
  const StupsApp({super.key});

  @override
  State<StupsApp> createState() => _StupsAppState();
}

class _StupsAppState extends State<StupsApp> {
  final _router = createRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Stups',
      theme: StupsTheme.light,
      darkTheme: StupsTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: _router,
    );
  }
}
