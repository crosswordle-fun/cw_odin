package main

import "core:fmt"
import rl "vendor:raylib"

render_selector :: proc(grid: Grid, selector: Selector, selector_buffer: SelectorBuffer, show_frags: bool) {
	line_color := rl.SKYBLUE
	if !show_frags {
		line_color = rl.PURPLE
	}

	x, y := grid_tile_position(grid, selector.row, selector.col)
	rl.DrawRectangleLinesEx(
		rl.Rectangle{f32(x), f32(y), f32(grid.cell_size), f32(grid.cell_size)},
		f32(BASE_SELECTOR_OUTLINE) * f32(grid.cell_size) / f32(BASE_CELL_SIZE),
		line_color,
	)

	for i in 0 ..< selector_buffer.count {
		row, col := selector_letter_position(grid, selector, i)
		x, y := grid_tile_position(grid, row, col)
		rl.DrawRectangleLinesEx(
			rl.Rectangle{f32(x), f32(y), f32(grid.cell_size), f32(grid.cell_size)},
			3,
			line_color,
		)
	}
}

render_selector_letter :: proc(grid: Grid, selector: Selector, selector_buffer: SelectorBuffer) {
	if selector_buffer.count == 0 do return

	scale := f32(grid.cell_size) / f32(BASE_CELL_SIZE)
	font_size := scaled_i32(BASE_SELECTOR_FONT_SIZE, f32(grid.cell_size) / f32(BASE_CELL_SIZE))
	label_offset := scaled_i32(BASE_SELECTOR_LABEL_OFFSET, scale)
	for i in 0 ..< selector_buffer.count {
		row, col := selector_letter_position(grid, selector, i)
		x, y := grid_tile_position(grid, row, col)
		label := fmt.caprintf("%c", selector_buffer.letters[i])
		rl.DrawText(
			label,
			x + grid.cell_size - font_size - label_offset,
			y + grid.cell_size - font_size - label_offset,
			font_size,
			rl.WHITE,
		)
	}
}

render_grid :: proc(grid: Grid) {
	scale := f32(grid.cell_size) / f32(BASE_CELL_SIZE)
	font_size := scaled_i32(BASE_BOARD_FONT_SIZE, scale)
	rune_padding := scaled_i32(BASE_RUNE_PADDING, scale)
	for i in 0 ..< len(grid.tiles) {
		tile := grid.tiles[i]
		x, y := grid_tile_position(grid, tile.row, tile.col)

		if grid.frags[i] != 0 {
			rl.DrawRectangle(x, y, grid.cell_size, grid.cell_size, rl.SKYBLUE)
			label := fmt.caprintf("%c", grid.frags[i])
			text_width := rl.MeasureText(label, font_size)
			text_x := x + (grid.cell_size - text_width) / 2
			text_y := y + (grid.cell_size - font_size) / 2
			rl.DrawText(label, text_x, text_y, font_size, rl.WHITE)
		} else {
			rl.DrawRectangle(x, y, grid.cell_size, grid.cell_size, rl.DARKGRAY)
		}

		if grid.runes[i] != 0 {
			rune_size := grid.cell_size - rune_padding * 2
			rune_x := x + rune_padding
			rune_y := y + rune_padding

			rl.DrawRectangle(rune_x, rune_y, rune_size, rune_size, rl.PURPLE)
			label := fmt.caprintf("%c", grid.runes[i])
			text_width := rl.MeasureText(label, font_size)
			text_x := rune_x + (rune_size - text_width) / 2
			text_y := rune_y + (rune_size - font_size) / 2
			rl.DrawText(label, text_x, text_y, font_size, rl.WHITE)
		}
	}
}

render_inventory_counts :: proc(
	screen_width: i32,
	screen_height: i32,
	counts: [LETTER_COUNT]u32,
	color: rl.Color,
) {
	scale := screen_scale(screen_width, screen_height)

	font_size := scaled_i32(BASE_HUD_FONT_SIZE, scale)
	item_width := scaled_i32(BASE_HUD_ITEM_WIDTH, scale)
	row_height := scaled_i32(BASE_HUD_ROW_HEIGHT, scale)
	value_offset := scaled_i32(BASE_HUD_VALUE_OFFSET, scale)
	hud_width := item_width * 13 - 10
	start_x := (screen_width - hud_width) / 2
	start_y := screen_height - (row_height * 2) - 20

	for i in 0 ..< LETTER_COUNT {
		row := i32(i / 13)
		col := i32(i % 13)
		x := start_x + col * item_width
		y := start_y + row * row_height
		label := fmt.caprintf("%c", FRAG_LETTERS[i])
		value := fmt.caprintf("%d", counts[i])

		rl.DrawText(label, x, y, font_size, color)
		rl.DrawText(value, x + value_offset, y, font_size, color)
	}
}

render_frags :: proc(screen_width: i32, screen_height: i32, frag_counts: Frags) {
	render_inventory_counts(screen_width, screen_height, frag_counts, rl.SKYBLUE)
}

render_runes :: proc(screen_width: i32, screen_height: i32, rune_counts: Runes) {
	render_inventory_counts(screen_width, screen_height, rune_counts, rl.PURPLE)
}

render_game :: proc(state: GameState) {
	rl.ClearBackground(rl.Color{20, 20, 24, 255})
	render_grid(state.grid)
	render_selector(state.grid, state.selector, state.selector_buffer, state.show_frags)
	render_selector_letter(state.grid, state.selector, state.selector_buffer)
	if state.show_frags do render_frags(state.screen_width, state.screen_height, state.frag_counts)
	else do render_runes(state.screen_width, state.screen_height, state.rune_counts)
}
