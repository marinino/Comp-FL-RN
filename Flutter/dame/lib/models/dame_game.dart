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

    if(checkBeatenPiece == null && foundOptimum != null){
      stateString = 'Spieler ${currentPlayer} hat die Schlagpflicht verletzt, wähle einen anderen Zug';
      return false;
    }
    if(foundOptimum != null && foundOptimum.isQueen && checkBeatenPiece != null
      && !checkBeatenPiece.isQueen){
      stateString = 'Dame schlagen geht vor';
          return false;
    }

    // Führen Sie den Zug aus
    board[endY][endX] = board[startY][startX];
    board[startY][startX] = null;

    // Prüfen Sie, ob ein Gegner übersprungen wurde, und entfernen Sie ihn
    //int midX = (startX + endX) ~/ 2;
    //int midY = (startY + endY) ~/ 2;
    //if (board[midX][midY] != null) {
    //  log('Puff');
    //}
    GamePiece? beatenPiece = checkAndRemoveOppBeaten(startX, startY, endX, endY, false);

    log(board.toString());
    bool newQueen = checkForQueenConv();



    // Changes player, if futher beat is not possible or there was no beat in the first place
    if(beatenPiece != null && findMovesWhichBeat() != null && newQueen == false){
      stateString = 'Spieler $currentPlayer bleibt dran';
    } else {
      currentPlayer = 3 - currentPlayer;
      stateString = 'Spieler $currentPlayer ist dran';
    }

    if(checkWin()){
      stateString = 'Spieler ${3-currentPlayer} hat gewonnen';
      Future.delayed(Duration(seconds: 5), (){
        resetGame();
        print("Nach dem Aufruf von DameGame()");
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

    // Checks if landing piece is free
    if(board[endY][endX] != null){
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

  GamePiece? findMovesWhichBeat(){

    var returnPiece;

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
                  return returnedPiece;
                } else if(returnedPiece != null){
                  returnPiece = returnedPiece;
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
                  return returnedPiece;
                } else if(returnedPiece != null){
                  returnPiece = returnedPiece;
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
                  return returnedPiece;
                } else if(returnedPiece != null){
                  returnPiece = returnedPiece;
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
                  return returnedPiece;
                } else if(returnedPiece != null){
                  returnPiece = returnedPiece;
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
                    return returnedPiece;
                  } else if(returnedPiece != null){
                    returnPiece = returnedPiece;
                  }
                }
              }

              if((board.indexOf(elementRow) + i) < 10 && (elementRow.indexOf(elementItem) - i) >= 0){
                if (isValidMove(elementRow.indexOf(elementItem), board.indexOf(elementRow), elementRow.indexOf(elementItem) - i, board.indexOf(elementRow) + i)) {
                  var tempPiece = checkAndRemoveOppBeaten(elementRow.indexOf(elementItem), board.indexOf(elementRow),
                      elementRow.indexOf(elementItem) - i, board.indexOf(elementRow) + i, true);

                  var returnedPiece = checkToChangeReturningPiece(returnPiece, tempPiece);
                  if(returnedPiece != null && returnedPiece.isQueen){
                    return returnedPiece;
                  } else if(returnedPiece != null){
                    returnPiece = returnedPiece;
                  }
                }
              }

              if((board.indexOf(elementRow) - i) >= 0 && (elementRow.indexOf(elementItem) + i) < 10){
                if (isValidMove(elementRow.indexOf(elementItem), board.indexOf(elementRow), elementRow.indexOf(elementItem) + i, board.indexOf(elementRow) - i)) {
                  var tempPiece = checkAndRemoveOppBeaten(elementRow.indexOf(elementItem), board.indexOf(elementRow),
                      elementRow.indexOf(elementItem) + i, board.indexOf(elementRow) - i, true);

                  var returnedPiece = checkToChangeReturningPiece(returnPiece, tempPiece);
                  if(returnedPiece != null && returnedPiece.isQueen){
                    return returnedPiece;
                  } else if(returnedPiece != null){
                    returnPiece = returnedPiece;
                  }
                }
              }

              if((board.indexOf(elementRow) - i) >= 0 && (elementRow.indexOf(elementItem) - i) >= 0){
                if (isValidMove(elementRow.indexOf(elementItem), board.indexOf(elementRow), elementRow.indexOf(elementItem) - i, board.indexOf(elementRow) - i)) {
                  var tempPiece = checkAndRemoveOppBeaten(elementRow.indexOf(elementItem), board.indexOf(elementRow),
                      elementRow.indexOf(elementItem) - i, board.indexOf(elementRow) - i, true);

                  var returnedPiece = checkToChangeReturningPiece(returnPiece, tempPiece);
                  if(returnedPiece != null && returnedPiece.isQueen){
                    return returnedPiece;
                  } else if(returnedPiece != null){
                    returnPiece = returnedPiece;
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
    if (returnPiece == null) {
      return tempPiece;
    } else if(!returnPiece.isQueen && tempPiece != null){
      return tempPiece;
    } else if(tempPiece != null && tempPiece.isQueen){
      return tempPiece;
    }
  }


}