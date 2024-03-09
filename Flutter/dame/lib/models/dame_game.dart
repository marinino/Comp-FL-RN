import 'dart:developer';
import 'dart:ui';
import 'game_piece.dart';

class DameGame {

  // Eine Liste von Callbacks, die aufgerufen werden, wenn das Spiel zurückgesetzt wird
  List<VoidCallback> _listeners = [];

  // Methode zum Hinzufügen eines Listeners
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  // Methode zum Entfernen eines Listeners
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  late List<List<GamePiece?>> board; // 0 = kein Stein, 1 = Spieler 1, 2 = Spieler 2
  late int currentPlayer; // 1 oder 2
  String stateString = '';

  DameGame() {
    // Initialisieren Sie das Spielbrett und setzen Sie den aktuellen Spieler
    board = List.generate(10, (_) => List.generate(10, (_) => null));

    currentPlayer = 1;

    // Setzen Sie die Startpositionen der Spielsteine
    for (int i = 0; i < 4; i++) {
      for (int j = (i % 2); j < 9; j += 2) {
        board[i][j + 1] = GamePiece(playerId: 1);
        board[9 - i][j] = GamePiece(playerId: 2);
      }
    }

    board[1][0] = GamePiece(playerId: 1);
    board[3][0] = GamePiece(playerId: 1);
    board[6][9] = GamePiece(playerId: 2);
    board[8][9] = GamePiece(playerId: 2);
    stateString = 'Spieler 1 ist an der Reihe';
  }

  bool move(int startX, int startY, int endX, int endY) {
    log('Called move');
    // Prüfen Sie, ob der Zug gültig ist
    if (!isValidMove(startX, startY, endX, endY)) {
      return false;
    }

    var checkBeatenPiece = checkAndRemoveOppBeaten(startX, startY, endX, endY, true);
    var foundOptimum = findMovesWhichBeat();

    if(checkBeatenPiece == null && foundOptimum.getPiece() != null){
      stateString = 'Spieler ${currentPlayer} hat die Schlagpflicht verletzt, wähle einen anderen Zug';
      return false;
    }
    if(foundOptimum.getPiece() != null && foundOptimum.getPiece()!.isQueen && checkBeatenPiece != null
      && !checkBeatenPiece.isQueen){
      stateString = 'Dame schlagen geht vor';
          return false;
    }

    // Führen Sie den Zug aus

    board[startY][startX]?.isAnimated = true;

    board[endY][endX] = board[startY][startX];
    board[startY][startX] = null;

    // Prüfen Sie, ob ein Gegner übersprungen wurde, und entfernen Sie ihn
    //int midX = (startX + endX) ~/ 2;
    //int midY = (startY + endY) ~/ 2;
    //if (board[midX][midY] != null) {
    //  log('Puff');
    //}
    GamePiece? beatenPiece = checkAndRemoveOppBeaten(startX, startY, endX, endY, true);

    bool newQueen = checkForQueenConv();



    // Changes player, if futher beat is not possible or there was no beat in the first place
    if(beatenPiece != null && findMovesWhichBeat().getPiece() != null && newQueen == false){
      stateString = 'Spieler $currentPlayer bleibt dran';
    } else {
      currentPlayer = 3 - currentPlayer;
      stateString = 'Spieler $currentPlayer ist dran';
    }

    if(checkWin()){
      stateString = 'Spieler ${3-currentPlayer} hat gewonnen';
      Future.delayed(Duration(seconds: 5), (){
        resetGame();
        log("Nach dem Aufruf von DameGame()");
      });
    }



    return true;
  }
    // Simulate flag makes it possible to test results of moves without actually performing them
  GamePiece? checkAndRemoveOppBeaten(int startX, int startY, int endX, endY, bool simulate){

    GamePiece? beatenPiece;

    // Only no fields were jumped, so nobody could be beaten
    if((startX - endX).abs() == 1){
      return null;
    }

    List<List<int>> jumpedFields = getJumpedFields(startX, startY, endX, endY);

    jumpedFields.forEach((element) {
      if(board[element[1]][element[0]]?.playerId != currentPlayer){
        beatenPiece = board[element[1]][element[0]];
        if(!simulate){
          board[element[1]][element[0]] = null;
        }

      }
    });
    return beatenPiece;
  }

  List<List<int>> getJumpedFields(int startX, int startY, int endX, endY){
    List<List<int>> visitedFields = [];

    int deltaX = endX > startX ? 1 : -1; // Bestimmt die Richtung auf der X-Achse
    int deltaY = endY > startY ? 1 : -1; // Bestimmt die Richtung auf der Y-Achse

    int x = startX;
    int y = startY;

    // Bewegt sich, bis der Endpunkt erreicht ist
    while (x != endX && y != endY) {
      x += deltaX;
      y += deltaY;
      visitedFields.add([x, y]);
    }
    if(visitedFields.isNotEmpty){
      visitedFields.removeAt(visitedFields.length - 1);
    }

    return visitedFields;
  }

  bool isValidMove(int startX, int startY, int endX, int endY) {
    // Fügen Sie hier Ihre Logik hinzu, um zu prüfen, ob ein Zug gültig ist
    // Berücksichtigen Sie die Richtung der Bewegung, ob das Zielfeld frei ist,
    // und ob ein Gegner übersprungen wird.

    bool jumpedOwnPiecesOrAir = false;
    List<List<int>> jumpedFields = getJumpedFields(startX, startY, endX, endY);
    print('CALLED ISVALIDMOVE');

    // Checks if landing piece is free
    if(board[endY][endX] != null){
      print('FIELD NOT EMPTY ${endY} ${endX}');
      stateString = 'Der Zielort muss ein freies Feld sein';
      return false;
    }

    // Jump straight in X or Y direction
    if(startX == endX || startY == endY){
      stateString = 'Es sind nur diagonale Züge erlaubt';
      return false;
    }

    // Jump not the same distance in X and Y
    if((startX - endX).abs() != (startY - endY).abs()){
      stateString = 'Es sind nur diagonale Züge erlaubt';
      return false;
    }

    jumpedFields.forEach((element) {
      if (board[element[1]][element[0]]?.playerId == currentPlayer) {
        jumpedOwnPiecesOrAir = true;
      }
    });
    // Need that for own pieces because Flutter FTW
    // Not jumping over a empty tile or a own piece
    if(jumpedOwnPiecesOrAir){
      stateString = 'Man darf nur über Steine des Gegners springen Test';
      return false;
    }

    // FOR NON QUEENS
    if((board[startY][startX] != null && (!board[startY][startX]!.isQueen))){
      //If you try to move backwards
      if(((endY < startY) && currentPlayer == 1) || ((endY > startY) && currentPlayer == 2)){
        stateString = 'Rückwärts laufen ist nur mit Damen erlaubt';
        return false;
      }

      // If the piece is not a queen it can not jump more than two
      if(board[startY][startX] != null && (!board[startY][startX]!.isQueen) && (startX - endX).abs() > 2){
        stateString = 'Normale Steine können maximal zwei Felder springen';
        return false;
      }

      jumpedFields.forEach((element) {
        if(board[element[1]][element[0]] == null){
          jumpedOwnPiecesOrAir = true;
        }
      });
      // Need that for own pieces because Flutter FTW
      // Not jumping over a empty tile or a own piece
      if(jumpedOwnPiecesOrAir){
        stateString = 'Man darf nur über Steine des Gegners springen';
        return false;
      }
    // FOR QUEENS
    } else if((board[startY][startX] != null && (board[startY][startX]!.isQueen))){
      // Queen must be surrounded by enemy piece

      int counterOfOpponentPieces = 0;
      bool foundOwnPiece = false;

      for (var element in jumpedFields) {
        if(board[element[1]][element[0]]?.playerId == (3 - currentPlayer)){
          counterOfOpponentPieces++;
        }
        if(board[element[1]][element[0]]?.playerId == currentPlayer){
          foundOwnPiece = true;
        }
      }
      if(counterOfOpponentPieces > 1){
        stateString = 'Man darf mit einer Dame nur über einen Gegnerstein springen';
        return false;
      }
      if(foundOwnPiece){
        stateString = 'Man darf mit einer Dame keine eigenen Steine überspringen';
        return false;
      }



      if((endY - 1 >= 0 && endX - 1 >= 0 && board[endY - 1][endX - 1]?.playerId != (3 - currentPlayer)) &&
          (endY - 1 >= 0 && endX + 1 < 10 && board[endY - 1][endX + 1]?.playerId != (3 - currentPlayer)) &&
          (endY + 1 < 10 && endX - 1 >= 0 && board[endY + 1][endX - 1]?.playerId != (3 - currentPlayer)) &&
          (endY + 1 < 10 && endX + 1 < 10 && board[endY + 1][endX + 1]?.playerId != (3 - currentPlayer)) &&
          checkAndRemoveOppBeaten(startX, startY, endX, endY, true) != null){
        stateString = 'Die Dame muss direkt um einen Gegner herum landen';
        return false;
      }
    }
    // IF ELIMINATION HAPPENS NO NEED TO CHECK IF MOVE IS VALID
    if(checkAndRemoveOppBeaten(startX, startY, endX, endY, true) != null){
      return true;
    }

    return true; // Ändern Sie dies, um die tatsächliche Prüfung widerzuspiegeln
  }

  bool checkWin() {

    bool foundWhite = false;
    bool foundBlack = false;

    for (var element in board) {
      for (var cell in element) {
        if(cell?.playerId == 1){
          foundWhite = true;
        }

        if(cell?.playerId == 2){
          foundBlack = true;
        }
      }
    }
    log('FOUND BLACK $foundBlack');
    log('FOUND WHITE $foundWhite');
    if(!(foundBlack && foundWhite)){
      log('GAME OVER, FUCK IT SOMEBODY WON');
    }

    return !(foundBlack && foundWhite); // Ändern Sie dies, um die tatsächliche Prüfung widerzuspiegeln
  }

  bool checkForQueenConv(){
    for(int i = 0; i < 10; i++){
      if(board[0][i]?.playerId == 2){
        if(board[0][i] != null && !(board[0][i]!.isQueen)) {
          stateString = 'Spieler 2 hat eine neue Dame';
          board[0][i]?.promoteToQueen();
          return true;
        }
      }

      if(board[9][i]?.playerId == 1){
        if(board[9][i] != null && !(board[9][i]!.isQueen)){
          stateString = 'Spieler 1 hat eine neue Dame';
          board[9][i]?.promoteToQueen();
          return true;
        }
      }
    }
    return false;
  }

  Move findMovesWhichBeat(){

    var returnPiece = new Move(null, -1, -1, -1, -1);

    // Check if any elimination is possible
    for (var elementRow in board) {
      for (var elementItem in elementRow) {
        if(elementItem != null && elementItem.playerId == currentPlayer){
          if(!elementItem.isQueen){
            // Test lower right
            if(board.indexOf(elementRow) + 2 < 10 &&
                elementRow.indexOf(elementItem) + 2 < 10) {
              // CONTINUE WITH CHECK IF MOVE IS VALID
              if (isValidMove(elementRow.indexOf(elementItem),
                  board.indexOf(elementRow),
                  elementRow.indexOf(elementItem) + 2,
                  board.indexOf(elementRow) + 2)) {

                var tempPiece = checkAndRemoveOppBeaten(elementRow.indexOf(elementItem), board.indexOf(elementRow),
                    elementRow.indexOf(elementItem) + 2, board.indexOf(elementRow) + 2, true);

                var returnedPiece = checkToChangeReturningPiece(returnPiece, tempPiece);
                if(returnedPiece != null && returnedPiece.isQueen){
                  return new Move(returnedPiece, elementRow.indexOf(elementItem) + 2, board.indexOf(elementRow) + 2,
                      elementRow.indexOf(elementItem), board.indexOf(elementRow));
                } else if(returnedPiece != null){
                  returnPiece = new Move(returnedPiece, elementRow.indexOf(elementItem) + 2, board.indexOf(elementRow) + 2,
                      elementRow.indexOf(elementItem), board.indexOf(elementRow));
                }
              }
            }
            if((board.indexOf(elementRow) + 2) < 10 &&
                0 <= elementRow.indexOf(elementItem) - 2) {
              if(isValidMove( elementRow.indexOf(elementItem),
                  board.indexOf(elementRow),
                  elementRow.indexOf(elementItem) - 2,
                  board.indexOf(elementRow) + 2)){

                var tempPiece = checkAndRemoveOppBeaten(elementRow.indexOf(elementItem), board.indexOf(elementRow),
                    elementRow.indexOf(elementItem) - 2, board.indexOf(elementRow) + 2, true);

                var returnedPiece = checkToChangeReturningPiece(returnPiece, tempPiece);
                if(returnedPiece != null && returnedPiece.isQueen){
                  return new Move(returnedPiece, elementRow.indexOf(elementItem) - 2, board.indexOf(elementRow) + 2,
                      elementRow.indexOf(elementItem), board.indexOf(elementRow));
                } else if(returnedPiece != null){
                  returnPiece = new Move(returnedPiece, elementRow.indexOf(elementItem) - 2, board.indexOf(elementRow) + 2,
                      elementRow.indexOf(elementItem), board.indexOf(elementRow));
                }
              }
            }
            if(0 <= board.indexOf(elementRow) - 2 &&
                0 <= elementRow.indexOf(elementItem) - 2) {
              if(isValidMove(elementRow.indexOf(elementItem),
                  board.indexOf(elementRow),
                  elementRow.indexOf(elementItem) - 2,
                  board.indexOf(elementRow) - 2)){
                var tempPiece = checkAndRemoveOppBeaten(elementRow.indexOf(elementItem), board.indexOf(elementRow),
                    elementRow.indexOf(elementItem) - 2, board.indexOf(elementRow) - 2, true);

                var returnedPiece = checkToChangeReturningPiece(returnPiece, tempPiece);
                if(returnedPiece != null && returnedPiece.isQueen){
                  return new Move(returnedPiece, elementRow.indexOf(elementItem) - 2, board.indexOf(elementRow) - 2,
                      elementRow.indexOf(elementItem), board.indexOf(elementRow));
                } else if(returnedPiece != null){
                  returnPiece = new Move(returnedPiece, elementRow.indexOf(elementItem) - 2, board.indexOf(elementRow) - 2,
                      elementRow.indexOf(elementItem), board.indexOf(elementRow));
                }
              }
            }
            if(0 <= board.indexOf(elementRow) - 2 &&
                elementRow.indexOf(elementItem) + 2 < 10){
              if(isValidMove(elementRow.indexOf(elementItem),
                  board.indexOf(elementRow),
                  elementRow.indexOf(elementItem) + 2,
                  board.indexOf(elementRow) - 2)){

                var tempPiece = checkAndRemoveOppBeaten(elementRow.indexOf(elementItem), board.indexOf(elementRow),
                    elementRow.indexOf(elementItem) + 2, board.indexOf(elementRow) - 2, true);

                var returnedPiece = checkToChangeReturningPiece(returnPiece, tempPiece);
                if(returnedPiece != null && returnedPiece.isQueen){
                  return new Move(returnedPiece, elementRow.indexOf(elementItem) + 2, board.indexOf(elementRow) - 2,
                      elementRow.indexOf(elementItem), board.indexOf(elementRow));
                } else if(returnedPiece != null){
                  returnPiece = new Move(returnedPiece, elementRow.indexOf(elementItem) + 2, board.indexOf(elementRow) - 2,
                      elementRow.indexOf(elementItem), board.indexOf(elementRow));
                }
              }
            }

          } else {
            for(var i = 2; i < 10; i++){
              if((board.indexOf(elementRow) + i) < 10 && (elementRow.indexOf(elementItem) + i) < 10){
                if (isValidMove(elementRow.indexOf(elementItem), board.indexOf(elementRow), elementRow.indexOf(elementItem) + i, board.indexOf(elementRow) + i)) {
                  var tempPiece = checkAndRemoveOppBeaten(elementRow.indexOf(elementItem), board.indexOf(elementRow),
                      elementRow.indexOf(elementItem) + i, board.indexOf(elementRow) + i, true);

                  var returnedPiece = checkToChangeReturningPiece(returnPiece, tempPiece);
                  if(returnedPiece != null && returnedPiece.isQueen){
                    return new Move(returnedPiece, elementRow.indexOf(elementItem) + i, board.indexOf(elementRow) + i,
                        elementRow.indexOf(elementItem), board.indexOf(elementRow));
                  } else if(returnedPiece != null){
                    returnPiece = new Move(returnedPiece, elementRow.indexOf(elementItem) + i, board.indexOf(elementRow) + i,
                        elementRow.indexOf(elementItem), board.indexOf(elementRow));
                  }
                }
              }

              if((board.indexOf(elementRow) + i) < 10 && (elementRow.indexOf(elementItem) - i) >= 0){
                if (isValidMove(elementRow.indexOf(elementItem), board.indexOf(elementRow), elementRow.indexOf(elementItem) - i, board.indexOf(elementRow) + i)) {
                  var tempPiece = checkAndRemoveOppBeaten(elementRow.indexOf(elementItem), board.indexOf(elementRow),
                      elementRow.indexOf(elementItem) - i, board.indexOf(elementRow) + i, true);

                  var returnedPiece = checkToChangeReturningPiece(returnPiece, tempPiece);
                  if(returnedPiece != null && returnedPiece.isQueen){
                    return new Move(returnedPiece, elementRow.indexOf(elementItem) - i, board.indexOf(elementRow) + i,
                        elementRow.indexOf(elementItem), board.indexOf(elementRow));
                  } else if(returnedPiece != null){
                    returnPiece = new Move(returnedPiece, elementRow.indexOf(elementItem) - i, board.indexOf(elementRow) + i,
                        elementRow.indexOf(elementItem), board.indexOf(elementRow));
                  }
                }
              }

              if((board.indexOf(elementRow) - i) >= 0 && (elementRow.indexOf(elementItem) + i) < 10){
                if (isValidMove(elementRow.indexOf(elementItem), board.indexOf(elementRow), elementRow.indexOf(elementItem) + i, board.indexOf(elementRow) - i)) {
                  var tempPiece = checkAndRemoveOppBeaten(elementRow.indexOf(elementItem), board.indexOf(elementRow),
                      elementRow.indexOf(elementItem) + i, board.indexOf(elementRow) - i, true);

                  var returnedPiece = checkToChangeReturningPiece(returnPiece, tempPiece);
                  if(returnedPiece != null && returnedPiece.isQueen){
                    return new Move(returnedPiece, elementRow.indexOf(elementItem) + i, board.indexOf(elementRow) - i,
                        elementRow.indexOf(elementItem), board.indexOf(elementRow));
                  } else if(returnedPiece != null){
                    returnPiece = new Move(returnedPiece, elementRow.indexOf(elementItem) + i, board.indexOf(elementRow) - i,
                        elementRow.indexOf(elementItem), board.indexOf(elementRow));
                  }
                }
              }

              if((board.indexOf(elementRow) - i) >= 0 && (elementRow.indexOf(elementItem) - i) >= 0){
                if (isValidMove(elementRow.indexOf(elementItem), board.indexOf(elementRow), elementRow.indexOf(elementItem) - i, board.indexOf(elementRow) - i)) {
                  var tempPiece = checkAndRemoveOppBeaten(elementRow.indexOf(elementItem), board.indexOf(elementRow),
                      elementRow.indexOf(elementItem) - i, board.indexOf(elementRow) - i, true);

                  var returnedPiece = checkToChangeReturningPiece(returnPiece, tempPiece);
                  if(returnedPiece != null && returnedPiece.isQueen){
                    return new Move(returnedPiece, elementRow.indexOf(elementItem) - i, board.indexOf(elementRow) - i,
                        elementRow.indexOf(elementItem), board.indexOf(elementRow));
                  } else if(returnedPiece != null){
                    returnPiece = new Move(returnedPiece, elementRow.indexOf(elementItem) - i, board.indexOf(elementRow) - i,
                        elementRow.indexOf(elementItem), board.indexOf(elementRow));
                  }
                }
              }
            }
          }
        }
      }
    }
    return returnPiece;
  }

  void resetGame(){
    board = List.generate(10, (_) => List.generate(10, (_) => null));

    currentPlayer = 1;

    // Setzen Sie die Startpositionen der Spielsteine
    for (int i = 0; i < 4; i++) {
      for (int j = (i % 2); j < 9; j += 2) {
        board[i][j + 1] = GamePiece(playerId: 1);
        board[9 - i][j] = GamePiece(playerId: 2);
      }
    }

    board[1][0] = GamePiece(playerId: 1);
    board[3][0] = GamePiece(playerId: 1);
    board[6][9] = GamePiece(playerId: 2);
    board[8][9] = GamePiece(playerId: 2);
    stateString = 'Spieler 1 ist an der Reihe';

    // Benachrichtigen aller Listener
    for (var listener in _listeners) {
      listener();
    }
  }

  GamePiece? checkToChangeReturningPiece(returnPiece, tempPiece){
    if (returnPiece.getPiece() == null) {
      return tempPiece;
    } else if(!returnPiece.getPiece().isQueen && tempPiece != null){
      return tempPiece;
    } else if(tempPiece != null && tempPiece.isQueen){
      return tempPiece;
    }
  }

  List<int> simulateComputerMove(){
    // Find moves which beat mit jedem Stein

        // finds 'ideal' piece to move, returns null if no piece beats
        var optimalMove = findMovesWhichBeat();
        // Makes ideal move if possible
        if(optimalMove.getPiece() != null){
          print('FOUND OPTIMAL MOVE');
          move(optimalMove.getStartX(), optimalMove.getStartY(), optimalMove.getEndX(), optimalMove.getEndY());
          return [optimalMove.getStartX(), optimalMove.getStartY(), optimalMove.getEndX(), optimalMove.getEndY()];
        } else {
          print('FOUND NO OPTIMAL MOVE');
        }

    // Create crowned piece if possible
        for(var i = 0; i <= 9; i++){
          if(board[1][i] != null && board[1][i]!.playerId == 2 && i-1 >= 0 && board[0][i-1] == null && !board[1][i]!.isQueen){
            print('FOUND PIECE TO CROWN TO LEFT');
            move(i, 1, i-1, 0);
            return [i, 1, i-1, 0];
          } else if(board[1][i] != null && board[1][i]!.playerId == 2 && i+1 <= 9 && board[0][i+1] == null && !board[1][i]!.isQueen){
            print('FOUND PIECE TO CROWN TO RIGHT');
            move(i, 1, i+1, 0);
            return [i, 1, i+1, 0];
          } else {
            print('FOUND NO PIECE TO CROWN');
          }
        }

        // Makes random move which is not made from baseline
        // Make move away from potential danger
        for(var i = 0; i <= 8; i++){
          for(var j = 0; j <= 9; j++){
            if(board[i][j] != null && board[i][j]!.playerId == 2 && !board[i][j]!.isQueen){
              if(isValidMove(j, i, j+1, i-1) && !surroundedByDanger(i-1, j+1, i, j)){
                print('RANDOM MOVE BUT WITH NO DANGER');
                move(j, i, j+1, i-1);
                return [j, i, j+1, i-1];
              } else if(isValidMove(j, i, j+1, i-1) && !surroundedByDanger(i-1, j+1, i, j)){
                print('RANDOM MOVE BUT WITH NO DANGER');
                move(j, i, j-1, i-1);
                return [j, i, j-1, i-1];
              }
            }
          }
        }

        // Makes random move which is not made from baseline
        for(var i = 0; i <= 8; i++){
          for(var j = 0; j <= 9; j++){
            if(board[i][j] != null && this.board[i][j]!.playerId == 2 && !board[i][j]!.isQueen){
              if(i-1 >= 0 && j+1 <= 9 && board[i-1][j+1] == null){
                print('RANDOM MOVE BUT WITH POT DANGER');
                move(j, i, j+1, i-1);
                return [j, i, j+1, i-1];
              } else if(i-1 >= 0 && j-1 >= 0 && board[i-1][j-1] != null){
                print('RANDOM MOVE BUT WITH POT DANGER');
                move(j, i, j-1, i-1);
                return [j, i, j-1, i-1];
              }
            }
          }
        }

        // Makes random move with dame
        for(var i = 0; i <= 8; i++){
          for(var j = 0; j <= 9; j++){
            if(board[i][j] != null && board[i][j]!.playerId == 2 && board[i][j]!.isQueen){
            log('FOUND PC STONE AT: ${i} ${j}');
            for(var k = 1; k <= 9; k++){

              log('SURROUNDED BY DANGER!!!!!?????????? - +');
              if(isValidMove(j, i, j+k, i-k) && !surroundedByDanger(i-k, j+k, i, j)){
                log('TOP RIGHT LETS GO ${i} ${j} ${i-k} ${j+k } THIS IS CURRENT K ${k}');
                move(j, i, j-k, i+k);
                log('MOVE DUN DUN');
                return [j, i, j-k, i+k];
              }

              log('SURROUNDED BY DANGER!!!!!?????????? - -');
              if(isValidMove(j, i, j-k, i-k) && !surroundedByDanger(i-k, j-k, i, j)){
                move(j, i, j-k, i-k);
                return [j, i, j-k, i-k];
              }

              log('SURROUNDED BY DANGER!!!!!?????????? + -');
              if(isValidMove(j, i, j-k, i+k) && !surroundedByDanger(i+k, j-k, i, j)){
                move(j, i, j-k, i+k);
                return [j, i, j-k, i+k];
              }

              log('SURROUNDED BY DANGER!!!!!?????????? + +');
              if(isValidMove(j, i, j+k, i+k) && !surroundedByDanger(i+k, j+k, i, j)){
                move(j, i, j+k, i+k);
                return [j, i, j+k, i+k];
              }

            }
          }
        }
      }

      // Makes random move with dame
      for(var i = 0; i <= 8; i++){
        for(var j = 0; j <= 9; j++){
        if(board[i][j] != null && board[i][j]!.playerId == 2 && this.board[i][j]!.isQueen){
          for(var k = 1; i+k <= 9 || i-k >= 0 || j+k <= 9 || j-k >= 0; k++){
            if(i-k >= 0 && j+k <= 9 && board[i-k][j+k] == null){
              move(j, i, j+k, i-k);
              return [j, i, j+k, i-k];
            } else if(i-k >= 0 && j-k >= 0 && board[i-k][j-k] == null){
              move(j, i, j-k, i-k);
              return [j, i, j-k, i-k];
            } else if(i+k <= 9 && j-k >= 0 && board[i+k][j-k] == null){
              move(j, i, j-k, i+k);
              return [j, i, j-k, i+k];
            } else if(i+k <= 9 && j+k <= 9 && board[i+k][j+k] == null){
              move(j, i, j+k, i+k);
              return [j, i, j+k, i+k];
              }
            }
          }
      }
    }

    // Make move from baseline
    var startY = 9;
    for(var i = 0; i <= 9; i++){
      if(board[9][i] != null && this.board[9][i]!.playerId == 2){
        if(i+1 <= 9 && board[8][i+1] == null){
          move(i, 9, i+1, 8);
          return [i, 9, i+1, 8];
        } else if(i+1 >= 0 && board[8][i-1] == null){
          move(i, 9, i-1, 8);
          return [i, 9, i-1, 8];
        }
      }
    }
    return [-1, -1, -1, -1];
    // Make random queen move

// Make the move
// Change the player, whcih actually already when executing move i guess

// Weitere Methoden wie Überprüfung auf gültige Züge, Überprüfung der Gewinnbedingungen usw.
}

  bool surroundedByDanger(int rowIndex, int columnIndex, int startRow, int startColumn) {
    log("$rowIndex, $columnIndex, 'ALARM'");


    if (columnIndex + 1 <= 9 &&
        rowIndex - 1 >= 0 &&
        board[rowIndex - 1][columnIndex + 1] != null &&
        board[rowIndex - 1][columnIndex + 1]!.playerId == (3 - currentPlayer) &&
        !board[rowIndex - 1][columnIndex + 1]!.isQueen &&
        columnIndex - 1 >= 0 &&
        rowIndex + 1 <= 9 &&
        (board[rowIndex + 1][columnIndex - 1] == null || (rowIndex + 1 == startRow && columnIndex - 1 == startColumn))) {
      log('WE HERE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
      return true;
    } else if (columnIndex - 1 >= 0 &&
        rowIndex - 1 >= 0 &&
        board[rowIndex - 1][columnIndex - 1] != null &&
        board[rowIndex - 1][columnIndex - 1]!.playerId == (3 - currentPlayer) &&
        !board[rowIndex - 1][columnIndex - 1]!.isQueen &&
        columnIndex + 1 <= 9 &&
        rowIndex + 1 <= 9 &&
        (board[rowIndex + 1][columnIndex + 1] == null || (rowIndex + 1 == startRow && columnIndex + 1 == startColumn))) {
      log('WE HERE');
      return true;
    }

    bool pieceFoundUpLeft = false;
    bool pieceFoundUpRight = false;
    bool pieceFoundDownLeft = false;
    bool pieceFoundDownRight = false;
    int maxIndex = columnIndex > rowIndex ? columnIndex : rowIndex;

    for (var k = 1; k + maxIndex <= 9; k++) {
      log("$k, 'BIG OL K', $maxIndex");
      if (0 <= (rowIndex + k) && (rowIndex + k) <= 9 &&
          columnIndex + k <= 9 && columnIndex + k >= 0 &&
          rowIndex + k != startRow && columnIndex + k != startColumn &&
          board[rowIndex + k][columnIndex + k] != null &&
          board[rowIndex + k][columnIndex + k]!.playerId == (3 - currentPlayer) &&
          board[rowIndex + k][columnIndex + k]!.isQueen &&
          !pieceFoundDownRight) {
        log('Found queen which could beat at ${rowIndex + k}, ${columnIndex + k}');
        return true;
      } else if (0 <= (rowIndex + k) && (rowIndex + k) <= 9 &&
          columnIndex + k <= 9 && columnIndex + k >= 0 &&
          rowIndex + k != startRow && columnIndex + k != startColumn &&
          board[rowIndex + k][columnIndex + k] != null) {
        pieceFoundDownRight = true;
        log('Found piece at ${rowIndex + k}, ${columnIndex + k}');
      } else {
        log('NO DANGER FOUND AT ${rowIndex + k}, ${columnIndex + k}');
      }
      if (0 <= (rowIndex - k) && (rowIndex - k) <= 9 &&
          columnIndex + k <= 9 && columnIndex + k >= 0 &&
          rowIndex - k != startRow && columnIndex + k != startColumn &&
          board[rowIndex - k][columnIndex + k] != null &&
          board[rowIndex - k][columnIndex + k]!.playerId == (3 - currentPlayer) &&
          board[rowIndex - k][columnIndex + k]!.isQueen &&
          !pieceFoundUpRight) {
        log('Found queen which could beat at ${rowIndex - k}, ${columnIndex + k}');
        return true;
      } else if (0 <= (rowIndex - k) && (rowIndex - k) <= 9 &&
          columnIndex + k <= 9 && columnIndex + k >= 0 &&
          rowIndex - k != startRow && columnIndex + k != startColumn &&
          board[rowIndex - k][columnIndex + k] != null) {
        pieceFoundUpRight = true;
        log('Found piece at ${rowIndex - k}, ${columnIndex + k}');
      } else {
        log('NO DANGER FOUND AT ${rowIndex - k}, ${columnIndex + k}');
      }
      if (0 <= (rowIndex + k) && (rowIndex + k) <= 9 &&
          columnIndex - k <= 9 && columnIndex - k >= 0 &&
          rowIndex + k != startRow && columnIndex - k != startColumn &&
          board[rowIndex + k][columnIndex - k] != null &&
          board[rowIndex + k][columnIndex - k]!.playerId == (3 - currentPlayer) &&
          board[rowIndex + k][columnIndex - k]!.isQueen &&
          !pieceFoundDownLeft) {
        log('Found queen which could beat at ${rowIndex + k}, ${columnIndex - k}');
        return true;
      } else if (0 <= (rowIndex + k) && (rowIndex + k) <= 9 &&
          columnIndex - k <= 9 && columnIndex - k >= 0 &&
          rowIndex + k != startRow && columnIndex - k != startColumn &&
          board[rowIndex + k][columnIndex - k] != null) {
        pieceFoundDownLeft = true;
        log('Found piece at ${rowIndex + k}, ${columnIndex - k}');
      } else {
        log('NO DANGER FOUND AT ${rowIndex + k}, ${columnIndex - k}');
      }
      if (0 <= (rowIndex - k) && (rowIndex - k) <= 9 &&
          columnIndex - k <= 9 && columnIndex - k >= 0 &&
          rowIndex - k != startRow && columnIndex - k != startColumn &&
          board[rowIndex - k][columnIndex - k] != null &&
          board[rowIndex - k][columnIndex - k]!.playerId == (3 - currentPlayer) &&
          board[rowIndex - k][columnIndex - k]!.isQueen &&
          !pieceFoundUpLeft) {
        log('Found queen which could beat at ${rowIndex - k}, ${columnIndex - k}');
        return true;
      } else if (0 <= (rowIndex - k) && (rowIndex - k) <= 9 &&
          columnIndex - k <= 9 && columnIndex - k >= 0 &&
          rowIndex - k != startRow && columnIndex - k != startColumn &&
          board[rowIndex - k][columnIndex - k] != null) {
        pieceFoundUpLeft = true;
        log('Found piece at ${rowIndex - k}, ${columnIndex - k}');
      } else {
        log('NO DANGER FOUND AT ${rowIndex - k}, ${columnIndex - k}');
      }
      // Additional checks similar to above for other directions
      // ...

    }

    log('OUT OF FOR');
    return false;
  }


}

class Move {
  GamePiece? piece;
  int endX;
  int endY;
  int startX;
  int startY;

  Move(this.piece, this.endX, this.endY, this.startX, this.startY);

  GamePiece? getPiece() {
    return piece;
  }

  int getEndX() {
    return endX;
  }

  int getEndY() {
    return endY;
  }

  int getStartX() {
    return startX;
  }

  int getStartY() {
    return startY;
  }
}
