package main

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
		did_craft := false
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

		if valid && state.crafting.count == game_data.crafting.matching_required {
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
				state.exp += game_data.crafting.exp_reward
				state.crafting.crafted_rune = letter
				ui_note_crafted_rune(&state.ui)
				ui_note_exp_reward(
					&state.ui,
					game_data.crafting.exp_reward,
					f32(state.screen_width / 2),
					f32(scaled_i32(game_data.crafting.reward_exp_y, ctx.scale)),
					state.theme.exp,
				)
				ui_spawn_burst(
					&state.ui,
					f32(state.screen_width / 2),
					f32(scaled_i32(game_data.crafting.reward_exp_y, ctx.scale)),
					state.theme.highlight_rune,
					game_data.crafting.reward_burst_count,
				)
				crafting_clear_selection(&state.crafting)
				did_craft = true
			}
		} else if valid && state.crafting.count == game_data.crafting.random_required {
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
				crafted_index := rl.GetRandomValue(0, i32(len(game_data.grid.alphabet)) - 1)
				for i in 0 ..< state.crafting.count {
					state.frag_counts[i32(state.crafting.selected[i] - 'A')] -= 1
				}
				state.rune_counts[crafted_index] += 1
				state.exp += game_data.crafting.exp_reward
				state.crafting.crafted_rune = game_data.grid.alphabet[crafted_index]
				ui_note_crafted_rune(&state.ui)
				ui_note_exp_reward(
					&state.ui,
					game_data.crafting.exp_reward,
					f32(state.screen_width / 2),
					f32(scaled_i32(game_data.crafting.reward_exp_y, ctx.scale)),
					state.theme.exp,
				)
				ui_spawn_burst(
					&state.ui,
					f32(state.screen_width / 2),
					f32(scaled_i32(game_data.crafting.reward_exp_y, ctx.scale)),
					state.theme.highlight_rune,
					game_data.crafting.reward_burst_count,
				)
				crafting_clear_selection(&state.crafting)
				did_craft = true
			}
		}
		if !did_craft do ui_note_invalid(&state.ui)
	}

	if rl.IsKeyPressed(rl.KeyboardKey.LEFT_SHIFT) || rl.IsKeyPressed(rl.KeyboardKey.RIGHT_SHIFT) {
		game_toggle_frag_rune_view(state)
	}

	build_crafting_mode_view(frame, ctx, state)
}
