package main

import "core:fmt"
import rl "vendor:raylib"

RENDER_BUFFER_CAPACITY :: 2048
// GAME_FONT_PATH :: "assets/jetbrains.ttf"
GAME_FONT_PATH :: "assets/tiny5.ttf"
TEXT_SPACING :: f32(1)

game_font: rl.Font

RenderCommandKind :: enum {
	Rect,
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
	theme:         Theme,
	time:          f32,
	dt:            f32,
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

game_font_load :: proc() {
	game_font = rl.LoadFont(GAME_FONT_PATH)
}

game_font_unload :: proc() {
	if rl.IsFontValid(game_font) {
		rl.UnloadFont(game_font)
	}
}

measure_text_width :: proc(label: cstring, font_size: i32) -> i32 {
	size := rl.MeasureTextEx(game_font, label, f32(font_size), TEXT_SPACING)
	return i32(size.x + 0.5)
}

render_frame_clear :: proc(frame: ^RenderFrame) {
	clear(&frame.world.commands)
	clear(&frame.ui.commands)
	clear(&frame.overlay.commands)
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

flush_render_buffer :: proc(buffer: RenderBuffer) {
	for i in 0 ..< len(buffer.commands) {
		command := buffer.commands[i]
		if command.additive {
			rl.BeginBlendMode(.ADDITIVE)
		}
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
		case .Rect_Gradient_V:
			rl.DrawRectangleGradientV(
				i32(command.rect.x),
				i32(command.rect.y),
				i32(command.rect.width),
				i32(command.rect.height),
				command.color,
				command.color2,
			)
		case .Circle:
			rl.DrawCircleV(command.point, command.radius, command.color)
		case .Circle_Gradient:
			rl.DrawCircleGradient(
				i32(command.point.x),
				i32(command.point.y),
				command.radius,
				command.color,
				command.color2,
			)
		case .Line:
			rl.DrawLineEx(command.point, command.point2, command.thickness, command.color)
		case .Poly:
			rl.DrawPoly(
				command.point,
				command.sides,
				command.radius,
				command.rotation,
				command.color,
			)
		case .Text:
			rl.DrawTextEx(
				game_font,
				command.text,
				rl.Vector2{command.rect.x, command.rect.y},
				f32(command.font_size),
				TEXT_SPACING,
				command.color,
			)
		case .Text_Rotated:
			rl.DrawTextPro(
				game_font,
				command.text,
				rl.Vector2{command.rect.x, command.rect.y},
				rl.Vector2{0, 0},
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

flush_render_frame :: proc(frame: RenderFrame) {
	flush_render_buffer(frame.world)
	flush_render_buffer(frame.ui)
	flush_render_buffer(frame.overlay)
}

