# cw_odin Game Design Document

## 1. Overview

`cw_odin` is a compact Odin/Raylib word-and-inventory game built around two connected play modes:

- **Cross**: a 7x7 letter board where the player spends letter fragments and runes to place letters on tiles.
- **Wordle**: an unlimited sequence of five-letter word puzzles that rewards fragments and experience.

The game loop is a resource cycle. Wordle solves generate fragments and EXP. Fragments can be placed onto the Cross board for large EXP rewards, or crafted into runes. Runes are then placed over matching fragments on the Cross board for even larger EXP rewards.

The current build is a local single-player prototype with keyboard and mouse input, responsive scaling, no persistence, and no audio.

## 2. High Concept

The player alternates between solving word puzzles and filling a cross-style board with earned letters. The board has two layers:

- **Fragments** are the base letter layer.
- **Runes** are the upgraded letter layer and can only be placed on top of matching fragments.

The design encourages the player to build letter inventory in Wordle, spend that inventory strategically on the Cross board, and use crafting to convert excess fragments into higher-value runes.

## 3. Platforms And Technology

- **Language**: Odin
- **Framework**: Raylib through Odin vendor bindings
- **Window**: Resizable desktop window
- **Base resolution**: 1280x720
- **Target framerate**: 60 FPS
- **Rendering model**: Immediate-mode Raylib drawing via an internal render command buffer

The game uses a fixed design resolution and scales UI and board elements proportionally to the current window size.

## 4. Core Player Experience

The player starts on a title screen, then enters the title-style mode selector at the top of the screen showing `Cross` and `Wordle`. The active mode is highlighted.

The global player progression is represented by **EXP**, shown in the upper-left corner. EXP is gained by:

- Placing fragments on the Cross board.
- Placing runes on the Cross board.
- Crafting runes.
- Solving Wordle levels.

Inventory is letter-specific. The player tracks counts for A-Z fragments or A-Z runes depending on the active inventory view.

## 5. Game Modes

### 5.1 Cross Mode

Cross mode is the board side of the game where the player places fragments or runes on a 7x7 board.

### 5.2 Wordle Mode

Wordle mode is a sequence of five-letter guessing puzzles. The player enters guesses, receives per-letter feedback, and earns a reward when the puzzle is solved.

The current solution is selected from a fixed solution list using the current level number modulo the solution list length. This means the solution sequence loops after the tenth level.

Current solution list:

1. CRANE
2. SLATE
3. BRICK
4. PLANT
5. GHOST
6. FLAME
7. STORM
8. CHARM
9. BLOOM
10. TRACE

## 6. Cross Board Design

### 6.1 Board Layout

The Cross board is a centered 7x7 grid.

- **Columns**: 7
- **Rows**: 7
- **Base cell size**: 64 px
- **Base gap**: 4 px

Each tile can hold:

- Zero or one fragment.
- Zero or one rune.

Fragments are drawn as full-size sky-blue letter tiles. Runes are drawn as smaller purple letter tiles inset over the fragment layer.

### 6.2 Selector

The selector marks the tile where a placement begins.

Initial selector position:

- Row: center row
- Column: center column

The selector can be moved with arrow keys or set directly by left-clicking a board tile.

The selector has an orientation:

- **Across**: letters advance to the right.
- **Down**: letters advance downward.

The orientation is toggled with `Space`.

### 6.3 Placement Buffer

The player types letters to fill a selector buffer. The buffer has a maximum length of five letters.

When the player submits the buffer, the game attempts to place every buffered letter starting from the selector position and following the current orientation.

The buffer can be edited with:

- Letter keys A-Z: append a letter.
- `Backspace`: remove the last buffered letter.
- `Enter`: submit the buffered letters.

### 6.4 Fragment Placement Rules

Fragment placement is active when the inventory view is showing fragments.

Rules:

- The selector buffer must contain at least one letter.
- The full placement must fit inside the board.
- Every target tile must have an empty fragment slot.
- The player must own enough fragments for every submitted letter.
- On success, each placed fragment is removed from inventory.
- On success, each target tile receives the submitted fragment letter.
- The selector buffer is cleared after successful placement.

Fragment placement does not require the submitted letters to form a dictionary word. The current implementation treats the buffer as freeform letter placement.

### 6.5 Rune Placement Rules

Rune placement is active when the inventory view is showing runes.

Rules:

- The selector buffer must contain at least one letter.
- The full placement must fit inside the board.
- Every target tile must already contain the same fragment letter as the submitted rune letter.
- Every target tile must have an empty rune slot.
- The player must own enough runes for every submitted letter.
- On success, each placed rune is removed from inventory.
- On success, each target tile receives the submitted rune letter.
- The selector buffer is cleared after successful placement.

This creates an upgrade path where fragments establish letters on the board and runes complete or empower those same letters.

### 6.6 Cross Rewards

Each tile has fixed EXP rewards:

- Fragment placement: **500 EXP per tile**
- Rune placement: **1000 EXP per tile**

After a successful Cross placement, the most recent Cross reward is shown as `+N EXP` between the board and inventory HUD.

## 7. Crafting Design

Crafting is a standalone view that lets the player spend fragments to create runes.

### 7.1 Crafting Input

The player types letters into a five-slot crafting selection.

Controls:

- Letter keys A-Z: add a fragment letter to the selection.
- `Backspace`: remove the last selected letter.
- `Enter`: submit the selected recipe.
- `Left Shift` or `Right Shift`: toggle the displayed inventory between fragments and runes.

The player cannot select more copies of a letter than they currently own in fragment inventory.

### 7.2 Crafting Recipes

There are two implemented rune recipes.

**Matching Rune**

- Requirement: exactly four selected fragments.
- All four selected fragments must be the same letter.
- Result: one rune of that same letter.

Example: `AAAA` creates one `A` rune.

**Random Rune**

- Requirement: exactly five selected fragments.
- All five selected fragments must be different letters.
- Result: one random rune from A-Z.

Example: `ABCDE` spends one each of A, B, C, D, and E, then creates a random rune.

### 7.3 Crafting Rewards

Successful crafting:

- Spends the selected fragments.
- Adds one rune to rune inventory.
- Grants **250 EXP**.
- Stores the latest crafted rune for display.
- Clears the crafting selection.

The crafting screen shows recipe status:

- `Incomplete Recipe`
- `Matching Rune`
- `Random Rune`

## 8. Wordle Design

### 8.1 Wordle Core Loop

The player attempts to guess a five-letter solution. Guesses are freeform five-letter entries; there is currently no dictionary validation.

Input:

- Letter keys A-Z: append to current guess.
- `Backspace`: remove the last letter.
- `Enter`: submit a complete five-letter guess.

Only complete five-letter guesses can be submitted.

### 8.2 Feedback Rules

Submitted guesses are evaluated using standard Wordle-style duplicate-aware feedback.

Feedback states:

- **Correct**: green, letter is in the correct position.
- **Present**: gold, letter is in the solution but a different position.
- **Miss**: gray, letter is not available in the solution.
- **Empty**: dark gray, used for the current input row before submission.

Evaluation happens in two passes:

1. Exact matches are marked Correct.
2. Remaining non-correct letters are matched against remaining solution letter counts and marked Present or Miss.

### 8.3 Winning A Level

When every submitted letter is Correct:

- The Wordle substate changes from Playing to Won.
- The solved word is stored for the win screen.
- The game randomly chooses one letter from the solution as the fragment reward.
- The matching fragment inventory count increases by one.
- The player gains **100 EXP**.
- The win screen displays the solution, reward fragment, and EXP reward.

Pressing `Enter` on the win screen advances to the next level.

### 8.4 Level Progression

When continuing after a win:

- The completed level is copied into Wordle history.
- Current guesses are cleared.
- Current input is cleared.
- Win reward fields are reset.
- Wordle returns to Playing state.
- View mode returns to Current.
- History selection is cleared.
- Scroll position resets.
- Level increments by one.

The level label displays level numbers as one-based values: internal level `0` is shown as `Level 1`.

### 8.5 Attempt Count

There is no maximum guess count. The guesses list is dynamic, and the visible board scrolls when the number of attempts exceeds available vertical space.

## 9. Wordle History

Solved Wordle levels are stored in a history list.

Each history record contains:

- Submitted guesses and feedback.
- Level number.
- Solved word.
- Reward fragment.
- Reward EXP.

History navigation:

- `Left`: move from current level to the most recent solved level, or move to an older solved level.
- `Right`: move to a newer solved level, or return to the current level after the newest history entry.
- `Space`: return directly to the current level.
- `Up` / `Down`: scroll attempts when the visible area cannot show all rows.

When viewing history, input for the current Wordle level is disabled.

## 10. Inventory And Economy

### 10.1 Inventory Types

The game tracks two 26-letter inventories:

- **Fragments**: one count per letter A-Z.
- **Runes**: one count per letter A-Z.

The displayed inventory is controlled by the fragment/rune view toggle.

### 10.2 Sources And Sinks

Fragment sources:

- Solving Wordle grants one random fragment from the solved word.
- Debug input grants ten fragments of every letter.

Fragment sinks:

- Placing fragments on the Cross board.
- Crafting runes.

Rune sources:

- Crafting.
- Debug input grants one rune of every letter.

Rune sinks:

- Placing runes on the Cross board.

EXP sources:

- Wordle solve: 100 EXP.
- Fragment board placement: 500 EXP per tile.
- Rune board placement: 1000 EXP per tile.
- Rune crafting: 250 EXP.

EXP currently has no spend or level-up behavior. It functions as a cumulative score.

## 11. Controls

### 11.1 Global Controls

| Input | Action |
| --- | --- |
| `1` | Switch to Wordle view |
| `2` | Switch to Cross view |
| `3` | Switch to Crafting view |
| Window resize | Recalculate layout scale and positions |

### 11.2 Cross Game Controls

| Input | Action |
| --- | --- |
| Arrow keys | Move selector |
| Left mouse click | Select board tile under cursor |
| `Space` | Toggle selector direction across/down |
| A-Z | Add letter to placement buffer |
| `Backspace` | Remove last buffered letter |
| `Enter` | Submit placement buffer |
| `Left Shift` / `Right Shift` | Toggle fragment/rune inventory and placement layer |
| `0` | Debug: add 10 fragments and 1 rune for every letter |

### 11.3 Cross Crafting Controls

| Input | Action |
| --- | --- |
| A-Z | Add fragment letter to crafting selection |
| `Backspace` | Remove last selected fragment |
| `Enter` | Submit crafting recipe |
| `Left Shift` / `Right Shift` | Toggle fragment/rune inventory display |
| `0` | Debug: add 10 fragments and 1 rune for every letter |

### 11.4 Wordle Controls

| Input | Action |
| --- | --- |
| A-Z | Add letter to current guess |
| `Backspace` | Remove last guess letter |
| `Enter` | Submit guess while playing |
| `Enter` | Continue to next level after winning |
| `Left` | View previous solved level |
| `Right` | View next solved level or return to current level |
| `Space` | Return to current level |
| `Up` | Scroll attempts up |
| `Down` | Scroll attempts down |

## 12. UI And Visual Design

### 12.1 Global UI

The background is a dark neutral color. The active mode title is highlighted with a white rectangle and dark text. EXP is shown in gold.

### 12.2 Color Language

- **Fragments**: sky blue
- **Runes**: purple
- **EXP**: gold
- **Wordle Correct**: green
- **Wordle Present**: gold
- **Wordle Miss**: gray
- **Empty tiles**: dark gray
- **Text**: white or light gray

### 12.3 Render Layers

The renderer organizes draw commands into three buffers:

- **World**: board tiles, Wordle tiles, crafting tiles.
- **UI**: title, EXP, labels, inventory, reward text.
- **Overlay**: Cross selector outlines and placement preview letters.

The buffers are flushed in world, UI, overlay order.

## 13. State Model

The central `GameState` owns all gameplay state:

- Cross grid.
- Selector and selector buffer.
- Wordle state.
- Fragment inventory.
- Rune inventory.
- Total EXP.
- Latest Cross reward EXP.
- Active fragment/rune view.
- Active view.
- Crafting state.
- Current screen dimensions.

Important nested state:

- `Grid` owns tiles, fragment layer, rune layer, tile EXP values, and layout data.
- `WordleState` owns current guesses, history, current input, level, substate, view mode, selected history index, scroll position, and win rewards.
- `CraftingState` owns selected fragments, selected count, and latest crafted rune.

## 14. Game Flow

### 14.1 New Session

On launch:

- A resizable 1280x720 window opens.
- The menu view starts active.
- The title screen shows `CROSSWORDLE` with `START` and `EXIT` buttons.
- Choosing `START` enters Cross view.
- The grid is empty.
- The selector starts in the center of the board.
- Fragment and rune inventories start empty.
- EXP starts at 0.
- Wordle starts at Level 1 with solution `CRANE`.
- Fragment view starts active.

### 14.2 Intended Progression Loop

1. Enter Wordle view with `1`.
2. Solve a Wordle level.
3. Gain one fragment from the solution and 100 EXP.
4. Return to Cross view with `2`.
5. Place earned fragments on the board for 500 EXP each, or save them for crafting.
6. Craft runes from fragment sets.
7. Place runes over matching fragments for 1000 EXP each.
8. Continue solving Wordles to feed the board economy.

## 15. Current Prototype Constraints

The current implementation intentionally or practically omits several systems:

- No save/load persistence.
- No audio.
- No animation beyond immediate frame redraws.
- No pause menu.
- No settings screen.
- No dictionary validation for Cross or Wordle inputs.
- No maximum Wordle guess count.
- No failure state for Wordle.
- No board-clearing, tile-removal, or undo mechanic.
- No EXP spending or level-up rewards.
- No generated Cross puzzle objectives.
- No mouse support in Wordle or crafting.
- No touch/controller support.
- No localization.

## 16. Implementation Notes

### 16.1 Main Loop

The main loop:

1. Updates screen size and layout.
2. Handles global view selection input outside the menu.
3. Routes input based on the active view.
4. Builds and renders the current frame.

Input is gated so each mode only processes relevant controls.

### 16.2 Layout Scaling

The game calculates a scale from the smaller ratio of current window size to base window size. Cell sizes, gaps, font sizes, and major offsets use this scale. The Cross grid is always recentered after resize.

### 16.3 Data Ownership

The code uses plain structs and procedural functions. Gameplay functions mutate `GameState` or nested state through pointers. Rendering reads immutable state and emits render commands.

### 16.4 Memory

Dynamic arrays are used for:

- Grid tile arrays and letter layers.
- Wordle current-level guesses.
- Wordle history records.
- Copied Wordle guesses inside each history record.
- Render command buffers.

The render buffers are destroyed on shutdown. The current code does not explicitly free Wordle dynamic arrays before program exit, relying on process teardown.

## 17. Feature Roadmap Candidates

These are natural extensions of the current design:

- Add save/load for inventory, EXP, board state, Wordle level, and history.
- Add word validation for Wordle guesses.
- Add Cross objectives that reward completing words or patterns.
- Add an EXP progression system with unlocks.
- Add better rune crafting recipes and recipe discovery.
- Add tile removal or board reset with an economy cost.
- Add animations for placement, crafting, and Wordle feedback.
- Add audio cues for typing, placement, crafting, solve, and invalid actions.
- Add invalid-action feedback messages.
- Add a menu/help overlay listing controls.
- Add mouse controls for crafting and Wordle.
- Add configurable solution and allowed-word lists.
