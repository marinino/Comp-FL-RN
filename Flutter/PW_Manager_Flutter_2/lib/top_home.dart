import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'main.dart';
import 'package:provider/provider.dart';

class TopSection extends StatelessWidget {

  AlphabeticalList listProvide = new AlphabeticalList();

  @override
  Widget build(BuildContext context) {

    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.secondary,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                '10 \n Passwords',
                style: TextStyle(
                  fontSize: 20.0,
                  color: theme.colorScheme.onSecondary,
                ),
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Text(
                '3 \n Strong',
                style: TextStyle(
                  fontSize: 16.0,
                  color: theme.colorScheme.onSecondary,
                ),
              ),
            ),
            const SizedBox(width: 16.0),
            Expanded(
              child: Text(
                '2 \n Mediocre',
                style: TextStyle(
                  fontSize: 16.0,
                  color: theme.colorScheme.onSecondary,
                ),
              ),
            ),
          ],
        ),

      )
    );

  }
}

class AlphabeticalList extends StatelessWidget {
  // Sample data for illustration


  @override
  Widget build(BuildContext context) {

    var listProvider = Provider.of<ListProvider>(context);
    List<AlphabeticalListItem> listItems = listProvider.listItems;
    // Sort the list alphabetically by the first letter of the title
    listItems.sort((a, b) => a.application.compareTo(b.application));

    // Create a map to group items by their first letter
    final groupedItems = groupBy(listItems, (AlphabeticalListItem item) => item.firstLetter);

    // Extract the keys and sort them
    final keys = groupedItems.keys.toList()..sort();

    final theme = Theme.of(context);

    void showPopup(BuildContext context, String password, String application) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text('Password of ' + application),
            content: Text(password),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text('Close'),
              ),
            ],
          );
        },
      );
    }

    return ListView.builder(
      itemCount: keys.length,
      itemBuilder: (context, index) {
        final key = keys[index];
        final itemsForSection = groupedItems[key]!;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section Heading
            ListTile(
              title: Text(
                  key,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary
                  )
              ),
            ),
            // List Items for the Section
            ListView.separated(
              shrinkWrap: true,
              physics: ClampingScrollPhysics(),
              itemCount: itemsForSection.length,
              itemBuilder: (context, itemIndex) {
                final item = itemsForSection[itemIndex];
                return ListTile(
                  title: Text(item.application),
                  subtitle: Text(item.email),
                  onTap: () {
                    // Handle the tap on the list item (button)
                    showPopup(context, item.password, item.application);
                  },
                );
              },
              separatorBuilder: (context, itemIndex) => Divider(),
            ),
          ],
        );
      },
    );
  }
}




