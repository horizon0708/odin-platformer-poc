package game

import fmt "core:fmt"
import "core:math"
import rl "vendor:raylib"

MovementVariant :: union {
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
	coyoteTimer:   Timer,
}

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
	collider:      Vector4I, // {offsetX, offsetY, width, height}
	colliderColor: rl.Color,
	jump:          Jump,
	colliding:     CollisionInfo,
	touching:      map[Direction][dynamic]i32,
	wasGrounded:   bool,
}

updateMovement :: proc(entity: ^GameEntity, gameState: ^GameState) {
	dt := rl.GetFrameTime()

	switch &movement in entity.movement {
	case Actor:
		direction: rl.Vector2
		if input, ok := entity.input.(Input); ok {
			direction.x = input.directionalInput.x
		}
		// horizontal movement
		solids := getSolids(gameState)
		defer delete(solids)
		setTouchingSolids(&movement, solids[:])
		moveActorX(&movement, solids[:], direction.x * movement.velocity.x * dt)

		timerUpdate(&movement.jump.coyoteTimer, &movement, dt, proc(entity: ^Actor) {
			fmt.printf("coyote timer complete\n")
		})


		isGroundedNow := isGrounded(&movement)
		if isGroundedNow {
			timerStop(&movement.jump.coyoteTimer)
		} else if movement.wasGrounded && !isGroundedNow {
			timerStart(&movement.jump.coyoteTimer, &movement, proc(self: ^Actor) {
				fmt.printf("coyote timer started\n")
			})
		}
		movement.wasGrounded = isGroundedNow


		// vertical movement
		if isGrounded(&movement) && movement.velocity.y > 0 {
			movement.velocity.y = 0
		} else {
			movement.velocity.y += (getGravity(&movement, &entity.input) * dt)
		}
		moveActorY(&movement, solids[:], movement.velocity.y * dt)
	case Solid:
	//noop
	}
}

onJumpKeyPressed :: proc(self: ^GameEntity) {
	movement := &self.movement.(Actor)
	if isGrounded(movement) || isCoyoteTimeActive(movement) {
		movement.velocity.y = getJumpVelocity(movement)
		timerStop(&movement.jump.coyoteTimer)
	}
}

isCoyoteTimeActive :: proc(movement: ^Actor) -> bool {
	return timerIsRunning(&movement.jump.coyoteTimer)
}

getGravity :: proc(movement: ^Actor, input: ^InputVariant) -> f32 {
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
	}

	if movement.velocity.y >= 0 {
		return fallGravity
	} else if extendJump {
		return jumpGravity
	} else {
		return jumpGravity * 2.5
	}
}


isGrounded :: proc(movement: ^Actor) -> bool {
	return len(movement.touching[.DOWN]) > 0
}

getJumpVelocity :: proc(movement: ^Actor) -> f32 {
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
				// on hitting something, y velocity is reset so that
				// hitting on the head makes you immediately fall
				self.velocity.y = 0
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
