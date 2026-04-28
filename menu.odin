package main

import rl "vendor:raylib"

MenuLayout :: struct {
	title_x:      i32,
	title_y:      i32,
	title_font:   i32,
	button_x:     i32,
	button_width: i32,
	button_height: i32,
	button_font:   i32,
	start_y:      i32,
	exit_y:       i32,
}

MenuSelection :: enum {
	Start,
	Exit,
}

menu_layout :: proc(ctx: RenderContext) -> MenuLayout {
	title_label: cstring = "CROSSWORDLE"
	start_label: cstring = "START"
	exit_label: cstring = "EXIT"

	title_font := scaled_i32(72, ctx.scale)
	button_font := scaled_i32(28, ctx.scale)
	button_padding_x := scaled_i32(28, ctx.scale)
	button_padding_y := scaled_i32(14, ctx.scale)
	button_gap := scaled_i32(16, ctx.scale)
	title_gap := scaled_i32(32, ctx.scale)

	title_width := rl.MeasureText(title_label, title_font)
	start_width := rl.MeasureText(start_label, button_font)
	exit_width := rl.MeasureText(exit_label, button_font)
	button_text_width := start_width
	if exit_width > button_text_width do button_text_width = exit_width

	button_width := button_text_width + button_padding_x * 2
	button_height := button_font + button_padding_y * 2
	title_x := (ctx.screen_width - title_width) / 2
	title_y := (ctx.screen_height - title_font) / 2
	button_x := (ctx.screen_width - button_width) / 2
	start_y := title_y + title_font + title_gap
	exit_y := start_y + button_height + button_gap

	return MenuLayout {
		title_x = title_x,
		title_y = title_y,
		title_font = title_font,
		button_x = button_x,
		button_width = button_width,
		button_height = button_height,
		button_font = button_font,
		start_y = start_y,
		exit_y = exit_y,
	}
}

menu_point_in_rect :: proc(point: rl.Vector2, x: i32, y: i32, width: i32, height: i32) -> bool {
	return point.x >= f32(x) &&
		point.y >= f32(y) &&
		point.x < f32(x + width) &&
		point.y < f32(y + height)
}

menu_selection_from_state :: proc(selection: i32) -> MenuSelection {
	if selection == 1 do return .Exit
	return .Start
}

menu_selection_to_state :: proc(selection: MenuSelection) -> i32 {
	if selection == .Exit do return 1
	return 0
}

menu_selection_rect :: proc(layout: MenuLayout, selection: MenuSelection) -> (x: i32, y: i32, width: i32, height: i32) {
	border_pad: i32 = 4
	switch selection {
	case .Start:
		x = layout.button_x - border_pad
		y = layout.start_y - border_pad
	case .Exit:
		x = layout.button_x - border_pad
		y = layout.exit_y - border_pad
	}
	width = layout.button_width + border_pad * 2
	height = layout.button_height + border_pad * 2
	return
}

build_menu_mode_view :: proc(
	frame: ^RenderFrame,
	layout: MenuLayout,
	start_hovered: bool,
	exit_hovered: bool,
	selection: MenuSelection,
) {
	build_text(&frame.ui, "CROSSWORDLE", layout.title_x, layout.title_y, layout.title_font, rl.WHITE)
	build_button(
		&frame.ui,
		"START",
		layout.button_x,
		layout.start_y,
		layout.button_width,
		layout.button_height,
		layout.button_font,
		start_hovered,
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
	)

	border_x, border_y, border_width, border_height := menu_selection_rect(layout, selection)
	push_rect_lines(
		&frame.overlay,
		border_x,
		border_y,
		border_width,
		border_height,
		3,
		rl.WHITE,
	)
}

menu_mode_frame :: proc(frame: ^RenderFrame, ctx: RenderContext, state: ^GameState) {
	layout := menu_layout(ctx)
	start_hovered := false
	exit_hovered := false
	selection := menu_selection_from_state(state.menu_selection)

	mouse_pos, ok := virtual_mouse_position()
	if ok {
		start_hovered = menu_point_in_rect(mouse_pos, layout.button_x, layout.start_y, layout.button_width, layout.button_height)
		exit_hovered = menu_point_in_rect(mouse_pos, layout.button_x, layout.exit_y, layout.button_width, layout.button_height)
		if start_hovered do selection = .Start
		if exit_hovered do selection = .Exit
	}

	if rl.IsKeyPressed(rl.KeyboardKey.UP) || rl.IsKeyPressed(rl.KeyboardKey.DOWN) {
		if selection == .Start {
			selection = .Exit
		} else {
			selection = .Start
		}
	}

	if rl.IsMouseButtonPressed(rl.MouseButton.LEFT) {
		if start_hovered {
			game_set_view(state, .Cross)
		} else if exit_hovered {
			state.should_quit = true
		}
	}

	if rl.IsKeyPressed(rl.KeyboardKey.ENTER) {
		switch selection {
		case .Start:
			game_set_view(state, .Cross)
		case .Exit:
			state.should_quit = true
		}
	}

	state.menu_selection = menu_selection_to_state(selection)
	build_menu_mode_view(frame, layout, start_hovered, exit_hovered, selection)
}
