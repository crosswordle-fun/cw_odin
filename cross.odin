package main

import rl "vendor:raylib"

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
		for {
			letter, ok := read_pressed_letter()
			if !ok do break
			selector_buffer_push_letter(&state.selector_buffer, letter)
		}
	}

	if rl.IsKeyPressed(rl.KeyboardKey.ENTER) {
		if state.selector_buffer.count > 0 {
			fits := true
			if state.selector.down {
				if state.selector.row + state.selector_buffer.count > state.grid.rows do fits = false
			} else {
				if state.selector.col + state.selector_buffer.count > state.grid.cols do fits = false
			}

			if fits {
				required := Frags{}
				valid := true
				for i in 0 ..< state.selector_buffer.count {
					letter := state.selector_buffer.letters[i]
					frag_index := i32(letter - 'A')
					tile_row, tile_col := selector_letter_position(state.grid, state.selector, i)
					tile_index := grid_tile_index(state.grid, tile_row, tile_col)
					if tile_index < 0 ||
					   tile_index >= i32(len(state.grid.frags)) ||
					   frag_index < 0 ||
					   frag_index >= LETTER_COUNT {
						valid = false
						break
					}

					required[frag_index] += 1
					if state.show_frags {
						if state.grid.frags[tile_index] != 0 {
							valid = false
							break
						}
					} else {
						if state.grid.frags[tile_index] != letter ||
						   state.grid.runes[tile_index] != 0 {
							valid = false
							break
						}
					}
				}

				if valid {
					if state.show_frags {
						for i in 0 ..< LETTER_COUNT {
							if required[i] > state.frag_counts[i] {
								valid = false
								break
							}
						}
					} else {
						for i in 0 ..< LETTER_COUNT {
							if required[i] > state.rune_counts[i] {
								valid = false
								break
							}
						}
					}
				}

				if valid {
					state.cross_reward_exp = 0
					burst_x := f32(0)
					burst_y := f32(0)
					for i in 0 ..< state.selector_buffer.count {
						letter := state.selector_buffer.letters[i]
						frag_index := i32(letter - 'A')
						tile_row, tile_col := selector_letter_position(
							state.grid,
							state.selector,
							i,
						)
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
					if state.selector_buffer.count > 0 {
						burst_x /= f32(state.selector_buffer.count)
						burst_y /= f32(state.selector_buffer.count)
						reward_color := state.theme.highlight_fragment
						if !state.show_frags do reward_color = state.theme.highlight_rune
						ui_note_exp_reward(
							&state.ui,
							state.cross_reward_exp,
							burst_x,
							burst_y,
							state.theme.exp,
						)
						ui_spawn_burst(&state.ui, burst_x, burst_y, reward_color, 10)
					}
					selector_buffer_clear(&state.selector_buffer)
				} else {
					ui_note_invalid(&state.ui)
				}
			} else {
				ui_note_invalid(&state.ui)
			}
		} else {
			ui_note_invalid(&state.ui)
		}
	}

	if rl.IsKeyPressed(rl.KeyboardKey.LEFT_SHIFT) || rl.IsKeyPressed(rl.KeyboardKey.RIGHT_SHIFT) {
		game_toggle_frag_rune_view(state)
	}

	build_cross_mode_view(frame, ctx, state)
}
