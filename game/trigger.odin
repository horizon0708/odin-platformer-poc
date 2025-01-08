package game

import ldtk "../ldtk"
import fmt "core:fmt"
import math "core:math"
import rl "vendor:raylib"
Trigger_Event :: union {
	Level_Transition,
}

Level_Transition :: struct {
	// linked entity 
	entity_id:      string,
	// level the linked entity is in
	level_id:       string,
	// world the linked entity is in
	world_id:       string,

	// player offset relative to the trigger when they enter
	player_offset:  rl.Vector2,
	// player state when they enter, so we know where to move them 
	// and copy over their state in the new level

	// direction to push player in 
	// once they are teleported to the new level
	// atm we assume that all exits are on the edge of the level
	// so we use its grid position to determine the direction
	//
	// e.g. level is 10x10
	// - if exit is at (2, 9), push player right 
	// - if exit is at (9, 2), push player down
	exit_direction: Direction,
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
	player := &gameState.player
	movement := player.movement.variant.(Actor) or_return

	for _, &trigger in gameState.triggers {
		player_rect := get_player_collider()
		was_colliding := trigger.colliding
		trigger.colliding = rl.CheckCollisionRecs(trigger.rect, player_rect)


		if !was_colliding && trigger.colliding && !trigger.disabled {
			player_offset := rl.Vector2 {
				player_rect.x - trigger.rect.x,
				player_rect.y - trigger.rect.y,
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

	transition_trigger := &gameState.triggers[event.entity_id]
	fmt.printf("transition_trigger: %v\n\n", transition_trigger)

	next_level := gameState.levels[event.level_id]
	set_debug_text("level", "next_level", fmt.tprintf("%v", next_level.identifier))
	set_debug_text("level", "exit_direction", fmt.tprintf("%v", event.exit_direction))
	sign := i32(math.sign(f32(gameState.player.movement.velocity.x)))
	// offset the player to the left or right depending on their velocity
	direction_to_push := getDirectionVector(event.exit_direction)
	player_offset_x := event.player_offset.x
	if direction_to_push.x != 0 {
		player_offset_x = 0
	}

	player_offset_y := event.player_offset.y
	if direction_to_push.y != 0 {
		player_offset_y = 0
	}

	gameState.player.movement.position = {
		i32(transition_trigger.rect.x) +
		direction_to_push.x * gameState.player.movement.collider.size.x +
		i32(player_offset_x),
		i32(transition_trigger.rect.y) +
		direction_to_push.y * gameState.player.movement.collider.size.y +
		i32(player_offset_y),
	}
}
