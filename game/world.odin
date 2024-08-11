package main

import "core:math/linalg"


TILE_CHUNK_UNINITILIZED : i32 : max(i32)
TILE_COUNT_PER_WIDTH    : i32 : 10 //x axis
TILE_COUNT_PER_HEIGHT   : i32 : 10 //y axis
TILE_COUNT_PER_BREADTH  : i32 : 10 //z axis


WorldPos :: struct{
	chunk  : vec3i,
	offset : vec3,
}


EntityNode  :: struct {
	entity_index : EntityIndex,
	next : ^EntityNode,
}


WorldChunk :: struct {
	pos      : vec3i,
	entities : [dynamic]EntityIndex,
}


/**
	World is a hashmap of chunk 
	so that all the algorithms are basic hashmap algorithms
*/

World :: struct {
	csim             : vec3, // chunk size in meters

	//hashmap
	chunk_hash       : map[i32][dynamic]WorldChunk,
	meters_to_pixels : u32,
}

world_add_chunk :: proc(world: ^World, pos : vec3i){

	new_chunk : WorldChunk = {pos = pos}

	hash := 19 * abs(pos.x) + 7 + abs(pos.y)

	if world.chunk_hash[hash] == nil{
		world.chunk_hash[hash] = make([dynamic]WorldChunk)
	}

	head_chunk := &world.chunk_hash[hash]

	append(head_chunk, new_chunk)
}

//this dosen't add the pos
_world_chunk_get :: proc(world: ^World, pos: vec3i) -> ^WorldChunk{
	hash := 19 * abs(pos.x) + 7 + abs(pos.y)

	if world.chunk_hash[hash] == nil{
		return nil
	}else{
		head := &world.chunk_hash[hash]

		for &chunk in head{
			if chunk.pos == pos{
				return &chunk
			}
		}

		return nil
	}

}

world_chunk_get :: proc(world: ^World, pos: vec3i) -> ^WorldChunk{
	curr := _world_chunk_get(world, pos) 
	if curr == nil{
		world_add_chunk(world, pos)
	}
	return  _world_chunk_get(world, pos)
}


/*
	Changes the given index to another index
*/
world_update_entity_index :: proc(
	world: ^World, 
	pos: WorldPos, 
	old_index, new_index : EntityIndex){


	if old_index == 0 || new_index == 0 do return

	chunk := world_chunk_get(world, pos.chunk)


	for item, index in chunk.entities{
		if item == old_index{
			unordered_remove(&chunk.entities, index)
			append(&chunk.entities, new_index)
			break
		}
	}

}

/**
 * Removes the entity inex
 */
world_remove_entity :: proc(world: ^World, old_p: WorldPos, entity_index : EntityIndex){
	if entity_index == 0 do return

	chunk := world_chunk_get(world, old_p.chunk)

	for item, index in chunk.entities{
		if item == entity_index{
			unordered_remove(&chunk.entities, index)
			break
		}
	}
}

/**
 * It changes the chunk it which it should belong 
 * i.e. remove it from the chunk from which it belonged
 *      get the chunk which the new position belongs and add to it
 */

world_update_entity_location :: proc(world: ^World, entity_index : EntityIndex, entity: ^LowEntity, new_p : WorldPos){

	if entity_index == 0 do return

	old_p := entity.world_pos

	if new_p.chunk == old_p.chunk  && new_p.offset == old_p.offset do return

	if new_p.chunk.x != TILE_CHUNK_UNINITILIZED{

		//this means that the old position was initilized and it's in the world
		if old_p.chunk.x != TILE_CHUNK_UNINITILIZED{

			chunk := world_chunk_get(world, old_p.chunk)

			for item, index in chunk.entities{
				if entity_index == item{
					unordered_remove(&chunk.entities, index)
				}
			}
		}

		/* Add to new po's chunk */

		chunk := world_chunk_get(world, new_p.chunk)
		found := false

		for item in chunk.entities{
			if item == entity_index{
				found = true
				break
			}
		}

		if !found{
			append(&chunk.entities, entity_index)
		}
		entity.world_pos = new_p
	}
}





world_initilize :: proc(game: ^GameState){

	if game.world == nil{
		game.world = new(World)
	}

	game.world.chunk_hash = make_map(map[i32][dynamic]WorldChunk)
	game.world.csim = vec3{f32(TILE_COUNT_PER_WIDTH), f32(TILE_COUNT_PER_HEIGHT), f32(TILE_COUNT_PER_BREADTH)};

	for key, &chunk in game.world.chunk_hash
	{
		chunk        = {}
		chunk[0].pos.x  = TILE_CHUNK_UNINITILIZED;
	}

}

world_adjust_position :: proc(world: ^World, chunk_pos : ^i32, offset: ^f32, csim: f32) {
	extra_offset : i32

	extra_offset = i32(linalg.floor(offset^/csim))

	chunk_pos^ += extra_offset
	offset^    -= f32(extra_offset) * csim
}


world_map_to_world_pos :: proc(world: ^World, origin: WorldPos, offset: vec3) -> WorldPos{
	csim := world.csim
	result := origin
	result.offset += offset

	world_adjust_position(world, &result.chunk.x, &result.offset.x, csim.x)
	world_adjust_position(world, &result.chunk.y, &result.offset.y, csim.y)
	world_adjust_position(world, &result.chunk.z, &result.offset.z, csim.z)
	return result
}

world_subtract :: proc(world: ^World, a: WorldPos, b: WorldPos) -> vec3{
	result: vec3 

	result.y = f32(a.chunk.y) - f32(b.chunk.y)
	result.z = f32(a.chunk.z) - f32(b.chunk.z)
	result.x = f32(a.chunk.x) - f32(b.chunk.x)

	result = result * world.csim
	result = result + (a.offset - b.offset)
	return result
}


















