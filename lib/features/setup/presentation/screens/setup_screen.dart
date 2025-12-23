import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/game/application/game_provider.dart';
import '../../../../features/game/domain/player.dart';
import '../../../game/presentation/screens/game_screen.dart';

class SetupScreen extends ConsumerStatefulWidget {
  const SetupScreen({super.key});

  @override
  ConsumerState<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends ConsumerState<SetupScreen> {
  final TextEditingController _nameController = TextEditingController();
  int _selectedTeam = 1;
  int _selectedRounds = 3; // Default rounds

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _addPlayer() {
    final name = _nameController.text.trim();
    if (name.isNotEmpty) {
      ref.read(gameProvider.notifier).addPlayer(name, _selectedTeam);
      _nameController.clear();
      setState(() {
        if (_selectedTeam < 4) {
          _selectedTeam++;
        } else {
          _selectedTeam = 1;
        }
      });
    }
  }

  void _startGame() {
    final notifier = ref.read(gameProvider.notifier);
    notifier.setTotalRounds(_selectedRounds);
    notifier.startGame();

    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (context) => const GameScreen()));
  }

  bool _canStartGame(List<Player> players) {
    if (players.isEmpty) return false;
    final Map<int, int> teamCounts = {};
    for (var p in players) {
      teamCounts[p.teamId] = (teamCounts[p.teamId] ?? 0) + 1;
    }
    // Need at least 1 team, and every active team needs 2+ players
    if (teamCounts.isEmpty) return false;
    for (var count in teamCounts.values) {
      if (count < 2) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    final gameState = ref.watch(gameProvider);
    final players = gameState.players;
    final bool isStartEnabled = _canStartGame(players);

    return Scaffold(
      appBar: AppBar(title: const Text("Game Setup")),
      body: Column(
        children: [
          // --- INPUT CARD ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  children: [
                    TextField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: "Player Name",
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.person),
                      ),
                      onSubmitted: (_) => _addPlayer(),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        const Text("Team: "),
                        DropdownButton<int>(
                          value: _selectedTeam,
                          items: [1, 2, 3, 4]
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text("Team $v"),
                                ),
                              )
                              .toList(),
                          onChanged: (v) => setState(() => _selectedTeam = v!),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          onPressed: _addPlayer,
                          icon: const Icon(Icons.add),
                          label: const Text("Join"),
                        ),
                      ],
                    ),
                    const Divider(),
                    // ROUND SELECTOR
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "Rounds:",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        DropdownButton<int>(
                          value: _selectedRounds,
                          items: [1, 2, 3, 5, 10]
                              .map(
                                (v) => DropdownMenuItem(
                                  value: v,
                                  child: Text("$v Rounds"),
                                ),
                              )
                              .toList(),
                          onChanged: (v) =>
                              setState(() => _selectedRounds = v!),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- TEAM PREVIEWS ---
          Expanded(
            child: players.isEmpty
                ? const Center(child: Text("Add players to start..."))
                : SingleChildScrollView(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            children: [
                              _buildTeamCard(1, players),
                              _buildTeamCard(3, players),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            children: [
                              _buildTeamCard(2, players),
                              _buildTeamCard(4, players),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),

          // --- START BUTTON ---
          Container(
            padding: const EdgeInsets.all(16),
            width: double.infinity,
            child: FilledButton(
              onPressed: isStartEnabled ? _startGame : null,
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: isStartEnabled ? Colors.green : Colors.grey,
              ),
              child: Text(
                isStartEnabled ? "START GAME" : "Needs 2+ players per team",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamCard(int teamId, List<Player> allPlayers) {
    final teamPlayers = allPlayers.where((p) => p.teamId == teamId).toList();
    final List<Color> teamColors = [
      Colors.blue.shade100,
      Colors.green.shade100,
      Colors.purple.shade100,
      Colors.orange.shade100,
    ];

    if (teamPlayers.isEmpty) return const SizedBox.shrink();

    return Card(
      color: teamColors[teamId - 1],
      margin: const EdgeInsets.all(4),
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          children: [
            Text(
              "Team $teamId",
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            ...teamPlayers.map((p) => Text(p.name)),
          ],
        ),
      ),
    );
  }
}
