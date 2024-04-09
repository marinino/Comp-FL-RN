import { View, Text, StyleSheet, Animated } from 'react-native';

export default class GamePiece {
  pieceId: string;
  playerId: number;
  isQueen: boolean;
  isAnimated: boolean;
  opacity: Animated.Value

  constructor(pieceId: string, playerId: number, isAnimated = false, isQueen: boolean = false, opacity = new Animated.Value(1) ) {
    this.pieceId = pieceId
    this.playerId = playerId;
    this.isQueen = isQueen;
    this.isAnimated = isAnimated;
    this.opacity = opacity
  }

  promoteToQueen(): void {
    this.isQueen = true;
  }

  getPlayedId(): number {
    return this.playerId;
  }

  toString(): string {
    return `GamePiece: Spieler(${this.playerId}), isQueen: ${this.isQueen}`;
  }
}
