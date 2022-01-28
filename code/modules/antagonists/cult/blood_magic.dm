/datum/action/innate/cult/blood_magic //Blood magic handles the creation of blood spells (formerly talismans)
	name = "Подготовка кровавой магии"
	button_icon_state = "carve"
	desc = "Подготовь кровавую магию, вырезая руны на своей плоти. Легче делать это с <b>руной усиления</b>."
	var/list/spells = list()
	var/channeling = FALSE

/datum/action/innate/cult/blood_magic/Grant()
	..()
	button.screen_loc = DEFAULT_BLOODSPELLS
	button.moved = DEFAULT_BLOODSPELLS
	button.ordered = FALSE

/datum/action/innate/cult/blood_magic/Remove()
	for(var/X in spells)
		qdel(X)
	..()

/datum/action/innate/cult/blood_magic/IsAvailable()
	if(!iscultist(owner))
		return FALSE
	return ..()

/datum/action/innate/cult/blood_magic/proc/Positioning()
	var/list/screen_loc_split = splittext(button.screen_loc,",")
	var/list/screen_loc_X = splittext(screen_loc_split[1],":")
	var/list/screen_loc_Y = splittext(screen_loc_split[2],":")
	var/pix_X = text2num(screen_loc_X[2])
	for(var/datum/action/innate/cult/blood_spell/B in spells)
		if(B.button.locked)
			var/order = pix_X+spells.Find(B)*31
			B.button.screen_loc = "[screen_loc_X[1]]:[order],[screen_loc_Y[1]]:[screen_loc_Y[2]]"
			B.button.moved = B.button.screen_loc

/datum/action/innate/cult/blood_magic/Activate()
	var/rune = FALSE
	var/limit = RUNELESS_MAX_BLOODCHARGE
	for(var/obj/effect/rune/empower/R in range(1, owner))
		rune = TRUE
		break
	if(rune)
		limit = MAX_BLOODCHARGE
	if(spells.len >= limit)
		if(rune)
			to_chat(owner, span_cultitalic("Не могу хранить более [MAX_BLOODCHARGE] заклинаний. <b>Выбери заклинание для удаления.</b>"))
		else
			to_chat(owner, span_cultitalic("<b><u>Не могу хранить более [RUNELESS_MAX_BLOODCHARGE] заклинаний без руны усиления! Выбери заклинание для удаления.</b></u>"))
		var/nullify_spell = input(owner, "Выбери заклинание для удаления.", "Текущие заклинания") as null|anything in spells
		if(nullify_spell)
			qdel(nullify_spell)
		return
	var/entered_spell_name
	var/datum/action/innate/cult/blood_spell/BS
	var/list/possible_spells = list()
	for(var/I in subtypesof(/datum/action/innate/cult/blood_spell))
		var/datum/action/innate/cult/blood_spell/J = I
		var/cult_name = initial(J.name)
		possible_spells[cult_name] = J
	possible_spells += "(УБРАТЬ ЗАКЛИНАНИЕ)"
	entered_spell_name = input(owner, "Pick a blood spell to prepare...", "Spell Choices") as null|anything in possible_spells
	if(entered_spell_name == "(УБРАТЬ ЗАКЛИНАНИЕ)")
		var/nullify_spell = input(owner, "Choose a spell to remove.", "Current Spells") as null|anything in spells
		if(nullify_spell)
			qdel(nullify_spell)
		return
	BS = possible_spells[entered_spell_name]
	if(QDELETED(src) || owner.incapacitated() || !BS || (rune && !(locate(/obj/effect/rune/empower) in range(1, owner))) || (spells.len >= limit))
		return
	to_chat(owner,span_warning("Начинаю вырезать странные символы на своей плоти!"))
	SEND_SOUND(owner, sound('sound/weapons/slice.ogg',0,1,10))
	if(!channeling)
		channeling = TRUE
	else
		to_chat(owner, span_cultitalic("Я уже пробуждаю кровавую магию!"))
		return
	if(do_after(owner, 100 - rune*60, target = owner))
		if(ishuman(owner))
			var/mob/living/carbon/human/H = owner
			H.bleed(40 - rune*32)
		var/datum/action/innate/cult/blood_spell/new_spell = new BS(owner)
		new_spell.Grant(owner, src)
		spells += new_spell
		Positioning()
		to_chat(owner, span_warning("Мои травмы издают магическое свечение, я приготовил призыв [new_spell.name]!"))
	channeling = FALSE

/datum/action/innate/cult/blood_spell //The next generation of talismans, handles storage/creation of blood magic
	name = "Кровавая Магия"
	button_icon_state = "telerune"
	desc = "Бойся Древней Крови."
	var/charges = 1
	var/magic_path = null
	var/obj/item/melee/blood_magic/hand_magic
	var/datum/action/innate/cult/blood_magic/all_magic
	var/base_desc //To allow for updating tooltips
	var/invocation
	var/health_cost = 0

/datum/action/innate/cult/blood_spell/Grant(mob/living/owner, datum/action/innate/cult/blood_magic/BM)
	if(health_cost)
		desc += "<br>Наношу <u>[health_cost] увечий</u> своей руке при использовании."
	base_desc = desc
	desc += "<br><b><u>Осталось [charges] использования</u></b>."
	all_magic = BM
	..()
	button.locked = TRUE
	button.ordered = FALSE

/datum/action/innate/cult/blood_spell/Remove()
	if(all_magic)
		all_magic.spells -= src
	if(hand_magic)
		qdel(hand_magic)
		hand_magic = null
	..()

/datum/action/innate/cult/blood_spell/IsAvailable()
	if(!iscultist(owner) || owner.incapacitated()  || !charges)
		return FALSE
	return ..()

/datum/action/innate/cult/blood_spell/Activate()
	if(magic_path) //If this spell flows from the hand
		if(!hand_magic)
			hand_magic = new magic_path(owner, src)
			if(!owner.put_in_hands(hand_magic))
				qdel(hand_magic)
				hand_magic = null
				to_chat(owner, span_warning("Мои руки заняты! Не могу использовать магию!"))
				return
			to_chat(owner, span_notice("Мои раны светятся, когда я пробуждаю [name]."))
			return
		if(hand_magic)
			qdel(hand_magic)
			hand_magic = null
			to_chat(owner, span_warning("Подавляю заклинание, оставляя его на потом."))


//Cult Blood Spells
/datum/action/innate/cult/blood_spell/stun
	name = "Оглушение"
	desc = "Заряжает руку оглушением и онемением при использовании на жертве."
	button_icon_state = "hand"
	magic_path = "/obj/item/melee/blood_magic/stun"
	health_cost = 10

/datum/action/innate/cult/blood_spell/teleport
	name = "Телепорт"
	desc = "Заряжает руку силой телепортации, чтобы переместить себя или другого культиста на руну телепортации."
	button_icon_state = "tele"
	magic_path = "/obj/item/melee/blood_magic/teleport"
	health_cost = 7

/datum/action/innate/cult/blood_spell/emp
	name = "ЭМИ"
	desc = "Излучает массивный электромагнитный импульс."
	button_icon_state = "emp"
	health_cost = 10
	invocation = "Ta'gh fara'qha fel d'amar det!"

/datum/action/innate/cult/blood_spell/emp/Activate()
	owner.whisper(invocation, language = /datum/language/common)
	owner.visible_message(span_warning("Рука [owner] вспыхивает ярко-синим цветом!") , \
		span_cultitalic("Произношу заклятие, вызывая ЭМИ из своей руки."))
	empulse(owner, 2, 5)
	charges--
	if(charges<=0)
		qdel(src)

/datum/action/innate/cult/blood_spell/shackles
	name = "Теневые кандалы"
	desc = "Заряжает твою руку магией, позволяющей заковать жертву в наручники и заставить замолкнуть, если получится заковать."
	button_icon_state = "cuff"
	charges = 4
	magic_path = "/obj/item/melee/blood_magic/shackles"

/datum/action/innate/cult/blood_spell/construction
	name = "Искаженное строительство"
	desc = "Заряжает твою руку магией искажения металла.<br><u>Превращает:</u><br>Пласталь в рунический металл<br>50 металла в оболочку культистов<br>Живых киборгов в оболочки после определённого времени<br>Оболочки боргов в оболочки культистов<br>Шлюзы в непрочные рунические шлюзы после определённого времени(намерение вреда)"
	button_icon_state = "transmute"
	magic_path = "/obj/item/melee/blood_magic/construction"
	health_cost = 12

/datum/action/innate/cult/blood_spell/equipment
	name = "Создание боевого снаряжения"
	desc = "Заряжает твою руку магией. При взаимодействии с другим культистом даст боевое снаряжение, включая броню культа, культистскую болу и культистский меч. Не рекомендуется к использованию до того, когда культ раскроют."
	button_icon_state = "equip"
	magic_path = "/obj/item/melee/blood_magic/armor"

/datum/action/innate/cult/blood_spell/dagger
	name = "Создание ритуального клинка"
	desc = "Позволяет призвать ритуальный клинок, в случае, если ты потерял клинок, который был у тебя изначально."
	invocation = "Wur d'dai leev'mai k'sagan!" //where did I leave my keys, again?
	button_icon_state = "equip" //this is the same icon that summon equipment uses, but eh, I'm not a spriter

/datum/action/innate/cult/blood_spell/dagger/Activate()
	var/turf/owner_turf = get_turf(owner)
	owner.whisper(invocation, language = /datum/language/common)
	owner.visible_message(span_warning("Рука [owner] на секунду вспыхивает красным светом.") , \
		span_cultitalic("Просьба о помощи услышана, пространство начинает искажатся и формироваться во что-то в моей руке!"))
	var/obj/item/melee/cultblade/dagger/summoned_blade = new (owner_turf)
	if(owner.put_in_hands(summoned_blade))
		to_chat(owner, span_warning("Ритуальный клинок появился в моей руке!"))
	else
		owner.visible_message(span_warning("Ритуальный клинок появился у ног [owner]!") , \
			span_cultitalic("Ритуальный клинок появился у моих ног."))
	SEND_SOUND(owner, sound('sound/effects/magic.ogg', FALSE, 0, 25))
	charges--
	if(charges <= 0)
		qdel(src)

/datum/action/innate/cult/blood_spell/horror
	name = "Галлюцинации"
	desc = "Вызывает галлюцинации на цель, работает на расстоянии. Тихое и невидимое заклинание."
	button_icon_state = "horror"
	var/obj/effect/proc_holder/horror/PH
	charges = 4

/datum/action/innate/cult/blood_spell/horror/New()
	PH = new()
	PH.attached_action = src
	..()

/datum/action/innate/cult/blood_spell/horror/Destroy()
	var/obj/effect/proc_holder/horror/destroy = PH
	. = ..()
	if(destroy  && !QDELETED(destroy))
		QDEL_NULL(destroy)

/datum/action/innate/cult/blood_spell/horror/Activate()
	PH.toggle(owner) //the important bit
	return TRUE

/obj/effect/proc_holder/horror
	active = FALSE
	ranged_mousepointer = 'icons/effects/mouse_pointers/cult_target.dmi'
	var/datum/action/innate/cult/blood_spell/attached_action

/obj/effect/proc_holder/horror/Destroy()
	var/datum/action/innate/cult/blood_spell/AA = attached_action
	. = ..()
	if(AA && !QDELETED(AA))
		QDEL_NULL(AA)

/obj/effect/proc_holder/horror/proc/toggle(mob/user)
	if(active)
		remove_ranged_ability(span_cult("Развеиваю магию..."))
	else
		add_ranged_ability(user, span_cult("Готовлюсь ужаснуть цель..."))

/obj/effect/proc_holder/horror/InterceptClickOn(mob/living/caller, params, atom/target)
	if(..())
		return
	if(ranged_ability_user.incapacitated() || !iscultist(caller))
		remove_ranged_ability()
		return
	var/turf/T = get_turf(ranged_ability_user)
	if(!isturf(T))
		return FALSE
	if(target in view(7, get_turf(ranged_ability_user)))
		if(!ishuman(target) || iscultist(target))
			return
		var/mob/living/carbon/human/H = target
		H.hallucination = max(H.hallucination, 120)
		SEND_SOUND(ranged_ability_user, sound('sound/effects/ghost.ogg',0,1,50))
		var/image/C = image('icons/effects/cult_effects.dmi',H,"bloodsparkles", ABOVE_MOB_LAYER)
		add_alt_appearance(/datum/atom_hud/alternate_appearance/basic/cult, "cult_apoc", C, NONE)
		addtimer(CALLBACK(H,/atom/.proc/remove_alt_appearance,"cult_apoc",TRUE), 2400, TIMER_OVERRIDE|TIMER_UNIQUE)
		to_chat(ranged_ability_user,span_cult("<b>[H] был проклят живыми кошмарами!</b>"))
		attached_action.charges--
		attached_action.desc = attached_action.base_desc
		attached_action.desc += "<br><b><u>Осталось [attached_action.charges] использований</u></b>."
		attached_action.UpdateButtonIcon()
		if(attached_action.charges <= 0)
			remove_ranged_ability(span_cult("Я истощил силы заклинания!"))
			qdel(src)

/datum/action/innate/cult/blood_spell/veiling
	name = "Скрытие следов"
	desc = "Поочерёдно скрывает и раскрывает постройки и руны культа."
	invocation = "Kla'atu barada nikt'o!"
	button_icon_state = "gone"
	charges = 10
	var/revealing = FALSE //if it reveals or not

/datum/action/innate/cult/blood_spell/veiling/Activate()
	if(!revealing)
		owner.visible_message(span_warning("Тонкий слой серой пыли осыпается с руки [owner]!") , \
			span_cultitalic("Вызываю заклинание завесы, скрывая ближайшие сооружения культа."))
		charges--
		SEND_SOUND(owner, sound('sound/magic/smoke.ogg',0,1,25))
		owner.whisper(invocation, language = /datum/language/common)
		for(var/obj/effect/rune/R in range(5,owner))
			R.conceal()
		for(var/obj/structure/destructible/cult/S in range(5,owner))
			S.conceal()
		for(var/turf/open/floor/engine/cult/T  in range(5,owner))
			if(!T.realappearance)
				continue
			T.realappearance.alpha = 0
		for(var/obj/machinery/door/airlock/cult/AL in range(5, owner))
			AL.conceal()
		revealing = TRUE
		name = "Раскрытие сооружений"
		button_icon_state = "back"
	else
		owner.visible_message(span_warning("Рука [owner] вспыхивает на миг!") , \
			span_cultitalic("Призываю контрзаклинание завесы, раскрывая ближайшие сооружения культа."))
		charges--
		owner.whisper(invocation, language = /datum/language/common)
		SEND_SOUND(owner, sound('sound/magic/enter_blood.ogg',0,1,25))
		for(var/obj/effect/rune/R in range(7,owner)) //More range in case you weren't standing in exactly the same spot
			R.reveal()
		for(var/obj/structure/destructible/cult/S in range(6,owner))
			S.reveal()
		for(var/turf/open/floor/engine/cult/T  in range(6,owner))
			if(!T.realappearance)
				continue
			T.realappearance.alpha = initial(T.realappearance.alpha)
		for(var/obj/machinery/door/airlock/cult/AL in range(6, owner))
			AL.reveal()
		revealing = FALSE
		name = "Скрытие сооружений"
		button_icon_state = "gone"
	if(charges<= 0)
		qdel(src)
	desc = base_desc
	desc += "<br><b><u>Has [charges] use\s remaining</u></b>."
	UpdateButtonIcon()

/datum/action/innate/cult/blood_spell/manipulation
	name = "Ритуалы Крови"
	desc = "Даёт возможность впитывать кровь для последующего использования в продвинутых ритуалах или для исцеления культистов. Используйте заклинание в руке, чтобы призывать продвинутый ритуал ."
	invocation = "Fel'th Dol Ab'orod!"
	button_icon_state = "manip"
	charges = 5
	magic_path = "/obj/item/melee/blood_magic/manipulator"


// The "magic hand" items
/obj/item/melee/blood_magic
	name = "\improper волшебная аура"
	desc = "Аура зловещего вида, которая искажает реальность вокруг неё."
	icon = 'icons/obj/items_and_weapons.dmi'
	lefthand_file = 'icons/mob/inhands/misc/touchspell_lefthand.dmi'
	righthand_file = 'icons/mob/inhands/misc/touchspell_righthand.dmi'
	icon_state = "disintegrate"
	inhand_icon_state = "disintegrate"
	item_flags = NEEDS_PERMIT | ABSTRACT | DROPDEL

	w_class = WEIGHT_CLASS_HUGE
	throwforce = 0
	throw_range = 0
	throw_speed = 0
	var/invocation
	var/uses = 1
	var/health_cost = 0 //The amount of health taken from the user when invoking the spell
	var/datum/action/innate/cult/blood_spell/source

/obj/item/melee/blood_magic/New(loc, spell)
	source = spell
	uses = source.charges
	health_cost = source.health_cost
	..()

/obj/item/melee/blood_magic/Destroy()
	if(!QDELETED(source))
		if(uses <= 0)
			source.hand_magic = null
			qdel(source)
			source = null
		else
			source.hand_magic = null
			source.charges = uses
			source.desc = source.base_desc
			source.desc += "<br><b><u>Осталось [uses] использования</u></b>."
			source.UpdateButtonIcon()
	..()

/obj/item/melee/blood_magic/attack_self(mob/living/user)
	afterattack(user, user, TRUE)

/obj/item/melee/blood_magic/attack(mob/living/M, mob/living/carbon/user)
	if(!iscarbon(user) || !iscultist(user))
		uses = 0
		qdel(src)
		return
	log_combat(user, M, "used a cult spell on", source.name, "")
//	M.lastattacker = user.real_name
//	M.lastattackerckey = user.ckey

/obj/item/melee/blood_magic/afterattack(atom/target, mob/living/carbon/user, proximity)
	. = ..()
	if(invocation)
		user.whisper(invocation, language = /datum/language/common)
	if(health_cost)
		if(user.active_hand_index == 1)
			user.apply_damage(health_cost, BRUTE, BODY_ZONE_L_ARM)
		else
			user.apply_damage(health_cost, BRUTE, BODY_ZONE_R_ARM)
	if(uses <= 0)
		qdel(src)
	else if(source)
		source.desc = source.base_desc
		source.desc += "<br><b><u>Осталось [uses] использования</u></b>."
		source.UpdateButtonIcon()

//Stun
/obj/item/melee/blood_magic/stun
	name = "Ошеломляющая аура"
	desc = "Оглушит и онемеет слабоумную жертву при контакте."
	color = RUNE_COLOR_RED
	invocation = "Fuu ma'jin!"

/obj/item/melee/blood_magic/stun/afterattack(atom/target, mob/living/carbon/user, proximity)
	if(!isliving(target) || !proximity)
		return
	var/mob/living/L = target
	if(iscultist(target))
		return
	if(iscultist(user))
		user.visible_message(span_warning("[user] держит руку [user.ru_ego()], которая издаёт яркую вспышку красного света!") , \
							span_cultitalic("Пытаюсь оглушить [L] заклинанием!"))

		user.mob_light(_range = 3, _color = LIGHT_COLOR_BLOOD_MAGIC, _duration = 0.2 SECONDS)

		var/anti_magic_source = L.anti_magic_check()
		if(anti_magic_source)

			L.mob_light(_range = 2, _color = LIGHT_COLOR_HOLY_MAGIC, _duration = 10 SECONDS)
			var/mutable_appearance/forbearance = mutable_appearance('icons/effects/genetics.dmi', "servitude", -MUTATIONS_LAYER)
			L.add_overlay(forbearance)
			addtimer(CALLBACK(L, /atom/proc/cut_overlay, forbearance), 100)

			if(istype(anti_magic_source, /obj/item))
				var/obj/item/ams_object = anti_magic_source
				target.visible_message(span_warning("[L] начинает излучать ауру света!") , \
									   span_userdanger("Моя [ams_object.name] начинает светится, излучая ауру святого света, которое окружает вас и защищает от вспышек света!"))
			else
				target.visible_message(span_warning("[L] начинает излучать ауру света!") , \
									   span_userdanger("Ощущение тепла омывает меня, лучи святого света окружают моё тело и защищают от вспышек света!"))

		else
			to_chat(user, span_cultitalic(" [L] падает на землю, издавая яркую красную вспышку!"))
			L.Paralyze(16 SECONDS)
			L.flash_act(1,TRUE)
			if(issilicon(target))
				var/mob/living/silicon/S = L
				S.emp_act(EMP_HEAVY)
			else if(iscarbon(target))
				var/mob/living/carbon/C = L
				C.silent += 6
				C.stuttering += 15
				C.cultslurring += 15
				C.Jitter(1.5 SECONDS)
		uses--
	..()

//Teleportation
/obj/item/melee/blood_magic/teleport
	name = "Аура телепортации"
	color = RUNE_COLOR_TELEPORT
	desc = "Телепортирует культиста на руну телепортации при контакте."
	invocation = "Sas'so c'arta forbici!"

/obj/item/melee/blood_magic/teleport/afterattack(atom/target, mob/living/carbon/user, proximity)
	if(!iscultist(target) || !proximity)
		to_chat(user, span_warning("Я могу телепортировать только культиста, стоящего рядом с собой!"))
		return
	if(iscultist(user))
		var/list/potential_runes = list()
		var/list/teleportnames = list()
		for(var/R in GLOB.teleport_runes)
			var/obj/effect/rune/teleport/T = R
			potential_runes[avoid_assoc_duplicate_keys(T.listkey, teleportnames)] = T

		if(!potential_runes.len)
			to_chat(user, span_warning("Отсутствуют подходящие руны!"))
			log_game("Teleport talisman failed - no other teleport runes")
			return

		var/turf/T = get_turf(src)
		if(is_away_level(T.z))
			to_chat(user, span_cultitalic("Я в неправильном измерении!"))
			log_game("Teleport spell failed - user in away mission")
			return

		var/input_rune_key = input(user, "Выбери руну для телепортации.", "Руна для телепортации в") as null|anything in potential_runes //we know what key they picked
		var/obj/effect/rune/teleport/actual_selected_rune = potential_runes[input_rune_key] //what rune does that key correspond to?
		if(QDELETED(src) || !user || !user.is_holding(src) || user.incapacitated() || !actual_selected_rune || !proximity)
			return
		var/turf/dest = get_turf(actual_selected_rune)
		if(dest.is_blocked_turf(TRUE))
			to_chat(user, span_warning("Выбранная руна заблокирована. Не могу телепортироваться туда."))
			return
		uses--
		var/turf/origin = get_turf(user)
		var/mob/living/L = target
		if(do_teleport(L, dest, channel = TELEPORT_CHANNEL_CULT))
			origin.visible_message(span_warning("Пыль стекает с руки [user], и [user.ru_who()] испаряет[user.p_s()] с резким треском!") , \
				span_cultitalic("Произношу слова талисмана и оказываюсь в другом месте!") , "<i>Слышу резкий треск.</i>")
			dest.visible_message(span_warning("There is a boom of outrushing air as something appears above the rune!") , null, "<i>You hear a boom.</i>")
		..()

//Shackles
/obj/item/melee/blood_magic/shackles
	name = "Сковывающая аура"
	desc = "Начнёт связывать жертву при контакте, и в случае успеха жертва онемеет."
	invocation = "In'totum Lig'abis!"
	color = "#000000" // black

/obj/item/melee/blood_magic/shackles/afterattack(atom/target, mob/living/carbon/user, proximity)
	if(iscultist(user) && iscarbon(target) && proximity)
		var/mob/living/carbon/C = target
		if(C.canBeHandcuffed())
			CuffAttack(C, user)
		else
			user.visible_message(span_cultitalic("У этой жертвы слишком мало рук, чтобы это сделать!"))
			return
		..()

/obj/item/melee/blood_magic/shackles/proc/CuffAttack(mob/living/carbon/C, mob/living/user)
	if(!C.handcuffed)
		playsound(loc, 'sound/weapons/cablecuff.ogg', 30, TRUE, -2)
		C.visible_message(span_danger("[user] связывает [C] темной магией!") , \
								span_userdanger("[user] начинает формировать кандалы темной магии вокруг моих запястий!"))
		if(do_mob(user, C, 30))
			if(!C.handcuffed)
				C.set_handcuffed(new /obj/item/restraints/handcuffs/energy/cult/used(C))
				C.update_handcuffed()
				C.silent += 5
				to_chat(user, span_notice("Связываю [C]."))
				log_combat(user, C, "shackled")
				uses--
			else
				to_chat(user, span_warning("[C] уже связан."))
		else
			to_chat(user, span_warning("Не получилось связать [C]."))
	else
		to_chat(user, span_warning("[C] уже связан."))


/obj/item/restraints/handcuffs/energy/cult //For the shackling spell
	name = "теневые кандалы"
	desc = "Кандалы, которые связывают руки зловещей магией."
	trashtype = /obj/item/restraints/handcuffs/energy/used
	item_flags = DROPDEL

/obj/item/restraints/handcuffs/energy/cult/used/dropped(mob/user)
	user.visible_message(span_danger("Кандалы на руках [user] разрушаются от выплеска темной магии!") , \
							span_userdanger("Мой [src] разрушается после выплеска темной магии!"))
	. = ..()


//Construction: Converts 50 iron to a construct shell, plasteel to runed metal, airlock to brittle runed airlock, a borg to a construct, or borg shell to a construct shell
/obj/item/melee/blood_magic/construction
	name = "Искаженная аура"
	desc = "Искажает некоторые металлические предметы при контакте."
	invocation = "Ethra p'ni dedol!"
	color = "#000000" // black
	var/channeling = FALSE

/obj/item/melee/blood_magic/construction/examine(mob/user)
	. = ..()
	. += {"<hr><u>Зловещее заклинание используется для превращения:</u>\n
	Пластали в рунический металл\n 
	[IRON_TO_CONSTRUCT_SHELL_CONVERSION] железа в оболочку культистов\n
	Живых киборгов в оболочки после определённого времени\n
	Оболочки киборгов в оболочки культистов\n
	Шлюзы в непрочные рунические шлюзы после определённого времени (намерение вреда)"}
/obj/item/melee/blood_magic/construction/afterattack(atom/target, mob/user, proximity_flag, click_parameters)
	if(proximity_flag && iscultist(user))
		if(channeling)
			to_chat(user, span_cultitalic("Я уже пробуждаю искаженное строительство!"))
			return
		var/turf/T = get_turf(target)
		if(istype(target, /obj/item/stack/sheet/iron))
			var/obj/item/stack/sheet/candidate = target
			if(candidate.use(IRON_TO_CONSTRUCT_SHELL_CONVERSION))
				uses--
				to_chat(user, span_warning("Темное облако исходит из моей руки, кружится вокруг железа и превращает его в оболочку!"))
				new /obj/structure/constructshell(T)
				SEND_SOUND(user, sound('sound/effects/magic.ogg',0,1,25))
			else
				to_chat(user, span_warning("Мне нужно [IRON_TO_CONSTRUCT_SHELL_CONVERSION] железа, чтобы сделать оболочку!"))
				return
		else if(istype(target, /obj/item/stack/sheet/plasteel))
			var/obj/item/stack/sheet/plasteel/candidate = target
			var/quantity = candidate.amount
			if(candidate.use(quantity))
				uses --
				new /obj/item/stack/sheet/runed_metal(T,quantity)
				to_chat(user, span_warning("Темное облако исходит из моей руки, кружится вокруг пластали и превращает ее в рунический металл!"))
				SEND_SOUND(user, sound('sound/effects/magic.ogg',0,1,25))
		else if(istype(target,/mob/living/silicon/robot))
			var/mob/living/silicon/robot/candidate = target
			if(candidate.mmi)
				channeling = TRUE
				user.visible_message(span_danger("Темное облако исходит из руки [user] и кружится вокруг [candidate]!"))
				playsound(T, 'sound/machines/airlock_alien_prying.ogg', 80, TRUE)
				var/prev_color = candidate.color
				candidate.color = "black"
				if(do_after(user, 90, target = candidate))
					candidate.emp_act(EMP_HEAVY)
					var/static/list/constructs = list(
						"Juggernaut" = image(icon = 'icons/mob/cult.dmi', icon_state = "juggernaut"),
						"Wraith" = image(icon = 'icons/mob/cult.dmi', icon_state = "wraith"),
						"Artificer" = image(icon = 'icons/mob/cult.dmi', icon_state = "artificer")
						)
					var/construct_class = show_radial_menu(user, src, constructs, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE, tooltips = TRUE)
					if(!check_menu(user))
						return
					if(QDELETED(candidate))
						channeling = FALSE
						return
					user.visible_message(span_danger("Темное облако рассеивается от [candidate], раскрывая\n [construct_class]!"))
					switch(construct_class)
						if("Juggernaut")
							makeNewConstruct(/mob/living/simple_animal/hostile/construct/juggernaut, candidate, user, FALSE, T)
						if("Wraith")
							makeNewConstruct(/mob/living/simple_animal/hostile/construct/wraith, candidate, user, FALSE, T)
						if("Artificer")
							makeNewConstruct(/mob/living/simple_animal/hostile/construct/artificer, candidate, user, FALSE, T)
						else
							return
					uses--
					candidate.mmi = null
					qdel(candidate)
					channeling = FALSE
				else
					channeling = FALSE
					candidate.color = prev_color
					return
			else
				uses--
				to_chat(user, span_warning("Темное облако исходит из моей руки, превращая [candidate] в оболочку!"))
				new /obj/structure/constructshell(T)
				SEND_SOUND(user, sound('sound/effects/magic.ogg',0,1,25))
				qdel(candidate)
		else if(istype(target,/obj/machinery/door/airlock))
			channeling = TRUE
			playsound(T, 'sound/machines/airlockforced.ogg', 50, TRUE)
			do_sparks(5, TRUE, target)
			if(do_after(user, 50, target = user))
				if(QDELETED(target))
					channeling = FALSE
					return
				target.narsie_act()
				uses--
				user.visible_message(span_warning("Черные клочья внезапно исходят из руки [user] и просачиваются в шлюз, искажая и переплетая его!"))
				SEND_SOUND(user, sound('sound/effects/magic.ogg',0,1,25))
				channeling = FALSE
			else
				channeling = FALSE
				return
		else
			to_chat(user, span_warning("Заклинание не работает с [target]!"))
			return
		..()

/obj/item/melee/blood_magic/construction/proc/check_menu(mob/user)
	if(!istype(user))
		CRASH("The cult construct selection radial menu was accessed by something other than a valid user.")
	if(user.incapacitated() || !user.Adjacent(src))
		return FALSE
	return TRUE


//Armor: Gives the target (cultist) a basic cultist combat loadout
/obj/item/melee/blood_magic/armor
	name = "Аура вооружения"
	desc = "Выдаст боевое снаряжения культиста при активации."
	color = "#33cc33" // green

/obj/item/melee/blood_magic/armor/afterattack(atom/target, mob/living/carbon/user, proximity)
	if(iscarbon(target) && iscultist(target) && proximity)
		uses--
		var/mob/living/carbon/C = target
		C.visible_message(span_warning("Внеземеная броня внезапно появляется на [C]!"))
		C.equip_to_slot_or_del(new /obj/item/clothing/under/color/black,ITEM_SLOT_ICLOTHING)
		C.equip_to_slot_or_del(new /obj/item/clothing/suit/hooded/cultrobes/alt(user), ITEM_SLOT_OCLOTHING)
		C.equip_to_slot_or_del(new /obj/item/clothing/shoes/cult/alt(user), ITEM_SLOT_FEET)
		C.equip_to_slot_or_del(new /obj/item/storage/backpack/cultpack(user), ITEM_SLOT_BACK)
		if(C == user)
			qdel(src) //Clears the hands
		C.put_in_hands(new /obj/item/melee/cultblade/dagger(user))
		C.put_in_hands(new /obj/item/restraints/legcuffs/bola/cult(user))
		..()

/obj/item/melee/blood_magic/manipulator
	name = "Аура ритаула крови"
	desc = "Впитывает кровь в месте прикосновения. Прикосновения к культистам и оболочкам будут их лечить. Используй в руке, чтобы произвести продвинутый ритуал."
	color = "#7D1717"

/obj/item/melee/blood_magic/manipulator/examine(mob/user)
	. = ..()
	. += "<hr>Кровавая алебадра, шквал кровавых стрел и кровавый луч будут стоить [BLOOD_HALBERD_COST], [BLOOD_BARRAGE_COST] и [BLOOD_BEAM_COST] соответственно."

/obj/item/melee/blood_magic/manipulator/afterattack(atom/target, mob/living/carbon/human/user, proximity)
	if(proximity)
		if(ishuman(target))
			var/mob/living/carbon/human/H = target
			if(NOBLOOD in H.dna.species.species_traits)
				to_chat(user,span_warning("Ритуалы крови не работают с тем, у кого нет крови!"))
				return
			if(iscultist(H))
				if(H.stat == DEAD)
					to_chat(user,span_warning("Только руна оживления может вернуть мертвых!"))
					return
				if(H.blood_volume < BLOOD_VOLUME_SAFE)
					var/restore_blood = BLOOD_VOLUME_SAFE - H.blood_volume
					if(uses*2 < restore_blood)
						H.blood_volume += uses*2
						to_chat(user,span_danger("Использовал всю кровавую силу, чтобы восстановить кровь, которую смог!"))
						uses = 0
						return ..()
					else
						H.blood_volume = BLOOD_VOLUME_SAFE
						uses -= round(restore_blood/2)
						to_chat(user,span_warning("Мои ритуалы восстановили кровь [H == user ? "your" : "[H.ru_ego()]"] до безопасного уровня!"))
				var/overall_damage = H.getBruteLoss() + H.getFireLoss() + H.getToxLoss() + H.getOxyLoss()
				if(overall_damage == 0)
					to_chat(user,span_cult("Этому культисту не нужно лечение!"))
				else
					var/ratio = uses/overall_damage
					if(H == user)
						to_chat(user,span_cult("<b>Исцеление кровью гораздо слабее, когда я использую его на себе!</b>"))
						ratio *= 0.35 // Healing is half as effective if you can't perform a full heal
						uses -= round(overall_damage) // Healing is 65% more "expensive" even if you can still perform the full heal
					if(ratio>1)
						ratio = 1
						uses -= round(overall_damage)
						H.visible_message(span_warning("[H] полностью исцелен [H==user ? "[H.ru_ego()]":"[H]"] магией крови!"))
					else
						H.visible_message(span_warning("[H] частично исцелен [H==user ? "[H.ru_ego()]":"[H]"] магией крови."))
						uses = 0
					ratio *= -1
					H.adjustOxyLoss((overall_damage*ratio) * (H.getOxyLoss() / overall_damage), 0)
					H.adjustToxLoss((overall_damage*ratio) * (H.getToxLoss() / overall_damage), 0)
					H.adjustFireLoss((overall_damage*ratio) * (H.getFireLoss() / overall_damage), 0)
					H.adjustBruteLoss((overall_damage*ratio) * (H.getBruteLoss() / overall_damage), 0)
					H.updatehealth()
					playsound(get_turf(H), 'sound/magic/staff_healing.ogg', 25)
					new /obj/effect/temp_visual/cult/sparks(get_turf(H))
					user.Beam(H, icon_state="sendbeam", time = 15)
			else
				if(H.stat == DEAD)
					to_chat(user,span_warning("[H.ru_ego(TRUE)] кровь перестала течь, мне придётся найти другой способ её извлечь."))
					return
				if(H.cultslurring)
					to_chat(user,span_danger("[H.ru_ego(TRUE)] кровь была испорчена куда более сильной магией крови, теперь она нам не подходит!"))
					return
				if(H.blood_volume > BLOOD_VOLUME_SAFE)
					H.blood_volume -= 100
					uses += 50
					user.Beam(H, icon_state="drainbeam", time = 1 SECONDS)
					playsound(get_turf(H), 'sound/magic/enter_blood.ogg', 50)
					H.visible_message(span_danger("[user] высасывает немного крови из [H]!"))
					to_chat(user,span_cultitalic("Высосал 50 единиц крови у [H]."))
					new /obj/effect/temp_visual/cult/sparks(get_turf(H))
				else
					to_chat(user,span_warning("[H.p_theyre(TRUE)] слишком мало крови - не могу высосать больше [H.ru_na()]!"))
					return
		if(isconstruct(target))
			var/mob/living/simple_animal/M = target
			var/missing = M.maxHealth - M.health
			if(missing)
				if(uses > missing)
					M.adjustHealth(-missing)
					M.visible_message(span_warning("[M] полностью исцелен магией крови [user]!"))
					uses -= missing
				else
					M.adjustHealth(-uses)
					M.visible_message(span_warning("[M] частично исцелен магией крови [user]!"))
					uses = 0
				playsound(get_turf(M), 'sound/magic/staff_healing.ogg', 25)
				user.Beam(M, icon_state="sendbeam", time = 1 SECONDS)
		if(istype(target, /obj/effect/decal/cleanable/blood))
			blood_draw(target, user)
		..()

/obj/item/melee/blood_magic/manipulator/proc/blood_draw(atom/target, mob/living/carbon/human/user)
	var/temp = 0
	var/turf/T = get_turf(target)
	if(T)
		for(var/obj/effect/decal/cleanable/blood/B in view(T, 2))
			if(B.blood_state == BLOOD_STATE_HUMAN)
				if(B.bloodiness == 100) //Bonus for "pristine" bloodpools, also to prevent cheese with footprint spam
					temp += 30
				else
					temp += max((B.bloodiness**2)/800,1)
				new /obj/effect/temp_visual/cult/turf/floor(get_turf(B))
				qdel(B)
		for(var/obj/effect/decal/cleanable/trail_holder/TH in view(T, 2))
			qdel(TH)
		if(temp)
			user.Beam(T,icon_state="drainbeam", time = 15)
			new /obj/effect/temp_visual/cult/sparks(get_turf(user))
			playsound(T, 'sound/magic/enter_blood.ogg', 50)
			to_chat(user, span_cultitalic("Мой ритуал крови принёс [round(temp)] очков крови из источников вокруг!"))
			uses += max(1, round(temp))

/obj/item/melee/blood_magic/manipulator/attack_self(mob/living/user)
	if(iscultist(user))
		var/static/list/spells = list(
			"Кровавая алебадра (150)" = image(icon = 'icons/obj/items_and_weapons.dmi', icon_state = "occultpoleaxe0"),
			"Шквал кровавых стрел (300)" = image(icon = 'icons/obj/guns/projectile.dmi', icon_state = "arcane_barrage"),
			"Кровавый луч (500)" = image(icon = 'icons/obj/items_and_weapons.dmi', icon_state = "disintegrate")
			)
		var/choice = show_radial_menu(user, src, spells, custom_check = CALLBACK(src, .proc/check_menu, user), require_near = TRUE)
		if(!check_menu(user))
			to_chat(user, span_cultitalic("Решаю не проводить великий ритуал крови."))
			return
		switch(choice)
			if("Кровавая алебадра (150)")
				if(uses < BLOOD_HALBERD_COST)
					to_chat(user, span_cultitalic("Мне нужно [BLOOD_HALBERD_COST] очков, чтобы совершить этот ритуал."))
				else
					uses -= BLOOD_HALBERD_COST
					var/turf/current_position = get_turf(user)
					qdel(src)
					var/datum/action/innate/cult/halberd/halberd_act_granted = new(user)
					var/obj/item/melee/cultblade/halberd/rite = new(current_position)
					halberd_act_granted.Grant(user, rite)
					rite.halberd_act = halberd_act_granted
					if(user.put_in_hands(rite))
						to_chat(user, span_cultitalic("[rite.name] появляется в моих руках!"))
					else
						user.visible_message(span_warning("[rite.name] появляется под ногами [user]!") , \
							span_cultitalic("[rite.name] материализуется у моих ног."))
			if("Шквал кровавых стрел (300)")
				if(uses < BLOOD_BARRAGE_COST)
					to_chat(user, span_cultitalic("Мне нужно [BLOOD_BARRAGE_COST] очков, чтобы совершить этот ритуал."))
				else
					var/obj/rite = new /obj/item/gun/ballistic/rifle/boltaction/enchanted/arcane_barrage/blood()
					uses -= BLOOD_BARRAGE_COST
					qdel(src)
					if(user.put_in_hands(rite))
						to_chat(user, span_cult("<b>Мои руки светятся силой крови!</b>"))
					else
						to_chat(user, span_cultitalic("Мне нужна свободная рука для проведения этого ритуала!"))
						qdel(rite)
			if("Кровавый луч (500)")
				if(uses < BLOOD_BEAM_COST)
					to_chat(user, span_cultitalic("Мне нужно [BLOOD_BEAM_COST] очков, чтобы совершить этот ритуаль."))
				else
					var/obj/rite = new /obj/item/blood_beam()
					uses -= BLOOD_BEAM_COST
					qdel(src)
					if(user.put_in_hands(rite))
						to_chat(user, span_cultlarge("<b>Мои руки светятся НЕПРЕВОСХОДИМОЙ СИЛОЙ!!!</b>"))
					else
						to_chat(user, span_cultitalic("Мне нужна свободная рука для проведения этого ритуала!"))
						qdel(rite)

/obj/item/melee/blood_magic/manipulator/proc/check_menu(mob/living/user)
	if(!istype(user))
		CRASH("The Blood Rites manipulator radial menu was accessed by something other than a valid user.")
	if(user.incapacitated() || !user.Adjacent(src))
		return FALSE
	return TRUE
