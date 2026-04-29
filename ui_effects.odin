package main

import "core:fmt"
import "core:math"
import rl "vendor:raylib"

VIEW_TRANSITION_DURATION :: f32(0.34)

ui_state_new :: proc(view: GameView, exp: u32) -> UiState {
	return UiState{previous_view = view, wordle_reveal_guess_row = -1, last_exp = exp}
}

ui_update :: proc(state: ^GameState, dt: f32) {
	frame_dt := dt
	if frame_dt < 0 do frame_dt = 0
	if frame_dt > 0.05 do frame_dt = 0.05

	state.ui.dt = frame_dt
	state.ui.time += frame_dt

	if state.exp > state.ui.last_exp {
		state.ui.exp_gain += state.exp - state.ui.last_exp
		state.ui.exp_gain_age = 0
	}
	state.ui.last_exp = state.exp

	state.ui.exp_gain_age += frame_dt
	state.ui.invalid_age += frame_dt
	state.ui.wordle_reveal_age += frame_dt
	state.ui.crafted_rune_age += frame_dt

	for i in 0 ..< len(state.ui.particles) {
		if !state.ui.particles[i].active do continue
		state.ui.particles[i].age += frame_dt
		if state.ui.particles[i].age >= state.ui.particles[i].lifetime {
			state.ui.particles[i].active = false
			continue
		}
		state.ui.particles[i].x += state.ui.particles[i].vx * frame_dt
		state.ui.particles[i].y += state.ui.particles[i].vy * frame_dt
		state.ui.particles[i].vy += 34 * frame_dt
		state.ui.particles[i].rotation += state.ui.particles[i].spin * frame_dt
	}

	for i in 0 ..< len(state.ui.floating_text) {
		if !state.ui.floating_text[i].active do continue
		state.ui.floating_text[i].age += frame_dt
		if state.ui.floating_text[i].age >= state.ui.floating_text[i].lifetime {
			state.ui.floating_text[i].active = false
		}
	}

	for i in 0 ..< len(state.ui.tile_pops) {
		if !state.ui.tile_pops[i].active do continue
		state.ui.tile_pops[i].age += frame_dt
		if state.ui.tile_pops[i].age >= 0.5 {
			state.ui.tile_pops[i].active = false
		}
	}
}

ui_note_view_change :: proc(ui: ^UiState, previous: GameView) {
	ui.previous_view = previous
	ui.previous_view_enter_time = ui.view_enter_time
	ui.view_enter_time = ui.time
	ui.invalid_age = 1
}

gameplay_view_index :: proc(view: GameView) -> i32 {
	switch view {
	case .Cross:
		return 0
	case .Wordle:
		return 1
	case .Crafting:
		return 2
	case .Menu:
		return -1
	}
	return -1
}

ui_view_transition_active :: proc(ui: UiState) -> bool {
	return ui.time - ui.view_enter_time < VIEW_TRANSITION_DURATION
}

ui_view_transition_offsets :: proc(
	ui: UiState,
	current_view: GameView,
	screen_width: i32,
	screen_height: i32,
) -> (
	previous_offset: rl.Vector2,
	current_offset: rl.Vector2,
) {
	age := ui.time - ui.view_enter_time
	if age >= VIEW_TRANSITION_DURATION || ui.previous_view == current_view {
		return rl.Vector2{0, 0}, rl.Vector2{0, 0}
	}

	t := rl.EaseCubicOut(saturate(age / VIEW_TRANSITION_DURATION), 0, 1, 1)
	previous_start := rl.Vector2{0, 0}
	previous_end := rl.Vector2{0, 0}
	current_start := rl.Vector2{0, 0}
	current_end := rl.Vector2{0, 0}

	previous_index := gameplay_view_index(ui.previous_view)
	current_index := gameplay_view_index(current_view)
	if ui.previous_view == .Menu && current_view != .Menu {
		previous_end = rl.Vector2{0, -f32(screen_height)}
		current_start = rl.Vector2{0, f32(screen_height)}
	} else if ui.previous_view != .Menu && current_view == .Menu {
		previous_end = rl.Vector2{0, f32(screen_height)}
		current_start = rl.Vector2{0, -f32(screen_height)}
	} else if previous_index >= 0 && current_index >= 0 {
		direction := f32(1)
		if current_index < previous_index do direction = -1
		previous_end = rl.Vector2{-direction * f32(screen_width), 0}
		current_start = rl.Vector2{direction * f32(screen_width), 0}
	}

	return rl.Vector2 {
		rl.Lerp(previous_start.x, previous_end.x, t),
		rl.Lerp(previous_start.y, previous_end.y, t),
	}, rl.Vector2{rl.Lerp(current_start.x, current_end.x, t), rl.Lerp(current_start.y, current_end.y, t)}
}

ui_note_invalid :: proc(ui: ^UiState) {
	ui.invalid_age = 0
}

ui_note_wordle_guess :: proc(ui: ^UiState, guess_row: i32) {
	ui.wordle_reveal_guess_row = guess_row
	ui.wordle_reveal_age = 0
}

ui_note_crafted_rune :: proc(ui: ^UiState) {
	ui.crafted_rune_age = 0
}

ui_spawn_floating_exp :: proc(ui: ^UiState, amount: u32, x: f32, y: f32, color: rl.Color) {
	for i in 0 ..< len(ui.floating_text) {
		if ui.floating_text[i].active do continue
		ui.floating_text[i] = UiFloatingText {
			active   = true,
			amount   = amount,
			x        = x,
			y        = y,
			lifetime = 1.2,
			color    = color,
		}
		return
	}
}

ui_spawn_burst :: proc(ui: ^UiState, x: f32, y: f32, color: rl.Color, count: i32) {
	for n in 0 ..< count {
		slot := -1
		for i in 0 ..< len(ui.particles) {
			if !ui.particles[i].active {
				slot = i
				break
			}
		}
		if slot < 0 do return

		angle := f32(rl.GetRandomValue(0, 628)) / 100.0
		speed := f32(rl.GetRandomValue(42, 126))
		life := f32(rl.GetRandomValue(45, 95)) / 100.0
		size := f32(rl.GetRandomValue(3, 8))
		ui.particles[slot] = UiParticle {
			active   = true,
			kind     = .Sparkle,
			x        = x,
			y        = y,
			vx       = math.cos(angle) * speed,
			vy       = math.sin(angle) * speed - 38,
			lifetime = life,
			size     = size,
			rotation = f32(rl.GetRandomValue(0, 360)),
			spin     = f32(rl.GetRandomValue(-220, 220)),
			color    = color,
		}
	}
}

ui_note_exp_reward :: proc(ui: ^UiState, amount: u32, x: f32, y: f32, color: rl.Color) {
	ui.exp_gain_age = 0
	ui_spawn_floating_exp(ui, amount, x, y, color)
	ui_spawn_burst(ui, x, y, color, 18)
}

ui_note_tile_pop :: proc(ui: ^UiState, key: i32) {
	free_slot := -1
	for i in 0 ..< len(ui.tile_pops) {
		if ui.tile_pops[i].active && ui.tile_pops[i].key == key {
			ui.tile_pops[i].age = 0
			return
		}
		if !ui.tile_pops[i].active && free_slot < 0 do free_slot = i
	}
	if free_slot >= 0 {
		ui.tile_pops[free_slot] = UiTilePop {
			active = true,
			key    = key,
		}
	}
}

ui_tile_pop_scale :: proc(ui: UiState, key: i32) -> f32 {
	for i in 0 ..< len(ui.tile_pops) {
		if !ui.tile_pops[i].active || ui.tile_pops[i].key != key do continue
		age := ui.tile_pops[i].age
		if age < 0.24 {
			return 0.82 + rl.EaseBackOut(age, 0, 0.28, 0.24)
		}
		settle := saturate((age - 0.24) / 0.22)
		return 1.10 + (1.0 - 1.10) * ease_out(settle)
	}
	return 1
}

ui_invalid_shake_x :: proc(ui: UiState, strength: f32) -> f32 {
	if ui.invalid_age >= 0.34 do return 0
	t := ui.invalid_age / 0.34
	return math.sin(ui.invalid_age * 92) * (1 - t) * strength
}

ui_view_transition_offset_y :: proc(ui: UiState, scale: f32) -> i32 {
	age := ui.time - ui.view_enter_time
	if age >= 0.32 do return 0
	t := ease_out(age / 0.32)
	return i32((1 - t) * 18 * scale)
}

ui_view_transition_alpha :: proc(ui: UiState) -> u8 {
	age := ui.time - ui.view_enter_time
	if age >= 0.32 do return 255
	return u8(255 * ease_out(age / 0.32))
}

draw_ui_effects :: proc(buffer: ^RenderBuffer, ctx: RenderContext, ui: UiState) {
	for i in 0 ..< len(ui.particles) {
		particle := ui.particles[i]
		if !particle.active do continue
		t := particle.age / particle.lifetime
		alpha := u8(220 * (1 - saturate(t)))
		color := with_alpha(particle.color, alpha)
		push_poly(buffer, particle.x, particle.y, 4, particle.size, particle.rotation, color, true)
	}

	for i in 0 ..< len(ui.floating_text) {
		text := ui.floating_text[i]
		if !text.active do continue
		t := saturate(text.age / text.lifetime)
		y := text.y - ease_out(t) * 44
		alpha := u8(255 * (1 - t))
		label := fmt.caprintf("+%d EXP", text.amount)
		font_size := scaled_i32(BASE_HUD_FONT_SIZE, ctx.scale)
		push_text(
			buffer,
			label,
			i32(text.x) - measure_text_width(label, font_size) / 2,
			i32(y),
			font_size,
			with_alpha(text.color, alpha),
		)
	}
}

draw_view_transition :: proc(buffer: ^RenderBuffer, ctx: RenderContext, ui: UiState) {
	age := ui.time - ui.view_enter_time
	if age >= VIEW_TRANSITION_DURATION do return
	alpha := u8(120 * (1 - ease_out(age / 0.28)))
	push_rect(
		buffer,
		0,
		0,
		ctx.screen_width,
		ctx.screen_height,
		with_alpha(ctx.theme.background, alpha),
	)
}
