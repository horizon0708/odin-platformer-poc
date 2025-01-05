package game

import fmt "core:fmt"
import "core:math/linalg"
import "core:strings"
import rl "vendor:raylib"


TypeVariant :: union #no_nil {
	Block,
	Player,
}

Player :: struct {}
Block :: struct {}

getTypeName :: proc(entity: ^GameEntity) -> string {
	fmt.println("entity:", entity)
	fmt.println("entity.type:", entity.type)

	switch type in &entity.type {
	case Player:
		return "player"
	case Block:
		return "block"
	case:
		assert(false, fmt.tprintf("unknown type: %v", type))
		return ""
	}
}
