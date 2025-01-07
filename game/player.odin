package game

import rl "vendor:raylib"

get_player :: proc() -> Maybe(^GameEntity) {
    return gameState.player
} 

get_player_position :: proc() -> rl.Vector2 {

    if player, ok := get_player().?; ok {
        
        return {
            f32(player.position.x),
            f32(player.position.y),
        }
    }

    return {0, 0}
}

spawn_player :: proc(gameState: ^GameState) {
    id, player := addGameEntity(
		{
			type = Player{},
			movement = Actor {
                position = gameState.current_spawn.position,
				velocity = {0, 0},
				xSpeed = LinearSpeed{speed = 50},
				collider = {0, 0, 8, 16},
				colliderColor = rl.GREEN,
				jump = {
					height = 60,
					timeToPeak = 0.5,
					timeToDescent = 0.3,
					coyoteTimer = {duration = 0.5},
				},
				dash = {
					timer = {duration = 0.1},
					cooldown = {duration = 0.5},
					speed = 300,
					airDashSpeed = 200,
					trailSpawnTimer = {running = true, type = .Repeating, duration = 0.1 / 8},
					trailColor = rl.BLUE,
					trailDuration = 0.15,
				},
				gunRecoil = {
					groundSpeed = 450,
					airSpeed = 900,
					dashJumpRecoilSpeed = 300,
					timer = {duration = 0.05},
					cooldown = {duration = 0.5},
					trailColor = rl.ORANGE,
					trailDuration = 0.22,
				},
			},
			input = Input{},
		},
	)
	gameState.player = player
}


