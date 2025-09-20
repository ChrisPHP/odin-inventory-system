package main

import "core:fmt"
import rl "vendor:raylib"
import "core:mem"
import "core:math/rand"

LEFT_MOUSE_DOWN := false
TEXTURE: rl.Texture
CELL_SIZE :: 16

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

    TEXTURE = rl.LoadTexture("assets/materials.png")

    init_item_database()
    ui_initial_setup()

    inventory_section := UI_CONTENT.center
    inv_width, inv_height := get_width_height(inventory_section)
    cut_bottom(&inventory_section, inv_height*0.30)

    for !rl.WindowShouldClose() {
        r_key_pressed := rl.IsKeyPressed(rl.KeyboardKey.R)
        e_key_pressed := rl.IsKeyPressed(rl.KeyboardKey.E)
        d_key_pressed := rl.IsKeyPressed(rl.KeyboardKey.D)
        g_key_pressed := rl.IsKeyPressed(rl.KeyboardKey.G)

        mouse_pos := rl.GetMousePosition()
        LEFT_MOUSE_DOWN = rl.IsMouseButtonDown(rl.MouseButton.LEFT)

        if r_key_pressed {
            new_item, ok := create_item(3, 10)
            index := rand.int31_max(29)
            add_item_specific_index(new_item, int(index), true)
    
        }

        if e_key_pressed {
            new_item, ok := create_item(1, 1)
            ok = add_item(new_item)
        }

        if d_key_pressed {
            remove_item(3, 5)
        }

        if g_key_pressed {
            item_index := rand.int31_max(6)+1
            new_item, ok := create_item(int(item_index), 10)
            index := rand.int31_max(29)   

            add_item_specific_index(new_item, int(index), true)
        }

        rl.BeginDrawing()
        rl.ClearBackground(rl.BLACK)

        
        draw_inventory_background(inventory_section, rl.Color({176, 137, 104, 255}),  rl.Color({127, 85, 57, 255}))
        draw_inventory_ui(inventory_section)

        rl.EndDrawing()
    }

    rl.CloseWindow()

    delete(ITEM_DB)
}