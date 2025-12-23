import 'player.dart';
import 'question.dart';

enum GameStatus { setup, playing, finished }

enum MatchPhase { hiding, guessing, results }

class GameState {
  final List<Player> players;
  final List<Question> questions;
  final GameStatus status;

  // Game Configuration
  final int totalRounds;

  // Current Progress
  final int currentRound;
  final int currentTeamIndex; // Index in the activeTeams list
  final List<int> activeTeamIds; // List of team IDs participating
  final int currentQuestionIndex;

  // Match Specifics
  final MatchPhase matchPhase;
  final Set<int>
  hiddenWordIndices; // Indices of words hidden in the current question
  final int currentHiderId; // ID of the player currently hiding

  // Scores: Map<TeamId, Score>
  final Map<int, int> teamScores;

  GameState({
    this.players = const [],
    this.questions = const [],
    this.status = GameStatus.setup,
    this.totalRounds = 3,
    this.currentRound = 1,
    this.currentTeamIndex = 0,
    this.activeTeamIds = const [],
    this.currentQuestionIndex = 0,
    this.matchPhase = MatchPhase.hiding,
    this.hiddenWordIndices = const {},
    this.currentHiderId = -1,
    this.teamScores = const {},
  });

  Question? get currentQuestion =>
      questions.isNotEmpty && currentQuestionIndex < questions.length
      ? questions[currentQuestionIndex]
      : null;

  int get currentTeamId =>
      activeTeamIds.isNotEmpty ? activeTeamIds[currentTeamIndex] : -1;

  GameState copyWith({
    List<Player>? players,
    List<Question>? questions,
    GameStatus? status,
    int? totalRounds,
    int? currentRound,
    int? currentTeamIndex,
    List<int>? activeTeamIds,
    int? currentQuestionIndex,
    MatchPhase? matchPhase,
    Set<int>? hiddenWordIndices,
    int? currentHiderId,
    Map<int, int>? teamScores,
  }) {
    return GameState(
      players: players ?? this.players,
      questions: questions ?? this.questions,
      status: status ?? this.status,
      totalRounds: totalRounds ?? this.totalRounds,
      currentRound: currentRound ?? this.currentRound,
      currentTeamIndex: currentTeamIndex ?? this.currentTeamIndex,
      activeTeamIds: activeTeamIds ?? this.activeTeamIds,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      matchPhase: matchPhase ?? this.matchPhase,
      hiddenWordIndices: hiddenWordIndices ?? this.hiddenWordIndices,
      currentHiderId: currentHiderId ?? this.currentHiderId,
      teamScores: teamScores ?? this.teamScores,
    );
  }
}
