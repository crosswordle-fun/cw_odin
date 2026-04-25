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

render_grid :: proc(grid: ^Grid) {
	for tile in grid.tiles {
		x := grid.offset_x + tile.col * (grid.cell_size + grid.gap)
		y := grid.offset_y + tile.row * (grid.cell_size + grid.gap)
		rl.DrawRectangle(x, y, grid.cell_size, grid.cell_size, rl.WHITE)
	}
}

main :: proc() {
	screen_width: i32 = 1280
	screen_height: i32 = 720

	rl.InitWindow(screen_width, screen_height, "cw_odin")
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)

	grid := grid_new(screen_width, screen_height)

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()

		rl.ClearBackground(rl.Color{20, 20, 24, 255})

		render_grid(&grid)

		rl.EndDrawing()
	}
}

