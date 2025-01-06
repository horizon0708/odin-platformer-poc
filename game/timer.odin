package game

import fmt "core:fmt"
import rl "vendor:raylib"

TimerType :: enum {
	OneShot,
	Repeating,
}

Timer :: struct {
	duration:    f32,
	currentTime: f32,
	running:     bool,
	type:        TimerType,
}

timerUpdate :: proc(timer: ^Timer, owner: ^$T, onComplete: proc(self: ^T)) {
	assert(onComplete != nil)
	dt := rl.GetFrameTime()

	if !timer.running {
		return
	}

	timer.currentTime += dt
	if timer.currentTime >= timer.duration {
		onComplete(owner)
		if timer.type == .OneShot {
			timer.running = false
		} else {
			timer.currentTime = 0
		}
	}
}

timerStart :: proc(timer: ^Timer, owner: ^$T, onStart: proc(self: ^T)) {

	assert(timer.duration > 0)
	timer.running = true
	timer.currentTime = 0
	if onStart != nil {
		onStart(owner)
	}
}

timerPause :: proc(timer: ^Timer) {
	if !timer.running {
		return
	}

	timer.running = false
}

timerStop :: proc(timer: ^Timer) {
	timer.running = false
	timer.currentTime = 0
}

timerIsRunning :: proc(timer: ^Timer) -> bool {
	return timer.running && timer.currentTime < timer.duration
}
