package main

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
