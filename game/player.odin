package game

import fmt "core:fmt"
import "core:math/linalg"
import "core:strings"
import rl "vendor:raylib"


Player :: struct {
	using entity:   Entity,
	using actor:    Actor,
	jump_held_down: bool,
	test_timer:     Timer,
}
