package main

import rl "vendor:raylib"

cross_placement_fits :: proc(
	selector: Selector,
	selector_buffer: SelectorBuffer,
	grid: Grid,
) -> bool {
	if selector_buffer.count <= 0 do return false
	if selector.down {
		return selector.row + selector_buffer.count <= grid.rows
	}
	return selector.col + selector_buffer.count <= grid.cols
}

cross_collect_required :: proc(state: ^GameState) -> (required: Frags, ok: bool) {
	if !cross_placement_fits(state.selector, state.selector_buffer, state.grid) do return required, false

	for i in 0 ..< state.selector_buffer.count {
		letter := state.selector_buffer.letters[i]
		frag_index := i32(letter - 'A')
		tile_row, tile_col := selector_letter_position(state.grid, state.selector, i)
		tile_index := grid_tile_index(state.grid, tile_row, tile_col)
		if tile_index < 0 ||
		   tile_index >= i32(len(state.grid.frags)) ||
		   frag_index < 0 ||
		   frag_index >= LETTER_COUNT {
			return required, false
		}

		required[frag_index] += 1
		if state.show_frags {
			if state.grid.frags[tile_index] != 0 do return required, false
		} else {
			if state.grid.frags[tile_index] != letter || state.grid.runes[tile_index] != 0 {
				return required, false
			}
		}
	}

	return required, true
}

cross_can_place :: proc(state: ^GameState, required: Frags) -> bool {
	for i in 0 ..< LETTER_COUNT {
		if state.show_frags {
			if required[i] > state.frag_counts[i] do return false
		} else {
			if required[i] > state.rune_counts[i] do return false
		}
	}
	return true
}

cross_apply_placement :: proc(state: ^GameState) {
	state.cross_reward_exp = 0
	burst_x := f32(0)
	burst_y := f32(0)

	for i in 0 ..< state.selector_buffer.count {
		letter := state.selector_buffer.letters[i]
		frag_index := i32(letter - 'A')
		tile_row, tile_col := selector_letter_position(state.grid, state.selector, i)
		tile_index := grid_tile_index(state.grid, tile_row, tile_col)
		tile_x, tile_y := grid_tile_position(state.grid, tile_row, tile_col)

		ui_note_tile_pop(&state.ui, tile_row * 100 + tile_col)
		burst_x += f32(tile_x + state.grid.cell_size / 2)
		burst_y += f32(tile_y + state.grid.cell_size / 2)
		if state.show_frags {
			state.grid.frags[tile_index] = letter
			state.frag_counts[frag_index] -= 1
			state.exp += state.grid.frag_exp[tile_index]
			state.cross_reward_exp += state.grid.frag_exp[tile_index]
		} else {
			state.grid.runes[tile_index] = letter
			state.rune_counts[frag_index] -= 1
			state.exp += state.grid.rune_exp[tile_index]
			state.cross_reward_exp += state.grid.rune_exp[tile_index]
		}
	}

	burst_x /= f32(state.selector_buffer.count)
	burst_y /= f32(state.selector_buffer.count)
	reward_color := state.theme.highlight_fragment
	if !state.show_frags do reward_color = state.theme.highlight_rune
	ui_note_exp_reward(&state.ui, state.cross_reward_exp, burst_x, burst_y, state.theme.exp)
	ui_spawn_burst(&state.ui, burst_x, burst_y, reward_color, 10)
	selector_buffer_clear(&state.selector_buffer)
}

cross_submit_buffer :: proc(state: ^GameState) {
	required, ok := cross_collect_required(state)
	if !ok || !cross_can_place(state, required) {
		ui_note_invalid(&state.ui)
		return
	}
	cross_apply_placement(state)
}

cross_mode_frame :: proc(frame: ^RenderFrame, ctx: RenderContext, state: ^GameState) {
	if rl.IsKeyPressed(rl.KeyboardKey.ZERO) do game_increment_frags_and_runes(state)

	if rl.IsKeyPressed(rl.KeyboardKey.UP) do selector_move(&state.selector, -1, 0, state.grid)
	if rl.IsKeyPressed(rl.KeyboardKey.DOWN) do selector_move(&state.selector, 1, 0, state.grid)
	if rl.IsKeyPressed(rl.KeyboardKey.LEFT) do selector_move(&state.selector, 0, -1, state.grid)
	if rl.IsKeyPressed(rl.KeyboardKey.RIGHT) do selector_move(&state.selector, 0, 1, state.grid)

	if rl.IsKeyPressed(rl.KeyboardKey.SPACE) do selector_toggle_direction(&state.selector)

	if rl.IsKeyPressed(rl.KeyboardKey.BACKSPACE) {
		selector_buffer_pop(&state.selector_buffer)
	} else {
		input_read_letters_to_selector_buffer(&state.selector_buffer)
	}

	if rl.IsKeyPressed(rl.KeyboardKey.ENTER) {
		cross_submit_buffer(state)
	}

	if input_shift_pressed() {
		game_toggle_frag_rune_view(state)
	}

	build_cross_mode_view(frame, ctx, state)
}
