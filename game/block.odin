package game

import fmt "core:fmt"
import rl "vendor:raylib"

Block :: struct {
	using solid: Solid,
}

blockDraw :: proc(block: ^Block, gameState: ^GameState) {
	if gameState.debug.show_colliders {
		rl.DrawRectangleLines(
			block.position.x + block.collider.x,
			block.position.y + block.collider.y,
			block.collider.z,
			block.collider.w,
			rl.RED,
		)
	}
}
