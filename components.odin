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
		scaled_i32(BASE_TITLE_FONT_SIZE, ctx.scale),
		color,
	)
}

build_mode_tabs :: proc(buffer: ^RenderBuffer, ctx: RenderContext, view: GameView) {
	font_size := scaled_i32(30, ctx.scale)
	title_gap := scaled_i32(BASE_TITLE_GAP, ctx.scale)
	padding_x := scaled_i32(BASE_TITLE_PADDING_X, ctx.scale)
	padding_y := scaled_i32(BASE_TITLE_PADDING_Y, ctx.scale)
	y := scaled_i32(BASE_TITLE_Y, ctx.scale)

	wordle_label: cstring = "WORDLE"
	cross_label: cstring = "CROSS"
	crafting_label: cstring = "CRAFTING"
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
	font_size := scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale)
	x := scaled_i32(24, ctx.scale)
	y := scaled_i32(24, ctx.scale)
	pulse := f32(0)
	if ui.exp_gain_age < 0.42 do pulse = math.sin(ui.exp_gain_age * 22) * (1 - ui.exp_gain_age / 0.42)
	badge_w := scaled_i32(132, ctx.scale) + i32(pulse * 5)
	badge_h := scaled_i32(38, ctx.scale) + i32(pulse * 3)
	push_rect(buffer, x, y, badge_w, badge_h, with_alpha(ctx.theme.surface, 236))
	push_rect_lines(buffer, x, y, badge_w, badge_h, 2, ctx.theme.outline)
	push_circle(
		buffer,
		f32(x + scaled_i32(20, ctx.scale)),
		f32(y + badge_h / 2),
		f32(scaled_i32(9, ctx.scale)),
		with_alpha(ctx.theme.exp, 220),
	)
	label := fmt.caprintf("EXP %d", exp)
	build_text(
		buffer,
		label,
		x + scaled_i32(36, ctx.scale),
		y + (badge_h - font_size) / 2,
		font_size,
		ctx.theme.exp,
	)
}

build_wordle_level :: proc(buffer: ^RenderBuffer, ctx: RenderContext, level: u32) {
	font_size := scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale)
	y := scaled_i32(BASE_WORDLE_LEVEL_Y, ctx.scale)
	label := fmt.caprintf("LEVEL %d", level + 1)
	build_centered_text(buffer, label, ctx.screen_width, y, font_size, ctx.theme.text)
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
	tile_size := scaled_i32(38, ctx.scale)
	tile_gap := scaled_i32(7, ctx.scale)
	base_height := grid_tile_base_height(tile_size)
	row_height := tile_size + base_height + tile_gap
	column_count := i32(2)
	column_rows := i32(13)
	hud_width := tile_size * column_count + tile_gap * (column_count - 1)
	hud_height := row_height * column_rows - tile_gap
	panel_pad_x := scaled_i32(10, ctx.scale)
	panel_pad_y := scaled_i32(6, ctx.scale)
	start_x := ctx.screen_width - hud_width - panel_pad_x - scaled_i32(46, ctx.scale)
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

	for i in 0 ..< LETTER_COUNT {
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
			FRAG_LETTERS[i],
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
