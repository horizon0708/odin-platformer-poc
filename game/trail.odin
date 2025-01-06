package game

import "core:fmt"
import rl "vendor:raylib"
Trail :: struct {
	rectangle: rl.Rectangle,
	color:     rl.Color,
	createdAt: f64,
	duration:  f64,
}

addTrail :: proc(entity: ^GameEntity) {
	actor := &entity.movement.(Actor)
	if actor == nil {
		return
	}

	trail := Trail {
		rectangle = rl.Rectangle{f32(entity.position.x), f32(entity.position.y), 10, 10},
		color     = rl.BLUE,
		createdAt = rl.GetTime(),
		duration  = 0.2,
	}
	append(&gameState.trails, trail)
}

updateTrails :: proc(gameState: ^GameState) {
	trailsToRemove := make([dynamic]int)
	defer delete(trailsToRemove)
	for trail, index in gameState.trails {
		if rl.GetTime() - trail.createdAt > trail.duration {
			append(&trailsToRemove, index)
		}
	}
	for index in trailsToRemove {
		unordered_remove(&gameState.trails, index)
	}
}

drawTrails :: proc(gameState: ^GameState) {
	for trail in gameState.trails {
		rl.DrawRectangleRec(trail.rectangle, trail.color)
	}
}
