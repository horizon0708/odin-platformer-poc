package game
import fmt "core:fmt"

import ldtk "../ldtk"
import rl "vendor:raylib"

WORLD_FILE :: "ldtk/test.ldtk"
START_LEVEL_ID :: "c6546f10-c210-11ef-ab64-d165d3b9d7f8"

load_levels :: proc(world_file: string) -> map[string]ldtk.Level {
	project, ok := ldtk.load_from_file(world_file, context.temp_allocator).?
	levels := make(map[string]ldtk.Level)
	if ok {
		for level in project.levels {
			levels[level.iid] = level
		}
	}
	return levels
}

load_level :: proc(gameState: ^GameState, level_id: Maybe(string) = nil) {
	level_id_to_load := level_id.? or_else gameState.current_level_id

	if level, ok := gameState.levels[level_id_to_load]; !ok {
		unload_level(gameState)
		gameState.current_level_id = level_id_to_load
	}

	level := gameState.levels[level_id_to_load]
	for layer in level.layer_instances {
		switch layer.type {
		case .IntGrid:
			load_int_grid(gameState, layer)
		case .Entities:
			load_entities(gameState, layer)
		case .Tiles:
			fmt.printf("Tiles: %v\n", layer)
		case .AutoLayer:
			fmt.printf("AutoLayer: %v\n", layer)
		}
	}
}

load_entities :: proc(gameState: ^GameState, layer: ldtk.Layer_Instance) {
	offsetX := i32(layer.grid_size * layer.c_width / 2)
	offsetY := i32(layer.grid_size * layer.c_height / 2)

	for entity in layer.entity_instances {
		position: Vector2I = {
			i32(entity.grid.x * layer.grid_size) - offsetX,
			i32(entity.grid.y * layer.grid_size) - offsetY,
		}
		switch entity.identifier {
		case "Player_Spawn":
			addPlayerSpawn(gameState, PlayerSpawn{position = position})
		case:
			assert(false, fmt.tprintf("Unknown entity: %s", entity.identifier))
		}
	}
}

load_int_grid :: proc(gameState: ^GameState, layer: ldtk.Layer_Instance) {
	offsetX := i32(layer.grid_size * layer.c_width / 2)
	offsetY := i32(layer.grid_size * layer.c_height / 2)
	for j in 0 ..< layer.c_height {
		for i in 0 ..< layer.c_width {
			cell_id := layer.int_grid_csv[j * layer.c_width + i]
			position: [2]i32 = {
				i32(i * layer.grid_size) - offsetX,
				i32(j * layer.grid_size) - offsetY,
			}
			if cell_id == 1 {
				addGameEntity(
					{
						movement = Solid {
							position = position,
							collider = {0, 0, i32(layer.grid_size), i32(layer.grid_size)},
							colliderColor = rl.RED,
						},
					},
				)
			}
		}
	}

}

unload_level :: proc(gameState: ^GameState) {

}
