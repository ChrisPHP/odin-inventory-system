package main

import "core:fmt"
import rl "vendor:raylib"

ItemType :: enum {
    NONE,
    TOOL,
    FOOD,
    BLOCK
}

ItemInfo :: struct {
    id: int,
    name: string,
    description: string,
    stack: int,
    type: ItemType,
    stack_limit: int,
}

ItemDatabase :: map[int]ItemInfo
ITEM_DB: ItemDatabase

INVENTORY: [30]ItemInfo

init_item_database :: proc() {
    ITEM_DB = make(ItemDatabase)

    register_item({1, "Pickaxe", "A Simple pickaxe.", 0, .TOOL, 1})
    register_item({2, "Sword", "A reliable steel sword.", 0, .TOOL, 1})
    register_item({3, "Strawberry", "A fresh, tasty strawberry.", 0, .FOOD, 64})
    register_item({4, "Raspberry", "A fresh, sweet raspberry.", 0, .FOOD, 64})
    register_item({5, "Stone Block", "A solid block of stone.", 0, .BLOCK, 64})
    register_item({6, "Wood Planks", "Processed wooden planks.", 0, .BLOCK, 64})
}

register_item :: proc(item: ItemInfo) {
    ITEM_DB[item.id] = item
}

create_item :: proc(id: int, stack_count: int = 1) -> (ItemInfo, bool) {
    template, exists := ITEM_DB[id]
    if !exists {
        return {}, false
    }

    item := template
    item.stack = clamp(stack_count, 0, template.stack_limit)
    return item, true
}

can_stack :: proc(a,b: ItemInfo) -> bool {
    return a.id == b.id && a.stack < a.stack_limit
}

add_item :: proc(item: ItemInfo) -> bool {
    if item.stack < 0 {
        return false
    }

    remaining := item.stack

    for &i in INVENTORY {
        if can_stack(i, item) {
            can_add := i.stack_limit - i.stack
            add_amount := min(remaining, can_add)
            i.stack += add_amount
            remaining -= add_amount

            if remaining <= 0 {
                return true
            }
        }
    }

    if remaining > 0 {
        for &i in INVENTORY {
            if i.id == 0 {
                new_item := item
                new_item.stack = min(remaining, item.stack_limit)
                remaining -= new_item.stack

                i = new_item
                if remaining <= 0 {
                    return true
                }
            }
        }
    }

    return remaining == 0
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

        section_rect := cut_left(&row_rect, inv_width/10)
        cut_right(&section_rect, 25)
        draw_rect(section_rect, rl.WHITE,rl.BLACK)

        split_rect := cut_top(&section_rect, 50)
        text := fmt.ctprintf("%v", i.name)
        stack := fmt.ctprintf("%v", i.stack)
        draw_text_in_rect(text, split_rect, 40, rl.BLACK)
        draw_text_in_rect(stack, section_rect, 40, rl.BLACK)
        index += 1
    }
}