package main

import "core:math"
import rl "vendor:raylib"

handle_arrow_key_input :: proc(state: ^GameState) {
	if rl.IsKeyPressed(rl.KeyboardKey.UP) do selector_move(&state.selector, -1, 0, state.grid)
	if rl.IsKeyPressed(rl.KeyboardKey.DOWN) do selector_move(&state.selector, 1, 0, state.grid)
	if rl.IsKeyPressed(rl.KeyboardKey.LEFT) do selector_move(&state.selector, 0, -1, state.grid)
	if rl.IsKeyPressed(rl.KeyboardKey.RIGHT) do selector_move(&state.selector, 0, 1, state.grid)
}

handle_mouse_selection_input :: proc(state: ^GameState) {
	if !rl.IsMouseButtonPressed(rl.MouseButton.LEFT) do return

	mouse_pos := rl.GetMousePosition()
	win_w := f32(rl.GetScreenWidth())
	win_h := f32(rl.GetScreenHeight())
	scale := math.min(win_w / f32(VIRTUAL_SCREEN_WIDTH), win_h / f32(VIRTUAL_SCREEN_HEIGHT))
	dst_w := f32(VIRTUAL_SCREEN_WIDTH) * scale
	dst_h := f32(VIRTUAL_SCREEN_HEIGHT) * scale
	dst_x := (win_w - dst_w) * 0.5
	dst_y := (win_h - dst_h) * 0.5

	if mouse_pos.x < dst_x || mouse_pos.y < dst_y {
		return
	}
	if mouse_pos.x >= dst_x + dst_w || mouse_pos.y >= dst_y + dst_h {
		return
	}

	mouse_pos.x = (mouse_pos.x - dst_x) / scale
	mouse_pos.y = (mouse_pos.y - dst_y) / scale
	grid_right := state.grid.offset_x + grid_pixel_width(state.grid)
	grid_bottom := state.grid.offset_y + grid_pixel_height(state.grid)

	if mouse_pos.x < f32(state.grid.offset_x) || mouse_pos.y < f32(state.grid.offset_y) {
		return
	}
	if mouse_pos.x >= f32(grid_right) || mouse_pos.y >= f32(grid_bottom) {
		return
	}

	step := f32(state.grid.cell_size + state.grid.gap)
	col := i32((mouse_pos.x - f32(state.grid.offset_x)) / step)
	row := i32((mouse_pos.y - f32(state.grid.offset_y)) / step)
	selector_set_tile(&state.selector, row, col)
}

handle_selector_direction_input :: proc(state: ^GameState) {
	if rl.IsKeyPressed(rl.KeyboardKey.SPACE) do selector_toggle_direction(&state.selector)
}

handle_selector_buffer_input :: proc(state: ^GameState) {
	if rl.IsKeyPressed(rl.KeyboardKey.BACKSPACE) {
		selector_buffer_pop(&state.selector_buffer)
		return
	}

	for {
		ch := rl.GetCharPressed()
		if ch == 0 {
			break
		}

		if ch >= 'a' && ch <= 'z' {
			ch -= 'a' - 'A'
		}

		if ch >= 'A' && ch <= 'Z' {
			selector_buffer_push_letter(&state.selector_buffer, rune(ch))
		}
	}
}

handle_submit_input :: proc(state: ^GameState) {
	if rl.IsKeyPressed(rl.KeyboardKey.ENTER) do game_submit_selector_buffer(state)
}

handle_inventory_debug_input :: proc(state: ^GameState) {
	if rl.IsKeyPressed(rl.KeyboardKey.ZERO) do game_increment_frags_and_runes(state)
}

handle_cross_substate_toggle_input :: proc(state: ^GameState) {
	if rl.IsKeyPressed(rl.KeyboardKey.ONE) do cross_toggle_substate(state)
}

handle_view_toggle_input :: proc(state: ^GameState) {
	if rl.IsKeyPressed(rl.KeyboardKey.LEFT_SHIFT) || rl.IsKeyPressed(rl.KeyboardKey.RIGHT_SHIFT) {
		game_toggle_frag_rune_view(state)
	}
}

handle_game_mode_toggle_input :: proc(state: ^GameState) {
	if rl.IsKeyPressed(rl.KeyboardKey.TAB) do game_toggle_mode(state)
}

handle_crafting_selection_input :: proc(state: ^GameState) {
	if rl.IsKeyPressed(rl.KeyboardKey.BACKSPACE) {
		crafting_pop_letter(&state.crafting)
		return
	}

	for {
		ch := rl.GetCharPressed()
		if ch == 0 {
			break
		}

		if ch >= 'a' && ch <= 'z' {
			ch -= 'a' - 'A'
		}

		if ch >= 'A' && ch <= 'Z' {
			crafting_push_letter(&state.crafting, state.frag_counts, rune(ch))
		}
	}
}

handle_crafting_submit_input :: proc(state: ^GameState) {
	if rl.IsKeyPressed(rl.KeyboardKey.ENTER) do crafting_submit(state)
}

wordle_visible_rows_for_state :: proc(state: GameState) -> i32 {
	scale := screen_scale(state.screen_width, state.screen_height)
	cell_size := scaled_i32(BASE_CELL_SIZE, scale)
	gap := scaled_i32(BASE_GAP, scale)
	start_y := scaled_i32(BASE_WORDLE_BOARD_Y, scale)
	row_step := cell_size + gap
	return wordle_visible_row_count(state.screen_height, start_y, row_step)
}

handle_wordle_history_input :: proc(state: ^GameState) {
	visible_rows := wordle_visible_rows_for_state(state^)
	if rl.IsKeyPressed(rl.KeyboardKey.LEFT) {
		wordle_view_previous_level(&state.wordle)
		wordle_scroll_attempts_latest(&state.wordle, visible_rows)
	}
	if rl.IsKeyPressed(rl.KeyboardKey.RIGHT) {
		wordle_view_next_level(&state.wordle)
		wordle_scroll_attempts_latest(&state.wordle, visible_rows)
	}
	if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
		wordle_view_current_level(&state.wordle)
		wordle_scroll_attempts_latest(&state.wordle, visible_rows)
	}
}

handle_wordle_attempt_scroll_input :: proc(state: ^GameState) {
	visible_rows := wordle_visible_rows_for_state(state^)

	if rl.IsKeyPressed(rl.KeyboardKey.UP) do wordle_scroll_attempts_up(&state.wordle, visible_rows)
	if rl.IsKeyPressed(rl.KeyboardKey.DOWN) do wordle_scroll_attempts_down(&state.wordle, visible_rows)
}

handle_wordle_guess_input :: proc(state: ^GameState) {
	if rl.IsKeyPressed(rl.KeyboardKey.BACKSPACE) {
		wordle_pop_letter(&state.wordle)
		return
	}

	for {
		ch := rl.GetCharPressed()
		if ch == 0 {
			break
		}

		if ch >= 'a' && ch <= 'z' {
			ch -= 'a' - 'A'
		}

		if ch >= 'A' && ch <= 'Z' {
			wordle_push_letter(&state.wordle, rune(ch))
		}
	}
}

handle_wordle_submit_input :: proc(state: ^GameState) {
	if rl.IsKeyPressed(rl.KeyboardKey.ENTER) {
		wordle_submit_guess(state)
		wordle_scroll_attempts_latest(&state.wordle, wordle_visible_rows_for_state(state^))
	}
}

handle_wordle_win_input :: proc(state: ^GameState) {
	if rl.IsKeyPressed(rl.KeyboardKey.ENTER) do wordle_continue_after_win(&state.wordle)
}
