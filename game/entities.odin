package main

EntityIndex :: u32


LowEntity :: struct {
	world_pos : WorldPos,
	using sim : SimEntity,
}


EntityFlagsEnum :: enum{
	entity_flag_simming,
	entity_undo,
	entity_flag_dead,
	entity_flag_falling,
	entity_flag_on_ground,
	entity_flag_selected,
	entity_flag_vflipped,
	eneity_anim_stretch_side, //if true then width else height
}

EntityFlags :: bit_set[EntityFlagsEnum]


AnimationState ::  enum u8{
	IDLE_FRONTSIDE,
	IDLE_BACKSIDE,

	WALK_FRONTSIDE,
	WALK_BACKSIDE,
	WALK_RIGHT,

	JUMP_ATTACK,
	JUMP,
}


TexOrient :: enum u8{
	flat, straight
}

EntityType:: enum u8{
	null,
	player,
	torch,
	grass,
	enemy,
	wall,
	house,
	tree,
	grimchild,
	stone,
	dragon,
};

SimEntity :: struct {
	type     : EntityType,
	pos, dP  : vec3,
	scale    : f32,
	orient   : TexOrient,
	asset_id : string,
	flags    : EntityFlags,

	storage_index : EntityIndex,

	light_index, anim_index, anim_step: u32,

	anim_state : AnimationState,
	direction  : vec3,
}



entity_add_low_entity :: proc(game: ^GameState, type: EntityType, pos: WorldPos){

	new_low : LowEntity = {}
	new_low.storage_index = u32(len(game.low_entities))
	new_low.type          = type
	new_low.world_pos.chunk.x = TILE_CHUNK_UNINITILIZED
	new_low.world_pos.chunk.y = TILE_CHUNK_UNINITILIZED

	if type != .null && new_low.storage_index > 0{
		world_update_entity_location(game.world, new_low.storage_index, &new_low, pos)
	}
	append(&game.low_entities, new_low)
}








