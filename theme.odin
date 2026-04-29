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

THEME_COUNT :: 3

THEMES := [?]Theme {
	Theme {
		background = TAILWIND_GRAY_100,
		canvas = TAILWIND_BLACK,
		text = TAILWIND_BLACK,
		text_inverted = TAILWIND_WHITE,
		text_muted = TAILWIND_BLACK,
		outline = TAILWIND_BLACK,
		surface = TAILWIND_GRAY_200,
		surface_shadow = TAILWIND_GRAY_400,
		empty_tile = TAILWIND_GRAY_200,
		highlight_fragment = TAILWIND_BLUE_400,
		highlight_fragment_shadow = TAILWIND_BLUE_500,
		highlight_rune = TAILWIND_PURPLE_400,
		highlight_rune_shadow = TAILWIND_PURPLE_500,
		exp = TAILWIND_BLACK,
		wordle_correct = TAILWIND_GREEN_400,
		wordle_present = TAILWIND_YELLOW_400,
		wordle_miss = TAILWIND_GRAY_400,
		wordle_empty = TAILWIND_GRAY_200,
		button_fill = TAILWIND_GRAY_600,
		button_shadow = TAILWIND_GRAY_200,
		button_text = TAILWIND_BLACK,
		button_text_inverted = TAILWIND_WHITE,
	},
}
