package main

import "core:math"
import rl "vendor:raylib"

build_view_frame_static :: proc(
	frame: ^RenderFrame,
	ctx: RenderContext,
	state: ^GameState,
	view: GameView,
) {
	build_cozy_background(&frame.world, ctx)

	view_state := state^
	view_state.view = view
	if state.view != view && state.ui.previous_view == view {
		view_state.ui.view_enter_time = state.ui.previous_view_enter_time
	}
	switch view {
	case .Menu:
		layout := menu_layout(ctx)
		selection := menu_selection_from_state(view_state.menu_selection)
		build_menu_mode_view(
			frame,
			ctx,
			layout,
			selection == .Start,
			selection == .Exit,
			selection,
			ctx.theme,
			view_state.ui,
		)
	case .Wordle:
		build_wordle_mode_view(frame, ctx, &view_state)
	case .Cross:
		build_cross_mode_view(frame, ctx, &view_state)
	case .Crafting:
		build_crafting_mode_view(frame, ctx, &view_state)
	}

	if gameplay_view_index(view) >= 0 {
		build_gameplay_fixed_ui(&frame.fixed_ui, ctx, &view_state)
	}
}

build_current_view_frame :: proc(frame: ^RenderFrame, ctx: RenderContext, state: ^GameState) {
	render_frame_clear(frame)
	build_cozy_background(&frame.world, ctx)
	frame_view := state.view
	switch frame_view {
	case .Menu:
		menu_mode_frame(frame, ctx, state)
	case .Wordle:
		wordle_mode_frame(frame, ctx, state)
	case .Cross:
		cross_mode_frame(frame, ctx, state)
	case .Crafting:
		crafting_mode_frame(frame, ctx, state)
	}

	if state.view != frame_view {
		render_frame_clear(frame)
		build_view_frame_static(frame, ctx, state, state.view)
	} else if gameplay_view_index(state.view) >= 0 {
		build_gameplay_fixed_ui(&frame.fixed_ui, ctx, state)
	}
}

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
		dt := rl.GetFrameTime()
		game_update_screen_size(&state, VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT)
		ui_update(&state, dt)
		escape_pressed := rl.IsKeyPressed(rl.KeyboardKey.ESCAPE)

		if state.view != .Menu {
			if escape_pressed {
				game_set_view(&state, .Menu)
			}
			if rl.IsKeyPressed(rl.KeyboardKey.ONE) do game_set_view(&state, .Cross)
			if rl.IsKeyPressed(rl.KeyboardKey.TWO) do game_set_view(&state, .Wordle)
			if rl.IsKeyPressed(rl.KeyboardKey.THREE) do game_set_view(&state, .Crafting)
		} else if escape_pressed {
			state.should_quit = true
		}
		if rl.IsKeyPressed(rl.KeyboardKey.NINE) do game_cycle_theme(&state)

		ctx := render_context_new(
			state.screen_width,
			state.screen_height,
			state.theme,
			state.ui.time,
			state.ui.dt,
		)
		build_current_view_frame(&render_frame, ctx, &state)

		if state.should_quit do break

		rl.BeginTextureMode(render_target)
		rl.ClearBackground(ctx.theme.background)
		if ui_view_transition_active(state.ui) && state.ui.previous_view != state.view {
			render_frame_clear(&previous_frame)
			build_view_frame_static(&previous_frame, ctx, &state, state.ui.previous_view)
			previous_offset, current_offset := ui_view_transition_offsets(
				state.ui,
				state.view,
				ctx.screen_width,
				ctx.screen_height,
			)
			if gameplay_view_index(state.ui.previous_view) >= 0 &&
			   gameplay_view_index(state.view) >= 0 {
				flush_render_frame_moving_offset_skip_background(previous_frame, previous_offset)
				flush_render_frame_moving_offset_skip_background(render_frame, current_offset)
				flush_render_buffer(render_frame.fixed_ui)
			} else {
				flush_render_frame_offset(previous_frame, previous_offset)
				flush_render_frame_offset(render_frame, current_offset)
			}
		} else {
			flush_render_frame(render_frame)
		}
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
		rl.DrawTexturePro(render_target.texture, source, dest, rl.Vector2{0, 0}, 0, rl.WHITE)
		rl.EndDrawing()
	}
}
