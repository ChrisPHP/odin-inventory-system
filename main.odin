package main

import "core:fmt"
import rl "vendor:raylib"
import "core:mem"

main :: proc() {
    tracking_allocator: mem.Tracking_Allocator
    mem.tracking_allocator_init(&tracking_allocator, context.allocator)
    defer mem.tracking_allocator_destroy(&tracking_allocator)
    context.allocator = mem.tracking_allocator(&tracking_allocator)
    defer {
        fmt.printfln("MEMORY SUMMARY")
        for _, leak in tracking_allocator.allocation_map {
            fmt.printfln(" %v leaked %m", leak.location, leak.size)
        }
        for bad_free in tracking_allocator.bad_free_array {
            fmt.printfln(" %v allocation %p was freed badly", bad_free.location, bad_free.memory)
        }
    }
    
    rl.InitWindow(3840, 2160, "Inventory System")
    rl.SetTargetFPS(60)

    init_item_database()
    ui_initial_setup()

    inventory_section := UI_CONTENT.center
    inv_width, inv_height := get_width_height(inventory_section)
    cut_bottom(&inventory_section, inv_height*0.30)

    for !rl.WindowShouldClose() {
        r_key_pressed := rl.IsKeyPressed(rl.KeyboardKey.R)
        e_key_pressed := rl.IsKeyPressed(rl.KeyboardKey.E)

        if r_key_pressed {
            new_item, ok := create_item(3, 10)
            ok = add_item(new_item)
        }

        if e_key_pressed {
            new_item, ok := create_item(1, 1)
            ok = add_item(new_item)
        }

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        draw_rect(inventory_section, rl.GRAY, rl.WHITE)
        draw_inventory_ui(inventory_section)

        rl.EndDrawing()
    }

    rl.CloseWindow()

    delete(ITEM_DB)
}