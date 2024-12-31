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

GameState :: struct {
	gameObjects: map[i32]Actor,
	solids:      [dynamic]Solid,
}
gameState: ^GameState
idCounter: i32 = 0
g_mem: ^Game_Memory
playerId: i32 = -1

main :: proc() {
	gameState = new(GameState)
	gameState^ = GameState {
		gameObjects = {},
		solids      = {},
	}
	defer free(gameState)

	g_mem = new(Game_Memory)

	g_mem^ = Game_Memory {
		player_pos  = {0, 0},
		some_number = 0,
	}
	defer free(g_mem)

	screen_width: i32 = 1200
	screen_height: i32 = 720

	rl.InitWindow(screen_width, screen_height, "game")
	rl.SetWindowPosition(2000, 1400)
	rl.SetWindowState({.WINDOW_RESIZABLE})
	defer rl.CloseWindow()

	rl.SetTargetFPS(60)

	// game setup
	playerId = addGameObject(Actor{position = {0, 0, 0}, collider = {0, 0, 10, 20}})
	addSolid(Solid{position = {20, 20, 0}, collider = {0, 0, 20, 20}})

	for !rl.WindowShouldClose() {
		{
			update()
			draw()
		}
	}
}

addGameObject :: proc(actor: Actor) -> i32 {
	idCounter += 1
	gameState.gameObjects[idCounter] = actor
	return idCounter
}

addSolid :: proc(solid: Solid) {
	append_elem(&gameState.solids, solid)
}

update :: proc() {
	input: rl.Vector2

	if rl.IsKeyDown(.UP) || rl.IsKeyDown(.W) {
		input.y -= 1
	}
	if rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.S) {
		input.y += 1
	}
	if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) {
		input.x -= 1
	}
	if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
		input.x += 1
	}

	input = linalg.normalize0(input)

	player := &gameState.gameObjects[playerId]
	moveActorX(player, gameState.solids[:], input.x)
	moveActorY(player, gameState.solids[:], input.y)

	g_mem.some_number += 1
}

draw :: proc() {
	rl.BeginDrawing()
	rl.ClearBackground(rl.GRAY)

	rl.BeginMode2D(game_camera())
	for _, actor in gameState.gameObjects {
		rl.DrawRectangleLines(
			actor.position.x + actor.collider.x,
			actor.position.y + actor.collider.y,
			actor.collider[2],
			actor.collider[3],
			rl.GREEN,
		)
	}

	for solid in gameState.solids {
		rl.DrawRectangleLines(
			solid.position.x,
			solid.position.y,
			solid.collider[2],
			solid.collider[3],
			rl.RED,
		)
	}

	rl.EndMode2D()

	rl.BeginMode2D(ui_camera())
	rl.DrawText(
		fmt.ctprintf("some_number: %v\nplayer_pos: %v", g_mem.some_number, g_mem.player_pos),
		5,
		5,
		8,
		rl.WHITE,
	)
	rl.EndMode2D()
	rl.EndDrawing()
}

game_camera :: proc() -> rl.Camera2D {
	w := f32(rl.GetScreenWidth())
	h := f32(rl.GetScreenHeight())

	return {zoom = h / PIXEL_WINDOW_HEIGHT, target = g_mem.player_pos, offset = {w / 2, h / 2}}
}

ui_camera :: proc() -> rl.Camera2D {
	return {zoom = f32(rl.GetScreenHeight()) / PIXEL_WINDOW_HEIGHT}
}
