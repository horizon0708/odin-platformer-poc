package game;

import rl "vendor:raylib"

main :: proc()
{

    screen_width :i32 = 800;
    screen_height :i32 = 450;

    rl.InitWindow(screen_width, screen_height, "game");
    defer rl.CloseWindow();

    rl.SetTargetFPS(60);

    for !rl.WindowShouldClose()
    {
        {
            rl.BeginDrawing();
            defer rl.EndDrawing();
            rl.ClearBackground(rl.RAYWHITE);

            rl.DrawText("Congrats! You created your first window!", 190, 200, 20, rl.LIGHTGRAY);
        }
    }
}