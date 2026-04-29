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
	theme:         Theme,
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

render_context_new :: proc(screen_width: i32, screen_height: i32, theme: Theme) -> RenderContext {
	return RenderContext {
		screen_width = screen_width,
		screen_height = screen_height,
		scale = screen_scale(screen_width, screen_height),
		theme = theme,
	}
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
				color = theme.text,
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
