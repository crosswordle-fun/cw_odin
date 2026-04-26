package main

import rl "vendor:raylib"

main :: proc() {
	rl.SetTargetFPS(60)
	rl.SetConfigFlags(rl.ConfigFlags{.WINDOW_RESIZABLE})

	rl.InitWindow(BASE_SCREEN_WIDTH, BASE_SCREEN_HEIGHT, "cw_odin")
	defer rl.CloseWindow()

	state := game_state_new(BASE_SCREEN_WIDTH, BASE_SCREEN_HEIGHT)
	render_frame := render_frame_new()
	defer render_frame_destroy(&render_frame)

	for !rl.WindowShouldClose() {
		game_update_screen_size(&state, rl.GetScreenWidth(), rl.GetScreenHeight())
		handle_game_mode_toggle_input(&state)

		if state.game_mode == .Cross {
			handle_inventory_debug_input(&state)
			handle_cross_substate_toggle_input(&state)

			if state.cross_substate == .Game {
				handle_arrow_key_input(&state)
				handle_mouse_selection_input(&state)
				handle_selector_buffer_input(&state)
				handle_selector_direction_input(&state)
				handle_submit_input(&state)
				handle_view_toggle_input(&state)
			} else if state.cross_substate == .Crafting {
				handle_crafting_selection_input(&state)
				handle_crafting_submit_input(&state)
				handle_view_toggle_input(&state)
			}
		} else if state.game_mode == .Wordle {
			handle_wordle_history_input(&state)
			handle_wordle_attempt_scroll_input(&state)
			if state.wordle.substate == .Playing {
				handle_wordle_guess_input(&state)
				handle_wordle_submit_input(&state)
			} else if state.wordle.substate == .Won {
				handle_wordle_win_input(&state)
			}
		}

		render_game(&render_frame, state)
	}
}
