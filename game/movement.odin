package game

import fmt "core:fmt"
import "core:math"
import rl "vendor:raylib"

Movement :: union {
	Actor,
	Solid,
}

Solid :: struct {
	using entity:  Entity,
	position:      Vector3I,
	collider:      Vector4I,
	colliderColor: rl.Color,
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

DirectionVector :: [Direction]Vector2I {
	.LEFT  = {-1, 0},
	.RIGHT = {1, 0},
	.UP    = {0, -1},
	.DOWN  = {0, 1},
}

Jump :: struct {
	height:        f32,
	timeToPeak:    f32,
	timeToDescent: f32,
}

InputVariant :: union {
	NoInput,
	Input,
}

Input :: struct {
	jumpHeldDown:     bool,
	jumpKeyPressed:   bool,
	directionalInput: rl.Vector2,
}

NoInput :: struct {}

CollisionInfo :: struct {
	bottom: [dynamic]i32,
	top:    [dynamic]i32,
	left:   [dynamic]i32,
	right:  [dynamic]i32,
}

Actor :: struct {
	velocity:      rl.Vector2,
	position:      Vector3I,
	remainder:     rl.Vector2,
	// {offsetX, offsetY, width, height}
	collider:      Vector4I,
	colliderColor: rl.Color,
	jump:          Jump,
	colliding:     CollisionInfo,
	touching:      map[Direction][dynamic]i32,
}

moveX :: proc(self: ^GameEntity, solids: []^Solid, x: f32) {
	switch &movement in self.movement {
	case Actor:
		movement.remainder.x += x
		move := i32(math.round(movement.remainder.x))

		if move != 0 {
			movement.remainder.x -= f32(move)
			sign := i32(math.sign(f32(move)))
			for {
				if (move == 0) {
					break
				}
				// Q: do we need this when we now have touching field?
				colliding_solids := getCollidingSolidIds(&movement, solids, {sign, 0})
				if len(colliding_solids) == 0 {
					movement.position.x += sign
					move -= sign
				} else {
					break
				}
			}
		}
	case Solid:
	}
}


getGravity2 :: proc(movement: ^Actor, input: ^InputVariant) -> f32 {
	assert(movement.jump.height > 0)
	assert(movement.jump.timeToPeak > 0)
	assert(movement.jump.timeToDescent > 0)


	jumpGravity :=
		(2.0 * movement.jump.height) / (movement.jump.timeToPeak * movement.jump.timeToPeak)
	fallGravity :=
		(2.0 * movement.jump.height) / (movement.jump.timeToDescent * movement.jump.timeToDescent)

	extendJump := false
	if input, ok := input.(Input); ok {
		extendJump = input.jumpHeldDown
		// fmt.printf("extendJump: %v\n", extendJump)
	}

	if movement.velocity.y >= 0 {
		return fallGravity
	} else if extendJump {
		return jumpGravity
	} else {
		return jumpGravity * 2.5
	}
}


isGrounded2 :: proc(movement: ^Actor) -> bool {
	return len(movement.touching[.DOWN]) > 0
}

getJumpVelocity2 :: proc(movement: ^Actor) -> f32 {
	return (-2.0 * movement.jump.height) / movement.jump.timeToPeak
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
			// Q: do we need this when we now have touching field?
			colliding_solids := getCollidingSolidIds(self, solids, {sign, 0})
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
			if len(colliding_solids) == 0 {
				self.position.y += sign
				move -= sign
			} else {

				break
			}
		}
	}
}

// Touching - when the actor is touching a solid in the given direction
// Colliding - when the actor is actively trying to move into a solid in the given direction
setTouchingSolids :: proc(self: ^Actor, solids: []^Solid) {
	for direction in Direction {
		// Q: why do I have to do this?
		vectors := DirectionVector
		dir_vec := vectors[direction]
		self.touching[direction] = getCollidingSolidIds(self, solids, dir_vec)
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
