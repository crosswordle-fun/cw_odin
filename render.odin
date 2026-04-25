package main

import "core:fmt"
import rl "vendor:raylib"

render_title_word :: proc(
	label: cstring,
	x: i32,
	y: i32,
	font_size: i32,
	padding_x: i32,
	padding_y: i32,
	active: bool,
) {
	text_width := rl.MeasureText(label, font_size)
	text_color := rl.WHITE

	if active {
		rl.DrawRectangle(
			x - padding_x,
			y - padding_y,
			text_width + padding_x * 2,
			font_size + padding_y * 2,
			rl.WHITE,
		)
		text_color = rl.Color{20, 20, 24, 255}
	}

	rl.DrawText(label, x, y, font_size, text_color)
}

render_title :: proc(screen_width: i32, screen_height: i32, game_mode: GameMode) {
	scale := screen_scale(screen_width, screen_height)
	font_size := scaled_i32(BASE_TITLE_FONT_SIZE, scale)
	title_gap := scaled_i32(BASE_TITLE_GAP, scale)
	padding_x := scaled_i32(BASE_TITLE_PADDING_X, scale)
	padding_y := scaled_i32(BASE_TITLE_PADDING_Y, scale)
	y := scaled_i32(BASE_TITLE_Y, scale)

	cross_label: cstring = "Cross"
	wordle_label: cstring = "Wordle"
	cross_width := rl.MeasureText(cross_label, font_size)
	wordle_width := rl.MeasureText(wordle_label, font_size)
	total_width := cross_width + title_gap + wordle_width
	start_x := (screen_width - total_width) / 2

	render_title_word(
		cross_label,
		start_x,
		y,
		font_size,
		padding_x,
		padding_y,
		game_mode == .Cross,
	)
	render_title_word(
		wordle_label,
		start_x + cross_width + title_gap,
		y,
		font_size,
		padding_x,
		padding_y,
		game_mode == .Wordle,
	)
}

render_selector :: proc(grid: Grid, selector: Selector, selector_buffer: SelectorBuffer, show_frags: bool) {
	line_color := rl.SKYBLUE
	if !show_frags {
		line_color = rl.PURPLE
	}

	x, y := grid_tile_position(grid, selector.row, selector.col)
	rl.DrawRectangleLinesEx(
		rl.Rectangle{f32(x), f32(y), f32(grid.cell_size), f32(grid.cell_size)},
		f32(BASE_SELECTOR_OUTLINE) * f32(grid.cell_size) / f32(BASE_CELL_SIZE),
		line_color,
	)

	for i in 0 ..< selector_buffer.count {
		row, col := selector_letter_position(grid, selector, i)
		x, y := grid_tile_position(grid, row, col)
		rl.DrawRectangleLinesEx(
			rl.Rectangle{f32(x), f32(y), f32(grid.cell_size), f32(grid.cell_size)},
			3,
			line_color,
		)
	}
}

render_selector_letter :: proc(grid: Grid, selector: Selector, selector_buffer: SelectorBuffer) {
	if selector_buffer.count == 0 do return

	scale := f32(grid.cell_size) / f32(BASE_CELL_SIZE)
	font_size := scaled_i32(BASE_SELECTOR_FONT_SIZE, f32(grid.cell_size) / f32(BASE_CELL_SIZE))
	label_offset := scaled_i32(BASE_SELECTOR_LABEL_OFFSET, scale)
	for i in 0 ..< selector_buffer.count {
		row, col := selector_letter_position(grid, selector, i)
		x, y := grid_tile_position(grid, row, col)
		label := fmt.caprintf("%c", selector_buffer.letters[i])
		rl.DrawText(
			label,
			x + grid.cell_size - font_size - label_offset,
			y + grid.cell_size - font_size - label_offset,
			font_size,
			rl.WHITE,
		)
	}
}

render_grid :: proc(grid: Grid) {
	scale := f32(grid.cell_size) / f32(BASE_CELL_SIZE)
	font_size := scaled_i32(BASE_BOARD_FONT_SIZE, scale)
	rune_padding := scaled_i32(BASE_RUNE_PADDING, scale)
	for i in 0 ..< len(grid.tiles) {
		tile := grid.tiles[i]
		x, y := grid_tile_position(grid, tile.row, tile.col)

		if grid.frags[i] != 0 {
			rl.DrawRectangle(x, y, grid.cell_size, grid.cell_size, rl.SKYBLUE)
			label := fmt.caprintf("%c", grid.frags[i])
			text_width := rl.MeasureText(label, font_size)
			text_x := x + (grid.cell_size - text_width) / 2
			text_y := y + (grid.cell_size - font_size) / 2
			rl.DrawText(label, text_x, text_y, font_size, rl.WHITE)
		} else {
			rl.DrawRectangle(x, y, grid.cell_size, grid.cell_size, rl.DARKGRAY)
		}

		if grid.runes[i] != 0 {
			rune_size := grid.cell_size - rune_padding * 2
			rune_x := x + rune_padding
			rune_y := y + rune_padding

			rl.DrawRectangle(rune_x, rune_y, rune_size, rune_size, rl.PURPLE)
			label := fmt.caprintf("%c", grid.runes[i])
			text_width := rl.MeasureText(label, font_size)
			text_x := rune_x + (rune_size - text_width) / 2
			text_y := rune_y + (rune_size - font_size) / 2
			rl.DrawText(label, text_x, text_y, font_size, rl.WHITE)
		}
	}
}

render_inventory_counts :: proc(
	screen_width: i32,
	screen_height: i32,
	counts: [LETTER_COUNT]u32,
	color: rl.Color,
) {
	scale := screen_scale(screen_width, screen_height)

	font_size := scaled_i32(BASE_HUD_FONT_SIZE, scale)
	item_width := scaled_i32(BASE_HUD_ITEM_WIDTH, scale)
	row_height := scaled_i32(BASE_HUD_ROW_HEIGHT, scale)
	value_offset := scaled_i32(BASE_HUD_VALUE_OFFSET, scale)
	hud_width := item_width * 13 - 10
	start_x := (screen_width - hud_width) / 2
	start_y := screen_height - (row_height * 2) - 20

	for i in 0 ..< LETTER_COUNT {
		row := i32(i / 13)
		col := i32(i % 13)
		x := start_x + col * item_width
		y := start_y + row * row_height
		label := fmt.caprintf("%c", FRAG_LETTERS[i])
		value := fmt.caprintf("%d", counts[i])

		rl.DrawText(label, x, y, font_size, color)
		rl.DrawText(value, x + value_offset, y, font_size, color)
	}
}

render_frags :: proc(screen_width: i32, screen_height: i32, frag_counts: Frags) {
	render_inventory_counts(screen_width, screen_height, frag_counts, rl.SKYBLUE)
}

render_runes :: proc(screen_width: i32, screen_height: i32, rune_counts: Runes) {
	render_inventory_counts(screen_width, screen_height, rune_counts, rl.PURPLE)
}

wordle_feedback_color :: proc(feedback: WordleFeedback) -> rl.Color {
	switch feedback {
	case .Correct:
		return rl.GREEN
	case .Present:
		return rl.GOLD
	case .Miss:
		return rl.GRAY
	case .Empty:
		return rl.DARKGRAY
	case:
		return rl.DARKGRAY
	}
}

render_wordle_tile :: proc(
	x: i32,
	y: i32,
	size: i32,
	letter: rune,
	feedback: WordleFeedback,
	font_size: i32,
) {
	tile_color := wordle_feedback_color(feedback)
	rl.DrawRectangle(x, y, size, size, tile_color)

	if letter != 0 {
		label := fmt.caprintf("%c", letter)
		text_width := rl.MeasureText(label, font_size)
		text_x := x + (size - text_width) / 2
		text_y := y + (size - font_size) / 2
		rl.DrawText(label, text_x, text_y, font_size, rl.WHITE)
	}
}

render_wordle_guess_row :: proc(
	guess: WordleGuess,
	x: i32,
	y: i32,
	cell_size: i32,
	gap: i32,
	font_size: i32,
) {
	for col in 0 ..< WORDLE_WORD_LEN {
		tile_x := x + i32(col) * (cell_size + gap)
		render_wordle_tile(tile_x, y, cell_size, guess.letters[col], guess.feedback[col], font_size)
	}
}

render_wordle_current_row :: proc(
	wordle: WordleState,
	x: i32,
	y: i32,
	cell_size: i32,
	gap: i32,
	font_size: i32,
) {
	for col in 0 ..< WORDLE_WORD_LEN {
		tile_x := x + i32(col) * (cell_size + gap)
		render_wordle_tile(tile_x, y, cell_size, wordle.current_guess[col], .Empty, font_size)
	}
}

render_wordle_level :: proc(screen_width: i32, screen_height: i32, wordle: WordleState) {
	scale := screen_scale(screen_width, screen_height)
	font_size := scaled_i32(BASE_HUD_FONT_SIZE, scale)
	y := scaled_i32(BASE_WORDLE_LEVEL_Y, scale)
	level_label := fmt.caprintf("Level %d", wordle.level + 1)
	label_width := rl.MeasureText(level_label, font_size)
	rl.DrawText(level_label, (screen_width - label_width) / 2, y, font_size, rl.WHITE)
}

render_wordle_record_level :: proc(screen_width: i32, screen_height: i32, record: WordleLevelRecord) {
	scale := screen_scale(screen_width, screen_height)
	font_size := scaled_i32(BASE_HUD_FONT_SIZE, scale)
	y := scaled_i32(BASE_WORDLE_LEVEL_Y, scale)
	level_label := fmt.caprintf("Level %d", record.level + 1)
	label_width := rl.MeasureText(level_label, font_size)
	rl.DrawText(level_label, (screen_width - label_width) / 2, y, font_size, rl.WHITE)
}

render_wordle_win_solution :: proc(
	solution: [WORDLE_WORD_LEN]rune,
	x: i32,
	y: i32,
	cell_size: i32,
	gap: i32,
	font_size: i32,
) {
	for col in 0 ..< WORDLE_WORD_LEN {
		tile_x := x + i32(col) * (cell_size + gap)
		render_wordle_tile(tile_x, y, cell_size, solution[col], .Correct, font_size)
	}
}

render_wordle_reward_fragment :: proc(
	screen_width: i32,
	y: i32,
	cell_size: i32,
	letter: rune,
	font_size: i32,
) {
	x := (screen_width - cell_size) / 2
	rl.DrawRectangle(x, y, cell_size, cell_size, rl.SKYBLUE)

	if letter != 0 {
		label := fmt.caprintf("%c", letter)
		text_width := rl.MeasureText(label, font_size)
		text_x := x + (cell_size - text_width) / 2
		text_y := y + (cell_size - font_size) / 2
		rl.DrawText(label, text_x, text_y, font_size, rl.WHITE)
	}
}

render_wordle_win :: proc(screen_width: i32, screen_height: i32, wordle: WordleState) {
	scale := screen_scale(screen_width, screen_height)
	cell_size := scaled_i32(BASE_CELL_SIZE, scale)
	gap := scaled_i32(BASE_GAP, scale)
	font_size := scaled_i32(BASE_BOARD_FONT_SIZE, scale)
	start_y := scaled_i32(BASE_WORDLE_BOARD_Y, scale)
	board_width := WORDLE_WORD_LEN * cell_size + (WORDLE_WORD_LEN - 1) * gap
	start_x := (screen_width - board_width) / 2
	reward_y := (screen_height - cell_size) / 2

	render_wordle_level(screen_width, screen_height, wordle)
	render_wordle_win_solution(wordle.win_solution, start_x, start_y, cell_size, gap, font_size)
	render_wordle_reward_fragment(screen_width, reward_y, cell_size, wordle.reward_fragment, font_size)
}

render_wordle_guesses :: proc(
	screen_height: i32,
	guesses: [dynamic]WordleGuess,
	current_guess: [WORDLE_WORD_LEN]rune,
	show_current_row: bool,
	scroll_row: i32,
	start_x: i32,
	start_y: i32,
	cell_size: i32,
	gap: i32,
	font_size: i32,
) {
	row_step := cell_size + gap
	current_row_count: i32 = 0
	if show_current_row do current_row_count = 1
	visible_rows := (screen_height - start_y - row_step) / row_step
	if visible_rows < 1 do visible_rows = 1

	total_rows := i32(len(guesses)) + current_row_count
	max_scroll := total_rows - visible_rows
	if max_scroll < 0 do max_scroll = 0
	first_row := clamp(scroll_row, 0, max_scroll)
	last_row := first_row + visible_rows

	draw_row: i32 = 0
	for guess_index in first_row ..< min(i32(len(guesses)), last_row) {
		y := start_y + draw_row * row_step
		render_wordle_guess_row(guesses[guess_index], start_x, y, cell_size, gap, font_size)
		draw_row += 1
	}

	if show_current_row && i32(len(guesses)) >= first_row && i32(len(guesses)) < last_row {
		y := start_y + draw_row * row_step
		current_wordle := WordleState {
			current_guess = current_guess,
		}
		render_wordle_current_row(current_wordle, start_x, y, cell_size, gap, font_size)
	}
}

render_wordle_playing :: proc(screen_width: i32, screen_height: i32, wordle: WordleState) {
	scale := screen_scale(screen_width, screen_height)
	cell_size := scaled_i32(BASE_CELL_SIZE, scale)
	gap := scaled_i32(BASE_GAP, scale)
	font_size := scaled_i32(BASE_BOARD_FONT_SIZE, scale)
	start_y := scaled_i32(BASE_WORDLE_BOARD_Y, scale)
	board_width := WORDLE_WORD_LEN * cell_size + (WORDLE_WORD_LEN - 1) * gap
	start_x := (screen_width - board_width) / 2

	render_wordle_guesses(
		screen_height,
		wordle.guesses,
		wordle.current_guess,
		true,
		wordle.scroll_row,
		start_x,
		start_y,
		cell_size,
		gap,
		font_size,
	)
	render_wordle_level(screen_width, screen_height, wordle)
}

render_wordle_history :: proc(screen_width: i32, screen_height: i32, record: WordleLevelRecord, scroll_row: i32) {
	scale := screen_scale(screen_width, screen_height)
	cell_size := scaled_i32(BASE_CELL_SIZE, scale)
	gap := scaled_i32(BASE_GAP, scale)
	font_size := scaled_i32(BASE_BOARD_FONT_SIZE, scale)
	start_y := scaled_i32(BASE_WORDLE_BOARD_Y, scale)
	board_width := WORDLE_WORD_LEN * cell_size + (WORDLE_WORD_LEN - 1) * gap
	start_x := (screen_width - board_width) / 2
	reward_y := (screen_height - cell_size) / 2

	render_wordle_guesses(
		screen_height,
		record.guesses,
		[WORDLE_WORD_LEN]rune{},
		false,
		scroll_row,
		start_x,
		start_y,
		cell_size,
		gap,
		font_size,
	)
	render_wordle_record_level(screen_width, screen_height, record)
	render_wordle_reward_fragment(screen_width, reward_y, cell_size, record.reward_fragment, font_size)
}

render_wordle :: proc(screen_width: i32, screen_height: i32, wordle: WordleState) {
	if wordle.view_mode == .History {
		if wordle.history_index >= 0 && wordle.history_index < i32(len(wordle.history)) {
			render_wordle_history(screen_width, screen_height, wordle.history[wordle.history_index], wordle.scroll_row)
		}
		return
	}

	switch wordle.substate {
	case .Playing:
		render_wordle_playing(screen_width, screen_height, wordle)
	case .Won:
		render_wordle_win(screen_width, screen_height, wordle)
	}
}
