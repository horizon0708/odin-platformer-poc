package game

import rl "vendor:raylib"

to_vector2i_int :: proc(vector: [2]int) -> Vector2I {
	return {i32(vector[0]), i32(vector[1])}
}
to_vector2i_f32 :: proc(vector: rl.Vector2) -> Vector2I {
	return {i32(vector.x), i32(vector.y)}
}
to_vector2i :: proc {
	to_vector2i_int,
	to_vector2i_f32,
}

to_vector2_i32 :: proc(vector: Vector2I) -> rl.Vector2 {
	return {f32(vector[0]), f32(vector[1])}
}
to_vector2_int :: proc(vector: [2]int) -> rl.Vector2 {
	return {f32(vector[0]), f32(vector[1])}
}
to_vector2 :: proc {
	to_vector2_i32,
	to_vector2_int,
}
