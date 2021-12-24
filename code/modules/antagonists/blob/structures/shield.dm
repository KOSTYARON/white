/obj/structure/blob/shield
	name = "крепкая масса"
	icon = BLOB_CURRENT_ICON
	icon_state = "strong"
	desc = "Твёрдая живая стена."
	var/damaged_desc = "Твёрдая живая стена."
	max_integrity = 150
	health_regen = BLOB_STRONG_HP_REGEN
	brute_resist = BLOB_BRUTE_RESIST * 0.5
	explosion_block = 3
	point_return = BLOB_REFUND_STRONG_COST
	atmosblock = TRUE
	armor = list(MELEE = 0, BULLET = 0, LASER = 0, ENERGY = 0, BOMB = 0, BIO = 0, RAD = 0, FIRE = 90, ACID = 90)

/obj/structure/blob/shield/scannerreport()
	if(atmosblock)
		return "Блокирует воздушные потоки."
	return "N/A"

/obj/structure/blob/shield/core // Automatically generated by the core
	point_return = 0

/obj/structure/blob/shield/take_damage(damage_amount, damage_type, damage_flag, sound_effect, attack_dir)
	. = ..()
	if(. && obj_integrity > 0)
		atmosblock = obj_integrity < (max_integrity * 0.5)
		air_update_turf(TRUE, atmosblock)

/obj/structure/blob/shield/update_icon()
	cut_overlays()
	color = null
	var/mutable_appearance/blob_overlay = mutable_appearance(icon, "strongpulse")
	if(overmind)
		blob_overlay.color = overmind.blobstrain.color
	for(var/obj/structure/blob/B in orange(src,1))
		overlays += image(icon, "strongconnect", dir = get_dir(src,B))
	add_overlay(blob_overlay)

	underlays.len = 0
	underlays += image(icon,"roots")

	update_health_overlay()

/obj/structure/blob/shield/update_icon_state()
	name = "[(obj_integrity < (max_integrity * 0.5)) ? "weakened " : null][initial(name)]"
	desc = (obj_integrity < (max_integrity * 0.5)) ? "[damaged_desc]" : initial(desc)
	return ..()

/obj/structure/blob/shield/reflective
	name = "отражающая масса"
	desc = "Сплошная стена из слегка подергивающихся усиков с отражающим свечением."
	damaged_desc = "Стена из подергивающихся усиков с отражающим светом."
	icon_state = "blob_glow"
	flags_ricochet = RICOCHET_SHINY
	point_return = BLOB_REFUND_REFLECTOR_COST
	explosion_block = 2
	max_integrity = BLOB_REFLECTOR_MAX_HP
	health_regen = BLOB_REFLECTOR_HP_REGEN

/obj/structure/blob/shield/reflective/core // Automatically generated by the core
	point_return = 0
