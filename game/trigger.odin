package game

import ldtk "../ldtk"
import rl "vendor:raylib"

Trigger_Event :: union {
	Level_Transition,
}

Level_Transition :: struct {
	// linked entity 
	entity_id:     string,
	// level the linked entity is in
	level_id:      string,
	// world the linked entity is in
	world_id:      string,

	// player offset relative to the trigger when they enter
	player_offset: rl.Vector2,
}

Level_Entrance :: struct {
	entity_reference_infos: ldtk.Entity_Reference_Infos,
}

Trigger :: struct {
	id:        string,
	rect:      rl.Rectangle,
	colliding: bool,
	disabled:  bool,
	event:     Trigger_Event,
}

add_trigger :: proc(gameState: ^GameState, trigger: Trigger) {
	gameState.triggers[trigger.id] = trigger
}

update_triggers :: proc(gameState: ^GameState) -> bool {
	player := get_player().? or_return
	movement := player.movement.(Actor) or_return

	for _, &trigger in gameState.triggers {
		player_rect := rl.Rectangle {
			x      = f32(movement.position.x + movement.collider.x),
			y      = f32(movement.position.y + movement.collider.y),
			width  = f32(movement.collider.z),
			height = f32(movement.collider.w),
		}
		was_colliding := trigger.colliding
		trigger.colliding = rl.CheckCollisionRecs(trigger.rect, player_rect)

		if was_colliding && !trigger.colliding && trigger.disabled {
			// once player leaves the transition area, enable it
			if event, ok := trigger.event.(Level_Transition); ok {
				trigger.disabled = false
			}
		}

		if !was_colliding && trigger.colliding && !trigger.disabled {
			player_offset := rl.Vector2 {
				trigger.rect.x - player_rect.x,
				trigger.rect.y - player_rect.y,
			}
			switch &event in trigger.event {
			case Level_Transition:
				event.player_offset = player_offset
				on_level_transition(gameState, event)
			}
		}
	}
	return true
}

on_level_transition :: proc(gameState: ^GameState, event: Level_Transition) {
	unload_level(gameState)
	load_level(gameState, event.level_id)

	// disable the trigger the player spawns in! 
	transition_trigger := &gameState.triggers[event.entity_id]
	transition_trigger.disabled = true

	gameState.current_spawn = PlayerSpawn {
		position = {
			i32(transition_trigger.rect.x - event.player_offset.x),
			i32(transition_trigger.rect.y - event.player_offset.y),
		},
	}
	spawn_player(gameState)
}
