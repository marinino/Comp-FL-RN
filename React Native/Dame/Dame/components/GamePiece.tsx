export default class GamePiece {
  pieceId: string;
  playerId: number;
  isQueen: boolean;
  isAnimated: boolean;

  constructor(pieceId: string, playerId: number, isAnimated = false, isQueen: boolean = false) {
    this.pieceId = pieceId
    this.playerId = playerId;
    this.isQueen = isQueen;
    this.isAnimated = isAnimated;
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
