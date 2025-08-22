package main

import "core:fmt"
import rl "vendor:raylib"

ItemInfo :: struct {
    name: string,
    description: string,
    stack: int,
    stack_limit: int,
    id: int
}

INVENTORY: [30]ItemInfo


inventory_handler :: proc() {
    fmt.println(INVENTORY)
}


draw_inventory_ui :: proc(inv_rect: Rect) {
    new_inv_rect := inv_rect
    cut_left(&new_inv_rect, 50)
    cut_right(&new_inv_rect, 50)
    cut_top(&new_inv_rect, 50)
    cut_bottom(&new_inv_rect, 50)
    inv_width, inv_height := get_width_height(new_inv_rect)

    index := 0
    row_rect := cut_top(&new_inv_rect, inv_height/3.1)
    for i in INVENTORY {
        if index == 10 {
            cut_top(&new_inv_rect, 25)
            row_rect = cut_top(&new_inv_rect, inv_height/3.1)
            index = 0
        }

        section_rect := cut_right(&row_rect, inv_width/10)
        cut_left(&section_rect, 25)
        draw_rect(section_rect, rl.WHITE,rl.BLACK)

        text := fmt.ctprintf("%v", i.id)
        draw_text_in_rect(text, section_rect, 40, rl.BLACK)
        index += 1
    }
}