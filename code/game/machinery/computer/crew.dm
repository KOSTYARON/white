/// How often the sensor data is updated
#define SENSORS_UPDATE_PERIOD	10 SECONDS //How often the sensor data updates.
/// The job sorting ID associated with otherwise unknown jobs
#define UNKNOWN_JOB_ID			81

/obj/machinery/computer/crew
	name = "консоль мониторинга за экипажем"
	desc = "Используется для контроля активных датчиков здоровья, встроенных в большую часть формы экипажа."
	icon_screen = "crew"
	icon_keyboard = "med_key"
	use_power = IDLE_POWER_USE
	idle_power_usage = 250
	active_power_usage = 500
	circuit = /obj/item/circuitboard/computer/crew
	light_color = LIGHT_COLOR_BLUE

/obj/machinery/computer/crew/syndie
	icon_keyboard = "syndie_key"

/obj/machinery/computer/crew/interact(mob/user)
	GLOB.crewmonitor.show(user,src)

GLOBAL_DATUM_INIT(crewmonitor, /datum/crewmonitor, new)

/datum/crewmonitor
	/// List of user -> UI source
	var/list/ui_sources = list()
	/// Cache of data generated by z-level, used for serving the data within SENSOR_UPDATE_PERIOD of the last update
	var/list/data_by_z = list()
	/// Cache of last update time for each z-level
	var/list/last_update = list()
	/// Map of job to ID for sorting purposes
	var/list/jobs = list(
		// Note that jobs divisible by 10 are considered heads of staff, and bolded
		// 00: Captain
		"Captain" = 00,
		// 10-19: Security
		"Head of Security" = 10,
		"Warden" = 11,
		"Security Officer" = 12,
		"Detective" = 13,
		"Russian Officer" = 14,
		"Veteran" = 15,
		// 20-29: Medbay
		"Chief Medical Officer" = 20,
		"Chemist" = 21,
		"Virologist" = 22,
		"Medical Doctor" = 23,
		"Paramedic" = 24,
		// 30-39: Science
		"Research Director" = 30,
		"Scientist" = 31,
		"Roboticist" = 32,
		"Geneticist" = 33,
		"Hacker" = 34,
		// 40-49: Engineering
		"Chief Engineer" = 40,
		"Station Engineer" = 41,
		"Atmospheric Technician" = 42,
		"Механик" = 43,
		// 50-59: Cargo
		"Head of Personnel" = 50,
		"Quartermaster" = 51,
		"Shaft Miner" = 52,
		"Cargo Technician" = 53,
		"Trader" = 54,
		// 60+: Civilian/other
		"Bartender" = 61,
		"Cook" = 62,
		"Botanist" = 63,
		"Curator" = 64,
		"Chaplain" = 65,
		"Clown" = 66,
		"Mime" = 67,
		"Janitor" = 68,
		"Lawyer" = 69,
		"Psychologist" = 71,
		// ANYTHING ELSE = UNKNOWN_JOB_ID, Unknowns/custom jobs will appear after civilians, and before assistants
		"Assistant" = 999,

		// 200-229: Centcom
		"Admiral" = 200,
		"CentCom Commander" = 210,
		"Custodian" = 211,
		"Medical Officer" = 212,
		"Research Officer" = 213,
		"Emergency Response Team Commander" = 220,
		"Security Response Officer" = 221,
		"Engineer Response Officer" = 222,
		"Medical Response Officer" = 223
	)

/datum/crewmonitor/ui_interact(mob/user, datum/tgui/ui)
	ui = SStgui.try_update_ui(user, src, ui)
	if (!ui)
		ui = new(user, src, "CrewConsole")
		ui.open()

/datum/crewmonitor/proc/show(mob/M, source)
	ui_sources[M] = source
	ui_interact(M)

/datum/crewmonitor/ui_host(mob/user)
	return ui_sources[user]

/datum/crewmonitor/ui_data(mob/user)
	var/z = user.z
	if(!z)
		var/turf/T = get_turf(user)
		z = T.z
	. = list(
		"sensors" = update_data(z),
		"link_allowed" = isAI(user)
	)

/datum/crewmonitor/proc/update_data(z)
	if(data_by_z["[z]"] && last_update["[z]"] && world.time <= last_update["[z]"] + SENSORS_UPDATE_PERIOD)
		return data_by_z["[z]"]

	var/list/results = list()
	for(var/tracked_mob in GLOB.suit_sensors_list | GLOB.nanite_sensors_list)
		var/mob/living/carbon/human/H = tracked_mob

		// Check if z-level is correct
		var/turf/pos = get_turf(H)
		if (pos.z != z)
			continue

		// Determine if this person is using nanites for sensors,
		// in which case the sensors are always set to full detail
		var/using_nanites = (H in GLOB.nanite_sensors_list)

		// Check for a uniform if not using nanites
		var/obj/item/clothing/under/uniform = H.w_uniform
		if (!using_nanites && !uniform)
			continue

		// Check that sensors are present and active
		if (!using_nanites && (!uniform.has_sensor || !uniform.sensor_mode))
			continue

		// The entry for this human
		var/list/entry = list(
			"ref" = REF(H),
			"name" = "Unknown",
			"ijob" = UNKNOWN_JOB_ID
		)

		// ID and id-related data
		var/obj/item/card/id/id_card = H.get_idcard(hand_first = FALSE)
		if (id_card)
			entry["name"] = id_card.registered_name
			entry["assignment"] = id_card.assignment
			entry["ijob"] = jobs[id_card.assignment]

		// Binary living/dead status
		if (using_nanites || uniform.sensor_mode >= SENSOR_LIVING)
			entry["life_status"] = !H.stat

		// Damage
		if (using_nanites || uniform.sensor_mode >= SENSOR_VITALS)
			entry += list(
				"oxydam" = round(H.getOxyLoss(), 1),
				"toxdam" = round(H.getToxLoss(), 1),
				"burndam" = round(H.getFireLoss(), 1),
				"brutedam" = round(H.getBruteLoss(), 1)
			)

		// Location
		if (pos && (using_nanites || uniform.sensor_mode >= SENSOR_COORDS))
			entry["area"] = get_area_name(H, format_text = TRUE)

		// Trackability
		entry["can_track"] = H.can_track()

		results[++results.len] = entry

	// Cache result
	data_by_z["[z]"] = results
	last_update["[z]"] = world.time

	return results

/datum/crewmonitor/ui_act(action,params)
	. = ..()
	if(.)
		return
	switch (action)
		if ("select_person")
			var/mob/living/silicon/ai/AI = usr
			if(!istype(AI))
				return
			AI.ai_camera_track(params["name"])

#undef SENSORS_UPDATE_PERIOD
#undef UNKNOWN_JOB_ID
