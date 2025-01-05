package game

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

routineUpdate :: proc(
	entity: ^GameEntity,
	gameState: ^GameState,
) -> (
	updatedEntity: ^GameEntity,
	done: bool,
) {
	updatedEntity = entity

	routine := (&(entity.routine.(Routine))) or_return

	if routine.currentStep >= len(routine.steps) {
		return updatedEntity, false
	}

	step := routine.steps[routine.currentStep]
	switch step in step {
	case MoveToPosition:
	// if movement.position == step.to {
	// 	routine.currentStep += 1
	// } else {
	// 	entity.shared.velocity = linalg.normalize0(step.to - movement.position)
	// }
	// movement.position = step.to
	case HoldPosition:
	// movement.position = movement.position
	}

	return updatedEntity, true
}
