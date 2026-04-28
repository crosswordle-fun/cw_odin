package main

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

main :: proc() {
	rl.SetTargetFPS(60)
	rl.SetConfigFlags(rl.ConfigFlags{.WINDOW_RESIZABLE})

	rl.InitWindow(VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT, "cw_odin")
	defer rl.CloseWindow()

	render_frame := render_frame_new()
	defer render_frame_destroy(&render_frame)
	render_target := rl.LoadRenderTexture(VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT)
	defer rl.UnloadRenderTexture(render_target)

	state := game_state_new(VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT)

	for !rl.WindowShouldClose() {
		game_update_screen_size(&state, VIRTUAL_SCREEN_WIDTH, VIRTUAL_SCREEN_HEIGHT)

		if rl.IsKeyPressed(rl.KeyboardKey.ONE) do game_set_view(&state, .Wordle)
		if rl.IsKeyPressed(rl.KeyboardKey.TWO) do game_set_view(&state, .Cross)
		if rl.IsKeyPressed(rl.KeyboardKey.THREE) do game_set_view(&state, .Crafting)

		render_frame_clear(&render_frame)
		ctx := render_context_new(state.screen_width, state.screen_height)
		switch state.view {
		case .Wordle:
			wordle_mode_frame(&render_frame, ctx, &state)
		case .Cross:
			cross_mode_frame(&render_frame, ctx, &state)
		case .Crafting:
			crafting_mode_frame(&render_frame, ctx, &state)
		}

		rl.BeginTextureMode(render_target)
		rl.ClearBackground(rl.Color{20, 20, 24, 255})
		flush_render_frame(render_frame)
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
		rl.ClearBackground(rl.BLACK)
		rl.DrawTexturePro(render_target.texture, source, dest, rl.Vector2{0, 0}, 0, rl.WHITE)
		rl.EndDrawing()
	}
}

draw_mode_tabs :: proc(buffer: ^RenderBuffer, ctx: RenderContext, view: GameView) {
	font_size := scaled_i32(BASE_TITLE_FONT_SIZE, ctx.scale)
	title_gap := scaled_i32(BASE_TITLE_GAP, ctx.scale)
	padding_x := scaled_i32(BASE_TITLE_PADDING_X, ctx.scale)
	padding_y := scaled_i32(BASE_TITLE_PADDING_Y, ctx.scale)
	y := scaled_i32(BASE_TITLE_Y, ctx.scale)

	wordle_label: cstring = "Wordle"
	cross_label: cstring = "Cross"
	crafting_label: cstring = "Crafting"
	wordle_width := rl.MeasureText(wordle_label, font_size)
	cross_width := rl.MeasureText(cross_label, font_size)
	crafting_width := rl.MeasureText(crafting_label, font_size)
	total_width := wordle_width + title_gap + cross_width + title_gap + crafting_width
	start_x := (ctx.screen_width - total_width) / 2

	mode_x := start_x
	mode_width := wordle_width
	mode_label := wordle_label
	active := view == .Wordle
	text_color := rl.WHITE
	if active {
		text_color = rl.Color{20, 20, 24, 255}
		append(
			&buffer.commands,
			RenderCommand {
				kind = .Rect,
				rect = rl.Rectangle {
					f32(mode_x - padding_x),
					f32(y - padding_y),
					f32(mode_width + padding_x * 2),
					f32(font_size + padding_y * 2),
				},
				color = rl.WHITE,
			},
		)
	}
	append(
		&buffer.commands,
		RenderCommand {
			kind = .Text,
			text = mode_label,
			rect = rl.Rectangle{f32(mode_x), f32(y), 0, 0},
			font_size = font_size,
			color = text_color,
		},
	)

	mode_x = start_x + wordle_width + title_gap
	mode_width = cross_width
	mode_label = cross_label
	active = view == .Cross
	text_color = rl.WHITE
	if active {
		text_color = rl.Color{20, 20, 24, 255}
		append(
			&buffer.commands,
			RenderCommand {
				kind = .Rect,
				rect = rl.Rectangle {
					f32(mode_x - padding_x),
					f32(y - padding_y),
					f32(mode_width + padding_x * 2),
					f32(font_size + padding_y * 2),
				},
				color = rl.WHITE,
			},
		)
	}
	append(
		&buffer.commands,
		RenderCommand {
			kind = .Text,
			text = mode_label,
			rect = rl.Rectangle{f32(mode_x), f32(y), 0, 0},
			font_size = font_size,
			color = text_color,
		},
	)

	mode_x = start_x + wordle_width + title_gap + cross_width + title_gap
	mode_width = crafting_width
	mode_label = crafting_label
	active = view == .Crafting
	text_color = rl.WHITE
	if active {
		text_color = rl.Color{20, 20, 24, 255}
		append(
			&buffer.commands,
			RenderCommand {
				kind = .Rect,
				rect = rl.Rectangle {
					f32(mode_x - padding_x),
					f32(y - padding_y),
					f32(mode_width + padding_x * 2),
					f32(font_size + padding_y * 2),
				},
				color = rl.WHITE,
			},
		)
	}
	append(
		&buffer.commands,
		RenderCommand {
			kind = .Text,
			text = mode_label,
			rect = rl.Rectangle{f32(mode_x), f32(y), 0, 0},
			font_size = font_size,
			color = text_color,
		},
	)
}

draw_exp_hud :: proc(buffer: ^RenderBuffer, ctx: RenderContext, exp: u32) {
	font_size := scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale)
	x := scaled_i32(24, ctx.scale)
	y := scaled_i32(24, ctx.scale)
	label := fmt.caprintf("EXP %d", exp)
	append(
		&buffer.commands,
		RenderCommand {
			kind = .Text,
			text = label,
			rect = rl.Rectangle{f32(x), f32(y), 0, 0},
			font_size = font_size,
			color = rl.GOLD,
		},
	)
}

draw_wordle_level :: proc(buffer: ^RenderBuffer, ctx: RenderContext, level: u32) {
	font_size := scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale)
	y := scaled_i32(BASE_WORDLE_LEVEL_Y, ctx.scale)
	label := fmt.caprintf("Level %d", level + 1)
	label_width := rl.MeasureText(label, font_size)
	append(
		&buffer.commands,
		RenderCommand {
			kind = .Text,
			text = label,
			rect = rl.Rectangle{f32((ctx.screen_width - label_width) / 2), f32(y), 0, 0},
			font_size = font_size,
			color = rl.WHITE,
		},
	)
}

draw_inventory_counts :: proc(
	buffer: ^RenderBuffer,
	ctx: RenderContext,
	counts: [LETTER_COUNT]u32,
	color: rl.Color,
) {
	font_size := scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale)
	item_width := scaled_i32(BASE_HUD_ITEM_WIDTH, ctx.scale)
	row_height := scaled_i32(BASE_HUD_ROW_HEIGHT, ctx.scale)
	value_offset := scaled_i32(BASE_HUD_VALUE_OFFSET, ctx.scale)
	hud_width := item_width * 13 - 10
	start_x := (ctx.screen_width - hud_width) / 2
	start_y := ctx.screen_height - (row_height * 2) - 20

	for i in 0 ..< LETTER_COUNT {
		row := i32(i / 13)
		col := i32(i % 13)
		x := start_x + col * item_width
		y := start_y + row * row_height
		label := fmt.caprintf("%c", FRAG_LETTERS[i])
		value := fmt.caprintf("%d", counts[i])

		append(
			&buffer.commands,
			RenderCommand {
				kind = .Text,
				text = label,
				rect = rl.Rectangle{f32(x), f32(y), 0, 0},
				font_size = font_size,
				color = color,
			},
		)
		append(
			&buffer.commands,
			RenderCommand {
				kind = .Text,
				text = value,
				rect = rl.Rectangle{f32(x + value_offset), f32(y), 0, 0},
				font_size = font_size,
				color = color,
			},
		)
	}
}

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

crafting_mode_frame :: proc(frame: ^RenderFrame, ctx: RenderContext, state: ^GameState) {
	if rl.IsKeyPressed(rl.KeyboardKey.ZERO) do game_increment_frags_and_runes(state)

	if rl.IsKeyPressed(rl.KeyboardKey.BACKSPACE) {
		crafting_pop_letter(&state.crafting)
	} else {
		for {
			letter, ok := read_pressed_letter()
			if !ok do break
			crafting_push_letter(&state.crafting, state.frag_counts, letter)
		}
	}

	if rl.IsKeyPressed(rl.KeyboardKey.ENTER) {
		required := Frags{}
		valid := true
		for i in 0 ..< state.crafting.count {
			letter := state.crafting.selected[i]
			frag_index := i32(letter - 'A')
			if frag_index < 0 || frag_index >= LETTER_COUNT {
				valid = false
				break
			}
			required[frag_index] += 1
		}

		if valid {
			for i in 0 ..< LETTER_COUNT {
				if required[i] > state.frag_counts[i] {
					valid = false
					break
				}
			}
		}

		if valid && state.crafting.count == 4 {
			letter := state.crafting.selected[0]
			for i in 1 ..< state.crafting.count {
				if state.crafting.selected[i] != letter {
					valid = false
					break
				}
			}
			if valid {
				frag_index := i32(letter - 'A')
				for i in 0 ..< state.crafting.count {
					state.frag_counts[i32(state.crafting.selected[i] - 'A')] -= 1
				}
				state.rune_counts[frag_index] += 1
				state.exp += RUNE_CRAFT_EXP_REWARD
				state.crafting.crafted_rune = letter
				crafting_clear_selection(&state.crafting)
			}
		} else if valid && state.crafting.count == 5 {
			for i in 0 ..< state.crafting.count {
				for j in i + 1 ..< state.crafting.count {
					if state.crafting.selected[i] == state.crafting.selected[j] {
						valid = false
						break
					}
				}
				if !valid do break
			}
			if valid {
				crafted_index := rl.GetRandomValue(0, LETTER_COUNT - 1)
				for i in 0 ..< state.crafting.count {
					state.frag_counts[i32(state.crafting.selected[i] - 'A')] -= 1
				}
				state.rune_counts[crafted_index] += 1
				state.exp += RUNE_CRAFT_EXP_REWARD
				state.crafting.crafted_rune = FRAG_LETTERS[crafted_index]
				crafting_clear_selection(&state.crafting)
			}
		}
	}

	if rl.IsKeyPressed(rl.KeyboardKey.LEFT_SHIFT) || rl.IsKeyPressed(rl.KeyboardKey.RIGHT_SHIFT) {
		game_toggle_frag_rune_view(state)
	}

	draw_mode_tabs(&frame.ui, ctx, state.view)
	draw_exp_hud(&frame.ui, ctx, state.exp)
	push_centered_text(
		&frame.ui,
		"Crafting",
		ctx.screen_width,
		scaled_i32(105, ctx.scale),
		scaled_i32(BASE_TITLE_FONT_SIZE, ctx.scale),
		rl.WHITE,
	)
	push_centered_text(
		&frame.ui,
		"Fragments",
		ctx.screen_width,
		scaled_i32(170, ctx.scale),
		scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale),
		rl.SKYBLUE,
	)

	cell_size := scaled_i32(BASE_CELL_SIZE, ctx.scale)
	gap := scaled_i32(BASE_GAP, ctx.scale)
	font_size := scaled_i32(BASE_BOARD_FONT_SIZE, ctx.scale)
	board_width := 5 * cell_size + 4 * gap
	start_x := (ctx.screen_width - board_width) / 2
	selected_y := scaled_i32(204, ctx.scale)
	status_y := selected_y + cell_size + scaled_i32(22, ctx.scale)
	output_label_y := status_y + scaled_i32(50, ctx.scale)
	output_y := output_label_y + scaled_i32(34, ctx.scale)
	output_exp_y := output_y + cell_size + scaled_i32(14, ctx.scale)

	for i in 0 ..< len(state.crafting.selected) {
		tile_x := start_x + i32(i) * (cell_size + gap)
		color := rl.DARKGRAY
		if i32(i) < state.crafting.count do color = rl.SKYBLUE
		push_letter_tile(
			&frame.world,
			tile_x,
			selected_y,
			cell_size,
			state.crafting.selected[i],
			color,
			font_size,
		)
	}

	status_label: cstring = "Incomplete Recipe"
	if state.crafting.count == 4 {
		same := true
		letter := state.crafting.selected[0]
		for i in 1 ..< state.crafting.count {
			if state.crafting.selected[i] != letter {
				same = false
				break
			}
		}
		if same do status_label = "Matching Rune"
	}
	if state.crafting.count == 5 {
		different := true
		for i in 0 ..< state.crafting.count {
			for j in i + 1 ..< state.crafting.count {
				if state.crafting.selected[i] == state.crafting.selected[j] {
					different = false
					break
				}
			}
			if !different do break
		}
		if different do status_label = "Random Rune"
	}
	push_centered_text(
		&frame.ui,
		status_label,
		ctx.screen_width,
		status_y,
		scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale),
		rl.LIGHTGRAY,
	)

	push_centered_text(
		&frame.ui,
		"Latest Rune",
		ctx.screen_width,
		output_label_y,
		scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale),
		rl.PURPLE,
	)
	push_letter_tile(
		&frame.world,
		(ctx.screen_width - cell_size) / 2,
		output_y,
		cell_size,
		state.crafting.crafted_rune,
		rl.PURPLE,
		font_size,
	)
	if state.crafting.crafted_rune != 0 {
		reward_detail := fmt.caprintf("+%d EXP", RUNE_CRAFT_EXP_REWARD)
		push_centered_text(
			&frame.ui,
			reward_detail,
			ctx.screen_width,
			output_exp_y,
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

wordle_mode_frame :: proc(frame: ^RenderFrame, ctx: RenderContext, state: ^GameState) {
	cell_size := scaled_i32(BASE_CELL_SIZE, ctx.scale)
	gap := scaled_i32(BASE_GAP, ctx.scale)
	font_size := scaled_i32(BASE_BOARD_FONT_SIZE, ctx.scale)
	start_y := scaled_i32(BASE_WORDLE_BOARD_Y, ctx.scale)
	row_step := cell_size + gap
	visible_rows := wordle_visible_row_count(ctx.screen_height, start_y, row_step)

	if rl.IsKeyPressed(rl.KeyboardKey.LEFT) {
		if len(state.wordle.history) > 0 {
			if state.wordle.view_mode == .Current {
				state.wordle.view_mode = .History
				state.wordle.history_index = i32(len(state.wordle.history)) - 1
			} else if state.wordle.history_index > 0 {
				state.wordle.history_index -= 1
			}
			state.wordle.scroll_row = 0
			if state.wordle.view_mode == .History &&
			   state.wordle.history_index >= 0 &&
			   state.wordle.history_index < i32(len(state.wordle.history)) {
				total_rows := i32(len(state.wordle.history[state.wordle.history_index].guesses))
				state.wordle.scroll_row = total_rows - visible_rows
				if state.wordle.scroll_row < 0 do state.wordle.scroll_row = 0
			}
		}
	}

	if rl.IsKeyPressed(rl.KeyboardKey.RIGHT) {
		if state.wordle.view_mode == .History {
			last_index := i32(len(state.wordle.history)) - 1
			if state.wordle.history_index < last_index {
				state.wordle.history_index += 1
			} else {
				state.wordle.view_mode = .Current
				state.wordle.history_index = -1
			}
			state.wordle.scroll_row = 0
			if state.wordle.view_mode == .History &&
			   state.wordle.history_index >= 0 &&
			   state.wordle.history_index < i32(len(state.wordle.history)) {
				total_rows := i32(len(state.wordle.history[state.wordle.history_index].guesses))
				state.wordle.scroll_row = total_rows - visible_rows
				if state.wordle.scroll_row < 0 do state.wordle.scroll_row = 0
			}
		}
	}

	if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
		if state.wordle.view_mode == .History {
			state.wordle.view_mode = .Current
			state.wordle.history_index = -1
			state.wordle.scroll_row = 0
		}
	}

	if rl.IsKeyPressed(rl.KeyboardKey.UP) {
		total_rows: i32 = 0
		if state.wordle.view_mode == .History {
			if state.wordle.history_index >= 0 &&
			   state.wordle.history_index < i32(len(state.wordle.history)) {
				total_rows = i32(len(state.wordle.history[state.wordle.history_index].guesses))
			}
		} else {
			total_rows = i32(len(state.wordle.guesses))
			if state.wordle.substate == .Playing do total_rows += 1
		}
		max_scroll := total_rows - visible_rows
		if max_scroll < 0 do max_scroll = 0
		state.wordle.scroll_row -= 1
		if state.wordle.scroll_row < 0 do state.wordle.scroll_row = 0
		if state.wordle.scroll_row > max_scroll do state.wordle.scroll_row = max_scroll
	}

	if rl.IsKeyPressed(rl.KeyboardKey.DOWN) {
		total_rows: i32 = 0
		if state.wordle.view_mode == .History {
			if state.wordle.history_index >= 0 &&
			   state.wordle.history_index < i32(len(state.wordle.history)) {
				total_rows = i32(len(state.wordle.history[state.wordle.history_index].guesses))
			}
		} else {
			total_rows = i32(len(state.wordle.guesses))
			if state.wordle.substate == .Playing do total_rows += 1
		}
		max_scroll := total_rows - visible_rows
		if max_scroll < 0 do max_scroll = 0
		state.wordle.scroll_row += 1
		if state.wordle.scroll_row < 0 do state.wordle.scroll_row = 0
		if state.wordle.scroll_row > max_scroll do state.wordle.scroll_row = max_scroll
	}

	if state.wordle.view_mode == .Current {
		if state.wordle.substate == .Playing {
			if rl.IsKeyPressed(rl.KeyboardKey.BACKSPACE) {
				wordle_pop_letter(&state.wordle)
			} else {
				for {
					letter, ok := read_pressed_letter()
					if !ok do break
					wordle_push_letter(&state.wordle, letter)
				}
			}

			if rl.IsKeyPressed(rl.KeyboardKey.ENTER) &&
			   state.wordle.current_count >= WORDLE_WORD_LEN {
				solution := wordle_current_solution(state.wordle)
				guess := wordle_evaluate_guess(state.wordle.current_guess, solution)
				append(&state.wordle.guesses, guess)
				wordle_clear_current_guess(&state.wordle)

				solved := true
				for i in 0 ..< WORDLE_WORD_LEN {
					if guess.feedback[i] != .Correct {
						solved = false
						break
					}
				}
				if solved {
					state.wordle.win_solution = solution
					reward_index := rl.GetRandomValue(0, WORDLE_WORD_LEN - 1)
					reward_letter := solution[reward_index]
					state.wordle.reward_fragment = reward_letter
					frag_index := i32(reward_letter - 'A')
					if frag_index >= 0 && frag_index < LETTER_COUNT {
						state.frag_counts[frag_index] += 1
					}
					state.wordle.reward_exp = WORDLE_LEVEL_EXP_REWARD
					state.exp += state.wordle.reward_exp
					state.wordle.substate = .Won
				}
				total_rows := i32(len(state.wordle.guesses))
				if state.wordle.substate == .Playing do total_rows += 1
				state.wordle.scroll_row = total_rows - visible_rows
				if state.wordle.scroll_row < 0 do state.wordle.scroll_row = 0
			}
		} else if state.wordle.substate == .Won {
			if rl.IsKeyPressed(rl.KeyboardKey.ENTER) {
				record := WordleLevelRecord {
					guesses         = wordle_copy_guesses(state.wordle.guesses),
					level           = state.wordle.level,
					solution        = state.wordle.win_solution,
					reward_fragment = state.wordle.reward_fragment,
					reward_exp      = state.wordle.reward_exp,
				}
				append(&state.wordle.history, record)
				clear(&state.wordle.guesses)
				wordle_clear_current_guess(&state.wordle)
				state.wordle.win_solution = [WORDLE_WORD_LEN]rune{}
				state.wordle.reward_fragment = 0
				state.wordle.reward_exp = 0
				state.wordle.substate = .Playing
				state.wordle.view_mode = .Current
				state.wordle.history_index = -1
				state.wordle.scroll_row = 0
				state.wordle.level += 1
			}
		}
	}

	draw_mode_tabs(&frame.ui, ctx, state.view)
	draw_exp_hud(&frame.ui, ctx, state.exp)
	draw_wordle_level(&frame.ui, ctx, state.wordle.level)

	board_width := WORDLE_WORD_LEN * cell_size + (WORDLE_WORD_LEN - 1) * gap
	start_x := (ctx.screen_width - board_width) / 2

	switch state.wordle.view_mode {
	case .History:
		if state.wordle.history_index >= 0 &&
		   state.wordle.history_index < i32(len(state.wordle.history)) {
			record := state.wordle.history[state.wordle.history_index]
			total_rows := i32(len(record.guesses))
			max_scroll := total_rows - visible_rows
			if max_scroll < 0 do max_scroll = 0
			if state.wordle.scroll_row < 0 do state.wordle.scroll_row = 0
			if state.wordle.scroll_row > max_scroll do state.wordle.scroll_row = max_scroll

			draw_rows: i32 = 0
			for guess_index in state.wordle.scroll_row ..< min(total_rows, state.wordle.scroll_row + visible_rows) {
				y := start_y + draw_rows * row_step
				guess := record.guesses[guess_index]
				for col in 0 ..< WORDLE_WORD_LEN {
					tile_x := start_x + i32(col) * (cell_size + gap)
					color := rl.DARKGRAY
					switch guess.feedback[col] {
					case .Correct:
						color = rl.GREEN
					case .Present:
						color = rl.GOLD
					case .Miss:
						color = rl.GRAY
					case .Empty:
						color = rl.DARKGRAY
					}
					push_letter_tile(
						&frame.world,
						tile_x,
						y,
						cell_size,
						guess.letters[col],
						color,
						font_size,
					)
				}
				draw_rows += 1
			}

			history_reward_size := cell_size / 2
			history_reward_font_size := font_size / 2
			margin := history_reward_size
			exp_x := margin
			exp_y :=
				ctx.screen_height -
				history_reward_size -
				margin +
				(history_reward_size - scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale)) / 2
			exp_label := fmt.caprintf("+%d EXP", record.reward_exp)
			push_text(
				&frame.ui,
				exp_label,
				exp_x,
				exp_y,
				scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale),
				rl.GOLD,
			)
			push_letter_tile(
				&frame.world,
				ctx.screen_width - history_reward_size - margin,
				ctx.screen_height - history_reward_size - margin,
				history_reward_size,
				record.reward_fragment,
				rl.SKYBLUE,
				history_reward_font_size,
			)
		}

	case .Current:
		switch state.wordle.substate {
		case .Playing:
			total_rows := i32(len(state.wordle.guesses)) + 1
			max_scroll := total_rows - visible_rows
			if max_scroll < 0 do max_scroll = 0
			if state.wordle.scroll_row < 0 do state.wordle.scroll_row = 0
			if state.wordle.scroll_row > max_scroll do state.wordle.scroll_row = max_scroll

			draw_rows: i32 = 0
			for guess_index in state.wordle.scroll_row ..< min(i32(len(state.wordle.guesses)), state.wordle.scroll_row + visible_rows) {
				y := start_y + draw_rows * row_step
				guess := state.wordle.guesses[guess_index]
				for col in 0 ..< WORDLE_WORD_LEN {
					tile_x := start_x + i32(col) * (cell_size + gap)
					color := rl.DARKGRAY
					switch guess.feedback[col] {
					case .Correct:
						color = rl.GREEN
					case .Present:
						color = rl.GOLD
					case .Miss:
						color = rl.GRAY
					case .Empty:
						color = rl.DARKGRAY
					}
					push_letter_tile(
						&frame.world,
						tile_x,
						y,
						cell_size,
						guess.letters[col],
						color,
						font_size,
					)
				}
				draw_rows += 1
			}

			if i32(len(state.wordle.guesses)) >= state.wordle.scroll_row &&
			   i32(len(state.wordle.guesses)) < state.wordle.scroll_row + visible_rows {
				y := start_y + draw_rows * row_step
				for col in 0 ..< WORDLE_WORD_LEN {
					tile_x := start_x + i32(col) * (cell_size + gap)
					push_letter_tile(
						&frame.world,
						tile_x,
						y,
						cell_size,
						state.wordle.current_guess[col],
						rl.DARKGRAY,
						font_size,
					)
				}
			}

		case .Won:
			title_y := scaled_i32(165, ctx.scale)
			subtitle_y := title_y + scaled_i32(64, ctx.scale)
			start_y := subtitle_y + scaled_i32(44, ctx.scale)
			reward_label_y := start_y + cell_size + scaled_i32(56, ctx.scale)
			reward_y := reward_label_y + scaled_i32(34, ctx.scale)
			reward_detail_y := reward_y + cell_size + scaled_i32(14, ctx.scale)

			push_centered_text(
				&frame.ui,
				"Congratulations!",
				ctx.screen_width,
				title_y,
				scaled_i32(BASE_TITLE_FONT_SIZE, ctx.scale),
				rl.WHITE,
			)
			push_centered_text(
				&frame.ui,
				"Puzzle solved. Your reward is ready.",
				ctx.screen_width,
				subtitle_y,
				scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale),
				rl.LIGHTGRAY,
			)

			for col in 0 ..< WORDLE_WORD_LEN {
				tile_x := start_x + i32(col) * (cell_size + gap)
				push_letter_tile(
					&frame.world,
					tile_x,
					start_y,
					cell_size,
					state.wordle.win_solution[col],
					rl.GREEN,
					font_size,
				)
			}

			push_centered_text(
				&frame.ui,
				"Rewards",
				ctx.screen_width,
				reward_label_y,
				scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale),
				rl.SKYBLUE,
			)
			push_letter_tile(
				&frame.world,
				(ctx.screen_width - cell_size) / 2,
				reward_y,
				cell_size,
				state.wordle.reward_fragment,
				rl.SKYBLUE,
				font_size,
			)
			reward_detail := fmt.caprintf("+%d EXP", state.wordle.reward_exp)
			push_centered_text(
				&frame.ui,
				reward_detail,
				ctx.screen_width,
				reward_detail_y,
				scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale),
				rl.GOLD,
			)
		}
	}
}

