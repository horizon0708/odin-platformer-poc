package game

import rl "vendor:raylib"

SharedState :: struct {
	position:     ^Vector2I,
	velocity:     ^rl.Vector2,
	direction:    ^rl.Vector2,
	jumpHeldDown: ^bool,
	facing:       ^Direction,
}
