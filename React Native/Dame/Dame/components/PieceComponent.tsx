// GamePiece.tsx
import React from 'react';
import { View, Text, StyleSheet, Animated } from 'react-native';

interface PieceProps {
  id: string;
  playerID: number;
  isQueen?: boolean;
  position: Animated.ValueXY;
  opacity: Animated.Value
}

const Piece: React.FC<PieceProps> = ({ id, playerID, isQueen = false, position}) => {
  const pieceStyle = {
    ...styles.piece,
    backgroundColor: playerID === 1 ? 'white' : 'black',
    borderWidth: isQueen ? 2 : 0,
    borderColor: isQueen ? 'gold' : 'transparent',
  };

  return (
      <Animated.View // Change this from View to Animated.View
        style={[
          pieceStyle,
          {
            transform: position.getTranslateTransform(), // Use the animated position here
          },
        ]}
      >
        {isQueen && <Text style={styles.queenText}>Q</Text>}
      </Animated.View>
    );
};

const styles = StyleSheet.create({
  piece: {
    width: '85%',
    height: '85%',
    borderRadius: 50,
    justifyContent: 'center',
    alignItems: 'center',
  },
  queenText: {
    color: 'red',
    fontWeight: 'bold',
  },
});

export default Piece;
