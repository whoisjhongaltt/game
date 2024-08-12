package main 

import rl "vendor:raylib"
import "core:fmt"
import "base:runtime"


/* Get hot reloading working */



GameState :: struct {
	initilized : bool,
	cam        : rl.Camera3D,
	cam_bounds : mat3,
	game_text  : cstring,
	player_index : EntityIndex,
	world        :^World,
	low_entities : [dynamic]LowEntity,

	cube_mesh    : rl.Mesh,
	cube_model   : rl.Model,
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
		cam.position = {0, 35, 30}
		cam.target   = {0,   0,  0}
		cam.up       = {0, 1, 0}
		cam.fovy     = 45.0
		cam.projection = .PERSPECTIVE
		cam_bounds[0] = {-50, -3, -50}
		cam_bounds[1] = {50, 3, 50}

		world_initilize(game_state)
		entity_add_low_entity(game_state, .null,{}, {})
		entity_add_low_entity(game_state, .player, {chunk={0,0,0}, offset={5, 0, 5}},{}, rl.YELLOW)

		for i in 0..<TILE_COUNT_PER_BREADTH{
			for j in 0..<TILE_COUNT_PER_WIDTH{
				entity_add_low_entity(game_state, .wall, {offset={f32(i), 0, f32(j)}},{})
			}
			entity_add_low_entity(game_state, .wall, {offset={f32(i), 1, f32(0)}},{}, rl.BLUE)
			entity_add_low_entity(game_state, .wall, {offset={f32(0), 1, f32(i)}},{}, rl.BLUE)
			entity_add_low_entity(game_state, .wall, {offset={f32(i), 1, f32(TILE_COUNT_PER_WIDTH-1)}},{}, rl.BLUE)
			entity_add_low_entity(game_state, .wall, {offset={f32(TILE_COUNT_PER_WIDTH-1), 1, f32(i)}},{}, rl.BLUE)
		}

		offset :i32= 7
		for i in 0..<TILE_COUNT_PER_BREADTH{

			for j in 0..<TILE_COUNT_PER_BREADTH{
				entity_add_low_entity(game_state, .wall, {chunk={0, 0, -1}, offset={f32(i), 5, f32(j-offset)}})
			}
			entity_add_low_entity(game_state, .wall, {chunk={0, 0, -1},offset={f32(i), 6, f32(0-offset)}},{},  rl.BLUE)
			entity_add_low_entity(game_state, .wall, {chunk={0, 0, -1},offset={f32(0), 6, f32(i-offset)}},{},  rl.BLUE)
			entity_add_low_entity(game_state, .wall, {chunk={0, 0, -1},offset={f32(i), 6, f32(TILE_COUNT_PER_WIDTH-1-offset)}},{},  rl.BLUE)
			entity_add_low_entity(game_state, .wall, {chunk={0, 0, -1},offset={f32(TILE_COUNT_PER_WIDTH-1), 6, f32(i)-f32(offset)}},{},  rl.BLUE)
		}

		for i in 1..<offset+3{
			entity_add_low_entity(game_state, .wall, {chunk={0, 0, 0},offset={f32(8), f32(i)/2.0, -f32(i)}},{.entity_rotated}, rl.RED)
		}
	}

	game_state.cube_mesh  = rl.GenMeshCube(1, 1, 1)
	game_state.cube_model = rl.LoadModelFromMesh(game_state.cube_mesh)

	game_state.initilized = true

}

game_render_entities :: proc(game: ^GameState, region: ^SimRegion){
	rl.BeginDrawing()
	rl.ClearBackground(rl.BLACK)

	//rl.UpdateCamera(&game.cam, .THIRD_PERSON)
	rl.DrawFPS(0, 0)

	rl.BeginMode3D(game.cam)
	for &entity in &region.entities{

		#partial switch(entity.type){
			case .player: {

				pos := entity.pos
				pos.y += 1 
				rl.DrawCubeWiresV(pos, {1,1,1}, rl.WHITE)
				rl.DrawCubeV(pos, {1,1,1}, entity.color)
			}
			case .wall: {
				//rl.DrawCubeV(entity.pos, {1,1,1}, entity.color)

				if .entity_rotated in entity.flags{
					rl.DrawModelEx(game_state.cube_model, entity.pos, {1, 0, 0}, -65, {1,1,1}, entity.color)
					rl.DrawModelWiresEx(game_state.cube_model, entity.pos, {1, 0, 0}, -65, {1,1,1}, rl.WHITE)
				}else{
					rl.DrawModelEx(game_state.cube_model, entity.pos, {0, 0, 0}, 0, {1,1,1}, entity.color)
				}
				//rl.DrawCubeWiresV(entity.pos, {1,1,1}, rl.WHITE)
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
	sim_region := sim_begin(game_state, {}, game_state.cam_bounds)

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












