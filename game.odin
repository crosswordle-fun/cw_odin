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

GRID_VIEWPORT_MAX :: i32(7)
CROSS_MOVE_REPEAT_DELAY :: f32(0.22)
CROSS_MOVE_REPEAT_INTERVAL :: f32(0.08)

screen_scale :: proc(screen_width: i32, screen_height: i32) -> f32 {
	scale_x := f32(screen_width) / f32(game_data.screen.virtual_width)
	scale_y := f32(screen_height) / f32(game_data.screen.virtual_height)
	if scale_y < scale_x do return scale_y
	return scale_x
}

grid_pixel_width :: proc(grid: Grid) -> i32 {
	return grid.view_cols * grid.cell_size + (grid.view_cols - 1) * grid.gap
}

grid_pixel_height :: proc(grid: Grid) -> i32 {
	base_height := grid_tile_base_height(grid.cell_size)
	return grid.view_rows * (grid.cell_size + base_height) + (grid.view_rows - 1) * grid.gap
}

grid_row_step :: proc(grid: Grid) -> i32 {
	return grid.cell_size + grid.gap + grid_tile_base_height(grid.cell_size)
}

grid_tile_index :: proc(grid: Grid, row: i32, col: i32) -> i32 {
	return row * grid.cols + col
}

grid_wrap_row :: proc(grid: Grid, row: i32) -> i32 {
	if grid.rows <= 0 do return 0
	wrapped := row % grid.rows
	if wrapped < 0 do wrapped += grid.rows
	return wrapped
}

grid_wrap_col :: proc(grid: Grid, col: i32) -> i32 {
	if grid.cols <= 0 do return 0
	wrapped := col % grid.cols
	if wrapped < 0 do wrapped += grid.cols
	return wrapped
}

grid_axis_visible_offset :: proc(
	origin: i32,
	visible_count: i32,
	total_count: i32,
	coord: i32,
) -> (
	offset: i32,
	ok: bool,
) {
	if total_count <= 0 || visible_count <= 0 do return 0, false
	if visible_count >= total_count do return clamp(coord, 0, total_count - 1), true

	wrapped_coord := coord % total_count
	if wrapped_coord < 0 do wrapped_coord += total_count
	wrapped_origin := origin % total_count
	if wrapped_origin < 0 do wrapped_origin += total_count

	offset = wrapped_coord - wrapped_origin
	if offset < 0 do offset += total_count
	return offset, offset < visible_count
}

grid_tile_position :: proc(grid: Grid, row: i32, col: i32) -> (x: i32, y: i32) {
	col_offset, _ := grid_axis_visible_offset(grid.view_col, grid.view_cols, grid.cols, col)
	row_offset, _ := grid_axis_visible_offset(grid.view_row, grid.view_rows, grid.rows, row)
	x = grid.offset_x + col_offset * (grid.cell_size + grid.gap)
	y = grid.offset_y + row_offset * grid_row_step(grid)
	return
}

grid_tile_visible :: proc(grid: Grid, row: i32, col: i32) -> bool {
	_, row_visible := grid_axis_visible_offset(grid.view_row, grid.view_rows, grid.rows, row)
	_, col_visible := grid_axis_visible_offset(grid.view_col, grid.view_cols, grid.cols, col)
	return row_visible && col_visible
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
	row = grid_wrap_row(grid, row)
	col = grid_wrap_col(grid, col)
	return
}

grid_new :: proc(virtual_width: i32, virtual_height: i32) -> Grid {
	grid_width :=
		game_data.grid.cols * game_data.grid.cell_size +
		(game_data.grid.cols - 1) * game_data.grid.gap
	base_height := grid_tile_base_height(game_data.grid.cell_size)
	grid_height :=
		game_data.grid.rows * (game_data.grid.cell_size + base_height) +
		(game_data.grid.rows - 1) * game_data.grid.gap
	tile_count := game_data.grid.cols * game_data.grid.rows

	grid := Grid {
		tiles         = make([]Tile, tile_count),
		frags         = make([]rune, tile_count),
		runes         = make([]rune, tile_count),
		frag_exp      = make([]u32, tile_count),
		rune_exp      = make([]u32, tile_count),
		cols          = game_data.grid.cols,
		rows          = game_data.grid.rows,
		view_cols     = min(game_data.grid.cols, GRID_VIEWPORT_MAX),
		view_rows     = min(game_data.grid.rows, GRID_VIEWPORT_MAX),
		cell_size     = game_data.grid.cell_size,
		gap           = game_data.grid.gap,
		screen_width  = virtual_width,
		screen_height = virtual_height,
		offset_x      = i32((virtual_width - i32(grid_width)) / 2),
		offset_y      = i32((virtual_height - i32(grid_height)) / 2),
	}

	i: i32 = 0
	for row in 0 ..< game_data.grid.rows {
		for col in 0 ..< game_data.grid.cols {
			grid.tiles[i] = Tile{i32(row), i32(col)}
			grid.frag_exp[i] = game_data.grid.frag_tile_exp
			grid.rune_exp[i] = game_data.grid.rune_tile_exp
			i += 1
		}
	}

	return grid
}

selector_new :: proc(grid: Grid) -> Selector {
	return Selector {
		row = clamp(grid.rows / 2, 0, grid.rows - 1),
		col = clamp(grid.cols / 2, 0, grid.cols - 1),
		down = game_data.grid.selector_down,
	}
}

game_state_new :: proc(virtual_width: i32, virtual_height: i32) -> GameState {
	grid := grid_new(virtual_width, virtual_height)
	state := GameState {
		grid           = grid,
		selector       = selector_new(grid),
		wordle         = wordle_state_new(),
		show_frags     = true,
		view           = .Menu,
		theme          = game_data.themes[0],
		theme_index    = 0,
		ui             = ui_state_new(.Menu, 0),
		menu_selection = 0,
		screen_width   = virtual_width,
		screen_height  = virtual_height,
	}
	grid_center_viewport(&state.grid, state.selector)
	game_update_screen_size(&state, virtual_width, virtual_height)
	return state
}

game_update_screen_size :: proc(state: ^GameState, virtual_width: i32, virtual_height: i32) {
	scale_x := f32(virtual_width) / f32(game_data.screen.virtual_width)
	scale_y := f32(virtual_height) / f32(game_data.screen.virtual_height)
	scale := scale_x
	if scale_y < scale_x do scale = scale_y

	state.grid.cell_size = i32(f32(game_data.grid.cell_size) * scale + 0.5)
	if state.grid.cell_size < 1 do state.grid.cell_size = 1
	state.grid.gap = i32(f32(game_data.grid.gap) * scale + 0.5)
	if state.grid.gap < 1 do state.grid.gap = 1
	state.grid.view_cols = min(state.grid.cols, GRID_VIEWPORT_MAX)
	state.grid.view_rows = min(state.grid.rows, GRID_VIEWPORT_MAX)
	grid_update_viewport(&state.grid, state.selector, state.selector_buffer.count)
	state.grid.screen_width = virtual_width
	state.grid.screen_height = virtual_height
	state.grid.offset_x = (virtual_width - grid_pixel_width(state.grid)) / 2
	state.grid.offset_y = (virtual_height - grid_pixel_height(state.grid)) / 2
	state.screen_width = virtual_width
	state.screen_height = virtual_height
}

selector_move :: proc(selector: ^Selector, row_delta: i32, col_delta: i32, grid: Grid) {
	selector.row = grid_wrap_row(grid, selector.row + row_delta)
	selector.col = grid_wrap_col(grid, selector.col + col_delta)
}

grid_center_viewport :: proc(grid: ^Grid, selector: Selector) {
	grid.view_cols = min(grid.cols, GRID_VIEWPORT_MAX)
	grid.view_rows = min(grid.rows, GRID_VIEWPORT_MAX)

	if grid.cols > grid.view_cols {
		grid.view_col = grid_wrap_col(grid^, selector.col - grid.view_cols / 2)
	} else {
		grid.view_col = 0
	}
	if grid.rows > grid.view_rows {
		grid.view_row = grid_wrap_row(grid^, selector.row - grid.view_rows / 2)
	} else {
		grid.view_row = 0
	}
}

grid_update_viewport :: proc(grid: ^Grid, selector: Selector, preview_count: i32) {
	grid.view_cols = min(grid.cols, GRID_VIEWPORT_MAX)
	grid.view_rows = min(grid.rows, GRID_VIEWPORT_MAX)

	span_rows := i32(1)
	span_cols := i32(1)
	if preview_count > 0 {
		if selector.down {
			span_rows = min(preview_count, grid.rows)
		} else {
			span_cols = min(preview_count, grid.cols)
		}
	}

	row_start := selector.row
	row_end := selector.row + span_rows - 1
	col_start := selector.col
	col_end := selector.col + span_cols - 1

	if grid.cols > grid.view_cols {
		col_start_offset, _ := grid_axis_visible_offset(
			grid.view_col,
			grid.view_cols,
			grid.cols,
			col_start,
		)
		col_end_offset, _ := grid_axis_visible_offset(
			grid.view_col,
			grid.view_cols,
			grid.cols,
			col_end,
		)
		if col_end_offset >= grid.view_cols - 1 {
			grid.view_col = grid_wrap_col(
				grid^,
				grid.view_col + col_end_offset - grid.view_cols + 2,
			)
		}
		if col_start_offset <= 0 {
			grid.view_col = grid_wrap_col(grid^, grid.view_col + col_start_offset - 1)
		}
	} else {
		grid.view_col = 0
	}

	if grid.rows > grid.view_rows {
		row_start_offset, _ := grid_axis_visible_offset(
			grid.view_row,
			grid.view_rows,
			grid.rows,
			row_start,
		)
		row_end_offset, _ := grid_axis_visible_offset(
			grid.view_row,
			grid.view_rows,
			grid.rows,
			row_end,
		)
		if row_end_offset >= grid.view_rows - 1 {
			grid.view_row = grid_wrap_row(
				grid^,
				grid.view_row + row_end_offset - grid.view_rows + 2,
			)
		}
		if row_start_offset <= 0 {
			grid.view_row = grid_wrap_row(grid^, grid.view_row + row_start_offset - 1)
		}
	} else {
		grid.view_row = 0
	}
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
	state.theme_index = (state.theme_index + 1) % i32(len(game_data.themes))
	state.theme = game_data.themes[state.theme_index]
}

game_set_view :: proc(state: ^GameState, view: GameView) {
	if state.view == view do return

	ui_note_view_change(&state.ui, state.view)
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
	if crafting.count >= game_data.crafting.selection_capacity do return

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
	return i32(wordle.level % u32(len(game_data.wordle.solutions)))
}

wordle_solution_string_to_runes :: proc(solution: string) -> [WORDLE_WORD_LEN]rune {
	letters := [WORDLE_WORD_LEN]rune{}
	i: i32 = 0
	for letter in solution {
		if i >= game_data.wordle.word_length do break
		letters[i] = letter
		i += 1
	}
	return letters
}

wordle_current_solution :: proc(wordle: WordleState) -> [WORDLE_WORD_LEN]rune {
	return wordle_solution_string_to_runes(
		game_data.wordle.solutions[wordle_solution_index(wordle)],
	)
}

wordle_is_viewing_current_level :: proc(wordle: WordleState) -> bool {
	return wordle.view_mode == .Current
}

wordle_push_letter :: proc(wordle: ^WordleState, letter: rune) {
	if !wordle_is_viewing_current_level(wordle^) do return
	if wordle.substate != .Playing do return
	if wordle.current_count < game_data.wordle.word_length {
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
	for i in 0 ..< game_data.wordle.word_length {
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

	for i in 0 ..< game_data.wordle.word_length {
		if guess[i] == solution[i] {
			result.feedback[i] = .Correct
		} else {
			solution_index := i32(solution[i] - 'A')
			if solution_index >= 0 && solution_index < LETTER_COUNT {
				remaining_counts[solution_index] += 1
			}
		}
	}

	for i in 0 ..< game_data.wordle.word_length {
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

game_apply_data_reload :: proc(state: ^GameState) {
	if state.theme_index < 0 || state.theme_index >= i32(len(game_data.themes)) {
		state.theme_index = 0
	}
	state.theme = game_data.themes[state.theme_index]

	old_grid := state.grid
	state.grid = grid_new(state.screen_width, state.screen_height)
	copy_count := min(len(old_grid.frags), len(state.grid.frags))
	for i in 0 ..< copy_count {
		state.grid.frags[i] = old_grid.frags[i]
		state.grid.runes[i] = old_grid.runes[i]
		state.grid.frag_exp[i] = game_data.grid.frag_tile_exp
		state.grid.rune_exp[i] = game_data.grid.rune_tile_exp
	}
	delete(old_grid.tiles)
	delete(old_grid.frags)
	delete(old_grid.runes)
	delete(old_grid.frag_exp)
	delete(old_grid.rune_exp)
	selector_move(&state.selector, 0, 0, state.grid)
	grid_center_viewport(&state.grid, state.selector)
	state.selector_buffer.count = min(
		state.selector_buffer.count,
		game_data.crafting.selection_capacity,
	)
	state.crafting.count = min(state.crafting.count, game_data.crafting.selection_capacity)
	if state.wordle.current_count > game_data.wordle.word_length {
		state.wordle.current_count = game_data.wordle.word_length
	}
	game_update_screen_size(state, state.screen_width, state.screen_height)
}
