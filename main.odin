package main

import rl "vendor:raylib"

main :: proc() {
	rl.SetTargetFPS(60)
	rl.SetConfigFlags(rl.ConfigFlags{.WINDOW_RESIZABLE})

	rl.InitWindow(BASE_SCREEN_WIDTH, BASE_SCREEN_HEIGHT, "cw_odin")
	defer rl.CloseWindow()

	state := game_state_new(BASE_SCREEN_WIDTH, BASE_SCREEN_HEIGHT)

	for !rl.WindowShouldClose() {
		game_update_screen_size(&state, rl.GetScreenWidth(), rl.GetScreenHeight())
		handle_input(&state)

		rl.BeginDrawing()
		defer rl.EndDrawing()

		render_game(state)
	}
}
