package main

import rl "vendor:raylib"

main :: proc() {
	rl.SetTargetFPS(60)
	rl.SetConfigFlags(rl.ConfigFlags{.WINDOW_RESIZABLE})

	rl.InitWindow(VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT, "CROSSWORDLE")
	if !rl.IsWindowReady() do return
	rl.SetExitKey(rl.KeyboardKey(0))
	defer rl.CloseWindow()
	game_font_load()
	defer game_font_unload()

	render_frame := render_frame_new()
	defer render_frame_destroy(&render_frame)
	previous_frame := render_frame_new()
	defer render_frame_destroy(&previous_frame)
	render_target := rl.LoadRenderTexture(VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT)
	defer rl.UnloadRenderTexture(render_target)

	state := game_state_new(VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT)
	game_set_view(&state, .Menu)

	for !rl.WindowShouldClose() {
		if !app_run_frame(&state, &render_frame, &previous_frame, render_target) do break
	}
}
