package main

import "core:math"
import rl "vendor:raylib"

main :: proc() {
	rl.SetTargetFPS(60)
	rl.SetConfigFlags(rl.ConfigFlags{.WINDOW_RESIZABLE})

	rl.InitWindow(VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT, "cw_odin")
	defer rl.CloseWindow()

	render_frame := render_frame_new()
	defer render_frame_destroy(&render_frame)
	render_target := rl.LoadRenderTexture(VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT)
	defer rl.UnloadRenderTexture(render_target)

	state := game_state_new(VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT)

	for !rl.WindowShouldClose() {
		game_update_screen_size(&state, VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT)
		handle_input(&state)
		render_game(&render_frame, state)

		rl.BeginTextureMode(render_target)
		rl.ClearBackground(rl.Color{20, 20, 24, 255})
		flush_render_frame(render_frame)
		rl.EndTextureMode()

		win_w := f32(rl.GetScreenWidth())
		win_h := f32(rl.GetScreenHeight())
		scale := math.min(win_w / f32(VIRTUAL_SCREEN_WIDTH), win_h / f32(VIRTUAL_SCREEN_HEIGHT))
		dst_w := f32(VIRTUAL_SCREEN_WIDTH) * scale
		dst_h := f32(VIRTUAL_SCREEN_HEIGHT) * scale
		dst_x := (win_w - dst_w) * 0.5
		dst_y := (win_h - dst_h) * 0.5
		source := rl.Rectangle {
			0,
			0,
			f32(render_target.texture.width),
			-f32(render_target.texture.height),
		}
		dest := rl.Rectangle{dst_x, dst_y, dst_w, dst_h}

		rl.BeginDrawing()
		rl.ClearBackground(rl.BLACK)
		rl.DrawTexturePro(render_target.texture, source, dest, rl.Vector2{0, 0}, 0, rl.WHITE)
		rl.EndDrawing()
	}
}

