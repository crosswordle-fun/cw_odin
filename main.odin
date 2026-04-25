package main
import "core:fmt"
import rl "vendor:raylib"

BASE_SCREEN_WIDTH :: 1280
BASE_SCREEN_HEIGHT :: 720
BASE_CELL_SIZE :: 64
BASE_GAP :: 4
BASE_HUD_ITEM_WIDTH :: 56
BASE_HUD_ROW_HEIGHT :: 30
BASE_HUD_FONT_SIZE :: 20
BASE_BOARD_FONT_SIZE :: 28
BASE_SELECTOR_FONT_SIZE :: 24
BASE_SELECTOR_OUTLINE :: 3
BASE_SELECTOR_LABEL_OFFSET :: 6
BASE_RUNE_PADDING :: 6
BASE_HUD_VALUE_OFFSET :: 18
GRID_COLS :: 7
GRID_ROWS :: 7

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

scaled_i32 :: proc(value: i32, scale: f32) -> i32 {
	scaled := i32(f32(value) * scale + 0.5)
	if scaled < 1 do return 1
	return scaled
}

Selector :: struct {
	row:  i32,
	col:  i32,
	down: bool,
}

SelectorBuffer :: struct {
	letters: [5]rune,
	count:   i32,
}

grid_new :: proc(screen_width: i32, screen_height: i32) -> Grid {
	grid_width := GRID_COLS * BASE_CELL_SIZE + (GRID_COLS - 1) * BASE_GAP
	grid_height := GRID_ROWS * BASE_CELL_SIZE + (GRID_ROWS - 1) * BASE_GAP

	grid := Grid {
		tiles         = make([]Tile, GRID_COLS * GRID_ROWS),
		frags         = make([]rune, GRID_COLS * GRID_ROWS),
		runes         = make([]rune, GRID_COLS * GRID_ROWS),
		cols          = GRID_COLS,
		rows          = GRID_ROWS,
		cell_size     = BASE_CELL_SIZE,
		gap           = BASE_GAP,
		screen_width  = screen_width,
		screen_height = screen_height,
		offset_x      = i32((screen_width - i32(grid_width)) / 2),
		offset_y      = i32((screen_height - i32(grid_height)) / 2),
	}

	i := 0
	for row in 0 ..< GRID_ROWS {
		for col in 0 ..< GRID_COLS {
			grid.tiles[i] = Tile{i32(row), i32(col)}
			i += 1
		}
	}

	return grid
}

grid_update_layout :: proc(grid: ^Grid, screen_width: i32, screen_height: i32) {
	scale_x := f32(screen_width) / f32(BASE_SCREEN_WIDTH)
	scale_y := f32(screen_height) / f32(BASE_SCREEN_HEIGHT)
	scale := scale_x
	if scale_y < scale do scale = scale_y

	grid.cell_size = scaled_i32(BASE_CELL_SIZE, scale)
	grid.gap = scaled_i32(BASE_GAP, scale)

	grid_width := grid.cols * grid.cell_size + (grid.cols - 1) * grid.gap
	grid_height := grid.rows * grid.cell_size + (grid.rows - 1) * grid.gap

	grid.screen_width = screen_width
	grid.screen_height = screen_height
	grid.offset_x = (screen_width - grid_width) / 2
	grid.offset_y = (screen_height - grid_height) / 2
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

toggle_selector_direction :: proc(selector: ^Selector) {
	if rl.IsKeyPressed(rl.KeyboardKey.SPACE) do selector.down = !selector.down
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

	if selector.down {
		if selector.row + selector_buffer.count > grid.rows do return
	} else {
		if selector.col + selector_buffer.count > grid.cols do return
	}

	required_frags := Frags{}
	required_runes := Runes{}

	for i in 0 ..< selector_buffer.count {
		letter := selector_buffer.letters[i]
		frag_index := i32(letter - 'A')
		tile_row := selector.row
		tile_col := selector.col
		if selector.down {
			tile_row += i
		} else {
			tile_col += i
		}
		tile_index := tile_row * grid.cols + tile_col
		if tile_index < 0 || tile_index >= i32(len(grid.frags)) do return
		if frag_index < 0 || frag_index >= i32(len(frag_counts[:])) do return

		required_frags[frag_index] += 1
		required_runes[frag_index] += 1

		if show_frags {
			if grid.frags[tile_index] != 0 do return
			continue
		}

		if grid.frags[tile_index] != letter do return
		if grid.runes[tile_index] != 0 do return
	}

	if show_frags {
		for i in 0 ..< len(required_frags[:]) {
			if required_frags[i] > frag_counts[i] do return
		}
	} else {
		for i in 0 ..< len(required_runes[:]) {
			if required_runes[i] > rune_counts[i] do return
		}
	}

	if show_frags {
		for i in 0 ..< selector_buffer.count {
			letter := selector_buffer.letters[i]
			frag_index := i32(letter - 'A')
			tile_row := selector.row
			tile_col := selector.col
			if selector.down {
				tile_row += i
			} else {
				tile_col += i
			}
			tile_index := tile_row * grid.cols + tile_col

			grid.frags[tile_index] = letter
			frag_counts[frag_index] -= 1
		}
		selector_buffer.count = 0
		return
	}

	for i in 0 ..< selector_buffer.count {
		letter := selector_buffer.letters[i]
		frag_index := i32(letter - 'A')
		tile_row := selector.row
		tile_col := selector.col
		if selector.down {
			tile_row += i
		} else {
			tile_col += i
		}
		tile_index := tile_row * grid.cols + tile_col

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
		f32(BASE_SELECTOR_OUTLINE) * f32(grid.cell_size) / f32(BASE_CELL_SIZE),
		line_color,
	)

	for i in 0 ..< selector_buffer.count {
		x := grid.offset_x + selector.col * (grid.cell_size + grid.gap)
		y := grid.offset_y + selector.row * (grid.cell_size + grid.gap)
		if selector.down {
			y = grid.offset_y + (selector.row + i) * (grid.cell_size + grid.gap)
		} else {
			x = grid.offset_x + (selector.col + i) * (grid.cell_size + grid.gap)
		}
		rl.DrawRectangleLinesEx(
			rl.Rectangle{f32(x), f32(y), f32(grid.cell_size), f32(grid.cell_size)},
			3,
			line_color,
		)
	}
}

render_selector_letter :: proc(grid: ^Grid, selector: ^Selector, selector_buffer: SelectorBuffer) {
	if selector_buffer.count == 0 do return

	scale := f32(grid.cell_size) / f32(BASE_CELL_SIZE)
	font_size := scaled_i32(BASE_SELECTOR_FONT_SIZE, f32(grid.cell_size) / f32(BASE_CELL_SIZE))
	label_offset := scaled_i32(BASE_SELECTOR_LABEL_OFFSET, scale)
	for i in 0 ..< selector_buffer.count {
		x := grid.offset_x + selector.col * (grid.cell_size + grid.gap)
		y := grid.offset_y + selector.row * (grid.cell_size + grid.gap)
		if selector.down {
			y = grid.offset_y + (selector.row + i) * (grid.cell_size + grid.gap)
		} else {
			x = grid.offset_x + (selector.col + i) * (grid.cell_size + grid.gap)
		}
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

render_grid :: proc(grid: ^Grid) {
	scale := f32(grid.cell_size) / f32(BASE_CELL_SIZE)
	font_size := scaled_i32(BASE_BOARD_FONT_SIZE, scale)
	rune_padding := scaled_i32(BASE_RUNE_PADDING, scale)
	for i in 0 ..< len(grid.tiles) {
		tile := grid.tiles[i]
		x := grid.offset_x + tile.col * (grid.cell_size + grid.gap)
		y := grid.offset_y + tile.row * (grid.cell_size + grid.gap)

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

render_frags :: proc(screen_width, screen_height: i32, frag_counts: Frags) {
	scale_x := f32(screen_width) / f32(BASE_SCREEN_WIDTH)
	scale_y := f32(screen_height) / f32(BASE_SCREEN_HEIGHT)
	scale := scale_x
	if scale_y < scale do scale = scale_y

	font_size := scaled_i32(BASE_HUD_FONT_SIZE, scale)
	item_width := scaled_i32(BASE_HUD_ITEM_WIDTH, scale)
	row_height := scaled_i32(BASE_HUD_ROW_HEIGHT, scale)
	value_offset := scaled_i32(BASE_HUD_VALUE_OFFSET, scale)
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
	scale_x := f32(screen_width) / f32(BASE_SCREEN_WIDTH)
	scale_y := f32(screen_height) / f32(BASE_SCREEN_HEIGHT)
	scale := scale_x
	if scale_y < scale do scale = scale_y

	font_size := scaled_i32(BASE_HUD_FONT_SIZE, scale)
	item_width := scaled_i32(BASE_HUD_ITEM_WIDTH, scale)
	row_height := scaled_i32(BASE_HUD_ROW_HEIGHT, scale)
	value_offset := scaled_i32(BASE_HUD_VALUE_OFFSET, scale)
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
	screen_width: i32 = BASE_SCREEN_WIDTH
	screen_height: i32 = BASE_SCREEN_HEIGHT

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
		screen_width = rl.GetScreenWidth()
		screen_height = rl.GetScreenHeight()
		grid_update_layout(&grid, screen_width, screen_height)

		selector_handle_arrow_input(&selector, grid)
		selector_handle_mouse_input(&selector, grid)
		selector_buffer_handle_input(&selector_buffer)
		toggle_selector_direction(&selector)
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

