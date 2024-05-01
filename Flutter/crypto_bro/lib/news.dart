import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';

Future<List<MyDataModel>> fetchData() async {
  http.Response response;

  try{
    response = await http.get(
        Uri.parse('https://newsdata.io/api/1/news?apikey=pub_3479125dc2aa95ff324e8db0dcba1f6dc723f&q=crypto%20news')
    );
  } catch(e){
    log(e.toString());
    return [];
  }

  if (response.statusCode == 200) {
    List<dynamic> values = json.decode(response.body)["results"];
    return values.map((e) => MyDataModel.fromJson(e)).toList();
  } else {
    throw Exception('Failed to load data');
  }
}

class MyDataModel {
  final String id;
  final String title;
  final String link;
  // Add other fields you expect from the API

  MyDataModel({required this.id, required this.title, required this.link});

  factory MyDataModel.fromJson(Map<String, dynamic> json) {
    return MyDataModel(
      id: json['article_id'],
      title: json['title'],
      link: json['link']
      // Initialize other fields
    );
  }
}

class NewsScreen extends StatelessWidget{
  const NewsScreen({super.key});

  @override
  Widget build(BuildContext context){
    return SingleChildScrollView(
      child: Column(
        children: [
          AppBar(
            title: const Text('News-Feed'),  // Header label added here
            centerTitle: true,
          ),
          const NewsTable()
        ]
      )
    );
  }
}

class NewsTable extends StatelessWidget {
  const NewsTable({super.key});

  // Function to launch URLs
  void _launchURL(Uri url) async {
    if (!await launchUrl(url)) throw 'Could not launch $url';
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<MyDataModel>>(
      future: fetchData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          // Create a DataTable widget and fill it with data
          return DataTable(
            columns: const <DataColumn>[
              DataColumn(label: Text('Articles')),
              // Add other DataColumn widgets for other fields
            ],
            rows: snapshot.data!
                .map(
                  (data) => DataRow(
                cells: [
                  DataCell(
                    Text(
                      data.title,
                      overflow: TextOverflow.ellipsis,  // Add an ellipsis at the end of the text
                      softWrap: false,  // Prevent the text from wrapping to the next line
                      maxLines: 2,  // Ensure the text doesn't exceed one line
                    ),
                    onTap: () => _launchURL(Uri.parse(data.link)),
                  ),
                  // Add other DataCell widgets for other fields
                ],
              ),
            ).toList(),
          );
        }
      },
    );
  }
}