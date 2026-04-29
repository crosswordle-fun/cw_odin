package main

import rl "vendor:raylib"

crafting_clear_selection :: proc(crafting: ^CraftingState) {
	for i in 0 ..< len(crafting.selected) {
		crafting.selected[i] = 0
	}
	crafting.count = 0
}

crafting_selected_count_for_letter :: proc(crafting: CraftingState, letter: rune) -> u32 {
	count: u32 = 0
	for i in 0 ..< crafting.count {
		if crafting.selected[i] == letter do count += 1
	}
	return count
}

crafting_push_letter :: proc(crafting: ^CraftingState, frag_counts: Frags, letter: rune) {
	if crafting.count >= i32(len(crafting.selected[:])) do return

	frag_index := i32(letter - 'A')
	if frag_index < 0 || frag_index >= LETTER_COUNT do return
	if crafting_selected_count_for_letter(crafting^, letter) >= frag_counts[frag_index] do return

	crafting.selected[crafting.count] = letter
	crafting.count += 1
}

crafting_pop_letter :: proc(crafting: ^CraftingState) {
	if crafting.count <= 0 do return

	crafting.count -= 1
	crafting.selected[crafting.count] = 0
}

crafting_required_counts :: proc(crafting: CraftingState) -> (required: Frags, ok: bool) {
	for i in 0 ..< crafting.count {
		letter := crafting.selected[i]
		frag_index := i32(letter - 'A')
		if frag_index < 0 || frag_index >= LETTER_COUNT do return required, false
		required[frag_index] += 1
	}
	return required, true
}

crafting_can_make_matching_rune :: proc(crafting: CraftingState) -> (letter: rune, ok: bool) {
	if crafting.count != 4 do return 0, false

	letter = crafting.selected[0]
	for i in 1 ..< crafting.count {
		if crafting.selected[i] != letter do return 0, false
	}
	return letter, true
}

crafting_can_make_random_rune :: proc(crafting: CraftingState) -> bool {
	if crafting.count != 5 do return false

	for i in 0 ..< crafting.count {
		for j in i + 1 ..< crafting.count {
			if crafting.selected[i] == crafting.selected[j] do return false
		}
	}
	return true
}

crafting_status_label :: proc(crafting: CraftingState) -> cstring {
	if _, matching := crafting_can_make_matching_rune(crafting); matching {
		return "MATCHING RUNE"
	}
	if crafting_can_make_random_rune(crafting) do return "RANDOM RUNE"
	return "INCOMPLETE RECIPE"
}

crafting_has_required_frags :: proc(frag_counts: Frags, required: Frags) -> bool {
	for i in 0 ..< LETTER_COUNT {
		if required[i] > frag_counts[i] do return false
	}
	return true
}

crafting_apply_recipe :: proc(state: ^GameState, ctx: RenderContext, crafted_rune: rune) {
	for i in 0 ..< state.crafting.count {
		state.frag_counts[i32(state.crafting.selected[i] - 'A')] -= 1
	}

	crafted_index := i32(crafted_rune - 'A')
	state.rune_counts[crafted_index] += 1
	state.exp += RUNE_CRAFT_EXP_REWARD
	state.crafting.crafted_rune = crafted_rune
	ui_note_crafted_rune(&state.ui)
	ui_note_exp_reward(
		&state.ui,
		RUNE_CRAFT_EXP_REWARD,
		f32(state.screen_width / 2),
		f32(scaled_i32(410, ctx.scale)),
		state.theme.exp,
	)
	ui_spawn_burst(
		&state.ui,
		f32(state.screen_width / 2),
		f32(scaled_i32(410, ctx.scale)),
		state.theme.highlight_rune,
		22,
	)
	crafting_clear_selection(&state.crafting)
}

crafting_submit_selection :: proc(state: ^GameState, ctx: RenderContext) {
	required, ok := crafting_required_counts(state.crafting)
	if !ok || !crafting_has_required_frags(state.frag_counts, required) {
		ui_note_invalid(&state.ui)
		return
	}

	if crafted_rune, matching := crafting_can_make_matching_rune(state.crafting); matching {
		crafting_apply_recipe(state, ctx, crafted_rune)
		return
	}

	if crafting_can_make_random_rune(state.crafting) {
		crafted_index := rl.GetRandomValue(0, LETTER_COUNT - 1)
		crafting_apply_recipe(state, ctx, FRAG_LETTERS[crafted_index])
		return
	}

	ui_note_invalid(&state.ui)
}

crafting_mode_frame :: proc(frame: ^RenderFrame, ctx: RenderContext, state: ^GameState) {
	if rl.IsKeyPressed(rl.KeyboardKey.ZERO) do game_increment_frags_and_runes(state)

	if rl.IsKeyPressed(rl.KeyboardKey.BACKSPACE) {
		crafting_pop_letter(&state.crafting)
	} else {
		input_read_letters_to_crafting(&state.crafting, state.frag_counts)
	}

	if rl.IsKeyPressed(rl.KeyboardKey.ENTER) {
		crafting_submit_selection(state, ctx)
	}

	if input_shift_pressed() {
		game_toggle_frag_rune_view(state)
	}

	build_crafting_mode_view(frame, ctx, state)
}
