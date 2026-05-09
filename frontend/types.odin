package main

import rl "vendor:raylib"

Tile :: struct {
	row: i32,
	col: i32,
}

Frags :: [LETTER_COUNT]u32
Runes :: [LETTER_COUNT]u32

Grid :: struct {
	tiles:         []Tile,
	frags:         []rune,
	runes:         []rune,
	frag_exp:      []u32,
	rune_exp:      []u32,
	cols:          i32,
	rows:          i32,
	view_col:      i32,
	view_row:      i32,
	view_cols:     i32,
	view_rows:     i32,
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
	letters: [CRAFTING_SELECTION_CAPACITY]rune,
	count:   i32,
}

GameView :: enum {
	Menu,
	Wordle,
	Cross,
	Crafting,
}

CraftingState :: struct {
	selected:     [CRAFTING_SELECTION_CAPACITY]rune,
	count:        i32,
	crafted_rune: rune,
}

WordleFeedback :: enum {
	Empty,
	Miss,
	Present,
	Correct,
}

WordleSubstate :: enum {
	Playing,
	Won,
}

WordleViewMode :: enum {
	Current,
	History,
}

WordleGuess :: struct {
	letters:  [WORDLE_WORD_LEN]rune,
	feedback: [WORDLE_WORD_LEN]WordleFeedback,
}

WordleLevelRecord :: struct {
	guesses:         [dynamic]WordleGuess,
	level:           u32,
	solution:        [WORDLE_WORD_LEN]rune,
	reward_fragment: rune,
	reward_exp:      u32,
}

WordleState :: struct {
	guesses:         [dynamic]WordleGuess,
	history:         [dynamic]WordleLevelRecord,
	current_guess:   [WORDLE_WORD_LEN]rune,
	current_count:   i32,
	level:           u32,
	substate:        WordleSubstate,
	view_mode:       WordleViewMode,
	history_index:   i32,
	scroll_row:      i32,
	win_solution:    [WORDLE_WORD_LEN]rune,
	reward_fragment: rune,
	reward_exp:      u32,
}

UiParticleKind :: enum {
	Sparkle,
	Fleck,
}

UiParticle :: struct {
	active:   bool,
	kind:     UiParticleKind,
	x:        f32,
	y:        f32,
	vx:       f32,
	vy:       f32,
	age:      f32,
	lifetime: f32,
	size:     f32,
	rotation: f32,
	spin:     f32,
	color:    rl.Color,
}

UiFloatingText :: struct {
	active:   bool,
	amount:   u32,
	x:        f32,
	y:        f32,
	age:      f32,
	lifetime: f32,
	color:    rl.Color,
}

UiTilePop :: struct {
	active: bool,
	key:    i32,
	age:    f32,
}

UiState :: struct {
	time:                     f32,
	dt:                       f32,
	view_enter_time:          f32,
	previous_view:            GameView,
	previous_view_enter_time: f32,
	last_exp:                 u32,
	exp_gain:                 u32,
	exp_gain_age:             f32,
	invalid_age:              f32,
	wordle_reveal_age:        f32,
	wordle_reveal_guess_row:  i32,
	crafted_rune_age:         f32,
	selector_move_active:     bool,
	selector_move_age:        f32,
	selector_move_offset_x:   f32,
	selector_move_offset_y:   f32,
	particles:                [UI_PARTICLE_CAPACITY]UiParticle,
	floating_text:            [UI_FLOATING_TEXT_CAPACITY]UiFloatingText,
	tile_pops:                [UI_TILE_POP_CAPACITY]UiTilePop,
}

GameState :: struct {
	grid:             Grid,
	selector:         Selector,
	selector_buffer:  SelectorBuffer,
	cross_held_key:   rl.KeyboardKey,
	cross_hold_age:   f32,
	cross_repeat_age: f32,
	wordle:           WordleState,
	frag_counts:      Frags,
	rune_counts:      Runes,
	exp:              u32,
	cross_reward_exp: u32,
	show_frags:       bool,
	view:             GameView,
	crafting:         CraftingState,
	theme:            Theme,
	theme_index:      i32,
	ui:               UiState,
	menu_selection:   i32,
	should_quit:      bool,
	screen_width:     i32,
	screen_height:    i32,
}
