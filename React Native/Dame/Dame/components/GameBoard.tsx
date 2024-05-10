import React, {useState, useEffect} from 'react';
import { StyleSheet, FlatList, TouchableOpacity, View, Text, Animated, Dimensions, Easing } from 'react-native';
import DameGame from './DameGame'; // Pfad zu Ihrer DameGame-Klasse
import Piece from './PieceComponent'

const GameBoard = () => {
    const [game, setGame] = useState(() => new DameGame());

    const [updateCounter, setUpdateCounter] = useState(0);
    const [updateCounter2, setUpdateCounter2] = useState(0);
    const [updateCounter3, setUpdateCounter3] = useState(0);
    const [forceRerenderZIndex, setForceRerenderZIndex] = useState(0);
    const [animatedPieceId, setAnimatedPieceId] = useState(null);
    const [animatedPiece, setAnimatedPiece] = useState(0);


    const [isInitialized, setIsInitialized] = useState(false);
    const squareSize = (Dimensions.get('window').width) / 10; // Assuming a square board for simplicity

    const forceUpdateZIndex = () => {
      setAnimatedPiece(animatedPiece + 1)
    };

    const forceUpdate = () => {
      setUpdateCounter(updateCounter + 1);
    };

    const forceUpdate2 = () => {
      setUpdateCounter2(updateCounter2 - 1);
    };

    const forceUpdate3 = () => {
        setUpdateCounter3(updateCounter3 + 1);
    };

    const handlePress = async (row, column) => {
      // Logik, um zu bestimmen, ob dies ein gültiger Zug ist, und um den Zug durchzuführen
      // Beispiel: Wenn ein Spieler einen Stein ausgewählt hat und nun ein Ziel auswählt
      // game.movePiece(startRow, startCol, row, col);
      //setAnimatedPieceId(`${row}-${column}`)


      await game.handlePressDeep(row, column)


        //HIII
      setGame(game)
      forceUpdate(); // Dies wird die Komponente dazu bringen, sich neu zu rendern
      console.log(`Try computer move` , game.currentPlayer)

      while(game.currentPlayer == 2 && await !game.checkWin()){
        console.log(`Try computer move`)
        await game.simulateComputerMoveWithMiniMax();
        setGame(game)
        forceUpdate2(); // Dies wird die Komponente dazu bringen, sich neu zu rendern
      }
      forceUpdate3();

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

const renderUnanimatedPieces = () => {

  let staticPieces = [];


  game.board.forEach((row, rowIndex) => {
    row.forEach((piece, colIndex) => {
      if (!piece) return; // Skip empty squares
      if (piece.isAnimated) return;  // Only render static



      const animatedStyle = {
        width: '10%',
        height: (Dimensions.get('window').width) / 10,
        position: 'absolute',
        pointerEvents: 'none',
        transform: [
          { translateX: game.pieceAnimatedValues[piece.pieceId].x },
          { translateY: game.pieceAnimatedValues[piece.pieceId].y },
        ],


      };



      const pieceElement = (
        <Animated.View key={`${rowIndex}-${colIndex}`} style={animatedStyle}>
          <Piece id={piece.pieceId} playerID={piece.playerId} isQueen={piece.isQueen} position={new Animated.ValueXY({x: game.pieceAnimatedValues[piece.pieceId].x, y: game.pieceAnimatedValues[piece.pieceId].y})} />
        </Animated.View>
      );


      staticPieces.push(pieceElement);

    });
  });



  // Render static pieces first, then animated pieces to ensure animated pieces are on top
  return [staticPieces];
};

const renderAnimatedPieces = () => {

  let animatedPieces = [];


  game.board.forEach((row, rowIndex) => {
    row.forEach((piece, colIndex) => {
      if (!piece) return; // Skip empty squares
      if (!piece.isAnimated) return // Only render animated

      forceUpdateZIndex()

      const animatedStyle = {
        width: '10%',
        height: (Dimensions.get('window').width) / 10,
        position: 'absolute',
        pointerEvents: 'none',
        transform: [
          { translateX: game.pieceAnimatedValues[piece.pieceId].x },
          { translateY: game.pieceAnimatedValues[piece.pieceId].y },
        ]
      };

      piece.isAnimated = false




      const pieceElement = (
        <Animated.View key={`${rowIndex}-${colIndex}`} style={{...animatedStyle, zIndex: 100}}>
          <Piece id={piece.pieceId} playerID={piece.playerId} isQueen={piece.isQueen} position={new Animated.ValueXY({x: game.pieceAnimatedValues[piece.pieceId].x, y: game.pieceAnimatedValues[piece.pieceId].y})} />
        </Animated.View>
      );

      animatedPieces.push(pieceElement);
      console.log(piece, 'ANIMATED')

    });
  });



  // Render static pieces first, then animated pieces to ensure animated pieces are on top
  console.log(animatedPieces)
  return [animatedPieces];
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
                  onPress={() => {
                    handlePress(row, col)}
                  }
                >
                </TouchableOpacity>
            )
        }
  };


  return (
    <>
       <View style={{ position: 'relative' }}>
         {/* Game Board */}
         <FlatList
           data={squares}
           renderItem={renderSquare}
           keyExtractor={item => item.id.toString()}
           numColumns={boardSize}
           scrollEnabled={false}
           style={[styles.board]}
         />

         {/* Overlay for Pieces */}
         <View style={styles.piecesOverlay}>

             <View style={{zIndex: 1}}>
               {renderUnanimatedPieces()}
             </View>
             <View style={{zIndex: 2}}>
                {renderAnimatedPieces()}
             </View>

         </View>
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
  piecesOverlay: {
    position: 'absolute',
    top: 0,
    left: 0,
    right: 0,
    bottom: 0,
    // Make sure it's above everything in the same stacking context

    pointerEvents: 'box-none',

  },
  animatedPieces: {
    zIndex: 2
  },
  unanimatedPieces: {
    zIndex: 1
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
