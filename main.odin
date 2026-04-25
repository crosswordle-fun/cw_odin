package main
import rl "vendor:raylib"

Tile :: struct {
	row: i32,
	col: i32,
}

Grid :: struct {
	tiles:         []Tile,
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
	row: i32,
	col: i32,
}

grid_new :: proc(screen_width: i32, screen_height: i32) -> Grid {
	cols: i32 = 15
	rows: i32 = 9
	cell_size: i32 = 64
	gap: i32 = 4

	grid_width := cols * cell_size + (cols - 1) * gap
	grid_height := rows * cell_size + (rows - 1) * gap

	grid := Grid {
		tiles         = make([]Tile, cols * rows),
		cols          = cols,
		rows          = rows,
		cell_size     = cell_size,
		gap           = gap,
		screen_width  = screen_width,
		screen_height = screen_height,
		offset_x      = (screen_width - grid_width) / 2,
		offset_y      = (screen_height - grid_height) / 2,
	}

	i := 0
	for row in 0 ..< rows {
		for col in 0 ..< cols {
			grid.tiles[i] = Tile{row, col}
			i += 1
		}
	}

	return grid
}

selector_new :: proc(grid: Grid) -> Selector {
	return Selector{row = grid.rows / 2, col = grid.cols / 2}
}

selector_handle_arrow_input :: proc(selector: ^Selector, grid: Grid) {
	if rl.IsKeyPressed(rl.KeyboardKey.UP) {
		selector.row = clamp(selector.row - 1, 0, grid.rows - 1)
	}
	if rl.IsKeyPressed(rl.KeyboardKey.DOWN) {
		selector.row = clamp(selector.row + 1, 0, grid.rows - 1)
	}
	if rl.IsKeyPressed(rl.KeyboardKey.LEFT) {
		selector.col = clamp(selector.col - 1, 0, grid.cols - 1)
	}
	if rl.IsKeyPressed(rl.KeyboardKey.RIGHT) {
		selector.col = clamp(selector.col + 1, 0, grid.cols - 1)
	}
}

selector_handle_mouse_input :: proc(selector: ^Selector, grid: Grid) {
	if !rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
		return
	}

	mouse_pos := rl.GetMousePosition()
	grid_right := grid.offset_x + grid.cols * grid.cell_size + (grid.cols - 1) * grid.gap
	grid_bottom := grid.offset_y + grid.rows * grid.cell_size + (grid.rows - 1) * grid.gap

	if mouse_pos.x < f32(grid.offset_x) || mouse_pos.y < f32(grid.offset_y) {
		return
	}
	if mouse_pos.x >= f32(grid_right) || mouse_pos.y >= f32(grid_bottom) {
		return
	}

	step := f32(grid.cell_size + grid.gap)
	selector.col = i32((mouse_pos.x - f32(grid.offset_x)) / step)
	selector.row = i32((mouse_pos.y - f32(grid.offset_y)) / step)
}

render_selector :: proc(grid: ^Grid, selector: ^Selector) {
	x := grid.offset_x + selector.col * (grid.cell_size + grid.gap)
	y := grid.offset_y + selector.row * (grid.cell_size + grid.gap)
	rl.DrawRectangleLinesEx(
		rl.Rectangle{f32(x), f32(y), f32(grid.cell_size), f32(grid.cell_size)},
		3,
		rl.WHITE,
	)
}

render_grid :: proc(grid: ^Grid) {
	for tile in grid.tiles {
		x := grid.offset_x + tile.col * (grid.cell_size + grid.gap)
		y := grid.offset_y + tile.row * (grid.cell_size + grid.gap)
		rl.DrawRectangle(x, y, grid.cell_size, grid.cell_size, rl.GRAY)
	}
}

main :: proc() {
	screen_width: i32 = 1280
	screen_height: i32 = 720

	rl.SetTargetFPS(60)
	rl.InitWindow(screen_width, screen_height, "cw_odin")
	defer rl.CloseWindow()

	grid := grid_new(screen_width, screen_height)
	selector := selector_new(grid)

	for !rl.WindowShouldClose() {
		selector_handle_arrow_input(&selector, grid)
		selector_handle_mouse_input(&selector, grid)

		rl.BeginDrawing()
		defer rl.EndDrawing()

		rl.ClearBackground(rl.Color{20, 20, 24, 255})
		render_grid(&grid)
		render_selector(&grid, &selector)
	}
}

