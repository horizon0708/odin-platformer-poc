package game

import "core:fmt"
import "core:strings"
DebugOptions :: struct {
	show_colliders:      bool,
	debug_text_sections: map[string]map[string]string,
}


build_debug_text :: proc(debug: ^DebugOptions) -> (cstring, strings.Builder) {
	builder := strings.builder_make()
	for section, section_data in debug.debug_text_sections {

		fmt.sbprintf(&builder, "%s\n", section)
		for key, value in section_data {
			fmt.sbprintf(&builder, "\t%s: %s\n", key, value)
		}
		fmt.sbprintf(&builder, "\n")
	}

	return strings.to_cstring(&builder), builder
}


set_debug_text :: proc(section: string, key: string, value: string) {
	if _, ok := gameState.debug.debug_text_sections[section]; !ok {
		gameState.debug.debug_text_sections[section] = {}
	}
	section_data := &gameState.debug.debug_text_sections[section]
	section_data[key] = value
}
