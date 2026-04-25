package main
import "core:fmt"
import rl "vendor:raylib"

Tile :: struct {
	row: i32,
	col: i32,
}

Frags :: [26]u32
Runes :: [26]u32

FRAG_LETTERS := [26]rune {
	'A',
	'B',
	'C',
	'D',
	'E',
	'F',
	'G',
	'H',
	'I',
	'J',
	'K',
	'L',
	'M',
	'N',
	'O',
	'P',
	'Q',
	'R',
	'S',
	'T',
	'U',
	'V',
	'W',
	'X',
	'Y',
	'Z',
}

Grid :: struct {
	tiles:         []Tile,
	frags:         []rune,
	runes:         []rune,
	cols:          i32,
	rows:          i32,
	cell_size:     i32,
	gap:           i32,
	screen_width:  i32,
	screen_height: i32,
	offset_x:      i32,
	offset_y:      i32,
}

Selector :: struct {
	row: i32,
	col: i32,
}

SelectorBuffer :: struct {
	letters: [5]rune,
	count:   i32,
}

grid_new :: proc(screen_width: i32, screen_height: i32) -> Grid {
	cols: i32 = 7
	rows: i32 = 7
	cell_size: i32 = 64
	gap: i32 = 4

	grid_width := cols * cell_size + (cols - 1) * gap
	grid_height := rows * cell_size + (rows - 1) * gap

	grid := Grid {
		tiles         = make([]Tile, cols * rows),
		frags         = make([]rune, cols * rows),
		runes         = make([]rune, cols * rows),
		cols          = cols,
		rows          = rows,
		cell_size     = cell_size,
		gap           = gap,
		screen_width  = screen_width,
		screen_height = screen_height,
		offset_x      = (screen_width - grid_width) / 2,
		offset_y      = (screen_height - grid_height) / 2,
	}

	i := 0
	for row in 0 ..< rows {
		for col in 0 ..< cols {
			grid.tiles[i] = Tile{row, col}
			i += 1
		}
	}

	return grid
}

selector_new :: proc(grid: Grid) -> Selector {
	return Selector{row = grid.rows / 2, col = grid.cols / 2}
}

selector_handle_arrow_input :: proc(selector: ^Selector, grid: Grid) {
	if rl.IsKeyPressed(rl.KeyboardKey.UP) {
		selector.row = clamp(selector.row - 1, 0, grid.rows - 1)
	}
	if rl.IsKeyPressed(rl.KeyboardKey.DOWN) {
		selector.row = clamp(selector.row + 1, 0, grid.rows - 1)
	}
	if rl.IsKeyPressed(rl.KeyboardKey.LEFT) {
		selector.col = clamp(selector.col - 1, 0, grid.cols - 1)
	}
	if rl.IsKeyPressed(rl.KeyboardKey.RIGHT) {
		selector.col = clamp(selector.col + 1, 0, grid.cols - 1)
	}
}

selector_handle_mouse_input :: proc(selector: ^Selector, grid: Grid) {
	if !rl.IsMouseButtonPressed(rl.MouseButton.LEFT) do return

	mouse_pos := rl.GetMousePosition()
	grid_right := grid.offset_x + grid.cols * grid.cell_size + (grid.cols - 1) * grid.gap
	grid_bottom := grid.offset_y + grid.rows * grid.cell_size + (grid.rows - 1) * grid.gap

	if mouse_pos.x < f32(grid.offset_x) || mouse_pos.y < f32(grid.offset_y) {
		return
	}
	if mouse_pos.x >= f32(grid_right) || mouse_pos.y >= f32(grid_bottom) {
		return
	}

	step := f32(grid.cell_size + grid.gap)
	selector.col = i32((mouse_pos.x - f32(grid.offset_x)) / step)
	selector.row = i32((mouse_pos.y - f32(grid.offset_y)) / step)
}

selector_buffer_handle_input :: proc(selector_buffer: ^SelectorBuffer) {
	if rl.IsKeyPressed(rl.KeyboardKey.BACKSPACE) {
		if selector_buffer.count > 0 {
			selector_buffer.count -= 1
			selector_buffer.letters[selector_buffer.count] = 0
		}
		return
	}

	for {
		ch := rl.GetCharPressed()
		if ch == 0 {
			break
		}

		if ch >= 'a' && ch <= 'z' {
			ch -= 'a' - 'A'
		}

		if ch >= 'A' && ch <= 'Z' {
			if selector_buffer.count < i32(len(selector_buffer.letters[:])) {
				selector_buffer.letters[selector_buffer.count] = rune(ch)
				selector_buffer.count += 1
			}
		}
	}
}

selector_submit_letters :: proc(
	grid: ^Grid,
	selector: Selector,
	selector_buffer: ^SelectorBuffer,
	frag_counts: ^Frags,
	rune_counts: ^Runes,
	show_frags: bool,
) {
	if !rl.IsKeyPressed(rl.KeyboardKey.ENTER) do return
	if selector_buffer.count == 0 do return

	if selector.col + selector_buffer.count > grid.cols do return

	for i in 0 ..< selector_buffer.count {
		letter := selector_buffer.letters[i]
		frag_index := i32(letter - 'A')
		tile_index := selector.row * grid.cols + selector.col + i
		if tile_index < 0 || tile_index >= i32(len(grid.frags)) do return
		if frag_index < 0 || frag_index >= i32(len(frag_counts[:])) do return

		if show_frags {
			if frag_counts[frag_index] == 0 do return
			if grid.frags[tile_index] != 0 do return
			continue
		}

		if rune_counts[frag_index] == 0 do return
		if grid.frags[tile_index] != letter do return
		if grid.runes[tile_index] != 0 do return
	}

	if show_frags {
		for i in 0 ..< selector_buffer.count {
			letter := selector_buffer.letters[i]
			frag_index := i32(letter - 'A')
			tile_index := selector.row * grid.cols + selector.col + i

			grid.frags[tile_index] = letter
			frag_counts[frag_index] -= 1
		}
		selector_buffer.count = 0
		return
	}

	for i in 0 ..< selector_buffer.count {
		letter := selector_buffer.letters[i]
		frag_index := i32(letter - 'A')
		tile_index := selector.row * grid.cols + selector.col + i

		grid.runes[tile_index] = letter
		rune_counts[frag_index] -= 1
	}
	selector_buffer.count = 0
}

increment_frags_and_runes :: proc(frag_counts: ^Frags, rune_counts: ^Runes) {
	if !rl.IsKeyPressed(rl.KeyboardKey.ONE) do return

	for i in 0 ..< len(frag_counts[:]) {
		frag_counts[i] += 10
		rune_counts[i] += 1
	}
}

toggle_frag_rune_view :: proc(show_frags: ^bool) {
	if rl.IsKeyPressed(rl.KeyboardKey.TAB) do show_frags^ = !show_frags^
}

render_selector :: proc(
	grid: ^Grid,
	selector: ^Selector,
	selector_buffer: SelectorBuffer,
	show_frags: bool,
) {
	line_color := rl.SKYBLUE
	if !show_frags {
		line_color = rl.PURPLE
	}

	x := grid.offset_x + selector.col * (grid.cell_size + grid.gap)
	y := grid.offset_y + selector.row * (grid.cell_size + grid.gap)
	rl.DrawRectangleLinesEx(
		rl.Rectangle{f32(x), f32(y), f32(grid.cell_size), f32(grid.cell_size)},
		3,
		line_color,
	)

	for i in 0 ..< selector_buffer.count {
		x := grid.offset_x + (selector.col + i) * (grid.cell_size + grid.gap)
		rl.DrawRectangleLinesEx(
			rl.Rectangle{f32(x), f32(y), f32(grid.cell_size), f32(grid.cell_size)},
			3,
			line_color,
		)
	}
}

render_selector_letter :: proc(grid: ^Grid, selector: ^Selector, selector_buffer: SelectorBuffer) {
	if selector_buffer.count == 0 do return

	font_size: i32 = 24
	for i in 0 ..< selector_buffer.count {
		x := grid.offset_x + (selector.col + i) * (grid.cell_size + grid.gap)
		y := grid.offset_y + selector.row * (grid.cell_size + grid.gap)
		label := fmt.caprintf("%c", selector_buffer.letters[i])
		rl.DrawText(
			label,
			x + grid.cell_size - font_size - 6,
			y + grid.cell_size - font_size - 6,
			font_size,
			rl.WHITE,
		)
	}
}

render_grid :: proc(grid: ^Grid) {
	for i in 0 ..< len(grid.tiles) {
		tile := grid.tiles[i]
		x := grid.offset_x + tile.col * (grid.cell_size + grid.gap)
		y := grid.offset_y + tile.row * (grid.cell_size + grid.gap)

		if grid.frags[i] != 0 {
			rl.DrawRectangle(x, y, grid.cell_size, grid.cell_size, rl.SKYBLUE)
			label := fmt.caprintf("%c", grid.frags[i])
			font_size: i32 = 28
			text_width := rl.MeasureText(label, font_size)
			text_x := x + (grid.cell_size - text_width) / 2
			text_y := y + (grid.cell_size - font_size) / 2
			rl.DrawText(label, text_x, text_y, font_size, rl.WHITE)
		} else {
			rl.DrawRectangle(x, y, grid.cell_size, grid.cell_size, rl.DARKGRAY)
		}

		if grid.runes[i] != 0 {
			rune_padding: i32 = 6
			rune_size := grid.cell_size - rune_padding * 2
			rune_x := x + rune_padding
			rune_y := y + rune_padding

			rl.DrawRectangle(rune_x, rune_y, rune_size, rune_size, rl.PURPLE)
			label := fmt.caprintf("%c", grid.runes[i])
			font_size: i32 = 28
			text_width := rl.MeasureText(label, font_size)
			text_x := rune_x + (rune_size - text_width) / 2
			text_y := rune_y + (rune_size - font_size) / 2
			rl.DrawText(label, text_x, text_y, font_size, rl.WHITE)
		}
	}
}

render_frags :: proc(screen_width, screen_height: i32, frag_counts: Frags) {
	font_size: i32 = 20
	item_width: i32 = 56
	row_height: i32 = 30
	value_offset: i32 = 18
	hud_width := item_width * 13 - 10
	start_x := (screen_width - hud_width) / 2
	start_y := screen_height - (row_height * 2) - 20

	for i in 0 ..< 26 {
		row := i32(i / 13)
		col := i32(i % 13)
		x := start_x + col * item_width
		y := start_y + row * row_height
		label := fmt.caprintf("%c", FRAG_LETTERS[i])
		value := fmt.caprintf("%d", frag_counts[i])

		rl.DrawText(label, x, y, font_size, rl.SKYBLUE)
		rl.DrawText(value, x + value_offset, y, font_size, rl.SKYBLUE)
	}
}

render_runes :: proc(screen_width, screen_height: i32, rune_counts: Runes) {
	font_size: i32 = 20
	item_width: i32 = 56
	row_height: i32 = 30
	value_offset: i32 = 18
	hud_width := item_width * 13 - 10
	start_x := (screen_width - hud_width) / 2
	start_y := screen_height - (row_height * 2) - 20

	for i in 0 ..< 26 {
		row := i32(i / 13)
		col := i32(i % 13)
		x := start_x + col * item_width
		y := start_y + row * row_height
		label := fmt.caprintf("%c", FRAG_LETTERS[i])
		value := fmt.caprintf("%d", rune_counts[i])

		rl.DrawText(label, x, y, font_size, rl.PURPLE)
		rl.DrawText(value, x + value_offset, y, font_size, rl.PURPLE)
	}
}

main :: proc() {
	screen_width: i32 = 1280
	screen_height: i32 = 720

	rl.SetTargetFPS(60)
	rl.SetConfigFlags(rl.ConfigFlags{.WINDOW_RESIZABLE})

	rl.InitWindow(screen_width, screen_height, "cw_odin")
	defer rl.CloseWindow()

	frag_counts := Frags{}
	rune_counts := Runes{}
	grid := grid_new(screen_width, screen_height)
	selector := selector_new(grid)
	selector_buffer := SelectorBuffer{}
	show_frags := true

	for !rl.WindowShouldClose() {
		selector_handle_arrow_input(&selector, grid)
		selector_handle_mouse_input(&selector, grid)
		selector_buffer_handle_input(&selector_buffer)
		selector_submit_letters(
			&grid,
			selector,
			&selector_buffer,
			&frag_counts,
			&rune_counts,
			show_frags,
		)
		increment_frags_and_runes(&frag_counts, &rune_counts)
		toggle_frag_rune_view(&show_frags)

		rl.BeginDrawing()
		defer rl.EndDrawing()

		rl.ClearBackground(rl.Color{20, 20, 24, 255})
		render_grid(&grid)
		render_selector(&grid, &selector, selector_buffer, show_frags)
		render_selector_letter(&grid, &selector, selector_buffer)
		if show_frags do render_frags(screen_width, screen_height, frag_counts)
		else do render_runes(screen_width, screen_height, rune_counts)
	}
}

