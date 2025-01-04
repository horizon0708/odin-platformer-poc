package game


// BaseEvent :: struct {
// 	sender: ^GameObject,
// }

// TimerCompleteEvent :: struct {
// 	using base: BaseEvent,
// }

// Event :: union {
// 	TimerCompleteEvent,
// }


// PubSub :: struct {
// 	eventSubscribers: map[i32][dynamic]i32,
// }

// getEventKey :: proc(event: Event) -> i32 {
// 	switch event in event {
// 	case TimerCompleteEvent:
// 		return 0
// 	case:
// 		return -1
// 	}
// }


// broadcast :: proc(event: Event, gameState: ^GameState) {
// 	eventKey := getEventKey(event)
// 	subscribers := gameState.pubsub.eventSubscribers[eventKey]
// 	for subscriberId in subscribers {
// 		if subscriber := gameState.gameObjects[subscriberId]; subscriber != nil {
// 			subscriber.on_event_received(event)
// 		} else {

// 		}
// 	}
// }
