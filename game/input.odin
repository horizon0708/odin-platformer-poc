package game
import rl "vendor:raylib"

InputVariant :: union #no_nil {
	NoInput,
	Input,
}

Input :: struct {
	jumpHeldDown:   bool,
	jumpKeyPressed: bool,
}

NoInput :: struct {
	jumpHeldDown: bool,
}

initInput :: proc(entity: ^GameEntity) {
	switch &input in entity.input {
	case NoInput:
		entity.jumpHeldDown = &input.jumpHeldDown
	case Input:
		entity.jumpHeldDown = &input.jumpHeldDown
	}
}

updateInput :: proc(
	entity: ^GameEntity,
	_gameState: ^GameState,
	onJumpKeyPressed: proc(self: ^GameEntity) -> bool,
) {
	if input, ok := &entity.input.(Input); ok {
		directionalInput: rl.Vector2
		if rl.IsKeyDown(.UP) || rl.IsKeyDown(.W) {
			directionalInput.y -= 1
		}
		if rl.IsKeyDown(.DOWN) || rl.IsKeyDown(.S) {
			directionalInput.y += 1
		}
		if rl.IsKeyDown(.LEFT) || rl.IsKeyDown(.A) {
			directionalInput.x -= 1
		}
		if rl.IsKeyDown(.RIGHT) || rl.IsKeyDown(.D) {
			directionalInput.x += 1
		}

		input.jumpKeyPressed = jumpKeyPressed()

		if input.jumpKeyPressed {
			onJumpKeyPressed(entity)
			entity.jumpHeldDown^ = true
		}

		if entity.jumpHeldDown^ && jumpKeyReleased() {
			entity.jumpHeldDown^ = false
		}

		// no need to normalize as we separate horizontal and vertical movement
		entity.direction^ = directionalInput
		// input.directionalInput = linalg.normalize0(directionalInput)
	}
}

jumpKeyPressed :: proc() -> bool {
	return rl.IsKeyDown(.SPACE) || rl.IsKeyDown(.X)
}

jumpKeyReleased :: proc() -> bool {
	return rl.IsKeyReleased(.SPACE) || rl.IsKeyReleased(.X)
}
