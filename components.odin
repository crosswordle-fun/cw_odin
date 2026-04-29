package main

import "core:fmt"
import rl "vendor:raylib"

build_text :: proc(
	buffer: ^RenderBuffer,
	label: cstring,
	x: i32,
	y: i32,
	font_size: i32,
	color: rl.Color,
) {
	push_text(buffer, label, x, y, font_size, color)
}

build_centered_text :: proc(
	buffer: ^RenderBuffer,
	label: cstring,
	screen_width: i32,
	y: i32,
	font_size: i32,
	color: rl.Color,
) {
	push_centered_text(buffer, label, screen_width, y, font_size, color)
}

build_centered_text_in_rect :: proc(
	buffer: ^RenderBuffer,
	label: cstring,
	x: i32,
	y: i32,
	width: i32,
	height: i32,
	font_size: i32,
	color: rl.Color,
) {
	label_width := rl.MeasureText(label, font_size)
	label_x := x + (width - label_width) / 2
	label_y := y + (height - font_size) / 2
	build_text(buffer, label, label_x, label_y, font_size, color)
}

build_tile :: proc(
	buffer: ^RenderBuffer,
	x: i32,
	y: i32,
	size: i32,
	letter: rune,
	color: rl.Color,
	font_size: i32,
) {
	push_letter_tile(buffer, x, y, size, letter, color, font_size)
}

TitleTile :: struct {
	x:          i32,
	y:          i32,
	face_size:  i32,
	letter:     rune,
	face_color: rl.Color,
	base_color: rl.Color,
	font_size:  i32,
	text_color: rl.Color,
}

build_title_tile :: proc(buffer: ^RenderBuffer, tile: TitleTile) {
	base_height := tile.face_size / 10
	if base_height < 1 do base_height = 1

	push_rect(
		buffer,
		tile.x,
		tile.y + tile.face_size,
		tile.face_size,
		base_height,
		tile.base_color,
	)
	push_rect(buffer, tile.x, tile.y, tile.face_size, tile.face_size, tile.face_color)

	if tile.letter != 0 {
		label := fmt.caprintf("%c", tile.letter)
		text_width := rl.MeasureText(label, tile.font_size)
		text_x := tile.x + (tile.face_size - text_width) / 2
		text_y := tile.y + (tile.face_size - tile.font_size) / 2
		push_text(buffer, label, text_x, text_y, tile.font_size, tile.text_color)
	}
}

build_layered_tile :: proc(
	buffer: ^RenderBuffer,
	x: i32,
	y: i32,
	size: i32,
	letter: rune,
	face_color: rl.Color,
	base_color: rl.Color,
	font_size: i32,
	text_color: rl.Color,
) {
	build_title_tile(
		buffer,
		TitleTile {
			x = x,
			y = y,
			face_size = size,
			letter = letter,
			face_color = face_color,
			base_color = base_color,
			font_size = font_size,
			text_color = text_color,
		},
	)
}

build_button :: proc(
	buffer: ^RenderBuffer,
	label: cstring,
	x: i32,
	y: i32,
	width: i32,
	height: i32,
	font_size: i32,
	active: bool,
) {
	if active {
		push_rect(buffer, x, y, width, height, rl.WHITE)
	}

	text_color := rl.WHITE
	if active {
		text_color = rl.Color{20, 20, 24, 255}
	}

	build_centered_text_in_rect(buffer, label, x, y, width, height, font_size, text_color)
}

build_title :: proc(
	buffer: ^RenderBuffer,
	ctx: RenderContext,
	label: cstring,
	y: i32,
	color: rl.Color,
) {
	build_centered_text(
		buffer,
		label,
		ctx.screen_width,
		y,
		scaled_i32(BASE_TITLE_FONT_SIZE, ctx.scale),
		color,
	)
}

build_mode_tabs :: proc(buffer: ^RenderBuffer, ctx: RenderContext, view: GameView) {
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

	wordle_x := start_x
	wordle_h := font_size + padding_y * 2
	build_button(
		buffer,
		wordle_label,
		wordle_x - padding_x,
		y - padding_y,
		wordle_width + padding_x * 2,
		wordle_h,
		font_size,
		view == .Wordle,
	)

	cross_x := start_x + wordle_width + title_gap
	build_button(
		buffer,
		cross_label,
		cross_x - padding_x,
		y - padding_y,
		cross_width + padding_x * 2,
		wordle_h,
		font_size,
		view == .Cross,
	)

	crafting_x := start_x + wordle_width + title_gap + cross_width + title_gap
	build_button(
		buffer,
		crafting_label,
		crafting_x - padding_x,
		y - padding_y,
		crafting_width + padding_x * 2,
		wordle_h,
		font_size,
		view == .Crafting,
	)
}

build_exp_hud :: proc(buffer: ^RenderBuffer, ctx: RenderContext, exp: u32) {
	font_size := scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale)
	x := scaled_i32(24, ctx.scale)
	y := scaled_i32(24, ctx.scale)
	label := fmt.caprintf("EXP %d", exp)
	build_text(buffer, label, x, y, font_size, rl.GOLD)
}

build_wordle_level :: proc(buffer: ^RenderBuffer, ctx: RenderContext, level: u32) {
	font_size := scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale)
	y := scaled_i32(BASE_WORDLE_LEVEL_Y, ctx.scale)
	label := fmt.caprintf("Level %d", level + 1)
	build_centered_text(buffer, label, ctx.screen_width, y, font_size, rl.WHITE)
}

build_inventory_counts :: proc(
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
		build_text(buffer, label, x, y, font_size, color)
		build_text(buffer, value, x + value_offset, y, font_size, color)
	}
}

build_crossword_grid :: proc(buffer: ^RenderBuffer, grid: Grid) {
	scale := f32(grid.cell_size) / f32(BASE_CELL_SIZE)
	font_size := scaled_i32(BASE_BOARD_FONT_SIZE, scale)
	rune_padding := scaled_i32(BASE_RUNE_PADDING, scale)

	for i in 0 ..< len(grid.tiles) {
		tile := grid.tiles[i]
		x, y := grid_tile_position(grid, tile.row, tile.col)
		base_height := grid_tile_base_height(grid.cell_size)

		if grid.frags[i] != 0 {
			build_layered_tile(
				buffer,
				x,
				y - base_height,
				grid.cell_size,
				grid.frags[i],
				rl.SKYBLUE,
				rl.DARKBLUE,
				font_size,
				rl.WHITE,
			)
		} else {
			push_rect(buffer, x, y, grid.cell_size, grid.cell_size, rl.DARKGRAY)
		}

		if grid.runes[i] != 0 {
			rune_size := grid.cell_size - rune_padding * 2
			build_layered_tile(
				buffer,
				x + rune_padding,
				y + rune_padding - base_height,
				rune_size,
				grid.runes[i],
				rl.PURPLE,
				rl.DARKPURPLE,
				font_size,
				rl.WHITE,
			)
		}
	}
}

build_crossword_selector_overlay :: proc(
	buffer: ^RenderBuffer,
	grid: Grid,
	selector: Selector,
	selector_buffer: SelectorBuffer,
	show_frags: bool,
) {
	line_color := rl.SKYBLUE
	if !show_frags do line_color = rl.PURPLE

	scale := f32(grid.cell_size) / f32(BASE_CELL_SIZE)
	font_size := scaled_i32(BASE_SELECTOR_FONT_SIZE, scale)
	label_offset := scaled_i32(BASE_SELECTOR_LABEL_OFFSET, scale)

	x, y := grid_tile_position(grid, selector.row, selector.col)
	push_rect_lines(
		buffer,
		x,
		y,
		grid.cell_size,
		grid.cell_size,
		f32(BASE_SELECTOR_OUTLINE) * f32(grid.cell_size) / f32(BASE_CELL_SIZE),
		line_color,
	)

	for i in 0 ..< selector_buffer.count {
		row, col := selector_letter_position(grid, selector, i)
		tile_x, tile_y := grid_tile_position(grid, row, col)
		push_rect_lines(buffer, tile_x, tile_y, grid.cell_size, grid.cell_size, 3, line_color)
		label := fmt.caprintf("%c", selector_buffer.letters[i])
		build_text(
			buffer,
			label,
			tile_x + grid.cell_size - font_size - label_offset,
			tile_y + grid.cell_size - font_size - label_offset,
			font_size,
			rl.WHITE,
		)
	}
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
	}
	return rl.DARKGRAY
}

build_wordle_guess_row :: proc(
	buffer: ^RenderBuffer,
	x: i32,
	y: i32,
	cell_size: i32,
	gap: i32,
	font_size: i32,
	guess: WordleGuess,
) {
	for col in 0 ..< WORDLE_WORD_LEN {
		tile_x := x + i32(col) * (cell_size + gap)
		build_tile(
			buffer,
			tile_x,
			y,
			cell_size,
			guess.letters[col],
			wordle_feedback_color(guess.feedback[col]),
			font_size,
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
) {
	for col in 0 ..< WORDLE_WORD_LEN {
		tile_x := x + i32(col) * (cell_size + gap)
		build_tile(buffer, tile_x, y, cell_size, current_guess[col], rl.DARKGRAY, font_size)
	}
}

build_wordle_play_board :: proc(buffer: ^RenderBuffer, ctx: RenderContext, wordle: WordleState) {
	cell_size := scaled_i32(BASE_CELL_SIZE, ctx.scale)
	gap := scaled_i32(BASE_GAP, ctx.scale)
	font_size := scaled_i32(BASE_BOARD_FONT_SIZE, ctx.scale)
	start_y := scaled_i32(BASE_WORDLE_BOARD_Y, ctx.scale)
	row_step := cell_size + gap
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
		build_wordle_guess_row(buffer, start_x, y, cell_size, gap, font_size, wordle.guesses[guess_index])
		draw_rows += 1
	}

	if i32(len(wordle.guesses)) >= scroll_row &&
	   i32(len(wordle.guesses)) < scroll_row + visible_rows {
		y := start_y + draw_rows * row_step
		build_wordle_current_row(buffer, start_x, y, cell_size, gap, font_size, wordle.current_guess)
	}
}

build_wordle_history_board :: proc(buffer: ^RenderBuffer, ctx: RenderContext, wordle: WordleState) {
	cell_size := scaled_i32(BASE_CELL_SIZE, ctx.scale)
	gap := scaled_i32(BASE_GAP, ctx.scale)
	font_size := scaled_i32(BASE_BOARD_FONT_SIZE, ctx.scale)
	start_y := scaled_i32(BASE_WORDLE_BOARD_Y, ctx.scale)
	row_step := cell_size + gap
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
		build_wordle_guess_row(buffer, start_x, y, cell_size, gap, font_size, record.guesses[guess_index])
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
	build_text(buffer, exp_label, exp_x, exp_y, scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale), rl.GOLD)
	build_tile(
		buffer,
		ctx.screen_width - history_reward_size - margin,
		ctx.screen_height - history_reward_size - margin,
		history_reward_size,
		record.reward_fragment,
		rl.SKYBLUE,
		history_reward_font_size,
	)
}

build_wordle_won_panel :: proc(buffer: ^RenderBuffer, ctx: RenderContext, wordle: WordleState) {
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
		"Congratulations!",
		ctx.screen_width,
		title_y,
		scaled_i32(BASE_TITLE_FONT_SIZE, ctx.scale),
		rl.WHITE,
	)
	build_centered_text(
		buffer,
		"Puzzle solved. Your reward is ready.",
		ctx.screen_width,
		subtitle_y,
		scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale),
		rl.LIGHTGRAY,
	)

	for col in 0 ..< WORDLE_WORD_LEN {
		tile_x := start_x + i32(col) * (cell_size + gap)
		build_tile(
			buffer,
			tile_x,
			start_y,
			cell_size,
			wordle.win_solution[col],
			rl.GREEN,
			font_size,
		)
	}

	build_centered_text(
		buffer,
		"Rewards",
		ctx.screen_width,
		reward_label_y,
		scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale),
		rl.SKYBLUE,
	)
	build_tile(
		buffer,
		(ctx.screen_width - cell_size) / 2,
		reward_y,
		cell_size,
		wordle.reward_fragment,
		rl.SKYBLUE,
		font_size,
	)
	reward_detail := fmt.caprintf("+%d EXP", wordle.reward_exp)
	build_centered_text(
		buffer,
		reward_detail,
		ctx.screen_width,
		reward_detail_y,
		scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale),
		rl.GOLD,
	)
}

build_wordle_mode_view :: proc(frame: ^RenderFrame, ctx: RenderContext, state: ^GameState) {
	build_mode_tabs(&frame.ui, ctx, state.view)
	build_exp_hud(&frame.ui, ctx, state.exp)
	build_wordle_level(&frame.ui, ctx, state.wordle.level)

	switch state.wordle.view_mode {
	case .History:
		build_wordle_history_board(&frame.world, ctx, state.wordle)

	case .Current:
		switch state.wordle.substate {
		case .Playing:
			build_wordle_play_board(&frame.world, ctx, state.wordle)
		case .Won:
			build_wordle_won_panel(&frame.world, ctx, state.wordle)
		}
	}
}

crafting_status_label :: proc(crafting: CraftingState) -> cstring {
	status_label: cstring = "Incomplete Recipe"
	if crafting.count == 4 {
		same := true
		letter := crafting.selected[0]
		for i in 1 ..< crafting.count {
			if crafting.selected[i] != letter {
				same = false
				break
			}
		}
		if same do status_label = "Matching Rune"
	}
	if crafting.count == 5 {
		different := true
		for i in 0 ..< crafting.count {
			for j in i + 1 ..< crafting.count {
				if crafting.selected[i] == crafting.selected[j] {
					different = false
					break
				}
			}
			if !different do break
		}
		if different do status_label = "Random Rune"
	}
	return status_label
}

build_crafting_mode_view :: proc(frame: ^RenderFrame, ctx: RenderContext, state: ^GameState) {
	build_mode_tabs(&frame.ui, ctx, state.view)
	build_exp_hud(&frame.ui, ctx, state.exp)
	build_title(&frame.ui, ctx, "Crafting", scaled_i32(105, ctx.scale), rl.WHITE)
	build_centered_text(
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
		build_tile(
			&frame.world,
			tile_x,
			selected_y,
			cell_size,
			state.crafting.selected[i],
			color,
			font_size,
		)
	}

	build_centered_text(
		&frame.ui,
		crafting_status_label(state.crafting),
		ctx.screen_width,
		status_y,
		scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale),
		rl.LIGHTGRAY,
	)

	build_centered_text(
		&frame.ui,
		"Latest Rune",
		ctx.screen_width,
		output_label_y,
		scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale),
		rl.PURPLE,
	)
	build_tile(
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
		build_centered_text(
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
	build_inventory_counts(&frame.ui, ctx, inventory_counts, inventory_color)
}

build_cross_mode_view :: proc(frame: ^RenderFrame, ctx: RenderContext, state: ^GameState) {
	build_mode_tabs(&frame.ui, ctx, state.view)
	build_exp_hud(&frame.ui, ctx, state.exp)
	build_crossword_grid(&frame.world, state.grid)
	build_crossword_selector_overlay(
		&frame.overlay,
		state.grid,
		state.selector,
		state.selector_buffer,
		state.show_frags,
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
			rl.GOLD,
		)
	}

	inventory_counts := state.frag_counts
	inventory_color := rl.SKYBLUE
	if !state.show_frags {
		inventory_counts = state.rune_counts
		inventory_color = rl.PURPLE
	}
	build_inventory_counts(&frame.ui, ctx, inventory_counts, inventory_color)
}
