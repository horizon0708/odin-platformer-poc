package game

import fmt "core:fmt"
import "core:math"
import rl "vendor:raylib"

MovementVariant :: union {
	Actor,
	Solid,
}

Solid :: struct {
	id:            i32,
	position:      Vector2I,
	facing:        Direction,
	direction:     rl.Vector2,
	velocity:      rl.Vector2,
	collider:      Vector4I,
	colliderColor: rl.Color,
	collidable:    bool,
	remainder:     rl.Vector2,
}

Vector2I :: [2]i32
Vector3I :: [3]i32
Vector4I :: [4]i32

Direction :: enum {
	RIGHT,
	LEFT,
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

GunRecoil :: struct {
	groundSpeed:         f32,
	airSpeed:            f32,
	dashJumpRecoilSpeed: f32,
	timer:               Timer,
	cooldown:            Timer,
	trailColor:          rl.Color,
	trailDuration:       f64,
}

Dash :: struct {
	speed:           f32,
	airDashSpeed:    f32,
	timer:           Timer,
	cooldown:        Timer,
	trailSpawnTimer: Timer,
	trailColor:      rl.Color,
	trailDuration:   f64,
}

Speed :: union {
	LinearSpeed,
	AcceleratedSpeed,
}

LinearSpeed :: struct {
	speed: f32,
}

AcceleratedSpeed :: struct {
	acceleration: f32,
	baseSpeed:    f32,
	maxSpeed:     f32,
}

CollisionInfo :: struct {
	bottom: [dynamic]i32,
	top:    [dynamic]i32,
	left:   [dynamic]i32,
	right:  [dynamic]i32,
}

MovementState :: enum {
	IDLE,
	MOVING,
	FALLING,
	JUMPING,
	DASHING,
	DASH_JUMPING,
	DASH_JUMPING_RECOIL,
}

Actor :: struct {
	id:            i32,
	position:      Vector2I,
	facing:        Direction,
	direction:     rl.Vector2,
	xSpeed:        Speed,
	velocity:      rl.Vector2,
	remainder:     rl.Vector2,
	collider:      Vector4I, // {offsetX, offsetY, width, height}
	colliderColor: rl.Color,
	jump:          Jump,
	dash:          Dash,
	gunRecoil:     GunRecoil,
	colliding:     CollisionInfo,
	touching:      map[Direction][dynamic]i32,
	wasGrounded:   bool,
	movementState: MovementState,
}

initMovement :: proc(entity: ^GameEntity) {
	switch &movement in entity.movement {
	case Actor:
		movement.id = entity.id
		entity.facing = &movement.facing
		entity.position = &movement.position
		entity.velocity = &movement.velocity
		entity.direction = &movement.direction
	case Solid:
		movement.id = entity.id
		entity.facing = &movement.facing
		entity.position = &movement.position
		entity.velocity = &movement.velocity
		entity.direction = &movement.direction
	}
}

onFireKeyPressed :: proc(self: ^GameEntity) -> bool {
	actor := &(self.movement.(Actor))
	if actor == nil {
		return false
	}
	if !fireAvailable(actor) {
		return false
	}

	timerStart(&actor.gunRecoil.cooldown, actor, proc(self: ^Actor) {
		fmt.printf("gun recoil cooldown timer started\n")
	})
	timerStart(&actor.gunRecoil.timer, actor, proc(self: ^Actor) {
		fmt.printf("gun recoil timer started\n")
	})
	if actor.movementState == .DASH_JUMPING {
		actor.movementState = .DASH_JUMPING_RECOIL
	}
	fmt.printf("fire key pressed\n")
	return true
}

fireAvailable :: proc(self: ^Actor) -> bool {
	return !timerIsRunning(&self.gunRecoil.cooldown)
}

onDashkeyPressed :: proc(self: ^GameEntity) -> bool {
	actor := &(self.movement.(Actor))
	if actor == nil {
		return false
	}
	if !dashAvailable(actor) {
		return false
	}

	timerStart(&actor.dash.timer, actor, proc(self: ^Actor) {
		self.movementState = .DASHING
		fmt.printf("dash timer started\n")
	})
	timerStart(&actor.dash.cooldown, actor, proc(self: ^Actor) {
		fmt.printf("dash cooldown timer started\n")
	})
	fmt.printf("dash key pressed\n")
	return true
}

dashAvailable :: proc(self: ^Actor) -> bool {
	return(
		!timerIsRunning(&self.dash.timer) &&
		!timerIsRunning(&self.dash.cooldown) &&
		isGrounded(self) \
	)
}

updateVelocityX :: proc(self: ^Actor) {
	dt := rl.GetFrameTime()

	switch x in self.xSpeed {
	case LinearSpeed:
		if timerIsRunning(&self.gunRecoil.timer) {
			speed := self.gunRecoil.groundSpeed
			if !isGrounded(self) {
				speed = self.gunRecoil.airSpeed
			}
			self.velocity.x = speed * -f32(getDirectionVector(self.facing).x)
		} else if self.movementState == .DASHING {
			self.velocity.x = self.dash.speed * f32(getDirectionVector(self.facing).x)
		} else if !isGrounded(self) && self.movementState == .DASH_JUMPING {
			self.velocity.x = self.dash.airDashSpeed * self.direction.x
		} else if self.movementState == .DASH_JUMPING_RECOIL {
			self.velocity.x = self.gunRecoil.dashJumpRecoilSpeed * self.direction.x
		} else {
			self.velocity.x = x.speed * self.direction.x
		}
	case AcceleratedSpeed:
		// TODO: clamp to max speed
		// Sort out direction etc
		self.velocity.x = x.baseSpeed + x.acceleration * dt
	}
}

getTrailColor :: proc(self: ^Actor) -> rl.Color {
	if self.movementState == .DASHING || self.movementState == .DASH_JUMPING {
		return self.dash.trailColor
	} else if self.movementState == .DASH_JUMPING_RECOIL {
		return self.gunRecoil.trailColor
	}
	return rl.WHITE
}

getTrailDuration :: proc(self: ^Actor) -> f64 {
	if self.movementState == .DASHING || self.movementState == .DASH_JUMPING {
		return self.dash.trailDuration
	} else if self.movementState == .DASH_JUMPING_RECOIL {
		return self.gunRecoil.trailDuration
	}
	return 0
}

getDirectionVector :: proc(facing: Direction) -> Vector2I {
	directionVector := DirectionVector
	return directionVector[facing]
}

isDashingOrDashJumping :: proc(self: ^Actor) -> bool {
	return timerIsRunning(&self.dash.timer) || self.movementState == .DASH_JUMPING
}

updateMovement :: proc(entity: ^GameEntity, gameState: ^GameState) {
	dt := rl.GetFrameTime()

	switch &movement in entity.movement {
	case Actor:
		// horizontal movement
		solids := getSolids(gameState)
		defer delete(solids)
		setTouchingSolids(&movement, solids[:])
		updateVelocityX(&movement)

		moveActorX(&movement, solids[:], movement.velocity.x * dt)

		timerUpdate(&movement.jump.coyoteTimer, &movement, proc(entity: ^Actor) {
			fmt.printf("coyote timer complete\n")
		})
		timerUpdate(&movement.dash.timer, &movement, proc(actor: ^Actor) {
			if isGrounded(actor) {
				if actor.velocity.x != 0 {
					actor.movementState = .MOVING
				} else {
					actor.movementState = .IDLE
				}
			}
		})
		timerUpdate(&movement.dash.cooldown, &movement, proc(entity: ^Actor) {
			fmt.printf("dash cooldown timer complete\n")
		})
		timerUpdate(&movement.gunRecoil.timer, entity, proc(entity: ^GameEntity) {
			fmt.printf("gun recoil timer complete\n")
		})
		// TODO: buffer reload when not grounded
		if isGrounded(&movement) {
			timerUpdate(&movement.gunRecoil.cooldown, entity, proc(entity: ^GameEntity) {
				fmt.printf("gun recoil cooldown timer complete\n")
			})
		}
		if movement.movementState == .DASHING ||
		   movement.movementState == .DASH_JUMPING ||
		   movement.movementState == .DASH_JUMPING_RECOIL {
			timerUpdate(&movement.dash.trailSpawnTimer, &movement, proc(movement: ^Actor) {
				addTrail(movement, getTrailColor(movement), getTrailDuration(movement))
			})
		}

		// if movement.velocity.x == 0 {
		// 	movement.movementState = .IDLE
		// }

		isGroundedNow := isGrounded(&movement)
		if isGroundedNow {
			timerStop(&movement.jump.coyoteTimer)
			if movement.movementState != .DASHING {
				if movement.velocity.x != 0 {
					movement.movementState = .MOVING
				} else {
					movement.movementState = .IDLE
				}
			}
		} else if movement.wasGrounded && !isGroundedNow {
			timerStart(&movement.jump.coyoteTimer, &movement, proc(self: ^Actor) {
				fmt.printf("coyote timer started\n")
			})
			if movement.velocity.y > 0 {
				movement.movementState = .FALLING
			} else {
				movement.movementState = .JUMPING
			}
		}
		movement.wasGrounded = isGroundedNow


		// vertical movement
		if isGrounded(&movement) &&
		   movement.velocity.y > 0 &&
		   timerIsRunning(&movement.gunRecoil.timer) {
			movement.velocity.y = 0
		} else {
			movement.velocity.y += (getGravity(&movement, &entity.input) * dt)
		}
		moveActorY(&movement, solids[:], movement.velocity.y * dt)

	case Solid:
		moveSolid(entity, gameState, movement.direction * movement.velocity * dt)
	//noop
	}
}

onJumpKeyPressed :: proc(self: ^GameEntity) -> bool {
	movement := (&(self.movement.(Actor))) or_return

	if isGrounded(movement) || isCoyoteTimeActive(movement) {
		movement.velocity.y = getJumpVelocity(movement)
		timerStop(&movement.jump.coyoteTimer)

		// if player was dashing when jumping, enter dash jumping to give extra speed while jumping
		if timerIsRunning(&movement.dash.timer) {
			movement.movementState = .DASH_JUMPING
		}
		return true
	}

	return false
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

moveActorX :: proc(self: ^Actor, solids: []^GameEntity, x: f32, onCollision: proc(id: i32) = nil) {
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
				if onCollision != nil {
					onCollision(self.id)
				}
				break
			}
		}
	}
}


/*
Solids move without checking for collisions with other solids.
If it is told to move by a certain amount, it will move by that amount.
*/
moveSolid :: proc(entity: ^GameEntity, gameState: ^GameState, diff: rl.Vector2) {
	solid, ok := &entity.movement.(Solid)
	if !ok {
		return
	}

	solid.remainder.x += diff.x
	solid.remainder.y += diff.y

	moveX := i32(math.round(solid.remainder.x))
	moveY := i32(math.round(solid.remainder.y))
	actors := getActors(gameState)
	solids := getSolids(gameState)
	defer delete(actors)
	defer delete(solids)

	if moveX != 0 || moveY != 0 {

		// Make this Solid non-collidable for Actors,
		// so that Actors moved by it do not get stuck on it
		// note: not sure why this is needed yet
		// also I haven't used this to filter out collisions yet
		solid.collidable = false

		if moveX != 0 {
			solid.remainder.x -= f32(moveX)
			solid.position.x += moveX
			if (moveX > 0) {
				for &actor in actors {
					if isOverlapping(solid, actor) {
						actorMoveAmt := getColliderRight(solid) - getColliderLeft(actor)
						moveActorX(actor, solids[:], f32(actorMoveAmt), onActorSquish)
					} else if isRiding(solid, actor) {
						moveActorX(actor, solids[:], f32(moveX))
					}
				}
			} else {
				for &actor in actors {
					if isOverlapping(solid, actor) {
						actorMoveAmt := getColliderLeft(solid) - getColliderRight(actor)
						moveActorX(actor, solids[:], f32(actorMoveAmt), onActorSquish)
					} else if isRiding(solid, actor) {
						moveActorX(actor, solids[:], f32(moveX))
					}
				}
			}
		}
		if moveY != 0 {
			solid.remainder.y -= f32(moveY)
			solid.position.y += moveY
			if (moveY > 0) {
				// going down
				for &actor in actors {
					if isOverlapping(solid, actor) {
						actorMoveAmt := getColliderBottom(solid) - getColliderTop(actor)
						moveActorY(actor, solids[:], f32(actorMoveAmt), onActorSquish)
					}
					// for now, you can't ride a solid up
					// this might change if there is wall climbing
				}
			} else {
				// going up
				for &actor in actors {
					if isOverlapping(solid, actor) {
						actorMoveAmt := getColliderTop(solid) - getColliderBottom(actor)
						moveActorY(actor, solids[:], f32(actorMoveAmt), onActorSquish)
					}
				}
			}
		}

		solid.collidable = true
	}
}

isRiding :: proc(solid: ^Solid, actor: ^Actor) -> bool {
	isRiding := false
	for id in actor.touching[.DOWN] {
		if id == solid.id {
			isRiding = true
			break
		}
	}
	return isRiding
}

onActorSquish :: proc(id: i32) {
	fmt.printf("actor squished %d \n", id)
}

getColliderRight_Solid :: proc(solid: ^Solid) -> i32 {
	return solid.position.x + solid.collider.x + solid.collider.z
}

getColliderRight_Actor :: proc(actor: ^Actor) -> i32 {
	return actor.position.x + actor.collider.x + actor.collider.z
}

getColliderRight :: proc {
	getColliderRight_Solid,
	getColliderRight_Actor,
}

getColliderLeft_Solid :: proc(solid: ^Solid) -> i32 {
	return solid.position.x + solid.collider.x
}

getColliderLeft_Actor :: proc(actor: ^Actor) -> i32 {
	return actor.position.x + actor.collider.x
}


getColliderLeft :: proc {
	getColliderLeft_Solid,
	getColliderLeft_Actor,
}

getColliderBottom_Solid :: proc(solid: ^Solid) -> i32 {
	return solid.position.y + solid.collider.y + solid.collider.w
}

getColliderBottom_Actor :: proc(actor: ^Actor) -> i32 {
	return actor.position.y + actor.collider.y + actor.collider.w
}

getColliderBottom :: proc {
	getColliderBottom_Solid,
	getColliderBottom_Actor,
}

getColliderTop_Solid :: proc(solid: ^Solid) -> i32 {
	return solid.position.y + solid.collider.y
}

getColliderTop_Actor :: proc(actor: ^Actor) -> i32 {
	return actor.position.y + actor.collider.y
}

getColliderTop :: proc {
	getColliderTop_Solid,
	getColliderTop_Actor,
}

getActors :: proc(gameState: ^GameState) -> [dynamic]^Actor {
	actors := [dynamic]^Actor{}
	for _, &entity in &gameState.entities {
		movement := (&(entity.movement.(Actor))) or_continue
		append(&actors, movement)
	}
	return actors
}

// TODO: bitset for collision

moveActorY :: proc(self: ^Actor, solids: []^GameEntity, y: f32, onCollision: proc(id: i32) = nil) {
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
				if onCollision != nil {
					onCollision(self.id)
				}
				break
			}
		}
	}
}

// Touching - when the actor is touching a solid in the given direction
// Colliding - when the actor is actively trying to move into a solid in the given direction
setTouchingSolids :: proc(self: ^Actor, solids: []^GameEntity) {
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

isOverlapping :: proc(solid: ^Solid, actor: ^Actor) -> bool {
	solid_rect := toRect(solid.position, solid.collider)
	actor_rect := toRect(actor.position, actor.collider)
	return rl.CheckCollisionRecs(solid_rect, actor_rect)
}


getCollidingSolidIds :: proc(
	self: ^Actor,
	solids: []^GameEntity,
	direction: Vector2I,
) -> [dynamic]i32 {
	check_rect := toRect(self.position + direction, self.collider)

	colliding_solids := [dynamic]i32{}
	for gameEntity in solids {
		solid := (&(gameEntity.movement.(Solid))) or_continue
		solid_rect := toRect(solid.position, solid.collider)
		if rl.CheckCollisionRecs(check_rect, solid_rect) {
			append_elem(&colliding_solids, gameEntity.id)
		}
	}
	return colliding_solids
}

toRect :: proc(position: Vector2I, collider: Vector4I) -> rl.Rectangle {
	return {
		x = f32(position.x + collider.x),
		y = f32(position.y + collider.y),
		width = f32(collider.z),
		height = f32(collider.w),
	}
}
