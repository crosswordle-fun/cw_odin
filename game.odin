package main

scaled_i32 :: proc(value: i32, scale: f32) -> i32 {
	scaled := i32(f32(value) * scale + 0.5)
	if scaled < 1 do return 1
	return scaled
}

grid_tile_base_height :: proc(cell_size: i32) -> i32 {
	base_height := cell_size / 10
	if base_height < 1 do base_height = 1
	return base_height
}

tile_row_step :: proc(cell_size: i32, gap: i32) -> i32 {
	return cell_size + gap + grid_tile_base_height(cell_size)
}

screen_scale :: proc(screen_width: i32, screen_height: i32) -> f32 {
	scale_x := f32(screen_width) / f32(VIRTUAL_SCREEN_WIDTH)
	scale_y := f32(screen_height) / f32(VIRTUAL_SCREEN_HEIGHT)
	if scale_y < scale_x do return scale_y
	return scale_x
}

grid_pixel_width :: proc(grid: Grid) -> i32 {
	return grid.cols * grid.cell_size + (grid.cols - 1) * grid.gap
}

grid_pixel_height :: proc(grid: Grid) -> i32 {
	base_height := grid_tile_base_height(grid.cell_size)
	return grid.rows * (grid.cell_size + base_height) + (grid.rows - 1) * grid.gap
}

grid_row_step :: proc(grid: Grid) -> i32 {
	return grid.cell_size + grid.gap + grid_tile_base_height(grid.cell_size)
}

grid_tile_index :: proc(grid: Grid, row: i32, col: i32) -> i32 {
	return row * grid.cols + col
}

grid_tile_position :: proc(grid: Grid, row: i32, col: i32) -> (x: i32, y: i32) {
	x = grid.offset_x + col * (grid.cell_size + grid.gap)
	y = grid.offset_y + row * grid_row_step(grid)
	return
}

selector_letter_position :: proc(
	grid: Grid,
	selector: Selector,
	offset: i32,
) -> (
	row: i32,
	col: i32,
) {
	row = selector.row
	col = selector.col
	if selector.down {
		row += offset
	} else {
		col += offset
	}
	return
}

grid_new :: proc(virtual_width: i32, virtual_height: i32) -> Grid {
	grid_width := GRID_COLS * BASE_CELL_SIZE + (GRID_COLS - 1) * BASE_GAP
	base_height := grid_tile_base_height(BASE_CELL_SIZE)
	grid_height := GRID_ROWS * (BASE_CELL_SIZE + base_height) + (GRID_ROWS - 1) * BASE_GAP

	grid := Grid {
		tiles         = make([]Tile, GRID_COLS * GRID_ROWS),
		frags         = make([]rune, GRID_COLS * GRID_ROWS),
		runes         = make([]rune, GRID_COLS * GRID_ROWS),
		frag_exp      = make([]u32, GRID_COLS * GRID_ROWS),
		rune_exp      = make([]u32, GRID_COLS * GRID_ROWS),
		cols          = GRID_COLS,
		rows          = GRID_ROWS,
		cell_size     = BASE_CELL_SIZE,
		gap           = BASE_GAP,
		screen_width  = virtual_width,
		screen_height = virtual_height,
		offset_x      = i32((virtual_width - i32(grid_width)) / 2),
		offset_y      = i32((virtual_height - i32(grid_height)) / 2),
	}

	i := 0
	for row in 0 ..< GRID_ROWS {
		for col in 0 ..< GRID_COLS {
			grid.tiles[i] = Tile{i32(row), i32(col)}
			grid.frag_exp[i] = FRAG_TILE_EXP_REWARD
			grid.rune_exp[i] = RUNE_TILE_EXP_REWARD
			i += 1
		}
	}

	return grid
}

selector_new :: proc(grid: Grid) -> Selector {
	return Selector{row = grid.rows / 2, col = grid.cols / 2}
}

game_state_new :: proc(virtual_width: i32, virtual_height: i32) -> GameState {
	grid := grid_new(virtual_width, virtual_height)
	return GameState {
		grid = grid,
		selector = selector_new(grid),
		wordle = wordle_state_new(),
		show_frags = true,
		view = .Menu,
		theme = THEMES[0],
		theme_index = 0,
		menu_selection = 0,
		screen_width = virtual_width,
		screen_height = virtual_height,
	}
}

game_update_screen_size :: proc(state: ^GameState, virtual_width: i32, virtual_height: i32) {
	scale_x := f32(virtual_width) / f32(VIRTUAL_SCREEN_WIDTH)
	scale_y := f32(virtual_height) / f32(VIRTUAL_SCREEN_HEIGHT)
	scale := scale_x
	if scale_y < scale_x do scale = scale_y

	state.grid.cell_size = i32(f32(BASE_CELL_SIZE) * scale + 0.5)
	if state.grid.cell_size < 1 do state.grid.cell_size = 1
	state.grid.gap = i32(f32(BASE_GAP) * scale + 0.5)
	if state.grid.gap < 1 do state.grid.gap = 1
	state.grid.screen_width = virtual_width
	state.grid.screen_height = virtual_height
	state.grid.offset_x = (virtual_width - grid_pixel_width(state.grid)) / 2
	state.grid.offset_y = (virtual_height - grid_pixel_height(state.grid)) / 2
	state.screen_width = virtual_width
	state.screen_height = virtual_height
}

selector_move :: proc(selector: ^Selector, row_delta: i32, col_delta: i32, grid: Grid) {
	selector.row = clamp(selector.row + row_delta, 0, grid.rows - 1)
	selector.col = clamp(selector.col + col_delta, 0, grid.cols - 1)
}

selector_set_tile :: proc(selector: ^Selector, row: i32, col: i32) {
	selector.row = row
	selector.col = col
}

selector_toggle_direction :: proc(selector: ^Selector) {
	selector.down = !selector.down
}

selector_buffer_pop :: proc(selector_buffer: ^SelectorBuffer) {
	if selector_buffer.count > 0 {
		selector_buffer.count -= 1
		selector_buffer.letters[selector_buffer.count] = 0
	}
}

selector_buffer_push_letter :: proc(selector_buffer: ^SelectorBuffer, letter: rune) {
	if selector_buffer.count < i32(len(selector_buffer.letters[:])) {
		selector_buffer.letters[selector_buffer.count] = letter
		selector_buffer.count += 1
	}
}

selector_buffer_clear :: proc(selector_buffer: ^SelectorBuffer) {
	selector_buffer.count = 0
}

game_toggle_frag_rune_view :: proc(state: ^GameState) {
	state.show_frags = !state.show_frags
}

game_cycle_theme :: proc(state: ^GameState) {
	state.theme_index = (state.theme_index + 1) % i32(len(THEMES))
	state.theme = THEMES[state.theme_index]
}

game_set_view :: proc(state: ^GameState, view: GameView) {
	if state.view == view do return

	state.view = view
}

game_increment_frags_and_runes :: proc(state: ^GameState) {
	for i in 0 ..< LETTER_COUNT {
		state.frag_counts[i] += 10
		state.rune_counts[i] += 1
	}
}

crafting_clear_selection :: proc(crafting: ^CraftingState) {
	for i in 0 ..< len(crafting.selected) {
		crafting.selected[i] = 0
	}
	crafting.count = 0
}

crafting_selected_count_for_letter :: proc(crafting: CraftingState, letter: rune) -> u32 {
	count: u32 = 0
	for i in 0 ..< crafting.count {
		if crafting.selected[i] == letter do count += 1
	}
	return count
}

crafting_push_letter :: proc(crafting: ^CraftingState, frag_counts: Frags, letter: rune) {
	if crafting.count >= i32(len(crafting.selected[:])) do return

	frag_index := i32(letter - 'A')
	if frag_index < 0 || frag_index >= LETTER_COUNT do return
	if crafting_selected_count_for_letter(crafting^, letter) >= frag_counts[frag_index] do return

	crafting.selected[crafting.count] = letter
	crafting.count += 1
}

crafting_pop_letter :: proc(crafting: ^CraftingState) {
	if crafting.count <= 0 do return

	crafting.count -= 1
	crafting.selected[crafting.count] = 0
}

wordle_state_new :: proc() -> WordleState {
	return WordleState {
		guesses = make([dynamic]WordleGuess, 0, 32),
		history = make([dynamic]WordleLevelRecord, 0, 32),
		substate = .Playing,
		view_mode = .Current,
		history_index = -1,
	}
}

wordle_solution_index :: proc(wordle: WordleState) -> i32 {
	return i32(wordle.level % WORDLE_SOLUTION_COUNT)
}

wordle_solution_string_to_runes :: proc(solution: string) -> [WORDLE_WORD_LEN]rune {
	letters := [WORDLE_WORD_LEN]rune{}
	for i in 0 ..< WORDLE_WORD_LEN {
		if i < len(solution) {
			letters[i] = rune(solution[i])
		}
	}
	return letters
}

wordle_current_solution :: proc(wordle: WordleState) -> [WORDLE_WORD_LEN]rune {
	return wordle_solution_string_to_runes(WORDLE_SOLUTIONS[wordle_solution_index(wordle)])
}

wordle_is_viewing_current_level :: proc(wordle: WordleState) -> bool {
	return wordle.view_mode == .Current
}

wordle_push_letter :: proc(wordle: ^WordleState, letter: rune) {
	if !wordle_is_viewing_current_level(wordle^) do return
	if wordle.substate != .Playing do return
	if wordle.current_count < WORDLE_WORD_LEN {
		wordle.current_guess[wordle.current_count] = letter
		wordle.current_count += 1
	}
}

wordle_pop_letter :: proc(wordle: ^WordleState) {
	if !wordle_is_viewing_current_level(wordle^) do return
	if wordle.substate != .Playing do return
	if wordle.current_count > 0 {
		wordle.current_count -= 1
		wordle.current_guess[wordle.current_count] = 0
	}
}

wordle_clear_current_guess :: proc(wordle: ^WordleState) {
	for i in 0 ..< WORDLE_WORD_LEN {
		wordle.current_guess[i] = 0
	}
	wordle.current_count = 0
}

wordle_evaluate_guess :: proc(
	guess: [WORDLE_WORD_LEN]rune,
	solution: [WORDLE_WORD_LEN]rune,
) -> WordleGuess {
	result := WordleGuess {
		letters = guess,
	}
	remaining_counts := Frags{}

	for i in 0 ..< WORDLE_WORD_LEN {
		if guess[i] == solution[i] {
			result.feedback[i] = .Correct
		} else {
			solution_index := i32(solution[i] - 'A')
			if solution_index >= 0 && solution_index < LETTER_COUNT {
				remaining_counts[solution_index] += 1
			}
		}
	}

	for i in 0 ..< WORDLE_WORD_LEN {
		if result.feedback[i] == .Correct do continue

		guess_index := i32(guess[i] - 'A')
		if guess_index >= 0 && guess_index < LETTER_COUNT && remaining_counts[guess_index] > 0 {
			result.feedback[i] = .Present
			remaining_counts[guess_index] -= 1
		} else {
			result.feedback[i] = .Miss
		}
	}

	return result
}

wordle_copy_guesses :: proc(guesses: [dynamic]WordleGuess) -> [dynamic]WordleGuess {
	copied := make([dynamic]WordleGuess, len(guesses), len(guesses))
	for i in 0 ..< len(guesses) {
		copied[i] = guesses[i]
	}
	return copied
}

wordle_visible_row_count :: proc(screen_height: i32, start_y: i32, row_step: i32) -> i32 {
	visible_rows := (screen_height - start_y - row_step) / row_step
	if visible_rows < 1 do visible_rows = 1
	return visible_rows
}
