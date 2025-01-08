package game

import rl "vendor:raylib"

/**
Components that set data of another component 
should do so using function defined here
*/

set_entity_direction :: proc(entity: ^GameEntity, direction: rl.Vector2) {
	entity.movement.direction = direction
}
