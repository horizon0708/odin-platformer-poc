package game

// core
import fmt "core:fmt"
import "core:math"
import "core:math/linalg"
import "core:strings"

// vendor
import rl "vendor:raylib"

// deps
import ldtk "../ldtk"

PIXEL_WINDOW_HEIGHT :: 180
TILE_SIZE :: 8

Game_Memory :: struct {
	player_pos:  rl.Vector2,
	some_number: int,
}

DebugOptions :: struct {
	show_colliders: bool,
}

GameEntity :: struct {
	id:           i32,
	using shared: SharedState,
	type:         TypeVariant,
	movement:     MovementVariant,
	input:        InputVariant,
	routine:      RoutineVariant,
}

Entity :: struct {
	id: i32,
}

GameState :: struct {
	player:           ^GameEntity,
	debug:            DebugOptions,
	entities:         map[i32]GameEntity,
	trails:           [dynamic]Trail,
	levels:           map[string]ldtk.Level,
	current_level_id: string,
	// TODO: this should be inside level
	current_spawn:    PlayerSpawn,
	triggers:         [dynamic]Trigger,
}
gameState: ^GameState
idCounter: i32 = 0

shader: rl.Shader

main :: proc() {
	// shader = rl.LoadShader(nil, "shaders/test.fs")

	rl.GetTime()
	gameState = new(GameState)
	gameState^ = GameState {
		debug = {show_colliders = true},
		levels = load_levels(WORLD_FILE),
		current_level_id = START_LEVEL_ID,
	}
	defer free(gameState)

	screen_width: i32 = 1200
	screen_height: i32 = 720

	rl.InitWindow(screen_width, screen_height, "game")
	rl.SetWindowPosition(2000, 1400)
	rl.SetWindowState({.WINDOW_RESIZABLE})
	defer rl.CloseWindow()

	shader = rl.LoadShader(nil, "shaders/test.fs")
	fmt.printf("shader: %v\n", shader)

	rl.SetTargetFPS(60)
	load_level(gameState, gameState.current_level_id)
	// add player
	spawn_player(gameState)


	// addGameEntity(
	// 	{
	// 		movement = Solid {
	// 			position = {16, 24},
	// 			velocity = {20, 20},
	// 			collider = {0, 0, 8, 8},
	// 			colliderColor = rl.RED,
	// 		},
	// 		routine = Routine {
	// 			repeat = true,
	// 			steps = {
	// 				MoveToPosition{to = {0, 24}},
	// 				HoldPosition{duration = 1},
	// 				MoveToPosition{to = {16, 24}},
	// 				HoldPosition{duration = 1},
	// 			},
	// 		},
	// 	},
	// )
	// addGameEntity(
	// 	{movement = Solid{position = {32, 24}, collider = {0, 0, 8, 8}, colliderColor = rl.RED}},
	// )
	// addGameEntity(
	// 	{
	// 		movement = Solid {
	// 			position = {16, 64},
	// 			velocity = {20, 20},
	// 			collider = {0, 0, 8, 8},
	// 			colliderColor = rl.RED,
	// 		},
	// 		routine = Routine {
	// 			repeat = true,
	// 			steps = {
	// 				MoveToPosition{to = {0, 64}},
	// 				HoldPosition{duration = 1},
	// 				MoveToPosition{to = {16, 64}},
	// 				HoldPosition{duration = 1},
	// 			},
	// 		},
	// 	},
	// )
	// addGameEntity(
	// 	{movement = Solid{position = {24, 64}, collider = {0, 0, 8, 8}, colliderColor = rl.RED}},
	// )

	// addGameEntity(
	// 	{
	// 		movement = Solid {
	// 			position = {-10 * TILE_SIZE, 10 * TILE_SIZE},
	// 			collider = {0, 0, 20 * TILE_SIZE, 8 * TILE_SIZE},
	// 			colliderColor = rl.RED,
	// 		},
	// 	},
	// )


	for !rl.WindowShouldClose() {
		{
			update()
			draw()
		}
	}
}


PlayerSpawn :: struct {
	position: Vector2I,
}

addPlayerSpawn :: proc(gameState: ^GameState, marker: PlayerSpawn) {
	gameState.current_spawn = marker
}

addGameEntity :: proc(entity: GameEntity) -> (i32, ^GameEntity) {
	idCounter += 1

	gameState.entities[idCounter] = entity
	stored_entity := &gameState.entities[idCounter]
	stored_entity.id = idCounter

	initMovement(stored_entity)
	initInput(stored_entity)

	assert(stored_entity.position != nil)
	assert(stored_entity.velocity != nil)
	assert(stored_entity.direction != nil)
	assert(stored_entity.jumpHeldDown != nil)
	assert(stored_entity.facing != nil)
	return idCounter, stored_entity
}

update :: proc() {
	dt := rl.GetFrameTime()
	updateTrails(gameState)
	for _, &entity in gameState.entities {
		// update input
		updateInput(
			&entity,
			gameState,
			onJumpKeyPressed = onJumpKeyPressed,
			onDashkeyPressed = onDashkeyPressed,
			onFireKeyPressed = onFireKeyPressed,
		)
		updateRoutine(&entity, gameState)
		updateMovement(&entity, gameState)
		update_triggers(gameState)
	}

}


draw :: proc() {
	// https://github.com/varugasu/raylib-shaders/blob/main/fragcoord/fragcoord.cpp
	dt := rl.GetFrameTime()
	// next https://www.shadertoy.com/view/mtSGDy
	// https://www.shadertoy.com/view/dtS3Dw
	// https://www.shadertoy.com/view/Dl23zR
	rl.SetShaderValue(shader, rl.GetShaderLocation(shader, "u_time"), &dt, .FLOAT)
	resolutionVector := rl.Vector2{f32(rl.GetRenderWidth()), f32(rl.GetRenderHeight())}
	rl.SetShaderValue(
		shader,
		rl.GetShaderLocation(shader, "u_resolution"),
		&resolutionVector,
		.VEC2,
	)


	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)

	rl.BeginMode2D(gameCamera())

	// rl.BeginShaderMode(shader)
	drawTrails(gameState)
	// rl.EndShaderMode()
	for _, &entity in gameState.entities {
		if gameState.debug.show_colliders {
			switch &movement in entity.movement {
			case Actor:
				if player, ok := &entity.type.(Player); ok {
					if isCoyoteTimeActive(&movement) {
						rl.DrawCircle(movement.position.x, movement.position.y, 1.5, rl.RED)
					}

					xCenter := (movement.position.x + (movement.collider.z) / 2)
					directionVector := DirectionVector
					facingDirection := directionVector[movement.facing]
					rl.DrawCircle(
						xCenter + facingDirection.x * 4,
						movement.position.y + movement.collider.w / 2,
						1.5,
						rl.ORANGE,
					)

					debug_text := fmt.tprintf(
						"player velocity: %v\ncolliding_top: %v\ncolliding_bottom: %v\nmovement state: %v\n",
						rl.Vector2 {
							math.round(movement.velocity.x),
							math.round(movement.velocity.y),
						},
						movement.touching[.UP],
						movement.touching[.DOWN],
						movement.movementState,
					)
					ctext := strings.clone_to_cstring(debug_text)
					textPosition := movement.position + {-100, -75}
					rl.DrawText(ctext, textPosition.x, textPosition.y, 1, rl.WHITE)
				}

				rl.DrawRectangle(
					movement.position.x,
					movement.position.y,
					movement.collider.z,
					movement.collider.w,
					movement.colliderColor,
				)
			case Solid:
				rl.DrawRectangle(
					movement.position.x,
					movement.position.y,
					movement.collider.z,
					movement.collider.w,
					movement.colliderColor,
				)
			}
		}


	}


	rl.EndMode2D()
	rl.BeginMode2D(uiCamera())
	rl.EndMode2D()
	rl.EndDrawing()
}

gameCamera :: proc() -> rl.Camera2D {
	w := f32(rl.GetScreenWidth())
	h := f32(rl.GetScreenHeight())


	return {
		zoom = h / PIXEL_WINDOW_HEIGHT,
		target = get_player_position(),
		offset = {w / 2, h / 2},
	}
}

uiCamera :: proc() -> rl.Camera2D {
	return {zoom = f32(rl.GetScreenHeight()) / PIXEL_WINDOW_HEIGHT}
}

getSolids :: proc(gameState: ^GameState) -> [dynamic]^GameEntity {
	solids := make([dynamic]^GameEntity)
	for _, &entity in gameState.entities {
		if solid, ok := &entity.movement.(Solid); ok {
			append_elem(&solids, &entity)
		}
	}
	return solids
}
