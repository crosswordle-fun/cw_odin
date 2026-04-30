package main

import "core:fmt"
import rl "vendor:raylib"

TEXT_SPACING :: f32(1)

game_font: rl.Font
game_custom_font: rl.Font
game_font_uses_custom: bool

RenderCommandKind :: enum {
	Rect,
	Rect_Rotated,
	Rect_Lines,
	Rect_Gradient_V,
	Circle,
	Circle_Gradient,
	Line,
	Poly,
	Text,
	Text_Rotated,
}

RenderCommand :: struct {
	kind:      RenderCommandKind,
	rect:      rl.Rectangle,
	color:     rl.Color,
	color2:    rl.Color,
	text:      cstring,
	point:     rl.Vector2,
	point2:    rl.Vector2,
	radius:    f32,
	rotation:  f32,
	font_size: i32,
	thickness: f32,
	sides:     i32,
	additive:  bool,
}

RenderBuffer :: struct {
	commands:         [dynamic]RenderCommand,
	background_count: int,
}

RenderFrame :: struct {
	world:    RenderBuffer,
	ui:       RenderBuffer,
	fixed_ui: RenderBuffer,
	overlay:  RenderBuffer,
}

RenderContext :: struct {
	screen_width:  i32,
	screen_height: i32,
	scale:         f32,
	theme:         Theme,
	time:          f32,
	dt:            f32,
}

render_buffer_new :: proc() -> RenderBuffer {
	return RenderBuffer {
		commands = make([dynamic]RenderCommand, 0, game_data.screen.render_buffer_capacity),
	}
}

render_frame_new :: proc() -> RenderFrame {
	return RenderFrame {
		world = render_buffer_new(),
		ui = render_buffer_new(),
		fixed_ui = render_buffer_new(),
		overlay = render_buffer_new(),
	}
}

render_buffer_destroy :: proc(buffer: ^RenderBuffer) {
	delete(buffer.commands)
}

render_frame_destroy :: proc(frame: ^RenderFrame) {
	render_buffer_destroy(&frame.world)
	render_buffer_destroy(&frame.ui)
	render_buffer_destroy(&frame.fixed_ui)
	render_buffer_destroy(&frame.overlay)
}

render_context_new :: proc(
	screen_width: i32,
	screen_height: i32,
	theme: Theme,
	time: f32,
	dt: f32,
) -> RenderContext {
	return RenderContext {
		screen_width = screen_width,
		screen_height = screen_height,
		scale = screen_scale(screen_width, screen_height),
		theme = theme,
		time = time,
		dt = dt,
	}
}

game_font_use_default :: proc() {
	game_font = rl.GetFontDefault()
	game_font_uses_custom = false
}

game_font_load :: proc() {
	if rl.IsFontValid(game_custom_font) {
		rl.UnloadFont(game_custom_font)
	}

	game_custom_font = rl.LoadFont(game_data.screen.font_path)
	if !rl.IsFontValid(game_custom_font) {
		fmt.eprintf("font: failed to load %s, keeping default font\n", game_data.screen.font_path)
		game_custom_font = {}
		game_font_use_default()
		return
	}

	if game_font_uses_custom {
		game_font = game_custom_font
	}
}

game_font_use_custom :: proc() {
	if !rl.IsFontValid(game_custom_font) {
		game_font_load()
	}
	if rl.IsFontValid(game_custom_font) {
		game_font = game_custom_font
		game_font_uses_custom = true
		return
	}
	game_font_use_default()
}

game_font_toggle :: proc() {
	if game_font_uses_custom {
		game_font_use_default()
	} else {
		game_font_use_custom()
	}
}

game_font_unload :: proc() {
	if rl.IsFontValid(game_custom_font) {
		rl.UnloadFont(game_custom_font)
	}
	game_custom_font = {}
	game_font_use_default()
}

measure_text_width :: proc(label: cstring, font_size: i32) -> i32 {
	size := rl.MeasureTextEx(game_font, label, f32(font_size), TEXT_SPACING)
	return i32(size.x + 0.5)
}

render_frame_clear :: proc(frame: ^RenderFrame) {
	clear(&frame.world.commands)
	frame.world.background_count = 0
	clear(&frame.ui.commands)
	frame.ui.background_count = 0
	clear(&frame.fixed_ui.commands)
	frame.fixed_ui.background_count = 0
	clear(&frame.overlay.commands)
	frame.overlay.background_count = 0
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

push_rotated_rect :: proc(
	buffer: ^RenderBuffer,
	center_x: f32,
	center_y: f32,
	width: i32,
	height: i32,
	rotation: f32,
	color: rl.Color,
) {
	append(
		&buffer.commands,
		RenderCommand {
			kind = .Rect_Rotated,
			rect = rl.Rectangle{center_x, center_y, f32(width), f32(height)},
			rotation = rotation,
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

push_rect_gradient_v :: proc(
	buffer: ^RenderBuffer,
	x: i32,
	y: i32,
	width: i32,
	height: i32,
	top: rl.Color,
	bottom: rl.Color,
) {
	append(
		&buffer.commands,
		RenderCommand {
			kind = .Rect_Gradient_V,
			rect = rl.Rectangle{f32(x), f32(y), f32(width), f32(height)},
			color = top,
			color2 = bottom,
		},
	)
}

push_circle :: proc(
	buffer: ^RenderBuffer,
	x: f32,
	y: f32,
	radius: f32,
	color: rl.Color,
	additive := false,
) {
	append(
		&buffer.commands,
		RenderCommand {
			kind = .Circle,
			point = rl.Vector2{x, y},
			radius = radius,
			color = color,
			additive = additive,
		},
	)
}

push_circle_gradient :: proc(
	buffer: ^RenderBuffer,
	x: f32,
	y: f32,
	radius: f32,
	inner: rl.Color,
	outer: rl.Color,
	additive := false,
) {
	append(
		&buffer.commands,
		RenderCommand {
			kind = .Circle_Gradient,
			point = rl.Vector2{x, y},
			radius = radius,
			color = inner,
			color2 = outer,
			additive = additive,
		},
	)
}

push_line :: proc(
	buffer: ^RenderBuffer,
	x1: f32,
	y1: f32,
	x2: f32,
	y2: f32,
	thickness: f32,
	color: rl.Color,
) {
	append(
		&buffer.commands,
		RenderCommand {
			kind = .Line,
			point = rl.Vector2{x1, y1},
			point2 = rl.Vector2{x2, y2},
			thickness = thickness,
			color = color,
		},
	)
}

push_poly :: proc(
	buffer: ^RenderBuffer,
	x: f32,
	y: f32,
	sides: i32,
	radius: f32,
	rotation: f32,
	color: rl.Color,
	additive := false,
) {
	append(
		&buffer.commands,
		RenderCommand {
			kind = .Poly,
			point = rl.Vector2{x, y},
			sides = sides,
			radius = radius,
			rotation = rotation,
			color = color,
			additive = additive,
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

push_rotated_text :: proc(
	buffer: ^RenderBuffer,
	label: cstring,
	x: i32,
	y: i32,
	font_size: i32,
	rotation: f32,
	color: rl.Color,
) {
	append(
		&buffer.commands,
		RenderCommand {
			kind = .Text_Rotated,
			text = label,
			rect = rl.Rectangle{f32(x), f32(y), 0, 0},
			font_size = font_size,
			rotation = rotation,
			color = color,
		},
	)
}

push_rotated_centered_text :: proc(
	buffer: ^RenderBuffer,
	label: cstring,
	center_x: f32,
	center_y: f32,
	font_size: i32,
	rotation: f32,
	color: rl.Color,
) {
	text_width := measure_text_width(label, font_size)
	append(
		&buffer.commands,
		RenderCommand {
			kind = .Text_Rotated,
			text = label,
			rect = rl.Rectangle{center_x, center_y, 0, 0},
			point = rl.Vector2{f32(text_width) * 0.5, f32(font_size) * 0.5},
			font_size = font_size,
			rotation = rotation,
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
	label_width := measure_text_width(label, font_size)
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
	theme: Theme,
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
		text_width := measure_text_width(label, font_size)
		text_x := x + (size - text_width) / 2
		text_y := y + (size - font_size) / 2
		append(
			&buffer.commands,
			RenderCommand {
				kind = .Text,
				text = label,
				rect = rl.Rectangle{f32(text_x), f32(text_y), 0, 0},
				font_size = font_size,
				color = theme.text,
			},
		)
	}
}

flush_render_buffer_offset_range :: proc(
	buffer: RenderBuffer,
	offset: rl.Vector2,
	start_index: int,
	end_index: int,
) {
	start := start_index
	if start < 0 do start = 0
	if start > len(buffer.commands) do start = len(buffer.commands)
	end := end_index
	if end < start do end = start
	if end > len(buffer.commands) do end = len(buffer.commands)
	for i in start ..< end {
		command := buffer.commands[i]
		if command.additive {
			rl.BeginBlendMode(.ADDITIVE)
		}
		switch command.kind {
		case .Rect:
			rl.DrawRectangle(
				i32(command.rect.x + offset.x),
				i32(command.rect.y + offset.y),
				i32(command.rect.width),
				i32(command.rect.height),
				command.color,
			)
		case .Rect_Rotated:
			rect := command.rect
			rect.x += offset.x
			rect.y += offset.y
			rl.DrawRectanglePro(
				rect,
				rl.Vector2{command.rect.width * 0.5, command.rect.height * 0.5},
				command.rotation,
				command.color,
			)
		case .Rect_Lines:
			rect := command.rect
			rect.x += offset.x
			rect.y += offset.y
			rl.DrawRectangleLinesEx(rect, command.thickness, command.color)
		case .Rect_Gradient_V:
			rl.DrawRectangleGradientV(
				i32(command.rect.x + offset.x),
				i32(command.rect.y + offset.y),
				i32(command.rect.width),
				i32(command.rect.height),
				command.color,
				command.color2,
			)
		case .Circle:
			rl.DrawCircleV(command.point + offset, command.radius, command.color)
		case .Circle_Gradient:
			rl.DrawCircleGradient(
				i32(command.point.x + offset.x),
				i32(command.point.y + offset.y),
				command.radius,
				command.color,
				command.color2,
			)
		case .Line:
			rl.DrawLineEx(
				command.point + offset,
				command.point2 + offset,
				command.thickness,
				command.color,
			)
		case .Poly:
			rl.DrawPoly(
				command.point + offset,
				command.sides,
				command.radius,
				command.rotation,
				command.color,
			)
		case .Text:
			rl.DrawTextEx(
				game_font,
				command.text,
				rl.Vector2{command.rect.x + offset.x, command.rect.y + offset.y},
				f32(command.font_size),
				TEXT_SPACING,
				command.color,
			)
		case .Text_Rotated:
			rl.DrawTextPro(
				game_font,
				command.text,
				rl.Vector2{command.rect.x + offset.x, command.rect.y + offset.y},
				command.point,
				command.rotation,
				f32(command.font_size),
				1,
				command.color,
			)
		}
		if command.additive {
			rl.EndBlendMode()
		}
	}
}

flush_render_buffer_offset_from :: proc(
	buffer: RenderBuffer,
	offset: rl.Vector2,
	start_index: int,
) {
	flush_render_buffer_offset_range(buffer, offset, start_index, len(buffer.commands))
}

flush_render_buffer_offset_until :: proc(
	buffer: RenderBuffer,
	offset: rl.Vector2,
	end_index: int,
) {
	flush_render_buffer_offset_range(buffer, offset, 0, end_index)
}

flush_render_buffer_offset :: proc(buffer: RenderBuffer, offset: rl.Vector2) {
	flush_render_buffer_offset_from(buffer, offset, 0)
}

flush_render_buffer :: proc(buffer: RenderBuffer) {
	flush_render_buffer_offset(buffer, rl.Vector2{0, 0})
}

flush_render_frame_offset :: proc(frame: RenderFrame, offset: rl.Vector2) {
	flush_render_buffer_offset(frame.world, offset)
	flush_render_buffer_offset(frame.ui, offset)
	flush_render_buffer_offset(frame.fixed_ui, offset)
	flush_render_buffer_offset(frame.overlay, offset)
}

flush_render_frame_moving_offset :: proc(frame: RenderFrame, offset: rl.Vector2) {
	flush_render_buffer_offset(frame.world, offset)
	flush_render_buffer_offset(frame.ui, offset)
	flush_render_buffer_offset(frame.overlay, offset)
}

flush_render_frame_moving_offset_skip_background :: proc(frame: RenderFrame, offset: rl.Vector2) {
	flush_render_buffer_offset_from(frame.world, offset, frame.world.background_count)
	flush_render_buffer_offset(frame.ui, offset)
	flush_render_buffer_offset(frame.overlay, offset)
}

flush_render_frame :: proc(frame: RenderFrame) {
	flush_render_frame_offset(frame, rl.Vector2{0, 0})
}
