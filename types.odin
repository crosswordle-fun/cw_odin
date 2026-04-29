package main

import rl "vendor:raylib"

LETTER_COUNT :: 26
WORDLE_WORD_LEN :: 5
CRAFTING_SELECTION_CAPACITY :: 5
DEFAULT_GAME_DATA_PATH :: "game_data.json5"

GameScreenData :: struct {
	virtual_width:          i32,
	virtual_height:         i32,
	target_fps:             i32,
	window_title:           cstring,
	font_path:              cstring,
	render_buffer_capacity: int,
}

GameGridData :: struct {
	cols:          i32,
	rows:          i32,
	visible_cols:  i32,
	visible_rows:  i32,
	cell_size:     i32,
	gap:           i32,
	frag_tile_exp: u32,
	rune_tile_exp: u32,
	selector_row:  i32,
	selector_col:  i32,
	selector_down: bool,
	alphabet:      []rune,
}

GameFontData :: struct {
	hud:      i32,
	board:    i32,
	selector: i32,
	title:    i32,
}

GameHudData :: struct {
	item_width:        i32,
	row_height:        i32,
	exp_x:             i32,
	exp_y:             i32,
	exp_badge_width:   i32,
	exp_badge_height:  i32,
	exp_icon_x:        i32,
	exp_text_x:        i32,
	exp_label_prefix:  cstring,
	inventory_tile:    i32,
	inventory_gap:     i32,
	inventory_columns: i32,
	inventory_rows:    i32,
	inventory_pad_x:   i32,
	inventory_pad_y:   i32,
	inventory_right:   i32,
}

GameTitleData :: struct {
	gap:       i32,
	padding_x: i32,
	padding_y: i32,
	y:         i32,
}

GameTabsData :: struct {
	font_size: i32,
	cross:     cstring,
	wordle:    cstring,
	crafting:  cstring,
}

GameMenuData :: struct {
	title:               string,
	start_label:         cstring,
	exit_label:          cstring,
	title_face_size:     i32,
	title_font_ratio:    f32,
	button_font:         i32,
	button_padding_x:    i32,
	button_padding_y:    i32,
	button_gap:          i32,
	title_button_gap:    i32,
	drop_duration:       f32,
	drop_distance:       f32,
	rebounce_raise_time: f32,
	rebounce_fall_time:  f32,
	rebounce_lift:       f32,
	rebounce_period:     f32,
	stagger:             f32,
}

GameWordleData :: struct {
	word_length:        i32,
	solutions:          []string,
	level_exp_reward:   u32,
	board_y:            i32,
	level_y:            i32,
	reward_exp_y:       i32,
	reward_burst_count: i32,
	win_title:          cstring,
	win_subtitle:       cstring,
	rewards_label:      cstring,
	level_label_prefix: cstring,
}

GameCraftingData :: struct {
	selection_capacity: i32,
	matching_required:  i32,
	random_required:    i32,
	exp_reward:         u32,
	fragment_label:     cstring,
	incomplete_label:   cstring,
	matching_label:     cstring,
	random_label:       cstring,
	latest_rune_label:  cstring,
	board_y:            i32,
	reward_exp_y:       i32,
	reward_burst_count: i32,
}

GameEffectsData :: struct {
	view_transition_duration: f32,
	exp_pulse_duration:       f32,
	exp_pulse_frequency:      f32,
	invalid_shake_duration:   f32,
	invalid_shake_frequency:  f32,
	floating_text_lifetime:   f32,
	floating_text_rise:       f32,
	exp_burst_count:          i32,
	tile_pop_duration:        f32,
}

GameData :: struct {
	screen:   GameScreenData,
	grid:     GameGridData,
	fonts:    GameFontData,
	hud:      GameHudData,
	title:    GameTitleData,
	tabs:     GameTabsData,
	menu:     GameMenuData,
	wordle:   GameWordleData,
	crafting: GameCraftingData,
	effects:  GameEffectsData,
	themes:   []Theme,
}

game_data: GameData

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

UI_PARTICLE_CAPACITY :: 160
UI_FLOATING_TEXT_CAPACITY :: 16
UI_TILE_POP_CAPACITY :: 128

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
