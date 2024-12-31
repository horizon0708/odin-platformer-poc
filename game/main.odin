package game

// core
import fmt "core:fmt"
import "core:math/linalg"

// vendor
import rl "vendor:raylib"

PIXEL_WINDOW_HEIGHT :: 180

Game_Memory :: struct {
	player_pos:  rl.Vector2,
	some_number: int,
}

DebugOptions :: struct {
	show_colliders: bool,
}

GameObject :: union {
	Player,
	Block,
}

GameState :: struct {
	player:      ^Player,
	gameObjects: map[i32]GameObject,
	debug:       DebugOptions,
}
gameState: ^GameState
idCounter: i32 = 0

main :: proc() {
	gameState = new(GameState)
	gameState^ = GameState {
		gameObjects = {},
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

	// game setup
	playerId := addGameObject(Player{position = {0, 0, 0}, collider = {0, 0, 8, 16}})
	if go := &gameState.gameObjects[playerId]; go != nil {
		// Q: I don't really get whats happening here
		// I think.. go^ deferences the pointer and then we cast it to a Player pointer
		if player, ok := &(go^).(Player); ok {
			gameState.player = player
		}
	}
	addGameObject(Block{position = {16, 24, 0}, collider = {0, 0, 8, 8}})
	addGameObject(Block{position = {32, 24, 0}, collider = {0, 0, 8, 8}})

	for !rl.WindowShouldClose() {
		{
			update()
			draw()
		}
	}
}

addGameObject :: proc(gameObject: GameObject) -> i32 {
	idCounter += 1
	gameState.gameObjects[idCounter] = gameObject
	return idCounter
}


update :: proc() {
	for _, &go in gameState.gameObjects {
		switch &go in go {
		case Player:
			playerUpdate(&go, gameState)
		case Block:
		// noop
		}
	}
}

draw :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)

	rl.BeginMode2D(gameCamera())
	for _, go in gameState.gameObjects {
		switch &go in go {
		case Player:
			playerDraw(&go, gameState)
		case Block:
			blockDraw(&go, gameState)
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

	// fmt.printf("[gameCamera]player: %v\n", &gameState.player.position)
	return {
		zoom = h / PIXEL_WINDOW_HEIGHT,
		target = {f32(gameState.player.position.x), f32(gameState.player.position.y)},
		offset = {w / 2, h / 2},
	}
}

uiCamera :: proc() -> rl.Camera2D {
	return {zoom = f32(rl.GetScreenHeight()) / PIXEL_WINDOW_HEIGHT}
}

getSolids :: proc(gameState: ^GameState) -> [dynamic]^Solid {
	solids := make([dynamic]^Solid)
	for _, &go in gameState.gameObjects {
		if block, ok := &go.(Block); ok {
			append_elem(&solids, &block.solid)
		}
	}
	return solids
}
