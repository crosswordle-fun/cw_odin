package main

import rl "vendor:raylib"

wordle_state_new :: proc() -> WordleState {
	return WordleState {
		guesses = make([dynamic]WordleGuess, 0, 32),
		history = make([dynamic]WordleLevelRecord, 0, 32),
		substate = .Playing,
		view_mode = .Current,
		history_index = -1,
	}
}

wordle_solution_index :: proc(wordle: WordleState) -> i32 {
	return i32(wordle.level % WORDLE_SOLUTION_COUNT)
}

wordle_solution_string_to_runes :: proc(solution: string) -> [WORDLE_WORD_LEN]rune {
	letters := [WORDLE_WORD_LEN]rune{}
	for i in 0 ..< WORDLE_WORD_LEN {
		if i < len(solution) {
			letters[i] = rune(solution[i])
		}
	}
	return letters
}

wordle_current_solution :: proc(wordle: WordleState) -> [WORDLE_WORD_LEN]rune {
	return wordle_solution_string_to_runes(WORDLE_SOLUTIONS[wordle_solution_index(wordle)])
}

wordle_is_viewing_current_level :: proc(wordle: WordleState) -> bool {
	return wordle.view_mode == .Current
}

wordle_push_letter :: proc(wordle: ^WordleState, letter: rune) {
	if !wordle_is_viewing_current_level(wordle^) do return
	if wordle.substate != .Playing do return
	if wordle.current_count < WORDLE_WORD_LEN {
		wordle.current_guess[wordle.current_count] = letter
		wordle.current_count += 1
	}
}

wordle_pop_letter :: proc(wordle: ^WordleState) {
	if !wordle_is_viewing_current_level(wordle^) do return
	if wordle.substate != .Playing do return
	if wordle.current_count > 0 {
		wordle.current_count -= 1
		wordle.current_guess[wordle.current_count] = 0
	}
}

wordle_clear_current_guess :: proc(wordle: ^WordleState) {
	for i in 0 ..< WORDLE_WORD_LEN {
		wordle.current_guess[i] = 0
	}
	wordle.current_count = 0
}

wordle_evaluate_guess :: proc(
	guess: [WORDLE_WORD_LEN]rune,
	solution: [WORDLE_WORD_LEN]rune,
) -> WordleGuess {
	result := WordleGuess {
		letters = guess,
	}
	remaining_counts := Frags{}

	for i in 0 ..< WORDLE_WORD_LEN {
		if guess[i] == solution[i] {
			result.feedback[i] = .Correct
		} else {
			solution_index := i32(solution[i] - 'A')
			if solution_index >= 0 && solution_index < LETTER_COUNT {
				remaining_counts[solution_index] += 1
			}
		}
	}

	for i in 0 ..< WORDLE_WORD_LEN {
		if result.feedback[i] == .Correct do continue

		guess_index := i32(guess[i] - 'A')
		if guess_index >= 0 && guess_index < LETTER_COUNT && remaining_counts[guess_index] > 0 {
			result.feedback[i] = .Present
			remaining_counts[guess_index] -= 1
		} else {
			result.feedback[i] = .Miss
		}
	}

	return result
}

wordle_copy_guesses :: proc(guesses: [dynamic]WordleGuess) -> [dynamic]WordleGuess {
	copied := make([dynamic]WordleGuess, len(guesses), len(guesses))
	for i in 0 ..< len(guesses) {
		copied[i] = guesses[i]
	}
	return copied
}

wordle_visible_row_count :: proc(screen_height: i32, start_y: i32, row_step: i32) -> i32 {
	visible_rows := (screen_height - start_y - row_step) / row_step
	if visible_rows < 1 do visible_rows = 1
	return visible_rows
}

wordle_display_level :: proc(wordle: WordleState) -> u32 {
	if wordle.view_mode == .History &&
	   wordle.history_index >= 0 &&
	   wordle.history_index < i32(len(wordle.history)) {
		return wordle.history[wordle.history_index].level
	}
	return wordle.level
}

wordle_total_rows :: proc(wordle: WordleState) -> i32 {
	if wordle.view_mode == .History {
		if wordle.history_index >= 0 && wordle.history_index < i32(len(wordle.history)) {
			return i32(len(wordle.history[wordle.history_index].guesses))
		}
		return 0
	}

	total_rows := i32(len(wordle.guesses))
	if wordle.substate == .Playing do total_rows += 1
	return total_rows
}

wordle_clamp_scroll :: proc(wordle: ^WordleState, visible_rows: i32) {
	max_scroll := wordle_total_rows(wordle^) - visible_rows
	if max_scroll < 0 do max_scroll = 0
	if wordle.scroll_row < 0 do wordle.scroll_row = 0
	if wordle.scroll_row > max_scroll do wordle.scroll_row = max_scroll
}

wordle_scroll_to_end :: proc(wordle: ^WordleState, visible_rows: i32) {
	wordle.scroll_row = wordle_total_rows(wordle^) - visible_rows
	wordle_clamp_scroll(wordle, visible_rows)
}

wordle_show_previous_history :: proc(wordle: ^WordleState, visible_rows: i32) {
	if len(wordle.history) <= 0 do return

	if wordle.view_mode == .Current {
		wordle.view_mode = .History
		wordle.history_index = i32(len(wordle.history)) - 1
	} else if wordle.history_index > 0 {
		wordle.history_index -= 1
	}
	wordle_scroll_to_end(wordle, visible_rows)
}

wordle_show_next_history :: proc(wordle: ^WordleState, visible_rows: i32) {
	if wordle.view_mode != .History do return

	last_index := i32(len(wordle.history)) - 1
	if wordle.history_index < last_index {
		wordle.history_index += 1
	} else {
		wordle.view_mode = .Current
		wordle.history_index = -1
		wordle.scroll_row = 0
		return
	}
	wordle_scroll_to_end(wordle, visible_rows)
}

wordle_show_current_level :: proc(wordle: ^WordleState) {
	wordle.view_mode = .Current
	wordle.history_index = -1
	wordle.scroll_row = 0
}

wordle_guess_solved :: proc(guess: WordleGuess) -> bool {
	for i in 0 ..< WORDLE_WORD_LEN {
		if guess.feedback[i] != .Correct do return false
	}
	return true
}

wordle_apply_level_reward :: proc(
	state: ^GameState,
	ctx: RenderContext,
	solution: [WORDLE_WORD_LEN]rune,
) {
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

wordle_submit_guess :: proc(state: ^GameState, ctx: RenderContext, visible_rows: i32) {
	if state.wordle.current_count < WORDLE_WORD_LEN {
		ui_note_invalid(&state.ui)
		return
	}

	solution := wordle_current_solution(state.wordle)
	guess := wordle_evaluate_guess(state.wordle.current_guess, solution)
	append(&state.wordle.guesses, guess)
	ui_note_wordle_guess(&state.ui, i32(len(state.wordle.guesses)) - 1)
	wordle_clear_current_guess(&state.wordle)

	if wordle_guess_solved(guess) {
		wordle_apply_level_reward(state, ctx, solution)
	}
	wordle_scroll_to_end(&state.wordle, visible_rows)
}

wordle_advance_level :: proc(wordle: ^WordleState) {
	record := WordleLevelRecord {
		guesses         = wordle_copy_guesses(wordle.guesses),
		level           = wordle.level,
		solution        = wordle.win_solution,
		reward_fragment = wordle.reward_fragment,
		reward_exp      = wordle.reward_exp,
	}
	append(&wordle.history, record)
	clear(&wordle.guesses)
	wordle_clear_current_guess(wordle)
	wordle.win_solution = [WORDLE_WORD_LEN]rune{}
	wordle.reward_fragment = 0
	wordle.reward_exp = 0
	wordle.substate = .Playing
	wordle.view_mode = .Current
	wordle.history_index = -1
	wordle.scroll_row = 0
	wordle.level += 1
}

wordle_mode_frame :: proc(frame: ^RenderFrame, ctx: RenderContext, state: ^GameState) {
	cell_size := scaled_i32(BASE_CELL_SIZE, ctx.scale)
	gap := scaled_i32(BASE_GAP, ctx.scale)
	start_y := scaled_i32(BASE_WORDLE_BOARD_Y, ctx.scale)
	row_step := tile_row_step(cell_size, gap)
	visible_rows := wordle_visible_row_count(ctx.screen_height, start_y, row_step)

	if rl.IsKeyPressed(rl.KeyboardKey.LEFT) {
		wordle_show_previous_history(&state.wordle, visible_rows)
	}

	if rl.IsKeyPressed(rl.KeyboardKey.RIGHT) {
		wordle_show_next_history(&state.wordle, visible_rows)
	}

	if rl.IsKeyPressed(rl.KeyboardKey.SPACE) {
		if state.wordle.view_mode == .History {
			wordle_show_current_level(&state.wordle)
		}
	}

	if rl.IsKeyPressed(rl.KeyboardKey.UP) {
		state.wordle.scroll_row -= 1
		wordle_clamp_scroll(&state.wordle, visible_rows)
	}

	if rl.IsKeyPressed(rl.KeyboardKey.DOWN) {
		state.wordle.scroll_row += 1
		wordle_clamp_scroll(&state.wordle, visible_rows)
	}

	if state.wordle.view_mode == .Current {
		if state.wordle.substate == .Playing {
			if rl.IsKeyPressed(rl.KeyboardKey.BACKSPACE) {
				wordle_pop_letter(&state.wordle)
			} else {
				input_read_letters_to_wordle(&state.wordle)
			}

			if rl.IsKeyPressed(rl.KeyboardKey.ENTER) {
				wordle_submit_guess(state, ctx, visible_rows)
			}
		} else if state.wordle.substate == .Won {
			if rl.IsKeyPressed(rl.KeyboardKey.ENTER) {
				wordle_advance_level(&state.wordle)
			}
		}
	}

	if input_shift_pressed() {
		game_toggle_frag_rune_view(state)
	}

	build_wordle_mode_view(frame, ctx, state)
}
