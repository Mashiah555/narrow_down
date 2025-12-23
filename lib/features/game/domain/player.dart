class Player {
  final int id;
  final String name;
  final int teamId;
  int score;

  // Constructor
  // in Dart, { ... } means named parameters.
  // 'required' means you MUST provide it when creating the object.
  Player({
    required this.id,
    required this.name,
    required this.teamId,
    this.score = 0, // Default value
  });
}
