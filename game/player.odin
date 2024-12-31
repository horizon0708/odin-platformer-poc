package game

import fmt "core:fmt"
import "core:math/linalg"
import "core:strings"
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
	if rl.IsKeyDown(.SPACE) || rl.IsKeyDown(.X) {
		tryJump(player)
	}

	input = linalg.normalize0(input)

	// Q: is this efficient?
	solids := getSolids(gameState)
	defer delete(solids)
	setTouchingSolids(player, solids[:])
	moveActorX(player, solids[:], input.x)


	// vertical movement
	if isGrounded(player) && player.velocity.y > 0 {
		player.velocity.y = 0
	} else {
		player.velocity.y += getGravity(player) * rl.GetFrameTime()
	}

	// fmt.printf("[playerUpdate] player velocity: %v\n", player.velocity)

	moveActorY(player, solids[:], player.velocity.y)
}


getGravity :: proc(player: ^Player) -> f32 {
	assert(player.jump.height > 0)
	assert(player.jump.timeToPeak > 0)
	assert(player.jump.timeToDescent > 0)

	jumpGravity := (2.0 * player.jump.height) / (player.jump.timeToPeak * player.jump.timeToPeak)
	fallGravity :=
		(2.0 * player.jump.height) / (player.jump.timeToDescent * player.jump.timeToDescent)

	if player.velocity.y < 0 {
		return fallGravity
	} else if rl.IsKeyDown(.SPACE) {
		return jumpGravity
	} else {
		return jumpGravity
	}
}

getJumpVelocity :: proc(player: ^Player) -> f32 {
	assert(player.jump.height > 0)
	assert(player.jump.timeToPeak > 0)
	return (-2.0 * player.jump.height) / player.jump.timeToPeak
}

tryJump :: proc(player: ^Player) {
	// check if player is on the ground
	if isGrounded(player) && player.velocity.y == 0 {
		player.velocity.y = getJumpVelocity(player)
		fmt.printf("jump velocity: %v\n", player.velocity.y)
	}
}

isGrounded :: proc(player: ^Player) -> bool {
	return len(player.touching[.DOWN]) > 0
}


playerDraw :: proc(player: ^Player, gameState: ^GameState) {

	solids := getSolids(gameState)
	defer delete(solids)
	debug_text := fmt.tprintf(
		"player velocity: %v\ncolliding_top: %v\ncolliding_bottom: %v\n",
		player.velocity,
		player.touching[.UP],
		player.touching[.DOWN],
	)
	ctext := strings.clone_to_cstring(debug_text)
	rl.DrawText(ctext, 0, 0, 5, rl.WHITE)


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

writeDebugText :: proc(text: string) {
	ctext := strings.clone_to_cstring(text)
	rl.DrawText(ctext, 0, 0, 5, rl.WHITE)
}
