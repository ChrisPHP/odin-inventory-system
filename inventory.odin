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

HeldItemInfo :: struct {
    rect: rl.Rectangle,
    item: ItemInfo,
    holding: bool,
    item_index: int
}

ItemDatabase :: map[int]ItemInfo
ITEM_DB: ItemDatabase

INVENTORY: [30]ItemInfo

HELD_ITEM := HeldItemInfo{
    rect=rl.Rectangle{},
    item=ItemInfo{},
    holding=false
}

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

    remaining = try_stack_existing(item, remaining)
    if remaining <= 0 {
        return true
    }

    remaining = try_place_in_empty_slots(item, remaining)

    return remaining == 0
}

add_item_specific_index :: proc(item: ItemInfo, index: int, new_slot: bool = false) -> int {
    if item.stack < 0 || index < 0 || index >= len(INVENTORY) {
        return item.stack
    }

    remaining := item.stack
    slot := &INVENTORY[index]

    i := INVENTORY[index]
    if can_stack(slot^, item) {
        add_amount := min(remaining, slot.stack_limit - slot.stack)
        slot.stack += add_amount
        remaining -= add_amount
    } else if i.id == 0 {
        new_item := item
        new_item.stack = min(remaining, item.stack_limit)
        remaining -= new_item.stack
        INVENTORY[index] = new_item
    }

    return remaining
}

try_stack_existing :: proc(item: ItemInfo, remaining: int) -> int {
    current_remaining := remaining

    for &slot in INVENTORY {
        if !can_stack(slot, item) {
            continue
        }

        add_amount := min(current_remaining, slot.stack_limit - slot.stack)
        slot.stack += add_amount
        current_remaining -= add_amount

        if current_remaining <= 0 {
            break
        }
    }

    return current_remaining
}

try_place_in_empty_slots :: proc(item: ItemInfo, remaining: int) -> int {
    current_remaining := remaining

    for &slot in INVENTORY {
        if slot.id != 0 {
            continue
        }
        new_item := item
        new_item.stack = min(current_remaining, item.stack_limit)
        current_remaining -= new_item.stack

        slot = new_item

        if current_remaining <= 0 {
            break
        }
    }

    return current_remaining
}

remove_item :: proc(item_id, amount: int) -> int {
    removed := 0

    for &i in INVENTORY {
        if i.id == item_id {
            take := min(i.stack, amount - removed)
            i.stack  -= take
            removed += take

            if i.stack <= 0 {
                i = ItemInfo{}
            }

            if removed >= amount {
                break
            }
        }
    }

    return removed
}

item_pickup :: proc(item: ItemInfo, index: int, item_rect: Rect) {
    mouse_pressed := rl.IsMouseButtonPressed(rl.MouseButton.LEFT)
    rect := rect_to_raylib(item_rect)
    if mouse_pressed && is_colliding_with_mouse(item_rect) {
        HELD_ITEM = {
            rect=rect,
            item=item,
            holding=true,
            item_index=index
        }
        
    }
}

item_on_release_rect :: proc(rect: Rect) -> bool {
    return HELD_ITEM.holding && rl.IsMouseButtonReleased(rl.MouseButton.LEFT) && is_colliding_with_mouse(rect)
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
    for &i, array_index in INVENTORY {
        if index == 10 {
            cut_top(&new_inv_rect, 25)
            row_rect = cut_top(&new_inv_rect, inv_height/3.1)
            index = 0
        }

        section_rect := cut_left(&row_rect, inv_width/10)
        cut_right(&section_rect, 25)
        draw_rect(section_rect, rl.WHITE,rl.BLACK)

        //Check if held item is dropped onto a slot
        if item_on_release_rect(section_rect) {
            remaining := add_item_specific_index(HELD_ITEM.item, array_index)
            if remaining > 0 {
                fmt.println(remaining)
                INVENTORY[HELD_ITEM.item_index].stack = remaining
            } else {
                INVENTORY[HELD_ITEM.item_index] = ItemInfo{}
            }
            HELD_ITEM.holding = false
        }

        if i.id != 0  {
            item_pickup(i, array_index, section_rect)
            split_rect := cut_top(&section_rect, 50)
            text := fmt.ctprintf("%v", i.name)
            stack := fmt.ctprintf("%v", i.stack)
            draw_text_in_rect(text, split_rect, 40, rl.BLACK)
            draw_text_in_rect(stack, section_rect, 40, rl.BLACK)
        } 
        index += 1
    }

    //Return held item to original place when released
    if HELD_ITEM.holding {
        mouse_pos := rl.GetMousePosition()
        if rl.IsMouseButtonDown(rl.MouseButton.LEFT) {
            new_rect := rl.Rectangle{
                x=mouse_pos.x,
                y=mouse_pos.y,
                width=HELD_ITEM.rect.width,
                height=HELD_ITEM.rect.height
            }
            rl.DrawRectangleRec(new_rect, rl.BLUE)
        }
    }
}