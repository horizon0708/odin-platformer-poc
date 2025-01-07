package game

import rl "vendor:raylib"

Trigger_Event :: union {
	Level_Transition,
}

Level_Transition :: struct {
	next_level_id: string,
}

Trigger :: struct {
	rect:  rl.Rectangle,
	event: Trigger_Event,
}

add_trigger :: proc(gameState: ^GameState, trigger: Trigger) {
	append(&gameState.triggers, trigger)
}

update_triggers :: proc(gameState: ^GameState) -> bool {
	player := get_player().? or_return
	movement := player.movement.(Actor) or_return

	for trigger in gameState.triggers {
		player_rect := rl.Rectangle {
			x      = f32(movement.position.x + movement.collider.x),
			y      = f32(movement.position.y + movement.collider.y),
			width  = f32(movement.collider.z),
			height = f32(movement.collider.w),
		}

		if rl.CheckCollisionRecs(trigger.rect, player_rect) {
			switch event in trigger.event {
			case Level_Transition:
				on_level_transition(gameState, event)
			}
		}
	}
	return true
}

on_level_transition :: proc(gameState: ^GameState, event: Level_Transition) {
	unload_level(gameState)
	load_level(gameState, event.next_level_id)
}
