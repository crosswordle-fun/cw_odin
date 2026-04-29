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
