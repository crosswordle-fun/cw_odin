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
	title_label := game_data.menu.title
	start_label := game_data.menu.start_label
	exit_label := game_data.menu.exit_label

	title_face_size := scaled_i32(game_data.menu.title_face_size, ctx.scale)
	title_gap := i32(rl.Clamp(f32(title_face_size) / 20.0, 1, f32(title_face_size)))
	title_base_height := title_face_size / 10
	if title_base_height < 1 do title_base_height = 1
	title_height := title_face_size + title_base_height
	title_font_size := i32(
		rl.Clamp(f32(title_face_size) * game_data.menu.title_font_ratio, 1, f32(title_face_size)),
	)
	button_font := scaled_i32(game_data.menu.button_font, ctx.scale)
	button_padding_x := scaled_i32(game_data.menu.button_padding_x, ctx.scale)
	button_padding_y := scaled_i32(game_data.menu.button_padding_y, ctx.scale)
	button_gap := scaled_i32(game_data.menu.button_gap, ctx.scale)

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
	start_y := title_y + title_height + scaled_i32(game_data.menu.title_button_gap, ctx.scale)
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

menu_title_drop_bounce :: proc(tile_age: f32) -> f32 {
	if tile_age >= game_data.menu.drop_duration do return 0
	bounce :=
		(1 - saturate(tile_age / game_data.menu.drop_duration)) * -game_data.menu.drop_distance
	if tile_age > 0 {
		bounce =
			-game_data.menu.drop_distance +
			rl.EaseBounceOut(
				tile_age,
				0,
				game_data.menu.drop_distance,
				game_data.menu.drop_duration,
			)
	}
	return bounce
}

menu_title_rebounce :: proc(tile_age: f32) -> f32 {
	raise_duration := game_data.menu.rebounce_raise_time
	fall_duration := game_data.menu.rebounce_fall_time
	lift := -game_data.menu.rebounce_lift

	if tile_age < 0 do return 0
	if tile_age < raise_duration {
		return rl.EaseSineInOut(tile_age, 0, lift, raise_duration)
	}

	fall_age := tile_age - raise_duration
	if fall_age < fall_duration {
		return rl.EaseBounceOut(fall_age, lift, -lift, fall_duration)
	}

	return 0
}

menu_title_cycle_color :: proc(
	gray, yellow, green, blue, purple: rl.Color,
	age, period: f32,
) -> rl.Color {
	if period <= 0 do return gray

	position := rl.Wrap(age, 0, period) / period
	if position < 1.0 / 5.0 {
		return lerp_color(gray, yellow, ease01(position * 5.0))
	}
	if position < 2.0 / 5.0 {
		return lerp_color(yellow, green, ease01((position - 1.0 / 5.0) * 5.0))
	}
	if position < 3.0 / 5.0 {
		return lerp_color(green, blue, ease01((position - 2.0 / 5.0) * 5.0))
	}
	if position < 4.0 / 5.0 {
		return lerp_color(blue, purple, ease01((position - 3.0 / 5.0) * 5.0))
	}
	return lerp_color(purple, gray, ease01((position - 4.0 / 5.0) * 5.0))
}

build_menu_title :: proc(buffer: ^RenderBuffer, layout: MenuLayout, theme: Theme, ui: UiState) {
	title_label := game_data.menu.title
	elapsed := ui.time - ui.view_enter_time
	title_stagger := game_data.menu.stagger
	bounce_duration := game_data.menu.drop_duration
	rebounce_period := game_data.menu.rebounce_period
	initial_drop_duration := bounce_duration + f32(len(title_label) - 1) * title_stagger

	x := layout.title_x
	for i in 0 ..< len(title_label) {
		tile_age := elapsed - f32(i) * title_stagger
		bounce := menu_title_drop_bounce(tile_age)
		if elapsed >= initial_drop_duration + rebounce_period {
			rebounce_elapsed := rl.Wrap(elapsed - initial_drop_duration, 0, rebounce_period)
			rebounce_age := rebounce_elapsed - f32(i) * title_stagger
			if rebounce_age >= 0 {
				bounce = menu_title_rebounce(rebounce_age)
			}
		}
		color_age := elapsed - f32(i) * title_stagger
		face_color := menu_title_cycle_color(
			theme.surface,
			TAILWIND_YELLOW_400,
			TAILWIND_GREEN_400,
			TAILWIND_BLUE_400,
			TAILWIND_PURPLE_400,
			color_age,
			rebounce_period,
		)
		base_color := menu_title_cycle_color(
			theme.surface_shadow,
			TAILWIND_YELLOW_600,
			TAILWIND_GREEN_600,
			TAILWIND_BLUE_600,
			TAILWIND_PURPLE_600,
			color_age,
			rebounce_period,
		)
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
				outline = theme.outline,
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
	build_menu_title(&frame.ui, layout, theme, ui)
	build_button(
		&frame.ui,
		game_data.menu.start_label,
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
		game_data.menu.exit_label,
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
