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

    // Force RTL for Hebrew layout
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Builder(
        builder: (context) {
          // --- GAME OVER ---
          if (gameState.status == GameStatus.finished) {
            return Scaffold(
              appBar: AppBar(title: const Text("סוף המשחק")),
              body: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "תוצאות סופיות",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 20),
                    ...gameState.teamScores.entries.map(
                      (e) => Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Text(
                          "קבוצה ${e.key}: ${e.value} נקודות",
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
                      child: const Text("חזרה להגדרות"),
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
              elevation: 0,
              centerTitle: true,
              title: Text(
                "סיבוב ${gameState.currentRound}/${gameState.totalRounds}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.only(left: 16.0),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        "קבוצה ${gameState.currentTeamId}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            body: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [activeColor, Colors.white],
                ),
              ),
              child: Column(
                children: [
                  // SCOREBOARD
                  _buildScoreboard(gameState),

                  // MAIN CONTENT AREA WITH ANIMATION
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 600),
                      switchInCurve: Curves.easeOutBack,
                      switchOutCurve: Curves.easeIn,
                      transitionBuilder:
                          (Widget child, Animation<double> animation) {
                            return FadeTransition(
                              opacity: animation,
                              child: SlideTransition(
                                position: Tween<Offset>(
                                  begin: const Offset(0.0, 0.2),
                                  end: Offset.zero,
                                ).animate(animation),
                                child: child,
                              ),
                            );
                          },
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
        },
      ),
    );
  }

  Widget _buildScoreboard(GameState gameState) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: gameState.activeTeamIds.map((tid) {
          final isPlaying = tid == gameState.currentTeamId;
          return AnimatedScale(
            scale: isPlaying ? 1.1 : 1.0,
            duration: const Duration(milliseconds: 300),
            child: Column(
              children: [
                Text(
                  "קבוצה $tid",
                  style: TextStyle(
                    fontWeight: isPlaying ? FontWeight.bold : FontWeight.normal,
                    color: isPlaying ? Colors.black : Colors.black54,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  "${gameState.teamScores[tid] ?? 0}",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }).toList(),
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

    // Logic: Pad sentence to always have 10 items
    final originalWords = question.text.split(' ');
    final List<String> words = List.from(originalWords);
    while (words.length < 10) {
      words.add("---"); // Padding character
    }

    switch (state.matchPhase) {
      // --- PHASE 1: HIDING ---
      case MatchPhase.hiding:
        return KeyedSubtree(
          key: const ValueKey("HidingPhase"),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    Text(
                      "מסתיר/ה: $playerName",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "לחצו על מילים כדי להסתיר אותן.\nלחצו על סיום כשתסיימו.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  itemCount: words.length,
                  itemBuilder: (context, index) {
                    final isHidden = state.hiddenWordIndices.contains(index);
                    return _buildWordCard(
                      text: words[index],
                      isHidden: isHidden,
                      onTap: () {
                        ref
                            .read(gameProvider.notifier)
                            .toggleWordVisibility(index);
                      },
                    );
                  },
                ),
              ),
              _buildBottomAction(
                context: context,
                label: "סיום - העבירו מכשיר",
                icon: Icons.check,
                onPressed: () {
                  ref.read(gameProvider.notifier).confirmHiddenWords();
                },
              ),
            ],
          ),
        );

      // --- PHASE 2: GUESSING ---
      case MatchPhase.guessing:
        return KeyedSubtree(
          key: const ValueKey("GuessingPhase"),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  children: [
                    Text(
                      "קבוצה ${state.currentTeamId} מנחשת",
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "נחשו את המשפט לפי המילים הגלויות!",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.black54),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 8,
                  ),
                  itemCount: words.length,
                  itemBuilder: (context, index) {
                    final isHidden = state.hiddenWordIndices.contains(index);
                    return _buildWordCard(
                      text: words[index],
                      isHidden: isHidden,
                      isGuessing: true,
                      onTap: () {}, // No interaction
                    );
                  },
                ),
              ),
              _buildBottomAction(
                context: context,
                label: "חשוף תשובה",
                icon: Icons.visibility,
                onPressed: () {
                  ref.read(gameProvider.notifier).revealAnswer();
                },
              ),
            ],
          ),
        );

      // --- PHASE 3: RESULTS ---
      case MatchPhase.results:
        final hiddenCount = state.hiddenWordIndices.length;
        return KeyedSubtree(
          key: const ValueKey("ResultsPhase"),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    "המשפט המלא היה:",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Text(
                      question.text,
                      style: const TextStyle(fontSize: 24, height: 1.3),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Text(
                    "תשובה: ${question.answer}",
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40),
                  Text(
                    "ניקוד: $hiddenCount נקודות",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red.shade100,
                            foregroundColor: Colors.red.shade900,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            ref
                                .read(gameProvider.notifier)
                                .completeMatch(false);
                          },
                          child: const Text(
                            "שגוי",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green.shade100,
                            foregroundColor: Colors.green.shade900,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          onPressed: () {
                            ref.read(gameProvider.notifier).completeMatch(true);
                          },
                          child: const Text(
                            "נכון",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
    }
  }

  Widget _buildWordCard({
    required String text,
    required bool isHidden,
    required VoidCallback onTap,
    bool isGuessing = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isHidden ? Colors.black87 : Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: isHidden ? 0.0 : 0.1),
                blurRadius: isHidden ? 0 : 8,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(
              color: isHidden
                  ? Colors.transparent
                  : Colors.grey.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isHidden && isGuessing)
                Icon(
                  Icons.lock,
                  color: Colors.white.withValues(alpha: 0.5),
                  size: 20,
                )
              else
                Expanded(
                  child: Text(
                    isHidden && isGuessing ? "מוסתר" : text,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                      color: isHidden ? Colors.white : Colors.black87,
                      decoration: (isHidden && !isGuessing)
                          ? TextDecoration.lineThrough
                          : null,
                      decorationColor: Colors.white70,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomAction({
    required BuildContext context,
    required String label,
    required IconData icon,
    required VoidCallback onPressed,
  }) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: Icon(icon),
            label: Text(label),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: Colors.black87,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
            ),
            onPressed: onPressed,
          ),
        ),
      ),
    );
  }
}
