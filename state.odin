package main

game_state_new :: proc(virtual_width: i32, virtual_height: i32) -> GameState {
	grid := grid_new(virtual_width, virtual_height)
	return GameState {
		grid = grid,
		selector = selector_new(grid),
		wordle = wordle_state_new(),
		show_frags = true,
		view = .Menu,
		theme = THEMES[0],
		theme_index = 0,
		ui = ui_state_new(.Menu, 0),
		menu_selection = 0,
		screen_width = virtual_width,
		screen_height = virtual_height,
	}
}

game_update_screen_size :: proc(state: ^GameState, virtual_width: i32, virtual_height: i32) {
	scale_x := f32(virtual_width) / f32(VIRTUAL_SCREEN_WIDTH)
	scale_y := f32(virtual_height) / f32(VIRTUAL_SCREEN_HEIGHT)
	scale := scale_x
	if scale_y < scale_x do scale = scale_y

	state.grid.cell_size = i32(f32(BASE_CELL_SIZE) * scale + 0.5)
	if state.grid.cell_size < 1 do state.grid.cell_size = 1
	state.grid.gap = i32(f32(BASE_GAP) * scale + 0.5)
	if state.grid.gap < 1 do state.grid.gap = 1
	state.grid.screen_width = virtual_width
	state.grid.screen_height = virtual_height
	state.grid.offset_x = (virtual_width - grid_pixel_width(state.grid)) / 2
	state.grid.offset_y = (virtual_height - grid_pixel_height(state.grid)) / 2
	state.screen_width = virtual_width
	state.screen_height = virtual_height
}

game_toggle_frag_rune_view :: proc(state: ^GameState) {
	state.show_frags = !state.show_frags
}

game_cycle_theme :: proc(state: ^GameState) {
	state.theme_index = (state.theme_index + 1) % i32(len(THEMES))
	state.theme = THEMES[state.theme_index]
}

game_set_view :: proc(state: ^GameState, view: GameView) {
	if state.view == view do return

	ui_note_view_change(&state.ui, state.view)
	state.view = view
}

game_increment_frags_and_runes :: proc(state: ^GameState) {
	for i in 0 ..< LETTER_COUNT {
		state.frag_counts[i] += 10
		state.rune_counts[i] += 1
	}
}
