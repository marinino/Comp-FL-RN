import 'dart:developer';

import '../models/dame_game.dart';
import 'package:flutter/material.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '10x10 Damespiel',
      home: DameBoard(),
    );
  }
}

class DameBoard extends StatefulWidget {
  @override
  _DameBoardState createState() => _DameBoardState();
}

class _DameBoardState extends State<DameBoard> {


  late DameGame game;

  @override
  void initState() {
    super.initState();
    game = DameGame();
    game.addListener(_updateGame);
  }

  @override
  void dispose() {
    game.removeListener(_updateGame);
    super.dispose();
  }

  void _updateGame() {
    setState(() {
      // Diese Methode wird aufgerufen, wenn das Spiel zurückgesetzt wird.
      // Der setState-Aufruf sorgt dafür, dass das Widget neu gebaut wird.
    });
  }


  int selectedX = -1;
  int selectedY = -1;



  void onFieldTap(int row, int column) {
    log(row.toString() + '; ' + column.toString());
    log(selectedY.toString() + '; sel: ' + selectedX.toString());
    if(selectedX == -1){
      if(game.board[row][column]?.playerId != game.currentPlayer){
        return;
      }
      selectedX = column;
      selectedY = row;
      game.stateString =
        'Spieler ${game.currentPlayer} hat den Stein auf der Position ($row, $column) markiert';
    } else if(selectedY == row && selectedX == column){
      selectedX = -1;
      selectedY = -1;
      game.stateString =
        'Spieler ${game.currentPlayer} hat seine Steinauswahl rückgängig gemacht';
      return;
    }
    else {
      log('Tried to call move');
      game.move(selectedX ,selectedY , column, row);

      selectedX = -1;
      selectedY = -1;
    }


    setState(() {

    });
    // Hier können Sie weitere Interaktionen hinzufügen
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('10x10 Damespiel'),
      ),
      body: Column(
        children: [
          Expanded(
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 10, // 10 Spalten
              ),
              itemCount: 100, // 10x10 Felder
              itemBuilder: (context, index) {
                int row = index ~/ 10;
                int col = index % 10;
                bool isDarkField = (index % 2 == 0) ^ (row % 2 == 0);
                Color? color = isDarkField ? Colors.brown[700] : Colors.brown[200];



                // Bestimmen Sie, welcher Spielstein (falls vorhanden) in diesem Feld ist
                Widget piece = SizedBox();
                if (isDarkField) {
                  String letter = '';
                  if(game.board[row][col] != null && game.board[row][col]!.isQueen){
                    letter = 'D';
                  }
                  if (game.board[row][col]?.playerId == 1) { // Spieler 1

                    piece = buildPiece(Colors.white, letter);
                  } else if (game.board[row][col]?.playerId == 2) { // Spieler 2

                    piece = buildPiece(Colors.black, letter);
                  }
                }

                return InkWell(
                  onTap: () => onFieldTap(index ~/ 10, index % 10),
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      border: Border.all(color: Colors.grey),
                    ),
                    child: Center(
                      child: piece,
                    ),
                  ),
                );
              },
            ),
          ),
          Container(
            child: Text(game.stateString,
              style: TextStyle(
                fontSize: 20
              ),
            )
          )

        ],
      )
      
    );
  }
}

Widget buildPiece(Color color, String letter) {

  bool pieceIsBlack = false;
  if(color == Colors.black){
    pieceIsBlack = true;
  }

  return Stack(
    alignment: Alignment.center,
    children: [
      FractionallySizedBox(
        widthFactor: 0.8,
        heightFactor: 0.8,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
      ),
      Text(letter,

        style: TextStyle(
          color: pieceIsBlack ? Colors.white : Colors.black, // Wählen Sie eine passende Textfarbe
          fontWeight: FontWeight.bold,

        ),
      )
    ],

  );
}