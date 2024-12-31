package game

import fmt "core:fmt"
import "core:math/linalg"
import rl "vendor:raylib"

Player :: struct {
	using actor: Actor,
}

playerUpdate :: proc(player: ^Player, gameState: ^GameState) {
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

	// Q: is this efficient?
	solids := get_solids(gameState)
	defer delete(solids)
	moveActorX(player, solids[:], input.x)
	moveActorY(player, solids[:], input.y)

	fmt.printf("[playerUpdate] player: %v\n", player.position)
}


playerDraw :: proc(player: ^Player, gameState: ^GameState) {
	if gameState.debug.show_colliders {
		rl.DrawRectangleLines(
			player.position.x + player.collider.x,
			player.position.y + player.collider.y,
			player.collider[2],
			player.collider[3],
			rl.GREEN,
		)
	}
}
