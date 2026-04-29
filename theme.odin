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

THEME_COUNT :: 1

THEMES := [?]Theme {
	Theme {
		background = rl.Color{250, 239, 216, 255},
		canvas = rl.Color{74, 55, 43, 255},
		text = rl.Color{71, 50, 39, 255},
		text_inverted = rl.Color{255, 248, 229, 255},
		text_muted = rl.Color{128, 101, 82, 255},
		surface = rl.Color{255, 246, 224, 255},
		surface_shadow = rl.Color{205, 164, 116, 255},
		empty_tile = rl.Color{226, 211, 184, 255},
		highlight_fragment = rl.Color{113, 173, 190, 255},
		highlight_fragment_shadow = rl.Color{66, 123, 143, 255},
		highlight_rune = rl.Color{151, 87, 120, 255},
		highlight_rune_shadow = rl.Color{104, 54, 80, 255},
		exp = rl.Color{210, 143, 43, 255},
		wordle_correct = rl.Color{112, 157, 103, 255},
		wordle_present = rl.Color{200, 153, 75, 255},
		wordle_miss = rl.Color{158, 146, 129, 255},
		wordle_empty = rl.Color{238, 226, 203, 255},
		button_fill = rl.Color{116, 151, 143, 255},
		button_shadow = rl.Color{172, 134, 94, 255},
		button_text = rl.Color{71, 50, 39, 255},
		button_text_inverted = rl.Color{255, 248, 229, 255},
	},
}
