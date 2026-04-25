package main

import rl "vendor:raylib"

grid_new :: proc(screen_width: i32, screen_height: i32) -> Grid {
	grid_width := GRID_COLS * BASE_CELL_SIZE + (GRID_COLS - 1) * BASE_GAP
	grid_height := GRID_ROWS * BASE_CELL_SIZE + (GRID_ROWS - 1) * BASE_GAP

	grid := Grid {
		tiles         = make([]Tile, GRID_COLS * GRID_ROWS),
		frags         = make([]rune, GRID_COLS * GRID_ROWS),
		runes         = make([]rune, GRID_COLS * GRID_ROWS),
		cols          = GRID_COLS,
		rows          = GRID_ROWS,
		cell_size     = BASE_CELL_SIZE,
		gap           = BASE_GAP,
		screen_width  = screen_width,
		screen_height = screen_height,
		offset_x      = i32((screen_width - i32(grid_width)) / 2),
		offset_y      = i32((screen_height - i32(grid_height)) / 2),
	}

	i := 0
	for row in 0 ..< GRID_ROWS {
		for col in 0 ..< GRID_COLS {
			grid.tiles[i] = Tile{i32(row), i32(col)}
			i += 1
		}
	}

	return grid
}

selector_new :: proc(grid: Grid) -> Selector {
	return Selector{row = grid.rows / 2, col = grid.cols / 2}
}

game_state_new :: proc(screen_width: i32, screen_height: i32) -> GameState {
	grid := grid_new(screen_width, screen_height)
	return GameState {
		grid = grid,
		selector = selector_new(grid),
		wordle = wordle_state_new(),
		show_frags = true,
		game_mode = .Cross,
		screen_width = screen_width,
		screen_height = screen_height,
	}
}

game_update_screen_size :: proc(state: ^GameState, screen_width: i32, screen_height: i32) {
	state.screen_width = screen_width
	state.screen_height = screen_height
	grid_update_layout(&state.grid, screen_width, screen_height)
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

game_toggle_mode :: proc(state: ^GameState) {
	switch state.game_mode {
	case .Cross:
		state.game_mode = .Wordle
	case .Wordle:
		state.game_mode = .Cross
	}
}

game_increment_frags_and_runes :: proc(state: ^GameState) {
	for i in 0 ..< LETTER_COUNT {
		state.frag_counts[i] += 10
		state.rune_counts[i] += 1
	}
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

wordle_evaluate_guess :: proc(guess: [WORDLE_WORD_LEN]rune, solution: [WORDLE_WORD_LEN]rune) -> WordleGuess {
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

wordle_guess_is_solution :: proc(guess: WordleGuess) -> bool {
	for i in 0 ..< WORDLE_WORD_LEN {
		if guess.feedback[i] != .Correct do return false
	}
	return true
}

wordle_reward_fragment :: proc(state: ^GameState, solution: [WORDLE_WORD_LEN]rune) -> rune {
	reward_index := rl.GetRandomValue(0, WORDLE_WORD_LEN - 1)
	letter := solution[reward_index]
	frag_index := i32(letter - 'A')
	if frag_index >= 0 && frag_index < LETTER_COUNT {
		state.frag_counts[frag_index] += 1
	}
	return letter
}

wordle_copy_guesses :: proc(guesses: [dynamic]WordleGuess) -> [dynamic]WordleGuess {
	copied := make([dynamic]WordleGuess, len(guesses), len(guesses))
	for i in 0 ..< len(guesses) {
		copied[i] = guesses[i]
	}
	return copied
}

wordle_store_current_level :: proc(wordle: ^WordleState) {
	record := WordleLevelRecord {
		guesses = wordle_copy_guesses(wordle.guesses),
		level = wordle.level,
		solution = wordle.win_solution,
		reward_fragment = wordle.reward_fragment,
	}
	append(&wordle.history, record)
}

wordle_advance_level :: proc(wordle: ^WordleState) {
	wordle_store_current_level(wordle)
	clear(&wordle.guesses)
	wordle_clear_current_guess(wordle)
	wordle.win_solution = [WORDLE_WORD_LEN]rune{}
	wordle.reward_fragment = 0
	wordle.substate = .Playing
	wordle.view_mode = .Current
	wordle.history_index = -1
	wordle.scroll_row = 0
	wordle.level += 1
}

wordle_submit_guess :: proc(state: ^GameState) {
	if !wordle_is_viewing_current_level(state.wordle) do return
	if state.wordle.substate != .Playing do return
	if state.wordle.current_count < WORDLE_WORD_LEN do return

	solution := wordle_current_solution(state.wordle)
	guess := wordle_evaluate_guess(state.wordle.current_guess, solution)
	append(&state.wordle.guesses, guess)
	wordle_clear_current_guess(&state.wordle)

	if wordle_guess_is_solution(guess) {
		state.wordle.win_solution = solution
		state.wordle.reward_fragment = wordle_reward_fragment(state, solution)
		state.wordle.substate = .Won
	}
}

wordle_continue_after_win :: proc(wordle: ^WordleState) {
	if !wordle_is_viewing_current_level(wordle^) do return
	if wordle.substate == .Won do wordle_advance_level(wordle)
}

wordle_view_previous_level :: proc(wordle: ^WordleState) {
	if len(wordle.history) == 0 do return

	if wordle.view_mode == .Current {
		wordle.view_mode = .History
		wordle.history_index = i32(len(wordle.history)) - 1
		wordle.scroll_row = 0
		return
	}

	if wordle.history_index > 0 {
		wordle.history_index -= 1
		wordle.scroll_row = 0
	}
}

wordle_view_next_level :: proc(wordle: ^WordleState) {
	if wordle.view_mode != .History do return

	last_index := i32(len(wordle.history)) - 1
	if wordle.history_index < last_index {
		wordle.history_index += 1
		wordle.scroll_row = 0
		return
	}

	wordle.view_mode = .Current
	wordle.history_index = -1
	wordle.scroll_row = 0
}

wordle_view_current_level :: proc(wordle: ^WordleState) {
	wordle.view_mode = .Current
	wordle.history_index = -1
	wordle.scroll_row = 0
}

wordle_visible_row_count :: proc(screen_height: i32, start_y: i32, row_step: i32) -> i32 {
	visible_rows := (screen_height - start_y - row_step) / row_step
	if visible_rows < 1 do visible_rows = 1
	return visible_rows
}

wordle_current_total_rows :: proc(wordle: WordleState) -> i32 {
	if wordle.substate == .Playing {
		return i32(len(wordle.guesses)) + 1
	}
	return i32(len(wordle.guesses))
}

wordle_history_total_rows :: proc(wordle: WordleState) -> i32 {
	if wordle.history_index < 0 || wordle.history_index >= i32(len(wordle.history)) do return 0
	return i32(len(wordle.history[wordle.history_index].guesses))
}

wordle_view_total_rows :: proc(wordle: WordleState) -> i32 {
	if wordle.view_mode == .History do return wordle_history_total_rows(wordle)
	return wordle_current_total_rows(wordle)
}

wordle_clamp_scroll_row :: proc(wordle: ^WordleState, visible_rows: i32) {
	total_rows := wordle_view_total_rows(wordle^)
	max_scroll := total_rows - visible_rows
	if max_scroll < 0 do max_scroll = 0
	wordle.scroll_row = clamp(wordle.scroll_row, 0, max_scroll)
}

wordle_scroll_attempts_latest :: proc(wordle: ^WordleState, visible_rows: i32) {
	total_rows := wordle_view_total_rows(wordle^)
	wordle.scroll_row = total_rows - visible_rows
	wordle_clamp_scroll_row(wordle, visible_rows)
}

wordle_scroll_attempts_up :: proc(wordle: ^WordleState, visible_rows: i32) {
	wordle.scroll_row -= 1
	wordle_clamp_scroll_row(wordle, visible_rows)
}

wordle_scroll_attempts_down :: proc(wordle: ^WordleState, visible_rows: i32) {
	wordle.scroll_row += 1
	wordle_clamp_scroll_row(wordle, visible_rows)
}

selector_submission_fits_grid :: proc(grid: Grid, selector: Selector, letter_count: i32) -> bool {
	if selector.down {
		if selector.row + letter_count > grid.rows do return false
	} else {
		if selector.col + letter_count > grid.cols do return false
	}
	return true
}

selector_submission_collect_requirements :: proc(
	grid: Grid,
	selector: Selector,
	selector_buffer: SelectorBuffer,
	frag_counts: Frags,
	show_frags: bool,
	required_frags: ^Frags,
	required_runes: ^Runes,
) -> bool {
	for i in 0 ..< selector_buffer.count {
		letter := selector_buffer.letters[i]
		frag_index := i32(letter - 'A')
		tile_row, tile_col := selector_letter_position(grid, selector, i)
		tile_index := grid_tile_index(grid, tile_row, tile_col)
		if tile_index < 0 || tile_index >= i32(len(grid.frags)) do return false
		if frag_index < 0 || frag_index >= LETTER_COUNT do return false

		required_frags[frag_index] += 1
		required_runes[frag_index] += 1

		if show_frags {
			if grid.frags[tile_index] != 0 do return false
			continue
		}

		if grid.frags[tile_index] != letter do return false
		if grid.runes[tile_index] != 0 do return false
	}
	return true
}

selector_submission_has_inventory :: proc(
	required_frags: Frags,
	required_runes: Runes,
	frag_counts: Frags,
	rune_counts: Runes,
	show_frags: bool,
) -> bool {
	if show_frags {
		for i in 0 ..< LETTER_COUNT {
			if required_frags[i] > frag_counts[i] do return false
		}
	} else {
		for i in 0 ..< LETTER_COUNT {
			if required_runes[i] > rune_counts[i] do return false
		}
	}
	return true
}

place_frags_from_selector_buffer :: proc(
	grid: ^Grid,
	selector: Selector,
	selector_buffer: SelectorBuffer,
	frag_counts: ^Frags,
) {
	for i in 0 ..< selector_buffer.count {
		letter := selector_buffer.letters[i]
		frag_index := i32(letter - 'A')
		tile_row, tile_col := selector_letter_position(grid^, selector, i)
		tile_index := grid_tile_index(grid^, tile_row, tile_col)

		grid.frags[tile_index] = letter
		frag_counts[frag_index] -= 1
	}
}

place_runes_from_selector_buffer :: proc(
	grid: ^Grid,
	selector: Selector,
	selector_buffer: SelectorBuffer,
	rune_counts: ^Runes,
) {
	for i in 0 ..< selector_buffer.count {
		letter := selector_buffer.letters[i]
		frag_index := i32(letter - 'A')
		tile_row, tile_col := selector_letter_position(grid^, selector, i)
		tile_index := grid_tile_index(grid^, tile_row, tile_col)

		grid.runes[tile_index] = letter
		rune_counts[frag_index] -= 1
	}
}

game_submit_selector_buffer :: proc(state: ^GameState) {
	if state.selector_buffer.count == 0 do return
	if !selector_submission_fits_grid(state.grid, state.selector, state.selector_buffer.count) do return

	required_frags := Frags{}
	required_runes := Runes{}
	if !selector_submission_collect_requirements(
		state.grid,
		state.selector,
		state.selector_buffer,
		state.frag_counts,
		state.show_frags,
		&required_frags,
		&required_runes,
	) {
		return
	}

	if !selector_submission_has_inventory(
		required_frags,
		required_runes,
		state.frag_counts,
		state.rune_counts,
		state.show_frags,
	) {
		return
	}

	if state.show_frags {
		place_frags_from_selector_buffer(
			&state.grid,
			state.selector,
			state.selector_buffer,
			&state.frag_counts,
		)
		selector_buffer_clear(&state.selector_buffer)
		return
	}

	place_runes_from_selector_buffer(
		&state.grid,
		state.selector,
		state.selector_buffer,
		&state.rune_counts,
	)
	selector_buffer_clear(&state.selector_buffer)
}
