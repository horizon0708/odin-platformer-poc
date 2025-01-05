package game

// core
import fmt "core:fmt"
import "core:math/linalg"

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

Entity :: struct {
	id: i32,
}

GameState :: struct {
	player: Player,
	blocks: map[i32]Block,
	debug:  DebugOptions,
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

	// game setup
	gameState.player = Player {
		position = {0, 0, 0},
		collider = {0, 0, 8, 16},
		jump = {height = 60, timeToPeak = 0.5, timeToDescent = 0.3},
		test_timer = {time = 1, running = true, type = .OneShot},
	}
	addBlock(Block{position = {16, 24, 0}, collider = {0, 0, 8, 8}})
	addBlock(Block{position = {32, 24, 0}, collider = {0, 0, 8, 8}})
	addBlock(
		Block {
			position = {-10 * TILE_SIZE, 10 * TILE_SIZE, 0},
			collider = {0, 0, 20 * TILE_SIZE, 8 * TILE_SIZE},
		},
	)

	for !rl.WindowShouldClose() {
		{
			update()
			draw()
		}
	}
}

addBlock :: proc(block: Block) -> i32 {
	idCounter += 1
	gameState.blocks[idCounter] = block
	return idCounter
}


update :: proc() {
	playerUpdate(&gameState.player, gameState)

	// for _, &block in gameState.blocks {
	// 	blockUpdate(&block, gameState)
	// }
}

draw :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)

	rl.BeginMode2D(gameCamera())
	playerDraw(&gameState.player, gameState)
	for _, &block in gameState.blocks {
		blockDraw(&block, gameState)
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
	for _, &block in gameState.blocks {
		append_elem(&solids, &block.solid)
	}
	return solids
}
