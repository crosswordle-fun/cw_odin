package main

import "core:fmt"
import rl "vendor:raylib"

MenuLayout :: struct {
	title_x:         i32,
	title_y:         i32,
	title_face_size: i32,
	title_gap:       i32,
	title_font_size: i32,
	title_height:    i32,
	button_x:        i32,
	button_width:    i32,
	button_height:   i32,
	button_font:     i32,
	start_y:         i32,
	exit_y:          i32,
}

MenuSelection :: enum {
	Start,
	Exit,
}

menu_layout :: proc(ctx: RenderContext) -> MenuLayout {
	title_label := "CROSSWORDLE"
	start_label: cstring = "START"
	exit_label: cstring = "EXIT"

	title_face_size := scaled_i32(72, ctx.scale)
	title_gap := i32(rl.Clamp(f32(title_face_size) / 20.0, 1, f32(title_face_size)))
	title_base_height := title_face_size / 10
	if title_base_height < 1 do title_base_height = 1
	title_height := title_face_size + title_base_height
	title_font_size := i32(rl.Clamp(f32(title_face_size) * 0.58, 1, f32(title_face_size)))
	button_font := scaled_i32(28, ctx.scale)
	button_padding_x := scaled_i32(28, ctx.scale)
	button_padding_y := scaled_i32(14, ctx.scale)
	button_gap := scaled_i32(16, ctx.scale)

	title_width :=
		i32(len(title_label)) * title_face_size + (i32(len(title_label)) - 1) * title_gap
	start_width := measure_text_width(start_label, button_font)
	exit_width := measure_text_width(exit_label, button_font)
	button_text_width := start_width
	if exit_width > button_text_width do button_text_width = exit_width

	button_width := button_text_width + button_padding_x * 2
	button_height := button_font + button_padding_y * 2
	title_x := (ctx.screen_width - title_width) / 2
	title_y := (ctx.screen_height - title_height) / 2
	button_x := (ctx.screen_width - button_width) / 2
	start_y := title_y + title_height + scaled_i32(32, ctx.scale)
	exit_y := start_y + button_height + button_gap

	return MenuLayout {
		title_x = title_x,
		title_y = title_y,
		title_face_size = title_face_size,
		title_gap = title_gap,
		title_font_size = title_font_size,
		title_height = title_height,
		button_x = button_x,
		button_width = button_width,
		button_height = button_height,
		button_font = button_font,
		start_y = start_y,
		exit_y = exit_y,
	}
}

menu_selection_from_state :: proc(selection: i32) -> MenuSelection {
	if selection == 1 do return .Exit
	return .Start
}

menu_selection_to_state :: proc(selection: MenuSelection) -> i32 {
	if selection == .Exit do return 1
	return 0
}

menu_title_drop_bounce :: proc(tile_age: f32) -> f32 {
	if tile_age >= 0.5 do return 0
	bounce := (1 - saturate(tile_age / 0.5)) * -28
	if tile_age > 0 do bounce = -28 + rl.EaseBounceOut(tile_age, 0, 28, 0.5)
	return bounce
}

menu_title_rebounce :: proc(tile_age: f32) -> f32 {
	raise_duration := f32(0.38)
	fall_duration := f32(0.52)
	lift := f32(-22)

	if tile_age < 0 do return 0
	if tile_age < raise_duration {
		return rl.EaseSineInOut(tile_age, 0, lift, raise_duration)
	}

	fall_age := tile_age - raise_duration
	if fall_age < fall_duration {
		return rl.EaseBounceOut(fall_age, lift, -lift, fall_duration)
	}

	return 0
}

menu_title_cycle_color :: proc(
	gray, yellow, green, blue, purple: rl.Color,
	age, period: f32,
) -> rl.Color {
	if period <= 0 do return gray

	position := rl.Wrap(age, 0, period) / period
	if position < 1.0 / 5.0 {
		return lerp_color(gray, yellow, ease01(position * 5.0))
	}
	if position < 2.0 / 5.0 {
		return lerp_color(yellow, green, ease01((position - 1.0 / 5.0) * 5.0))
	}
	if position < 3.0 / 5.0 {
		return lerp_color(green, blue, ease01((position - 2.0 / 5.0) * 5.0))
	}
	if position < 4.0 / 5.0 {
		return lerp_color(blue, purple, ease01((position - 3.0 / 5.0) * 5.0))
	}
	return lerp_color(purple, gray, ease01((position - 4.0 / 5.0) * 5.0))
}

build_menu_title :: proc(buffer: ^RenderBuffer, layout: MenuLayout, theme: Theme, ui: UiState) {
	title_label := "CROSSWORDLE"
	elapsed := ui.time - ui.view_enter_time
	title_stagger := f32(0.045)
	bounce_duration := f32(0.5)
	rebounce_period := f32(3.0)
	initial_drop_duration := bounce_duration + f32(len(title_label) - 1) * title_stagger

	x := layout.title_x
	for i in 0 ..< len(title_label) {
		tile_age := elapsed - f32(i) * title_stagger
		bounce := menu_title_drop_bounce(tile_age)
		if elapsed >= initial_drop_duration + rebounce_period {
			rebounce_elapsed := rl.Wrap(elapsed - initial_drop_duration, 0, rebounce_period)
			rebounce_age := rebounce_elapsed - f32(i) * title_stagger
			if rebounce_age >= 0 {
				bounce = menu_title_rebounce(rebounce_age)
			}
		}
		color_age := elapsed - f32(i) * title_stagger
		face_color := menu_title_cycle_color(
			theme.surface,
			TAILWIND_YELLOW_400,
			TAILWIND_GREEN_400,
			TAILWIND_BLUE_400,
			TAILWIND_PURPLE_400,
			color_age,
			rebounce_period,
		)
		base_color := menu_title_cycle_color(
			theme.surface_shadow,
			TAILWIND_YELLOW_600,
			TAILWIND_GREEN_600,
			TAILWIND_BLUE_600,
			TAILWIND_PURPLE_600,
			color_age,
			rebounce_period,
		)
		build_title_tile(
			buffer,
			TitleTile {
				x = x,
				y = layout.title_y + i32(bounce),
				face_size = layout.title_face_size,
				letter = rune(title_label[i]),
				face_color = face_color,
				base_color = base_color,
				font_size = layout.title_font_size,
				text_color = theme.text,
				outline = theme.outline,
			},
		)
		x += layout.title_face_size + layout.title_gap
	}
}

build_menu_mode_view :: proc(
	frame: ^RenderFrame,
	ctx: RenderContext,
	layout: MenuLayout,
	start_hovered: bool,
	exit_hovered: bool,
	selection: MenuSelection,
	theme: Theme,
	ui: UiState,
) {
	build_menu_title(&frame.ui, layout, theme, ui)
	build_button(
		&frame.ui,
		"START",
		layout.button_x,
		layout.start_y,
		layout.button_width,
		layout.button_height,
		layout.button_font,
		start_hovered,
		theme,
	)
	build_button(
		&frame.ui,
		"EXIT",
		layout.button_x,
		layout.exit_y,
		layout.button_width,
		layout.button_height,
		layout.button_font,
		exit_hovered,
		theme,
	)

	draw_ui_effects(&frame.overlay, ctx, ui)
}

menu_mode_frame :: proc(frame: ^RenderFrame, ctx: RenderContext, state: ^GameState) {
	layout := menu_layout(ctx)
	selection := menu_selection_from_state(state.menu_selection)

	if rl.IsKeyPressed(rl.KeyboardKey.UP) || rl.IsKeyPressed(rl.KeyboardKey.DOWN) {
		if selection == .Start {
			selection = .Exit
		} else {
			selection = .Start
		}
	}

	if rl.IsKeyPressed(rl.KeyboardKey.ENTER) {
		switch selection {
		case .Start:
			game_set_view(state, .Wordle)
		case .Exit:
			state.should_quit = true
		}
	}

	state.menu_selection = menu_selection_to_state(selection)
	start_hovered := selection == .Start
	exit_hovered := selection == .Exit
	build_menu_mode_view(
		frame,
		ctx,
		layout,
		start_hovered,
		exit_hovered,
		selection,
		ctx.theme,
		state.ui,
	)
}

build_crossword_grid :: proc(
	buffer: ^RenderBuffer,
	grid: Grid,
	selector: Selector,
	selector_buffer: SelectorBuffer,
	theme: Theme,
	ui: UiState,
) {
	scale := f32(grid.cell_size) / f32(BASE_CELL_SIZE)
	font_size := scaled_i32(BASE_BOARD_FONT_SIZE, scale)

	for i in 0 ..< len(grid.tiles) {
		tile := grid.tiles[i]
		x, y := grid_tile_position(grid, tile.row, tile.col)
		pop_key := tile.row * 100 + tile.col
		pop_scale := ui_tile_pop_scale(ui, pop_key)
		covered_by_selector := tile.row == selector.row && tile.col == selector.col
		for preview_index in 0 ..< selector_buffer.count {
			preview_row, preview_col := selector_letter_position(grid, selector, preview_index)
			if tile.row == preview_row && tile.col == preview_col {
				covered_by_selector = true
				break
			}
		}

		if grid.runes[i] != 0 {
			build_tile_scaled(
				buffer,
				x,
				y,
				grid.cell_size,
				grid.runes[i],
				theme.highlight_rune,
				font_size,
				theme,
				pop_scale,
			)
		} else if grid.frags[i] != 0 {
			build_tile_scaled(
				buffer,
				x,
				y,
				grid.cell_size,
				grid.frags[i],
				theme.highlight_fragment,
				font_size,
				theme,
				pop_scale,
			)
		} else {
			if covered_by_selector do continue
			push_rect(buffer, x, y, grid.cell_size, grid.cell_size, theme.empty_tile)
			push_rect_lines(buffer, x, y, grid.cell_size, grid.cell_size, 2, theme.outline)
		}
	}
}

build_crossword_selector_overlay :: proc(
	buffer: ^RenderBuffer,
	grid: Grid,
	selector: Selector,
	selector_buffer: SelectorBuffer,
	show_frags: bool,
	theme: Theme,
	ui: UiState,
) {
	selector_color := theme.highlight_fragment
	selector_shadow := theme.highlight_fragment_shadow
	if !show_frags do selector_color = theme.highlight_rune
	if !show_frags do selector_shadow = theme.highlight_rune_shadow

	scale := f32(grid.cell_size) / f32(BASE_CELL_SIZE)
	font_size := scaled_i32(BASE_SELECTOR_FONT_SIZE, scale)
	selector_alpha: u8 = 100

	shake := ui_invalid_shake_x(ui, f32(grid.cell_size) * 0.12)
	x, y := grid_tile_position(grid, selector.row, selector.col)
	preview_face := with_alpha(selector_color, selector_alpha)
	preview_base := with_alpha(selector_shadow, selector_alpha)
	preview_outline := theme.outline
	if selector_buffer.count == 0 {
		build_layered_tile(
			buffer,
			x + i32(shake),
			y - grid_tile_base_height(grid.cell_size),
			grid.cell_size,
			0,
			preview_face,
			preview_base,
			font_size,
			theme.text,
			preview_outline,
		)
	}

	for i in 0 ..< selector_buffer.count {
		row, col := selector_letter_position(grid, selector, i)
		tile_x, tile_y := grid_tile_position(grid, row, col)
		preview_x := tile_x + i32(shake)
		build_layered_tile_with_corner_letter(
			buffer,
			preview_x,
			tile_y - grid_tile_base_height(grid.cell_size),
			grid.cell_size,
			selector_buffer.letters[i],
			preview_face,
			preview_base,
			font_size,
			theme.text,
			preview_outline,
		)
	}
}

wordle_feedback_color :: proc(feedback: WordleFeedback, theme: Theme) -> rl.Color {
	switch feedback {
	case .Correct:
		return theme.wordle_correct
	case .Present:
		return theme.wordle_present
	case .Miss:
		return theme.wordle_miss
	case .Empty:
		return theme.wordle_empty
	}
	return theme.wordle_empty
}

build_wordle_guess_row :: proc(
	buffer: ^RenderBuffer,
	x: i32,
	y: i32,
	cell_size: i32,
	gap: i32,
	font_size: i32,
	guess: WordleGuess,
	theme: Theme,
	ui: UiState,
	row_index: i32,
) {
	for col in 0 ..< WORDLE_WORD_LEN {
		tile_x := x + i32(col) * (cell_size + gap)
		color := wordle_feedback_color(guess.feedback[col], theme)
		face_lift := i32(0)
		if ui.wordle_reveal_guess_row == row_index {
			lift := grid_tile_base_height(cell_size)
			face_lift = wordle_submit_click_lift(ui.wordle_reveal_age, lift)
			if face_lift < 0 do color = theme.wordle_empty
		}
		build_tile_with_face_lift(
			buffer,
			tile_x,
			y,
			cell_size,
			guess.letters[col],
			color,
			font_size,
			theme,
			face_lift,
		)
	}
}

build_wordle_current_row :: proc(
	buffer: ^RenderBuffer,
	x: i32,
	y: i32,
	cell_size: i32,
	gap: i32,
	font_size: i32,
	current_guess: [WORDLE_WORD_LEN]rune,
	theme: Theme,
	ctx: RenderContext,
	ui: UiState,
) {
	shake := i32(ui_invalid_shake_x(ui, f32(cell_size) * 0.10))
	for col in 0 ..< WORDLE_WORD_LEN {
		tile_x := x + i32(col) * (cell_size + gap) + shake
		if current_guess[col] != 0 {
			lift := tile_click_lift(ctx.time, grid_tile_base_height(cell_size))
			build_tile_with_face_lift(
				buffer,
				tile_x,
				y,
				cell_size,
				current_guess[col],
				theme.wordle_empty,
				font_size,
				theme,
				lift,
			)
		} else {
			build_tile_or_square(
				buffer,
				tile_x,
				y,
				cell_size,
				current_guess[col],
				theme.wordle_empty,
				theme.wordle_empty,
				font_size,
				theme,
			)
		}
	}
}

build_wordle_play_board :: proc(
	buffer: ^RenderBuffer,
	ctx: RenderContext,
	wordle: WordleState,
	ui: UiState,
) {
	cell_size := scaled_i32(BASE_CELL_SIZE, ctx.scale)
	gap := scaled_i32(BASE_GAP, ctx.scale)
	font_size := scaled_i32(BASE_BOARD_FONT_SIZE, ctx.scale)
	start_y := scaled_i32(BASE_WORDLE_BOARD_Y, ctx.scale)
	row_step := tile_row_step(cell_size, gap)
	visible_rows := wordle_visible_row_count(ctx.screen_height, start_y, row_step)
	board_width := WORDLE_WORD_LEN * cell_size + (WORDLE_WORD_LEN - 1) * gap
	start_x := (ctx.screen_width - board_width) / 2

	total_rows := i32(len(wordle.guesses)) + 1
	max_scroll := total_rows - visible_rows
	if max_scroll < 0 do max_scroll = 0
	scroll_row := wordle.scroll_row
	if scroll_row < 0 do scroll_row = 0
	if scroll_row > max_scroll do scroll_row = max_scroll

	draw_rows: i32 = 0
	for guess_index in scroll_row ..< min(i32(len(wordle.guesses)), scroll_row + visible_rows) {
		y := start_y + draw_rows * row_step
		build_wordle_guess_row(
			buffer,
			start_x,
			y,
			cell_size,
			gap,
			font_size,
			wordle.guesses[guess_index],
			ctx.theme,
			ui,
			guess_index,
		)
		draw_rows += 1
	}

	if i32(len(wordle.guesses)) >= scroll_row &&
	   i32(len(wordle.guesses)) < scroll_row + visible_rows {
		y := start_y + draw_rows * row_step
		build_wordle_current_row(
			buffer,
			start_x,
			y,
			cell_size,
			gap,
			font_size,
			wordle.current_guess,
			ctx.theme,
			ctx,
			ui,
		)
	}
}

build_wordle_history_board :: proc(
	buffer: ^RenderBuffer,
	ctx: RenderContext,
	wordle: WordleState,
	ui: UiState,
) {
	cell_size := scaled_i32(BASE_CELL_SIZE, ctx.scale)
	gap := scaled_i32(BASE_GAP, ctx.scale)
	font_size := scaled_i32(BASE_BOARD_FONT_SIZE, ctx.scale)
	start_y := scaled_i32(BASE_WORDLE_BOARD_Y, ctx.scale)
	row_step := tile_row_step(cell_size, gap)
	visible_rows := wordle_visible_row_count(ctx.screen_height, start_y, row_step)
	board_width := WORDLE_WORD_LEN * cell_size + (WORDLE_WORD_LEN - 1) * gap
	start_x := (ctx.screen_width - board_width) / 2

	if wordle.history_index < 0 || wordle.history_index >= i32(len(wordle.history)) do return

	record := wordle.history[wordle.history_index]
	total_rows := i32(len(record.guesses))
	max_scroll := total_rows - visible_rows
	if max_scroll < 0 do max_scroll = 0
	scroll_row := wordle.scroll_row
	if scroll_row < 0 do scroll_row = 0
	if scroll_row > max_scroll do scroll_row = max_scroll

	draw_rows: i32 = 0
	for guess_index in scroll_row ..< min(total_rows, scroll_row + visible_rows) {
		y := start_y + draw_rows * row_step
		build_wordle_guess_row(
			buffer,
			start_x,
			y,
			cell_size,
			gap,
			font_size,
			record.guesses[guess_index],
			ctx.theme,
			ui,
			-10,
		)
		draw_rows += 1
	}

	history_reward_size := cell_size / 2
	history_reward_font_size := font_size / 2
	margin := scaled_i32(40, ctx.scale)
	reward_gap := scaled_i32(14, ctx.scale)
	reward_y := ctx.screen_height - history_reward_size - margin
	exp_label := fmt.caprintf("+%d EXP", record.reward_exp)
	exp_font_size := scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale)
	exp_width := measure_text_width(exp_label, exp_font_size)
	reward_x := margin
	exp_x := reward_x
	exp_y := reward_y + (history_reward_size - exp_font_size) / 2
	tile_x := reward_x + exp_width + reward_gap
	build_text(buffer, exp_label, exp_x, exp_y, exp_font_size, ctx.theme.exp)
	build_tile(
		buffer,
		tile_x,
		reward_y,
		history_reward_size,
		record.reward_fragment,
		ctx.theme.highlight_fragment,
		history_reward_font_size,
		ctx.theme,
	)
}

build_wordle_won_panel :: proc(
	buffer: ^RenderBuffer,
	ctx: RenderContext,
	wordle: WordleState,
	ui: UiState,
) {
	cell_size := scaled_i32(BASE_CELL_SIZE, ctx.scale)
	gap := scaled_i32(BASE_GAP, ctx.scale)
	font_size := scaled_i32(BASE_BOARD_FONT_SIZE, ctx.scale)
	board_width := WORDLE_WORD_LEN * cell_size + (WORDLE_WORD_LEN - 1) * gap
	start_x := (ctx.screen_width - board_width) / 2

	title_y := scaled_i32(165, ctx.scale)
	subtitle_y := title_y + scaled_i32(64, ctx.scale)
	start_y := subtitle_y + scaled_i32(44, ctx.scale)
	reward_label_y := start_y + cell_size + scaled_i32(56, ctx.scale)
	reward_y := reward_label_y + scaled_i32(34, ctx.scale)
	reward_detail_y := reward_y + cell_size + scaled_i32(14, ctx.scale)

	build_centered_text(
		buffer,
		"CONGRATULATIONS!",
		ctx.screen_width,
		title_y,
		scaled_i32(BASE_TITLE_FONT_SIZE, ctx.scale),
		ctx.theme.text,
	)
	build_centered_text(
		buffer,
		"PUZZLE SOLVED. YOUR REWARD IS READY.",
		ctx.screen_width,
		subtitle_y,
		scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale),
		ctx.theme.text_muted,
	)

	for col in 0 ..< WORDLE_WORD_LEN {
		tile_x := start_x + i32(col) * (cell_size + gap)
		build_tile(
			buffer,
			tile_x,
			start_y,
			cell_size,
			wordle.win_solution[col],
			ctx.theme.wordle_correct,
			font_size,
			ctx.theme,
		)
	}

	build_centered_text(
		buffer,
		"REWARDS",
		ctx.screen_width,
		reward_label_y,
		scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale),
		ctx.theme.highlight_fragment,
	)
	reward_scale := f32(1)
	if ui.wordle_reveal_age < 1.1 do reward_scale = 0.86 + 0.14 * rl.EaseBackOut(saturate(ui.wordle_reveal_age / 0.38), 0, 1, 1)
	build_tile_scaled(
		buffer,
		(ctx.screen_width - cell_size) / 2,
		reward_y,
		cell_size,
		wordle.reward_fragment,
		ctx.theme.highlight_fragment,
		font_size,
		ctx.theme,
		reward_scale,
	)
	reward_detail := fmt.caprintf("+%d EXP", wordle.reward_exp)
	build_centered_text(
		buffer,
		reward_detail,
		ctx.screen_width,
		reward_detail_y,
		scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale),
		ctx.theme.exp,
	)
}

build_wordle_mode_view :: proc(frame: ^RenderFrame, ctx: RenderContext, state: ^GameState) {
	build_wordle_level(&frame.ui, ctx, wordle_display_level(state.wordle))

	switch state.wordle.view_mode {
	case .History:
		build_wordle_history_board(&frame.world, ctx, state.wordle, state.ui)

	case .Current:
		switch state.wordle.substate {
		case .Playing:
			build_wordle_play_board(&frame.world, ctx, state.wordle, state.ui)
		case .Won:
			build_wordle_won_panel(&frame.world, ctx, state.wordle, state.ui)
		}
	}
	draw_ui_effects(&frame.overlay, ctx, state.ui)
}

build_crafting_mode_view :: proc(frame: ^RenderFrame, ctx: RenderContext, state: ^GameState) {
	build_centered_text(
		&frame.ui,
		"FRAGMENTS",
		ctx.screen_width,
		scaled_i32(170, ctx.scale),
		scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale),
		ctx.theme.highlight_fragment,
	)

	cell_size := scaled_i32(BASE_CELL_SIZE, ctx.scale)
	gap := scaled_i32(BASE_GAP, ctx.scale)
	font_size := scaled_i32(BASE_BOARD_FONT_SIZE, ctx.scale)
	board_width := 5 * cell_size + 4 * gap
	start_x := (ctx.screen_width - board_width) / 2
	selected_y := scaled_i32(204, ctx.scale)
	selection_shake := i32(ui_invalid_shake_x(state.ui, f32(cell_size) * 0.10))
	status_y := selected_y + cell_size + scaled_i32(22, ctx.scale)
	output_label_y := status_y + scaled_i32(50, ctx.scale)
	output_y := output_label_y + scaled_i32(34, ctx.scale)
	output_exp_y := output_y + cell_size + scaled_i32(14, ctx.scale)

	for i in 0 ..< len(state.crafting.selected) {
		tile_x := start_x + i32(i) * (cell_size + gap) + selection_shake
		letter := state.crafting.selected[i]
		color := ctx.theme.highlight_fragment
		if i32(i) >= state.crafting.count do color = ctx.theme.empty_tile
		if letter != 0 {
			lift := tile_click_lift(ctx.time, grid_tile_base_height(cell_size), i32(i))
			build_tile_with_face_lift(
				&frame.world,
				tile_x,
				selected_y,
				cell_size,
				letter,
				color,
				font_size,
				ctx.theme,
				lift,
			)
		} else {
			build_tile_or_square(
				&frame.world,
				tile_x,
				selected_y,
				cell_size,
				letter,
				color,
				ctx.theme.empty_tile,
				font_size,
				ctx.theme,
			)
		}
	}

	build_centered_text(
		&frame.ui,
		crafting_status_label(state.crafting),
		ctx.screen_width,
		status_y,
		scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale),
		ctx.theme.text_muted,
	)

	build_centered_text(
		&frame.ui,
		"LATEST RUNE",
		ctx.screen_width,
		output_label_y,
		scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale),
		ctx.theme.highlight_rune,
	)
	rune_scale := f32(1)
	if state.crafting.crafted_rune != 0 && state.ui.crafted_rune_age < 0.8 {
		rune_scale =
			0.78 + 0.22 * rl.EaseBackOut(saturate(state.ui.crafted_rune_age / 0.32), 0, 1, 1)
	}
	if state.crafting.crafted_rune != 0 {
		build_tile_scaled(
			&frame.world,
			(ctx.screen_width - cell_size) / 2,
			output_y,
			cell_size,
			state.crafting.crafted_rune,
			ctx.theme.highlight_rune,
			font_size,
			ctx.theme,
			rune_scale,
		)
	} else {
		build_tile_or_square(
			&frame.world,
			(ctx.screen_width - cell_size) / 2,
			output_y,
			cell_size,
			state.crafting.crafted_rune,
			ctx.theme.highlight_rune,
			ctx.theme.empty_tile,
			font_size,
			ctx.theme,
		)
	}
	if state.crafting.crafted_rune != 0 {
		reward_detail := fmt.caprintf("+%d EXP", RUNE_CRAFT_EXP_REWARD)
		build_centered_text(
			&frame.ui,
			reward_detail,
			ctx.screen_width,
			output_exp_y,
			scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale),
			ctx.theme.exp,
		)
	}

	draw_ui_effects(&frame.overlay, ctx, state.ui)
}

build_cross_mode_view :: proc(frame: ^RenderFrame, ctx: RenderContext, state: ^GameState) {
	build_crossword_grid(
		&frame.world,
		state.grid,
		state.selector,
		state.selector_buffer,
		ctx.theme,
		state.ui,
	)
	build_crossword_selector_overlay(
		&frame.overlay,
		state.grid,
		state.selector,
		state.selector_buffer,
		state.show_frags,
		ctx.theme,
		state.ui,
	)

	if state.cross_reward_exp != 0 {
		grid_bottom := state.grid.offset_y + grid_pixel_height(state.grid)
		hud_start_y := state.screen_height - (scaled_i32(BASE_HUD_ROW_HEIGHT, ctx.scale) * 2) - 20
		reward_y :=
			grid_bottom +
			(hud_start_y - grid_bottom - scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale)) / 2
		label := fmt.caprintf("+%d EXP", state.cross_reward_exp)
		build_centered_text(
			&frame.ui,
			label,
			state.screen_width,
			reward_y,
			scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale),
			ctx.theme.exp,
		)
	}

	draw_ui_effects(&frame.overlay, ctx, state.ui)
}
