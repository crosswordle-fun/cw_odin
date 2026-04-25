package main

scaled_i32 :: proc(value: i32, scale: f32) -> i32 {
	scaled := i32(f32(value) * scale + 0.5)
	if scaled < 1 do return 1
	return scaled
}

screen_scale :: proc(screen_width: i32, screen_height: i32) -> f32 {
	scale_x := f32(screen_width) / f32(BASE_SCREEN_WIDTH)
	scale_y := f32(screen_height) / f32(BASE_SCREEN_HEIGHT)
	scale := scale_x
	if scale_y < scale do scale = scale_y
	return scale
}

grid_pixel_width :: proc(grid: Grid) -> i32 {
	return grid.cols * grid.cell_size + (grid.cols - 1) * grid.gap
}

grid_pixel_height :: proc(grid: Grid) -> i32 {
	return grid.rows * grid.cell_size + (grid.rows - 1) * grid.gap
}

grid_tile_index :: proc(grid: Grid, row: i32, col: i32) -> i32 {
	return row * grid.cols + col
}

grid_tile_position :: proc(grid: Grid, row: i32, col: i32) -> (x: i32, y: i32) {
	x = grid.offset_x + col * (grid.cell_size + grid.gap)
	y = grid.offset_y + row * (grid.cell_size + grid.gap)
	return
}

selector_letter_position :: proc(grid: Grid, selector: Selector, offset: i32) -> (row: i32, col: i32) {
	row = selector.row
	col = selector.col
	if selector.down {
		row += offset
	} else {
		col += offset
	}
	return
}

grid_update_layout :: proc(grid: ^Grid, screen_width: i32, screen_height: i32) {
	scale := screen_scale(screen_width, screen_height)

	grid.cell_size = scaled_i32(BASE_CELL_SIZE, scale)
	grid.gap = scaled_i32(BASE_GAP, scale)

	grid_width := grid_pixel_width(grid^)
	grid_height := grid_pixel_height(grid^)

	grid.screen_width = screen_width
	grid.screen_height = screen_height
	grid.offset_x = (screen_width - grid_width) / 2
	grid.offset_y = (screen_height - grid_height) / 2
}
