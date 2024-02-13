import React, {useState} from 'react';
import { StyleSheet, FlatList, TouchableOpacity, View, Text } from 'react-native';
import DameGame from './DameGame'; // Pfad zu Ihrer DameGame-Klasse

const GameBoard = () => {
    const [game, setGame] = useState(() => new DameGame());

    const [updateCounter, setUpdateCounter] = useState(0);

    const forceUpdate = () => {
      setUpdateCounter(updateCounter + 1);
    };

    const handlePress = (row, column) => {
      // Logik, um zu bestimmen, ob dies ein gültiger Zug ist, und um den Zug durchzuführen
      // Beispiel: Wenn ein Spieler einen Stein ausgewählt hat und nun ein Ziel auswählt
      // game.movePiece(startRow, startCol, row, col);
      game.handlePressDeep(row, column)

      // Aktualisieren Sie den Zustand, um die UI neu zu rendern
      setGame(game)
      forceUpdate(); // Dies wird die Komponente dazu bringen, sich neu zu rendern
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

  const renderSquare = ({ item }) => {
    const row = Math.floor(item.id / game.boardSize);
    const col = item.id % game.boardSize;
    const piece = game.board[row][col];

    return (

        <TouchableOpacity
          style={[styles.square, item.isDark ? styles.darkSquare : styles.lightSquare]}
          onPress={() => handlePress(row, col)}
        >
          {piece && (
            <View style={[styles.piece, { backgroundColor: piece.playerId === 1 ? 'white' : 'black' }]}>
              <Text style={[styles.pieceText, , { color: piece.playerId === 1 ? 'black' : 'white' }]}>
                {piece.isQueen ? 'D' : ''}
              </Text>
            </View>
          )}
        </TouchableOpacity>

    );
  };


  return (
    <>
        <FlatList
          data={squares}
          renderItem={renderSquare}
          keyExtractor={item => item.id.toString()}
          numColumns={boardSize}
        />

        <View style={styles.statusContainer}>
            <Text style={styles.statusText}>{game.stateString}</Text>
        </View>
    </>
  );
};

const styles = StyleSheet.create({
  square: {
    width: '10%', // 10 Spalten
    height: '10%',
    aspectRatio: 1, // Quadratische Felder
    alignItems: 'center',
    justifyContent: 'center',
  },
  darkSquare: {
    backgroundColor: 'brown',
  },
  lightSquare: {
    backgroundColor: 'beige',
  },
  piece: {
    width: '60%', // Größe des Spielsteins
    height: '60%',
    borderRadius: 50, // Kreisform
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
  }
});

export default GameBoard;
