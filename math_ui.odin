package main

import rl "vendor:raylib"

scaled_i32 :: proc(value: i32, scale: f32) -> i32 {
	scaled := i32(f32(value) * scale + 0.5)
	if scaled < 1 do return 1
	return scaled
}

grid_tile_base_height :: proc(cell_size: i32) -> i32 {
	base_height := cell_size / 10
	if base_height < 1 do base_height = 1
	return base_height
}

tile_row_step :: proc(cell_size: i32, gap: i32) -> i32 {
	return cell_size + gap + grid_tile_base_height(cell_size)
}

screen_scale :: proc(screen_width: i32, screen_height: i32) -> f32 {
	scale_x := f32(screen_width) / f32(VIRTUAL_SCREEN_WIDTH)
	scale_y := f32(screen_height) / f32(VIRTUAL_SCREEN_HEIGHT)
	if scale_y < scale_x do return scale_y
	return scale_x
}

saturate :: proc(value: f32) -> f32 {
	if value < 0 do return 0
	if value > 1 do return 1
	return value
}

ease01 :: proc(value: f32) -> f32 {
	t := saturate(value)
	return rl.EaseSineInOut(t, 0, 1, 1)
}

ease_out :: proc(value: f32) -> f32 {
	t := saturate(value)
	return rl.EaseCubicOut(t, 0, 1, 1)
}

with_alpha :: proc(color: rl.Color, alpha: u8) -> rl.Color {
	return rl.Color{color[0], color[1], color[2], alpha}
}

lerp_color :: proc(a: rl.Color, b: rl.Color, t: f32) -> rl.Color {
	v := saturate(t)
	return rl.Color {
		u8(f32(a[0]) + (f32(b[0]) - f32(a[0])) * v),
		u8(f32(a[1]) + (f32(b[1]) - f32(a[1])) * v),
		u8(f32(a[2]) + (f32(b[2]) - f32(a[2])) * v),
		u8(f32(a[3]) + (f32(b[3]) - f32(a[3])) * v),
	}
}
