# CROSSWORDLE Game Design Document

## Overview

**CROSSWORDLE** is a keyboard-driven puzzle game built around three connected modes:

1. **WORDLE**: solve five-letter word puzzles to earn letter fragments.
2. **CRAFTING**: combine fragments into runes.
3. **CROSS**: spend fragments or runes to place letters onto a large crossword-style grid for EXP.

The current implementation is a local, single-player Raylib/Odin game. It uses a fixed 1280x720 virtual canvas rendered into a resizable window with letterboxing. There is no persistence, networking, dictionary validation, failure state, or time pressure implemented.

## High-Level Player Loop

1. Start at the animated main menu and choose **PLAY**.
2. Enter **WORDLE** mode by default.
3. Solve Wordle levels to gain:
   - 100 EXP per solved level.
   - 1 random fragment taken from one letter in the solved word.
4. Use **CRAFTING** to spend fragments and create runes.
5. Use **CROSS** to place either fragments or runes onto the 25x25 grid.
6. Earn EXP from each placed tile:
   - Fragment tile: 500 EXP.
   - Rune tile: 1000 EXP.
7. Switch among modes freely and continue accumulating inventory and EXP.

## Game Modes

### Main Menu

The game opens to a title screen with two choices:

- **PLAY**: enters Wordle mode.
- **QUIT**: exits the game.

The title is rendered as tile letters with staggered drop/bounce animation and cycling colors.

### WORDLE Mode

WORDLE is an unlimited-guess five-letter puzzle mode.

#### Rules

- The current solution is selected by `level % number_of_solutions`.
- Implemented solutions are:
  - CRANE
  - SLATE
  - BRICK
  - PLANT
  - GHOST
  - FLAME
  - STORM
  - CHARM
  - BLOOM
  - TRACE
- Player inputs five letters and submits with Enter.
- Guesses are evaluated with standard Wordle-style feedback:
  - Correct: right letter, right position.
  - Present: letter exists elsewhere in the word.
  - Miss: letter is not present, or excess duplicate.
- There is no maximum guess count.
- There is no dictionary check; any five A-Z letters can be submitted.

#### Win Reward

When all five positions are correct:

- The player receives 100 EXP.
- One random letter from the solution is awarded as a fragment.
- The mode enters a win panel state showing the solved word and reward.
- Pressing Enter after the win archives the level into history, increments the level, and starts the next puzzle.

#### History and Scrolling

Completed Wordle levels are saved in an in-memory session history.

- Left/Right navigates between previous completed levels and the current level.
- Space returns from history to the current level.
- Up/Down scrolls long guess lists.

### CRAFTING Mode

CRAFTING converts fragments into runes. It uses the player’s fragment inventory and supports two recipes.

#### Input and Selection

- Player types A-Z letters to add fragments to the crafting selection.
- Selection capacity is 5 letters.
- A letter can only be selected as many times as the player owns that fragment.
- Backspace removes the most recently selected letter.
- Enter attempts to craft.

#### Recipes

1. **Matching Rune Recipe**
   - Requires exactly 4 selected fragments.
   - All 4 fragments must be the same letter.
   - Consumes those 4 fragments.
   - Awards 1 rune of that same letter.
   - Awards 250 EXP.

2. **Random Rune Recipe**
   - Requires exactly 5 selected fragments.
   - All 5 fragments must be different letters.
   - Consumes those 5 fragments.
   - Awards 1 random A-Z rune.
   - Awards 250 EXP.

Invalid recipes trigger invalid feedback and do not consume resources.

### CROSS Mode

CROSS is a 25x25 wrapping letter-placement grid with an 11x7 visible viewport. The player controls a selector, enters a sequence of letters, and places that sequence horizontally or vertically.

#### Grid and Viewport

- Full grid size: 25 columns x 25 rows.
- Visible viewport: 11 columns x 7 rows.
- Movement wraps around grid edges.
- The viewport follows the selector and expands to keep the typed preview visible.
- Each tile can contain:
  - A fragment letter.
  - A rune letter layered after a matching fragment.

#### Fragment Placement

When the game is in fragment view:

- Submitted letters are placed as fragments.
- Target tiles must be empty of fragments.
- The player must own enough fragments for all letters in the submitted sequence.
- Each placed fragment consumes 1 fragment inventory item.
- Each placed fragment grants 500 EXP.

#### Rune Placement

When the game is in rune view:

- Submitted letters are placed as runes.
- Each target tile must already contain the same fragment letter.
- Target tiles must not already contain a rune.
- The player must own enough matching runes.
- Each placed rune consumes 1 rune inventory item.
- Each placed rune grants 1000 EXP.

#### Placement Sequence

- The player types letters into a selector buffer.
- Space toggles placement direction between horizontal and vertical.
- Enter submits the buffered letters.
- Backspace removes the last buffered letter.
- Invalid placement gives invalid feedback and keeps resources unchanged.

## Shared Systems

### Inventory

The game tracks two A-Z inventories:

- **Fragments**: earned from Wordle and spent in Crafting/Cross.
- **Runes**: earned from Crafting and spent in Cross.

The HUD displays one inventory type at a time. Shift toggles between fragment and rune display in gameplay modes.

### EXP

EXP is a session total. It is increased by:

- Solving a Wordle level: 100 EXP.
- Crafting any valid rune recipe: 250 EXP.
- Placing a fragment in Cross: 500 EXP per tile.
- Placing a rune in Cross: 1000 EXP per tile.

EXP has visual pulse, floating text, and particle burst feedback when gained.

### Themes and Fonts

Two themes are implemented:

- Default gray/Wordle-like palette.
- Cozy Craft warm palette.

The player can cycle themes during play. The game also supports toggling between the loaded custom font and Raylib's default font.

### Visual Feedback

Implemented presentation features include:

- Animated tile-based title.
- Scrolling patterned background tiles.
- View transition slide effects.
- Selector movement easing.
- Tile pop animations.
- Wordle guess reveal animation.
- EXP floating text and particle bursts.
- Invalid action shake/feedback.
- Crafted rune and reward reveal animations.

## Controls

### Global

| Key | Action |
| --- | --- |
| Escape | Return to menu from gameplay; quit from menu |
| 1 | Switch to CROSS mode from gameplay |
| 2 | Switch to WORDLE mode from gameplay |
| 3 | Switch to CRAFTING mode from gameplay |
| 8 | Toggle font |
| 9 | Cycle theme |
| Shift | Toggle fragment/rune inventory view in gameplay modes |

### Menu

| Key | Action |
| --- | --- |
| Up/Down | Toggle selected menu option |
| Enter | Confirm selected menu option |
| Escape | Quit |

### WORDLE

| Key | Action |
| --- | --- |
| A-Z | Type guess letters |
| Backspace | Delete current guess letter |
| Enter | Submit five-letter guess; continue after win |
| Left/Right | Browse completed level history/current level |
| Up/Down | Scroll guess list |
| Space | Return from history to current level |

### CROSS

| Key | Action |
| --- | --- |
| Arrow keys | Move selector, with hold repeat |
| A-Z | Add letters to placement buffer |
| Backspace | Remove last buffered letter |
| Space | Toggle horizontal/vertical placement direction |
| Enter | Place buffered letters |
| Shift | Toggle fragment/rune placement view |
| 0 | Debug: add 10 fragments and 1 rune of every letter |

### CRAFTING

| Key | Action |
| --- | --- |
| A-Z | Add fragment to recipe selection |
| Backspace | Remove last selected fragment |
| Enter | Attempt crafting recipe |
| Shift | Toggle inventory display |
| 0 | Debug: add 10 fragments and 1 rune of every letter |

## Current Technical Constraints / Non-Features

The current implementation does **not** include:

- Save/load persistence.
- Audio.
- Mouse or gamepad control.
- Word dictionary validation.
- A Wordle guess limit or lose state.
- Campaign progression beyond cycling the fixed solution list.
- Grid word validation or crossword clues.
- Resource sinks beyond crafting and grid placement.
- Multiplayer or online features.

## Design Pillars Reflected in the Implementation

1. **Puzzle modes feed each other**: Wordle produces fragments, Crafting turns fragments into runes, Cross consumes both for EXP.
2. **Keyboard-first flow**: every core action is direct and keyboard-driven.
3. **Generous play**: no timers, no Wordle failure, no hard reset on invalid actions.
4. **Tactile UI**: rewards, invalid actions, movement, and mode changes all have animated feedback.
5. **Session-based progression**: inventory, EXP, grid state, and Wordle history exist for the current run only.
