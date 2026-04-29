package main

import "core:fmt"
import "core:math"
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
	label_width := measure_text_width(label, font_size)
	label_x := x + (width - label_width) / 2
	label_y := y + (height - font_size) / 2
	build_text(buffer, label, label_x, label_y, font_size, color)
}

build_cozy_background :: proc(buffer: ^RenderBuffer, ctx: RenderContext) {
	push_rect(buffer, 0, 0, ctx.screen_width, ctx.screen_height, ctx.theme.background)
}

build_tile :: proc(
	buffer: ^RenderBuffer,
	x: i32,
	y: i32,
	size: i32,
	letter: rune,
	color: rl.Color,
	font_size: i32,
	theme: Theme,
) {
	build_tile_scaled(buffer, x, y, size, letter, color, font_size, theme, 1)
}

build_tile_with_face_lift :: proc(
	buffer: ^RenderBuffer,
	x: i32,
	y: i32,
	size: i32,
	letter: rune,
	color: rl.Color,
	font_size: i32,
	theme: Theme,
	face_lift: i32,
) {
	base_color := rl.Color {
		u8(f32(color[0]) * 0.72),
		u8(f32(color[1]) * 0.72),
		u8(f32(color[2]) * 0.72),
		color[3],
	}
	build_layered_tile_with_face_lift(
		buffer,
		x,
		y - grid_tile_base_height(size),
		size,
		letter,
		color,
		base_color,
		font_size,
		theme.text,
		theme.outline,
		face_lift,
	)
}

tile_click_lift :: proc(time: f32, lift: i32, phase: i32 = 0) -> i32 {
	if lift <= 0 do return 0
	adjusted_lift := lift / 2
	if adjusted_lift <= 0 do return 0
	step := i32(time / 0.5) + phase
	if step % 2 == 0 do return -adjusted_lift
	return 0
}

wordle_submit_click_lift :: proc(age: f32, lift: i32) -> i32 {
	if lift <= 0 do return 0
	adjusted_lift := lift / 2
	if adjusted_lift <= 0 do return 0
	if age < 0 do return -adjusted_lift
	if age < 0.24 {
		t := rl.EaseBackOut(age, 0, 1, 0.24)
		return -adjusted_lift + i32(f32(adjusted_lift) * 1.18 * t + 0.5)
	}
	if age < 0.46 {
		settle := saturate((age - 0.24) / 0.22)
		return i32(f32(adjusted_lift) * 0.18 * (1 - ease_out(settle)) + 0.5)
	}
	return 0
}

build_tile_scaled :: proc(
	buffer: ^RenderBuffer,
	x: i32,
	y: i32,
	size: i32,
	letter: rune,
	color: rl.Color,
	font_size: i32,
	theme: Theme,
	scale: f32,
) {
	draw_size := i32(f32(size) * scale + 0.5)
	if draw_size < 1 do draw_size = 1
	draw_x := x + (size - draw_size) / 2
	draw_y := y + (size - draw_size) / 2
	base_color := rl.Color {
		u8(f32(color[0]) * 0.72),
		u8(f32(color[1]) * 0.72),
		u8(f32(color[2]) * 0.72),
		color[3],
	}
	build_layered_tile(
		buffer,
		draw_x,
		draw_y - grid_tile_base_height(draw_size),
		draw_size,
		letter,
		color,
		base_color,
		font_size,
		theme.text,
		theme.outline,
	)
}

build_tile_or_square :: proc(
	buffer: ^RenderBuffer,
	x: i32,
	y: i32,
	size: i32,
	letter: rune,
	fill_color: rl.Color,
	empty_color: rl.Color,
	font_size: i32,
	theme: Theme,
) {
	if letter != 0 {
		build_tile(buffer, x, y, size, letter, fill_color, font_size, theme)
		return
	}

	push_rect(buffer, x, y, size, size, empty_color)
	push_rect_lines(buffer, x, y, size, size, 2, theme.outline)
}

TitleTile :: struct {
	x:          i32,
	y:          i32,
	face_size:  i32,
	face_lift:  i32,
	letter:     rune,
	face_color: rl.Color,
	base_color: rl.Color,
	font_size:  i32,
	text_color: rl.Color,
	outline:    rl.Color,
}

build_title_tile :: proc(buffer: ^RenderBuffer, tile: TitleTile) {
	base_height := tile.face_size / 10
	if base_height < 1 do base_height = 1
	base_overlap := -tile.face_lift + 1
	if base_overlap < 1 do base_overlap = 1
	face_y := tile.y + tile.face_lift

	push_rect(
		buffer,
		tile.x,
		tile.y + tile.face_size - base_overlap,
		tile.face_size,
		base_height + base_overlap,
		tile.base_color,
	)
	push_rect(buffer, tile.x, face_y, tile.face_size, tile.face_size, tile.face_color)
	outline_height := tile.y + tile.face_size + base_height - face_y
	push_rect_lines(buffer, tile.x, face_y, tile.face_size, outline_height, 2, tile.outline)

	if tile.letter != 0 {
		label := fmt.caprintf("%c", tile.letter)
		text_width := measure_text_width(label, tile.font_size)
		text_x := tile.x + (tile.face_size - text_width) / 2
		text_y := face_y + (tile.face_size - tile.font_size) / 2
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
	outline: rl.Color,
) {
	build_layered_tile_with_face_lift(
		buffer,
		x,
		y,
		size,
		letter,
		face_color,
		base_color,
		font_size,
		text_color,
		outline,
		0,
	)
}

build_layered_tile_with_corner_letter :: proc(
	buffer: ^RenderBuffer,
	x: i32,
	y: i32,
	size: i32,
	letter: rune,
	face_color: rl.Color,
	base_color: rl.Color,
	font_size: i32,
	text_color: rl.Color,
	outline: rl.Color,
) {
	build_layered_tile(
		buffer,
		x,
		y,
		size,
		0,
		face_color,
		base_color,
		font_size,
		text_color,
		outline,
	)

	if letter == 0 do return

	corner_font_size := font_size / 2 + 3
	if corner_font_size < 1 do corner_font_size = 1
	padding := size / 10
	if padding < 2 do padding = 2
	label := fmt.caprintf("%c", letter)
	text_width := measure_text_width(label, corner_font_size)
	text_x := x + size - padding - text_width
	text_y := y + size - padding - corner_font_size
	push_text(buffer, label, text_x, text_y, corner_font_size, text_color)
}

build_layered_tile_with_face_lift :: proc(
	buffer: ^RenderBuffer,
	x: i32,
	y: i32,
	size: i32,
	letter: rune,
	face_color: rl.Color,
	base_color: rl.Color,
	font_size: i32,
	text_color: rl.Color,
	outline: rl.Color,
	face_lift: i32,
) {
	build_title_tile(
		buffer,
		TitleTile {
			x = x,
			y = y,
			face_size = size,
			face_lift = face_lift,
			letter = letter,
			face_color = face_color,
			base_color = base_color,
			font_size = font_size,
			text_color = text_color,
			outline = outline,
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
	theme: Theme,
) {
	lift: i32 = 0
	if !active do lift = height / 12
	shadow_y := y + height / 9
	push_rect(buffer, x, shadow_y, width, height, with_alpha(theme.button_shadow, 116))

	fill := theme.surface
	if active {
		fill = theme.button_fill
	}
	push_rect(buffer, x, y - lift, width, height, fill)
	outline_y := y - lift
	outline_height := shadow_y + height - outline_y
	push_rect_lines(buffer, x, outline_y, width, outline_height, 2, theme.outline)

	text_color := theme.button_text
	if active do text_color = theme.button_text_inverted

	build_centered_text_in_rect(buffer, label, x, y - lift, width, height, font_size, text_color)
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
		scaled_i32(game_data.fonts.title, ctx.scale),
		color,
	)
}

build_mode_tabs :: proc(buffer: ^RenderBuffer, ctx: RenderContext, view: GameView) {
	font_size := scaled_i32(game_data.tabs.font_size, ctx.scale)
	title_gap := scaled_i32(game_data.title.gap, ctx.scale)
	padding_x := scaled_i32(game_data.title.padding_x, ctx.scale)
	padding_y := scaled_i32(game_data.title.padding_y, ctx.scale)
	y := scaled_i32(game_data.title.y, ctx.scale)

	wordle_label := game_data.tabs.wordle
	cross_label := game_data.tabs.cross
	crafting_label := game_data.tabs.crafting
	wordle_text_width := measure_text_width(wordle_label, font_size)
	cross_text_width := measure_text_width(cross_label, font_size)
	crafting_text_width := measure_text_width(crafting_label, font_size)
	title_text_width := crafting_text_width
	if wordle_text_width > title_text_width do title_text_width = wordle_text_width
	if cross_text_width > title_text_width do title_text_width = cross_text_width
	title_width := title_text_width + padding_x * 2
	total_width := title_width * 3 + title_gap * 2
	start_x := (ctx.screen_width - total_width) / 2

	title_h := font_size + padding_y * 2
	cross_x := start_x
	build_button(
		buffer,
		cross_label,
		cross_x,
		y - padding_y,
		title_width,
		title_h,
		font_size,
		view == .Cross,
		ctx.theme,
	)

	wordle_x := cross_x + title_width + title_gap
	build_button(
		buffer,
		wordle_label,
		wordle_x,
		y - padding_y,
		title_width,
		title_h,
		font_size,
		view == .Wordle,
		ctx.theme,
	)

	crafting_x := wordle_x + title_width + title_gap
	build_button(
		buffer,
		crafting_label,
		crafting_x,
		y - padding_y,
		title_width,
		title_h,
		font_size,
		view == .Crafting,
		ctx.theme,
	)
}

build_gameplay_fixed_ui :: proc(buffer: ^RenderBuffer, ctx: RenderContext, state: ^GameState) {
	build_mode_tabs(buffer, ctx, state.view)
	build_exp_hud(buffer, ctx, state.exp, state.ui)
	build_active_inventory_counts(buffer, ctx, state)
}

build_exp_hud :: proc(buffer: ^RenderBuffer, ctx: RenderContext, exp: u32, ui: UiState) {
	font_size := scaled_i32(game_data.fonts.hud, ctx.scale)
	x := scaled_i32(game_data.hud.exp_x, ctx.scale)
	y := scaled_i32(game_data.hud.exp_y, ctx.scale)
	pulse := f32(0)
	if ui.exp_gain_age < game_data.effects.exp_pulse_duration {
		pulse =
			math.sin(ui.exp_gain_age * game_data.effects.exp_pulse_frequency) *
			(1 - ui.exp_gain_age / game_data.effects.exp_pulse_duration)
	}
	badge_w := scaled_i32(game_data.hud.exp_badge_width, ctx.scale) + i32(pulse * 5)
	badge_h := scaled_i32(game_data.hud.exp_badge_height, ctx.scale) + i32(pulse * 3)
	push_rect(buffer, x, y, badge_w, badge_h, with_alpha(ctx.theme.surface, 236))
	push_rect_lines(buffer, x, y, badge_w, badge_h, 2, ctx.theme.outline)
	push_circle(
		buffer,
		f32(x + scaled_i32(game_data.hud.exp_icon_x, ctx.scale)),
		f32(y + badge_h / 2),
		f32(scaled_i32(9, ctx.scale)),
		with_alpha(ctx.theme.exp, 220),
	)
	label := fmt.caprintf("%s %d", game_data.hud.exp_label_prefix, exp)
	build_text(
		buffer,
		label,
		x + scaled_i32(game_data.hud.exp_text_x, ctx.scale),
		y + (badge_h - font_size) / 2,
		font_size,
		ctx.theme.exp,
	)
}

build_wordle_level :: proc(buffer: ^RenderBuffer, ctx: RenderContext, level: u32) {
	font_size := scaled_i32(game_data.fonts.hud, ctx.scale)
	y := scaled_i32(game_data.wordle.level_y, ctx.scale)
	label := fmt.caprintf("%s %d", game_data.wordle.level_label_prefix, level + 1)
	build_centered_text(buffer, label, ctx.screen_width, y, font_size, ctx.theme.text)
}

wordle_display_level :: proc(wordle: WordleState) -> u32 {
	if wordle.view_mode == .History &&
	   wordle.history_index >= 0 &&
	   wordle.history_index < i32(len(wordle.history)) {
		return wordle.history[wordle.history_index].level
	}
	return wordle.level
}

inventory_count_label :: proc(count: u32) -> cstring {
	if count > 99 do return "99+"
	return fmt.caprintf("%d", count)
}

build_inventory_count_tile :: proc(
	buffer: ^RenderBuffer,
	x: i32,
	y: i32,
	size: i32,
	letter: rune,
	count: u32,
	color: rl.Color,
	theme: Theme,
	scale: f32,
) {
	face_color := color
	text_color := theme.text
	if count == 0 {
		face_color = theme.empty_tile
		text_color = theme.text_muted
	}

	base_color := rl.Color {
		u8(f32(face_color[0]) * 0.72),
		u8(f32(face_color[1]) * 0.72),
		u8(f32(face_color[2]) * 0.72),
		face_color[3],
	}
	letter_font_size := scaled_i32(22, scale)
	count_font_size := scaled_i32(12, scale)
	build_title_tile(
		buffer,
		TitleTile {
			x = x,
			y = y,
			face_size = size,
			letter = letter,
			face_color = face_color,
			base_color = base_color,
			font_size = letter_font_size,
			text_color = text_color,
			outline = theme.outline,
		},
	)

	count_label := inventory_count_label(count)
	count_x := x + scaled_i32(4, scale)
	count_y := y + size - count_font_size - scaled_i32(3, scale)
	build_text(buffer, count_label, count_x, count_y, count_font_size, text_color)
}

build_inventory_counts :: proc(
	buffer: ^RenderBuffer,
	ctx: RenderContext,
	counts: [LETTER_COUNT]u32,
	color: rl.Color,
) {
	tile_size := scaled_i32(game_data.hud.inventory_tile, ctx.scale)
	tile_gap := scaled_i32(game_data.hud.inventory_gap, ctx.scale)
	base_height := grid_tile_base_height(tile_size)
	row_height := tile_size + base_height + tile_gap
	column_count := game_data.hud.inventory_columns
	column_rows := game_data.hud.inventory_rows
	hud_width := tile_size * column_count + tile_gap * (column_count - 1)
	hud_height := row_height * column_rows - tile_gap
	panel_pad_x := scaled_i32(game_data.hud.inventory_pad_x, ctx.scale)
	panel_pad_y := scaled_i32(game_data.hud.inventory_pad_y, ctx.scale)
	start_x :=
		ctx.screen_width -
		hud_width -
		panel_pad_x -
		scaled_i32(game_data.hud.inventory_right, ctx.scale)
	start_y := (ctx.screen_height - hud_height) / 2
	push_rect(
		buffer,
		start_x - panel_pad_x,
		start_y - panel_pad_y + scaled_i32(5, ctx.scale),
		hud_width + panel_pad_x * 2,
		hud_height + panel_pad_y * 2,
		with_alpha(ctx.theme.surface_shadow, 82),
	)
	push_rect(
		buffer,
		start_x - panel_pad_x,
		start_y - panel_pad_y,
		hud_width + panel_pad_x * 2,
		hud_height + panel_pad_y * 2,
		with_alpha(ctx.theme.surface, 226),
	)
	push_rect_lines(
		buffer,
		start_x - panel_pad_x,
		start_y - panel_pad_y,
		hud_width + panel_pad_x * 2,
		hud_height + panel_pad_y * 2,
		2,
		ctx.theme.outline,
	)

	for i in 0 ..< len(game_data.grid.alphabet) {
		index := i32(i)
		row := index % column_rows
		col := index / column_rows
		x := start_x + col * (tile_size + tile_gap)
		y := start_y + row * row_height
		build_inventory_count_tile(
			buffer,
			x,
			y,
			tile_size,
			game_data.grid.alphabet[i],
			counts[i],
			color,
			ctx.theme,
			ctx.scale,
		)
	}
}

build_active_inventory_counts :: proc(
	buffer: ^RenderBuffer,
	ctx: RenderContext,
	state: ^GameState,
) {
	inventory_counts := state.frag_counts
	inventory_color := ctx.theme.highlight_fragment
	if !state.show_frags {
		inventory_counts = state.rune_counts
		inventory_color = ctx.theme.highlight_rune
	}
	build_inventory_counts(buffer, ctx, inventory_counts, inventory_color)
}

build_crossword_coord_label :: proc(
	buffer: ^RenderBuffer,
	grid: Grid,
	row: i32,
	col: i32,
	theme: Theme,
) {
	x, y := grid_tile_position(grid, row, col)
	scale := f32(grid.cell_size) / f32(game_data.grid.cell_size)
	font_size := scaled_i32(10, scale)
	padding := scaled_i32(3, scale)
	label := fmt.caprintf("%d,%d", col, row)
	build_text(
		buffer,
		label,
		x + padding,
		y + padding,
		font_size,
		with_alpha(theme.text, 180),
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
	scale := f32(grid.cell_size) / f32(game_data.grid.cell_size)
	font_size := scaled_i32(game_data.fonts.board, scale)

	for i in 0 ..< len(grid.tiles) {
		tile := grid.tiles[i]
		if !grid_tile_visible(grid, tile.row, tile.col) do continue

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
			if !covered_by_selector {
				push_rect(buffer, x, y, grid.cell_size, grid.cell_size, theme.empty_tile)
				push_rect_lines(buffer, x, y, grid.cell_size, grid.cell_size, 2, theme.outline)
			}
		}
		build_crossword_coord_label(buffer, grid, tile.row, tile.col, theme)
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

	scale := f32(grid.cell_size) / f32(game_data.grid.cell_size)
	font_size := scaled_i32(game_data.fonts.selector, scale)
	selector_alpha: u8 = 100

	shake := ui_invalid_shake_x(ui, f32(grid.cell_size) * 0.12)
	preview_face := with_alpha(selector_color, selector_alpha)
	preview_base := with_alpha(selector_shadow, selector_alpha)
	preview_outline := theme.outline
	if selector_buffer.count == 0 && grid_tile_visible(grid, selector.row, selector.col) {
		x, y := grid_tile_position(grid, selector.row, selector.col)
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
		build_crossword_coord_label(buffer, grid, selector.row, selector.col, theme)
	}

	for i in 0 ..< selector_buffer.count {
		row, col := selector_letter_position(grid, selector, i)
		if !grid_tile_visible(grid, row, col) do continue

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
		build_crossword_coord_label(buffer, grid, row, col, theme)
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
	for col in 0 ..< game_data.wordle.word_length {
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
	for col in 0 ..< game_data.wordle.word_length {
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
	cell_size := scaled_i32(game_data.grid.cell_size, ctx.scale)
	gap := scaled_i32(game_data.grid.gap, ctx.scale)
	font_size := scaled_i32(game_data.fonts.board, ctx.scale)
	start_y := scaled_i32(game_data.wordle.board_y, ctx.scale)
	row_step := tile_row_step(cell_size, gap)
	visible_rows := wordle_visible_row_count(ctx.screen_height, start_y, row_step)
	board_width :=
		game_data.wordle.word_length * cell_size + (game_data.wordle.word_length - 1) * gap
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
	cell_size := scaled_i32(game_data.grid.cell_size, ctx.scale)
	gap := scaled_i32(game_data.grid.gap, ctx.scale)
	font_size := scaled_i32(game_data.fonts.board, ctx.scale)
	start_y := scaled_i32(game_data.wordle.board_y, ctx.scale)
	row_step := tile_row_step(cell_size, gap)
	visible_rows := wordle_visible_row_count(ctx.screen_height, start_y, row_step)
	board_width :=
		game_data.wordle.word_length * cell_size + (game_data.wordle.word_length - 1) * gap
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
	exp_font_size := scaled_i32(game_data.fonts.hud, ctx.scale)
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
	cell_size := scaled_i32(game_data.grid.cell_size, ctx.scale)
	gap := scaled_i32(game_data.grid.gap, ctx.scale)
	font_size := scaled_i32(game_data.fonts.board, ctx.scale)
	board_width :=
		game_data.wordle.word_length * cell_size + (game_data.wordle.word_length - 1) * gap
	start_x := (ctx.screen_width - board_width) / 2

	title_y := scaled_i32(165, ctx.scale)
	subtitle_y := title_y + scaled_i32(64, ctx.scale)
	start_y := subtitle_y + scaled_i32(44, ctx.scale)
	reward_label_y := start_y + cell_size + scaled_i32(56, ctx.scale)
	reward_y := reward_label_y + scaled_i32(34, ctx.scale)
	reward_detail_y := reward_y + cell_size + scaled_i32(14, ctx.scale)

	build_centered_text(
		buffer,
		game_data.wordle.win_title,
		ctx.screen_width,
		title_y,
		scaled_i32(game_data.fonts.title, ctx.scale),
		ctx.theme.text,
	)
	build_centered_text(
		buffer,
		game_data.wordle.win_subtitle,
		ctx.screen_width,
		subtitle_y,
		scaled_i32(game_data.fonts.hud, ctx.scale),
		ctx.theme.text_muted,
	)

	for col in 0 ..< game_data.wordle.word_length {
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
		game_data.wordle.rewards_label,
		ctx.screen_width,
		reward_label_y,
		scaled_i32(game_data.fonts.hud, ctx.scale),
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
		scaled_i32(game_data.fonts.hud, ctx.scale),
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

crafting_status_label :: proc(crafting: CraftingState) -> cstring {
	status_label := game_data.crafting.incomplete_label
	if crafting.count == game_data.crafting.matching_required {
		same := true
		letter := crafting.selected[0]
		for i in 1 ..< crafting.count {
			if crafting.selected[i] != letter {
				same = false
				break
			}
		}
		if same do status_label = game_data.crafting.matching_label
	}
	if crafting.count == game_data.crafting.random_required {
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
		if different do status_label = game_data.crafting.random_label
	}
	return status_label
}

build_crafting_mode_view :: proc(frame: ^RenderFrame, ctx: RenderContext, state: ^GameState) {
	build_centered_text(
		&frame.ui,
		game_data.crafting.fragment_label,
		ctx.screen_width,
		scaled_i32(170, ctx.scale),
		scaled_i32(game_data.fonts.hud, ctx.scale),
		ctx.theme.highlight_fragment,
	)

	cell_size := scaled_i32(game_data.grid.cell_size, ctx.scale)
	gap := scaled_i32(game_data.grid.gap, ctx.scale)
	font_size := scaled_i32(game_data.fonts.board, ctx.scale)
	board_width :=
		game_data.crafting.selection_capacity * cell_size +
		(game_data.crafting.selection_capacity - 1) * gap
	start_x := (ctx.screen_width - board_width) / 2
	selected_y := scaled_i32(game_data.crafting.board_y, ctx.scale)
	selection_shake := i32(ui_invalid_shake_x(state.ui, f32(cell_size) * 0.10))
	status_y := selected_y + cell_size + scaled_i32(22, ctx.scale)
	output_label_y := status_y + scaled_i32(50, ctx.scale)
	output_y := output_label_y + scaled_i32(34, ctx.scale)
	output_exp_y := output_y + cell_size + scaled_i32(14, ctx.scale)

	for i in 0 ..< game_data.crafting.selection_capacity {
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
		scaled_i32(game_data.fonts.hud, ctx.scale),
		ctx.theme.text_muted,
	)

	build_centered_text(
		&frame.ui,
		game_data.crafting.latest_rune_label,
		ctx.screen_width,
		output_label_y,
		scaled_i32(game_data.fonts.hud, ctx.scale),
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
		reward_detail := fmt.caprintf("+%d EXP", game_data.crafting.exp_reward)
		build_centered_text(
			&frame.ui,
			reward_detail,
			ctx.screen_width,
			output_exp_y,
			scaled_i32(game_data.fonts.hud, ctx.scale),
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
		hud_start_y :=
			state.screen_height - (scaled_i32(game_data.hud.row_height, ctx.scale) * 2) - 20
		reward_y :=
			grid_bottom +
			(hud_start_y - grid_bottom - scaled_i32(game_data.fonts.hud, ctx.scale)) / 2
		label := fmt.caprintf("+%d EXP", state.cross_reward_exp)
		build_centered_text(
			&frame.ui,
			label,
			state.screen_width,
			reward_y,
			scaled_i32(game_data.fonts.hud, ctx.scale),
			ctx.theme.exp,
		)
	}

	draw_ui_effects(&frame.overlay, ctx, state.ui)
}
