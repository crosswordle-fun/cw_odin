package main

import "core:fmt"
import rl "vendor:raylib"

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
