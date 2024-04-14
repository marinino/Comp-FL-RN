import 'dart:ui';
import 'game_piece.dart';
import 'dart:math';

class DameGame {

  // A list of callbacks that are invoked when the game is reset
  final List<VoidCallback> _listeners = [];

  // Method for adding a listener
  void addListener(VoidCallback listener) {
    _listeners.add(listener);
  }

  // Method for removing a listener
  void removeListener(VoidCallback listener) {
    _listeners.remove(listener);
  }

  late List<
  List<GamePiece?>> board; // 0 = No piece, 1 = Player 1, 2 = Player 2
  late int currentPlayer; // 1 or 2
  String stateString = '';

  DameGame() {
    // Initialize the game board and set the current player
    board = List.generate(10, (_) => List.generate(10, (_) => null));

    currentPlayer = 1;

    // Set the starting positions of the game pieces
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
    stateString = 'Player 1 is next';
  }

  Future<bool> move(int startX, int startY, int endX, int endY) async {
    // Check if the move is valid
    if (!await isValidMove(startX, startY, endX, endY, [], currentPlayer)) {
      return false;
    }

    var checkBeatenPiece = checkAndRemoveOppBeaten(
        startX, startY, endX, endY, true, board, currentPlayer);
    var foundOptimum = await findMovesWhichBeat([], currentPlayer);

    if (checkBeatenPiece == null && foundOptimum.getPiece() != null) {
      stateString =
      'Player $currentPlayer hurt the mandation to capture, choose a different move';
      return false;
    }
    if (foundOptimum.getPiece() != null && foundOptimum.getPiece()!.isQueen &&
        checkBeatenPiece != null
        && !checkBeatenPiece.isQueen) {
      stateString = 'Captured pieces need to be capture if possible';
      return false;
    }

    // Perform the move

    board[startY][startX]?.isAnimated = true;

    board[endY][endX] = board[startY][startX];
    board[startY][startX] = null;

    return true;
  }

  // Simulate flag makes it possible to test results of moves without actually performing them
  GamePiece? checkAndRemoveOppBeaten(int startX, int startY, int endX, endY,
      bool simulate, List<List<GamePiece?>> pBoard, int pPlayer) {
    GamePiece? beatenPiece;

    // Only one fields were jumped, so nobody could be beaten
    if ((startX - endX).abs() == 1) {
      return null;
    }

    List<List<int>> jumpedFields = getJumpedFields(startX, startY, endX, endY);

    for (var element in jumpedFields) {
      if (pBoard[element[1]][element[0]]?.playerId != pPlayer) {
        beatenPiece = pBoard[element[1]][element[0]];
        if (!simulate) {
          pBoard[element[1]][element[0]] = null;
        }
      }
    }
    return beatenPiece;
  }

  List<List<int>> getJumpedFields(int startX, int startY, int endX, endY) {
    List<List<int>> visitedFields = [];

    int deltaX = endX > startX
        ? 1
        : -1; // Determines the direction in x-axis
    int deltaY = endY > startY
        ? 1
        : -1; // Determines the direction in y-axis

    int x = startX;
    int y = startY;

    // Moves until target field is reached
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

  // Checking if the move is valid
  Future<bool> isValidMove(int startX, int startY, int endX, int endY, List<Move> path, int pPlayer) async {

    List<List<GamePiece?>> newBoard = board.map((list) => List<GamePiece?>.from(list))
        .toList();

    for (var move = path.length - 1; move >= 0; move--) {
      newBoard = await applyMove(newBoard, path[move]);
    }

    bool jumpedOwnPiecesOrAir = false;
    List<List<int>> jumpedFields = getJumpedFields(startX, startY, endX, endY);

    // The given parameters are out of bounds
    if(endX > 9 || endX < 0 || endY > 9 || endY < 0){
      return false;
    }

    // Target field if occupied
    if (newBoard[endY][endX] != null) {
      stateString = 'Target field has to be empty';
      return false;
    }

    // Jump straight in X or Y direction
    if (startX == endX || startY == endY) {
      stateString = 'Only diagonal moves are allowed';
      return false;
    }

    // Jump different distance in X and Y
    if ((startX - endX).abs() != (startY - endY).abs()) {
      stateString = 'Only diagonal moves are allowed';
      return false;
    }

    for (var element in jumpedFields) {
      if (newBoard[element[1]][element[0]]?.playerId == pPlayer) {
        jumpedOwnPiecesOrAir = true;
      }
    }
    // Jumping over a empty tile or a own piece
    if (jumpedOwnPiecesOrAir) {
      stateString = 'Only opponent pieces are allowed to be jumped';
      return false;
    }

    // FOR NON QUEENS
    if ((newBoard[startY][startX] != null && (!newBoard[startY][startX]!.isQueen))) {
      // Moving backwards
      if (((endY < startY) && pPlayer == 1) ||
          ((endY > startY) && pPlayer == 2)) {
        stateString = 'Moving backwards is only allowed with crowned pieces';
        return false;
      }

      // Non crowned pieces can not jump more than one field
      if (newBoard[startY][startX] != null && (!newBoard[startY][startX]!.isQueen) &&
          (startX - endX).abs() > 2) {
        stateString = 'Normal pieces can only jump two fields max';
        return false;
      }

      for (var element in jumpedFields) {
        if (newBoard[element[1]][element[0]] == null) {
          jumpedOwnPiecesOrAir = true;
        }
      }
      // Jumping over a empty tile or a own piece
      if (jumpedOwnPiecesOrAir) {
        stateString = 'Only opponent pieces may be jumped';
        return false;
      }
      // FOR CROWNED PIECES
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
        'A crowned piece can only jump over opponent pieces';
        return false;
      }
      if (foundOwnPiece) {
        stateString =
        'A crowned piece can not jump over own players pieces';
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
        stateString = 'The crowned piece in to land in the vicinity of an opponent piece';
        return false;
      }
    }
    // IF ELIMINATION HAPPENS NO NEED TO CHECK IF MOVE IS VALID
    if (checkAndRemoveOppBeaten(startX, startY, endX, endY, true, newBoard, pPlayer) != null) {
      return true;
    }

    return true;
  }

  // Checks if at least one piece of both players is still on the board
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

    return !(foundBlack && foundWhite);
  }

  bool checkForQueenConv() {
    for (int i = 0; i < 10; i++) {
      if (board[0][i]?.playerId == 2) {
        if (board[0][i] != null && !(board[0][i]!.isQueen)) {
          stateString = 'Player 2 has new crowned piece';
          board[0][i]?.promoteToQueen();
          return true;
        }
      }

      if (board[9][i]?.playerId == 1) {
        if (board[9][i] != null && !(board[9][i]!.isQueen)) {
          stateString = 'Player 1 has new crowned piece';
          board[9][i]?.promoteToQueen();
          return true;
        }
      }
    }
    return false;
  }

  Future<Move> findMovesWhichBeat(List<Move> path, int pPlayer) async {
    var returnPiece = Move(null, -1, -1, -1, -1);

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
            // Check for lower right piece
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

    // Set initial positions
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
    stateString = 'Player 1 is next';

    // Alerts all listeners
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
    } else {
      return null;
    }
  }

  Future<List<int>> simulateComputerMove() async {
    // finds 'ideal' piece to move, returns null if no piece beats
    var optimalMove = await findMovesWhichBeat([], currentPlayer);
    // Makes ideal move if possible
    if (optimalMove.getPiece() != null) {
      move(optimalMove.getStartX(), optimalMove.getStartY(),
          optimalMove.getEndX(), optimalMove.getEndY());
      return [
        optimalMove.getStartX(),
        optimalMove.getStartY(),
        optimalMove.getEndX(),
        optimalMove.getEndY()
      ];
    }

    // Create crowned piece if possible
    for (var i = 0; i <= 9; i++) {
      if (board[1][i] != null && board[1][i]!.playerId == 2 && i - 1 >= 0 &&
          board[0][i - 1] == null && !board[1][i]!.isQueen) {
        move(i, 1, i - 1, 0);
        return [i, 1, i - 1, 0];
      } else
      if (board[1][i] != null && board[1][i]!.playerId == 2 && i + 1 <= 9 &&
          board[0][i + 1] == null && !board[1][i]!.isQueen) {
        move(i, 1, i + 1, 0);
        return [i, 1, i + 1, 0];
      } else {
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
            move(j, i, j + 1, i - 1);
            return [j, i, j + 1, i - 1];
          } else
          if (j - 1 >= 0 && i - 1 >= 0 && await isValidMove(j, i, j - 1, i - 1, [], currentPlayer) &&
              !surroundedByDanger(i - 1, j - 1, i, j)) {
            move(j, i, j - 1, i - 1);
            return [j, i, j - 1, i - 1];
          }
        }
      }
    }

    // Makes random move which is not made from baseline
    for (var i = 0; i <= 8; i++) {
      for (var j = 0; j <= 9; j++) {
        if (board[i][j] != null && board[i][j]!.playerId == 2 &&
            !board[i][j]!.isQueen) {
          if (i - 1 >= 0 && j + 1 <= 9 && board[i - 1][j + 1] == null) {
            move(j, i, j + 1, i - 1);
            return [j, i, j + 1, i - 1];
          } else if (i - 1 >= 0 && j - 1 >= 0 && board[i - 1][j - 1] != null) {
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
          for (var k = 1; k <= 9; k++) {
            if (await isValidMove(j, i, j + k, i - k, [], currentPlayer) &&
                !surroundedByDanger(i - k, j + k, i, j)) {
              move(j, i, j - k, i + k);
              return [j, i, j - k, i + k];
            }

            if (await isValidMove(j, i, j - k, i - k, [], currentPlayer) &&
                !surroundedByDanger(i - k, j - k, i, j)) {
              move(j, i, j - k, i - k);
              return [j, i, j - k, i - k];
            }

            if (await isValidMove(j, i, j - k, i + k, [], currentPlayer) &&
                !surroundedByDanger(i + k, j - k, i, j)) {
              move(j, i, j - k, i + k);
              return [j, i, j - k, i + k];
            }

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
    for (var i = 0; i <= 9; i++) {
      if (board[9][i] != null && board[9][i]!.playerId == 2) {
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
  }

  bool surroundedByDanger(int rowIndex, int columnIndex, int startRow,
      int startColumn) {

    if (columnIndex + 1 <= 9 &&
        rowIndex - 1 >= 0 &&
        board[rowIndex - 1][columnIndex + 1] != null &&
        board[rowIndex - 1][columnIndex + 1]!.playerId == (3 - currentPlayer) &&
        !board[rowIndex - 1][columnIndex + 1]!.isQueen &&
        columnIndex - 1 >= 0 &&
        rowIndex + 1 <= 9 &&
        (board[rowIndex + 1][columnIndex - 1] == null ||
            (rowIndex + 1 == startRow && columnIndex - 1 == startColumn))) {
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
      return true;
    }

    bool pieceFoundUpLeft = false;
    bool pieceFoundUpRight = false;
    bool pieceFoundDownLeft = false;
    bool pieceFoundDownRight = false;
    int maxIndex = columnIndex > rowIndex ? columnIndex : rowIndex;

    for (var k = 1; k + maxIndex <= 9; k++) {
      if (0 <= (rowIndex + k) && (rowIndex + k) <= 9 &&
          columnIndex + k <= 9 && columnIndex + k >= 0 &&
          rowIndex + k != startRow && columnIndex + k != startColumn &&
          board[rowIndex + k][columnIndex + k] != null &&
          board[rowIndex + k][columnIndex + k]!.playerId ==
              (3 - currentPlayer) &&
          board[rowIndex + k][columnIndex + k]!.isQueen &&
          !pieceFoundDownRight) {
        return true;
      } else if (0 <= (rowIndex + k) && (rowIndex + k) <= 9 &&
          columnIndex + k <= 9 && columnIndex + k >= 0 &&
          rowIndex + k != startRow && columnIndex + k != startColumn &&
          board[rowIndex + k][columnIndex + k] != null) {
        pieceFoundDownRight = true;
      }
      if (0 <= (rowIndex - k) && (rowIndex - k) <= 9 &&
          columnIndex + k <= 9 && columnIndex + k >= 0 &&
          rowIndex - k != startRow && columnIndex + k != startColumn &&
          board[rowIndex - k][columnIndex + k] != null &&
          board[rowIndex - k][columnIndex + k]!.playerId ==
              (3 - currentPlayer) &&
          board[rowIndex - k][columnIndex + k]!.isQueen &&
          !pieceFoundUpRight) {
        return true;
      } else if (0 <= (rowIndex - k) && (rowIndex - k) <= 9 &&
          columnIndex + k <= 9 && columnIndex + k >= 0 &&
          rowIndex - k != startRow && columnIndex + k != startColumn &&
          board[rowIndex - k][columnIndex + k] != null) {
        pieceFoundUpRight = true;
      }
      if (0 <= (rowIndex + k) && (rowIndex + k) <= 9 &&
          columnIndex - k <= 9 && columnIndex - k >= 0 &&
          rowIndex + k != startRow && columnIndex - k != startColumn &&
          board[rowIndex + k][columnIndex - k] != null &&
          board[rowIndex + k][columnIndex - k]!.playerId ==
              (3 - currentPlayer) &&
          board[rowIndex + k][columnIndex - k]!.isQueen &&
          !pieceFoundDownLeft) {
        return true;
      } else if (0 <= (rowIndex + k) && (rowIndex + k) <= 9 &&
          columnIndex - k <= 9 && columnIndex - k >= 0 &&
          rowIndex + k != startRow && columnIndex - k != startColumn &&
          board[rowIndex + k][columnIndex - k] != null) {
        pieceFoundDownLeft = true;
      }
      if (0 <= (rowIndex - k) && (rowIndex - k) <= 9 &&
          columnIndex - k <= 9 && columnIndex - k >= 0 &&
          rowIndex - k != startRow && columnIndex - k != startColumn &&
          board[rowIndex - k][columnIndex - k] != null &&
          board[rowIndex - k][columnIndex - k]!.playerId ==
              (3 - currentPlayer) &&
          board[rowIndex - k][columnIndex - k]!.isQueen &&
          !pieceFoundUpLeft) {
        return true;
      } else if (0 <= (rowIndex - k) && (rowIndex - k) <= 9 &&
          columnIndex - k <= 9 && columnIndex - k >= 0 &&
          rowIndex - k != startRow && columnIndex - k != startColumn &&
          board[rowIndex - k][columnIndex - k] != null) {
        pieceFoundUpLeft = true;
      }
      // Additional checks similar to above for other directions
      // ...

    }
    return false;
  }

  Future<List<int>> simulateComputerMoveWithMiniMax() async {

    Move optimalMove = await findMovesWhichBeat([], currentPlayer);
    // Makes ideal move if possible
    if (optimalMove.getPiece() != null) {
      move(optimalMove.getStartX(), optimalMove.getStartY(),
          optimalMove.getEndX(), optimalMove.getEndY());

      return Future.value([optimalMove.getStartX(), optimalMove.getStartY(),
        optimalMove.getEndX(), optimalMove.getEndY()]);
    } else {
      List<List<GamePiece?>> boardCopy = board.map((list) => List<GamePiece?>.from(list))
          .toList();

      MinimaxResult minimaxRes = await minimax(
          boardCopy, 3, -10000000, 10000000, true, []);

      move(minimaxRes.path[minimaxRes.path.length - 1].getStartX(),
          minimaxRes.path[minimaxRes.path.length - 1].getStartY(),
          minimaxRes.path[minimaxRes.path.length - 1].getEndX(),
          minimaxRes.path[minimaxRes.path.length - 1].getEndY());

      return Future.value([minimaxRes.path[minimaxRes.path.length - 1].getStartX(),
          minimaxRes.path[minimaxRes.path.length - 1].getStartY(),
          minimaxRes.path[minimaxRes.path.length - 1].getEndX(),
          minimaxRes.path[minimaxRes.path.length - 1].getEndY()]);

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

    for (var row = 0; row < 10; row++) {
      for (var col = 0; col < 10; col++) {
        var piece = currentBoard[row][col];

        if (piece != null) {
          // For Player 1 ~ means Player = false
          if (!piece.isQueen && piece.playerId == playerGeneratingFor &&
              playerGeneratingFor == 2) {
            if (await isValidMove(
                col, row, col + 1, row - 1, path,
                2)) {

                possibleMoves.add(Move(
                    piece, col + 1, row - 1, col, row));

            }
            if (await isValidMove(
                col, row, col - 1, row - 1, path,
                2)) {

                possibleMoves.add(Move(
                    piece, col - 1, row - 1, col, row));

            }
            if (await isValidMove(
                col, row, col + 2, row - 2, path,
                2)) {

                possibleMoves.add(Move(
                    piece, col + 2, row - 2, col, row));

            }
            if (await isValidMove(
                col, row, col - 2, row - 2, path,
                2)) {

                possibleMoves.add(Move(
                    piece, col - 2, row - 2, col, row));

            }
          } else if (!piece.isQueen && piece.playerId == playerGeneratingFor &&
              playerGeneratingFor == 1) {
            if (await isValidMove(
                col, row, col + 1, row + 1, path,
                1)) {

                possibleMoves.add(Move(
                    piece, col + 1, row + 1, col, row));

            }
            if (await isValidMove(
                col, row, col - 1, row + 1, path,
                1)) {

                possibleMoves.add(Move(
                    piece, col - 1, row + 1, col, row));

            }
            if (await isValidMove(
                col, row, col + 2, row + 2, path,
                1)) {

                possibleMoves.add(Move(
                    piece, col + 2, row + 2, col, row));

            }
            if (await isValidMove(
                col, row, col - 2, row + 2, path,
                1)) {

                possibleMoves.add(Move(
                    piece, col - 2, row + 2, col, row));

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
      }
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

        foundCleanMoves.add(Move(
            move.getPiece(), move.getEndX(),
            move.getEndY(), move.getStartX(),
            move.getStartY()));
      }
    }

    if (foundCleanMoves.isNotEmpty) {
      return foundCleanMoves;
    } else {
      return possibleMoves;
    }
  }

    Future<List<List<GamePiece?>>> applyMove(List<List<GamePiece?>> board, Move move) {

      var piece = board[move.getStartY()][move.getStartX()];
      board[move.getEndY()][move.getEndX()] = piece;
      board[move.getStartY()][move.getStartX()] = null;

      return Future.value(board);
    }

    Future<int> evaluateState(List<List<GamePiece?>> pBoard, List<Move> path) async {
      List<List<GamePiece?>> evaluationBoardCopy = board.map((list) =>
        List<GamePiece?>.from(list)).toList();
      var returnValueForBeat = 0;
      int boardScore = 0;

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

        if (potBeatenPiece != null && potBeatenPiece.playerId == 1) {
          returnValueForBeat = 10000000;
          return returnValueForBeat;
        } else if (potBeatenPiece != null && potBeatenPiece.playerId == 2) {
          returnValueForBeat = -10000000;
          return returnValueForBeat;
        }
      }

      for (var row in evaluationBoardCopy) {
        for (var piece in row) {
          if (piece != null) {
            var colValue = 0;
            var rowValue = 0;
            var addValue = 0;
            var subValue = 0;

            if (evaluationBoardCopy.indexOf(row) == 0) {
              rowValue = 35;
            } else if (evaluationBoardCopy.indexOf(row) == 1) {
              rowValue = 1;
            } else if (evaluationBoardCopy.indexOf(row) == 2) {
              rowValue = 2;
            } else if (evaluationBoardCopy.indexOf(row) == 3) {
              rowValue = 4;
            } else if (evaluationBoardCopy.indexOf(row) == 4) {
              rowValue = 7;
            } else if (evaluationBoardCopy.indexOf(row) == 5) {
              rowValue = 11;
            } else if (evaluationBoardCopy.indexOf(row) == 6) {
              rowValue = 16;
            } else if (evaluationBoardCopy.indexOf(row) == 7) {
              rowValue = 22;
            } else if (evaluationBoardCopy.indexOf(row) == 8) {
              rowValue = 29;
            } else if (evaluationBoardCopy.indexOf(row) == 9) {
              rowValue = 37;
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
                evaluationBoardCopy.indexOf(row) + 1 < 10 &&
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
        return returnValueForBeat;
      } else {
        return boardScore;
      }

  }

  Future<MinimaxResult> minimax(List<List<GamePiece?>> pBoard, int depth, int alpha,
      int beta, bool isMaximizingPlayer, List<Move> path) async {
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
        List<List<GamePiece?>> tempState = newState.map((list) =>
        List<GamePiece?>.from(list)).toList();

        var value = await minimax(
            await applyMove(tempState, move), depth - 1, alpha, beta, false, [move, ...path]);
        if (value.score >= maxEval.score) {
          maxEval.score = value.score;
          maxEval.path = value.path; // Prepend this move to the path leading to the best score
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
    return 'MOVE from x:$startX y: $startY to x:$endX y:$endY';
  }
}

class MinimaxResult {
  int score;
  List<Move> path;

  MinimaxResult({required this.score, required this.path});
}
