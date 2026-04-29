package main

import rl "vendor:raylib"

cross_mode_frame :: proc(frame: ^RenderFrame, ctx: RenderContext, state: ^GameState) {
	if rl.IsKeyPressed(rl.KeyboardKey.ZERO) do game_increment_frags_and_runes(state)

	if rl.IsKeyPressed(rl.KeyboardKey.UP) do selector_move(&state.selector, -1, 0, state.grid)
	if rl.IsKeyPressed(rl.KeyboardKey.DOWN) do selector_move(&state.selector, 1, 0, state.grid)
	if rl.IsKeyPressed(rl.KeyboardKey.LEFT) do selector_move(&state.selector, 0, -1, state.grid)
	if rl.IsKeyPressed(rl.KeyboardKey.RIGHT) do selector_move(&state.selector, 0, 1, state.grid)

	if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
		mouse_pos, ok := virtual_mouse_position()
		if ok {
			grid_right := state.grid.offset_x + grid_pixel_width(state.grid)
			grid_bottom := state.grid.offset_y + grid_pixel_height(state.grid)
			if mouse_pos.x >= f32(state.grid.offset_x) &&
			   mouse_pos.y >= f32(state.grid.offset_y) &&
			   mouse_pos.x < f32(grid_right) &&
			   mouse_pos.y < f32(grid_bottom) {
				step := f32(grid_row_step(state.grid))
				col := i32((mouse_pos.x - f32(state.grid.offset_x)) / step)
				row := i32((mouse_pos.y - f32(state.grid.offset_y)) / step)
				selector_set_tile(&state.selector, row, col)
			}
		}
	}

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
					for i in 0 ..< state.selector_buffer.count {
						letter := state.selector_buffer.letters[i]
						frag_index := i32(letter - 'A')
						tile_row, tile_col := selector_letter_position(
							state.grid,
							state.selector,
							i,
						)
						tile_index := grid_tile_index(state.grid, tile_row, tile_col)
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
					selector_buffer_clear(&state.selector_buffer)
				}
			}
		}
	}

	if rl.IsKeyPressed(rl.KeyboardKey.LEFT_SHIFT) || rl.IsKeyPressed(rl.KeyboardKey.RIGHT_SHIFT) {
		game_toggle_frag_rune_view(state)
	}

	build_cross_mode_view(frame, ctx, state)
}
