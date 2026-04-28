package main

import "core:math"
import rl "vendor:raylib"

read_pressed_letter :: proc() -> (letter: rune, ok: bool) {
	for {
		ch := rl.GetCharPressed()
		if ch == 0 do return 0, false
		if ch >= 'a' && ch <= 'z' do ch -= 'a' - 'A'
		if ch >= 'A' && ch <= 'Z' do return rune(ch), true
	}
}

virtual_mouse_position :: proc() -> (position: rl.Vector2, ok: bool) {
	mouse_pos := rl.GetMousePosition()
	win_w := f32(rl.GetScreenWidth())
	win_h := f32(rl.GetScreenHeight())
	scale := math.min(win_w / f32(VIRTUAL_SCREEN_WIDTH), win_h / f32(VIRTUAL_SCREEN_HEIGHT))
	dst_w := f32(VIRTUAL_SCREEN_WIDTH) * scale
	dst_h := f32(VIRTUAL_SCREEN_HEIGHT) * scale
	dst_x := (win_w - dst_w) * 0.5
	dst_y := (win_h - dst_h) * 0.5

	if mouse_pos.x >= dst_x &&
		mouse_pos.y >= dst_y &&
		mouse_pos.x < dst_x + dst_w &&
		mouse_pos.y < dst_y + dst_h {
		position.x = (mouse_pos.x - dst_x) / scale
		position.y = (mouse_pos.y - dst_y) / scale
		return position, true
	}

	return position, false
}
