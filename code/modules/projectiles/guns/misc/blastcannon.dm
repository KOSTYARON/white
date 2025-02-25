/**
 * A gun that consumes a TTV to shoot an projectile with equivalent power.
 *
 * It's basically an immovable rod launcher.
 */
/obj/item/gun/blastcannon
	name = "трубопистолет"
	desc = "Труба приваренная к прикладу пистолета с механическим курком. Сверху на трубе есть отверстие и если в него заглянуть, то можно увидеть подпружиненное колесо. Довольно небольшой, можно таскать в сумке."
	icon = 'icons/obj/guns/wide_guns.dmi'
	icon_state = "blastcannon_empty"
	lefthand_file = 'icons/mob/inhands/weapons/64x_guns_left.dmi'
	righthand_file = 'icons/mob/inhands/weapons/64x_guns_right.dmi'
	inhand_x_dimension = 64
	base_pixel_x = -2
	pixel_x = -2
	inhand_icon_state = "blastcannon_empty"
	w_class = WEIGHT_CLASS_NORMAL
	force = 10
	fire_sound = 'sound/weapons/blastcannon.ogg'
	item_flags = NONE
	clumsy_check = FALSE
	randomspread = FALSE

	/// The TTV this contains that will be used to create the projectile
	var/obj/item/transfer_valve/bomb
	/// Additional volume added to the gasmixture used to calculate the bombs power.
	var/reaction_volume_mod = 0
	/// Whether the gases are reacted once before calculating the range
	var/prereaction = TRUE
	/// How many times gases react() before calculation. Very finnicky value, do not mess with without good reason.
	var/reaction_cycles = 3
	/// The maximum power the blastcannon is capable of reaching
	var/max_power = INFINITY

	// For debugging/badminry
	/// Whether you can fire this without a bomb.
	var/bombcheck = TRUE
	/// The range this defaults to without a bomb for debugging and badminry
	var/debug_power = 0


/obj/item/gun/blastcannon/debug
	debug_power = 80
	bombcheck = FALSE

/obj/item/gun/blastcannon/Initialize()
	. = ..()
	if(!pin)
		pin = new
	AddElement(/datum/element/update_icon_updates_onmob)

/obj/item/gun/blastcannon/Destroy()
	if(bomb)
		QDEL_NULL(bomb)
	return ..()

/obj/item/gun/blastcannon/attack_self(mob/user)
	if(bomb)
		bomb.forceMove(user.loc)
		user.put_in_hands(bomb)
		user.visible_message(span_warning("[user] отсоединяет [bomb] от [src]."))
		bomb = null
		name = initial(name)
		desc = initial(desc)
	update_icon()
	return ..()

/obj/item/gun/blastcannon/update_icon_state()
	. = ..()
	icon_state = "[base_icon_state]_[bomb ? "loaded" : "empty"]"
	inhand_icon_state = icon_state

/obj/item/gun/blastcannon/attackby(obj/item/transfer_valve/bomb_to_attach, mob/user)
	if(!istype(bomb_to_attach))
		return ..()

	if(!bomb_to_attach.tank_one || !bomb_to_attach.tank_two)
		to_chat(user, span_warning("И что за польза от незавершенной бомбы?"))
		return FALSE
	if(!user.transferItemToLoc(bomb_to_attach, src))
		to_chat(user, span_warning("[bomb_to_attach] похоже, застряла в твоей руке!"))
		return FALSE

	user.visible_message(span_warning("[user] присоединил [bomb_to_attach] к [src]!"))
	bomb = bomb_to_attach
	name = "пушка уничтожитель"
	desc = "Самодельное устройство используемое для концентрации энергии от взрыва бомбы в направленную волну."
	update_icon()
	return TRUE

/// Handles the bomb power calculations
/obj/item/gun/blastcannon/proc/calculate_bomb()
	if(!istype(bomb) || !istype(bomb.tank_one) || !istype(bomb.tank_two))
		return 0

	var/datum/gas_mixture/temp = new(max(reaction_volume_mod, 0))
	bomb.merge_gases(temp)

	if(prereaction)
		temp.react(src)
		var/prereaction_pressure = temp.return_pressure()
		if(prereaction_pressure < TANK_FRAGMENT_PRESSURE)
			return 0
	for(var/i in 1 to reaction_cycles)
		temp.react(src)

	var/pressure = temp.return_pressure()
	qdel(temp)
	if(pressure < TANK_FRAGMENT_PRESSURE)
		return 0
	return ((pressure - TANK_FRAGMENT_PRESSURE) / TANK_FRAGMENT_SCALE)


/obj/item/gun/blastcannon/afterattack(atom/target, mob/user, flag, params)
	if((!bomb && bombcheck) || (!target) || (get_dist(get_turf(target), get_turf(user)) <= 2))
		return ..()

	var/power =  bomb ? calculate_bomb() : debug_power
	power = min(power, max_power)
	QDEL_NULL(bomb)
	update_icon()

	var/heavy = power * 0.25
	var/medium = power * 0.5
	var/light = power
	user.visible_message(span_danger("[user] opens [bomb] on [user.ru_ego()] [name] and fires a blast wave at [target]!") ,span_danger("You open [bomb] on your [name] and fire a blast wave at [target]!"))
	playsound(user, "explosion", 100, TRUE)
	var/turf/starting = get_turf(user)
	var/turf/targturf = get_turf(target)
	message_admins("Blast wave fired from [ADMIN_VERBOSEJMP(starting)] at [ADMIN_VERBOSEJMP(targturf)] ([target.name]) by [ADMIN_LOOKUPFLW(user)] with power [heavy]/[medium]/[light].")
	log_game("Blast wave fired from [AREACOORD(starting)] at [AREACOORD(targturf)] ([target.name]) by [key_name(user)] with power [heavy]/[medium]/[light].")
	var/obj/projectile/blastwave/BW = new(loc, heavy, medium, light)
	BW.preparePixelProjectile(target, get_turf(src), params, 0)
	BW.fire()
	name = initial(name)
	desc = initial(desc)

/// The projectile used by the blastcannon
/obj/projectile/blastwave
	name = "взрывная волна"
	icon_state = "blastwave"
	damage = 0
	nodamage = FALSE
	movement_type = FLYING
	projectile_phasing = ALL		// just blows up the turfs lmao
	/// The maximum distance this will inflict [EXPLODE_DEVASTATE]
	var/heavyr = 0
	/// The maximum distance this will inflict [EXPLODE_HEAVY]
	var/mediumr = 0
	/// The maximum distance this will inflict [EXPLODE_LIGHT]
	var/lightr = 0

/obj/projectile/blastwave/Initialize(mapload, _heavy, _medium, _light)
	range = max(_heavy, _medium, _light, 0)
	heavyr = _heavy
	mediumr = _medium
	lightr = _light
	return ..()

/obj/projectile/blastwave/Range()
	. = ..()
	if(QDELETED(src))
		return

	heavyr = max(heavyr - 1, 0)
	mediumr = max(mediumr - 1, 0)
	lightr = max(lightr - 1, 0)

	if(heavyr)
		SSexplosions.highturf += loc
	else if(mediumr)
		SSexplosions.medturf += loc
	else if(lightr)
		SSexplosions.lowturf += loc
	else
		qdel(src)
		return

/obj/projectile/blastwave/ex_act()
	return
