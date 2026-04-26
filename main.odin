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
		handle_view_selection_input(&state)

		switch state.view {
		case .Wordle:
			handle_wordle_input(&state)
		case .Cross:
			handle_cross_input(&state)
		case .Crafting:
			handle_crafting_input(&state)
		}

		render_frame_clear(&render_frame)
		ctx := render_context_new(state.screen_width, state.screen_height)
		build_global_hud(&render_frame, ctx, state)
		switch state.view {
		case .Wordle:
			build_wordle_scene(&render_frame, ctx, state.wordle)
		case .Cross:
			build_cross_board_scene(&render_frame, ctx, state)
		case .Crafting:
			build_crafting_scene(&render_frame, ctx, state)
		}

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
