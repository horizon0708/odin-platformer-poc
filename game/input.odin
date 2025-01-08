package game

import "core:fmt"
import rl "vendor:raylib"

Input :: struct {
	variant: InputVariant,
}

InputVariant :: union #no_nil {
	NoInput,
	PlayerInput,
}

PlayerInput :: struct {
	jumpHeldDown:   bool,
	jumpKeyPressed: bool,
}

NoInput :: struct {}

jumpHeldDown :: proc(entity: ^GameEntity) -> bool {
	if variant, ok := &entity.input.variant.(PlayerInput); ok {
		return variant.jumpHeldDown
	}
	return false
}


updateInput :: proc(
	entity: ^GameEntity,
	_gameState: ^GameState,
	onJumpKeyPressed: proc(self: ^GameEntity) -> bool,
	onDashkeyPressed: proc(self: ^GameEntity) -> bool,
	onFireKeyPressed: proc(self: ^GameEntity) -> bool,
) {
	if input, ok := &entity.input.variant.(PlayerInput); ok {
		directionalInput: rl.Vector2
		if rl.IsKeyDown(.UP) || rl.IsKeyDown(.W) {
			directionalInput.y -= 1
		}
		if rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.S) {
			directionalInput.y += 1
		}
		if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) {
			directionalInput.x -= 1
			entity.movement.facing = .LEFT
		}
		if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
			directionalInput.x += 1
			entity.movement.facing = .RIGHT
		}

		input.jumpKeyPressed = jumpKeyPressed()

		if input.jumpKeyPressed {
			onJumpKeyPressed(entity)
			input.jumpHeldDown = true
		}

		if input.jumpHeldDown && jumpKeyReleased() {
			input.jumpHeldDown = false
		}

		if dashKeyPressed() {
			onDashkeyPressed(entity)
		}

		if fireKeyPressed() {
			onFireKeyPressed(entity)
		}

		// no need to normalize as we separate horizontal and vertical movement
		// for the player
		set_entity_direction(entity, directionalInput)
	}
}

jumpKeyPressed :: proc() -> bool {
	return rl.IsKeyDown(.SPACE) || rl.IsKeyDown(.X)
}

jumpKeyReleased :: proc() -> bool {
	return rl.IsKeyReleased(.SPACE) || rl.IsKeyReleased(.X)
}

dashKeyPressed :: proc() -> bool {
	return rl.IsKeyDown(.Z)
}

fireKeyPressed :: proc() -> bool {
	return rl.IsKeyDown(.C)
}
