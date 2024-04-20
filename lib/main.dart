import 'package:expense_tracker/constants/theme_constants.dart';
import 'package:expense_tracker/services/theme_provider.dart';
import 'package:expense_tracker/screens/categories/categories_page.dart';
import 'package:expense_tracker/screens/transactions/transactions_page.dart';
import 'package:expense_tracker/screens/settings/settings_page.dart';
import 'package:expense_tracker/services/settings_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SettingsService.init().then((value) {
    runApp(const PageContainer());
  });
}

class PageContainer extends StatefulWidget {
  const PageContainer({super.key});

  @override
  State<PageContainer> createState() {
    return _PageContainerState();
  }
}

class _PageContainerState extends State<PageContainer> {
  int _currentPageIndex = 0;

  final List<Widget> _pages = const <Widget>[
    CategoriesPage(),
    TransactionsPage(),
    SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeProvider>(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, value, child) {
          return MaterialApp(
            title: 'Money tracker',
            debugShowCheckedModeBanner: false,
            theme: kLightTheme,
            darkTheme: kDarkTheme,
            themeMode: SettingsService.getThemeMode(),
            home: Scaffold(
              bottomNavigationBar: BottomNavigationBar(
                items: const [
                  BottomNavigationBarItem(
                    icon: Icon(Icons.label),
                    label: 'Categories',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.format_list_bulleted),
                    label: 'Transactions',
                  ),
                  BottomNavigationBarItem(
                    icon: Icon(Icons.settings),
                    label: 'Settings',
                  ),
                ],
                currentIndex: _currentPageIndex,
                onTap: (value) {
                  setState(() {
                    _currentPageIndex = value;
                  });
                },
                type: BottomNavigationBarType.fixed,
                showSelectedLabels: true,
                showUnselectedLabels: true,
                enableFeedback: true,
              ),
              body: _pages[_currentPageIndex],
            ),
          );
        },
      ),
    );
  }
}
