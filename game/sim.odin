package main


/**
 * This file provides struct and functions to simulation a world 
 */

SimRegion :: struct{
	bounds       : mat3,
	center       : WorldPos,
	world        : ^World,
	entities     : #soa[dynamic]SimEntity,
}

sim_add_entity :: proc(
	game_state: ^GameState,
	region    : ^SimRegion,
	low_index :  EntityIndex,
	low       : ^LowEntity,
	entity_rel_pos : vec3 

	){


	entity : SimEntity 

	entity              = low.sim
	low.flags           += {.entity_flag_simming}
	entity.storage_index = low_index
	entity.pos           = entity_rel_pos

	append_soa(&region.entities, entity)
}



sim_begin :: proc(game: ^GameState, center: WorldPos, bounds: mat3) -> ^SimRegion{

	world : = game.world

	sim_region       := new(SimRegion)
	sim_region.world  = world
	sim_region.center = center
	sim_region.bounds = bounds

	min_pos := world_map_to_world_pos(world, sim_region.center, vec3(bounds[0])).chunk
	max_pos := world_map_to_world_pos(world, sim_region.center, vec3(bounds[1])).chunk

	for x in min_pos.x ..= max_pos.x{
		for y in min_pos.y ..= max_pos.y{
			for z in min_pos.z ..= max_pos.z{
				chunk := world_chunk_get(world, vec3i{i32(x), i32(y), i32(z)})

				if chunk != nil{
					for item in chunk.entities{
						entity := &game.low_entities[item]

						if .entity_flag_simming not_in entity.flags{
							entity_sim_space := world_subtract(world, entity.world_pos, center)
							sim_add_entity(game, sim_region, item, entity, entity_sim_space)
						}
					}
				}
			}
		}
	}

	return sim_region
}

sim_end :: proc(region: ^SimRegion, game: ^GameState){

	for &entity, index in &region.entities{

		low := &game.low_entities[entity.storage_index]
		entity.flags = low.flags
		low.sim = entity

		low.flags -= {.entity_flag_simming}

		new_pos := world_map_to_world_pos(region.world, region.center, entity.pos)
		old_pos := low.world_pos

		if old_pos.chunk != new_pos.chunk || old_pos.offset != new_pos.offset{
			world_update_entity_location(region.world, entity.storage_index, low, new_pos)
		}
	}

	free(region)
}




















