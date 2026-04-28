package main

import "core:fmt"
import rl "vendor:raylib"

draw_mode_tabs :: proc(buffer: ^RenderBuffer, ctx: RenderContext, view: GameView) {
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

	mode_x := start_x
	mode_width := wordle_width
	mode_label := wordle_label
	active := view == .Wordle
	text_color := rl.WHITE
	if active {
		text_color = rl.Color{20, 20, 24, 255}
		append(
			&buffer.commands,
			RenderCommand {
				kind = .Rect,
				rect = rl.Rectangle{
					f32(mode_x - padding_x),
					f32(y - padding_y),
					f32(mode_width + padding_x * 2),
					f32(font_size + padding_y * 2),
				},
				color = rl.WHITE,
			},
		)
	}
	append(
		&buffer.commands,
		RenderCommand {
			kind = .Text,
			text = mode_label,
			rect = rl.Rectangle{f32(mode_x), f32(y), 0, 0},
			font_size = font_size,
			color = text_color,
		},
	)

	mode_x = start_x + wordle_width + title_gap
	mode_width = cross_width
	mode_label = cross_label
	active = view == .Cross
	text_color = rl.WHITE
	if active {
		text_color = rl.Color{20, 20, 24, 255}
		append(
			&buffer.commands,
			RenderCommand {
				kind = .Rect,
				rect = rl.Rectangle{
					f32(mode_x - padding_x),
					f32(y - padding_y),
					f32(mode_width + padding_x * 2),
					f32(font_size + padding_y * 2),
				},
				color = rl.WHITE,
			},
		)
	}
	append(
		&buffer.commands,
		RenderCommand {
			kind = .Text,
			text = mode_label,
			rect = rl.Rectangle{f32(mode_x), f32(y), 0, 0},
			font_size = font_size,
			color = text_color,
		},
	)

	mode_x = start_x + wordle_width + title_gap + cross_width + title_gap
	mode_width = crafting_width
	mode_label = crafting_label
	active = view == .Crafting
	text_color = rl.WHITE
	if active {
		text_color = rl.Color{20, 20, 24, 255}
		append(
			&buffer.commands,
			RenderCommand {
				kind = .Rect,
				rect = rl.Rectangle{
					f32(mode_x - padding_x),
					f32(y - padding_y),
					f32(mode_width + padding_x * 2),
					f32(font_size + padding_y * 2),
				},
				color = rl.WHITE,
			},
		)
	}
	append(
		&buffer.commands,
		RenderCommand {
			kind = .Text,
			text = mode_label,
			rect = rl.Rectangle{f32(mode_x), f32(y), 0, 0},
			font_size = font_size,
			color = text_color,
		},
	)
}

draw_exp_hud :: proc(buffer: ^RenderBuffer, ctx: RenderContext, exp: u32) {
	font_size := scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale)
	x := scaled_i32(24, ctx.scale)
	y := scaled_i32(24, ctx.scale)
	label := fmt.caprintf("EXP %d", exp)
	append(
		&buffer.commands,
		RenderCommand {
			kind = .Text,
			text = label,
			rect = rl.Rectangle{f32(x), f32(y), 0, 0},
			font_size = font_size,
			color = rl.GOLD,
		},
	)
}

draw_wordle_level :: proc(buffer: ^RenderBuffer, ctx: RenderContext, level: u32) {
	font_size := scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale)
	y := scaled_i32(BASE_WORDLE_LEVEL_Y, ctx.scale)
	label := fmt.caprintf("Level %d", level + 1)
	label_width := rl.MeasureText(label, font_size)
	append(
		&buffer.commands,
		RenderCommand {
			kind = .Text,
			text = label,
			rect = rl.Rectangle{f32((ctx.screen_width - label_width) / 2), f32(y), 0, 0},
			font_size = font_size,
			color = rl.WHITE,
		},
	)
}

draw_inventory_counts :: proc(
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
		append(
			&buffer.commands,
			RenderCommand {
				kind = .Text,
				text = value,
				rect = rl.Rectangle{f32(x + value_offset), f32(y), 0, 0},
				font_size = font_size,
				color = color,
			},
		)
	}
}
