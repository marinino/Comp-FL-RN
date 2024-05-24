class GamePiece {
  int playerId;
  bool isQueen;
  bool isAnimated;

  GamePiece({required this.playerId, this.isQueen = false, this.isAnimated = false});

  // Promotes piece to crowned piece
  void promoteToQueen() {
    isQueen = true;
  }

  int getPlayedId(){
    return playerId;
  }

  @override
  String toString() {
    return 'GamePiece: Player($playerId), isQueen: $isQueen';
  }
}