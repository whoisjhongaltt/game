package main 

import rl "vendor:raylib"
import "core:dynlib"
import "core:os"
import "core:fmt"
import win32 "core:sys/windows"

/* *
	Raylib's coodinate system
*/

window_width  :i32: 1000
window_height :i32: 800


GameApi :: struct {
	init    : proc (game_state : rawptr),
	render  : proc (),
	deinit  : proc () -> rawptr,
	
	lib_handle       : dynlib.Library,
	dll_time         : os.File_Time,
	game_api_version : i32,
	game_loaded      : bool,
}


PlatformState :: struct {
	using game_api : GameApi,
	game_state     : rawptr
}

platform : PlatformState

update_game_api :: proc(){
	/*  
		NOTE :: use handle instead of name
	*/
	
	dll_time, dll_time_err := os.last_write_time_by_name("./game.dll")
	reload := dll_time_err == os.ERROR_NONE && platform.dll_time != dll_time

	if reload{

		if platform.game_loaded{

			platform.game_state = platform.deinit()

			dynlib.unload_library(platform.lib_handle)
			platform.init   = nil
			platform.render = nil
			platform.deinit = nil
			platform.lib_handle = nil
		}


		win32.DeleteFileW(win32.L("./new_game.dll"))
		win32.CopyFileW(win32.L("./game.dll"), win32.L("./new_game.dll"), win32.TRUE)

		lib, lib_ok := dynlib.initialize_symbols(&platform.game_api, "./new_game.dll", "game_", "lib_handle")

		if lib_ok{
			platform.init(platform.game_state)
		}else{
			fmt.println(dynlib.last_error())
		}


		platform.game_loaded = lib_ok
		platform.dll_time = dll_time
	}

}

main :: proc(){


	using rl

	InitWindow(window_width, window_height, "Coodinates")




	SetTargetFPS(60)

	for !WindowShouldClose(){

		update_game_api()


		if platform.game_loaded{
			platform.render()
		}else{
			BeginDrawing()
				ClearBackground(RAYWHITE)
				DrawText("Game not loaded", window_width/2, window_height/2, 30, BLACK)
			EndDrawing()
		}

	}
}