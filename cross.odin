package main

import rl "vendor:raylib"

cross_key_delta :: proc(key: rl.KeyboardKey) -> (row_delta: i32, col_delta: i32, ok: bool) {
	#partial switch key {
	case rl.KeyboardKey.UP:
		return -1, 0, true
	case rl.KeyboardKey.DOWN:
		return 1, 0, true
	case rl.KeyboardKey.LEFT:
		return 0, -1, true
	case rl.KeyboardKey.RIGHT:
		return 0, 1, true
	}
	return 0, 0, false
}

cross_latest_pressed_arrow :: proc() -> rl.KeyboardKey {
	latest := rl.KeyboardKey.KEY_NULL
	if rl.IsKeyPressed(rl.KeyboardKey.UP) do latest = rl.KeyboardKey.UP
	if rl.IsKeyPressed(rl.KeyboardKey.DOWN) do latest = rl.KeyboardKey.DOWN
	if rl.IsKeyPressed(rl.KeyboardKey.LEFT) do latest = rl.KeyboardKey.LEFT
	if rl.IsKeyPressed(rl.KeyboardKey.RIGHT) do latest = rl.KeyboardKey.RIGHT
	return latest
}

cross_any_down_arrow :: proc() -> rl.KeyboardKey {
	if rl.IsKeyDown(rl.KeyboardKey.UP) do return rl.KeyboardKey.UP
	if rl.IsKeyDown(rl.KeyboardKey.DOWN) do return rl.KeyboardKey.DOWN
	if rl.IsKeyDown(rl.KeyboardKey.LEFT) do return rl.KeyboardKey.LEFT
	if rl.IsKeyDown(rl.KeyboardKey.RIGHT) do return rl.KeyboardKey.RIGHT
	return rl.KeyboardKey.KEY_NULL
}

cross_update_selector_movement :: proc(state: ^GameState, dt: f32) {
	key := cross_latest_pressed_arrow()
	if key == rl.KeyboardKey.KEY_NULL {
		if state.cross_held_key != rl.KeyboardKey.KEY_NULL && rl.IsKeyDown(state.cross_held_key) {
			key = state.cross_held_key
		} else {
			key = cross_any_down_arrow()
		}
	}

	if key == rl.KeyboardKey.KEY_NULL {
		state.cross_held_key = rl.KeyboardKey.KEY_NULL
		state.cross_hold_age = 0
		state.cross_repeat_age = 0
		return
	}

	moved := false
	if key != state.cross_held_key {
		state.cross_held_key = key
		state.cross_hold_age = 0
		state.cross_repeat_age = 0
		moved = true
	} else {
		state.cross_hold_age += dt
		state.cross_repeat_age += dt
		if state.cross_hold_age >= CROSS_MOVE_REPEAT_DELAY &&
		   state.cross_repeat_age >= CROSS_MOVE_REPEAT_INTERVAL {
			moved = true
			state.cross_repeat_age = 0
		}
	}

	if moved {
		row_delta, col_delta, ok := cross_key_delta(key)
		if ok {
			selector_move(&state.selector, row_delta, col_delta, state.grid)
			grid_update_viewport(&state.grid, state.selector)
		}
	}
}

cross_mode_frame :: proc(frame: ^RenderFrame, ctx: RenderContext, state: ^GameState) {
	if rl.IsKeyPressed(rl.KeyboardKey.ZERO) do game_increment_frags_and_runes(state)

	cross_update_selector_movement(state, ctx.dt)

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
				if state.selector_buffer.count > state.grid.rows do fits = false
			} else {
				if state.selector_buffer.count > state.grid.cols do fits = false
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
						ui_note_tile_pop(&state.ui, tile_row * 100 + tile_col)
						if grid_tile_visible(state.grid, tile_row, tile_col) {
							tile_x, tile_y := grid_tile_position(state.grid, tile_row, tile_col)
							burst_x += f32(tile_x + state.grid.cell_size / 2)
							burst_y += f32(tile_y + state.grid.cell_size / 2)
						}
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
						visible_count: i32 = 0
						for i in 0 ..< state.selector_buffer.count {
							tile_row, tile_col := selector_letter_position(
								state.grid,
								state.selector,
								i,
							)
							if grid_tile_visible(state.grid, tile_row, tile_col) do visible_count += 1
						}
						if visible_count > 0 {
							burst_x /= f32(visible_count)
							burst_y /= f32(visible_count)
						} else {
							tile_x, tile_y := grid_tile_position(
								state.grid,
								state.selector.row,
								state.selector.col,
							)
							burst_x = f32(tile_x + state.grid.cell_size / 2)
							burst_y = f32(tile_y + state.grid.cell_size / 2)
						}
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
