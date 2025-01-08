package game

import fmt "core:fmt"
import "core:math"
import rl "vendor:raylib"

Movement :: struct {
	variant:       MovementVariant,
	entityId:      i32,
	position:      Vector2I,
	facing:        Direction,
	direction:     rl.Vector2,
	velocity:      rl.Vector2,
	remainder:     rl.Vector2,
	collider:      Collider,
	movementState: MovementState,
}

Collider :: struct {
	offset:   Vector2I,
	size:     Vector2I,
	color:    rl.Color,
	disabled: bool,
}

MovementVariant :: union {
	Actor,
	Solid,
}

Solid :: struct {}

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
	xSpeed:      Speed,
	jump:        Jump,
	dash:        Dash,
	gunRecoil:   GunRecoil,
	colliding:   CollisionInfo,
	touching:    map[Direction][dynamic]i32,
	wasGrounded: bool,
}

initMovement :: proc(entity: ^GameEntity) {
	entity.movement.entityId = entity.id
}

onFireKeyPressed :: proc(self: ^GameEntity) -> bool {
	actor := &(self.movement.variant.(Actor))
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
	if self.movement.movementState == .DASH_JUMPING {
		self.movement.movementState = .DASH_JUMPING_RECOIL
	}
	fmt.printf("fire key pressed\n")
	return true
}

fireAvailable :: proc(self: ^Actor) -> bool {
	return !timerIsRunning(&self.gunRecoil.cooldown)
}

onDashkeyPressed :: proc(self: ^GameEntity) -> bool {
	actor := &(self.movement.variant.(Actor))
	if actor == nil {
		return false
	}
	if !dashAvailable(actor) {
		return false
	}

	timerStart(&actor.dash.timer, self, proc(self: ^GameEntity) {
		self.movement.movementState = .DASHING
		fmt.printf("dash timer started\n")
	})
	timerStart(&actor.dash.cooldown, self, proc(self: ^GameEntity) {
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

updateVelocityX :: proc(self: ^GameEntity) {
	dt := rl.GetFrameTime()
	actor, ok := &self.movement.variant.(Actor)
	if !ok {
		return
	}


	switch x in actor.xSpeed {
	case LinearSpeed:
		if timerIsRunning(&actor.gunRecoil.timer) {
			speed := actor.gunRecoil.groundSpeed
			if !isGrounded(actor) {
				speed = actor.gunRecoil.airSpeed
			}
			self.movement.velocity.x = speed * -f32(getDirectionVector(self.movement.facing).x)
		} else if self.movement.movementState == .DASHING {
			self.movement.velocity.x =
				actor.dash.speed * f32(getDirectionVector(self.movement.facing).x)
		} else if !isGrounded(actor) && self.movement.movementState == .DASH_JUMPING {
			self.movement.velocity.x = actor.dash.airDashSpeed * self.movement.direction.x
		} else if self.movement.movementState == .DASH_JUMPING_RECOIL {
			self.movement.velocity.x =
				actor.gunRecoil.dashJumpRecoilSpeed * self.movement.direction.x
		} else {
			self.movement.velocity.x = x.speed * self.movement.direction.x
		}
	case AcceleratedSpeed:
		// TODO: clamp to max speed
		// Sort out direction etc
		self.movement.velocity.x = x.baseSpeed + x.acceleration * dt
	}
}

getTrailColor :: proc(entity: ^GameEntity) -> rl.Color {
	actor := &entity.movement.variant.(Actor)
	if entity.movement.movementState == .DASHING ||
	   entity.movement.movementState == .DASH_JUMPING {
		return actor.dash.trailColor
	} else if entity.movement.movementState == .DASH_JUMPING_RECOIL {
		return actor.gunRecoil.trailColor
	}
	return rl.WHITE
}

getTrailDuration :: proc(entity: ^GameEntity) -> f64 {
	actor := &entity.movement.variant.(Actor)
	if entity.movement.movementState == .DASHING ||
	   entity.movement.movementState == .DASH_JUMPING {
		return actor.dash.trailDuration
	} else if entity.movement.movementState == .DASH_JUMPING_RECOIL {
		return actor.gunRecoil.trailDuration
	}
	return 0
}

getDirectionVector :: proc(facing: Direction) -> Vector2I {
	directionVector := DirectionVector
	return directionVector[facing]
}

isDashingOrDashJumping :: proc(entity: ^GameEntity) -> bool {
	actor := &entity.movement.variant.(Actor)
	if actor == nil {
		return false
	}

	return timerIsRunning(&actor.dash.timer) || entity.movement.movementState == .DASH_JUMPING
}

updateMovement :: proc(entity: ^GameEntity, gameState: ^GameState) {
	dt := rl.GetFrameTime()

	switch &movement in entity.movement.variant {
	case Actor:
		// horizontal movement
		solids := getSolids(gameState)
		defer delete(solids)
		set_touching_solids(entity, solids[:])
		updateVelocityX(entity)
		moveActorX(entity, solids[:], entity.movement.velocity.x * dt)
		// fmt.printf("direction %v\n", entity.movement.direction)

		timerUpdate(&movement.jump.coyoteTimer, &movement, proc(entity: ^Actor) {
			fmt.printf("coyote timer complete\n")
		})
		timerUpdate(&movement.dash.timer, entity, proc(entity: ^GameEntity) {
			actor := &entity.movement.variant.(Actor)
			if isGrounded(actor) {
				if entity.movement.velocity.x != 0 {
					entity.movement.movementState = .MOVING
				} else {
					entity.movement.movementState = .IDLE
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
		if entity.movement.movementState == .DASHING ||
		   entity.movement.movementState == .DASH_JUMPING ||
		   entity.movement.movementState == .DASH_JUMPING_RECOIL {
			timerUpdate(&movement.dash.trailSpawnTimer, entity, proc(entity: ^GameEntity) {
				addTrail(entity, getTrailColor(entity), getTrailDuration(entity))
			})
		}

		// if movement.velocity.x == 0 {
		// 	movement.movementState = .IDLE
		// }

		isGroundedNow := isGrounded(&movement)
		if isGroundedNow {
			timerStop(&movement.jump.coyoteTimer)
			if entity.movement.movementState != .DASHING {
				if entity.movement.velocity.x != 0 {
					entity.movement.movementState = .MOVING
				} else {
					entity.movement.movementState = .IDLE
				}
			}
		} else if movement.wasGrounded && !isGroundedNow {
			timerStart(&movement.jump.coyoteTimer, &movement, proc(self: ^Actor) {
				fmt.printf("coyote timer started\n")
			})
			if entity.movement.velocity.y > 0 {
				entity.movement.movementState = .FALLING
			} else {
				entity.movement.movementState = .JUMPING
			}
		}
		movement.wasGrounded = isGroundedNow


		// vertical movement
		if isGrounded(&movement) &&
		   entity.movement.velocity.y > 0 &&
		   timerIsRunning(&movement.gunRecoil.timer) {
			entity.movement.velocity.y = 0
		} else {
			entity.movement.velocity.y += (getGravity(entity) * dt)
		}
		moveActorY(entity, solids[:], entity.movement.velocity.y * dt)

	case Solid:
		moveSolid(entity, gameState, entity.movement.direction * entity.movement.velocity * dt)
	//noop
	}
}

onJumpKeyPressed :: proc(self: ^GameEntity) -> bool {
	movement := (&(self.movement.variant.(Actor))) or_return

	if isGrounded(movement) || isCoyoteTimeActive(movement) {
		self.movement.velocity.y = getJumpVelocity(movement)
		timerStop(&movement.jump.coyoteTimer)

		// if player was dashing when jumping, enter dash jumping to give extra speed while jumping
		if timerIsRunning(&movement.dash.timer) {
			self.movement.movementState = .DASH_JUMPING
		}
		return true
	}

	return false
}

isCoyoteTimeActive :: proc(movement: ^Actor) -> bool {
	return timerIsRunning(&movement.jump.coyoteTimer)
}

getGravity :: proc(entity: ^GameEntity) -> f32 {
	actor, ok := &entity.movement.variant.(Actor)
	if !ok {
		return 0
	}


	assert(actor.jump.height > 0)
	assert(actor.jump.timeToPeak > 0)
	assert(actor.jump.timeToDescent > 0)


	jumpGravity := (2.0 * actor.jump.height) / (actor.jump.timeToPeak * actor.jump.timeToPeak)
	fallGravity :=
		(2.0 * actor.jump.height) / (actor.jump.timeToDescent * actor.jump.timeToDescent)

	extendJump := false
	input, input_ok := &entity.input.variant.(PlayerInput)
	if input_ok {
		extendJump = input.jumpHeldDown
	}

	if entity.movement.velocity.y >= 0 {
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

moveActorX :: proc(
	entitiy: ^GameEntity,
	solids: []^GameEntity,
	x: f32,
	onCollision: proc(id: i32) = nil,
) {
	actor := &entitiy.movement.variant.(Actor)
	if actor == nil {
		return
	}
	movement := &entitiy.movement

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
			colliding_solids := get_colliding_solid_ids(entitiy, solids, {sign, 0})
			if len(colliding_solids) == 0 {
				movement.position.x += sign
				move -= sign
			} else {
				if onCollision != nil {
					onCollision(entitiy.id)
				}
				break
			}
		}
	}
}

moveActorY :: proc(
	self: ^GameEntity,
	solids: []^GameEntity,
	y: f32,
	onCollision: proc(id: i32) = nil,
) {
	actor := &self.movement.variant.(Actor)
	if actor == nil {
		return
	}

	self.movement.remainder.y += y
	move := i32(math.round(self.movement.remainder.y))

	if move != 0 {
		self.movement.remainder.y -= f32(move)
		sign := i32(math.sign(f32(move)))
		for {
			if (move == 0) {
				break
			}
			colliding_solids := get_colliding_solid_ids(self, solids, {0, sign})
			if len(colliding_solids) == 0 {
				self.movement.position.y += sign
				move -= sign
			} else {
				// on hitting something, y velocity is reset so that
				// hitting on the head makes you immediately fall
				self.movement.velocity.y = 0
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
	solid := &entity.movement.variant.(Solid)
	if solid == nil {
		return
	}
	movement := &entity.movement

	movement.remainder.x += diff.x
	movement.remainder.y += diff.y

	moveX := i32(math.round(movement.remainder.x))
	moveY := i32(math.round(movement.remainder.y))
	actors := getActors(gameState)
	solids := getSolids(gameState)
	defer delete(actors)
	defer delete(solids)

	if moveX != 0 || moveY != 0 {

		// Make this Solid non-collidable for Actors,
		// so that Actors moved by it do not get stuck on it
		// note: not sure why this is needed yet
		// also I haven't used this to filter out collisions yet
		movement.collider.disabled = true

		solidBounds := getColliderBounds(entity)

		if moveX != 0 {
			movement.remainder.x -= f32(moveX)
			movement.position.x += moveX
			if (moveX > 0) {
				for &actor_entity in actors {
					actor, ok := &actor_entity.movement.variant.(Actor)
					if !ok {
						continue
					}

					actorBounds := getColliderBounds(actor_entity)
					if isOverlapping(entity, actor_entity) {
						actorMoveAmt := solidBounds.right - actorBounds.left
						moveActorX(actor_entity, solids[:], f32(actorMoveAmt), onActorSquish)
					} else if isRiding(entity, actor) {
						moveActorX(actor_entity, solids[:], f32(moveX))
					}
				}
			} else {
				for &actor_entity in actors {
					actor, ok := &actor_entity.movement.variant.(Actor)
					if !ok {
						continue
					}

					actorBounds := getColliderBounds(actor_entity)
					if isOverlapping(entity, actor_entity) {
						actorMoveAmt := solidBounds.left - actorBounds.right
						moveActorX(actor_entity, solids[:], f32(actorMoveAmt), onActorSquish)
					} else if isRiding(entity, actor) {
						moveActorX(actor_entity, solids[:], f32(moveX))
					}
				}
			}
		}
		if moveY != 0 {
			movement.remainder.y -= f32(moveY)
			movement.position.y += moveY
			if (moveY > 0) {
				// going down
				for &actor_entity in actors {
					if isOverlapping(entity, actor_entity) {
						actorBounds := getColliderBounds(actor_entity)
						// actorMoveAmt := getColliderBottom(solid) - getColliderTop(actor)
						actorMoveAmt := solidBounds.bottom - actorBounds.top
						moveActorY(actor_entity, solids[:], f32(actorMoveAmt), onActorSquish)
					}
					// for now, you can't ride a solid up
					// this might change if there is wall climbing
				}
			} else {
				// going up
				for &actor_entity in actors {
					if isOverlapping(entity, actor_entity) {
						actorBounds := getColliderBounds(actor_entity)
						actorMoveAmt := solidBounds.top - actorBounds.bottom
						moveActorY(actor_entity, solids[:], f32(actorMoveAmt), onActorSquish)
					}
				}
			}
		}

		movement.collider.disabled = false
	}
}

isRiding :: proc(entity: ^GameEntity, actor: ^Actor) -> bool {
	isRiding := false
	for id in actor.touching[.DOWN] {
		if id == entity.id {
			isRiding = true
			break
		}
	}
	return isRiding
}

onActorSquish :: proc(id: i32) {
	fmt.printf("actor squished %d \n", id)
}


Bounds :: struct {
	left:   i32,
	right:  i32,
	top:    i32,
	bottom: i32,
}

/**
left, right, top, bottom
*/
getColliderBounds :: proc(entity: ^GameEntity) -> Bounds {
	left := entity.movement.position.x + entity.movement.collider.offset.x
	right := left + entity.movement.collider.size.x
	top := entity.movement.position.y + entity.movement.collider.offset.y
	bottom := top + entity.movement.collider.size.y
	return Bounds{left, right, top, bottom}
}

getActors :: proc(gameState: ^GameState) -> [dynamic]^GameEntity {
	actors := [dynamic]^GameEntity{}
	for _, &entity in &gameState.entities {
		movement := (&(entity.movement.variant.(Actor))) or_continue
		append(&actors, &entity)
	}
	return actors
}

// TODO: bitset for collision


// Touching - when the actor is touching a solid in the given direction
// Colliding - when the actor is actively trying to move into a solid in the given direction
set_touching_solids :: proc(entity: ^GameEntity, solids: []^GameEntity) {
	for direction in Direction {
		// Q: why do I have to do this?
		vectors := DirectionVector
		dir_vec := vectors[direction]
		if actor, ok := &entity.movement.variant.(Actor); ok {
			actor.touching[direction] = get_colliding_solid_ids(entity, solids, dir_vec)
		}
	}
}


isOverlapping :: proc(entity: ^GameEntity, entity2: ^GameEntity) -> bool {
	rect1 := to_rect(entity)
	rect2 := to_rect(entity2)
	return rl.CheckCollisionRecs(rect1, rect2)
}

getSolids :: proc(gameState: ^GameState) -> [dynamic]^GameEntity {
	solids := make([dynamic]^GameEntity)
	for _, &entity in gameState.entities {
		if solid, ok := &entity.movement.variant.(Solid); ok {
			append_elem(&solids, &entity)
		}
	}
	return solids
}


get_colliding_solid_ids :: proc(
	entity: ^GameEntity,
	solids: []^GameEntity,
	direction: Vector2I,
) -> [dynamic]i32 {
	movement := &entity.movement.variant.(Actor)
	if movement == nil {
		return [dynamic]i32{}
	}

	check_rect := to_rect(entity, direction)

	colliding_solids := [dynamic]i32{}
	for solid_entity in solids {
		solid, ok := &(solid_entity.movement.variant.(Solid))
		if !ok {
			continue
		}
		solid_rect := to_rect(solid_entity)
		if rl.CheckCollisionRecs(check_rect, solid_rect) {
			append_elem(&colliding_solids, solid_entity.id)
		}
	}
	return colliding_solids
}

to_rect :: proc(entity: ^GameEntity, offset: Vector2I = {0, 0}) -> rl.Rectangle {
	return {
		x = f32(entity.movement.position.x + entity.movement.collider.offset.x + offset.x),
		y = f32(entity.movement.position.y + entity.movement.collider.offset.y + offset.y),
		width = f32(entity.movement.collider.size.x),
		height = f32(entity.movement.collider.size.y),
	}
}
