package game

import "core:fmt"
import "core:math"
import "core:math/linalg"
import rl "vendor:raylib"

RoutineVariant :: union #no_nil {
	NoRoutine,
	Routine,
}

NoRoutine :: struct {}

Routine :: struct {
	repeat:      bool,
	steps:       [dynamic]RoutineStep,
	currentStep: int,
	timer:       Timer,
}

RoutineStep :: union {
	MoveToPosition,
	HoldPosition,
}

MoveToPosition :: struct {
	to: Vector2I,
}

HoldPosition :: struct {
	duration: f32,
}

updateRoutine :: proc(
	entity: ^GameEntity,
	gameState: ^GameState,
) -> (
	updatedEntity: ^GameEntity,
	done: bool,
) {
	updatedEntity = entity

	routine := (&(entity.routine.(Routine))) or_return

	step := routine.steps[routine.currentStep]
	switch step in step {
	case MoveToPosition:
		if entity.movement.position == step.to {
			entity.movement.direction = {0, 0}
			nextRoutineStep(routine)
		} else {
			x := math.sign(f32(step.to.x - entity.movement.position.x))
			y := math.sign(f32(step.to.y - entity.movement.position.y))
			entity.movement.direction = linalg.normalize0(rl.Vector2{x, y})
		}
	case HoldPosition:
		timerUpdate(&routine.timer, routine, nextRoutineStep)
	}

	return updatedEntity, true
}

nextRoutineStep :: proc(routine: ^Routine) {
	nextStepIndex := routine.currentStep + 1
	if nextStepIndex >= len(routine.steps) {
		if !routine.repeat {
			return
		}
		nextStepIndex = 0
	}

	routine.currentStep = nextStepIndex
	nextStep := routine.steps[routine.currentStep]
	switch nextStep in nextStep {
	case MoveToPosition:
	// noop
	case HoldPosition:
		routine.timer.duration = nextStep.duration
		timerStart(&routine.timer, routine, nil)
	}
}
