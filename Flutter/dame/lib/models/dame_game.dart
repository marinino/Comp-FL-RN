import 'dart:developer';
import 'dart:ui';
import 'game_piece.dart';
import 'dart:math';

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

  late List<
      List<GamePiece?>> board; // 0 = kein Stein, 1 = Spieler 1, 2 = Spieler 2
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

  Future<bool> move(int startX, int startY, int endX, int endY) async {
    print('Called move');
    // Prüfen Sie, ob der Zug gültig ist
    if (!await isValidMove(startX, startY, endX, endY, [], currentPlayer)) {
      return false;
    }

    var checkBeatenPiece = checkAndRemoveOppBeaten(
        startX, startY, endX, endY, true, board, currentPlayer);
    var foundOptimum = await findMovesWhichBeat([], currentPlayer);

    if (checkBeatenPiece == null && foundOptimum.getPiece() != null) {
      stateString =
      'Spieler ${currentPlayer} hat die Schlagpflicht verletzt, wähle einen anderen Zug';
      return false;
    }
    if (foundOptimum.getPiece() != null && foundOptimum.getPiece()!.isQueen &&
        checkBeatenPiece != null
        && !checkBeatenPiece.isQueen) {
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


    return true;
  }

  // Simulate flag makes it possible to test results of moves without actually performing them
  GamePiece? checkAndRemoveOppBeaten(int startX, int startY, int endX, endY,
      bool simulate, List<List<GamePiece?>> pBoard, int pPlayer) {
    GamePiece? beatenPiece;
    //print('REMOVED BEATEN PIECE');

    // Only no fields were jumped, so nobody could be beaten
    if ((startX - endX).abs() == 1) {
      return null;
    }

    List<List<int>> jumpedFields = getJumpedFields(startX, startY, endX, endY);

    jumpedFields.forEach((element) {
      if (pBoard[element[1]][element[0]]?.playerId != pPlayer) {
        beatenPiece = pBoard[element[1]][element[0]];
        if (!simulate) {
          pBoard[element[1]][element[0]] = null;
        }
      }
    });
    return beatenPiece;
  }

  List<List<int>> getJumpedFields(int startX, int startY, int endX, endY) {
    List<List<int>> visitedFields = [];

    int deltaX = endX > startX
        ? 1
        : -1; // Bestimmt die Richtung auf der X-Achse
    int deltaY = endY > startY
        ? 1
        : -1; // Bestimmt die Richtung auf der Y-Achse

    int x = startX;
    int y = startY;

    // Bewegt sich, bis der Endpunkt erreicht ist
    while (x != endX && y != endY) {
      x += deltaX;
      y += deltaY;
      visitedFields.add([x, y]);
    }
    if (visitedFields.isNotEmpty) {
      visitedFields.removeAt(visitedFields.length - 1);
    }

    return visitedFields;
  }

  Future<bool> isValidMove(int startX, int startY, int endX, int endY, List<Move> path, int pPlayer) async {
    // Fügen Sie hier Ihre Logik hinzu, um zu prüfen, ob ein Zug gültig ist
    // Berücksichtigen Sie die Richtung der Bewegung, ob das Zielfeld frei ist,
    // und ob ein Gegner übersprungen wird.

    List<List<GamePiece?>> newBoard = board.map((list) => List<GamePiece?>.from(list))
        .toList();

    //print(path.toString());

    for (var move = path.length - 1; move >= 0; move--) {
      newBoard = await applyMove(newBoard, path[move]);
    }
    //print(newBoard.toString());

    bool jumpedOwnPiecesOrAir = false;
    List<List<int>> jumpedFields = getJumpedFields(startX, startY, endX, endY);
    //print('CALLED ISVALIDMOVE' + endX.toString() + endY.toString() + startX.toString() + startY.toString());

    if(endX > 9 || endX < 0 || endY > 9 || endY < 0){
      //print('EndX out of range');
      //if(endY == 5 && endX == 2){
        print('Out of bounds');
      //}
      return false;
    }

    //print('Still going anyway');

    // Checks if landing piece is free
    if (newBoard[endY][endX] != null) {
      //print('FIELD NOT EMPTY ${endY} ${endX}');
      //if(endY == 5 && endX == 2){
        print('Zielort nicht frei');
      //}
      stateString = 'Der Zielort muss ein freies Feld sein';
      return false;
    }

    // Jump straight in X or Y direction
    if (startX == endX || startY == endY) {
      //if(endY == 5 && endX == 2){
        print('Nur diagonale Züge erlaubt, is gleich');
      //}
      stateString = 'Es sind nur diagonale Züge erlaubt';
      return false;
    }

    // Jump not the same distance in X and Y
    if ((startX - endX).abs() != (startY - endY).abs()) {
      //if(endY == 5 && endX == 2){
        print('Nur diagonale Züge erlaubt, nicht genau diagonal');
      //}
      stateString = 'Es sind nur diagonale Züge erlaubt';
      return false;
    }

    jumpedFields.forEach((element) {
      if (newBoard[element[1]][element[0]]?.playerId == pPlayer) {
        jumpedOwnPiecesOrAir = true;
      }
    });
    // Need that for own pieces because Flutter FTW
    // Not jumping over a empty tile or a own piece
    if (jumpedOwnPiecesOrAir) {
      //if(endY == 5 && endX == 2){
        print('Man darf nur über Steine des Gegners springen');
      //}
      stateString = 'Man darf nur über Steine des Gegners springen Test';
      return false;
    }

    // FOR NON QUEENS
    if ((newBoard[startY][startX] != null && (!newBoard[startY][startX]!.isQueen))) {
      //If you try to move backwards
      if (((endY < startY) && pPlayer == 1) ||
          ((endY > startY) && pPlayer == 2)) {
        //if(endY == 5 && endX == 2){
          print('Rückwärts laufen ist nur mit Damen erlaubt');
        //}
        stateString = 'Rückwärts laufen ist nur mit Damen erlaubt';
        return false;
      }

      // If the piece is not a queen it can not jump more than two
      if (newBoard[startY][startX] != null && (!newBoard[startY][startX]!.isQueen) &&
          (startX - endX).abs() > 2) {
        //if(endY == 5 && endX == 2){
          print('Nur max zwei Felder');
        //}
        stateString = 'Normale Steine können maximal zwei Felder springen';
        return false;
      }

      jumpedFields.forEach((element) {
        if (newBoard[element[1]][element[0]] == null) {
          jumpedOwnPiecesOrAir = true;
        }
      });
      // Need that for own pieces because Flutter FTW
      // Not jumping over a empty tile or a own piece
      if (jumpedOwnPiecesOrAir) {
        //if(endY == 5 && endX == 2){
          print('Man darf nur über Steine des Gegners springen');
        //}
        stateString = 'Man darf nur über Steine des Gegners springen';
        return false;
      }
      // FOR QUEENS
    } else
    if ((newBoard[startY][startX] != null && (newBoard[startY][startX]!.isQueen))) {
      // Queen must be surrounded by enemy piece

      int counterOfOpponentPieces = 0;
      bool foundOwnPiece = false;

      for (var element in jumpedFields) {
        if (newBoard[element[1]][element[0]]?.playerId == (3 - pPlayer)) {
          counterOfOpponentPieces++;
        }
        if (newBoard[element[1]][element[0]]?.playerId == pPlayer) {
          foundOwnPiece = true;
        }
      }
      if (counterOfOpponentPieces > 1) {
        stateString =
        'Man darf mit einer Dame nur über einen Gegnerstein springen';
        return false;
      }
      if (foundOwnPiece) {
        stateString =
        'Man darf mit einer Dame keine eigenen Steine überspringen';
        return false;
      }


      if ((endY - 1 >= 0 && endX - 1 >= 0 &&
          newBoard[endY - 1][endX - 1]?.playerId != (3 - pPlayer)) &&
          (endY - 1 >= 0 && endX + 1 < 10 &&
              newBoard[endY - 1][endX + 1]?.playerId != (3 - pPlayer)) &&
          (endY + 1 < 10 && endX - 1 >= 0 &&
              newBoard[endY + 1][endX - 1]?.playerId != (3 - pPlayer)) &&
          (endY + 1 < 10 && endX + 1 < 10 &&
              newBoard[endY + 1][endX + 1]?.playerId != (3 - pPlayer)) &&
          checkAndRemoveOppBeaten(startX, startY, endX, endY, true, newBoard, pPlayer) != null) {
        stateString = 'Die Dame muss direkt um einen Gegner herum landen';
        return false;
      }
    }
    // IF ELIMINATION HAPPENS NO NEED TO CHECK IF MOVE IS VALID
    if (checkAndRemoveOppBeaten(startX, startY, endX, endY, true, newBoard, pPlayer) != null) {
      return true;
    }

    return true; // Ändern Sie dies, um die tatsächliche Prüfung widerzuspiegeln
  }

  bool checkWin(List<List<GamePiece?>> pBoard) {
    bool foundWhite = false;
    bool foundBlack = false;

    for (var element in pBoard) {
      for (var cell in element) {
        if (cell?.playerId == 1) {
          foundWhite = true;
        }

        if (cell?.playerId == 2) {
          foundBlack = true;
        }
      }
    }
    print('FOUND BLACK $foundBlack');
    print('FOUND WHITE $foundWhite');
    if (!(foundBlack && foundWhite)) {
      print('GAME OVER, FUCK IT SOMEBODY WON');
    }

    return !(foundBlack &&
        foundWhite); // Ändern Sie dies, um die tatsächliche Prüfung widerzuspiegeln
  }

  bool checkForQueenConv() {
    for (int i = 0; i < 10; i++) {
      if (board[0][i]?.playerId == 2) {
        if (board[0][i] != null && !(board[0][i]!.isQueen)) {
          stateString = 'Spieler 2 hat eine neue Dame';
          board[0][i]?.promoteToQueen();
          return true;
        }
      }

      if (board[9][i]?.playerId == 1) {
        if (board[9][i] != null && !(board[9][i]!.isQueen)) {
          stateString = 'Spieler 1 hat eine neue Dame';
          board[9][i]?.promoteToQueen();
          return true;
        }
      }
    }
    return false;
  }

  Future<Move> findMovesWhichBeat(List<Move> path, int pPlayer) async {
    var returnPiece = new Move(null, -1, -1, -1, -1);

    List<List<GamePiece?>> newBoard = board.map((list) => List<GamePiece?>.from(list))
        .toList();

    for (var move = path.length - 1; move >= 0; move--) {
      newBoard = await applyMove(newBoard, path[move]);
    }

    // Check if any elimination is possible
    for (var elementRow in newBoard) {
      for (var elementItem in elementRow) {
        if (elementItem != null && elementItem.playerId == pPlayer) {
          if (!elementItem.isQueen) {
            // Test lower right
            if (newBoard.indexOf(elementRow) + 2 < 10 &&
                elementRow.indexOf(elementItem) + 2 < 10) {
              // CONTINUE WITH CHECK IF MOVE IS VALID
              if (await isValidMove(elementRow.indexOf(elementItem),
                  newBoard.indexOf(elementRow),
                  elementRow.indexOf(elementItem) + 2,
                  newBoard.indexOf(elementRow) + 2, path, pPlayer)) {
                var tempPiece = checkAndRemoveOppBeaten(
                    elementRow.indexOf(elementItem), newBoard.indexOf(elementRow),
                    elementRow.indexOf(elementItem) + 2,
                    newBoard.indexOf(elementRow) + 2, true, newBoard, pPlayer);

                var returnedPiece = checkToChangeReturningPiece(
                    returnPiece, tempPiece);
                if (returnedPiece != null && returnedPiece.isQueen) {
                  return Move(
                      returnedPiece, elementRow.indexOf(elementItem) + 2,
                      newBoard.indexOf(elementRow) + 2,
                      elementRow.indexOf(elementItem),
                      newBoard.indexOf(elementRow));
                } else if (returnedPiece != null) {
                  returnPiece = Move(
                      returnedPiece, elementRow.indexOf(elementItem) + 2,
                      newBoard.indexOf(elementRow) + 2,
                      elementRow.indexOf(elementItem),
                      newBoard.indexOf(elementRow));
                }
              }
            }
            if ((newBoard.indexOf(elementRow) + 2) < 10 &&
                0 <= elementRow.indexOf(elementItem) - 2) {
              if (await isValidMove(elementRow.indexOf(elementItem),
                  newBoard.indexOf(elementRow),
                  elementRow.indexOf(elementItem) - 2,
                  newBoard.indexOf(elementRow) + 2, path, pPlayer)) {
                var tempPiece = checkAndRemoveOppBeaten(
                    elementRow.indexOf(elementItem), newBoard.indexOf(elementRow),
                    elementRow.indexOf(elementItem) - 2,
                    newBoard.indexOf(elementRow) + 2, true, newBoard, pPlayer);

                var returnedPiece = checkToChangeReturningPiece(
                    returnPiece, tempPiece);
                if (returnedPiece != null && returnedPiece.isQueen) {
                  return Move(
                      returnedPiece, elementRow.indexOf(elementItem) - 2,
                      newBoard.indexOf(elementRow) + 2,
                      elementRow.indexOf(elementItem),
                      newBoard.indexOf(elementRow));
                } else if (returnedPiece != null) {
                  returnPiece = Move(
                      returnedPiece, elementRow.indexOf(elementItem) - 2,
                      newBoard.indexOf(elementRow) + 2,
                      elementRow.indexOf(elementItem),
                      newBoard.indexOf(elementRow));
                }
              }
            }
            if (0 <= newBoard.indexOf(elementRow) - 2 &&
                0 <= elementRow.indexOf(elementItem) - 2) {
              if (await isValidMove(elementRow.indexOf(elementItem),
                  newBoard.indexOf(elementRow),
                  elementRow.indexOf(elementItem) - 2,
                  newBoard.indexOf(elementRow) - 2, path, pPlayer)) {
                var tempPiece = checkAndRemoveOppBeaten(
                    elementRow.indexOf(elementItem), newBoard.indexOf(elementRow),
                    elementRow.indexOf(elementItem) - 2,
                    newBoard.indexOf(elementRow) - 2, true, newBoard, pPlayer);

                var returnedPiece = checkToChangeReturningPiece(
                    returnPiece, tempPiece);
                if (returnedPiece != null && returnedPiece.isQueen) {
                  return Move(
                      returnedPiece, elementRow.indexOf(elementItem) - 2,
                      newBoard.indexOf(elementRow) - 2,
                      elementRow.indexOf(elementItem),
                      newBoard.indexOf(elementRow));
                } else if (returnedPiece != null) {
                  returnPiece = Move(
                      returnedPiece, elementRow.indexOf(elementItem) - 2,
                      newBoard.indexOf(elementRow) - 2,
                      elementRow.indexOf(elementItem),
                      newBoard.indexOf(elementRow));
                }
              }
            }
            if (0 <= newBoard.indexOf(elementRow) - 2 &&
                elementRow.indexOf(elementItem) + 2 < 10) {
              if (await isValidMove(elementRow.indexOf(elementItem),
                  newBoard.indexOf(elementRow),
                  elementRow.indexOf(elementItem) + 2,
                  newBoard.indexOf(elementRow) - 2, path, pPlayer)) {
                var tempPiece = checkAndRemoveOppBeaten(
                    elementRow.indexOf(elementItem), newBoard.indexOf(elementRow),
                    elementRow.indexOf(elementItem) + 2,
                    newBoard.indexOf(elementRow) - 2, true, newBoard, pPlayer);

                var returnedPiece = checkToChangeReturningPiece(
                    returnPiece, tempPiece);
                if (returnedPiece != null && returnedPiece.isQueen) {
                  return Move(
                      returnedPiece, elementRow.indexOf(elementItem) + 2,
                      newBoard.indexOf(elementRow) - 2,
                      elementRow.indexOf(elementItem),
                      newBoard.indexOf(elementRow));
                } else if (returnedPiece != null) {
                  returnPiece = Move(
                      returnedPiece, elementRow.indexOf(elementItem) + 2,
                      newBoard.indexOf(elementRow) - 2,
                      elementRow.indexOf(elementItem),
                      newBoard.indexOf(elementRow));
                }
              }
            }
          } else {
            for (var i = 2; i < 10; i++) {
              if ((newBoard.indexOf(elementRow) + i) < 10 &&
                  (elementRow.indexOf(elementItem) + i) < 10) {
                if (await isValidMove(
                    elementRow.indexOf(elementItem), newBoard.indexOf(elementRow),
                    elementRow.indexOf(elementItem) + i,
                    newBoard.indexOf(elementRow) + i, path, pPlayer)) {
                  var tempPiece = checkAndRemoveOppBeaten(
                      elementRow.indexOf(elementItem),
                      newBoard.indexOf(elementRow),
                      elementRow.indexOf(elementItem) + i,
                      newBoard.indexOf(elementRow) + i, true, newBoard, pPlayer);

                  var returnedPiece = checkToChangeReturningPiece(
                      returnPiece, tempPiece);
                  if (returnedPiece != null && returnedPiece.isQueen) {
                    return Move(
                        returnedPiece, elementRow.indexOf(elementItem) + i,
                        newBoard.indexOf(elementRow) + i,
                        elementRow.indexOf(elementItem),
                        newBoard.indexOf(elementRow));
                  } else if (returnedPiece != null) {
                    returnPiece = Move(
                        returnedPiece, elementRow.indexOf(elementItem) + i,
                        newBoard.indexOf(elementRow) + i,
                        elementRow.indexOf(elementItem),
                        newBoard.indexOf(elementRow));
                  }
                }
              }

              if ((newBoard.indexOf(elementRow) + i) < 10 &&
                  (elementRow.indexOf(elementItem) - i) >= 0) {
                if (await isValidMove(
                    elementRow.indexOf(elementItem), newBoard.indexOf(elementRow),
                    elementRow.indexOf(elementItem) - i,
                    newBoard.indexOf(elementRow) + i, path, pPlayer)) {
                  var tempPiece = checkAndRemoveOppBeaten(
                      elementRow.indexOf(elementItem),
                      newBoard.indexOf(elementRow),
                      elementRow.indexOf(elementItem) - i,
                      newBoard.indexOf(elementRow) + i, true, newBoard, pPlayer);

                  var returnedPiece = checkToChangeReturningPiece(
                      returnPiece, tempPiece);
                  if (returnedPiece != null && returnedPiece.isQueen) {
                    return Move(
                        returnedPiece, elementRow.indexOf(elementItem) - i,
                        newBoard.indexOf(elementRow) + i,
                        elementRow.indexOf(elementItem),
                        newBoard.indexOf(elementRow));
                  } else if (returnedPiece != null) {
                    returnPiece = Move(
                        returnedPiece, elementRow.indexOf(elementItem) - i,
                        newBoard.indexOf(elementRow) + i,
                        elementRow.indexOf(elementItem),
                        newBoard.indexOf(elementRow));
                  }
                }
              }

              if ((newBoard.indexOf(elementRow) - i) >= 0 &&
                  (elementRow.indexOf(elementItem) + i) < 10) {
                if (await isValidMove(
                    elementRow.indexOf(elementItem), newBoard.indexOf(elementRow),
                    elementRow.indexOf(elementItem) + i,
                    newBoard.indexOf(elementRow) - i, path, pPlayer)) {
                  var tempPiece = checkAndRemoveOppBeaten(
                      elementRow.indexOf(elementItem),
                      newBoard.indexOf(elementRow),
                      elementRow.indexOf(elementItem) + i,
                      newBoard.indexOf(elementRow) - i, true, newBoard, pPlayer);

                  var returnedPiece = checkToChangeReturningPiece(
                      returnPiece, tempPiece);
                  if (returnedPiece != null && returnedPiece.isQueen) {
                    return Move(
                        returnedPiece, elementRow.indexOf(elementItem) + i,
                        newBoard.indexOf(elementRow) - i,
                        elementRow.indexOf(elementItem),
                        newBoard.indexOf(elementRow));
                  } else if (returnedPiece != null) {
                    returnPiece = Move(
                        returnedPiece, elementRow.indexOf(elementItem) + i,
                        newBoard.indexOf(elementRow) - i,
                        elementRow.indexOf(elementItem),
                        newBoard.indexOf(elementRow));
                  }
                }
              }

              if ((newBoard.indexOf(elementRow) - i) >= 0 &&
                  (elementRow.indexOf(elementItem) - i) >= 0) {
                if (await isValidMove(
                    elementRow.indexOf(elementItem), newBoard.indexOf(elementRow),
                    elementRow.indexOf(elementItem) - i,
                    newBoard.indexOf(elementRow) - i, path, pPlayer)) {
                  var tempPiece = checkAndRemoveOppBeaten(
                      elementRow.indexOf(elementItem),
                      newBoard.indexOf(elementRow),
                      elementRow.indexOf(elementItem) - i,
                      newBoard.indexOf(elementRow) - i, true, newBoard, pPlayer);

                  var returnedPiece = checkToChangeReturningPiece(
                      returnPiece, tempPiece);
                  if (returnedPiece != null && returnedPiece.isQueen) {
                    return Move(
                        returnedPiece, elementRow.indexOf(elementItem) - i,
                        newBoard.indexOf(elementRow) - i,
                        elementRow.indexOf(elementItem),
                        newBoard.indexOf(elementRow));
                  } else if (returnedPiece != null) {
                    returnPiece = Move(
                        returnedPiece, elementRow.indexOf(elementItem) - i,
                        newBoard.indexOf(elementRow) - i,
                        elementRow.indexOf(elementItem),
                        newBoard.indexOf(elementRow));
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

  void resetGame() {
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

  GamePiece? checkToChangeReturningPiece(returnPiece, tempPiece) {
    if (returnPiece.getPiece() == null) {
      return tempPiece;
    } else if (!returnPiece
        .getPiece()
        .isQueen && tempPiece != null) {
      return tempPiece;
    } else if (tempPiece != null && tempPiece.isQueen) {
      return tempPiece;
    }
  }

  Future<List<int>> simulateComputerMove() async {
    // Find moves which beat mit jedem Stein

    // finds 'ideal' piece to move, returns null if no piece beats
    var optimalMove = await findMovesWhichBeat([], currentPlayer);
    // Makes ideal move if possible
    if (optimalMove.getPiece() != null) {
      print('FOUND OPTIMAL MOVE');
      move(optimalMove.getStartX(), optimalMove.getStartY(),
          optimalMove.getEndX(), optimalMove.getEndY());
      return [
        optimalMove.getStartX(),
        optimalMove.getStartY(),
        optimalMove.getEndX(),
        optimalMove.getEndY()
      ];
    } else {
      print('FOUND NO OPTIMAL MOVE');
    }

    // Create crowned piece if possible
    for (var i = 0; i <= 9; i++) {
      if (board[1][i] != null && board[1][i]!.playerId == 2 && i - 1 >= 0 &&
          board[0][i - 1] == null && !board[1][i]!.isQueen) {
        print('FOUND PIECE TO CROWN TO LEFT');
        move(i, 1, i - 1, 0);
        return [i, 1, i - 1, 0];
      } else
      if (board[1][i] != null && board[1][i]!.playerId == 2 && i + 1 <= 9 &&
          board[0][i + 1] == null && !board[1][i]!.isQueen) {
        print('FOUND PIECE TO CROWN TO RIGHT');
        move(i, 1, i + 1, 0);
        return [i, 1, i + 1, 0];
      } else {
        print('FOUND NO PIECE TO CROWN');
      }
    }

    // Makes random move which is not made from baseline
    // Make move away from potential danger
    for (var i = 0; i <= 8; i++) {
      for (var j = 0; j <= 9; j++) {
        if (board[i][j] != null && board[i][j]!.playerId == 2 &&
            !board[i][j]!.isQueen) {
          if (j + 1 < 10 && i - 1 >= 0 && await isValidMove(j, i, j + 1, i - 1, [], currentPlayer) &&
              !surroundedByDanger(i - 1, j + 1, i, j)) {
            print('RANDOM MOVE BUT WITH NO DANGER');
            move(j, i, j + 1, i - 1);
            return [j, i, j + 1, i - 1];
          } else
          if (j - 1 >= 0 && i - 1 >= 0 && await isValidMove(j, i, j - 1, i - 1, [], currentPlayer) &&
              !surroundedByDanger(i - 1, j - 1, i, j)) {
            print('RANDOM MOVE BUT WITH NO DANGER');
            move(j, i, j - 1, i - 1);
            return [j, i, j - 1, i - 1];
          }
        }
      }
    }

    // Makes random move which is not made from baseline
    for (var i = 0; i <= 8; i++) {
      for (var j = 0; j <= 9; j++) {
        if (board[i][j] != null && this.board[i][j]!.playerId == 2 &&
            !board[i][j]!.isQueen) {
          if (i - 1 >= 0 && j + 1 <= 9 && board[i - 1][j + 1] == null) {
            print('RANDOM MOVE BUT WITH POT DANGER');
            move(j, i, j + 1, i - 1);
            return [j, i, j + 1, i - 1];
          } else if (i - 1 >= 0 && j - 1 >= 0 && board[i - 1][j - 1] != null) {
            print('RANDOM MOVE BUT WITH POT DANGER');
            move(j, i, j - 1, i - 1);
            return [j, i, j - 1, i - 1];
          }
        }
      }
    }

    // Makes random move with dame
    for (var i = 0; i <= 8; i++) {
      for (var j = 0; j <= 9; j++) {
        if (board[i][j] != null && board[i][j]!.playerId == 2 &&
            board[i][j]!.isQueen) {
          print('FOUND PC STONE AT: ${i} ${j}');
          for (var k = 1; k <= 9; k++) {
            print('SURROUNDED BY DANGER!!!!!?????????? - +');
            if (await isValidMove(j, i, j + k, i - k, [], currentPlayer) &&
                !surroundedByDanger(i - k, j + k, i, j)) {
              print('TOP RIGHT LETS GO ${i} ${j} ${i - k} ${j +
                  k } THIS IS CURRENT K ${k}');
              move(j, i, j - k, i + k);
              print('MOVE DUN DUN');
              return [j, i, j - k, i + k];
            }

            print('SURROUNDED BY DANGER!!!!!?????????? - -');
            if (await isValidMove(j, i, j - k, i - k, [], currentPlayer) &&
                !surroundedByDanger(i - k, j - k, i, j)) {
              move(j, i, j - k, i - k);
              return [j, i, j - k, i - k];
            }

            print('SURROUNDED BY DANGER!!!!!?????????? + -');
            if (await isValidMove(j, i, j - k, i + k, [], currentPlayer) &&
                !surroundedByDanger(i + k, j - k, i, j)) {
              move(j, i, j - k, i + k);
              return [j, i, j - k, i + k];
            }

            print('SURROUNDED BY DANGER!!!!!?????????? + +');
            if (await isValidMove(j, i, j + k, i + k, [], currentPlayer) &&
                !surroundedByDanger(i + k, j + k, i, j)) {
              move(j, i, j + k, i + k);
              return [j, i, j + k, i + k];
            }
          }
        }
      }
    }

    // Makes random move with dame
    for (var i = 0; i <= 8; i++) {
      for (var j = 0; j <= 9; j++) {
        if (board[i][j] != null && board[i][j]!.playerId == 2 &&
            board[i][j]!.isQueen) {
          for (var k = 1; i + k <= 9 || i - k >= 0 || j + k <= 9 ||
              j - k >= 0; k++) {
            if (i - k >= 0 && j + k <= 9 && board[i - k][j + k] == null) {
              move(j, i, j + k, i - k);
              return [j, i, j + k, i - k];
            } else
            if (i - k >= 0 && j - k >= 0 && board[i - k][j - k] == null) {
              move(j, i, j - k, i - k);
              return [j, i, j - k, i - k];
            } else
            if (i + k <= 9 && j - k >= 0 && board[i + k][j - k] == null) {
              move(j, i, j - k, i + k);
              return [j, i, j - k, i + k];
            } else
            if (i + k <= 9 && j + k <= 9 && board[i + k][j + k] == null) {
              move(j, i, j + k, i + k);
              return [j, i, j + k, i + k];
            }
          }
        }
      }
    }

    // Make move from baseline
    var startY = 9;
    for (var i = 0; i <= 9; i++) {
      if (board[9][i] != null && this.board[9][i]!.playerId == 2) {
        if (i + 1 <= 9 && board[8][i + 1] == null) {
          move(i, 9, i + 1, 8);
          return [i, 9, i + 1, 8];
        } else if (i + 1 >= 0 && board[8][i - 1] == null) {
          move(i, 9, i - 1, 8);
          return [i, 9, i - 1, 8];
        }
      }
    }
    return [-1, -1, -1, -1];
    // Make random queen move

// Make the move
// Change the player, whcih actually already when executing move i guess

// Weitere Methoden wie Überprüfung auf gültige Züge, Überprüfung der Gewinnbedingungen usw.
  }

  bool surroundedByDanger(int rowIndex, int columnIndex, int startRow,
      int startColumn) {
    print("$rowIndex, $columnIndex, 'ALARM'");


    if (columnIndex + 1 <= 9 &&
        rowIndex - 1 >= 0 &&
        board[rowIndex - 1][columnIndex + 1] != null &&
        board[rowIndex - 1][columnIndex + 1]!.playerId == (3 - currentPlayer) &&
        !board[rowIndex - 1][columnIndex + 1]!.isQueen &&
        columnIndex - 1 >= 0 &&
        rowIndex + 1 <= 9 &&
        (board[rowIndex + 1][columnIndex - 1] == null ||
            (rowIndex + 1 == startRow && columnIndex - 1 == startColumn))) {
      print('WE HERE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!');
      return true;
    } else if (columnIndex - 1 >= 0 &&
        rowIndex - 1 >= 0 &&
        board[rowIndex - 1][columnIndex - 1] != null &&
        board[rowIndex - 1][columnIndex - 1]!.playerId == (3 - currentPlayer) &&
        !board[rowIndex - 1][columnIndex - 1]!.isQueen &&
        columnIndex + 1 <= 9 &&
        rowIndex + 1 <= 9 &&
        (board[rowIndex + 1][columnIndex + 1] == null ||
            (rowIndex + 1 == startRow && columnIndex + 1 == startColumn))) {
      print('WE HERE');
      return true;
    }

    bool pieceFoundUpLeft = false;
    bool pieceFoundUpRight = false;
    bool pieceFoundDownLeft = false;
    bool pieceFoundDownRight = false;
    int maxIndex = columnIndex > rowIndex ? columnIndex : rowIndex;

    for (var k = 1; k + maxIndex <= 9; k++) {
      print("$k, 'BIG OL K', $maxIndex");
      if (0 <= (rowIndex + k) && (rowIndex + k) <= 9 &&
          columnIndex + k <= 9 && columnIndex + k >= 0 &&
          rowIndex + k != startRow && columnIndex + k != startColumn &&
          board[rowIndex + k][columnIndex + k] != null &&
          board[rowIndex + k][columnIndex + k]!.playerId ==
              (3 - currentPlayer) &&
          board[rowIndex + k][columnIndex + k]!.isQueen &&
          !pieceFoundDownRight) {
        print('Found queen which could beat at ${rowIndex + k}, ${columnIndex +
            k}');
        return true;
      } else if (0 <= (rowIndex + k) && (rowIndex + k) <= 9 &&
          columnIndex + k <= 9 && columnIndex + k >= 0 &&
          rowIndex + k != startRow && columnIndex + k != startColumn &&
          board[rowIndex + k][columnIndex + k] != null) {
        pieceFoundDownRight = true;
        print('Found piece at ${rowIndex + k}, ${columnIndex + k}');
      } else {
        print('NO DANGER FOUND AT ${rowIndex + k}, ${columnIndex + k}');
      }
      if (0 <= (rowIndex - k) && (rowIndex - k) <= 9 &&
          columnIndex + k <= 9 && columnIndex + k >= 0 &&
          rowIndex - k != startRow && columnIndex + k != startColumn &&
          board[rowIndex - k][columnIndex + k] != null &&
          board[rowIndex - k][columnIndex + k]!.playerId ==
              (3 - currentPlayer) &&
          board[rowIndex - k][columnIndex + k]!.isQueen &&
          !pieceFoundUpRight) {
        print('Found queen which could beat at ${rowIndex - k}, ${columnIndex +
            k}');
        return true;
      } else if (0 <= (rowIndex - k) && (rowIndex - k) <= 9 &&
          columnIndex + k <= 9 && columnIndex + k >= 0 &&
          rowIndex - k != startRow && columnIndex + k != startColumn &&
          board[rowIndex - k][columnIndex + k] != null) {
        pieceFoundUpRight = true;
        print('Found piece at ${rowIndex - k}, ${columnIndex + k}');
      } else {
        print('NO DANGER FOUND AT ${rowIndex - k}, ${columnIndex + k}');
      }
      if (0 <= (rowIndex + k) && (rowIndex + k) <= 9 &&
          columnIndex - k <= 9 && columnIndex - k >= 0 &&
          rowIndex + k != startRow && columnIndex - k != startColumn &&
          board[rowIndex + k][columnIndex - k] != null &&
          board[rowIndex + k][columnIndex - k]!.playerId ==
              (3 - currentPlayer) &&
          board[rowIndex + k][columnIndex - k]!.isQueen &&
          !pieceFoundDownLeft) {
            print('Found queen which could beat at ${rowIndex + k}, ${columnIndex -
            k}');
        return true;
      } else if (0 <= (rowIndex + k) && (rowIndex + k) <= 9 &&
          columnIndex - k <= 9 && columnIndex - k >= 0 &&
          rowIndex + k != startRow && columnIndex - k != startColumn &&
          board[rowIndex + k][columnIndex - k] != null) {
        pieceFoundDownLeft = true;
        print('Found piece at ${rowIndex + k}, ${columnIndex - k}');
      } else {
        print('NO DANGER FOUND AT ${rowIndex + k}, ${columnIndex - k}');
      }
      if (0 <= (rowIndex - k) && (rowIndex - k) <= 9 &&
          columnIndex - k <= 9 && columnIndex - k >= 0 &&
          rowIndex - k != startRow && columnIndex - k != startColumn &&
          board[rowIndex - k][columnIndex - k] != null &&
          board[rowIndex - k][columnIndex - k]!.playerId ==
              (3 - currentPlayer) &&
          board[rowIndex - k][columnIndex - k]!.isQueen &&
          !pieceFoundUpLeft) {
        print('Found queen which could beat at ${rowIndex - k}, ${columnIndex -
            k}');
        return true;
      } else if (0 <= (rowIndex - k) && (rowIndex - k) <= 9 &&
          columnIndex - k <= 9 && columnIndex - k >= 0 &&
          rowIndex - k != startRow && columnIndex - k != startColumn &&
          board[rowIndex - k][columnIndex - k] != null) {
        pieceFoundUpLeft = true;
        print('Found piece at ${rowIndex - k}, ${columnIndex - k}');
      } else {
        print('NO DANGER FOUND AT ${rowIndex - k}, ${columnIndex - k}');
      }
      // Additional checks similar to above for other directions
      // ...

    }

    print('OUT OF FOR');
    return false;
  }

  Future<List<int>> simulateComputerMoveWithMiniMax() async {

    // Find moves which beat mit jedem Stein
    Move optimalMove = await findMovesWhichBeat([], currentPlayer);
    print('Optimal move ' + optimalMove.toString());
    // Makes ideal move if possible
    if (optimalMove.getPiece() != null) {
      move(optimalMove.getStartX(), optimalMove.getStartY(),
          optimalMove.getEndX(), optimalMove.getEndY());

      return Future.value([optimalMove.getStartX(), optimalMove.getStartY(),
        optimalMove.getEndX(), optimalMove.getEndY()]);
    } else {
      List<List<GamePiece?>> boardCopy = board.map((list) => List<GamePiece?>.from(list))
          .toList();

      print('HERE WE GO MINIMAX START!!!!!');

      MinimaxResult minimaxRes = await minimax(
          boardCopy, 3, -10000000, 10000000, true, []);
      print(minimaxRes.path.toString() + ' is FINAL RESULT' + minimaxRes.score.toString());
      for (var node in minimaxRes.path) {
        print(node.getPiece().toString() + node.getStartX().toString() + node.getStartY().toString() + node.getEndX().toString() + node.getEndY().toString());
      }
      print(minimaxRes.toString() + ' is FINAL RESULT' +
          minimaxRes.path[minimaxRes.path.length - 1].getStartY().toString() +
          minimaxRes.path[minimaxRes.path.length - 1].getStartX().toString() +
          minimaxRes.path[minimaxRes.path.length - 1].getEndY().toString() +
          minimaxRes.path[minimaxRes.path.length - 1].getEndX().toString());
      move(minimaxRes.path[minimaxRes.path.length - 1].getStartX(),
          minimaxRes.path[minimaxRes.path.length - 1].getStartY(),
          minimaxRes.path[minimaxRes.path.length - 1].getEndX(),
          minimaxRes.path[minimaxRes.path.length - 1].getEndY());

      return Future.value([minimaxRes.path[minimaxRes.path.length - 1].getStartX(),
          minimaxRes.path[minimaxRes.path.length - 1].getStartY(),
          minimaxRes.path[minimaxRes.path.length - 1].getEndX(),
          minimaxRes.path[minimaxRes.path.length - 1].getEndY()]);

      // Make the move
      // Change the player, whcih actually already when executing move i guess


      // Weitere Methoden wie Überprüfung auf gültige Züge, Überprüfung der Gewinnbedingungen usw.
    }
  }

  Future<List<Move>> generateMoves(List<Move> path, bool isMaxPlayer) async {
    List<Move> possibleMoves = [];

    var playerGeneratingFor = 1;
    if (isMaxPlayer == true) {
      playerGeneratingFor = 2;
    }

    List<List<GamePiece?>> currentBoard = board.map((list) => List<GamePiece?>.from(list))
        .toList();

    for (var move = path.length - 1; move >= 0; move--) {
      currentBoard = await applyMove(currentBoard, path[move]);
    }

    var beatingMoveExists = false;
    print('FIND BEATING MOVES $playerGeneratingFor WIT PATH $path');
    var beatingMove = await findMovesWhichBeat(path, playerGeneratingFor);
    print('${beatingMove}MOVE');
    var beatingPiece = beatingMove.getPiece();
    print('${beatingPiece}PIECE');
    if (beatingPiece != null) {
      print('BEATING MOVE FOUND $beatingMove');
      beatingMoveExists = true;
    }
    for (var row in currentBoard) {
      //console.log(currentBoard[row], 'Row', row, 'of board')
    }
    for (var row = 0; row < 10; row++) {
      for (var col = 0; col < 10; col++) {
        var piece = currentBoard[row][col];

        //console.log(piece, 'PIECE FROM GENERATE MOVES IS AT', row, col)
        if (piece != null) {
          // For Player 1 ~ means Player = false
          if (!piece.isQueen && piece.playerId == playerGeneratingFor &&
              playerGeneratingFor == 2) {
            if (await isValidMove(
                col, row, col + 1, row - 1, path,
                2)) {

                possibleMoves.add(Move(
                    piece, col + 1, row - 1, col, row));

            } else {
              //console.log('VALID MOVES SAGT NEIN + - 1')
            }
            if (await isValidMove(
                col, row, col - 1, row - 1, path,
                2)) {

                possibleMoves.add(Move(
                    piece, col - 1, row - 1, col, row));

            } else {
              //console.log('VALID MOVES SAGT NEIN - - 1')

            }
            if (await isValidMove(
                col, row, col + 2, row - 2, path,
                2)) {

                possibleMoves.add(Move(
                    piece, col + 2, row - 2, col, row));

            } else {
              //console.log('VALID MOVES SAGT NEIN + - 2')

            }
            if (await isValidMove(
                col, row, col - 2, row - 2, path,
                2)) {

                possibleMoves.add(Move(
                    piece, col - 2, row - 2, col, row));

            } else {
              //console.log('VALID MOVES SAGT NEIN - - 2')

            }
          } else if (!piece.isQueen && piece.playerId == playerGeneratingFor &&
              playerGeneratingFor == 1) {
            //console.log('GENERATING FOR PLAYER 1')
            if (await isValidMove(
                col, row, col + 1, row + 1, path,
                1)) {

                //console.log('ADDED MOVES')
                possibleMoves.add(Move(
                    piece, col + 1, row + 1, col, row));

            } else {
              //console.log('VALID MOVES SAGT NEIN + + 1'
            }
            if (await isValidMove(
                col, row, col - 1, row + 1, path,
                1)) {
              //console.log('Simple billo check', currentBoard[6][4])

                //console.log('ADDED MOVES')
                possibleMoves.add(Move(
                    piece, col - 1, row + 1, col, row));

            } else {
              //console.log('VALID MOVES SAGT NEIN - + 1')
            }
            if (await isValidMove(
                col, row, col + 2, row + 2, path,
                1)) {

                //console.log('ADDED MOVES')
                possibleMoves.add(Move(
                    piece, col + 2, row + 2, col, row));

            } else {
              print('VALID MOVES SAGT NEIN - + 2' + col.toString() + row.toString() +
                  (col + 2).toString() + (row + 2).toString());
            }
            if (await isValidMove(
                col, row, col - 2, row + 2, path,
                1)) {
              //console.log(!beatingMoveExists, beatingMoveExists ,this.checkAndRemoveOppBeaten(col, row, Number(col) - 2, Number(row) + 2, true, currentBoard, playerGeneratingFor))

                //console.log('ADDED MOVES')
                possibleMoves.add(Move(
                    piece, col - 2, row + 2, col, row));

            } else {
              print('VALID MOVES SAGT NEIN - + 2' + col.toString() + row.toString() +
                  (col - 2).toString() + (row + 2).toString());
            }
          } else if (piece.isQueen && piece.playerId == playerGeneratingFor) {
            for (var i = 1; i < 10; i++) {
              if (col - i >= 0 && row + i < 10 && await isValidMove(
                  col, row, col - i, row + i, path,
                  playerGeneratingFor)) {

                  possibleMoves.add(Move(
                      piece, col - i, row + i, col, row));

              }
              if (col - i >= 0 && row - i >= 0 && await isValidMove(
                  col, row, col - i, row - i, path,
                  playerGeneratingFor)) {

                  possibleMoves.add(Move(
                      piece, col - i, row - i, col, row));

              }
              if (col + i < 10 && row + i < 10 && await isValidMove(
                  col, row, col + i, row + i, path,
                  playerGeneratingFor)) {

                  possibleMoves.add(Move(
                      piece, col + i, row + i, col, row));

              }
              if (col + i < 10 && row - i >= 0 && await isValidMove(
                  col, row, col + i, row - i, path,
                  playerGeneratingFor)) {

                  possibleMoves.add(Move(
                      piece, col + i, row - i, col, row));

              }
            }
          }
        }

        // Make random queen move
      }
    }
    for (var move in possibleMoves) {
      print('${move.getStartX()}${move.getStartY()}${move.getEndX()}${move.getEndY()}\n');
    }

    List<Move> foundCleanMoves = [];

    for (var move in possibleMoves) {
      var moveInQ = checkAndRemoveOppBeaten(
          move.getStartX(),
          move.getStartY(),
          move.getEndX(),
          move.getEndY(),
          true,
          currentBoard,
          playerGeneratingFor);
      if (moveInQ != null) {
        print('SETTING BOOL TRUE BECAUSE OF' + move.toString() + move.getStartX().toString()
              + move.getStartY().toString() + move.getEndX().toString() + move.getEndY().toString());
        foundCleanMoves.add(Move(
            move.getPiece(), move.getEndX(),
            move.getEndY(), move.getStartX(),
            move.getStartY()));
      }
    }

    if (foundCleanMoves.isNotEmpty) {
      print('RETURNED MODIFIED ARRAY');
      return foundCleanMoves;
    } else {
      print('RETURNED UNMODIFIED ARRAY');
      return possibleMoves;
    }
  }

    Future<List<List<GamePiece?>>> applyMove(List<List<GamePiece?>> board, Move move) {

      /**
          const beatenPiece: GamePiece | null = this.checkAndRemoveOppBeaten(startCol, startRow, endCol, endRow, true);
          var foundBeatingMove = this.findMovesWhichBeat().getPiece()
          if (beatenPiece == null && foundBeatingMove) {
          this.stateString = `Spieler ${this.currentPlayer} hat die Schlagpflicht verletzt, wähle einen anderen Zug`;
          return false;
          }

          if(foundBeatingMove && foundBeatingMove.isQueen && beatenPiece && !beatenPiece.isQueen){
          stateString = 'Dame schlagen geht vor';
          return false;
          }
       */


      // Beispiel für das Bewegen eines Spielsteins


      var piece = board[move.getStartY()][move.getStartX()];
      board[move.getEndY()][move.getEndX()] = piece;
      //console.log(board[move.getEndY()][move.getEndX()], ' Moved piece at new location')
      board[move.getStartY()][move.getStartX()] = null;
      //console.log(board[move.getStartY()][move.getStartX()], ' Content of old location')

      return Future.value(board);

      //const beatenPiece = this.checkAndRemoveOppBeaten(startCol, startRow, endCol, endRow, false);

    }

    Future<int> evaluateState(List<List<GamePiece?>> pBoard, List<Move> path) async {
      List<List<GamePiece?>> evaluationBoardCopy = board.map((list) =>
        List<GamePiece?>.from(list)).toList();
      var returnValueForBeat = 0;
      int boardScore = 0;

      print('EVAL PATH' + path.toString());


      // Apply first move of simulation, which will be a maxi move
      for (var move = path.length - 1; move >= 0; move--) {
        evaluationBoardCopy = await applyMove(evaluationBoardCopy, path[move]);
        var potBeatenPiece = checkAndRemoveOppBeaten(
            path[move].getStartX(),
            path[move].getStartY(),
            path[move].getEndX(),
            path[move].getEndY(),
            true,
            evaluationBoardCopy,
            (path[move]
                .getPiece()
                !.playerId));

        //console.log(potBeatenPiece, 'POT BEATEN PIECE')
        if (potBeatenPiece != null && potBeatenPiece.playerId == 1) {
          print(path[move].toString() + 'gives us infinity');
          returnValueForBeat = 10000000;
          return returnValueForBeat;
        } else if (potBeatenPiece != null && potBeatenPiece.playerId == 2) {
          print(path[move].toString() + 'gives us negative infinity');
          returnValueForBeat = -10000000;
          return returnValueForBeat;
        }
      }

      for (var row in evaluationBoardCopy) {
        for (var piece in row) {
          if (piece != null) {
            int colValue = 0;
            var rowValue = 0;
            var addValue = 0;
            var subValue = 0;

            if (evaluationBoardCopy.indexOf(row) == 0) {
              rowValue = 35;
            } else if (evaluationBoardCopy.indexOf(row) == 1) {
              rowValue == 1;
            } else if (evaluationBoardCopy.indexOf(row) == 2) {
              rowValue == 2;
            } else if (evaluationBoardCopy.indexOf(row) == 3) {
              rowValue == 4;
            } else if (evaluationBoardCopy.indexOf(row) == 4) {
              rowValue == 7;
            } else if (evaluationBoardCopy.indexOf(row) == 5) {
              rowValue == 11;
            } else if (evaluationBoardCopy.indexOf(row) == 6) {
              rowValue == 16;
            } else if (evaluationBoardCopy.indexOf(row) == 7) {
              rowValue == 22;
            } else if (evaluationBoardCopy.indexOf(row) == 8) {
              rowValue == 29;
            } else if (evaluationBoardCopy.indexOf(row) == 9) {
              rowValue == 37;
            }

            if (row.indexOf(piece) < 5) {
              colValue = (5 - row.indexOf(piece)).abs();
            } else {
              colValue = (4 - row.indexOf(piece)).abs();
            }

            if (evaluationBoardCopy.indexOf(row) - 1 >= 0 &&
                row.indexOf(piece) - 1 >= 0 &&
                (evaluationBoardCopy[evaluationBoardCopy.indexOf(row) - 1][row
                    .indexOf(piece) - 1] == null ||
                    evaluationBoardCopy[evaluationBoardCopy.indexOf(row) -
                        1][row.indexOf(piece) - 1]?.playerId == 2)) {
              addValue = addValue + 10;
            }
            if (evaluationBoardCopy.indexOf(row) - 1 >= 0 &&
                row.indexOf(piece) + 1 < 10 &&
                (evaluationBoardCopy[evaluationBoardCopy.indexOf(row) - 1][row
                    .indexOf(piece) + 1] == null ||
                    evaluationBoardCopy[evaluationBoardCopy.indexOf(row) -
                        1][row.indexOf(piece) + 1]?.playerId == 2)) {
              addValue = addValue + 10;
            }

            if (evaluationBoardCopy.indexOf(row) - 1 >= 0 &&
                row.indexOf(piece) - 1 >= 0 && row.indexOf(piece) + 1 < 10 &&
                (evaluationBoardCopy[evaluationBoardCopy.indexOf(row) - 1][row
                    .indexOf(piece) - 1] != null &&
                    evaluationBoardCopy[evaluationBoardCopy.indexOf(row) -
                        1][row.indexOf(piece) - 1]?.playerId == 1 &&
                    evaluationBoardCopy[evaluationBoardCopy.indexOf(row) +
                        1][row.indexOf(piece) + 1] == null)) {
              subValue = subValue - 10;
            }
            if (evaluationBoardCopy.indexOf(row) - 1 >= 0 &&
                row.indexOf(piece) + 1 < 10 && row.indexOf(piece) - 1 >= 0 &&
                evaluationBoardCopy.indexOf(row) + 1 < 10 &&
                (evaluationBoardCopy[evaluationBoardCopy.indexOf(row) - 1][row
                    .indexOf(piece) + 1] != null &&
                    evaluationBoardCopy[evaluationBoardCopy.indexOf(row) -
                        1][row.indexOf(piece) + 1]?.playerId == 1 &&
                    evaluationBoardCopy[evaluationBoardCopy.indexOf(row) +
                        1][row.indexOf(piece) - 1] == null)) {
              subValue = subValue - 10;
            }

            boardScore =
                boardScore + colValue + rowValue + addValue + subValue;
          }
        }
      }

      if (returnValueForBeat != 0) {
        //console.log(returnValueForBeat, 'for path', path)
        return returnValueForBeat;
      } else {
        //console.log(boardScore, 'for path', path)
        return boardScore;
      }

  }

  Future<MinimaxResult> minimax(List<List<GamePiece?>> pBoard, int depth, int alpha,
      int beta, bool isMaximizingPlayer, List<Move> path) async {
    print(depth.toString() + ' DEEEEEPNESSSS');
    if (depth == 0 || checkWin(pBoard)) {
      return MinimaxResult(
          score: await evaluateState(pBoard, path), path: path);
    }

    List<List<GamePiece?>> newState = pBoard.map((list) => List<GamePiece?>.from(list))
        .toList();

    if (isMaximizingPlayer) {
      MinimaxResult maxEval = MinimaxResult(
          score: -10000000, path: []);
      for (var move in await generateMoves(path, true)) {
        print('CURRENT MOVE $move');
        List<List<GamePiece?>> tempState = newState.map((list) =>
        List<GamePiece?>.from(list)).toList();

        var value = await minimax(
            await applyMove(tempState, move), depth - 1, alpha, beta, false, [move, ...path]);
        //console.log(path, 'Current path')
        if (value.score >= maxEval.score) {
          maxEval.score = value.score;
          maxEval.path = value
              .path; // Prepend this move to the path leading to the best score
        }
        alpha = max(alpha, value.score);
        /**
            if (beta <= alpha) {
            break;
            }
         */

      }
      return Future.value(maxEval);
    } else {
      MinimaxResult minEval = MinimaxResult(
          score: 10000000, path: []);
      for (var move in await generateMoves(path, false)) {
        print('CURRENT MOVE' + move.toString());
        List<List<GamePiece?>> tempState = newState.map((list) =>
        List<GamePiece?>.from(list)).toList();

        var value = await minimax(
            await applyMove(tempState, move), depth - 1, alpha, beta, true,
            [move, ...path]);
        if (value.score <= minEval.score) {
          minEval.score = value.score;
          minEval.path = value.path; // Prepend this move to the path
        }
        beta = min(beta, value.score);
        /**
            if (beta <= alpha) {
            break;
            }
         */
      }
      return Future.value(minEval);
    }
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

  @override
  String toString(){
    return 'MOVE from x:${startX} y: ${startY} to x:${endX} y:${endY}';
  }
}

class MinimaxResult {
  int score;
  List<Move> path;

  MinimaxResult({required this.score, required this.path});
}
