package game

import "core:fmt"
import rl "vendor:raylib"
Trail :: struct {
	rectangle: rl.Rectangle,
	color:     rl.Color,
	createdAt: f64,
	duration:  f64,
}

addTrail :: proc(entity: ^GameEntity, color: rl.Color, duration: f64) {
	trail := Trail {
		rectangle = rl.Rectangle {
			f32(entity.movement.position.x),
			f32(entity.movement.position.y),
			8,
			16,
		},
		color     = color,
		createdAt = rl.GetTime(),
		duration  = duration,
	}
	append(&gameState.trails, trail)
}

updateTrails :: proc(gameState: ^GameState) {
	for i := len(gameState.trails) - 1; i >= 0; i -= 1 {
		trail := &gameState.trails[i]
		progress := (rl.GetTime() - trail.createdAt) / trail.duration
		trail.color.a = u8(200 * (1 - progress))
		if rl.GetTime() - trail.createdAt > trail.duration {
			unordered_remove(&gameState.trails, i)
		}
	}
}

drawTrails :: proc(gameState: ^GameState) {
	for trail in gameState.trails {
		rl.DrawRectangleRec(trail.rectangle, trail.color)
	}
}
