package game

import "core:math"

import rl "vendor:raylib"

Solid :: struct {
	position: Vector3I,
	collider: Vector4I,
}

Vector2I :: [2]i32
Vector3I :: [3]i32
Vector4I :: [4]i32

Actor :: struct {
	position:  Vector3I,
	remainder: rl.Vector2,
	// {offsetX, offsetY, width, height}
	collider:  Vector4I,
}

moveActorX :: proc(self: ^Actor, solids: []Solid, x: f32) {
	self.remainder.x += x
	move := i32(math.round(self.remainder.x))

	if move != 0 {
		self.remainder.x -= f32(move)
		sign := i32(math.sign(f32(move)))
		for {
			if (move == 0) {
				break
			}
			if !isColliding(self, solids, {sign, 0}) {
				self.position.x += sign
				move -= sign
			} else {
				break
			}

		}
	}
}

moveActorY :: proc(self: ^Actor, solids: []Solid, y: f32) {
	self.remainder.y += y
	move := i32(math.round(self.remainder.y))

	if move != 0 {
		self.remainder.y -= f32(move)
		sign := i32(math.sign(f32(move)))
		for {
			if (move == 0) {
				break
			}
			if !isColliding(self, solids, {0, sign}) {
				self.position.y += sign
				move -= sign
			} else {
				break
			}
		}
	}
}

/// Returns true if the actor will collide with any solid in the given direction
isColliding :: proc(self: ^Actor, solids: []Solid, direction: Vector2I) -> bool {
	// Create a rectangle offset in the direction we want to check
	check_rect := rl.Rectangle {
		x      = f32(self.position.x + direction.x),
		y      = f32(self.position.y + direction.y),
		width  = f32(self.collider[2]),
		height = f32(self.collider[3]),
	}

	// Check for collision with any solid
	for solid in solids {
		solid_rect := rl.Rectangle {
			x      = f32(solid.position.x),
			y      = f32(solid.position.y),
			width  = f32(solid.collider[2]),
			height = f32(solid.collider[3]),
		}
		if rl.CheckCollisionRecs(check_rect, solid_rect) {
			return true
		}
	}
	return false
}
