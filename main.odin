package main

import rl "vendor:raylib"

main :: proc() {
	screen_width: i32 = 1280
	screen_height: i32 = 720

	rl.InitWindow(screen_width, screen_height, "cw_odin")
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)

	cell_size: i32 = 64
	gap: i32 = 4
	grid_cols: i32 = 15
	grid_rows: i32 = 5
	grid_width: i32 = grid_cols * cell_size + (grid_cols - 1) * gap
	grid_height: i32 = grid_rows * cell_size + (grid_rows - 1) * gap
	offset_x: i32 = (screen_width - grid_width) / 2
	offset_y: i32 = (screen_height - grid_height) / 2

	for !rl.WindowShouldClose() {
		rl.BeginDrawing()

		rl.ClearBackground(rl.Color{20, 20, 24, 255})

		for row in 0 ..< grid_rows {
			for col in 0 ..< grid_cols {
				x := offset_x + col * (cell_size + gap)
				y := offset_y + row * (cell_size + gap)
				rl.DrawRectangle(x, y, cell_size, cell_size, rl.WHITE)
			}
		}

		rl.EndDrawing()
	}
}
