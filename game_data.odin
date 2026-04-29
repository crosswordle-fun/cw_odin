package main

import "core:encoding/json"
import "core:fmt"
import "core:os"
import "core:time"
import rl "vendor:raylib"

GameDataWatcher :: struct {
	path:       string,
	last_write: time.Time,
	valid:      bool,
}

game_data_validate :: proc(data: ^GameData) -> (ok: bool) {
	if data.screen.virtual_width <= 0 || data.screen.virtual_height <= 0 {
		fmt.eprintln("game_data: screen virtual size must be positive")
		return false
	}
	if data.screen.target_fps <= 0 {
		fmt.eprintln("game_data: target_fps must be positive")
		return false
	}
	if data.screen.render_buffer_capacity <= 0 {
		fmt.eprintln("game_data: render_buffer_capacity must be positive")
		return false
	}
	if data.grid.cols <= 0 ||
	   data.grid.rows <= 0 ||
	   data.grid.cell_size <= 0 ||
	   data.grid.gap <= 0 {
		fmt.eprintln("game_data: grid cols, rows, cell_size, and gap must be positive")
		return false
	}
	if len(data.grid.alphabet) == 0 || len(data.grid.alphabet) > LETTER_COUNT {
		fmt.eprintln("game_data: alphabet must contain 1..26 letters")
		return false
	}
	for letter in data.grid.alphabet {
		if letter < 'A' || letter > 'Z' {
			fmt.eprintf("game_data: alphabet letter %c must be A-Z\n", letter)
			return false
		}
	}
	if data.grid.selector_row < 0 ||
	   data.grid.selector_row >= data.grid.rows ||
	   data.grid.selector_col < 0 ||
	   data.grid.selector_col >= data.grid.cols {
		fmt.eprintln("game_data: selector default must be inside the grid")
		return false
	}
	if data.wordle.word_length <= 0 || data.wordle.word_length > WORDLE_WORD_LEN {
		fmt.eprintf("game_data: word_length must be 1..%d\n", WORDLE_WORD_LEN)
		return false
	}
	if len(data.wordle.solutions) == 0 {
		fmt.eprintln("game_data: wordle solutions cannot be empty")
		return false
	}
	for solution in data.wordle.solutions {
		if i32(len(solution)) != data.wordle.word_length {
			fmt.eprintf(
				"game_data: solution %q must be %d letters\n",
				solution,
				data.wordle.word_length,
			)
			return false
		}
		for ch in solution {
			if ch < 'A' || ch > 'Z' {
				fmt.eprintf("game_data: solution %q contains non A-Z letters\n", solution)
				return false
			}
		}
	}
	if data.crafting.selection_capacity <= 0 ||
	   data.crafting.selection_capacity > CRAFTING_SELECTION_CAPACITY {
		fmt.eprintf(
			"game_data: crafting selection_capacity must be 1..%d\n",
			CRAFTING_SELECTION_CAPACITY,
		)
		return false
	}
	if data.crafting.matching_required <= 0 ||
	   data.crafting.matching_required > data.crafting.selection_capacity ||
	   data.crafting.random_required <= 0 ||
	   data.crafting.random_required > data.crafting.selection_capacity {
		fmt.eprintln("game_data: crafting recipe requirements must fit selection_capacity")
		return false
	}
	if len(data.themes) == 0 {
		fmt.eprintln("game_data: at least one theme is required")
		return false
	}
	return true
}

game_data_load :: proc(path: string) -> (data: GameData, ok: bool) {
	bytes, read_err := os.read_entire_file(path, context.allocator)
	if read_err != nil {
		fmt.eprintf("game_data: failed to read %s: %v\n", path, read_err)
		return {}, false
	}
	defer delete(bytes)

	parse_err := json.unmarshal(bytes, &data, spec = .JSON5)
	if parse_err != nil {
		fmt.eprintf("game_data: failed to parse %s: %v\n", path, parse_err)
		return {}, false
	}
	if !game_data_validate(&data) {
		return {}, false
	}
	return data, true
}

game_data_watcher_new :: proc(path: string) -> GameDataWatcher {
	watcher := GameDataWatcher {
		path = path,
	}
	write_time, err := os.last_write_time_by_name(path)
	if err == nil {
		watcher.last_write = write_time
		watcher.valid = true
	}
	return watcher
}

game_data_hot_reload :: proc(watcher: ^GameDataWatcher, state: ^GameState) -> (reloaded: bool) {
	write_time, err := os.last_write_time_by_name(watcher.path)
	if err != nil do return false
	if watcher.valid && write_time == watcher.last_write do return false

	next, ok := game_data_load(watcher.path)
	watcher.last_write = write_time
	watcher.valid = true
	if !ok {
		fmt.eprintln("game_data: keeping previous runtime data")
		return false
	}

	game_data = next
	rl.SetTargetFPS(game_data.screen.target_fps)
	game_font_unload()
	game_font_load()
	game_apply_data_reload(state)
	fmt.eprintf("game_data: reloaded %s\n", watcher.path)
	return true
}
