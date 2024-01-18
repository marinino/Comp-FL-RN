export default class GamePiece {
  playerId: number;
  isQueen: boolean;

  constructor(playerId: number, isQueen: boolean = false) {
    this.playerId = playerId;
    this.isQueen = isQueen;
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
