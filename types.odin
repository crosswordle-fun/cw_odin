package main

BASE_SCREEN_WIDTH :: 1280
BASE_SCREEN_HEIGHT :: 720
BASE_CELL_SIZE :: 64
BASE_GAP :: 4
BASE_HUD_ITEM_WIDTH :: 56
BASE_HUD_ROW_HEIGHT :: 30
BASE_HUD_FONT_SIZE :: 20
BASE_BOARD_FONT_SIZE :: 28
BASE_SELECTOR_FONT_SIZE :: 24
BASE_TITLE_FONT_SIZE :: 48
BASE_TITLE_GAP :: 16
BASE_TITLE_PADDING_X :: 10
BASE_TITLE_PADDING_Y :: 6
BASE_TITLE_Y :: 30
BASE_SELECTOR_OUTLINE :: 3
BASE_SELECTOR_LABEL_OFFSET :: 6
BASE_RUNE_PADDING :: 6
BASE_HUD_VALUE_OFFSET :: 18
GRID_COLS :: 7
GRID_ROWS :: 7
LETTER_COUNT :: 26
WORDLE_WORD_LEN :: 5
WORDLE_SOLUTION_COUNT :: 10
BASE_WORDLE_BOARD_Y :: 125
BASE_WORDLE_LEVEL_Y :: 92

Tile :: struct {
	row: i32,
	col: i32,
}

Frags :: [LETTER_COUNT]u32
Runes :: [LETTER_COUNT]u32

FRAG_LETTERS := [LETTER_COUNT]rune {
	'A',
	'B',
	'C',
	'D',
	'E',
	'F',
	'G',
	'H',
	'I',
	'J',
	'K',
	'L',
	'M',
	'N',
	'O',
	'P',
	'Q',
	'R',
	'S',
	'T',
	'U',
	'V',
	'W',
	'X',
	'Y',
	'Z',
}

Grid :: struct {
	tiles:         []Tile,
	frags:         []rune,
	runes:         []rune,
	cols:          i32,
	rows:          i32,
	cell_size:     i32,
	gap:           i32,
	screen_width:  i32,
	screen_height: i32,
	offset_x:      i32,
	offset_y:      i32,
}

Selector :: struct {
	row:  i32,
	col:  i32,
	down: bool,
}

SelectorBuffer :: struct {
	letters: [5]rune,
	count:   i32,
}

GameMode :: enum {
	Cross,
	Wordle,
}

WordleFeedback :: enum {
	Empty,
	Miss,
	Present,
	Correct,
}

WordleGuess :: struct {
	letters:  [WORDLE_WORD_LEN]rune,
	feedback: [WORDLE_WORD_LEN]WordleFeedback,
}

WordleState :: struct {
	guesses:       [dynamic]WordleGuess,
	current_guess: [WORDLE_WORD_LEN]rune,
	current_count: i32,
	level:         u32,
}

GameState :: struct {
	grid:            Grid,
	selector:        Selector,
	selector_buffer: SelectorBuffer,
	wordle:          WordleState,
	frag_counts:     Frags,
	rune_counts:     Runes,
	show_frags:      bool,
	game_mode:       GameMode,
	screen_width:    i32,
	screen_height:   i32,
}
