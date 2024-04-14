import 'dart:convert';
import 'package:flutter/material.dart';
import 'generate_password.dart';
import 'top_home.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (context) => ListProvider(),
      child: const MyApp(),
    ),

  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepOrange),
      ),
      home: const MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {

  int _currentIndex = 0; // Index of the current tab
  final List<Widget> _screens = [
    const HomeScreen(),
    const SecondScreen(),
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

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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

  ListProvider() {
    loadItems(); // Load items when the provider is initialized
  }
  Future<void> loadItems() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    // Assuming you store your items under a single key as a list
    String? itemsString = prefs.getString('items');
    if (itemsString != null) {
      List<dynamic> jsonList = json.decode(itemsString);
      listItems = jsonList
          .map((jsonItem) => AlphabeticalListItem.fromJson(jsonItem))
          .toList();
      notifyListeners();
    }
  }

  List<AlphabeticalListItem> listItems = [
    AlphabeticalListItem(application: 'Apple', email: 'example1@mail.com', password: '123456'),
    AlphabeticalListItem(application: 'Banana', email: 'example2@mail.com', password: '123456'),
    AlphabeticalListItem(application: 'Avocado', email: 'example3@mail.com', password: '123456'),
    AlphabeticalListItem(application: 'Grapes', email: 'example4@mail.com', password: '123456'),
    AlphabeticalListItem(application: 'Orange', email: 'example5@mail.com', password: '123456'),
    // Add more items as needed
  ];

  void addItem(AlphabeticalListItem newItem) {
    listItems.add(newItem);
    notifyListeners();
  }

  List<AlphabeticalListItem> getList(){
    return listItems;
  }
}

class AlphabeticalListItem {
  final String application;
  final String email;
  final String password;

  AlphabeticalListItem({required this.application, required this.email, required this.password});

  // Extract the first letter from the title
  String get firstLetter => application.isNotEmpty ? application[0].toUpperCase() : '';

  // Convert a AlphabeticalListItem object into a map
  Map<String, dynamic> toJson() => {
    'application': application,
    'email': email,
    'password': password,
  };

  // Factory constructor to create an instance of AlphabeticalListItem from a map
  factory AlphabeticalListItem.fromJson(Map<String, dynamic> json) {
    return AlphabeticalListItem(
      application: json['application'],
      email: json['email'],
      password: json['password'],
    );
  }
}
