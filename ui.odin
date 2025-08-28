package main

import rl "vendor:raylib"
import "core:fmt"

Rect :: struct {
    minx, miny, maxx, maxy: f32,
}

UiContent :: struct {
    top_banner: Rect,
    left_sidebar: Rect,
    center: Rect,
    right_sidebar: Rect,
    bottom_banner: Rect
}

UI_CONTENT: UiContent

cut_left :: proc(rect: ^Rect, a: f32) -> Rect {
    minx := rect.minx
    rect.minx = min(rect.maxx, rect.minx + a)
    return Rect{minx, rect.miny, rect.minx, rect.maxy}
}

cut_right :: proc(rect: ^Rect, a: f32) -> Rect {
    maxx := rect.maxx
    rect.maxx = max(rect.minx, rect.maxx - a)
    return Rect{rect.maxx, rect.miny, maxx, rect.maxy}
}

cut_top :: proc(rect: ^Rect, a: f32) -> Rect {
    miny := rect.miny
    rect.miny = min(rect.maxy, rect.miny + a)
    return Rect{rect.minx, miny, rect.maxx, rect.miny}
}

cut_bottom :: proc(rect: ^Rect, a: f32) -> Rect {
    maxy := rect.maxy
    rect.maxy = max(rect.miny, rect.maxy - a)
    return Rect{rect.minx, rect.maxy, rect.maxx, maxy}
}

rect_to_raylib :: proc(rect: Rect) -> rl.Rectangle {
    width := max(0, rect.maxx - rect.minx)
    height := max(0, rect.maxy - rect.miny)
    return rl.Rectangle{
        x = rect.minx,
        y = rect.miny,
        width = width,
        height = height,
    }
}

get_width_height :: proc(rect: Rect) ->(f32, f32) {
    width := max(0, rect.maxx - rect.minx)
    height := max(0, rect.maxy - rect.miny)
    return width, height
}

draw_rect :: proc(rect: Rect, color: rl.Color, outline_color: rl.Color = rl.BLACK) {
    rl_rect := rect_to_raylib(rect)
    rl.DrawRectangleRec(rl_rect, color)
    rl.DrawRectangleLinesEx(rl_rect, 2, outline_color)
}

is_colliding_with_mouse :: proc(rect: Rect) -> bool {
    mouse_pos := rl.GetMousePosition()
    rect := rect_to_raylib(rect)
    return  rl.CheckCollisionPointRec(mouse_pos, rect)
}

draw_text_in_rect :: proc(text: cstring, rect: Rect, font_size: i32, color: rl.Color) {
    text_width := rl.MeasureText(text, font_size)
    rect_width := rect.maxx - rect.minx
    rect_height := rect.maxy - rect.miny
    
    x := rect.minx + (rect_width - f32(text_width)) / 2
    y := rect.miny + (rect_height - f32(font_size)) / 2

    rl.DrawText(text, i32(x), i32(y), font_size, color)
}

ui_initial_setup :: proc() {
    width :f32= 3840
    height :f32= 2160
    layout := Rect{0,0, width, height}
    top_bar := cut_top(&layout, (height*0.1))
    bottom_bar := cut_bottom(&layout, (height*0.1))
    sidebar_left := cut_left(&layout, (width*0.1))
    sidebar_right := cut_right(&layout, (width*0.1))

    UI_CONTENT = UiContent{
        top_banner = top_bar,
        left_sidebar = sidebar_left,
        center = layout,
        right_sidebar = sidebar_right,
        bottom_banner = bottom_bar
    }
}