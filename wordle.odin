package main

import rl "vendor:raylib"

wordle_mode_frame :: proc(frame: ^RenderFrame, ctx: RenderContext, state: ^GameState) {
	cell_size := scaled_i32(BASE_CELL_SIZE, ctx.scale)
	gap := scaled_i32(BASE_GAP, ctx.scale)
	start_y := scaled_i32(BASE_WORDLE_BOARD_Y, ctx.scale)
	row_step := tile_row_step(cell_size, gap)
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
				ui_note_wordle_guess(&state.ui, i32(len(state.wordle.guesses)) - 1)
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
					ui_note_exp_reward(
						&state.ui,
						state.wordle.reward_exp,
						f32(state.screen_width / 2),
						f32(scaled_i32(360, ctx.scale)),
						state.theme.exp,
					)
					ui_spawn_burst(
						&state.ui,
						f32(state.screen_width / 2),
						f32(scaled_i32(360, ctx.scale)),
						state.theme.wordle_correct,
						24,
					)
					state.wordle.substate = .Won
				}
				total_rows := i32(len(state.wordle.guesses))
				if state.wordle.substate == .Playing do total_rows += 1
				state.wordle.scroll_row = total_rows - visible_rows
				if state.wordle.scroll_row < 0 do state.wordle.scroll_row = 0
			} else if rl.IsKeyPressed(rl.KeyboardKey.ENTER) {
				ui_note_invalid(&state.ui)
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

	build_wordle_mode_view(frame, ctx, state)
}
