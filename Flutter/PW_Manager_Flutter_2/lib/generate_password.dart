import 'dart:ffi';
import 'dart:ffi';

import 'package:flutter/material.dart';
import 'dart:math';
import 'top_home.dart';
import 'main.dart';
import 'package:provider/provider.dart';

class SecondScreen extends StatefulWidget {
  @override
  _SecondScreenState createState() => _SecondScreenState();
}

class _SecondScreenState extends State<SecondScreen> {
  double _passwordLength = 6;
  int _digitsValue = 0;
  int _capsValue = 0;
  int _symbolsValue = 0;
  String _generatedString = '';
  //AlphabeticalList alphabeticalList = new AlphabeticalList();

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Generate Passwords',
          style: TextStyle(
              color: theme.colorScheme.onPrimary
          ),
        ),
        backgroundColor: theme.colorScheme.primary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SingleChildScrollView(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min, // Important for SingleChildScrollView
              children: [
                Text(
                  'Length of password: $_passwordLength',
                  style: TextStyle(fontSize: 20.0),
                ),
                SizedBox(height: 20.0),
                Slider(
                  value: _passwordLength,
                  min: 6,
                  max: 20,
                  divisions: 14,
                  onChanged: (value) {
                    setState(() {
                      _passwordLength = value.roundToDouble();
                    });
                  },

                ),
                SizedBox(height: 20.0),
                _buildLabelWithButtons('Digits', _digitsValue),
                _buildLabelWithButtons('Capitals', _capsValue),
                _buildLabelWithButtons('Symbols', _symbolsValue),
                SizedBox(height: 20.0),
                Row(
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _generatedString = _generateString();
                        });
                      },
                      child: Text(
                        'Generate Password',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                      ),
                    ),
                    SizedBox(width: 16.0), // Adjust the spacing between buttons as needed
                    ElevatedButton(
                      onPressed: () {
                        openPopUpToSavePassword();
                      },
                      child: Text(
                        'Save Password',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimary,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.secondary, // Adjust the color as needed
                      ),
                    ),
                  ],
                ),
                Card(color: theme.colorScheme.primary,    // ← And also this.
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      _generatedString,
                      style: TextStyle(
                          color: theme.colorScheme.onPrimary
                      ),
                    ),

                  ),
                ),
              ],
            ),
          ),
        ),
        )
    );
  }

  Widget _buildLabelWithButtons(String label, int value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          '$label: $value',
          style: TextStyle(fontSize: 16.0),
        ),
        SizedBox(height: 8.0),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                _incrementLabelValue(label);
              },
            ),
            IconButton(
              icon: Icon(Icons.remove),
              onPressed: () {
                _decrementLabelValue(label);
              },
            ),
          ],
        ),
        SizedBox(height: 16.0),
      ],
    );
  }

  void _incrementLabelValue(String label) {
    setState(() {
      switch (label) {
        case 'Digits':
          _digitsValue++;
          break;
        case 'Capitals':
          _capsValue++;
          break;
        case 'Symbols':
          _symbolsValue++;
          break;
      }
    });
  }

  void _decrementLabelValue(String label) {
    setState(() {
      switch (label) {
        case 'Digits':
          _digitsValue = _digitsValue > 0 ? _digitsValue - 1 : 0;
          break;
        case 'Capitals':
          _capsValue = _capsValue > 0 ? _capsValue - 1 : 0;
          break;
        case 'Symbols':
          _symbolsValue = _symbolsValue > 0 ? _symbolsValue - 1 : 0;
          break;
      }
    });
  }

  String _generateString() {
    if (_passwordLength < _digitsValue + _capsValue + _symbolsValue) {
      throw ArgumentError('Total length should be greater than or equal to the sum of digits, capital letters, lowercase letters, and symbols.');
    }

    final rand = Random();

    // Generate digits
    final digits = List.generate(_digitsValue, (_) => rand.nextInt(10).toString());

    // Generate capital letters
    final capitalLetters = List.generate(_capsValue, (_) => String.fromCharCode(rand.nextInt(26) + 65));

    // Define symbols
    const symbols = r"!@#$%^&*()_-+=[]{}|;:,.<>?";

    // Generate symbols
    final symbolList = List.generate(_symbolsValue, (_) => symbols[rand.nextInt(symbols.length)]);

    // Concatenate all the generated characters
    final characters = [...digits, ...capitalLetters, ...symbolList];
    characters.shuffle(); // Shuffle the characters to randomize their order

    // Generate the remaining characters to fill the specified length
    final remainingLength = _passwordLength.round() - characters.length;
    final remainingCharacters = List.generate(remainingLength, (_) => String.fromCharCode(rand.nextInt(26) + 97));

    final passwordAsArray = (characters.join() + remainingCharacters.join()).split('');
    passwordAsArray.shuffle();

    return passwordAsArray.join();

  }

  void openPopUpToSavePassword(){
    TextEditingController applicationInput = TextEditingController();
    TextEditingController eMailInput = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Enter further'),
          content: Column(
            children: [
              const Text('Enter application:'),
              TextField(
                controller: applicationInput,
                decoration: InputDecoration(
                  hintText: 'Application name...',
                ),
              ),
              SizedBox(height: 30.0),
              const Text('Enter E-Mail:'),
              TextField(
                controller: eMailInput,
                decoration: InputDecoration(
                  hintText: 'E-Mail adress...',
                ),
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              onPressed: () {
                var listProvider = Provider.of<ListProvider>(context, listen: false);
                // Do something with the entered text, e.g., print it
                print('Entered text: ${applicationInput.text}');
                AlphabeticalListItem item = new AlphabeticalListItem(
                    application: applicationInput.text,
                    email: eMailInput.text,
                    password: _generatedString);
                listProvider.addItem(item);

                setState(() {});
                //print(alphabeticalList.listItems.length);
                Navigator.pop(context);
              },
              child: Text('Submit'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: Text('Cancel'),
            ),
          ],
        );
      },
    );

  }
}
