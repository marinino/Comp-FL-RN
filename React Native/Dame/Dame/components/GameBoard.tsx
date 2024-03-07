import React, {useState, useEffect} from 'react';
import { StyleSheet, FlatList, TouchableOpacity, View, Text, Animated, Dimensions } from 'react-native';
import DameGame from './DameGame'; // Pfad zu Ihrer DameGame-Klasse
import Piece from './PieceComponent'

const GameBoard = () => {
    const [game, setGame] = useState(() => new DameGame());

    const [updateCounter, setUpdateCounter] = useState(0);
    const [updateCounter2, setUpdateCounter2] = useState(0);
    const [animatedPieceId, setAnimatedPieceId] = useState(null);


    const [isInitialized, setIsInitialized] = useState(false);
    const squareSize = (Dimensions.get('window').width) / 10; // Assuming a square board for simplicity


    const forceUpdate = () => {
      setUpdateCounter(updateCounter + 1);
      console.log('UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUPPPPPPPPPPPPPPPPPPPPPPDDDDDDDDDDDDDDDDDDDDDDDAAAAAAAAAAAAAAATTTTE')
    };

    const forceUpdate2 = () => {
      setUpdateCounter2(updateCounter2 - 1);
      console.log('UUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUUPPPPPPPPPPPPPPPPPPPPPPDDDDDDDDDDDDDDDDDDDDDDDAAAAAAAAAAAAAAATTTTE')
    };

    const handlePress = async (row, column) => {
      // Logik, um zu bestimmen, ob dies ein gültiger Zug ist, und um den Zug durchzuführen
      // Beispiel: Wenn ein Spieler einen Stein ausgewählt hat und nun ein Ziel auswählt
      // game.movePiece(startRow, startCol, row, col);
      //setAnimatedPieceId(`${row}-${column}`)
      await game.handlePressDeep(row, column)
      setAnimatedPieceId(null)

      console.log('HandlePress is DDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDDONE')
        //HIII
      setGame(game)
      forceUpdate(); // Dies wird die Komponente dazu bringen, sich neu zu rendern

      if(game.currentPlayer == 2){
        console.log('SIM PC MOVE')
        await game.simulateComputerMove();
        console.log('PC MOVE ENDED')
        console.log(game.board, game.stateString)
        setGame(game)
        forceUpdate2(); // Dies wird die Komponente dazu bringen, sich neu zu rendern
      }


    };

  const boardSize = 10;
  const squares = Array.from({ length: boardSize * boardSize }, (_, index) => {
  const row = Math.floor(index / boardSize);
  const col = index % boardSize;
  const isDark = (row + col) % 2 === 1;
  let hasPiece = false;
  let pieceColor = 'transparent';

  // Platzieren von Damesteinen in den ersten 4 und letzten 4 Reihen auf dunklen Feldern
  if (isDark && (row < 4 || row >= 6)) {
    hasPiece = true;
    pieceColor = row < 4 ? 'white' : 'black'; // Weiße Steine für Spieler 1, schwarze für Spieler 2
  }

  return {
    id: index,
    isDark,
    hasPiece,
    pieceColor,
  };
});

    const renderPieces = () => {
        console.log('RENDERING PIECESr')
      return game.board.flatMap((row, rowIndex) =>
        row.map((piece, colIndex) => {

            if (!piece) return null; // Skip empty squares

            // Determine if this piece is the one being animated
            const isAnimating = piece.isAnimated;
            const pieceZIndex = isAnimating ? 1000 : 1; // Elevated zIndex for the animating piece

            console.log(pieceZIndex)

            const animatedStyle = {
              transform: [
                { translateX: game.pieceAnimatedValues[piece.pieceId].x},
                { translateY: game.pieceAnimatedValues[piece.pieceId].y},
              ],
              zIndex: pieceZIndex
            };
            piece.isAnimated = false
            return (

              <Animated.View key={`${rowIndex}-${colIndex}`} style={[styles.piece, animatedStyle]}>
                <Piece id={piece.pieceId} playerID={piece.playerId} isQueen={piece.isQueen} position={new Animated.ValueXY({x: (game.pieceAnimatedValues[piece.pieceId].x), y: (game.pieceAnimatedValues[piece.pieceId].y)})}/>
              </Animated.View>
            );
        }).filter(Boolean)
      );
    };

  const renderSquare = ({ item }) => {
    const row = Math.floor(item.id / game.boardSize);
    const col = item.id % game.boardSize;
    const piece = game.board[row][col];
    const squareWidth = Dimensions.get('window').width;
    const animatedValue = piece ? game.pieceAnimatedValues[piece.pieceId] : new Animated.ValueXY();

        if (!animatedValue) {
            console.error(`Animated value for piece ${row}-${col} is undefined.`);
            return <Text>No...</Text>;; // Or handle this scenario appropriately
        } else {
            //setIsInitialized(false)
            return(

                <TouchableOpacity
                  style={[styles.square, item.isDark ? styles.darkSquare : styles.lightSquare]}
                  onPress={() => handlePress(row, col)}
                >
                </TouchableOpacity>
            )
        }
  };


  return (
    <>
       <View style={styles.gameBoardContainer}>
         <FlatList
           data={squares}
           renderItem={renderSquare}
           keyExtractor={item => item.id.toString()}
           numColumns={boardSize}
           scrollEnabled={false} // Optionally disable scrolling if the board should be static
           style={[styles.board]}
         />
         {renderPieces()}

        <View style={styles.statusContainer}>
            <Text style={styles.statusText}>{game.stateString}</Text>
        </View>
       </View>
    </>
  );
};



const styles = StyleSheet.create({
  square: {
    width: '10%', // 10 Spalten
    height: '10%',
    aspectRatio: 1, // Quadratische Felder
  },
  darkSquare: {
    backgroundColor: 'brown',
  },
  lightSquare: {
    backgroundColor: 'beige',
  },
  piece: {
    width: '10%', // Größe des Spielsteins
    height: (Dimensions.get('window').width)/10,
    //borderRadius: 50, // Kreisform
    position: 'absolute',
    //top: 0,
    //left: 0,
    pointerEvents: 'none'

  },

  pieceText: {
    flex: 1,
    fontWeight: 'bold',
    fontSize: 18,
    textAlign: 'center', // Zentriert den Text horizontal
    textAlignVertical: 'center', // Zentriert den Text vertikal (nur für Android notwendig)
  },
  statusContainer: {
    padding: 10, // oder eine geeignete Größe
    borderWidth: 1, // oder eine geeignete Größe
    borderColor: 'gray', // oder eine geeignete Farbe
    margin: 10, // oder eine geeignete Größe
  },
  statusText: {
    fontSize: 16, // oder eine geeignete Größe
    color: 'black', // oder eine geeignete Farbe
  },
});

export default GameBoard;
