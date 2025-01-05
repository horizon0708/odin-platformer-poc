package game

// core
import fmt "core:fmt"
import "core:math/linalg"
import "core:strings"

// vendor
import rl "vendor:raylib"

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
	id:       i32,
	type:     TypeVariant,
	movement: MovementVariant,
	input:    InputVariant,
}

Entity :: struct {
	id: i32,
}

GameState :: struct {
	player:   ^GameEntity,
	debug:    DebugOptions,
	entities: map[i32]GameEntity,
}
gameState: ^GameState
idCounter: i32 = 0

main :: proc() {
	gameState = new(GameState)
	gameState^ = GameState {
		debug = {show_colliders = true},
	}
	defer free(gameState)

	screen_width: i32 = 1200
	screen_height: i32 = 720

	rl.InitWindow(screen_width, screen_height, "game")
	rl.SetWindowPosition(2000, 1400)
	rl.SetWindowState({.WINDOW_RESIZABLE})
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)
	// add player
	id, player := addGameEntity(
		{
			type = Player{},
			movement = Actor {
				velocity = {50, 0},
				collider = {0, 0, 8, 16},
				colliderColor = rl.GREEN,
				jump = {
					height = 60,
					timeToPeak = 0.5,
					timeToDescent = 0.3,
					coyoteTimer = {duration = 0.5},
				},
			},
			input = Input{},
		},
	)

	// game setup
	gameState.player = player

	addGameEntity(
		{
			movement = Solid {
				position = {16, 24, 0},
				collider = {0, 0, 8, 8},
				colliderColor = rl.RED,
			},
		},
	)
	addGameEntity(
		{
			movement = Solid {
				position = {32, 24, 0},
				collider = {0, 0, 8, 8},
				colliderColor = rl.RED,
			},
		},
	)
	addGameEntity(
		{
			movement = Solid {
				position = {-10 * TILE_SIZE, 10 * TILE_SIZE, 0},
				collider = {0, 0, 20 * TILE_SIZE, 8 * TILE_SIZE},
				colliderColor = rl.RED,
			},
		},
	)

	for !rl.WindowShouldClose() {
		{
			update()
			draw()
		}
	}
}

addGameEntity :: proc(entity: GameEntity) -> (i32, ^GameEntity) {
	idCounter += 1
	entity := entity
	entity.id = idCounter
	gameState.entities[idCounter] = entity
	return idCounter, &gameState.entities[idCounter]
}

update :: proc() {
	dt := rl.GetFrameTime()
	for _, &entity in gameState.entities {
		// update input
		updateInput(&entity, gameState, onJumpKeyPressed = onJumpKeyPressed)
		updateMovement(&entity, gameState)
	}

}

draw :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)

	rl.BeginMode2D(gameCamera())
	for _, &entity in gameState.entities {
		if gameState.debug.show_colliders {
			switch &movement in entity.movement {
			case Actor:
				if player, ok := &entity.type.(Player); ok {
					if isCoyoteTimeActive(&movement) {
						rl.DrawCircle(movement.position.x, movement.position.y, 1.5, rl.RED)
					}
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
	debug_text := fmt.tprintf(
		"player velocity: %v\ncolliding_top: %v\ncolliding_bottom: %v\n",
		gameState.player.movement.(Actor).velocity,
		gameState.player.movement.(Actor).touching[.UP],
		gameState.player.movement.(Actor).touching[.DOWN],
	)
	ctext := strings.clone_to_cstring(debug_text)
	rl.DrawText(ctext, 0, 0, 5, rl.WHITE)

	rl.EndMode2D()

	rl.BeginMode2D(uiCamera())
	rl.EndMode2D()
	rl.EndDrawing()
}

gameCamera :: proc() -> rl.Camera2D {
	w := f32(rl.GetScreenWidth())
	h := f32(rl.GetScreenHeight())

	// fmt.printf("[gameCamera]player: %v\n", &gameState.player.position)
	player_movement := &gameState.player.movement.(Actor)

	return {
		zoom = h / PIXEL_WINDOW_HEIGHT,
		target = {f32(player_movement.position.x), f32(player_movement.position.y)},
		offset = {w / 2, h / 2},
	}
}

uiCamera :: proc() -> rl.Camera2D {
	return {zoom = f32(rl.GetScreenHeight()) / PIXEL_WINDOW_HEIGHT}
}

getSolids :: proc(gameState: ^GameState) -> [dynamic]^Solid {
	solids := make([dynamic]^Solid)
	for _, &entity in gameState.entities {
		if solid, ok := &entity.movement.(Solid); ok {
			append_elem(&solids, solid)
		}
	}
	return solids
}
