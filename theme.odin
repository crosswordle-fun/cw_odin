package main

import rl "vendor:raylib"

Theme :: struct {
	background:                rl.Color,
	canvas:                    rl.Color,
	text:                      rl.Color,
	text_inverted:             rl.Color,
	text_muted:                rl.Color,
	outline:                   rl.Color,
	surface:                   rl.Color,
	surface_shadow:            rl.Color,
	empty_tile:                rl.Color,
	highlight_fragment:        rl.Color,
	highlight_fragment_shadow: rl.Color,
	highlight_rune:            rl.Color,
	highlight_rune_shadow:     rl.Color,
	exp:                       rl.Color,
	wordle_correct:            rl.Color,
	wordle_present:            rl.Color,
	wordle_miss:               rl.Color,
	wordle_empty:              rl.Color,
	button_fill:               rl.Color,
	button_shadow:             rl.Color,
	button_text:               rl.Color,
	button_text_inverted:      rl.Color,
}
