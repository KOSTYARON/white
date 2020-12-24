/mob/living/carbon/monkey
	name = "monkey"
	verb_say = "выкрикивает"
	initial_language_holder = /datum/language_holder/monkey
	gender = NEUTER
	pass_flags = PASSTABLE
	ventcrawler = VENTCRAWLER_NUDE
	mob_biotypes = MOB_ORGANIC|MOB_HUMANOID
	butcher_results = list(/obj/item/food/meat/slab/monkey = 5, /obj/item/stack/sheet/animalhide/monkey = 1)
	type_of_meat = /obj/item/food/meat/slab/monkey
	gib_type = /obj/effect/decal/cleanable/blood/gibs
	unique_name = TRUE
	can_be_shoved_into = TRUE
	blocks_emissive = EMISSIVE_BLOCK_UNIQUE
	bodyparts = list(
		/obj/item/bodypart/chest/monkey,
		/obj/item/bodypart/head/monkey,
		/obj/item/bodypart/l_arm/monkey,
		/obj/item/bodypart/r_arm/monkey,
		/obj/item/bodypart/r_leg/monkey,
		/obj/item/bodypart/l_leg/monkey,
		)
	hud_type = /datum/hud/monkey
	melee_damage_lower = 1
	melee_damage_upper = 3
	ai_controller = /datum/ai_controller/monkey
	faction = list("neutral", "monkey")

/mob/living/carbon/monkey/Initialize(mapload, cubespawned=FALSE, mob/spawner)
	add_verb(src, /mob/living/proc/mob_sleep)
	add_verb(src, /mob/living/proc/toggle_resting)

	if(unique_name) //used to exclude pun pun
		gender = pick(MALE, FEMALE)
	real_name = name

	//initialize limbs
	create_bodyparts()
	create_internal_organs()

	. = ..()

	if (cubespawned)
		var/cap = CONFIG_GET(number/monkeycap)
		if (LAZYLEN(SSmobs.cubemonkeys) > cap)
			if (spawner)
				to_chat(spawner, "<span class='warning'>Bluespace harmonics prevent the spawning of more than [cap] monkeys on the station at one time!</span>")
			return INITIALIZE_HINT_QDEL
		SSmobs.cubemonkeys += src

	create_dna(src)
	dna.initialize_dna(random_blood_type())
	AddComponent(/datum/component/footstep, FOOTSTEP_MOB_BAREFOOT, 1, -6)
	AddComponent(/datum/component/bloodysoles/feet)

/mob/living/carbon/monkey/Destroy()
	SSmobs.cubemonkeys -= src
	return ..()

/mob/living/carbon/monkey/create_reagents(max_vol, flags)
	. = ..()
	RegisterSignal(reagents, list(COMSIG_REAGENTS_NEW_REAGENT, COMSIG_REAGENTS_DEL_REAGENT), .proc/on_reagent_change)
	RegisterSignal(reagents, COMSIG_PARENT_QDELETING, .proc/on_reagents_del)

/// Handles removing signal hooks incase someone is crazy enough to reset the reagents datum.
/mob/living/carbon/monkey/proc/on_reagents_del(datum/reagents/reagents)
	SIGNAL_HANDLER
	UnregisterSignal(reagents, list(COMSIG_REAGENTS_NEW_REAGENT, COMSIG_REAGENTS_DEL_REAGENT, COMSIG_PARENT_QDELETING))
	return NONE

/mob/living/carbon/monkey/create_internal_organs()
	internal_organs += new /obj/item/organ/appendix
	internal_organs += new /obj/item/organ/lungs
	internal_organs += new /obj/item/organ/heart
	internal_organs += new /obj/item/organ/brain
	internal_organs += new /obj/item/organ/tongue
	internal_organs += new /obj/item/organ/eyes
	internal_organs += new /obj/item/organ/ears
	internal_organs += new /obj/item/organ/liver
	internal_organs += new /obj/item/organ/stomach
	..()

/**
 * Snowflake handling for morphine and nuka cola speed mods.
 *
 * Should be moved to the reagents at some future point. As it is I'm in a hurry.
 */
/mob/living/carbon/monkey/proc/on_reagent_change(datum/reagents/holder, ...)
	SIGNAL_HANDLER
	var/amount
	if(reagents.has_reagent(/datum/reagent/medicine/morphine))
		amount = -1
	if(reagents.has_reagent(/datum/reagent/consumable/nuka_cola))
		amount = -1
	if(amount)
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/monkey_reagent_speedmod, TRUE, amount)
	return NONE

/mob/living/carbon/monkey/updatehealth()
	. = ..()
	var/slow = 0
	if(!HAS_TRAIT(src, TRAIT_IGNOREDAMAGESLOWDOWN))
		var/health_deficiency = (maxHealth - health)
		if(health_deficiency >= 45)
			slow += (health_deficiency / 25)
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/monkey_health_speedmod, TRUE, slow)

/mob/living/carbon/monkey/adjust_bodytemperature(amount, min_temp=0, max_temp=INFINITY, use_insulation=FALSE, use_steps=FALSE)
	. = ..()
	var/slow = 0
	if (bodytemperature < 283.222)
		slow += ((283.222 - bodytemperature) / 10) * 1.75
		add_or_update_variable_movespeed_modifier(/datum/movespeed_modifier/monkey_temperature_speedmod, TRUE, slow)

/mob/living/carbon/monkey/get_status_tab_items()
	. = ..()
	. += "Взаимодействие: [a_intent]"
	. += "Режим перемещения: [m_intent]"
	if(client && mind)
		var/datum/antagonist/changeling/changeling = mind.has_antag_datum(/datum/antagonist/changeling)
		if(changeling)
			. += ""
			. += "Химикаты: [changeling.chem_charges]/[changeling.chem_storage]"
			. += "Поглощено ДНК: [changeling.absorbedcount]"

/mob/living/carbon/monkey/verb/removeinternal()
	set name = "Remove Internals"
	set category = "IC"
	internal = null
	return

/mob/living/carbon/monkey/can_use_guns(obj/item/G)
	if(G.trigger_guard == TRIGGER_GUARD_NONE)
		to_chat(src, "<span class='warning'>А я не умею!</span>")
		return FALSE
	return TRUE

/mob/living/carbon/monkey/reagent_check(datum/reagent/R) //can metabolize all reagents
	return FALSE

/mob/living/carbon/monkey/canBeHandcuffed()
	if(num_hands < 2)
		return FALSE
	return TRUE

/mob/living/carbon/monkey/assess_threat(judgement_criteria, lasercolor = "", datum/callback/weaponcheck=null)
	if(judgement_criteria & JUDGE_EMAGGED)
		return 10 //Everyone is a criminal!

	var/threatcount = 0

	//Securitrons can't identify monkeys
	if( !(judgement_criteria & JUDGE_IGNOREMONKEYS) && (judgement_criteria & JUDGE_IDCHECK) )
		threatcount += 4

	//Lasertag bullshit
	if(lasercolor)
		if(lasercolor == "b")//Lasertag turrets target the opposing team, how great is that? -Sieve
			if(is_holding_item_of_type(/obj/item/gun/energy/laser/redtag))
				threatcount += 4

		if(lasercolor == "r")
			if(is_holding_item_of_type(/obj/item/gun/energy/laser/bluetag))
				threatcount += 4

		return threatcount

	//Check for weapons
	if( (judgement_criteria & JUDGE_WEAPONCHECK) && weaponcheck )
		for(var/obj/item/I in held_items) //if they're holding a gun
			if(weaponcheck.Invoke(I))
				threatcount += 4
		if(weaponcheck.Invoke(back)) //if a weapon is present in the back slot
			threatcount += 4 //trigger look_for_perp() since they're nonhuman and very likely hostile

	//mindshield implants imply trustworthyness
	if(HAS_TRAIT(src, TRAIT_MINDSHIELD))
		threatcount -= 1

	return threatcount

/mob/living/carbon/monkey/IsVocal()
	if(!getorganslot(ORGAN_SLOT_LUNGS))
		return 0
	return 1

/mob/living/carbon/monkey/angry

/mob/living/carbon/monkey/angry/Initialize()
	. = ..()
	ai_controller.blackboard[BB_MONKEY_AGRESSIVE] = TRUE
	if(prob(10))
		var/obj/item/clothing/head/helmet/justice/escape/helmet = new(src)
		equip_to_slot_or_del(helmet,ITEM_SLOT_HEAD)
		helmet.attack_self(src) // todo encapsulate toggle
