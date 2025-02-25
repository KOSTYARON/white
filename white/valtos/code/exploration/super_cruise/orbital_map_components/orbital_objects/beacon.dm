/datum/orbital_object/z_linked/beacon
	name = "Неопознанный Сигнал"
	mass = 0
	radius = 10
	can_dock_anywhere = TRUE
	render_mode = RENDER_MODE_BEACON
	//The attached event
	var/datum/ruin_event/ruin_event

/datum/orbital_object/z_linked/beacon/New()
	. = ..()
	var/datum/orbital_map/linked_map = SSorbits.orbital_maps[orbital_map_index]
	ruin_event = SSorbits.get_event()
	if(ruin_event?.warning_message)
		name = "[initial(name)] #[rand(1, 9)][linked_map.object_count][rand(1, 9)] ([ruin_event.warning_message])"
	else
		name = "[initial(name)] #[rand(1, 9)][linked_map.object_count][rand(1, 9)]"
	//Link the ruin event to ourselves
	ruin_event?.linked_z = src

/datum/orbital_object/z_linked/beacon/post_map_setup()
	//Orbit around the systems sun
	var/datum/orbital_map/linked_map = SSorbits.orbital_maps[orbital_map_index]
	set_orbitting_around_body(linked_map.center, 2000 + 25 * linked_z_level[1].z_value)

/datum/orbital_object/z_linked/beacon/weak
	name = "Слабый Сигнал"

//====================
// Asteroids
//====================

/datum/orbital_object/z_linked/beacon/ruin/asteroid
	name = "Астероид"
	render_mode = RENDER_MODE_DEFAULT

/datum/orbital_object/z_linked/beacon/ruinasteroid/New()
	. = ..()
	radius = rand(5, 15)

/datum/orbital_object/z_linked/beacon/ruin/asteroid/assign_z_level()
	var/datum/space_level/assigned_space_level = SSzclear.get_free_z_level()
	linked_z_level = list(assigned_space_level)
	assigned_space_level.orbital_body = src
	generate_asteroids(world.maxx / 2, world.maxy / 2, assigned_space_level.z_value, 120, rand(-0.5, 0), rand(40, 70))

/datum/orbital_object/z_linked/beacon/ruin/asteroid/post_map_setup()
	//Orbit around the systems central gravitional body
	//Pack closely together to make an asteriod belt.
	var/datum/orbital_map/linked_map = SSorbits.orbital_maps[orbital_map_index]
	set_orbitting_around_body(linked_map.center, 800 + 20 * rand(-19, 19))

//====================
// Regular Ruin Z-levels
//====================

/datum/orbital_object/z_linked/beacon/ruin/spaceruin
	name = "Неизвестный Сигнал"

/datum/orbital_object/z_linked/beacon/ruin/spaceruin/New()
	. = ..()
	SSorbits.ruin_levels++

/datum/orbital_object/z_linked/beacon/ruin/spaceruin/Destroy(force, ...)
	. = ..()
	SSorbits.ruin_levels--

/datum/orbital_object/z_linked/beacon/ruin/spaceruin/assign_z_level()
	var/datum/space_level/assigned_space_level = SSzclear.get_free_z_level()
	linked_z_level = list(assigned_space_level)
	assigned_space_level.orbital_body = src
	seedRuins(list(assigned_space_level.z_value), CONFIG_GET(number/space_budget), /area/space, SSmapping.space_ruins_templates)

/datum/orbital_object/z_linked/beacon/ruin/spaceruin/post_map_setup()
	//Orbit around the systems sun
	var/datum/orbital_map/linked_map = SSorbits.orbital_maps[orbital_map_index]
	set_orbitting_around_body(linked_map.center, 2000 + 25 * rand(40, 20))

//====================
// Random-Ruin z-levels
//====================
/datum/orbital_object/z_linked/beacon/ruin
	//The linked objective to the ruin, for generating extra stuff if required.
	var/datum/orbital_objective/linked_objective

/datum/orbital_object/z_linked/beacon/ruin/Destroy()
	//Remove linked objective.
	if(linked_objective)
		linked_objective.linked_beacon = null
		linked_objective = null
	. = ..()

/datum/orbital_object/z_linked/beacon/ruin/proc/assign_z_level()
	var/datum/space_level/assigned_space_level = SSzclear.get_free_z_level()
	linked_z_level = list(assigned_space_level)
	assigned_space_level.orbital_body = src
	generate_space_ruin(world.maxx / 2, world.maxy / 2, assigned_space_level.z_value, 100, 100, linked_objective, null, ruin_event)

/datum/orbital_object/z_linked/beacon/ruin/post_map_setup()
	//Orbit around the systems sun
	var/datum/orbital_map/linked_map = SSorbits.orbital_maps[orbital_map_index]
	set_orbitting_around_body(linked_map.center, 2000 + 25 * rand(40, 20))


//====================
//Stranded shuttles
//====================
/datum/orbital_object/z_linked/beacon/ruin/stranded_shuttle
	name = "Аварийный маяк"
	static_object = TRUE

/datum/orbital_object/z_linked/beacon/ruin/stranded_shuttle/assign_z_level()
	var/datum/space_level/assigned_space_level = SSzclear.get_free_z_level()
	linked_z_level = list(assigned_space_level)
	assigned_space_level.orbital_body = src
	generate_asteroids(world.maxx / 2, world.maxy / 2, assigned_space_level.z_value, 120, -0.4, 40)

/datum/orbital_object/z_linked/beacon/ruin/stranded_shuttle/post_map_setup()
	return

//====================
//Interdiction
//====================
/datum/orbital_object/z_linked/beacon/ruin/interdiction
	name = "Аварийный маяк"
	static_object = TRUE

/datum/orbital_object/z_linked/beacon/ruin/interdiction/assign_z_level()
	var/datum/space_level/assigned_space_level = SSzclear.get_free_z_level()
	linked_z_level = list(assigned_space_level)
	assigned_space_level.orbital_body = src

/datum/orbital_object/z_linked/beacon/ruin/interdiction/post_map_setup()
	return
