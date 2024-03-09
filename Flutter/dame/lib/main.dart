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

class _DameBoardState extends State<DameBoard> with TickerProviderStateMixin {


  late DameGame game;
  AnimationController? _animationController;
  Animation<Offset>? _animation;


  @override
  void initState() {
    super.initState();
    game = DameGame();
    game.addListener(_updateGame);

    _animationController = AnimationController(
      duration: const Duration(milliseconds: 10000),
      vsync: this,
    )..addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Do something when the animation ends
        print("Animation completed!");
        for(var i = 0; i < 10; i++){
          for(var j = 0; j < 10; j++){
            game.board[i][j]?.isAnimated = false;
          }
        }
        if(game.currentPlayer == 2){
          log('SIM PC MOVE ${game.currentPlayer}');
          var dataFromMove = game.simulateComputerMove();
          _startAnimation(dataFromMove[0] ,dataFromMove[1] , dataFromMove[2], dataFromMove[3]);
        }
        print("Animation completed!");
      }
    });
  }

  @override
  void dispose() {
    game.removeListener(_updateGame);
    _animationController?.dispose();
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

      game.move(selectedX ,selectedY , column, row);
      _startAnimation(selectedX ,selectedY , column, row);

      selectedX = -1;
      selectedY = -1;
    }


    setState(() {

    });
    // Hier können Sie weitere Interaktionen hinzufügen
  }

  void _startAnimation(int startX, int startY, int endX, int endY) {
    log('PINWORD' + startX.toString() + ' ' + startY.toString() + ' ' + endX.toString() + ' ' + ' ' + endY.toString());
    final beginOffset = Offset((startX.toDouble() - endX.toDouble()) * (MediaQuery.of(context).size.width / 10),
        (startY.toDouble()- endY.toDouble()) * (MediaQuery.of(context).size.width / 10));
    final endOffset = Offset((MediaQuery.of(context).size.width / 10) * 0.1,(MediaQuery.of(context).size.width / 10)  * 0.1);
    _animation = Tween<Offset>(begin: beginOffset, end: endOffset).animate(
      CurvedAnimation(parent: _animationController!, curve: Curves.easeInOut),
    );

    _animationController?.forward(from: 0.0);
    log('START ANIMATION OR DONE ODER SO 1234');


    setState(() {
      // Trigger rebuild to start animation
    });
  }

  Widget createPieceWidget(Color color, String letter, bool animate, int x, int y) {
    // Create the base piece widget
    Widget piece = Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: (MediaQuery.of(context).size.width / 10) * 0.8,
          height: (MediaQuery.of(context).size.width / 10) * 0.8,
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
        ),
        Text(
          letter,
          style: TextStyle(
            color: color == Colors.black ? Colors.white : Colors.black,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
    // Apply animation if needed
    print(piece);
    if (animate && _animation != null) {
      piece = AnimatedBuilder(
        animation: _animation!,
        builder: (context, child) {
          return Transform.translate(
            offset: _animation!.value - Offset(x.toDouble(), y.toDouble()),
            child: child,
          );
        },
        child: piece,
      );
    }

    // Wrap the piece in an IgnorePointer if you don't want it to intercept touch events
    return IgnorePointer(
      ignoring: true, // Set to true to ignore pointer events, false to allow them
      child: piece,
    );
  }

  Widget buildGamePieces() {
    double screenWidth = MediaQuery.of(context).size.width;
    List<Widget> pieces = [];
    // Iterate over the game state to create widgets for each piece
    for (var row = 0; row < 10; row++) {
      for (var col = 0; col < 10; col++) {
        final piece = game.board[row][col];
        if (piece != null) {
          final letter = piece.isQueen ? 'D' : '';
          final color = piece.playerId == 2 ? Colors.black : Colors.white;
          final pieceWidget = Positioned(
            left: col * (screenWidth / 10) + screenWidth / 10 * 0.1,
            top: row * (screenWidth / 10) + screenWidth / 10 * 0.1,
            child: createPieceWidget(color, letter, piece.isAnimated, col, row),
          );
          pieces.add(pieceWidget);
        }
      }
    }
    return Stack(children: pieces);
  }


  Widget buildGameBoard() {
    return GridView.builder(
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 10, // Define the number of columns in the grid
      ),
      itemCount: 100, // Total number of squares (10x10 board)
      itemBuilder: (context, index) {
        int row = index ~/ 10; // Calculate row number
        int col = index % 10; // Calculate column number
        bool isDarkField = (index % 2 == 0) ^ (row % 2 == 0); // Determine if the square should be dark
        Color color = isDarkField ? Colors.brown[700]! : Colors.brown[200]!; // Set color based on whether the field is dark or not

        // Simply return a container for each grid square
        return InkWell(
            onTap: () {
            // Handle the tap, e.g., by calling onFieldTap with the row and column
            onFieldTap(row, col);
          },
          child: Container(
            decoration: BoxDecoration(
              color: color, // Use the calculated color
              border: Border.all(color: Colors.grey), // Add border to distinguish between squares
            ),
          ),
        );
      },
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('10x10 Damespiel'),
      ),
      body: Column(
        children: [
          Expanded(child: Stack(
            children: [
              buildGameBoard(),
              buildGamePieces()
            ],
          )

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

