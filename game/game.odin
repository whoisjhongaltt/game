package main 

import rl "vendor:raylib"
import "core:fmt"
import "base:runtime"


/* Get hot reloading working */


Entity :: struct {

}

GameState :: struct {
	initilized : bool,
	cam        : rl.Camera3D,
	cam_bounds : mat3,
	game_text  : cstring,
	player_index : EntityIndex,
	world        :^World,
	low_entities : [dynamic]LowEntity
}



game_state : ^GameState

@(export)
game_init :: proc (game_data : rawptr){

	if game_data != nil{
		old_game_state := cast(^GameState)game_data

		if old_game_state.initilized{
			game_state = old_game_state
		}
		game_state.game_text = "Samrat Ghale"
	}else{
		game_state    = new(GameState)
		using game_state
		cam.position = {0, 20, 20}
		cam.target   = {0,   0,  0}
		cam.up       = {0, 1, 0}
		cam.fovy     = 45.0
		cam.projection = .PERSPECTIVE
		cam_bounds[0] = {-20, -3, -20}
		cam_bounds[1] = {20, 3, 20}

		world_initilize(game_state)
		entity_add_low_entity(game_state, .null, {})
		entity_add_low_entity(game_state, .player, {})

		for i in 0..=9{
			for j in 0..=9{
				entity_add_low_entity(game_state, .wall, {offset={f32(i), 0, f32(j)}})
			}
		}

		for i in 0..=9{
			for j in 0..=9{
				entity_add_low_entity(game_state, .wall, {chunk={1, 0, 1}, offset={f32(i), 0, f32(j)}})
			}
		}
	}
	game_state.initilized = true

}

game_render_entities :: proc(game: ^GameState, region: ^SimRegion){
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLUE)

	//rl.UpdateCamera(&game.cam, .THIRD_PERSON)
	rl.DrawFPS(0, 0)

	rl.BeginMode3D(game.cam)
	for &entity in &region.entities{

		#partial switch(entity.type){
			case .player: {

				pos := entity.pos
				pos.y += 1 
				rl.DrawCubeWiresV(pos, {1,1,1}, rl.WHITE)
				rl.DrawCubeV(pos, {1,1,1}, rl.GREEN)
			}
			case .wall: {
				rl.DrawCubeV(entity.pos, {1,1,1}, rl.RED)
			}
		}
	}

	rl.EndMode3D()
	rl.EndDrawing()
}


@(export)
game_render :: proc(){ 

	center : WorldPos
	if game_state.player_index != 0{
		player := &game_state.low_entities[game_state.player_index]

		if player.type == .player{
			center = player.world_pos
		}
	}
	sim_region := sim_begin(game_state, center, game_state.cam_bounds)

	/*
		update movement
	*/

	game_render_entities(game_state, sim_region)
	for &entity in &sim_region.entities{

		#partial switch entity.type{
			case .player:{
				if rl.IsKeyPressed(.S){
					entity.pos.z += 1
				}
				if rl.IsKeyPressed(.D){
					entity.pos.x += 1
				}
				if rl.IsKeyPressed(.A){
					entity.pos.x -= 1
				}
				if rl.IsKeyPressed(.W){
					entity.pos.z -= 1
				}
			}
		}
	}


	sim_end(sim_region, game_state)
}


@(export)
game_deinit :: proc() -> rawptr{ 
	free(game_state)
	return nil;
}












