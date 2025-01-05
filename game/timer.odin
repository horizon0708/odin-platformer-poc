package game

import fmt "core:fmt"

TimerType :: enum {
	OneShot,
	Repeating,
}

Timer :: struct {
	time:        f32,
	currentTime: f32,
	running:     bool,
	type:        TimerType,
}

timerUpdate :: proc(timer: ^Timer, owner: ^$T, dt: f32, onComplete: proc(self: ^T)) {
	if !timer.running {
		return
	}

	timer.currentTime += dt
	if timer.currentTime >= timer.time {
		onComplete(owner)
		if timer.type == .OneShot {
			timer.running = false
		} else {
			timer.currentTime = 0
		}
	}
}

timerStart :: proc(timer: ^Timer, owner: ^$T, onStart: proc(self: ^T)) {
	if timer.running {
		fmt.printf("timer already running\n")
		return
	}

	timer.running = true
	timer.currentTime = 0
	onStart(owner)
}

timerPause :: proc(timer: ^Timer) {
	if !timer.running {
		return
	}

	timer.running = false
}
