import GamePiece from './GamePiece'
import GameBoard from './GameBoard'
import { Animated, Dimensions, Easing } from 'react-native';


export default class DameGame {


  constructor() {
    this.pieceAnimatedValues = {}
    this.pieceZValues = {}
    this.squareWidth = (Dimensions.get('window').width)/20
    this.topLeftValue =
    this.animationRunning = false
    this.selectedX = -1
    this.selectedY = -1
    this.boardSize = 10;
    this.board = Array.from({ length: this.boardSize }, () => Array(this.boardSize).fill(null));
    this.currentPlayer = 1; // 1 für Spieler 1, 2 für Spieler 2
    this.bestMinimaxMove = new Move(null, -1, -1, -1, -1);
    this.currentTree = null

    //this.board[0][1] = new GamePiece(`0-1`, 1, false)

    //this.board[2][3] = new GamePiece(`3-4`, 2, false)

    // Initialisieren des Bretts mit Spielsteinen
    for (let row = 0; row < this.boardSize; row++) {
      for (let col = 0; col < this.boardSize; col++) {
        if ((row + col) % 2 === 1) {
          if (row < 4) {
            this.board[row][col] = new GamePiece(`${row}-${col}`, 1);
          } else if (row >= 6) {
            this.board[row][col] = new GamePiece(`${row}-${col}`, 2);
          }
        }
      }
    }

    const initialAnimatedValues = {};
    this.board.forEach((row, rowIndex) => {
      row.forEach((piece, colIndex) => {
        if (this.board[rowIndex][colIndex]) {
          const key = `${rowIndex}-${colIndex}`; // Or any unique identifier for the piece
          initialAnimatedValues[key] = new Animated.ValueXY({ x: this.squareWidth * colIndex + this.squareWidth * 0.15 / 2, y: this.squareWidth * rowIndex + this.squareWidth * 0.15 / 2}); // Initial position
        }
      });
    });
    this.pieceAnimatedValues = initialAnimatedValues;

    const initialZValues = {};
    this.board.forEach((row, rowIndex) => {
      row.forEach((piece, colIndex) => {
        if (this.board[rowIndex][colIndex]) {
          const key = `${rowIndex}-${colIndex}`; // Or any unique identifier for the piece
          initialZValues[key] = 1; // Initial position
        }
      });
    });
    this.pieceZValues = initialZValues;
  }

  async movePiece(startRow, startCol, endRow, endCol) {
      // Hier könnten Sie die Logik zum Bewegen der Spielsteine implementieren
      // einschließlich der Überprüfung auf gültige Züge und das Schlagen gegnerischer Steine
      //console.log('ICH HAB DIE RICHTIG GERUFEN')

      // Prüfen Sie, ob der Zug gültig ist
      var validMoveBool = await this.isValidMove(startCol, startRow, endCol, endRow)
      if (!validMoveBool) {
        //console.log('DIS MOVE NOT VALID')
        return false;
      }

      const beatenPiece: GamePiece | null = await this.checkAndRemoveOppBeaten(startCol, startRow, endCol, endRow, true);
      var foundBeatingMovePre = await this.findMovesWhichBeat()
      var foundBeatingMove = foundBeatingMovePre.getPiece()
      if (beatenPiece == null && foundBeatingMove) {
        this.stateString = `Spieler ${this.currentPlayer} hat die Schlagpflicht verletzt, wähle einen anderen Zug`;
        //console.log('SCHLAGPFLICHT UND SO')
        return false;
      }

      if(foundBeatingMove && foundBeatingMove.isQueen && beatenPiece && !beatenPiece.isQueen){
        stateString = 'Dame schlagen geht vor';
        //console.log('DAME SCHLAGEN')
        return false;
      }

      // Beispiel für das Bewegen eines Spielsteins
      const piece = this.board[startRow][startCol];
      this.board[endRow][endCol] = piece;
      this.board[startRow][startCol] = null;

      //console.log('TO DA ANIMATION')



        if(piece && !this.animationRunning){

          const animatedValue = this.pieceAnimatedValues[piece.pieceId];
          this.animationRunning = true
          piece.isAnimated = true




          return new Promise(async (resolve, reject) => {
            Animated.timing(animatedValue, {
                  toValue: { x: endCol * this.squareWidth + this.squareWidth * 0.15 / 2, y: endRow * this.squareWidth + this.squareWidth * 0.15 / 2 }, // You need to convert board positions to screen positions
                  duration: 1000,
                  easing: Easing.inOut(Easing.ease),
                  useNativeDriver: true,
              }).start(async ({ finished }) => {

                      // Assuming newPosition provides the correct final coordinates
                      // You might need to convert row and column to actual x, y coordinates
                  this.pieceAnimatedValues[piece.pieceId] = new Animated.ValueXY({ x: this.squareWidth * endCol + this.squareWidth * 0.15 / 2, y: this.squareWidth * endRow + this.squareWidth * 0.15 / 2});

                  // Aktualisieren Sie den Zustand, um die UI neu zu rendern
                  this.animationRunning = false

                  const beatenPiece = await this.checkAndRemoveOppBeaten(startCol, startRow, endCol, endRow, false);
                  const newQueen: boolean = await this.checkForQueenConv();
                  const movesWhichBeat = await this.findMovesWhichBeat()

                  // Ändert den Spieler, wenn kein weiterer Schlag möglich ist oder es keinen Schlag gab
                  if (beatenPiece != null && movesWhichBeat.getPiece() && !newQueen) {
                    this.stateString = `Player ${this.currentPlayer} is next`;
                  } else {
                    this.currentPlayer = 3 - this.currentPlayer;
                    this.stateString = `Player ${this.currentPlayer} can continue`;
                  }


                  if (await this.checkWin()) {
                    this.stateString = `Spieler ${3 - this.currentPlayer} hat gewonnen`;
                    setTimeout(async () => {
                      await this.resetGame();
                    }, 5000);
                  }







                  if(finished){
                        resolve();
                  } else {
                      // Handle interruption or rejection
                      reject(new Error('Animation was interrupted'));
                  }





              });
            })


          }


    }

  async handlePressDeep(row, column){
    var returnedDataFromMove = null
    if(this.selectedX == -1){
        if(this.board[row][column]?.playerId != this.currentPlayer){
          return;
        }
        this.selectedX = column;
        this.selectedY = row;
        this.stateString =
          `Spieler ${this.currentPlayer} hat den Stein auf der Position (${row}, ${column}) markiert`;
      } else if(this.selectedY == row && this.selectedX == column){
        this.selectedX = -1;
        this.selectedY = -1;
        this.stateString =
          `Spieler ${this.currentPlayer} hat seine Steinauswahl rückgängig gemacht`;
        return;
      }
      else {
        returnedDataFromMove = await this.movePiece(this.selectedY, this.selectedX, row, column);



        this.selectedX = -1;
        this.selectedY = -1;
      }
      return returnedDataFromMove
  }

  async checkAndRemoveOppBeaten(startX: number, startY: number, endX: number, endY: number, simulate: boolean, pBoard: number[][], pPlayerId: number): GamePiece | null {

      let board = this.board
      if(pBoard){
          board = pBoard
      }
      let playerId = this.currentPlayer
      if(pPlayerId){
          playerId = pPlayerId
      }
      let beatenPiece: GamePiece | null = null;

      // Nur wenn keine Felder übersprungen wurden, konnte niemand geschlagen werden
      if (Math.abs(startX - endX) === 1) {
        return null;
      }


      const jumpedFields: number[][] = await this.getJumpedFields(startX, startY, endX, endY);


      jumpedFields.forEach((element) => {
        //console.log('THIS FIELD WAS JUMPED', board[element[1]][element[0]], playerId, element[1], element[0])
        if (board[element[1]][element[0]]?.playerId !== playerId) {
          //console.log('GOT IF FOR SOME REASON')
          beatenPiece = board[element[1]][element[0]];
          if (!simulate) {


                    board[element[1]][element[0]] = null;




          }
        }
      });
      //console.log(beatenPiece, 'BEATENPIECE RETURN VALUE')
      return beatenPiece
    }

    getJumpedFields(startX: number, startY: number, endX: number, endY: number): number[][] {
       const visitedFields: number[][] = [];

       const deltaX = endX > startX ? 1 : -1; // Bestimmt die Richtung auf der X-Achse
       const deltaY = endY > startY ? 1 : -1; // Bestimmt die Richtung auf der Y-Achse

       let x = startX;
       let y = startY;

       // Bewegt sich, bis der Endpunkt erreicht ist
       while (x !== endX && y !== endY) {
         x += deltaX;
         y += deltaY;
         visitedFields.push([x, y]);
       }
       if (visitedFields.length > 0) {
         visitedFields.pop(); // Entfernt das letzte Element
       }

       return visitedFields;
     }

    async isValidMove(startX: number, startY: number, endX: number, endY: number, pBoard: number[][], playerOnTheMove: number): boolean {
        // ... Ihre Logik, um zu prüfen, ob ein Zug gültig ist ...

        //console.log('Is valid move is called')

        var board = this.board
        if(pBoard){
            board = pBoard
        }

        var currentPlayer = this.currentPlayer
        if(playerOnTheMove){
            currentPlayer = playerOnTheMove
        }



        if(startX < 0 || startX > 9 ||startY < 0 || startY > 9 || endX < 0 || endX > 9 ||endY < 0 || endY > 9){
            return false
        }

        let jumpedOwnPiecesOrAir = false;
        const jumpedFields: number[][] = await this.getJumpedFields(startX, startY, endX, endY);

        // Überprüfen, ob das Zielfeld frei ist
        if (board[endY][endX] !== null) {
          //console.log('VALID MOVE FEHLERCODE 1')
          this.stateString = 'Der Zielort muss ein freies Feld sein';
          return false;
        }

        // Überprüfen, ob nur diagonale Züge gemacht werden
        if (startX === endX || startY === endY) {
          //console.log('VALID MOVE FEHLERCODE 2')
          this.stateString = 'Es sind nur diagonale Züge erlaubt';
          return false;
        }

        // Überprüfen, ob der Sprung gleich weit in X und Y ist
        if (Math.abs(startX - endX) !== Math.abs(startY - endY)) {
          //console.log('VALID MOVE FEHLERCODE 3')
          this.stateString = 'Es sind nur diagonale Züge erlaubt';
          return false;
        }

        jumpedFields.forEach((element) => {
          if (board[element[1]][element[0]]?.playerId == currentPlayer) {
            jumpedOwnPiecesOrAir = true;
          }
        });
        // Need that for own pieces because Flutter FTW
        // Not jumping over a empty tile or a own piece
        if(jumpedOwnPiecesOrAir){
          //console.log('VALID MOVE FEHLERCODE 4')
          this.stateString = 'Man darf nur über Steine des Gegners springen Test';
          return false;
        }

        // FOR NON QUEENS
        if((board[startY][startX] != null && (!board[startY][startX]!.isQueen))){
          //If you try to move backwards
          if(((endY < startY) && currentPlayer == 1) || ((endY > startY) && currentPlayer == 2)){
            //console.log('VALID MOVE FEHLERCODE 5')
            this.stateString = 'Rückwärts laufen ist nur mit Damen erlaubt';
            return false;
          }

          // If the piece is not a queen it can not jump more than two
          if(board[startY][startX] != null && (!board[startY][startX]!.isQueen) && Math.abs(startX - endX) > 2){
            //console.log('VALID MOVE FEHLERCODE 6')
            this.stateString = 'Normale Steine können maximal zwei Felder springen';
            return false;
          }

          jumpedFields.forEach((element) => {
            if(board[element[1]][element[0]] == null){
              jumpedOwnPiecesOrAir = true;
            }
          });
          // Need that for own pieces because Flutter FTW
          // Not jumping over a empty tile or a own piece
          if(jumpedOwnPiecesOrAir){
            //console.log('VALID MOVE FEHLERCODE 7')
            this.stateString = 'Man darf nur über Steine des Gegners springen';
            return false;
          }
        // FOR QUEENS
        } else if((board[startY][startX] != null && (board[startY][startX]!.isQueen))){
          // Queen must be surrounded by enemy piece

          var counterOfOpponentPieces = 0;
          var foundOwnPiece = false;

          jumpedFields.forEach((element) => {
            if(board[element[1]][element[0]]?.playerId == (3 - currentPlayer)){
              counterOfOpponentPieces++;
            }
            if(board[element[1]][element[0]]?.playerId == currentPlayer){
              foundOwnPiece = true;
            }
          })

          if(counterOfOpponentPieces > 1){
            this.stateString = 'Man darf mit einer Dame nur über einen Gegnerstein springen';
            return false;
          }
          if(foundOwnPiece){
            this.stateString = 'Man darf mit einer Dame keine eigenen Steine überspringen';
            return false;
          }

          if((endY - 1 >= 0 && endX - 1 >= 0 && board[endY - 1][endX - 1]?.playerId != (3 - currentPlayer)) &&
              (endY - 1 >= 0 && endX + 1 < 10 && board[endY - 1][endX + 1]?.playerId != (3 - currentPlayer)) &&
              (endY + 1 < 10 && endX - 1 >= 0 && board[endY + 1][endX - 1]?.playerId != (3 - currentPlayer)) &&
              (endY + 1 < 10 && endX + 1 < 10 && board[endY + 1][endX + 1]?.playerId != (3 - currentPlayer)) &&
              await this.checkAndRemoveOppBeaten(startX, startY, endX, endY, true, board, currentPlayer) != null){
            this.stateString = 'Die Dame muss direkt um einen Gegner herum landen';
            return false;
          }
        }
        // IF ELIMINATION HAPPENS NO NEED TO CHECK IF MOVE IS VALID
        if(await this.checkAndRemoveOppBeaten(startX, startY, endX, endY, true, board, currentPlayer) != null){
          return true;
        }

        return true; // Ändern Sie dies, um die tatsächliche Prüfung widerzuspiegeln
    }

    checkWin(path: Move[]): boolean {
        let foundWhite = false;
        let foundBlack = false;

        let board = this.board.map(row => [...row])
        if(path){
            for(let move = path.length - 1; move >= 0; move--){
                board = this.applyMove(board, path[move])
            }
        }


        board.forEach((row) => {
          row.forEach((cell) => {
            if (cell?.playerId === 1) {
              foundWhite = true;
            }

            if (cell?.playerId === 2) {
              foundBlack = true;
            }
          })
        })


        if (!(foundBlack && foundWhite)) {
        }

        return !(foundBlack && foundWhite);
      }

    checkForQueenConv(): boolean {
        for (let i = 0; i < 10; i++) {
          if (this.board[0][i]?.playerId === 2) {
            if (this.board[0][i] !== null && !this.board[0][i].isQueen) {
              this.stateString = 'Spieler 2 hat eine neue Dame';
              this.board[0][i].promoteToQueen();
              return true;
            }
          }

          if (this.board[9][i]?.playerId === 1) {
            if (this.board[9][i] !== null && !this.board[9][i].isQueen) {
              this.stateString = 'Spieler 1 hat eine neue Dame';
              this.board[9][i].promoteToQueen();
              return true;
            }
          }
        }

        return false;
      }

  async findMovesWhichBeat(pBoard: number[][], playerOnTheMove: number): Move {

      let board = this.board
      if(pBoard){
          board = pBoard
      }

      //console.log(board)

      var currentPlayer = this.currentPlayer
      if(playerOnTheMove){
          currentPlayer = playerOnTheMove
      }

      //console.log(currentPlayer)

      var returnMove = new Move(null, -1, -1, -1, -1);
      // Überprüfen, ob eine Eliminierung möglich ist
        for(elementRow of board){
          for(elementItem of elementRow){
            //console.log('WHAT IS DIS????', elementItem, 'ON')
            if (elementItem && elementItem.playerId === currentPlayer) {
              const rowIndex = board.indexOf(elementRow);
              const itemIndex = elementRow.indexOf(elementItem);
              //console.log(rowIndex, itemIndex)
              if(!board[rowIndex][itemIndex].isQueen){
                // Teste verschiedene Richtungen

                if (rowIndex + 2 < 10 && itemIndex + 2 < 10) {
                  if (await this.isValidMove(itemIndex, rowIndex, itemIndex + 2, rowIndex + 2)) {

                      var tempPiece = await this.checkAndRemoveOppBeaten(itemIndex, rowIndex, itemIndex + 2, rowIndex + 2, true, board, currentPlayer)
                      var returnedPiece = await this.checkToChangeReturningPiece(returnMove.getPiece(), tempPiece);
                      if(returnedPiece != null && returnedPiece.isQueen){
                        return new Move(returnedPiece, itemIndex + 2, rowIndex + 2, itemIndex, rowIndex);
                      } else if(returnedPiece != null){
                        returnMove = new Move(returnedPiece, itemIndex + 2, rowIndex + 2, itemIndex, rowIndex);
                      }
                  }
                }

                if (rowIndex + 2 < 10 && itemIndex - 2 >= 0) {
                  if (await this.isValidMove(itemIndex, rowIndex, itemIndex - 2, rowIndex + 2)) {
                     var tempPiece = await this.checkAndRemoveOppBeaten(itemIndex, rowIndex, itemIndex - 2, rowIndex + 2, true, board, currentPlayer)
                     var returnedPiece = await this.checkToChangeReturningPiece(returnMove.getPiece(), tempPiece);
                     if(returnedPiece != null && returnedPiece.isQueen){
                         return new Move(returnedPiece, itemIndex - 2, rowIndex + 2, itemIndex, rowIndex);
                     } else if(returnedPiece != null){
                         returnMove = new Move(returnedPiece, itemIndex - 2, rowIndex + 2, itemIndex, rowIndex);
                     }
                  }
                }
                if (rowIndex - 2 >= 0 && itemIndex - 2 >= 0) {
                  if (await this.isValidMove(itemIndex, rowIndex, itemIndex - 2, rowIndex - 2)) {
                    var tempPiece = await this.checkAndRemoveOppBeaten(itemIndex, rowIndex, itemIndex - 2, rowIndex - 2, true, board, currentPlayer)
                    var returnedPiece = await this.checkToChangeReturningPiece(returnMove.getPiece(), tempPiece);
                    if(returnedPiece != null && returnedPiece.isQueen){
                      return new Move(returnedPiece, itemIndex - 2, rowIndex - 2, itemIndex, rowIndex);
                    } else if(returnedPiece != null){
                      returnMove = new Move(returnedPiece, itemIndex - 2, rowIndex - 2, itemIndex, rowIndex);
                    }
                  }
                }
                if (rowIndex - 2 >= 0 && itemIndex + 2 < 10) {
                  if (await this.isValidMove(itemIndex, rowIndex, itemIndex + 2, rowIndex - 2)) {
                    var tempPiece = await this.checkAndRemoveOppBeaten(itemIndex, rowIndex, itemIndex + 2, rowIndex - 2, true, board, currentPlayer)
                    var returnedPiece = await this.checkToChangeReturningPiece(returnMove.getPiece(), tempPiece);
                    if(returnedPiece != null && returnedPiece.isQueen){
                      return new Move(returnedPiece, itemIndex + 2, rowIndex - 2, itemIndex, rowIndex);
                    } else if(returnedPiece != null){
                      returnMove = new Move(returnedPiece, itemIndex + 2, rowIndex - 2, itemIndex, rowIndex);
                    }
                  }
                }

              } else {
                  for(var i = 2; i < 10; i++){
                      if((rowIndex + i) < 10 && (itemIndex + i) < 10 && !returnMove.getPiece()){
                          if (await this.isValidMove(itemIndex, rowIndex, itemIndex + i, rowIndex + i)) {
                            var tempPiece = await this.checkAndRemoveOppBeaten(itemIndex, rowIndex, itemIndex + i, rowIndex + i, true, board, currentPlayer)
                            var returnedPiece = await this.checkToChangeReturningPiece(returnMove.getPiece(), tempPiece);
                            if(returnedPiece != null && returnedPiece.isQueen){
                              return new Move(returnedPiece, itemIndex + i, rowIndex + i, itemIndex, rowIndex);
                            } else if(returnedPiece != null){
                              returnMove = new Move(returnedPiece, itemIndex + i, rowIndex + i, itemIndex, rowIndex);
                            }
                          }
                      }
                      if((rowIndex - i) >= 0 && (itemIndex - i) >= 0 && !returnMove.getPiece()){
                          if (await this.isValidMove(itemIndex, rowIndex, itemIndex - i, rowIndex - i)) {
                            var tempPiece = await this.checkAndRemoveOppBeaten(itemIndex, rowIndex, itemIndex - i, rowIndex - i, true, board, currentPlayer)
                            var returnedPiece = await this.checkToChangeReturningPiece(returnMove.getPiece(), tempPiece);
                            if(returnedPiece != null && returnedPiece.isQueen){
                              return new Move(returnedPiece, itemIndex - i, rowIndex - i, itemIndex, rowIndex);
                            } else if(returnedPiece != null){
                              returnMove = new Move(returnedPiece, itemIndex - i, rowIndex - i, itemIndex, rowIndex);
                            }
                          }
                      }

                      if((rowIndex - i) >= 0 && (itemIndex + i) < 10 && !returnMove.getPiece()){
                          if (await this.isValidMove(itemIndex, rowIndex, itemIndex + i, rowIndex - i)) {
                            var tempPiece = await this.checkAndRemoveOppBeaten(itemIndex, rowIndex, itemIndex + i, rowIndex - i, true, board, currentPlayer)
                            var returnedPiece = await this.checkToChangeReturningPiece(returnMove.getPiece(), tempPiece);
                            if(returnedPiece != null && returnedPiece.isQueen){
                              return new Move(returnedPiece, itemIndex + i, rowIndex - i, itemIndex, rowIndex);
                            } else if(returnedPiece != null){
                              returnMove = new Move(returnedPiece, itemIndex + i, rowIndex - i, itemIndex, rowIndex);
                            }
                          }
                      }

                      if((rowIndex + i) < 10 && (itemIndex - i) >= 0 && !returnMove.getPiece()){
                          if (await this.isValidMove(itemIndex, rowIndex, itemIndex - i, rowIndex + i)) {
                            var tempPiece = await this.checkAndRemoveOppBeaten(itemIndex, rowIndex, itemIndex - i, rowIndex + i, true, board, currentPlayer)
                            var returnedPiece = await this.checkToChangeReturningPiece(returnMove.getPiece(), tempPiece);
                            if(returnedPiece != null && returnedPiece.isQueen){
                              return new Move(returnedPiece, itemIndex - i, rowIndex + i, itemIndex, rowIndex);
                            } else if(returnedPiece != null){
                              returnMove = new Move(returnedPiece, itemIndex - i, rowIndex + i, itemIndex, rowIndex);
                            }
                          }
                      }
                  }
              }
            }
          }
        }
        //console.log(returnMove)
        return returnMove;
    };


       resetGame(): void {
           this.board = Array.from({ length: 10 }, () => Array(10).fill(null));

           this.currentPlayer = 1;

           // Setzen der Startpositionen der Spielsteine
           for (let i = 0; i < 4; i++) {
             for (let j = (i % 2); j < 9; j += 2) {
               this.board[i][j + 1] = new GamePiece(1);
               this.board[9 - i][j] = new GamePiece(2);
             }
           }

           this.board[1][0] = new GamePiece(1);
           this.board[3][0] = new GamePiece(1);
           this.board[6][9] = new GamePiece(2);
           this.board[8][9] = new GamePiece(2);
           this.stateString = 'Spieler 1 ist an der Reihe';

           // Benachrichtigen aller Listener (falls erforderlich)
           // ...
       }

    checkToChangeReturningPiece(returnPiece, tempPiece): GamePiece | null {
        if (returnPiece == null) {
          return tempPiece;
        } else if(!returnPiece.isQueen && tempPiece != null){
          return tempPiece;
        } else if(tempPiece != null && tempPiece.isQueen){
          return tempPiece;
        }
      }
  // Weitere Methoden wie Überprüfung auf gültige Züge, Überprüfung der Gewinnbedingungen usw.

  async simulateComputerMove(): void {
    return new Promise(async (resolve, reject) => {
        try{
            // Find moves which beat mit jedem Stein
                      for(const row in this.board){
                          for(const piece in this.board[row]){
                              // finds 'ideal' piece to move, returns null if no piece beats
                              const optimalMove = await this.findMovesWhichBeat();
                              //console.log('Optimal move', optimalMove)
                              // Makes ideal move if possible
                              if(optimalMove.getPiece() != null){
                                  await this.movePiece(optimalMove.getStartY(), optimalMove.getStartX(), optimalMove.getEndY(), optimalMove.getEndX())
                                  resolve();
                                  return;
                              }

                              // Create crowned piece if possible
                              for(var i = 0; i <= 9; i++){
                                if(this.board[1][i] && this.board[1][i].playerId == 2 && i-1 >= 0 && !this.board[0][i-1] && !this.board[1][i].isQueen){
                                    await this.movePiece(1, i, 0, i-1)
                                    resolve();
                                    return;
                                } else if(this.board[1][i] && this.board[1][i].playerId == 2 && i+1 <= 9 && !this.board[0][i+1] && !this.board[1][i].isQueen){
                                    await this.movePiece(1, i, 0, i+1)
                                    resolve();
                                    return;
                                }
                              }

                              // Makes random move which is not made from baseline
                              // Make move away from potential danger
                              for(var i = 0; i <= 8; i++){
                                  for(var j = 0; j <= 9; j++){
                                      if(this.board[i][j] && this.board[i][j].playerId == 2 && !this.board[i][j].isQueen){
                                          if(i-1 >= 0 && j+1 <= 9 && !this.board[i-1][j+1] &&
                                                  (i-2 >= 0 && (!this.board[i-2][j] || this.board[i-2][j].playerId == 2)) &&
                                                  (i-2 >= 0 && j+2 <= 9 && (!this.board[i-2][j+2] || this.board[i-2][j+2].playerId == 2))){
                                              await this.movePiece(i, j, i-1, j+1)

                                              resolve();
                                              return;
                                          } else if(i-1 >= 0 && j-1 >= 0 && !this.board[i-1][j-1] &&
                                                  (i-2 >= 0 && (!this.board[i-2][j] || this.board[i-2][j].playerId == 2)) &&
                                                  (i-2 >= 0 && j-2 >= 0 && (!this.board[i-2][j-2] || this.board[i-2][j-2].playerId == 2))){
                                              await this.movePiece(i, j, i-1, j-1)

                                              resolve();
                                              return;
                                          }
                                      }
                                  }
                              }

                              // Makes random move which is not made from baseline
                              for(var i = 0; i <= 8; i++){
                                  for(var j = 0; j <= 9; j++){
                                      if(this.board[i][j] && this.board[i][j].playerId == 2 && !this.board[i][j].isQueen){
                                          if(i-1 >= 0 && j+1 <= 9 && !this.board[i-1][j+1]){
                                              await this.movePiece(i, j, i-1, j+1)

                                              resolve();
                                              return;
                                          } else if(i-1 >= 0 && j-1 >= 0 && !this.board[i-1][j-1]){
                                              await this.movePiece(i, j, i-1, j-1)

                                              resolve();
                                              return;
                                          }
                                      }
                                  }
                              }

                              // Makes random move with dame
                              for(var i = 0; i <= 8; i++){
                                  for(var j = 0; j <= 9; j++){
                                      if(this.board[i][j] && this.board[i][j].playerId == 2 && this.board[i][j].isQueen){
                                          for(var k = 1; k <= 9; k++){
                                                  var surroundedByDanger1 = await this.surroundedByDanger(i-k, j+k, i, j)
                                                  if(await this.isValidMove(j, i, j+k, i-k) && !surroundedByDanger1){
                                                      await this.movePiece(i, j, i-k, j+k)

                                                      resolve();
                                                      return;
                                                  }
                                                  var surroundedByDanger2 = await this.surroundedByDanger(i-k, j+k, i, j)
                                                  if(await this.isValidMove(j, i, j-k, i-k) && !surroundedByDanger2){
                                                      await this.movePiece(i, j, i-k, j-k)

                                                      resolve();
                                                      return;
                                                  }
                                                  var surroundedByDanger3 = await this.surroundedByDanger(i+k, j-k, i, j)
                                                  if(await this.isValidMove(j, i, j-k, i+k) && !surroundedByDanger3){
                                                      await this.movePiece(i, j, i+k, j-k)

                                                      resolve();
                                                      return;
                                                  }
                                                  var surroundedByDanger4 = await this.surroundedByDanger(i+k, j+k, i, j)
                                                  if(await this.isValidMove(j, i, j+k, i+k) && !surroundedByDanger4){
                                                      await this.movePiece(i, j, i+k, j+k)

                                                      resolve();
                                                      return;
                                                  }

                                          }
                                      }
                                  }
                              }

                              // Makes random move with dame
                              for(var i = 0; i <= 8; i++){
                                  for(var j = 0; j <= 9; j++){
                                      if(this.board[i][j] && this.board[i][j].playerId == 2 && this.board[i][j].isQueen){
                                          for(var k = 1; i+k <= 9 || i-k >= 0 || j+k <= 9 || j-k >= 0; k++){
                                              if(i-k >= 0 && j+k <= 9 && !this.board[i-k][j+k]){
                                                  await this.movePiece(i, j, i-k, j+k)

                                                  resolve();
                                                  return;
                                              } else if(i-k >= 0 && j-k >= 0 && !this.board[i-k][j-k]){
                                                  await this.movePiece(i, j, i-k, j-k)

                                                  resolve();
                                                  return;
                                              } else if(i+k <= 9 && j-k >= 0 && !this.board[i+k][j-k]){
                                                  await this.movePiece(i, j, i+k, j-k)

                                                  resolve();
                                                  return;
                                              } else if(i+k <= 9 && j+k <= 9 && !this.board[i+k][j+k]){
                                                  await this.movePiece(i, j, i+k, j+k)

                                                  resolve();
                                                  return;
                                              }
                                          }
                                      }
                                  }
                              }

                              // Make move from baseline
                              var startY = 9
                              for(var i = 0; i <= 9; i++){
                                  if(this.board[9][i] && this.board[9][i].playerId == 2){
                                      if(i+1 <= 9 && !this.board[8][i+1]){
                                          await this.movePiece(9, i, 8, i+1)

                                          resolve();
                                          return;
                                      } else if(i+1 >= 0 && !this.board[8][i-1]){
                                          await this.movePiece(9, i, 8, i-1)

                                          resolve();
                                          return;
                                      }
                                  }
                              }
                              // Make random queen move
                          }
                      }

        } catch(err) {
            reject(error)
        }
                    // Make the move
          // Change the player, whcih actually already when executing move i guess

        })

    // Weitere Methoden wie Überprüfung auf gültige Züge, Überprüfung der Gewinnbedingungen usw.
  }

  surroundedByDanger(rowIndex: int, columnIndex: int, startRow: int, startColumn: int): boolean {


    // Checks if piece is could be normally beaten
    if(columnIndex + 1 <= 9 && rowIndex - 1 >= 0 && this.board[rowIndex - 1][columnIndex + 1] &&
            this.board[rowIndex - 1][columnIndex + 1].playerId == (3-this.currentPlayer) &&
            !this.board[rowIndex - 1][columnIndex + 1].isQueen &&
            columnIndex - 1 >= 0 && rowIndex + 1 <= 9 &&
            (!this.board[rowIndex + 1][columnIndex - 1] || (rowIndex + 1 == startRow && columnIndex - 1 == startColumn))){
        return true;

    }else if(columnIndex - 1 >= 0 && rowIndex - 1 >= 0 && this.board[rowIndex - 1][columnIndex - 1] &&
            this.board[rowIndex - 1][columnIndex - 1].playerId == (3-this.currentPlayer) &&
            !this.board[rowIndex - 1][columnIndex - 1].isQueen &&
            columnIndex + 1 <= 9 && rowIndex + 1 <= 9 &&
             (!this.board[rowIndex + 1][columnIndex + 1] || (rowIndex + 1 == startRow && columnIndex + 1 == startColumn))){
        return true;
    }

    var pieceFoundUpLeft: bool = false
    var pieceFoundUpRight: bool = false
    var pieceFoundDownLeft: bool = false
    var pieceFoundDownRight: bool = false
    var maxIndex: int = -1
    if(columnIndex > rowIndex){
        maxIndex = columnIndex
    } else {
        maxIndex = rowIndex
    }

    for(var k = 1; k + maxIndex <= 9; k++){
        if(0 <= rowIndex + k && rowIndex + k <= 9 && 0 <= columnIndex + k && columnIndex + k <= 9
                && rowIndex + k != startRow && columnIndex + k != startColumn
                && this.board[rowIndex + k][columnIndex + k]
                && this.board[rowIndex + k][columnIndex + k].playerId == (3-this.currentPlayer)
                && this.board[rowIndex + k][columnIndex + k].isQueen
                && !pieceFoundDownRight){
            return true
        } else if(0 <= rowIndex + k && rowIndex + k <= 9 && 0 <= columnIndex + k && columnIndex + k <= 9
                && rowIndex + k != startRow && columnIndex + k != startColumn
                && this.board[rowIndex + k][columnIndex + k]){
            pieceFoundDownRight = true;
        } else {
        }
        if(9 >= rowIndex - k && rowIndex - k >= 0 && 0 <= columnIndex + k && columnIndex + k <= 9
                && rowIndex - k != startRow && columnIndex + k != startColumn
                && this.board[rowIndex - k][columnIndex + k]
                && this.board[rowIndex - k][columnIndex + k].playerId == (3-this.currentPlayer)
                && this.board[rowIndex - k][columnIndex + k].isQueen
                && !pieceFoundUpRight){
            return true
        } else if(9 >= rowIndex - k && rowIndex - k >= 0 && 0 <= columnIndex + k && columnIndex + k <= 9
                && rowIndex - k != startRow && columnIndex + k != startColumn
                && this.board[rowIndex - k][columnIndex + k]){
            pieceFoundUpRight = true;
        } else {
        }

        if(0 <= rowIndex + k && rowIndex + k <= 9 && 9 >= columnIndex - k && columnIndex - k >= 0
                    && rowIndex + k != startRow && columnIndex - k != startColumn
                    && this.board[rowIndex + k][columnIndex - k]
                    && this.board[rowIndex + k][columnIndex - k].playerId == (3-this.currentPlayer)
                    && this.board[rowIndex + k][columnIndex - k].isQueen
                    && !pieceFoundDownLeft){
            return true
        } else if(0 <= rowIndex + k && rowIndex + k <= 9 && 9 >= columnIndex - k && columnIndex - k >= 0
                && rowIndex + k != startRow && columnIndex - k != startColumn
                && this.board[rowIndex + k][columnIndex - k]){
            pieceFoundDownLeft = true;
        } else {
        }

        if(9 >= rowIndex - k && rowIndex - k >= 0 && 9 >= columnIndex - k && columnIndex - k >= 0
                && rowIndex - k != startRow && columnIndex - k != startColumn
                && this.board[rowIndex - k][columnIndex - k]
                && this.board[rowIndex - k][columnIndex - k].playerId == (3-this.currentPlayer)
                && this.board[rowIndex - k][columnIndex - k].isQueen
                && !pieceFoundUpLeft){
            return true
        } else if(9 >= rowIndex - k && rowIndex - k >= 0 && 9 >= columnIndex - k && columnIndex - k >= 0
                && rowIndex - k != startRow && columnIndex - k != startColumn
                && this.board[rowIndex - k][columnIndex - k]){
            pieceFoundUpLeft = true;
        } else {
        }
    }

    return false;
  }

  async simulateComputerMoveWithMiniMax(){
        return new Promise(async (resolve, reject) => {
            try{
                // Find moves which beat mit jedem Stein
                const optimalMove = await this.findMovesWhichBeat();
                //console.log('Optimal move', optimalMove)
                // Makes ideal move if possible
                if(optimalMove.getPiece() != null){
                    await this.movePiece(optimalMove.getStartY(), optimalMove.getStartX(), optimalMove.getEndY(), optimalMove.getEndX())
                    resolve();
                    return;
                } else {
                    var boardCopy = this.board.map(row => [...row])
                    this.minimax(boardCopy, 3, -1000000000000, 1000000000000, true, []).then((minimaxRes) => {
                        for(node in minimaxRes.path){
                            //console.log(minimaxRes.path[node].getPiece())
                        }
                        if(minimaxRes.path.length > 0){
                            //console.log(minimaxRes.path, 'PATH')
                            //console.log(minimaxRes, ' is FINAL RESULT', minimaxRes.path[minimaxRes.path.length - 1].getStartY(), minimaxRes.path[minimaxRes.path.length - 1].getStartX()
                            //    , minimaxRes.path[minimaxRes.path.length - 1].getEndY(), minimaxRes.path[minimaxRes.path.length - 1].getEndX())
                            this.movePiece(minimaxRes.path[minimaxRes.path.length - 1].getStartY(), minimaxRes.path[minimaxRes.path.length - 1].getStartX(),
                                minimaxRes.path[minimaxRes.path.length - 1].getEndY(), minimaxRes.path[minimaxRes.path.length - 1].getEndX())
                            .then(() => {
                                resolve()
                            })
                        } else {
                            console.log('Path was empty')
                        }


                    })

                    //console.log(minimaxRes, ' is FINAL RESULT')

                }




                // Make random queen move


            } catch(err) {
                let minimaxRes = await this.minimax(boardCopy, 2, -1000000000000, 1000000000000, true, [])
                await this.movePiece(minimaxRes.path[minimaxRes.path.length - 1].getStartY(), minimaxRes.path[minimaxRes.path.length - 1].getStartX(),
                                        minimaxRes.path[minimaxRes.path.length - 1].getEndY(), minimaxRes.path[minimaxRes.path.length - 1].getEndX())
            }
                        // Make the move
              // Change the player, whcih actually already when executing move i guess

            })

        // Weitere Methoden wie Überprüfung auf gültige Züge, Überprüfung der Gewinnbedingungen usw.
      }


  async generateMoves(path: Move[], isMaxPlayer: boolean): Move[] {
    possibleMoves = []

    let playerGeneratingFor = 1
    if(isMaxPlayer){
        playerGeneratingFor = 2
    }

    let currentBoard = this.board.map(row => [...row])

    for(let move = path.length - 1; move >= 0; move--){
        currentBoard = await this.applyMove(currentBoard, path[move])
    }

    let beatingMoveExists = false
    //console.log('FIND BEATING MOVES', playerGeneratingFor, 'WIT PATH', path)
    let beatingMove = await this.findMovesWhichBeat(currentBoard, playerGeneratingFor)
    //console.log(beatingMove, 'MOVE')
    let beatingPiece = beatingMove.getPiece()
    //console.log(beatingPiece, 'PIECE')
    if(beatingPiece){
        //console.log('BEATING MOVE FOUND', beatingMove)
        beatingMoveExists = true
    }
    for(row in currentBoard){
        //console.log(currentBoard[row], 'Row', row, 'of board')
    }
    for(var row = 0; row < 10; row++){
      for(var col = 0; col < 10; col++){
          var piece = currentBoard[row][col]

          //console.log(piece, 'PIECE FROM GENERATE MOVES IS AT', row, col)
          if(piece){

            // For Player 1 ~ means Player = false
            if(!piece.isQueen && piece.playerId == playerGeneratingFor && playerGeneratingFor == 2){
              if(await this.isValidMove(col, row, Number(col) + 1, Number(row) - 1, currentBoard, 2)){
                if(!beatingMoveExists || (beatingMoveExists && await this.checkAndRemoveOppBeaten(col, row, Number(col) + 1, Number(row) - 1, true, currentBoard, playerGeneratingFor))){
                    possibleMoves.push(new Move(piece, Number(col) + 1, Number(row) - 1, col, row))
                } else {
                    //console.log('BEATING MOVES BLOCKED + - 1')
                }
              } else {
                //console.log('VALID MOVES SAGT NEIN + - 1')
              }
              if(await this.isValidMove(col, row, Number(col) - 1, Number(row) - 1, currentBoard, 2)){
                if(!beatingMoveExists || (beatingMoveExists && await this.checkAndRemoveOppBeaten(col, row, Number(col) - 1, Number(row) - 1, true, currentBoard, playerGeneratingFor))){
                    possibleMoves.push(new Move(piece, Number(col) - 1, Number(row) - 1, col, row))
                }else {
                     //console.log('BEATING MOVES BLOCKED - - 1')
                 }
               } else {
                 //console.log('VALID MOVES SAGT NEIN - - 1')

              }
              if(await this.isValidMove(col, row, Number(col) + 2, Number(row) - 2, currentBoard, 2)){
                if(!beatingMoveExists || (beatingMoveExists && await this.checkAndRemoveOppBeaten(col, row, Number(col) + 2, Number(row) - 2, true, currentBoard, playerGeneratingFor))){
                    possibleMoves.push(new Move(piece, Number(col) + 2, Number(row) - 2, col, row))
                }else {
                    //console.log('BEATING MOVES BLOCKED + - 2')
                }
              } else {
                //console.log('VALID MOVES SAGT NEIN + - 2')

              }
              if(await this.isValidMove(col, row, Number(col) - 2, Number(row) - 2, currentBoard, 2)){
                if(!beatingMoveExists || (beatingMoveExists && await this.checkAndRemoveOppBeaten(col, row, Number(col) - 2, Number(row) - 2, true, currentBoard, playerGeneratingFor))){
                    possibleMoves.push(new Move(piece, Number(col) - 2, Number(row) - 2, col, row))
                } else {
                      //console.log('BEATING MOVES BLOCKED - - 2')
                }
              } else {
                  //console.log('VALID MOVES SAGT NEIN - - 2')

              }
            } else if(!piece.isQueen && piece.playerId == playerGeneratingFor && playerGeneratingFor == 1) {
                //console.log('GENERATING FOR PLAYER 1')
              if(await this.isValidMove(col, row, Number(col) + 1, Number(row) + 1, currentBoard, 1)){
                if(!beatingMoveExists || (beatingMoveExists && await this.checkAndRemoveOppBeaten(col, row, Number(col) + 1, Number(row) + 1, true, currentBoard, playerGeneratingFor))){
                    //console.log('ADDED MOVES')
                    possibleMoves.push(new Move(piece, Number(col) + 1, Number(row) + 1, col, row))
                }else {
                   //console.log('BEATING MOVES BLOCKED + + 1')
                }
              } else {
                //console.log('VALID MOVES SAGT NEIN + + 1'
              }
              if(await this.isValidMove(col, row, Number(col) - 1, Number(row) + 1, currentBoard, 1)){
                //console.log('Simple billo check', currentBoard[6][4])
                if(!beatingMoveExists || (beatingMoveExists && await this.checkAndRemoveOppBeaten(col, row, Number(col) - 1, Number(row) + 1, true, currentBoard, playerGeneratingFor))){
                    //console.log('ADDED MOVES')
                    possibleMoves.push(new Move(piece, Number(col) - 1, Number(row) + 1, col, row))
                }else {
                    //console.log('BEATING MOVES BLOCKED - + 1')
                }
              } else {
                   //console.log('VALID MOVES SAGT NEIN - + 1')
              }
              if(await this.isValidMove(col, row, Number(col) + 2, Number(row) + 2, currentBoard, 1)){
                if(!beatingMoveExists || (beatingMoveExists && await this.checkAndRemoveOppBeaten(col, row, Number(col) + 2, Number(row) + 2, true, currentBoard, playerGeneratingFor))){
                    //console.log('ADDED MOVES')
                    possibleMoves.push(new Move(piece, Number(col) + 2, Number(row) + 2, col, row))
                }else {
                    //console.log('BEATING MOVES BLOCKED + + 2')
                }
              } else {
                //console.log('VALID MOVES SAGT NEIN + + 2', col, row, Number(col) + 2, Number(row) + 2)
              }
              if(await this.isValidMove(col, row, Number(col) - 2, Number(row) + 2, currentBoard, 1)){
                //console.log(!beatingMoveExists, beatingMoveExists ,this.checkAndRemoveOppBeaten(col, row, Number(col) - 2, Number(row) + 2, true, currentBoard, playerGeneratingFor))
                if(!beatingMoveExists || (beatingMoveExists && await this.checkAndRemoveOppBeaten(col, row, Number(col) - 2, Number(row) + 2, true, currentBoard, playerGeneratingFor))){
                    //console.log('ADDED MOVES')
                    possibleMoves.push(new Move(piece, Number(col) - 2, Number(row) + 2, col, row))
                }else {
                    //console.log('BEATING MOVES BLOCKED - + 2')
                }
              } else {
                //console.log('VALID MOVES SAGT NEIN - + 2', col, row, Number(col) - 2, Number(row) + 2)
              }
            } else if(piece.isQueen && piece.playerId == playerGeneratingFor) {
              for(var i = 1; i < 10; i++){
                if(Number(col) - i >= 0 && row + i < 10 && await this.isValidMove(col, row, Number(col) - i, Number(row) + i, currentBoard, playerGeneratingFor)){
                  if(!beatingMoveExists || (beatingMoveExists && await this.checkAndRemoveOppBeaten(col, row, Number(col) - i, Number(row) + i, true, currentBoard, playerGeneratingFor))){
                      possibleMoves.push(new Move(piece, Number(col) - i, Number(row) + i, col, row))
                  }
                }
                if(Number(col) - i >= 0 && row - i >= 0 && await this.isValidMove(col, row, Number(col) - i, Number(row) - i, currentBoard, playerGeneratingFor)){
                  if(!beatingMoveExists || (beatingMoveExists && await this.checkAndRemoveOppBeaten(col, row, Number(col) - i, Number(row) - i, true, currentBoard, playerGeneratingFor))){
                      possibleMoves.push(new Move(piece, Number(col) - i, Number(row) - i, col, row))
                  }
                }
                if(Number(col) + i < 10 && row + i < 10 && await this.isValidMove(col, row, Number(col) + i, Number(row) + i, currentBoard, playerGeneratingFor)){
                  if(!beatingMoveExists || (beatingMoveExists && await this.checkAndRemoveOppBeaten(col, row, Number(col) + i, Number(row) + i, true, currentBoard, playerGeneratingFor))){
                      possibleMoves.push(new Move(piece, Number(col) + i, Number(row) + i, col, row))
                  }
                }
                if(Number(col) + i < 10 && row - i >= 0 && await this.isValidMove(col, row, Number(col) + i, Number(row) - i, currentBoard, playerGeneratingFor)){
                  if(!beatingMoveExists || (beatingMoveExists && await this.checkAndRemoveOppBeaten(col, row, Number(col) + i, Number(row) - i, true, currentBoard, playerGeneratingFor))){
                      possibleMoves.push(new Move(piece, Number(col) + i, Number(row) - i, col, row))
                  }
                }
              }
            }
          }

          // Make random queen move
      }
    }
    for(move in possibleMoves){
        //console.log(move, ':', JSON.stringify(possibleMoves[move]) + '\n')
    }

    let foundCleanMoves = []

    for(move in possibleMoves){
        let moveInQ = await this.checkAndRemoveOppBeaten(possibleMoves[move].getStartX(), possibleMoves[move].getStartY(), possibleMoves[move].getEndX(), possibleMoves[move].getEndY(), true, currentBoard, playerGeneratingFor)
        if(moveInQ){
            //console.log('SETTING BOOL TRUE BECAUSE OF', possibleMoves[move])
            foundCleanMoves.push(new Move(possibleMoves[move].getPiece(), possibleMoves[move].getEndX(), possibleMoves[move].getEndY(), possibleMoves[move].getStartX(), possibleMoves[move].getStartY()))
        }
    }

    if(foundCleanMoves.length > 0){
        return foundCleanMoves
    } else {
        return possibleMoves
    }
  }

  applyMove(board: number[][], move: Move): number[][] {

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


      const piece = board[move.getStartY()][move.getStartX()];
      board[move.getEndY()][move.getEndX()] = piece;
      //console.log(board[move.getEndY()][move.getEndX()], ' Moved piece at new location')
      board[move.getStartY()][move.getStartX()] = null;
      //console.log(board[move.getStartY()][move.getStartX()], ' Content of old location')

      return board

      //const beatenPiece = this.checkAndRemoveOppBeaten(startCol, startRow, endCol, endRow, false);

  }

  async evaluateState(path: Move[]): number {


    let evaluationBoardCopy = this.board.map(row => [...row])
    let returnValueForBeat = 0
    let boardScore = 0
    let alreadyBeatenFound = false
    //console.log('EVAL PATH', path)


    // Apply first move of simulation, which will be a maxi move
    for(let move = path.length - 1; move >= 0; move--){
        evaluationBoardCopy = await this.applyMove(evaluationBoardCopy, path[move])
        let potBeatenPiece = await this.checkAndRemoveOppBeaten(path[move].getStartX(), path[move].getStartY(), path[move].getEndX(), path[move].getEndY(), true,  evaluationBoardCopy, (path[move].getPiece().playerId))

        //console.log(potBeatenPiece, 'POT BEATEN PIECE')
        if(potBeatenPiece && potBeatenPiece.playerId == 1 && !alreadyBeatenFound){
            //console.log(path[move], 'gives us infinity')
            alreadyBeatenFound = true
            return 1000000000000

        } else if(potBeatenPiece && potBeatenPiece.playerId == 2 && !alreadyBeatenFound){
            //console.log(path[move], 'gives us negative infinity')
            alreadyBeatenFound = true
            return -1000000000000

        }
    }

    for(const row in evaluationBoardCopy){
        for(const col in evaluationBoardCopy[row]){
            const piece = evaluationBoardCopy[row][col]
            if(piece){

                let colValue = 0
                let rowValue = 9 - row
                let addValue = 0
                let subValue = 0

                if(rowValue == 0){
                    rowValue = 35
                } else if(row == 1){
                    rowValue == 1
                } else if(row == 2){
                    rowValue == 2
                } else if(row == 3){
                    rowValue == 4
                } else if(row == 4){
                    rowValue == 7
                } else if(row == 5){
                    rowValue == 11
                } else if(row == 6){
                    rowValue == 16
                }else if(row == 7){
                    rowValue == 22
                }else if(row == 8){
                    rowValue == 29
                }else if(row == 9){
                    rowValue == 37
                }

                if(col < 5){
                    colValue = Math.abs(5 - col)
                } else {
                    colValue = Math.abs(4 - col)
                }

                if(row - 1 >= 0 && col -1 >= 0 && (!evaluationBoardCopy[row - 1][col - 1] || evaluationBoardCopy[row - 1][col - 1].playerId == 2)){
                    addValue++
                }
                if(row - 1 >= 0 && col +1 < 10 && (!evaluationBoardCopy[row - 1][col + 1] || evaluationBoardCopy[row - 1][col + 1].playerId == 2)){
                    addValue++
                }

                if(row - 1 >= 0 && col - 1 >= 0 && col + 1 < 10 && (evaluationBoardCopy[row - 1][col - 1] && evaluationBoardCopy[row - 1][col - 1].playerId == 1 &&
                         !evaluationBoardCopy[row + 1][col + 1])){
                    subValue = subValue - 10
                }
                if(row - 1 >= 0 && col + 1 < 10 && col - 1 >= 0 && (evaluationBoardCopy[row - 1][col + 1] && evaluationBoardCopy[row - 1][col + 1].playerId == 1 &&
                        !evaluationBoardCopy[row + 1][col - 1])){
                    subValue = subValue - 10
                }

                boardScore = boardScore + (colValue + rowValue + addValue + subValue)
            }



        }
    }
    return boardScore
  }

  async minimax(state: number[][], depth: number, alpha: number, beta: number, isMaximizingPlayer: boolean, path: Move[]): MinimaxResult {
      if (depth === 0 || await this.checkWin(path)) {
          var evalEstimate = await this.evaluateState(path)
          //console.log(path, evalEstimate)
          return {score: evalEstimate, path: path};
      }

      let newState = state.map(row => [...row])

      if (isMaximizingPlayer) {
          let maxEval: MinimaxResult = { score: -1100000000000, path: [] };
          for (const move of await this.generateMoves(path, true)) {
              //console.log('CURRENT MOVE', move)
              let tempState = newState.map(row => [...row])
              const value = await this.minimax(await this.applyMove(tempState, move), depth - 1, alpha, beta, false, [move].concat(path));
              //console.log(path, 'Current path')
              if (value.score >= maxEval.score) {
                  maxEval.score = value.score;
                  maxEval.path = value.path; // Prepend this move to the path leading to the best score
              }
              //alpha = Math.max(alpha, value.score);
              /**
              if (beta <= alpha) {
                  break;
              }
              */

          }
          return maxEval;
      } else {
          let minEval: MinimaxResult = { score: 1100000000000, path: [] };
          for (const move of await this.generateMoves(path, false)) {
              //console.log('CURRENT MOVE', move)
              let tempState = newState.map(row => [...row])
              const value = await this.minimax(await this.applyMove(tempState, move), depth - 1, alpha, beta, true, [move].concat(path));
              if (value.score <= minEval.score) {
                  minEval.score = value.score;
                  minEval.path = value.path; // Prepend this move to the path
              }
              //beta = Math.min(beta, value.score);
              /**
              if (beta <= alpha) {
                  break;
              }
              */
          }
          return minEval;
      }

    }

}


class Move{

    piece: GamePiece
    endX: number
    endY: number
    startX: number
    startY: number

    constructor(piece: GamePiece, endX: number, endY: number, startX: number, startY: number){
        this.piece = piece
        this.endX = endX
        this.endY = endY
        this.startY = startY
        this.startX = startX
    }

    getPiece(): GamePiece {
        return this.piece
    }

    getEndX(): number {
        return this.endX
    }

    getEndY(): number {
        return this.endY
    }

    getStartX(): number {
        return this.startX
    }

    getStartY(): number {
        return this.startY
    }
}

interface MinimaxResult {
    score: number
    path: Move[]
}