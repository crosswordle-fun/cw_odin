package main

import "core:fmt"
import rl "vendor:raylib"

RENDER_BUFFER_CAPACITY :: 2048

RenderCommandKind :: enum {
	Rect,
	Rect_Lines,
	Text,
}

RenderCommand :: struct {
	kind:      RenderCommandKind,
	rect:      rl.Rectangle,
	color:     rl.Color,
	text:      cstring,
	font_size: i32,
	thickness: f32,
}

RenderBuffer :: struct {
	commands: [dynamic]RenderCommand,
}

RenderFrame :: struct {
	world:   RenderBuffer,
	ui:      RenderBuffer,
	overlay: RenderBuffer,
}

RenderContext :: struct {
	screen_width:  i32,
	screen_height: i32,
	scale:         f32,
}

render_buffer_new :: proc() -> RenderBuffer {
	return RenderBuffer{commands = make([dynamic]RenderCommand, 0, RENDER_BUFFER_CAPACITY)}
}

render_frame_new :: proc() -> RenderFrame {
	return RenderFrame {
		world = render_buffer_new(),
		ui = render_buffer_new(),
		overlay = render_buffer_new(),
	}
}

render_buffer_destroy :: proc(buffer: ^RenderBuffer) {
	delete(buffer.commands)
}

render_frame_destroy :: proc(frame: ^RenderFrame) {
	render_buffer_destroy(&frame.world)
	render_buffer_destroy(&frame.ui)
	render_buffer_destroy(&frame.overlay)
}

render_context_new :: proc(screen_width: i32, screen_height: i32) -> RenderContext {
	return RenderContext {
		screen_width = screen_width,
		screen_height = screen_height,
		scale = screen_scale(screen_width, screen_height),
	}
}

render_frame_clear :: proc(frame: ^RenderFrame) {
	clear(&frame.world.commands)
	clear(&frame.ui.commands)
	clear(&frame.overlay.commands)
}

render_buffer_push :: proc(buffer: ^RenderBuffer, command: RenderCommand) {
	append(&buffer.commands, command)
}

push_rect :: proc(
	buffer: ^RenderBuffer,
	x: i32,
	y: i32,
	width: i32,
	height: i32,
	color: rl.Color,
) {
	append(
		&buffer.commands,
		RenderCommand {
			kind = .Rect,
			rect = rl.Rectangle{f32(x), f32(y), f32(width), f32(height)},
			color = color,
		},
	)
}

push_rect_lines :: proc(
	buffer: ^RenderBuffer,
	x: i32,
	y: i32,
	width: i32,
	height: i32,
	thickness: f32,
	color: rl.Color,
) {
	append(
		&buffer.commands,
		RenderCommand {
			kind = .Rect_Lines,
			rect = rl.Rectangle{f32(x), f32(y), f32(width), f32(height)},
			color = color,
			thickness = thickness,
		},
	)
}

push_text :: proc(
	buffer: ^RenderBuffer,
	label: cstring,
	x: i32,
	y: i32,
	font_size: i32,
	color: rl.Color,
) {
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
}

push_centered_text :: proc(
	buffer: ^RenderBuffer,
	label: cstring,
	screen_width: i32,
	y: i32,
	font_size: i32,
	color: rl.Color,
) {
	label_width := rl.MeasureText(label, font_size)
	append(
		&buffer.commands,
		RenderCommand {
			kind = .Text,
			text = label,
			rect = rl.Rectangle{f32((screen_width - label_width) / 2), f32(y), 0, 0},
			font_size = font_size,
			color = color,
		},
	)
}

push_letter_tile :: proc(
	buffer: ^RenderBuffer,
	x: i32,
	y: i32,
	size: i32,
	letter: rune,
	color: rl.Color,
	font_size: i32,
) {
	append(
		&buffer.commands,
		RenderCommand {
			kind = .Rect,
			rect = rl.Rectangle{f32(x), f32(y), f32(size), f32(size)},
			color = color,
		},
	)

	if letter != 0 {
		label := fmt.caprintf("%c", letter)
		text_width := rl.MeasureText(label, font_size)
		text_x := x + (size - text_width) / 2
		text_y := y + (size - font_size) / 2
		append(
			&buffer.commands,
			RenderCommand {
				kind = .Text,
				text = label,
				rect = rl.Rectangle{f32(text_x), f32(text_y), 0, 0},
				font_size = font_size,
				color = rl.WHITE,
			},
		)
	}
}

flush_render_buffer :: proc(buffer: RenderBuffer) {
	for i in 0 ..< len(buffer.commands) {
		command := buffer.commands[i]
		switch command.kind {
		case .Rect:
			rl.DrawRectangle(
				i32(command.rect.x),
				i32(command.rect.y),
				i32(command.rect.width),
				i32(command.rect.height),
				command.color,
			)
		case .Rect_Lines:
			rl.DrawRectangleLinesEx(command.rect, command.thickness, command.color)
		case .Text:
			rl.DrawText(
				command.text,
				i32(command.rect.x),
				i32(command.rect.y),
				command.font_size,
				command.color,
			)
		}
	}
}

flush_render_frame :: proc(frame: RenderFrame) {
	flush_render_buffer(frame.world)
	flush_render_buffer(frame.ui)
	flush_render_buffer(frame.overlay)
}

build_title_word :: proc(
	buffer: ^RenderBuffer,
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
		push_rect(
			buffer,
			x - padding_x,
			y - padding_y,
			text_width + padding_x * 2,
			font_size + padding_y * 2,
			rl.WHITE,
		)
		text_color = rl.Color{20, 20, 24, 255}
	}

	push_text(buffer, label, x, y, font_size, text_color)
}

build_title :: proc(buffer: ^RenderBuffer, ctx: RenderContext, view: GameView) {
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

	build_title_word(
		buffer,
		wordle_label,
		start_x,
		y,
		font_size,
		padding_x,
		padding_y,
		view == .Wordle,
	)
	build_title_word(
		buffer,
		cross_label,
		start_x + wordle_width + title_gap,
		y,
		font_size,
		padding_x,
		padding_y,
		view == .Cross,
	)
	build_title_word(
		buffer,
		crafting_label,
		start_x + wordle_width + title_gap + cross_width + title_gap,
		y,
		font_size,
		padding_x,
		padding_y,
		view == .Crafting,
	)
}

build_exp_hud :: proc(buffer: ^RenderBuffer, ctx: RenderContext, exp: u32) {
	font_size := scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale)
	x := scaled_i32(24, ctx.scale)
	y := scaled_i32(24, ctx.scale)
	label := fmt.caprintf("EXP %d", exp)
	push_text(buffer, label, x, y, font_size, rl.GOLD)
}

build_global_hud :: proc(frame: ^RenderFrame, ctx: RenderContext, state: GameState) {
	build_title(&frame.ui, ctx, state.view)
	build_exp_hud(&frame.ui, ctx, state.exp)
}

build_grid :: proc(buffer: ^RenderBuffer, grid: Grid) {
	scale := f32(grid.cell_size) / f32(BASE_CELL_SIZE)
	font_size := scaled_i32(BASE_BOARD_FONT_SIZE, scale)
	rune_padding := scaled_i32(BASE_RUNE_PADDING, scale)

	for i in 0 ..< len(grid.tiles) {
		tile := grid.tiles[i]
		x, y := grid_tile_position(grid, tile.row, tile.col)

		if grid.frags[i] != 0 {
			push_letter_tile(buffer, x, y, grid.cell_size, grid.frags[i], rl.SKYBLUE, font_size)
		} else {
			push_rect(buffer, x, y, grid.cell_size, grid.cell_size, rl.DARKGRAY)
		}

		if grid.runes[i] != 0 {
			rune_size := grid.cell_size - rune_padding * 2
			rune_x := x + rune_padding
			rune_y := y + rune_padding
			push_letter_tile(
				buffer,
				rune_x,
				rune_y,
				rune_size,
				grid.runes[i],
				rl.PURPLE,
				font_size,
			)
		}
	}
}

build_selector :: proc(
	buffer: ^RenderBuffer,
	grid: Grid,
	selector: Selector,
	selector_buffer: SelectorBuffer,
	show_frags: bool,
) {
	line_color := rl.SKYBLUE
	if !show_frags do line_color = rl.PURPLE

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
		x, y = grid_tile_position(grid, row, col)
		push_rect_lines(buffer, x, y, grid.cell_size, grid.cell_size, 3, line_color)
	}
}

build_selector_letters :: proc(
	buffer: ^RenderBuffer,
	grid: Grid,
	selector: Selector,
	selector_buffer: SelectorBuffer,
) {
	if selector_buffer.count == 0 do return

	scale := f32(grid.cell_size) / f32(BASE_CELL_SIZE)
	font_size := scaled_i32(BASE_SELECTOR_FONT_SIZE, scale)
	label_offset := scaled_i32(BASE_SELECTOR_LABEL_OFFSET, scale)

	for i in 0 ..< selector_buffer.count {
		row, col := selector_letter_position(grid, selector, i)
		x, y := grid_tile_position(grid, row, col)
		label := fmt.caprintf("%c", selector_buffer.letters[i])
		push_text(
			buffer,
			label,
			x + grid.cell_size - font_size - label_offset,
			y + grid.cell_size - font_size - label_offset,
			font_size,
			rl.WHITE,
		)
	}
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

		push_text(buffer, label, x, y, font_size, color)
		push_text(buffer, value, x + value_offset, y, font_size, color)
	}
}

build_inventory :: proc(
	buffer: ^RenderBuffer,
	ctx: RenderContext,
	frag_counts: Frags,
	rune_counts: Runes,
	show_frags: bool,
) {
	if show_frags do build_inventory_counts(buffer, ctx, frag_counts, rl.SKYBLUE)
	else do build_inventory_counts(buffer, ctx, rune_counts, rl.PURPLE)
}

build_cross_exp_reward :: proc(buffer: ^RenderBuffer, grid: Grid, reward_exp: u32) {
	if reward_exp == 0 do return

	scale := screen_scale(grid.screen_width, grid.screen_height)
	font_size := scaled_i32(BASE_HUD_FONT_SIZE, scale)
	item_width := scaled_i32(BASE_HUD_ITEM_WIDTH, scale)
	row_height := scaled_i32(BASE_HUD_ROW_HEIGHT, scale)
	hud_width := item_width * 13 - 10
	hud_start_y := grid.screen_height - (row_height * 2) - 20
	grid_bottom := grid.offset_y + grid_pixel_height(grid)
	y := grid_bottom + (hud_start_y - grid_bottom - font_size) / 2

	label := fmt.caprintf("+%d EXP", reward_exp)
	push_centered_text(buffer, label, grid.screen_width, y, font_size, rl.GOLD)
}

build_cross_board_scene :: proc(frame: ^RenderFrame, ctx: RenderContext, state: GameState) {
	build_grid(&frame.world, state.grid)
	build_selector(
		&frame.overlay,
		state.grid,
		state.selector,
		state.selector_buffer,
		state.show_frags,
	)
	build_selector_letters(&frame.overlay, state.grid, state.selector, state.selector_buffer)
	build_cross_exp_reward(&frame.ui, state.grid, state.cross_reward_exp)
	build_inventory(&frame.ui, ctx, state.frag_counts, state.rune_counts, state.show_frags)
}

build_crafting_selected :: proc(
	buffer: ^RenderBuffer,
	crafting: CraftingState,
	x: i32,
	y: i32,
	cell_size: i32,
	gap: i32,
	font_size: i32,
) {
	for i in 0 ..< len(crafting.selected) {
		tile_x := x + i32(i) * (cell_size + gap)
		color := rl.DARKGRAY
		if i32(i) < crafting.count do color = rl.SKYBLUE
		push_letter_tile(buffer, tile_x, y, cell_size, crafting.selected[i], color, font_size)
	}
}

build_crafting_recipe_status :: proc(
	buffer: ^RenderBuffer,
	ctx: RenderContext,
	y: i32,
	font_size: i32,
	crafting: CraftingState,
) {
	label: cstring = "Incomplete Recipe"
	if crafting.count == 4 && crafting_selection_all_same(crafting) {
		label = "Matching Rune"
	} else if crafting.count == 5 && crafting_selection_all_different(crafting) {
		label = "Random Rune"
	}
	push_centered_text(buffer, label, ctx.screen_width, y, font_size, rl.LIGHTGRAY)
}

build_crafting_scene :: proc(frame: ^RenderFrame, ctx: RenderContext, state: GameState) {
	cell_size := scaled_i32(BASE_CELL_SIZE, ctx.scale)
	gap := scaled_i32(BASE_GAP, ctx.scale)
	font_size := scaled_i32(BASE_BOARD_FONT_SIZE, ctx.scale)
	hud_font_size := scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale)
	title_y := scaled_i32(105, ctx.scale)
	selected_label_y := scaled_i32(170, ctx.scale)
	selected_y := selected_label_y + scaled_i32(34, ctx.scale)
	status_y := selected_y + cell_size + scaled_i32(22, ctx.scale)
	output_label_y := status_y + scaled_i32(50, ctx.scale)
	output_y := output_label_y + scaled_i32(34, ctx.scale)
	output_exp_y := output_y + cell_size + scaled_i32(14, ctx.scale)
	board_width := 5 * cell_size + 4 * gap
	start_x := (ctx.screen_width - board_width) / 2

	push_centered_text(
		&frame.ui,
		"Crafting",
		ctx.screen_width,
		title_y,
		scaled_i32(BASE_TITLE_FONT_SIZE, ctx.scale),
		rl.WHITE,
	)
	push_centered_text(
		&frame.ui,
		"Fragments",
		ctx.screen_width,
		selected_label_y,
		hud_font_size,
		rl.SKYBLUE,
	)
	build_crafting_selected(
		&frame.world,
		state.crafting,
		start_x,
		selected_y,
		cell_size,
		gap,
		font_size,
	)
	build_crafting_recipe_status(&frame.ui, ctx, status_y, hud_font_size, state.crafting)
	push_centered_text(
		&frame.ui,
		"Latest Rune",
		ctx.screen_width,
		output_label_y,
		hud_font_size,
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
			hud_font_size,
			rl.GOLD,
		)
	}
	build_inventory(&frame.ui, ctx, state.frag_counts, state.rune_counts, state.show_frags)
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

build_wordle_tile :: proc(
	buffer: ^RenderBuffer,
	x: i32,
	y: i32,
	size: i32,
	letter: rune,
	feedback: WordleFeedback,
	font_size: i32,
) {
	push_letter_tile(buffer, x, y, size, letter, wordle_feedback_color(feedback), font_size)
}

build_wordle_guess_row :: proc(
	buffer: ^RenderBuffer,
	guess: WordleGuess,
	x: i32,
	y: i32,
	cell_size: i32,
	gap: i32,
	font_size: i32,
) {
	for col in 0 ..< WORDLE_WORD_LEN {
		tile_x := x + i32(col) * (cell_size + gap)
		build_wordle_tile(
			buffer,
			tile_x,
			y,
			cell_size,
			guess.letters[col],
			guess.feedback[col],
			font_size,
		)
	}
}

build_wordle_current_row :: proc(
	buffer: ^RenderBuffer,
	current_guess: [WORDLE_WORD_LEN]rune,
	x: i32,
	y: i32,
	cell_size: i32,
	gap: i32,
	font_size: i32,
) {
	for col in 0 ..< WORDLE_WORD_LEN {
		tile_x := x + i32(col) * (cell_size + gap)
		build_wordle_tile(buffer, tile_x, y, cell_size, current_guess[col], .Empty, font_size)
	}
}

build_wordle_level :: proc(buffer: ^RenderBuffer, ctx: RenderContext, level: u32) {
	font_size := scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale)
	y := scaled_i32(BASE_WORDLE_LEVEL_Y, ctx.scale)
	level_label := fmt.caprintf("Level %d", level + 1)
	push_centered_text(buffer, level_label, ctx.screen_width, y, font_size, rl.WHITE)
}

build_wordle_guesses :: proc(
	buffer: ^RenderBuffer,
	ctx: RenderContext,
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
	visible_rows := (ctx.screen_height - start_y - row_step) / row_step
	if visible_rows < 1 do visible_rows = 1

	total_rows := i32(len(guesses)) + current_row_count
	max_scroll := total_rows - visible_rows
	if max_scroll < 0 do max_scroll = 0
	first_row := clamp(scroll_row, 0, max_scroll)
	last_row := first_row + visible_rows

	draw_row: i32 = 0
	for guess_index in first_row ..< min(i32(len(guesses)), last_row) {
		y := start_y + draw_row * row_step
		build_wordle_guess_row(buffer, guesses[guess_index], start_x, y, cell_size, gap, font_size)
		draw_row += 1
	}

	if show_current_row && i32(len(guesses)) >= first_row && i32(len(guesses)) < last_row {
		y := start_y + draw_row * row_step
		build_wordle_current_row(buffer, current_guess, start_x, y, cell_size, gap, font_size)
	}
}

build_wordle_playing :: proc(frame: ^RenderFrame, ctx: RenderContext, wordle: WordleState) {
	cell_size := scaled_i32(BASE_CELL_SIZE, ctx.scale)
	gap := scaled_i32(BASE_GAP, ctx.scale)
	font_size := scaled_i32(BASE_BOARD_FONT_SIZE, ctx.scale)
	start_y := scaled_i32(BASE_WORDLE_BOARD_Y, ctx.scale)
	board_width := WORDLE_WORD_LEN * cell_size + (WORDLE_WORD_LEN - 1) * gap
	start_x := (ctx.screen_width - board_width) / 2

	build_wordle_guesses(
		&frame.world,
		ctx,
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
	build_wordle_level(&frame.ui, ctx, wordle.level)
}

build_wordle_win_solution :: proc(
	buffer: ^RenderBuffer,
	solution: [WORDLE_WORD_LEN]rune,
	x: i32,
	y: i32,
	cell_size: i32,
	gap: i32,
	font_size: i32,
) {
	for col in 0 ..< WORDLE_WORD_LEN {
		tile_x := x + i32(col) * (cell_size + gap)
		build_wordle_tile(buffer, tile_x, y, cell_size, solution[col], .Correct, font_size)
	}
}

build_wordle_win :: proc(frame: ^RenderFrame, ctx: RenderContext, wordle: WordleState) {
	cell_size := scaled_i32(BASE_CELL_SIZE, ctx.scale)
	gap := scaled_i32(BASE_GAP, ctx.scale)
	font_size := scaled_i32(BASE_BOARD_FONT_SIZE, ctx.scale)
	title_font_size := scaled_i32(BASE_TITLE_FONT_SIZE, ctx.scale)
	subtitle_font_size := scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale)
	title_y := scaled_i32(165, ctx.scale)
	subtitle_y := title_y + scaled_i32(64, ctx.scale)
	start_y := subtitle_y + scaled_i32(44, ctx.scale)
	board_width := WORDLE_WORD_LEN * cell_size + (WORDLE_WORD_LEN - 1) * gap
	start_x := (ctx.screen_width - board_width) / 2
	reward_label_y := start_y + cell_size + scaled_i32(56, ctx.scale)
	reward_y := reward_label_y + scaled_i32(34, ctx.scale)
	reward_detail_y := reward_y + cell_size + scaled_i32(14, ctx.scale)

	build_wordle_level(&frame.ui, ctx, wordle.level)
	push_centered_text(
		&frame.ui,
		"Congratulations!",
		ctx.screen_width,
		title_y,
		title_font_size,
		rl.WHITE,
	)
	push_centered_text(
		&frame.ui,
		"Puzzle solved. Your reward is ready.",
		ctx.screen_width,
		subtitle_y,
		subtitle_font_size,
		rl.LIGHTGRAY,
	)
	build_wordle_win_solution(
		&frame.world,
		wordle.win_solution,
		start_x,
		start_y,
		cell_size,
		gap,
		font_size,
	)
	push_centered_text(
		&frame.ui,
		"Rewards",
		ctx.screen_width,
		reward_label_y,
		subtitle_font_size,
		rl.SKYBLUE,
	)
	push_letter_tile(
		&frame.world,
		(ctx.screen_width - cell_size) / 2,
		reward_y,
		cell_size,
		wordle.reward_fragment,
		rl.SKYBLUE,
		font_size,
	)
	reward_detail := fmt.caprintf("+%d EXP", wordle.reward_exp)
	push_centered_text(
		&frame.ui,
		reward_detail,
		ctx.screen_width,
		reward_detail_y,
		subtitle_font_size,
		rl.GOLD,
	)
}

build_wordle_history :: proc(
	frame: ^RenderFrame,
	ctx: RenderContext,
	record: WordleLevelRecord,
	scroll_row: i32,
) {
	cell_size := scaled_i32(BASE_CELL_SIZE, ctx.scale)
	gap := scaled_i32(BASE_GAP, ctx.scale)
	font_size := scaled_i32(BASE_BOARD_FONT_SIZE, ctx.scale)
	start_y := scaled_i32(BASE_WORDLE_BOARD_Y, ctx.scale)
	board_width := WORDLE_WORD_LEN * cell_size + (WORDLE_WORD_LEN - 1) * gap
	start_x := (ctx.screen_width - board_width) / 2

	build_wordle_guesses(
		&frame.world,
		ctx,
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
	build_wordle_level(&frame.ui, ctx, record.level)

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

build_wordle_scene :: proc(frame: ^RenderFrame, ctx: RenderContext, wordle: WordleState) {
	switch wordle.view_mode {
	case .History:
		if wordle.history_index >= 0 && wordle.history_index < i32(len(wordle.history)) {
			build_wordle_history(
				frame,
				ctx,
				wordle.history[wordle.history_index],
				wordle.scroll_row,
			)
		}
		return
	case .Current:
		switch wordle.substate {
		case .Playing:
			build_wordle_playing(frame, ctx, wordle)
		case .Won:
			build_wordle_win(frame, ctx, wordle)
		}
	}
}

