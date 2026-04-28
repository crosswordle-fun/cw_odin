package main

import "core:fmt"
import rl "vendor:raylib"

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
