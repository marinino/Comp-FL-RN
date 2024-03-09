class GamePiece {
  int playerId;
  bool isQueen;
  bool isAnimated;

  GamePiece({required this.playerId, this.isQueen = false, this.isAnimated = false});

  // Eine Methode, um den Spielstein zur Dame zu machen
  void promoteToQueen() {
    isQueen = true;
  }

  int getPlayedId(){
    return playerId;
  }

  @override
  String toString() {
    return 'GamePiece: Spieler($playerId), isQueen: $isQueen';
  }
}