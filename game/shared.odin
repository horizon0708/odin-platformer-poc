package game

import rl "vendor:raylib"

SharedState :: struct {
	position:     ^Vector3I,
	velocity:     ^rl.Vector2,
	direction:    ^rl.Vector2,
	jumpHeldDown: ^bool,
}
