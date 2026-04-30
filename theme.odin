package main

import rl "vendor:raylib"

Theme :: struct {
	text:       rl.Color,
	text_alt:   rl.Color,
	background: rl.Color,
	base:       rl.Color,
	outline:    rl.Color,
	absent:     rl.Color,
	present:    rl.Color,
	correct:    rl.Color,
	frag:       rl.Color,
	rune:       rl.Color,
}

theme_base_color :: proc(color: rl.Color) -> rl.Color {
	return color
}

theme_face_color :: proc(color: rl.Color) -> rl.Color {
	alpha := (u16(color[3]) * 4 + 2) / 5
	return rl.Color{color[0], color[1], color[2], u8(alpha)}
}
