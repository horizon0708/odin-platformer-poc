package game

import fmt "core:fmt"
import "core:math"
import rl "vendor:raylib"

Solid :: struct {
	id:       i32,
	position: Vector3I,
	collider: Vector4I,
}

Vector2I :: [2]i32
Vector3I :: [3]i32
Vector4I :: [4]i32

Direction :: enum {
	LEFT,
	RIGHT,
	UP,
	DOWN,
}

Jump :: struct {
	height:        f32,
	timeToPeak:    f32,
	timeToDescent: f32,
}

CollisionInfo :: struct {
	bottom: [dynamic]i32,
	top:    [dynamic]i32,
	left:   [dynamic]i32,
	right:  [dynamic]i32,
}

Actor :: struct {
	id:        i32,
	velocity:  rl.Vector2,
	position:  Vector3I,
	remainder: rl.Vector2,
	// {offsetX, offsetY, width, height}
	collider:  Vector4I,
	jump:      Jump,
	colliding: CollisionInfo,
}

moveActorX :: proc(self: ^Actor, solids: []^Solid, x: f32) {
	self.remainder.x += x
	move := i32(math.round(self.remainder.x))

	if move != 0 {
		self.remainder.x -= f32(move)
		sign := i32(math.sign(f32(move)))
		for {
			if (move == 0) {
				break
			}
			colliding_solids := getCollidingSolidIds(self, solids, {sign, 0})
			setColliding(self, {sign, 0}, colliding_solids)
			if len(colliding_solids) == 0 {
				self.position.x += sign
				move -= sign
			} else {
				break
			}
		}
	}
}

// TODO: bitset for collision

moveActorY :: proc(self: ^Actor, solids: []^Solid, y: f32) {
	self.remainder.y += y
	move := i32(math.round(self.remainder.y))

	if move != 0 {
		self.remainder.y -= f32(move)
		sign := i32(math.sign(f32(move)))
		for {
			if (move == 0) {
				break
			}
			colliding_solids := getCollidingSolidIds(self, solids, {0, sign})
			setColliding(self, {0, sign}, colliding_solids)
			if len(colliding_solids) == 0 {

				self.position.y += sign
				move -= sign
			} else {

				break
			}
		}
	}
}

setColliding :: proc(self: ^Actor, direction: Vector2I, solids: [dynamic]i32) {
	// hmm this isn't exhuastive...

	switch direction {
	case {0, -1}:
		delete(self.colliding.top)
		self.colliding.top = solids
	case {0, 1}:
		delete(self.colliding.bottom)
		self.colliding.bottom = solids
	case {-1, 0}:
		delete(self.colliding.left)
		self.colliding.left = solids
	case {1, 0}:
		delete(self.colliding.right)
		self.colliding.right = solids
	}
}

isColliding :: proc(self: ^Actor, direction: Direction) -> bool {
	switch direction {
	case .LEFT:
		return len(self.colliding.left) > 0
	case .RIGHT:
		return len(self.colliding.right) > 0
	case .UP:
		return len(self.colliding.top) > 0
	case .DOWN:
		return len(self.colliding.bottom) > 0
	}
	return false
}

/// Returns true if the actor will collide with any solid in the given direction
// isColliding :: proc(self: ^Actor, solids: []^Solid, direction: Vector2I) -> bool {
// 	// Create a rectangle offset in the direction we want to check
// 	dir_vec := Vector3I{direction.x, direction.y, 0}
// 	check_rect := toRect(self.position + dir_vec, self.collider)

// 	// Check for collision with any solid
// 	for solid in solids {
// 		solid_rect := toRect(solid.position, solid.collider)
// 		if rl.CheckCollisionRecs(check_rect, solid_rect) {
// 			return true
// 		}
// 	}
// 	return false
// }


getCollidingSolidIds :: proc(self: ^Actor, solids: []^Solid, direction: Vector2I) -> [dynamic]i32 {
	dir_vec := Vector3I{direction.x, direction.y, 0}
	check_rect := toRect(self.position + dir_vec, self.collider)

	colliding_solids := [dynamic]i32{}
	for solid in solids {
		solid_rect := toRect(solid.position, solid.collider)
		if rl.CheckCollisionRecs(check_rect, solid_rect) {
			append_elem(&colliding_solids, solid.id)
		}
	}
	return colliding_solids
}

toRect :: proc(position: Vector3I, collider: Vector4I) -> rl.Rectangle {
	return {
		x = f32(position.x + collider.x),
		y = f32(position.y + collider.y),
		width = f32(collider.z),
		height = f32(collider.w),
	}
}
