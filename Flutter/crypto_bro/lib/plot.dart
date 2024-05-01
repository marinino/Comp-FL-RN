import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_charts/charts.dart';
import 'package:flutter/services.dart' show rootBundle;

enum IconLabel {
  smile('Smile', Icons.sentiment_satisfied_outlined),
  cloud(
    'Cloud',
    Icons.cloud_outlined,
  ),
  brush('Brush', Icons.brush_outlined),
  heart('Heart', Icons.favorite);

  const IconLabel(this.label, this.icon);
  final String label;
  final IconData icon;
}

enum CurrencyLabel {
  bitcoin('Bitcoin', Colors.blue),
  ethereum('Ethereum', Colors.pink),
  xpr('XPR', Colors.green),
  dash('Dash', Colors.orange),
  stellar('Stellar', Colors.grey);

  const CurrencyLabel(this.label, this.color);
  final String label;
  final Color color;
}

class PlotScreen extends StatefulWidget {
  const PlotScreen({super.key});

  @override
  State<PlotScreen> createState() => _PlotScreenState();
}

class _PlotScreenState extends State<PlotScreen> {
  State<StatefulWidget> createState() {
    // TODO: implement createState
    throw UnimplementedError();
  }

  final TextEditingController colorController = TextEditingController();
  final TextEditingController iconController = TextEditingController();
  CurrencyLabel? selectedCurrency;
  IconLabel? selectedIcon;
  TooltipBehavior? _tooltipBehavior;
  List<DataPoint> bitcoinData = [];
  List<DataPoint> dashData = [];
  List<DataPoint> ethereumData = [];
  List<DataPoint> stellarData = [];
  List<DataPoint> xprData = [];

  void loadBitcoinData() async {
    var jsonText = await rootBundle.loadString('assets/bitcoin_currency_data.json');
    List<Map<String, dynamic>> bitcoinRaw = List<Map<String, dynamic>>.from(json.decode(jsonText));

    for(var el in bitcoinRaw){  
      bitcoinData.add(DataPoint(el['Date'], el['Currency_Value']));
    }

  }

  void loadDashData() async {
    var jsonText = await rootBundle.loadString('assets/dash_currency_data.json');
    List<Map<String, dynamic>> dashRaw = List<Map<String, dynamic>>.from(json.decode(jsonText));

    for(var el in dashRaw){
      dashData.add(DataPoint(el['Date'], el['Currency_Value']));
    }
  }

  void loadEthereumData() async {
    var jsonText = await rootBundle.loadString('assets/ethereum_currency_data.json');
    List<Map<String, dynamic>> ethereumRaw = List<Map<String, dynamic>>.from(json.decode(jsonText));

    for(var el in ethereumRaw){
      ethereumData.add(DataPoint(el['Date'], el['Currency_Value']));
    }
  }

  void loadStellarData() async {
    var jsonText = await rootBundle.loadString('assets/stellar_currency_data.json');
    List<Map<String, dynamic>> stellarRaw = List<Map<String, dynamic>>.from(json.decode(jsonText));

    for(var el in stellarRaw){
      stellarData.add(DataPoint(el['Date'], el['Currency_Value']));
    }
  }

  void loadXPRData() async {
    var jsonText = await rootBundle.loadString('assets/xpr_currency_data.json');
    List<Map<String, dynamic>> xprRaw = List<Map<String, dynamic>>.from(json.decode(jsonText));

    for(var el in xprRaw){
      xprData.add(DataPoint(el['Date'], el['Currency_Value']));
    }
  }

  @override
  void initState(){
    _tooltipBehavior = TooltipBehavior(enable: true);
    loadBitcoinData();
    loadDashData();
    loadEthereumData();
    loadStellarData();
    loadXPRData();
    super.initState();
  }

  var dataDisplayed = [DataPoint('Jan', 0), DataPoint('Feb', 0), DataPoint('Mar', 0),
    DataPoint('Apr', 0), DataPoint('May', 0)];

  var currentTrend = 'Neutral';
  var currentTrendColor = 'black';

  void changeDataDisplayed() {
    if(selectedCurrency?.label == 'Bitcoin'){
      updateDisplayData(bitcoinData);
    } else if(selectedCurrency?.label == "Ethereum") {
      updateDisplayData(ethereumData);
    } else if(selectedCurrency?.label == "XPR") {
      updateDisplayData(xprData);
    } else if(selectedCurrency?.label == "Dash") {
      updateDisplayData(dashData);
    } else if(selectedCurrency?.label == "Stellar") {
      updateDisplayData(stellarData);
    }
    updateCurrentTrend();
  }

  void updateDisplayData(List<DataPoint> newValue){
    setState(() {
      dataDisplayed = newValue;
    });
  }

  void updateCurrentTrend(){
    setState(() {
      if(dataDisplayed.last.value > dataDisplayed.elementAt(dataDisplayed.length - 2).value){
        currentTrend = 'Rising';
      } else if(dataDisplayed.last.value < dataDisplayed.elementAt(dataDisplayed.length - 2).value){
        currentTrend = 'Falling';
      } else {
        currentTrend = 'Neutral';
      }
    });
  }

  Color setColorForTrend(){
    if(currentTrend == 'Rising'){
      return Colors.green;
    } else if(currentTrend == 'Falling'){
      return Colors.red;
    } else {
      return Colors.black;
    }
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return Scaffold(
      appBar: AppBar(
        title: const Text('Currency Trends'),  // Header label added here
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  DropdownMenu<CurrencyLabel>(
                    initialSelection: CurrencyLabel.bitcoin,
                    controller: colorController,
                    // requestFocusOnTap is enabled/disabled by platforms when it is null.
                    // On mobile platforms, this is false by default. Setting this to true will
                    // trigger focus request on the text field and virtual keyboard will appear
                    // afterward. On desktop platforms however, this defaults to true.
                    requestFocusOnTap: false,
                    label: const Text('Currency'),
                    onSelected: (CurrencyLabel? currency) {
                      setState(() {
                        selectedCurrency = currency;
                      });
                      changeDataDisplayed();
                    },
                    dropdownMenuEntries: CurrencyLabel.values
                        .map<DropdownMenuEntry<CurrencyLabel>>(
                            (CurrencyLabel currency) {
                          return DropdownMenuEntry<CurrencyLabel>(
                            value: currency,
                            label: currency.label,
                            enabled: currency.label != 'Grey',
                            style: MenuItemButton.styleFrom(
                              foregroundColor: currency.color,
                            ),
                          );
                        }).toList(),
                  ),
                  const SizedBox(height: 20),
                  Text('Current value: ${dataDisplayed.last.value}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 20
                    ),
                  ),
                  const SizedBox(height: 15),
                  //SizedBox(height: 20),
                  SfCartesianChart(
                      // Initialize category axis
                      primaryXAxis: const CategoryAxis(
                      ),
                      primaryYAxis: const NumericAxis(
                        minimum: 0,
                        maximum: 2,
                      ),
                      legend: const Legend(isVisible: false),
                      tooltipBehavior: _tooltipBehavior,
                      series: <LineSeries<DataPoint, String>>[
                        LineSeries<DataPoint, String>(
                            dataSource:  dataDisplayed,
                            xValueMapper: (DataPoint point, _) => point.date,
                            yValueMapper: (DataPoint point, _) => point.value,
                            // Enable data label
                            dataLabelSettings: const DataLabelSettings(isVisible: false)
                        )
                      ]
                  ),
                  const SizedBox(height: 20),
                  Text('Current Trend: $currentTrend',
                    style: TextStyle(
                      color: setColorForTrend(),
                      fontWeight: FontWeight.bold,
                      fontSize: 20
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DataPoint {

  final String date;
  final double value;

  DataPoint(this.date, this.value);
}