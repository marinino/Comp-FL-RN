import GamePiece from './GamePiece'
import { Animated, Dimensions } from 'react-native';


export default class DameGame {


  constructor() {
    console.log('DAMEGAME')
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

    this.board[0][5] = new GamePiece(`${0}-${5}`, 2, false, true);
    this.board[1][4] = new GamePiece(`${1}-${4}`, 1, false);
    this.board[1][2] = new GamePiece(`${1}-${2}`, 1, false);

    // Initialisieren des Bretts mit Spielsteinen
    for (let row = 0; row < this.boardSize; row++) {
      for (let col = 0; col < this.boardSize; col++) {
        if ((row + col) % 2 === 1) {
          if (row < 4) {
            //this.board[row][col] = new GamePiece(`${row}-${col}`, 1, false);
          } else if (row >= 6) {
            //this.board[row][col] = new GamePiece(`${row}-${col}`, 2, false);
          }
        }
      }
    }
    console.log('DAMEGAME')

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

      // Prüfen Sie, ob der Zug gültig ist
      if (!this.isValidMove(startCol, startRow, endCol, endRow)) {
        return false;
      }

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

      // Beispiel für das Bewegen eines Spielsteins
      const piece = this.board[startRow][startCol];
      this.board[endRow][endCol] = piece;
      this.board[startRow][startCol] = null;



        if(!this.animationRunning){

          const animatedValue = this.pieceAnimatedValues[piece.pieceId];
          console.log('ANIMATION BOUT TO START', animatedValue)
          this.animationRunning = true
          piece.isAnimated = true

          console.log(this.pieceZValues, 'FROM ANIMATE')
          return new Promise((resolve, reject) => {
            Animated.timing(animatedValue, {
                  toValue: { x: endCol * this.squareWidth + this.squareWidth * 0.15 / 2, y: endRow * this.squareWidth + this.squareWidth * 0.15 / 2 }, // You need to convert board positions to screen positions
                  duration: 1000,
                  useNativeDriver: true,
              }).start(({ finished }) => {

                      // Assuming newPosition provides the correct final coordinates
                      // You might need to convert row and column to actual x, y coordinates
                  this.pieceAnimatedValues[piece.pieceId] = new Animated.ValueXY({ x: this.squareWidth * endCol + this.squareWidth * 0.15 / 2, y: this.squareWidth * endRow + this.squareWidth * 0.15 / 2});

                  // Aktualisieren Sie den Zustand, um die UI neu zu rendern
                  this.animationRunning = false
                  console.log('ANIMATION BOUT ENDED')



                  const beatenPieceAfterMove: GamePiece | null = this.checkAndRemoveOppBeaten(startCol, startRow, endCol, endRow, false);


                  const newQueen: boolean = this.checkForQueenConv();


                  // Ändert den Spieler, wenn kein weiterer Schlag möglich ist oder es keinen Schlag gab
                  if (beatenPieceAfterMove != null && this.findMovesWhichBeat().getPiece() && !newQueen) {
                    console.log('Player stays')
                    this.stateString = `Spieler ${this.currentPlayer} bleibt dran`;
                  } else {
                    this.currentPlayer = 3 - this.currentPlayer;
                    this.stateString = `Spieler ${this.currentPlayer} ist dran`;
                  }


                  if (this.checkWin()) {
                    this.stateString = `Spieler ${3 - this.currentPlayer} hat gewonnen`;
                    setTimeout(() => {
                      this.resetGame();
                    }, 5000);
                  }

                  console.log('1233456789')



                  if(finished){
                        console.log('Animation completed')
                        resolve();
                  } else {
                      console.log('Animation interrupted');
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
        console.log('Tried to call move');
        returnedDataFromMove = await this.movePiece(this.selectedY, this.selectedX, row, column);

        this.selectedX = -1;
        this.selectedY = -1;
      }
      return returnedDataFromMove
  }

  checkAndRemoveOppBeaten(startX: number, startY: number, endX: number, endY: number, simulate: boolean): GamePiece | null {
      let beatenPiece: GamePiece | null = null;

      // Nur wenn keine Felder übersprungen wurden, konnte niemand geschlagen werden
      if (Math.abs(startX - endX) === 1) {
        return null;
      }


      const jumpedFields: number[][] = this.getJumpedFields(startX, startY, endX, endY);

      jumpedFields.forEach((element) => {
        if (this.board[element[1]][element[0]]?.playerId !== this.currentPlayer) {
          beatenPiece = this.board[element[1]][element[0]];
          if (!simulate) {
            this.board[element[1]][element[0]] = null;
          }
        }
      });

      return beatenPiece;
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

    isValidMove(startX: number, startY: number, endX: number, endY: number): boolean {
        // ... Ihre Logik, um zu prüfen, ob ein Zug gültig ist ...

        if(startX < 0 || startX > 9 ||startY < 0 || startY > 9 || endX < 0 || endX > 9 ||endY < 0 || endY > 9){
            return false
        }

        let jumpedOwnPiecesOrAir = false;
        const jumpedFields: number[][] = this.getJumpedFields(startX, startY, endX, endY);

        // Überprüfen, ob das Zielfeld frei ist
        if (this.board[endY][endX] !== null) {
          this.stateString = 'Der Zielort muss ein freies Feld sein';
          return false;
        }

        // Überprüfen, ob nur diagonale Züge gemacht werden
        if (startX === endX || startY === endY) {
          this.stateString = 'Es sind nur diagonale Züge erlaubt';
          return false;
        }

        // Überprüfen, ob der Sprung gleich weit in X und Y ist
        if (Math.abs(startX - endX) !== Math.abs(startY - endY)) {
          this.stateString = 'Es sind nur diagonale Züge erlaubt';
          return false;
        }

        jumpedFields.forEach((element) => {
          if (this.board[element[1]][element[0]]?.playerId == this.currentPlayer) {
            jumpedOwnPiecesOrAir = true;
          }
        });
        // Need that for own pieces because Flutter FTW
        // Not jumping over a empty tile or a own piece
        if(jumpedOwnPiecesOrAir){
          this.stateString = 'Man darf nur über Steine des Gegners springen Test';
          return false;
        }

        // FOR NON QUEENS
        if((this.board[startY][startX] != null && (!this.board[startY][startX]!.isQueen))){
          //If you try to move backwards
          if(((endY < startY) && this.currentPlayer == 1) || ((endY > startY) && this.currentPlayer == 2)){
            this.stateString = 'Rückwärts laufen ist nur mit Damen erlaubt';
            return false;
          }

          // If the piece is not a queen it can not jump more than two
          if(this.board[startY][startX] != null && (!this.board[startY][startX]!.isQueen) && Math.abs(startX - endX) > 2){
            this.stateString = 'Normale Steine können maximal zwei Felder springen';
            return false;
          }

          jumpedFields.forEach((element) => {
            if(this.board[element[1]][element[0]] == null){
              jumpedOwnPiecesOrAir = true;
            }
          });
          // Need that for own pieces because Flutter FTW
          // Not jumping over a empty tile or a own piece
          if(jumpedOwnPiecesOrAir){
            this.stateString = 'Man darf nur über Steine des Gegners springen';
            return false;
          }
        // FOR QUEENS
        } else if((this.board[startY][startX] != null && (this.board[startY][startX]!.isQueen))){
          // Queen must be surrounded by enemy piece

          var counterOfOpponentPieces = 0;
          var foundOwnPiece = false;

          jumpedFields.forEach((element) => {
            if(this.board[element[1]][element[0]]?.playerId == (3 - this.currentPlayer)){
              counterOfOpponentPieces++;
            }
            if(this.board[element[1]][element[0]]?.playerId == this.currentPlayer){
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

          if((endY - 1 >= 0 && endX - 1 >= 0 && this.board[endY - 1][endX - 1]?.playerId != (3 - this.currentPlayer)) &&
              (endY - 1 >= 0 && endX + 1 < 10 && this.board[endY - 1][endX + 1]?.playerId != (3 - this.currentPlayer)) &&
              (endY + 1 < 10 && endX - 1 >= 0 && this.board[endY + 1][endX - 1]?.playerId != (3 - this.currentPlayer)) &&
              (endY + 1 < 10 && endX + 1 < 10 && this.board[endY + 1][endX + 1]?.playerId != (3 - this.currentPlayer)) &&
              this.checkAndRemoveOppBeaten(startX, startY, endX, endY, true) != null){
            this.stateString = 'Die Dame muss direkt um einen Gegner herum landen';
            return false;
          }
        }
        // IF ELIMINATION HAPPENS NO NEED TO CHECK IF MOVE IS VALID
        if(this.checkAndRemoveOppBeaten(startX, startY, endX, endY, true) != null){
          return true;
        }

        return true; // Ändern Sie dies, um die tatsächliche Prüfung widerzuspiegeln
    }

    checkWin(): boolean {
        let foundWhite = false;
        let foundBlack = false;

        this.board.forEach((row) => {
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
          console.log('GAME OVER, SOMEBODY WON');
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

  findMovesWhichBeat(): Move {

      var returnMove = new Move(null, -1, -1, -1, -1);
      // Überprüfen, ob eine Eliminierung möglich ist
        for(elementRow of this.board){
          for(elementItem of elementRow){
            if (elementItem && elementItem.playerId === this.currentPlayer) {
              const rowIndex = this.board.indexOf(elementRow);
              const itemIndex = elementRow.indexOf(elementItem);

              if(!this.board[rowIndex][itemIndex].isQueen){
                // Teste verschiedene Richtungen

                if (rowIndex + 2 < 10 && itemIndex + 2 < 10) {
                  if (this.isValidMove(itemIndex, rowIndex, itemIndex + 2, rowIndex + 2)) {

                      var tempPiece = this.checkAndRemoveOppBeaten(itemIndex, rowIndex, itemIndex + 2, rowIndex + 2, true)
                      var returnedPiece = this.checkToChangeReturningPiece(returnMove.getPiece(), tempPiece);
                      if(returnedPiece != null && returnedPiece.isQueen){
                        return new Move(returnedPiece, itemIndex + 2, rowIndex + 2, itemIndex, rowIndex);
                      } else if(returnedPiece != null){
                        returnMove = new Move(returnedPiece, itemIndex + 2, rowIndex + 2, itemIndex, rowIndex);
                      }
                  }
                }

                if (rowIndex + 2 < 10 && itemIndex - 2 >= 0) {
                  if (this.isValidMove(itemIndex, rowIndex, itemIndex - 2, rowIndex + 2)) {
                     var tempPiece = this.checkAndRemoveOppBeaten(itemIndex, rowIndex, itemIndex - 2, rowIndex + 2, true)
                     var returnedPiece = this.checkToChangeReturningPiece(returnMove.getPiece(), tempPiece);
                     if(returnedPiece != null && returnedPiece.isQueen){
                         return new Move(returnedPiece, itemIndex - 2, rowIndex + 2, itemIndex, rowIndex);
                     } else if(returnedPiece != null){
                         returnMove = new Move(returnedPiece, itemIndex - 2, rowIndex + 2, itemIndex, rowIndex);
                     }
                  }
                }
                if (rowIndex - 2 >= 0 && itemIndex - 2 >= 0) {
                  if (this.isValidMove(itemIndex, rowIndex, itemIndex - 2, rowIndex - 2)) {
                    var tempPiece = this.checkAndRemoveOppBeaten(itemIndex, rowIndex, itemIndex - 2, rowIndex - 2, true)
                    var returnedPiece = this.checkToChangeReturningPiece(returnMove.getPiece(), tempPiece);
                    if(returnedPiece != null && returnedPiece.isQueen){
                      return new Move(returnedPiece, itemIndex - 2, rowIndex - 2, itemIndex, rowIndex);
                    } else if(returnedPiece != null){
                      returnMove = new Move(returnedPiece, itemIndex - 2, rowIndex - 2, itemIndex, rowIndex);
                    }
                  }
                }
                if (rowIndex - 2 >= 0 && itemIndex + 2 < 10) {
                  if (this.isValidMove(itemIndex, rowIndex, itemIndex + 2, rowIndex - 2)) {
                    var tempPiece = this.checkAndRemoveOppBeaten(itemIndex, rowIndex, itemIndex + 2, rowIndex - 2, true)
                    var returnedPiece = this.checkToChangeReturningPiece(returnMove.getPiece(), tempPiece);
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
                          if (this.isValidMove(itemIndex, rowIndex, itemIndex + i, rowIndex + i)) {
                            var tempPiece = this.checkAndRemoveOppBeaten(itemIndex, rowIndex, itemIndex + i, rowIndex + i, true)
                            var returnedPiece = this.checkToChangeReturningPiece(returnMove.getPiece(), tempPiece);
                            if(returnedPiece != null && returnedPiece.isQueen){
                              return new Move(returnedPiece, itemIndex + i, rowIndex + i, itemIndex, rowIndex);
                            } else if(returnedPiece != null){
                              returnMove = new Move(returnedPiece, itemIndex + i, rowIndex + i, itemIndex, rowIndex);
                            }
                          }
                      }
                      if((rowIndex - i) >= 0 && (itemIndex - i) >= 0 && !returnMove.getPiece()){
                          if (this.isValidMove(itemIndex, rowIndex, itemIndex - i, rowIndex - i)) {
                            var tempPiece = this.checkAndRemoveOppBeaten(itemIndex, rowIndex, itemIndex - i, rowIndex - i, true)
                            var returnedPiece = this.checkToChangeReturningPiece(returnMove.getPiece(), tempPiece);
                            if(returnedPiece != null && returnedPiece.isQueen){
                              return new Move(returnedPiece, itemIndex - i, rowIndex - i, itemIndex, rowIndex);
                            } else if(returnedPiece != null){
                              returnMove = new Move(returnedPiece, itemIndex - i, rowIndex - i, itemIndex, rowIndex);
                            }
                          }
                      }

                      if((rowIndex - i) >= 0 && (itemIndex + i) < 10 && !returnMove.getPiece()){
                          if (this.isValidMove(itemIndex, rowIndex, itemIndex + i, rowIndex - i)) {
                            var tempPiece = this.checkAndRemoveOppBeaten(itemIndex, rowIndex, itemIndex + i, rowIndex - i, true)
                            var returnedPiece = this.checkToChangeReturningPiece(returnMove.getPiece(), tempPiece);
                            if(returnedPiece != null && returnedPiece.isQueen){
                              return new Move(returnedPiece, itemIndex + i, rowIndex - i, itemIndex, rowIndex);
                            } else if(returnedPiece != null){
                              returnMove = new Move(returnedPiece, itemIndex + i, rowIndex - i, itemIndex, rowIndex);
                            }
                          }
                      }

                      if((rowIndex + i) < 10 && (itemIndex - i) >= 0 && !returnMove.getPiece()){
                          if (this.isValidMove(itemIndex, rowIndex, itemIndex - i, rowIndex + i)) {
                            var tempPiece = this.checkAndRemoveOppBeaten(itemIndex, rowIndex, itemIndex - i, rowIndex + i, true)
                            var returnedPiece = this.checkToChangeReturningPiece(returnMove.getPiece(), tempPiece);
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
                              const optimalMove = this.findMovesWhichBeat();
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
                                          console.log('FOUND PC STONE AT: ', i, j)
                                          for(var k = 1; k <= 9; k++){

                                                  console.log('SURROUNDED BY DANGER!!!!!?????????? - +')
                                                  if(this.isValidMove(j, i, j+k, i-k) && !this.surroundedByDanger(i-k, j+k, i, j)){
                                                      console.log('TOP RIGHT LETS GO', i, j, i-k, j+k, 'THIS IS CURRENT K', k)
                                                      await this.movePiece(i, j, i-k, j+k)
                                                      console.log('MOVE DUN DUN')
                                                      resolve();
                                                      return;
                                                  }

                                                  console.log('SURROUNDED BY DANGER!!!!!?????????? - -')
                                                  if(this.isValidMove(j, i, j-k, i-k) && !this.surroundedByDanger(i-k, j-k, i, j)){
                                                      await this.movePiece(i, j, i-k, j-k)
                                                      resolve();
                                                      return;
                                                  }

                                                  console.log('SURROUNDED BY DANGER!!!!!?????????? + -')
                                                  if(this.isValidMove(j, i, j-k, i+k) && !this.surroundedByDanger(i+k, j-k, i, j)){
                                                      await this.movePiece(i, j, i+k, j-k)
                                                      resolve();
                                                      return;
                                                  }

                                                  console.log('SURROUNDED BY DANGER!!!!!?????????? + +')
                                                  if(this.isValidMove(j, i, j+k, i+k) && !this.surroundedByDanger(i+k, j+k, i, j)){
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

    console.log(rowIndex, columnIndex, 'ALARM')

    // Checks if piece is could be normally beaten
    if(columnIndex + 1 <= 9 && rowIndex - 1 >= 0 && this.board[rowIndex - 1][columnIndex + 1] &&
            this.board[rowIndex - 1][columnIndex + 1].playerId == (3-this.currentPlayer) &&
            !this.board[rowIndex - 1][columnIndex + 1].isQueen &&
            columnIndex - 1 >= 0 && rowIndex + 1 <= 9 &&
            (!this.board[rowIndex + 1][columnIndex - 1] || (rowIndex + 1 == startRow && columnIndex - 1 == startColumn))){
        console.log('WE HERE!!!!!!!!!!!!!!!!!!!!!!!!!!!!!')
        return true;

    }else if(columnIndex - 1 >= 0 && rowIndex - 1 >= 0 && this.board[rowIndex - 1][columnIndex - 1] &&
            this.board[rowIndex - 1][columnIndex - 1].playerId == (3-this.currentPlayer) &&
            !this.board[rowIndex - 1][columnIndex - 1].isQueen &&
            columnIndex + 1 <= 9 && rowIndex + 1 <= 9 &&
             (!this.board[rowIndex + 1][columnIndex + 1] || (rowIndex + 1 == startRow && columnIndex + 1 == startColumn))){
            console.log('WE HERE')
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
        console.log(k, 'BIG OL K', maxIndex)
        if(0 <= rowIndex + k && rowIndex + k <= 9 && 0 <= columnIndex + k && columnIndex + k <= 9
                && rowIndex + k != startRow && columnIndex + k != startColumn
                && this.board[rowIndex + k][columnIndex + k]
                && this.board[rowIndex + k][columnIndex + k].playerId == (3-this.currentPlayer)
                && this.board[rowIndex + k][columnIndex + k].isQueen
                && !pieceFoundDownRight){
            console.log('Found queen which could beat at ', rowIndex + k, columnIndex + k)
            return true
        } else if(0 <= rowIndex + k && rowIndex + k <= 9 && 0 <= columnIndex + k && columnIndex + k <= 9
                && rowIndex + k != startRow && columnIndex + k != startColumn
                && this.board[rowIndex + k][columnIndex + k]){
            console.log('Found piece at ', rowIndex + k, columnIndex + k)
            pieceFoundDownRight = true;
        } else {
            console.log('NO DANGER FOUND AT', rowIndex + k, columnIndex + k)
        }
        console.log(9 >= (rowIndex - k) >= 0)
        if(9 >= rowIndex - k && rowIndex - k >= 0 && 0 <= columnIndex + k && columnIndex + k <= 9
                && rowIndex - k != startRow && columnIndex + k != startColumn
                && this.board[rowIndex - k][columnIndex + k]
                && this.board[rowIndex - k][columnIndex + k].playerId == (3-this.currentPlayer)
                && this.board[rowIndex - k][columnIndex + k].isQueen
                && !pieceFoundUpRight){
                console.log('Found queen which could beat at ', rowIndex - k, columnIndex + k)
            return true
        } else if(9 >= rowIndex - k && rowIndex - k >= 0 && 0 <= columnIndex + k && columnIndex + k <= 9
                && rowIndex - k != startRow && columnIndex + k != startColumn
                && this.board[rowIndex - k][columnIndex + k]){
                console.log('Found piece at ', rowIndex - k, columnIndex + k)
            pieceFoundUpRight = true;
        } else {
            console.log('NO DANGER FOUND', rowIndex - k, columnIndex + k)
        }

        if(0 <= rowIndex + k && rowIndex + k <= 9 && 9 >= columnIndex - k && columnIndex - k >= 0
                    && rowIndex + k != startRow && columnIndex - k != startColumn
                    && this.board[rowIndex + k][columnIndex - k]
                    && this.board[rowIndex + k][columnIndex - k].playerId == (3-this.currentPlayer)
                    && this.board[rowIndex + k][columnIndex - k].isQueen
                    && !pieceFoundDownLeft){
                    console.log('Found queen which could beat at ', rowIndex + k, columnIndex - k)
            return true
        } else if(0 <= rowIndex + k && rowIndex + k <= 9 && 9 >= columnIndex - k && columnIndex - k >= 0
                && rowIndex + k != startRow && columnIndex - k != startColumn
                && this.board[rowIndex + k][columnIndex - k]){
            pieceFoundDownLeft = true;
            console.log('Found piece at ', rowIndex + k, columnIndex - k)
        } else {
            console.log('NO DANGER FOUND', rowIndex + k, columnIndex - k)
        }

        if(9 >= rowIndex - k && rowIndex - k >= 0 && 9 >= columnIndex - k && columnIndex - k >= 0
                && rowIndex - k != startRow && columnIndex - k != startColumn
                && this.board[rowIndex - k][columnIndex - k]
                && this.board[rowIndex - k][columnIndex - k].playerId == (3-this.currentPlayer)
                && this.board[rowIndex - k][columnIndex - k].isQueen
                && !pieceFoundUpLeft){
                console.log('Found queen which could beat at ', rowIndex - k, columnIndex - k)
            return true
        } else if(9 >= rowIndex - k && rowIndex - k >= 0 && 9 >= columnIndex - k && columnIndex - k >= 0
                && rowIndex - k != startRow && columnIndex - k != startColumn
                && this.board[rowIndex - k][columnIndex - k]){
                console.log('Found piece at ', rowIndex - k, columnIndex - k)
            pieceFoundUpLeft = true;
        } else {
            console.log('NO DANGER FOUND', rowIndex - k, columnIndex - k)
        }
    }

    console.log('OUT OF FOR')
    return false;
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