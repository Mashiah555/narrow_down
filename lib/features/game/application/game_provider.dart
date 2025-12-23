import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../domain/game_state.dart';
import '../domain/player.dart';
import '../domain/question.dart';

final gameProvider = NotifierProvider<GameNotifier, GameState>(
  GameNotifier.new,
);

class GameNotifier extends Notifier<GameState> {
  @override
  GameState build() {
    return GameState();
  }

  // --- SETUP ACTIONS ---

  void addPlayer(String name, int teamId) {
    if (name.isEmpty) return;
    final int newId =
        DateTime.now().millisecondsSinceEpoch + Random().nextInt(1000);
    final newPlayer = Player(id: newId, name: name, teamId: teamId);
    state = state.copyWith(players: [...state.players, newPlayer]);
  }

  void setTotalRounds(int rounds) {
    state = state.copyWith(totalRounds: rounds);
  }

  void startGame() {
    // 1. Identify active teams (teams with players)
    final Set<int> teamIds = state.players.map((p) => p.teamId).toSet();
    final List<int> sortedTeamIds = teamIds.toList()..sort();

    // 2. Initialize scores
    final Map<int, int> initialScores = {for (var id in sortedTeamIds) id: 0};

    // 3. Prepare Questions (Mock data extended)
    final initialQuestions = [
      Question(
        id: 1,
        text: 'How long is the Titanic in meters?',
        answer: '269',
      ),
      Question(
        id: 2,
        text: 'In what year was the first iPhone released?',
        answer: '2007',
      ),
      Question(
        id: 3,
        text: 'How many bones are in the human body?',
        answer: '206',
      ),
      Question(
        id: 4,
        text: 'What is the capital city of Australia?',
        answer: 'Canberra',
      ),
      Question(
        id: 5,
        text: 'Who painted the Mona Lisa?',
        answer: 'Leonardo da Vinci',
      ),
      Question(
        id: 6,
        text: 'Which planet is closest to the Sun?',
        answer: 'Mercury',
      ),
    ]..shuffle();

    state = state.copyWith(
      questions: initialQuestions,
      status: GameStatus.playing,
      currentRound: 1,
      currentTeamIndex: 0,
      activeTeamIds: sortedTeamIds,
      currentQuestionIndex: 0,
      matchPhase: MatchPhase.hiding,
      teamScores: initialScores,
      hiddenWordIndices: {},
    );

    _prepareTurn();
  }

  // --- GAMEPLAY ACTIONS ---

  /// Calculates who is hiding based on Round Number and Team List
  void _prepareTurn() {
    final currentTeamId = state.currentTeamId;
    final teamPlayers = state.players
        .where((p) => p.teamId == currentTeamId)
        .toList();

    if (teamPlayers.isEmpty) return;

    // Rule: The player that hides is decided based on the round number
    // Round 1 -> Index 0, Round 2 -> Index 1, etc.
    final hiderIndex = (state.currentRound - 1) % teamPlayers.length;
    final hiderId = teamPlayers[hiderIndex].id;

    state = state.copyWith(
      currentHiderId: hiderId,
      hiddenWordIndices: {},
      matchPhase: MatchPhase.hiding,
    );
  }

  /// Toggles a word's visibility during Hiding Phase
  void toggleWordVisibility(int wordIndex) {
    if (state.matchPhase != MatchPhase.hiding) return;

    final newIndices = Set<int>.from(state.hiddenWordIndices);
    if (newIndices.contains(wordIndex)) {
      newIndices.remove(wordIndex);
    } else {
      newIndices.add(wordIndex);
    }
    state = state.copyWith(hiddenWordIndices: newIndices);
  }

  /// Hider clicks "Done"
  void confirmHiddenWords() {
    if (state.matchPhase != MatchPhase.hiding) return;

    // Ensure at least one word is visible (optional rule, but good for gameplay)
    // or ensure not all words are hidden.
    // For now, we just proceed.

    state = state.copyWith(matchPhase: MatchPhase.guessing);
  }

  /// Guessers click "Reveal"
  void revealAnswer() {
    if (state.matchPhase != MatchPhase.guessing) return;
    state = state.copyWith(matchPhase: MatchPhase.results);
  }

  /// End of match: Score processing
  void completeMatch(bool wasCorrect) {
    if (state.matchPhase != MatchPhase.results) return;

    if (wasCorrect) {
      // Reward: Point for each word hidden
      final points = state.hiddenWordIndices.length;
      final currentTeamId = state.currentTeamId;

      final newScores = Map<int, int>.from(state.teamScores);
      newScores[currentTeamId] = (newScores[currentTeamId] ?? 0) + points;

      state = state.copyWith(teamScores: newScores);
    }

    _advanceGame();
  }

  void _advanceGame() {
    // Move to next team
    int nextTeamIndex = state.currentTeamIndex + 1;
    int nextRound = state.currentRound;
    int nextQuestionIndex = state.currentQuestionIndex + 1;

    // If all teams played this round
    if (nextTeamIndex >= state.activeTeamIds.length) {
      nextTeamIndex = 0;
      nextRound++;
    }

    // Check Game Over
    if (nextRound > state.totalRounds) {
      state = state.copyWith(status: GameStatus.finished);
      return;
    }

    // Check if we ran out of questions (loop back if needed)
    if (nextQuestionIndex >= state.questions.length) {
      nextQuestionIndex = 0;
    }

    state = state.copyWith(
      currentTeamIndex: nextTeamIndex,
      currentRound: nextRound,
      currentQuestionIndex: nextQuestionIndex,
      matchPhase: MatchPhase.hiding, // Reset to start of match
    );

    _prepareTurn();
  }

  void restartGame() {
    state = GameState(players: state.players); // Keep players, reset rest
  }
}
