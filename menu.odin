package main

import rl "vendor:raylib"

MenuLayout :: struct {
	title_x:         i32,
	title_y:         i32,
	title_face_size: i32,
	title_gap:       i32,
	title_font_size: i32,
	title_height:    i32,
	button_x:        i32,
	button_width:    i32,
	button_height:   i32,
	button_font:     i32,
	start_y:         i32,
	exit_y:          i32,
}

MenuSelection :: enum {
	Start,
	Exit,
}

menu_layout :: proc(ctx: RenderContext) -> MenuLayout {
	title_label := "CROSSWORDLE"
	start_label: cstring = "START"
	exit_label: cstring = "EXIT"

	title_face_size := scaled_i32(72, ctx.scale)
	title_gap := i32(rl.Clamp(f32(title_face_size) / 20.0, 1, f32(title_face_size)))
	title_base_height := title_face_size / 10
	if title_base_height < 1 do title_base_height = 1
	title_height := title_face_size + title_base_height
	title_font_size := i32(rl.Clamp(f32(title_face_size) * 0.58, 1, f32(title_face_size)))
	button_font := scaled_i32(28, ctx.scale)
	button_padding_x := scaled_i32(28, ctx.scale)
	button_padding_y := scaled_i32(14, ctx.scale)
	button_gap := scaled_i32(16, ctx.scale)

	title_width :=
		i32(len(title_label)) * title_face_size + (i32(len(title_label)) - 1) * title_gap
	start_width := measure_text_width(start_label, button_font)
	exit_width := measure_text_width(exit_label, button_font)
	button_text_width := start_width
	if exit_width > button_text_width do button_text_width = exit_width

	button_width := button_text_width + button_padding_x * 2
	button_height := button_font + button_padding_y * 2
	title_x := (ctx.screen_width - title_width) / 2
	title_y := (ctx.screen_height - title_height) / 2
	button_x := (ctx.screen_width - button_width) / 2
	start_y := title_y + title_height + scaled_i32(32, ctx.scale)
	exit_y := start_y + button_height + button_gap

	return MenuLayout {
		title_x = title_x,
		title_y = title_y,
		title_face_size = title_face_size,
		title_gap = title_gap,
		title_font_size = title_font_size,
		title_height = title_height,
		button_x = button_x,
		button_width = button_width,
		button_height = button_height,
		button_font = button_font,
		start_y = start_y,
		exit_y = exit_y,
	}
}

menu_selection_from_state :: proc(selection: i32) -> MenuSelection {
	if selection == 1 do return .Exit
	return .Start
}

menu_selection_to_state :: proc(selection: MenuSelection) -> i32 {
	if selection == .Exit do return 1
	return 0
}

build_menu_title :: proc(buffer: ^RenderBuffer, layout: MenuLayout, theme: Theme, ui: UiState) {
	title_label := "CROSSWORDLE"
	face_color := theme.surface
	base_color := theme.surface_shadow

	x := layout.title_x
	for i in 0 ..< len(title_label) {
		tile_age := ui.time - ui.view_enter_time - f32(i) * 0.045
		bounce := f32(0)
		if tile_age < 0.5 {
			bounce = (1 - saturate(tile_age / 0.5)) * -28
			if tile_age > 0 do bounce = -28 + rl.EaseBounceOut(tile_age, 0, 28, 0.5)
		}
		build_title_tile(
			buffer,
			TitleTile {
				x = x,
				y = layout.title_y + i32(bounce),
				face_size = layout.title_face_size,
				letter = rune(title_label[i]),
				face_color = face_color,
				base_color = base_color,
				font_size = layout.title_font_size,
				text_color = theme.text,
			},
		)
		x += layout.title_face_size + layout.title_gap
	}
}

build_menu_mode_view :: proc(
	frame: ^RenderFrame,
	ctx: RenderContext,
	layout: MenuLayout,
	start_hovered: bool,
	exit_hovered: bool,
	selection: MenuSelection,
	theme: Theme,
	ui: UiState,
) {
	panel_x := layout.button_x - scaled_i32(42, ctx.scale)
	panel_y := layout.start_y - scaled_i32(28, ctx.scale)
	panel_w := layout.button_width + scaled_i32(84, ctx.scale)
	panel_h := layout.exit_y + layout.button_height - panel_y + scaled_i32(28, ctx.scale)
	push_rect(
		&frame.ui,
		panel_x,
		panel_y + scaled_i32(8, ctx.scale),
		panel_w,
		panel_h,
		with_alpha(theme.surface_shadow, 74),
	)
	push_rect(&frame.ui, panel_x, panel_y, panel_w, panel_h, with_alpha(theme.surface, 230))
	push_rect_lines(&frame.ui, panel_x, panel_y, panel_w, panel_h, 2, rl.BLACK)
	build_menu_title(&frame.ui, layout, theme, ui)
	build_button(
		&frame.ui,
		"START",
		layout.button_x,
		layout.start_y,
		layout.button_width,
		layout.button_height,
		layout.button_font,
		start_hovered,
		theme,
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
		theme,
	)

	draw_ui_effects(&frame.overlay, ctx, ui)
}

menu_mode_frame :: proc(frame: ^RenderFrame, ctx: RenderContext, state: ^GameState) {
	layout := menu_layout(ctx)
	selection := menu_selection_from_state(state.menu_selection)

	if rl.IsKeyPressed(rl.KeyboardKey.UP) || rl.IsKeyPressed(rl.KeyboardKey.DOWN) {
		if selection == .Start {
			selection = .Exit
		} else {
			selection = .Start
		}
	}

	if rl.IsKeyPressed(rl.KeyboardKey.ENTER) {
		switch selection {
		case .Start:
			game_set_view(state, .Wordle)
		case .Exit:
			state.should_quit = true
		}
	}

	state.menu_selection = menu_selection_to_state(selection)
	start_hovered := selection == .Start
	exit_hovered := selection == .Exit
	build_menu_mode_view(
		frame,
		ctx,
		layout,
		start_hovered,
		exit_hovered,
		selection,
		ctx.theme,
		state.ui,
	)
}

