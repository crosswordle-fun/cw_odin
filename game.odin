package main

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
		show_frags = true,
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

game_increment_frags_and_runes :: proc(state: ^GameState) {
	for i in 0 ..< LETTER_COUNT {
		state.frag_counts[i] += 10
		state.rune_counts[i] += 1
	}
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

