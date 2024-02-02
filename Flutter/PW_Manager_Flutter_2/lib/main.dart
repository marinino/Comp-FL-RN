import 'package:flutter/material.dart';
import 'generate_password.dart';
import 'top_home.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ListProvider(),
      child: MyApp(),
    ),

  );
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}


class _MainScreenState extends State<MainScreen> {

  int _currentIndex = 0; // Index of the current tab

  final List<Widget> _screens = [
    HomeScreen(),
    SecondScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.generating_tokens),
            label: 'Generate',
          ),
        ],
      ),
    );
  }
}

//


class HomeScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
            'Manage Passwords',
          style: TextStyle(
            color: theme.colorScheme.onPrimary
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: TopSection(),
          ),
          Expanded(
            flex: 3,
            child: AlphabeticalList(),
          ),
        ],
      ),
    );
  }
}

class ListProvider extends ChangeNotifier {

  List<AlphabeticalListItem> listItems = [
    AlphabeticalListItem(application: 'Apple', email: 'Subtitle A', password: '123456'),
    AlphabeticalListItem(application: 'Banana', email: 'Subtitle B', password: '123456'),
    AlphabeticalListItem(application: 'Avocado', email: 'Subtitle A', password: '123456'),
    AlphabeticalListItem(application: 'Grapes', email: 'Subtitle G', password: '123456'),
    AlphabeticalListItem(application: 'Orange', email: 'Subtitle O', password: '123456'),
    // Add more items as needed
  ];

  void addItem(AlphabeticalListItem newItem) {
    listItems.add(newItem);
    notifyListeners();
  }
}

class AlphabeticalListItem {
  final String application;
  final String email;
  final String password;

  AlphabeticalListItem({required this.application, required this.email, required this.password});

  // Extract the first letter from the title
  String get firstLetter => application.isNotEmpty ? application[0].toUpperCase() : '';
}
