package game

import fmt "core:fmt"
import "core:math/linalg"
import "core:strings"
import rl "vendor:raylib"


TypeVariant :: union {
	Block,
	Player,
}

Block :: struct {}
Player :: struct {}
