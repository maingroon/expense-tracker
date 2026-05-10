import 'package:expense_tracker/constants/theme_constants.dart';
import 'package:expense_tracker/screens/analytics/analytics_page.dart';
import 'package:expense_tracker/screens/forecast/forecast_screen.dart';
import 'package:expense_tracker/services/aggregation_service.dart';
import 'package:expense_tracker/services/categories_service.dart';
import 'package:expense_tracker/services/database_service.dart';
import 'package:expense_tracker/services/forecast_repository.dart';
import 'package:expense_tracker/services/forecasting_service.dart';
import 'package:expense_tracker/services/ridge_forecasting_service.dart';
import 'package:expense_tracker/services/theme_provider.dart';
import 'package:expense_tracker/screens/categories/categories_page.dart';
import 'package:expense_tracker/screens/transactions/transactions_page.dart';
import 'package:expense_tracker/screens/settings/settings_page.dart';
import 'package:expense_tracker/services/settings_service.dart';
import 'package:expense_tracker/services/transactions_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await SettingsService.init();
    await CategoriesService.init();
    await TransactionsService.init();
    runApp(const PageContainer());
  } catch (e) {
    runApp(InitErrorApp(error: e));
  }
}

class InitErrorApp extends StatelessWidget {
  const InitErrorApp({required this.error, super.key});

  final Object error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'Failed to initialize app',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(error.toString()),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: () async {
                    try {
                      await SettingsService.init();
                      await CategoriesService.init();
                      await TransactionsService.init();
                    } catch (_) {}
                  },
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PageContainer extends StatefulWidget {
  const PageContainer({super.key});

  @override
  State<PageContainer> createState() => _PageContainerState();
}

class _PageContainerState extends State<PageContainer> {
  int _currentPageIndex = 0;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(create: (_) => ThemeProvider()),
        Provider<DatabaseService>(create: (_) => DatabaseService()),
        ProxyProvider<DatabaseService, AggregationService>(
          update: (_, db, __) => AggregationService(db),
        ),
        ProxyProvider<DatabaseService, ForecastRepository>(
          update: (_, db, __) => ForecastRepository(db),
        ),
        ProxyProvider2<AggregationService, ForecastRepository, ForecastingService>(
          update: (_, agg, repo, __) => RidgeForecastingService(
            agg,
            repo,
            fallback: NaiveForecastingService(agg, repo),
          ),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, child) {
          final pages = <Widget>[
            const CategoriesPage(),
            const TransactionsPage(),
            const AnalyticsPage(),
            const ForecastScreen(),
            const SettingsPage(),
          ];

          final safeIndex = _currentPageIndex.clamp(0, pages.length - 1);

          return MaterialApp(
            title: 'Expense tracker',
            debugShowCheckedModeBanner: false,
            theme: kLightTheme,
            darkTheme: kDarkTheme,
            themeMode: themeProvider.getThemeMode(),
            home: Scaffold(
              bottomNavigationBar: NavigationBar(
                onDestinationSelected: (int index) {
                  setState(() => _currentPageIndex = index);
                },
                selectedIndex: safeIndex,
                destinations: const <Widget>[
                  NavigationDestination(
                    selectedIcon: Icon(Icons.category),
                    icon: Icon(Icons.category_outlined),
                    label: 'Categories',
                  ),
                  NavigationDestination(
                    selectedIcon: Icon(Icons.format_list_bulleted),
                    icon: Icon(Icons.format_list_bulleted_outlined),
                    label: 'Transactions',
                  ),
                  NavigationDestination(
                    selectedIcon: Icon(Icons.bar_chart),
                    icon: Icon(Icons.bar_chart_outlined),
                    label: 'Analytics',
                  ),
                  NavigationDestination(
                    selectedIcon: Icon(Icons.show_chart),
                    icon: Icon(Icons.show_chart_outlined),
                    label: 'Forecast',
                  ),
                  NavigationDestination(
                    selectedIcon: Icon(Icons.settings),
                    icon: Icon(Icons.settings_outlined),
                    label: 'Settings',
                  ),
                ],
              ),
              body: pages[safeIndex],
            ),
          );
        },
      ),
    );
  }
}
