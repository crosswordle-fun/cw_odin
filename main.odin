package main

import "core:math"
import rl "vendor:raylib"

main :: proc() {
	rl.SetTargetFPS(60)
	rl.SetConfigFlags(rl.ConfigFlags{.WINDOW_RESIZABLE})

	rl.InitWindow(VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT, "CROSSWORDLE")
	rl.SetExitKey(rl.KeyboardKey(0))
	defer rl.CloseWindow()

	render_frame := render_frame_new()
	defer render_frame_destroy(&render_frame)
	render_target := rl.LoadRenderTexture(VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT)
	defer rl.UnloadRenderTexture(render_target)

	state := game_state_new(VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT)

	for !rl.WindowShouldClose() {
		game_update_screen_size(&state, VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT)
		escape_pressed := rl.IsKeyPressed(rl.KeyboardKey.ESCAPE)

		if state.view != .Menu {
			if escape_pressed {
				game_set_view(&state, .Menu)
			}
			if rl.IsKeyPressed(rl.KeyboardKey.ONE) do game_set_view(&state, .Wordle)
			if rl.IsKeyPressed(rl.KeyboardKey.TWO) do game_set_view(&state, .Cross)
			if rl.IsKeyPressed(rl.KeyboardKey.THREE) do game_set_view(&state, .Crafting)
		} else if escape_pressed {
			state.should_quit = true
		}
		if rl.IsKeyPressed(rl.KeyboardKey.NINE) do game_cycle_theme(&state)

		render_frame_clear(&render_frame)
		ctx := render_context_new(state.screen_width, state.screen_height, state.theme)
		switch state.view {
		case .Menu:
			menu_mode_frame(&render_frame, ctx, &state)
		case .Wordle:
			wordle_mode_frame(&render_frame, ctx, &state)
		case .Cross:
			cross_mode_frame(&render_frame, ctx, &state)
		case .Crafting:
			crafting_mode_frame(&render_frame, ctx, &state)
		}

		if state.should_quit do break

		rl.BeginTextureMode(render_target)
		rl.ClearBackground(ctx.theme.background)
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
		rl.ClearBackground(ctx.theme.canvas)
		rl.DrawTexturePro(render_target.texture, source, dest, rl.Vector2{0, 0}, 0, ctx.theme.text)
		rl.EndDrawing()
	}
}
