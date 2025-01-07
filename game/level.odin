package game
import json "core:encoding/json"
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

// get_level_bounds :: proc(gameState: ^GameState) -> rl.Rectangle {
// 	level := gameState.levels[gameState.current_level_id]
// 	return {
// 		x = 0,
// 		y = 0,
// 		width = i32(level.c_width * level.grid_size),
// 		height = i32(level.c_height * level.grid_size),
// 	}
// }

load_level :: proc(gameState: ^GameState, level_id: Maybe(string) = nil) {
	level_id_to_load := level_id.? or_else gameState.current_level_id

	if level, ok := gameState.levels[level_id_to_load]; !ok {
		unload_level(gameState)
		gameState.current_level_id = level_id_to_load
	}

	level := gameState.levels[level_id_to_load]
	// fmt.printf("Loading level: %s\n", level)
	for layer in level.layer_instances {
		switch layer.type {
		case .IntGrid:
			// fmt.printf("IntGrid: %v\n", layer)
			load_int_grid(gameState, layer)
		case .Entities:
			// fmt.printf("Entities: %v\n", layer)
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
		case "Level_Entrance":
			field_instance := entity.field_instances[0]
			value, ok := get_entity_reference_infos(field_instance.value)
			if !ok {
				assert(false, "Failed to get entity reference infos")
				continue
			}

			add_trigger(
				gameState,
				Trigger {
					id = entity.iid,
					rect = {
						x = f32(position.x),
						y = f32(position.y),
						width = f32(entity.width),
						height = f32(entity.height),
					},
					event = Level_Transition {
						entity_id = value.entity_iid,
						level_id = value.level_iid,
						world_id = value.world_iid,
					},
				},
			)


			fmt.printf("Level_Entrance: %v\n", value)
		case:
			assert(false, fmt.tprintf("Unknown entity: %s", entity.identifier))
		}
	}
}

get_entity_reference_infos :: proc(
	any_value: json.Value,
) -> (
	reference_infos: ldtk.Entity_Reference_Infos,
	ok: bool,
) {
	value := any_value.(json.Object) or_return

	entity_iid, ok1 := value["entityIid"].(string)
	layer_iid, ok2 := value["layerIid"].(string)
	level_iid, ok3 := value["levelIid"].(string)
	world_iid, ok4 := value["worldIid"].(string)

	if !(ok1 && ok2 && ok3 && ok4) {
		return reference_infos, false
	}
	return ldtk.Entity_Reference_Infos {
			entity_iid = entity_iid,
			layer_iid = layer_iid,
			level_iid = level_iid,
			world_iid = world_iid,
		},
		true
}

Level_Transition_Trigger :: struct {
	position:      Vector2I,
	collider_size: Vector2I,
	next_level_id: string,
}

add_level_transition_trigger :: proc(gameState: ^GameState, trigger: Level_Transition_Trigger) {

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
	clear(&gameState.entities)
}
