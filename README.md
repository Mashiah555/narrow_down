# Narrow Down - Code Documentation

This document provides a detailed overview of the source code files for the "Narrow Down" Flutter application. The project is a board-game style app where teams compete by guessing answers to questions with missing words.

## main.dart
- **Purpose**: The entry point of the application.
- **Key Responsibilities**:
  - `main()`: Initializes the Flutter app and wraps the root widget in a `ProviderScope`. This is essential for Riverpod to manage state across the application.
  - `Narrow DownApp`: The root `StatelessWidget`. It configures the `MaterialApp`, sets the visual theme (Teal color scheme), and defines the `SetupScreen` as the home page.

## game_state.dart
- **Purpose**: Defines the immutable state object used by Riverpod to track the entire game's status at any given moment.
- **Key Components**:
  - **Enums**:
    - `GameStatus`: Tracks the high-level state (setup, playing, finished).
    - `MatchPhase`: Tracks the specific stage of a single turn (hiding, guessing, results).
  - **GameState Class**: A data class that holds:
    - *Configuration*: totalRounds, players, questions.
    - *Progress*: currentRound, currentTeamIndex, currentQuestionIndex.
    - *Match Specifics*: hiddenWordIndices (which words are currently obscured), currentHiderId, and activeTeamIds.
    - *Scores*: A map tracking the score for each team.
  - `copyWith`: A utility method standard in Flutter state management, allowing updates to specific fields while keeping the object immutable.

## game_provider.dart
- **Purpose**: Contains the business logic and state management for the game. It acts as the "Brain" of the application.
- **Key Responsibilities**:
  - `GameNotifier`: A Riverpod Notifier class that modifies the `GameState`.
  - **Setup Logic**:
    - `addPlayer`: Adds a new player to a specific team.
    - `startGame`: Initializes scores, shuffles questions, and determines the first playing team.
  - **Game Loop Logic**:
    - `_prepareTurn`: Automatically calculates which player should be the "Hider" based on the round number and team roster (Rotation logic).
    - `toggleWordVisibility`: Logic for the Hiding Phase, allowing the hider to select words to obscure.
    - `revealAnswer`: Transitions the game from Guessing Phase to Results Phase.
    - `completeMatch`: Updates scores if the guess was correct and calls `_advanceGame` to move to the next team or round.

## setup_screen.dart
- **Purpose**: The initial screen where users configure the game session.
- **Key Features**:
  - **Player Input**: Text field and Team dropdown to add players.
  - **Round Selection**: Dropdown to define how many rounds the game will last.
  - **Team Preview**: Visually groups players into Team Cards (Team 1, 2, 3, 4) so users can see the roster.
  - **Validation**: The "Start Game" button remains disabled until valid conditions are met (at least 1 active team, and every active team must have at least 2 players).

## game_screen.dart
- **Purpose**: The main interactive screen where the actual gameplay happens. It adapts its UI dynamically based on the current `MatchPhase`.
- **Key Features**:
  - **Dynamic Background**: The background color animates to match the color of the team currently playing.
  - **Phase Rendering**:
    - *Hiding Phase*: Shows the full question. Words are interactive ActionChips that can be tapped to toggle their visibility.
    - *Guessing Phase*: Shows the question with selected words replaced by black boxes (placeholders).
    - *Results Phase*: Reveals the full question and answer, displaying "Correct" and "Wrong" buttons to resolve the turn.
  - **Scoreboard**: A top widget that displays the current scores for all active teams.

## player.dart
- **Purpose**: A simple data model representing a participant.
- **Attributes**:
  - `id`: Unique identifier (int).
  - `name`: Display name.
  - `teamId`: The team the player belongs to (1-4).

## question.dart
- **Purpose**: A simple data model representing a trivia question.
- **Attributes**:
  - `id`: Unique identifier.
  - `text`: The full question string (e.g., "How tall is the Eiffel Tower?").
  - `answer`: The correct answer string.
