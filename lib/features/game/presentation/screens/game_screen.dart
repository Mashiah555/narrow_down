import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../application/game_provider.dart';
import '../../domain/game_state.dart';

class GameScreen extends ConsumerWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final gameState = ref.watch(gameProvider);
    final notifier = ref.read(gameProvider.notifier);

    // --- GAME OVER ---
    if (gameState.status == GameStatus.finished) {
      return Scaffold(
        appBar: AppBar(title: const Text("Game Over")),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "Final Scores",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 20),
              ...gameState.teamScores.entries.map(
                (e) => Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    "Team ${e.key}: ${e.value} pts",
                    style: const TextStyle(fontSize: 20),
                  ),
                ),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  notifier.restartGame();
                  Navigator.pop(context);
                },
                child: const Text("Back to Setup"),
              ),
            ],
          ),
        ),
      );
    }

    // --- ACTIVE GAME ---

    // Determine Colors
    final teamColors = {
      1: Colors.blue.shade100,
      2: Colors.green.shade100,
      3: Colors.purple.shade100,
      4: Colors.orange.shade100,
    };
    final activeColor =
        teamColors[gameState.currentTeamId] ?? Colors.grey.shade200;

    // Find Current Player Name
    final currentPlayer = gameState.players.firstWhere(
      (p) => p.id == gameState.currentHiderId,
      orElse: () => gameState.players.first, // Fallback
    );

    return Scaffold(
      appBar: AppBar(
        backgroundColor: activeColor,
        title: Text("Round ${gameState.currentRound}/${gameState.totalRounds}"),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Center(
              child: Text(
                "Team ${gameState.currentTeamId}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        color: activeColor,
        child: Column(
          children: [
            // SCOREBOARD
            Container(
              color: Colors.white.withValues(alpha: 0.5),
              padding: const EdgeInsets.all(8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: gameState.activeTeamIds.map((tid) {
                  final isPlaying = tid == gameState.currentTeamId;
                  return Column(
                    children: [
                      Text(
                        "Team $tid",
                        style: TextStyle(
                          fontWeight: isPlaying
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                      Text(
                        "${gameState.teamScores[tid] ?? 0}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  );
                }).toList(),
              ),
            ),

            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: _buildPhaseContent(
                  context,
                  ref,
                  gameState,
                  currentPlayer.name,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPhaseContent(
    BuildContext context,
    WidgetRef ref,
    GameState state,
    String playerName,
  ) {
    final question = state.currentQuestion;
    if (question == null) return const SizedBox.shrink();

    // Split text into words for interactivity
    final words = question.text.split(' ');

    switch (state.matchPhase) {
      // --- PHASE 1: HIDING ---
      case MatchPhase.hiding:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Hider: $playerName",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text(
                "Tap words to hide them. Click Done and pass to your team.",
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 30),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(words.length, (index) {
                final isHidden = state.hiddenWordIndices.contains(index);
                return ActionChip(
                  label: Text(words[index]),
                  backgroundColor: isHidden ? Colors.black87 : Colors.white,
                  labelStyle: TextStyle(
                    color: isHidden ? Colors.white : Colors.black,
                  ),
                  onPressed: () {
                    ref.read(gameProvider.notifier).toggleWordVisibility(index);
                  },
                );
              }),
            ),
            const SizedBox(height: 50),
            ElevatedButton.icon(
              icon: const Icon(Icons.check),
              label: const Text("DONE - PASS DEVICE"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: () {
                ref.read(gameProvider.notifier).confirmHiddenWords();
              },
            ),
          ],
        );

      // --- PHASE 2: GUESSING ---
      case MatchPhase.guessing:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              "Team ${state.currentTeamId} Guessing",
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const Text(
              "Guess the question based on visible words!",
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(words.length, (index) {
                final isHidden = state.hiddenWordIndices.contains(index);
                if (isHidden) {
                  // Hidden word placeholder
                  return Container(
                    width: 60,
                    height: 30,
                    decoration: BoxDecoration(
                      color: Colors.black26,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  );
                }
                return Chip(label: Text(words[index]));
              }),
            ),
            const SizedBox(height: 50),
            ElevatedButton.icon(
              icon: const Icon(Icons.visibility),
              label: const Text("REVEAL ANSWER"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 30,
                  vertical: 15,
                ),
                textStyle: const TextStyle(fontSize: 18),
              ),
              onPressed: () {
                ref.read(gameProvider.notifier).revealAnswer();
              },
            ),
          ],
        );

      // --- PHASE 3: RESULTS ---
      case MatchPhase.results:
        final hiddenCount = state.hiddenWordIndices.length;
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "The Full Question Was:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            Text(
              question.text,
              style: const TextStyle(fontSize: 24),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 10),
            Text(
              "Answer: ${question.answer}",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 40),
            Text(
              "Reward: $hiddenCount points",
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red.shade100,
                    foregroundColor: Colors.red,
                  ),
                  onPressed: () {
                    ref.read(gameProvider.notifier).completeMatch(false);
                  },
                  child: const Text("WRONG"),
                ),
                const SizedBox(width: 20),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green.shade100,
                    foregroundColor: Colors.green.shade900,
                  ),
                  onPressed: () {
                    ref.read(gameProvider.notifier).completeMatch(true);
                  },
                  child: const Text("CORRECT"),
                ),
              ],
            ),
          ],
        );
    }
  }
}
