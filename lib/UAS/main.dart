import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'view/detail.dart';
import 'view/favorites.dart';
import 'view/home.dart';
import 'view/location.dart';
import 'view/travel_list.dart';
import 'view/world_map.dart';
import 'viewmodel/favorite_service.dart';
import 'widgets/app_colors.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: kCream,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );
  // Muat daftar favorit tersimpan sebelum UI tampil (aman: tidak melempar).
  await FavoriteService.instance.load();
  runApp(const CountryExplorerUasApp());
}

/// Tema global Coastal Journey. Dibangun dari konstanta di `app_colors.dart`
/// agar seluruh widget Material (tombol, input, chip, dialog, bottom sheet,
/// progress, FAB, AppBar, dst.) otomatis mengikuti identitas visual yang sama.
ThemeData buildCoastalTheme() {
  final scheme = ColorScheme.fromSeed(
    seedColor: kDeepTeal,
    brightness: Brightness.light,
  ).copyWith(
    primary: kDeepTeal,
    onPrimary: Colors.white,
    primaryContainer: kSoftSeafoam,
    onPrimaryContainer: kDeepTeal,
    secondary: kOcean,
    onSecondary: Colors.white,
    secondaryContainer: kSoftSeafoam,
    onSecondaryContainer: kDeepTeal,
    tertiary: kCoral,
    onTertiary: Colors.white,
    tertiaryContainer: kSoftSand,
    onTertiaryContainer: kDeepTeal,
    surface: kSurface,
    onSurface: kDeepTeal,
    onSurfaceVariant: kTextSecondary,
    surfaceTint: Colors.transparent,
    surfaceContainerLowest: kSurface,
    surfaceContainerLow: kCream,
    surfaceContainer: kCream,
    surfaceContainerHigh: kCream,
    surfaceContainerHighest: kSoftSand,
    outline: kOcean,
    outlineVariant: kBorder,
    error: kRed,
    onError: Colors.white,
    shadow: kDeepTeal,
  );

  OutlineInputBorder inputBorder(Color color, [double width = 1]) =>
      OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: color, width: width),
      );

  final buttonShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(14),
  );

  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: kCream,
    canvasColor: kCream,
    fontFamily: 'Roboto',
    iconTheme: const IconThemeData(color: kOcean),
    dividerTheme: const DividerThemeData(color: kBorder, thickness: 1),
    appBarTheme: const AppBarTheme(
      backgroundColor: kCream,
      foregroundColor: kDeepTeal,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      elevation: 0,
      centerTitle: false,
      iconTheme: IconThemeData(color: kDeepTeal),
      actionsIconTheme: IconThemeData(color: kDeepTeal),
      titleTextStyle: TextStyle(
        color: kDeepTeal,
        fontSize: 20,
        fontWeight: FontWeight.w800,
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: kDeepTeal,
        foregroundColor: Colors.white,
        disabledBackgroundColor: kDeepTeal.withValues(alpha: 0.12),
        disabledForegroundColor: kDeepTeal.withValues(alpha: 0.38),
        shape: buttonShape,
      ),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: kDeepTeal,
        foregroundColor: Colors.white,
        shape: buttonShape,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: kDeepTeal,
        side: const BorderSide(color: kBorder),
        shape: buttonShape,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: kOcean),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: kDeepTeal),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: kDeepTeal,
      foregroundColor: Colors.white,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: kSurface,
      hintStyle: const TextStyle(color: kTextMuted),
      labelStyle: const TextStyle(color: kTextSecondary),
      floatingLabelStyle: const TextStyle(color: kOcean),
      prefixIconColor: kOcean,
      suffixIconColor: kOcean,
      border: inputBorder(kBorder),
      enabledBorder: inputBorder(kBorder),
      focusedBorder: inputBorder(kOcean, 1.5),
      errorBorder: inputBorder(kRed),
      focusedErrorBorder: inputBorder(kRed, 1.5),
    ),
    textSelectionTheme: TextSelectionThemeData(
      cursorColor: kOcean,
      selectionColor: kSeafoam.withValues(alpha: 0.55),
      selectionHandleColor: kOcean,
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: kOcean,
      linearTrackColor: kBorder,
      circularTrackColor: kSoftSeafoam,
    ),
    chipTheme: ChipThemeData(
      backgroundColor: kSurface,
      selectedColor: kDeepTeal,
      disabledColor: kSoftSand,
      side: const BorderSide(color: kBorder),
      labelStyle: const TextStyle(
        color: kDeepTeal,
        fontWeight: FontWeight.w700,
      ),
      secondaryLabelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w700,
      ),
      checkmarkColor: Colors.white,
      iconTheme: const IconThemeData(color: kOcean),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    cardTheme: CardThemeData(
      color: kSurface,
      surfaceTintColor: Colors.transparent,
      shadowColor: kShadow,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(17),
        side: const BorderSide(color: kBorder),
      ),
    ),
    listTileTheme: const ListTileThemeData(
      iconColor: kOcean,
      textColor: kDeepTeal,
      selectedColor: kDeepTeal,
      selectedTileColor: kSoftSeafoam,
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: kSurface,
      surfaceTintColor: Colors.transparent,
      titleTextStyle: const TextStyle(
        color: kDeepTeal,
        fontSize: 19,
        fontWeight: FontWeight.w800,
      ),
      contentTextStyle: const TextStyle(color: kTextBody, height: 1.4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: kSurface,
      surfaceTintColor: Colors.transparent,
      modalBackgroundColor: kSurface,
      dragHandleColor: kSeafoam,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: kDeepTeal,
      contentTextStyle: const TextStyle(color: Colors.white),
      actionTextColor: kSand,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    popupMenuTheme: const PopupMenuThemeData(
      color: kSurface,
      surfaceTintColor: Colors.transparent,
      textStyle: TextStyle(color: kDeepTeal),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? Colors.white : kOcean,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? kOcean : kSoftSeafoam,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? kDeepTeal : null,
      ),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? kDeepTeal : kTextSecondary,
      ),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: kSurface,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: kDeepTeal,
      headerForegroundColor: Colors.white,
    ),
  );
}

class CountryExplorerUasApp extends StatelessWidget {
  const CountryExplorerUasApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Country Explorer',
      theme: buildCoastalTheme(),
      initialRoute: '/',
      routes: {
        '/': (context) => const Home(),
        '/detail': (context) {
          // Argumen dicek aman (tanpa operator "!") agar route tidak crash
          // bila dipanggil tanpa kode negara.
          final args = ModalRoute.of(context)?.settings.arguments;
          if (args is String && args.trim().isNotEmpty) {
            return Detail(countryCode: args);
          }
          return const Scaffold(
            body: Center(child: Text('Kode negara tidak valid.')),
          );
        },
        '/location': (context) => const LocationPage(),
        '/travel': (context) => const TravelList(),
        '/favorites': (context) => const FavoritesPage(),
        '/map': (context) => const WorldMapPage(),
      },
    );
  }
}
