package main

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

cross_mode_frame :: proc(frame: ^RenderFrame, ctx: RenderContext, state: ^GameState) {
	if rl.IsKeyPressed(rl.KeyboardKey.ZERO) do game_increment_frags_and_runes(state)

	if rl.IsKeyPressed(rl.KeyboardKey.UP) do selector_move(&state.selector, -1, 0, state.grid)
	if rl.IsKeyPressed(rl.KeyboardKey.DOWN) do selector_move(&state.selector, 1, 0, state.grid)
	if rl.IsKeyPressed(rl.KeyboardKey.LEFT) do selector_move(&state.selector, 0, -1, state.grid)
	if rl.IsKeyPressed(rl.KeyboardKey.RIGHT) do selector_move(&state.selector, 0, 1, state.grid)

	if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
		mouse_pos := rl.GetMousePosition()
		win_w := f32(rl.GetScreenWidth())
		win_h := f32(rl.GetScreenHeight())
		scale := math.min(win_w / f32(VIRTUAL_SCREEN_WIDTH), win_h / f32(VIRTUAL_SCREEN_HEIGHT))
		dst_w := f32(VIRTUAL_SCREEN_WIDTH) * scale
		dst_h := f32(VIRTUAL_SCREEN_HEIGHT) * scale
		dst_x := (win_w - dst_w) * 0.5
		dst_y := (win_h - dst_h) * 0.5

		if mouse_pos.x >= dst_x &&
		   mouse_pos.y >= dst_y &&
		   mouse_pos.x < dst_x + dst_w &&
		   mouse_pos.y < dst_y + dst_h {
			mouse_pos.x = (mouse_pos.x - dst_x) / scale
			mouse_pos.y = (mouse_pos.y - dst_y) / scale
			grid_right := state.grid.offset_x + grid_pixel_width(state.grid)
			grid_bottom := state.grid.offset_y + grid_pixel_height(state.grid)
			if mouse_pos.x >= f32(state.grid.offset_x) &&
			   mouse_pos.y >= f32(state.grid.offset_y) &&
			   mouse_pos.x < f32(grid_right) &&
			   mouse_pos.y < f32(grid_bottom) {
				step := f32(state.grid.cell_size + state.grid.gap)
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

	draw_mode_tabs(&frame.ui, ctx, state.view)
	draw_exp_hud(&frame.ui, ctx, state.exp)

	scale := f32(state.grid.cell_size) / f32(BASE_CELL_SIZE)
	font_size := scaled_i32(BASE_BOARD_FONT_SIZE, scale)
	rune_padding := scaled_i32(BASE_RUNE_PADDING, scale)

	for i in 0 ..< len(state.grid.tiles) {
		tile := state.grid.tiles[i]
		x, y := grid_tile_position(state.grid, tile.row, tile.col)

		if state.grid.frags[i] != 0 {
			push_letter_tile(
				&frame.world,
				x,
				y,
				state.grid.cell_size,
				state.grid.frags[i],
				rl.SKYBLUE,
				font_size,
			)
		} else {
			push_rect(&frame.world, x, y, state.grid.cell_size, state.grid.cell_size, rl.DARKGRAY)
		}

		if state.grid.runes[i] != 0 {
			rune_size := state.grid.cell_size - rune_padding * 2
			push_letter_tile(
				&frame.world,
				x + rune_padding,
				y + rune_padding,
				rune_size,
				state.grid.runes[i],
				rl.PURPLE,
				font_size,
			)
		}
	}

	line_color := rl.SKYBLUE
	if !state.show_frags do line_color = rl.PURPLE
	x, y := grid_tile_position(state.grid, state.selector.row, state.selector.col)
	push_rect_lines(
		&frame.overlay,
		x,
		y,
		state.grid.cell_size,
		state.grid.cell_size,
		f32(BASE_SELECTOR_OUTLINE) * f32(state.grid.cell_size) / f32(BASE_CELL_SIZE),
		line_color,
	)

	for i in 0 ..< state.selector_buffer.count {
		row, col := selector_letter_position(state.grid, state.selector, i)
		tile_x, tile_y := grid_tile_position(state.grid, row, col)
		push_rect_lines(
			&frame.overlay,
			tile_x,
			tile_y,
			state.grid.cell_size,
			state.grid.cell_size,
			3,
			line_color,
		)
		label := fmt.caprintf("%c", state.selector_buffer.letters[i])
		label_offset := scaled_i32(BASE_SELECTOR_LABEL_OFFSET, scale)
		push_text(
			&frame.overlay,
			label,
			tile_x + state.grid.cell_size - font_size - label_offset,
			tile_y + state.grid.cell_size - font_size - label_offset,
			scaled_i32(BASE_SELECTOR_FONT_SIZE, scale),
			rl.WHITE,
		)
	}

	if state.cross_reward_exp != 0 {
		grid_bottom := state.grid.offset_y + grid_pixel_height(state.grid)
		hud_start_y := state.screen_height - (scaled_i32(BASE_HUD_ROW_HEIGHT, ctx.scale) * 2) - 20
		reward_y :=
			grid_bottom +
			(hud_start_y - grid_bottom - scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale)) / 2
		label := fmt.caprintf("+%d EXP", state.cross_reward_exp)
		push_centered_text(
			&frame.ui,
			label,
			state.screen_width,
			reward_y,
			scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale),
			rl.GOLD,
		)
	}

	inventory_counts := state.frag_counts
	inventory_color := rl.SKYBLUE
	if !state.show_frags {
		inventory_counts = state.rune_counts
		inventory_color = rl.PURPLE
	}
	draw_inventory_counts(&frame.ui, ctx, inventory_counts, inventory_color)
}
