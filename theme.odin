package main

import rl "vendor:raylib"

Theme :: struct {
	background:                rl.Color,
	canvas:                    rl.Color,
	text:                      rl.Color,
	text_inverted:             rl.Color,
	text_muted:                rl.Color,
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

THEME_COUNT :: 5

THEMES := [?]Theme {
	Theme {
		background = rl.Color{20, 20, 24, 255},
		canvas = rl.BLACK,
		text = rl.WHITE,
		text_inverted = rl.Color{20, 20, 24, 255},
		text_muted = rl.LIGHTGRAY,
		surface = rl.GRAY,
		surface_shadow = rl.DARKGRAY,
		empty_tile = rl.DARKGRAY,
		highlight_fragment = rl.SKYBLUE,
		highlight_fragment_shadow = rl.DARKBLUE,
		highlight_rune = rl.PURPLE,
		highlight_rune_shadow = rl.DARKPURPLE,
		exp = rl.GOLD,
		wordle_correct = rl.GREEN,
		wordle_present = rl.GOLD,
		wordle_miss = rl.GRAY,
		wordle_empty = rl.DARKGRAY,
		button_fill = rl.WHITE,
		button_shadow = rl.Color{20, 20, 24, 255},
		button_text = rl.WHITE,
		button_text_inverted = rl.Color{20, 20, 24, 255},
	},
}

