package main

import rl "vendor:raylib"

read_pressed_letter :: proc() -> (letter: rune, ok: bool) {
	for {
		ch := rl.GetCharPressed()
		if ch == 0 do return 0, false
		if ch >= 'a' && ch <= 'z' do ch -= 'a' - 'A'
		if ch >= 'A' && ch <= 'Z' do return rune(ch), true
	}
}

input_shift_pressed :: proc() -> bool {
	return(
		rl.IsKeyPressed(rl.KeyboardKey.LEFT_SHIFT) ||
		rl.IsKeyPressed(rl.KeyboardKey.RIGHT_SHIFT) \
	)
}

input_read_letters_to_selector_buffer :: proc(selector_buffer: ^SelectorBuffer) {
	for {
		letter, ok := read_pressed_letter()
		if !ok do break
		selector_buffer_push_letter(selector_buffer, letter)
	}
}

input_read_letters_to_wordle :: proc(wordle: ^WordleState) {
	for {
		letter, ok := read_pressed_letter()
		if !ok do break
		wordle_push_letter(wordle, letter)
	}
}

input_read_letters_to_crafting :: proc(crafting: ^CraftingState, frag_counts: Frags) {
	for {
		letter, ok := read_pressed_letter()
		if !ok do break
		crafting_push_letter(crafting, frag_counts, letter)
	}
}
