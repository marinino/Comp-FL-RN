import GamePiece from './GamePiece'

export default class DameGame {
  constructor() {
    console.log('DAMEGAME')
    this.selectedX = -1
    this.selectedY = -1
    this.boardSize = 10;
    this.board = Array.from({ length: this.boardSize }, () => Array(this.boardSize).fill(null));
    this.currentPlayer = 1; // 1 für Spieler 1, 2 für Spieler 2

    // Initialisieren des Bretts mit Spielsteinen
    for (let row = 0; row < this.boardSize; row++) {
      for (let col = 0; col < this.boardSize; col++) {
        if ((row + col) % 2 === 1) {
          if (row < 4) {
            this.board[row][col] = new GamePiece(1, false);
          } else if (row >= 6) {
            this.board[row][col] = new GamePiece(2, false);
          }
        }
      }
    }
  }

  movePiece(startRow, startCol, endRow, endCol) {
    // Hier könnten Sie die Logik zum Bewegen der Spielsteine implementieren
    // einschließlich der Überprüfung auf gültige Züge und das Schlagen gegnerischer Steine

    console.log('Called move');

    // Prüfen Sie, ob der Zug gültig ist
    if (!this.isValidMove(startCol, startRow, endCol, endRow)) {
      return false;
    }

    const beatenPiece: GamePiece | null = this.checkAndRemoveOppBeaten(startCol, startRow, endCol, endRow, true);
    var foundBeatingMove = this.findMovesWhichBeat()
    if (beatenPiece == null && foundBeatingMove) {
      this.stateString = `Spieler ${this.currentPlayer} hat die Schlagpflicht verletzt, wähle einen anderen Zug`;
      return false;
    }

    // Beispiel für das Bewegen eines Spielsteins
    const piece = this.board[startRow][startCol];
    console.log(piece, endRow, endCol)
    this.board[endRow][endCol] = piece;
    console.log(this.board[endRow][endCol])
    this.board[startRow][startCol] = null;
    console.log(this.board[startRow][startCol])

    console.log(this.board)

    const beatenPieceAfterMove: GamePiece | null = this.checkAndRemoveOppBeaten(startCol, startRow, endCol, endRow, false);

    console.log(this.board);
    const newQueen: boolean = this.checkForQueenConv();

    // Ändert den Spieler, wenn kein weiterer Schlag möglich ist oder es keinen Schlag gab
    if (beatenPieceAfterMove != null && this.findMovesWhichBeat() && !newQueen) {
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

    return true;
  }

  handlePressDeep(row, column){
    if(this.selectedX == -1){
        console.log(row, column)
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
        this.movePiece(this.selectedY, this.selectedX, row, column);

        this.selectedX = -1;
        this.selectedY = -1;
      }
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
            console.log(element[1], element[0], this.board[element[1]][element[0]])
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

        console.log(`FOUND BLACK ${foundBlack}`);
        console.log(`FOUND WHITE ${foundWhite}`);

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

  findMovesWhichBeat(): GamePiece? {

    var returnPiece = null;
    // Überprüfen, ob eine Eliminierung möglich ist
      for(elementRow of this.board){
        for(elementItem of elementRow){
          if (elementItem !== null && elementItem.playerId === this.currentPlayer) {
            const rowIndex = this.board.indexOf(elementRow);
            const itemIndex = elementRow.indexOf(elementItem);
            console.log(rowIndex, itemIndex)

            if(!this.board[rowIndex][itemIndex].isQueen){
              // Teste verschiedene Richtungen
              console.log('WHERE YOU GO 1')

              if (rowIndex + 2 < 10 && itemIndex + 2 < 10) {
                if (this.isValidMove(itemIndex, rowIndex, itemIndex + 2, rowIndex + 2)) {

                    var tempPiece = this.checkAndRemoveOppBeaten(itemIndex, rowIndex, itemIndex + 2, rowIndex + 2, true)
                    var returnedPiece = checkToChangeReturningPiece(returnPiece, tempPiece);
                    if(returnedPiece != null && returnedPiece.isQueen){
                      return returnedPiece;
                    } else if(returnedPiece != null){
                      returnPiece = returnedPiece;
                    }

                }
              }
              console.log('WHERE YOU GO 2')

              if (rowIndex + 2 < 10 && itemIndex - 2 >= 0) {
                if (this.isValidMove(itemIndex, rowIndex, itemIndex - 2, rowIndex + 2)) {
                   var tempPiece = this.checkAndRemoveOppBeaten(itemIndex, rowIndex, itemIndex - 2, rowIndex + 2, true)
                   var returnedPiece = checkToChangeReturningPiece(returnPiece, tempPiece);
                   if(returnedPiece != null && returnedPiece.isQueen){
                       return returnedPiece;
                   } else if(returnedPiece != null){
                       returnPiece = returnedPiece;
                   }
                }
              }
              console.log('WHERE YOU GO 3')
              if (rowIndex - 2 >= 0 && itemIndex - 2 >= 0) {
                if (this.isValidMove(itemIndex, rowIndex, itemIndex - 2, rowIndex - 2)) {
                  var tempPiece = this.checkAndRemoveOppBeaten(itemIndex, rowIndex, itemIndex - 2, rowIndex - 2, true)
                  var returnedPiece = checkToChangeReturningPiece(returnPiece, tempPiece);
                  if(returnedPiece != null && returnedPiece.isQueen){
                    return returnedPiece;
                  } else if(returnedPiece != null){
                    returnPiece = returnedPiece;
                  }
                }
              }
              console.log('BEFORE LOWER LEFT' , rowIndex, itemIndex)
              if (rowIndex - 2 >= 0 && itemIndex + 2 < 10) {
                console.log('GONE HERE')
                if (this.isValidMove(itemIndex, rowIndex, itemIndex + 2, rowIndex - 2)) {
                  var tempPiece = this.checkAndRemoveOppBeaten(itemIndex, rowIndex, itemIndex + 2, rowIndex - 2, true)
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
                    if((rowIndex + i) < 10 && (itemIndex + i) < 10 && !returnBool){
                        if (this.isValidMove(itemIndex, rowIndex, itemIndex + i, rowIndex + i)) {
                          var tempPiece = this.checkAndRemoveOppBeaten(itemIndex, rowIndex, itemIndex + i, rowIndex + i, true)
                          var returnedPiece = checkToChangeReturningPiece(returnPiece, tempPiece);
                          if(returnedPiece != null && returnedPiece.isQueen){
                            return returnedPiece;
                          } else if(returnedPiece != null){
                            returnPiece = returnedPiece;
                          }
                        }
                    }

                    if((rowIndex - i) >= 0 && (itemIndex - i) >= 0 && !returnBool){
                        if (this.isValidMove(itemIndex, rowIndex, itemIndex - i, rowIndex - i)) {
                          var tempPiece = this.checkAndRemoveOppBeaten(itemIndex, rowIndex, itemIndex - i, rowIndex - i, true)
                          var returnedPiece = checkToChangeReturningPiece(returnPiece, tempPiece);
                          if(returnedPiece != null && returnedPiece.isQueen){
                            return returnedPiece;
                          } else if(returnedPiece != null){
                            returnPiece = returnedPiece;
                          }
                        }
                    }

                    if((rowIndex - i) >= 0 && (itemIndex + i) < 10 && !returnBool){
                        if (this.isValidMove(itemIndex, rowIndex, itemIndex + i, rowIndex - i)) {
                          var tempPiece = this.checkAndRemoveOppBeaten(itemIndex, rowIndex, itemIndex + i, rowIndex - i, true)
                          var returnedPiece = checkToChangeReturningPiece(returnPiece, tempPiece);
                          if(returnedPiece != null && returnedPiece.isQueen){
                            return returnedPiece;
                          } else if(returnedPiece != null){
                            returnPiece = returnedPiece;
                          }
                        }
                    }

                    if((rowIndex + i) < 10 && (itemIndex - i) >= 0 && !returnBool){
                        if (this.isValidMove(itemIndex, rowIndex, itemIndex - i, rowIndex + i)) {
                          var tempPiece = this.checkAndRemoveOppBeaten(itemIndex, rowIndex, itemIndex - i, rowIndex + i, true)
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
      return returnBool;
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

    checkToChangeReturningPiece(returnPiece, tempPiece): GamePiece? {
        if (returnPiece == null) {
          return tempPiece;
        } else if(!returnPiece.isQueen && tempPiece != null){
          return tempPiece;
        } else if(tempPiece != null && tempPiece.isQueen){
          return tempPiece;
        }
      }
  // Weitere Methoden wie Überprüfung auf gültige Züge, Überprüfung der Gewinnbedingungen usw.
}
