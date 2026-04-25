import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sage/core/configs/theme/app_theme.dart';
import 'package:sage/presentation/choose_mode/bloc/theme_cubit.dart';
import 'package:sage/presentation/splash/pages/splash.dart';
import 'package:sage/service_locator.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: kIsWeb
          ? HydratedStorageDirectory.web
          : HydratedStorageDirectory(
              (await getApplicationDocumentsDirectory()).path,
            ),
    );
  } catch (error, stackTrace) {
    debugPrint('Hydrated storage init failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }
  try {
    await initializeDependencies();
  } catch (error, stackTrace) {
    debugPrint('Service locator init failed: $error');
    debugPrintStack(stackTrace: stackTrace);
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => ThemeCubit()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, mode) => MaterialApp(
          title: 'Sage',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: mode,
          home: const SplashPage(),
        ),
      ),
    );
  }
}
