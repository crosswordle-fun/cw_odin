package main

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
	if rl.IsKeyPressed(rl.KeyboardKey.ONE) do game_increment_frags_and_runes(state)
}

handle_view_toggle_input :: proc(state: ^GameState) {
	if rl.IsKeyPressed(rl.KeyboardKey.TAB) do game_toggle_frag_rune_view(state)
}
