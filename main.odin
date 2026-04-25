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
		handle_game_mode_toggle_input(&state)

		if state.game_mode == .Cross {
			handle_arrow_key_input(&state)
			handle_mouse_selection_input(&state)
			handle_selector_buffer_input(&state)
			handle_selector_direction_input(&state)
			handle_submit_input(&state)
			handle_inventory_debug_input(&state)
			handle_view_toggle_input(&state)
		} else if state.game_mode == .Wordle {
			if state.wordle.substate == .Playing {
				handle_wordle_guess_input(&state)
				handle_wordle_submit_input(&state)
			} else if state.wordle.substate == .Won {
				handle_wordle_win_input(&state)
			}
		}

		rl.BeginDrawing()
		defer rl.EndDrawing()

		rl.ClearBackground(rl.Color{20, 20, 24, 255})
		render_title(state.screen_width, state.screen_height, state.game_mode)

		if state.game_mode == .Cross {
			render_grid(state.grid)
			render_selector(state.grid, state.selector, state.selector_buffer, state.show_frags)
			render_selector_letter(state.grid, state.selector, state.selector_buffer)
			if state.show_frags do render_frags(state.screen_width, state.screen_height, state.frag_counts)
			else do render_runes(state.screen_width, state.screen_height, state.rune_counts)
		} else if state.game_mode == .Wordle {
			render_wordle(state.screen_width, state.screen_height, state.wordle)
		}
	}
}
