package game
import rl "vendor:raylib"

InputVariant :: union {
	NoInput,
	Input,
}

Input :: struct {
	jumpHeldDown:     bool,
	jumpKeyPressed:   bool,
	directionalInput: rl.Vector2,
}

NoInput :: struct {}

updateInput :: proc(
	entity: ^GameEntity,
	_gameState: ^GameState,
	onJumpKeyPressed: proc(self: ^GameEntity),
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

		if movement, ok := entity.movement.(Actor); ok && input.jumpKeyPressed {
			onJumpKeyPressed(entity)
			input.jumpHeldDown = true
		}

		if input.jumpHeldDown && jumpKeyReleased() {
			input.jumpHeldDown = false
		}
		// no need to normalize as we separate horizontal and vertical movement
		input.directionalInput = directionalInput
		// input.directionalInput = linalg.normalize0(directionalInput)
	}
}

jumpKeyPressed :: proc() -> bool {
	return rl.IsKeyDown(.SPACE) || rl.IsKeyDown(.X)
}

jumpKeyReleased :: proc() -> bool {
	return rl.IsKeyReleased(.SPACE) || rl.IsKeyReleased(.X)
}
