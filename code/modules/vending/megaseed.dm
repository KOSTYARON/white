/obj/machinery/vending/hydroseeds
	name = "MegaSeed Servitor"
	desc = "Когда нужны семена быстро!"
	product_slogans = "ТУТ СЕМЕНА ЖИВУТ! ПОЛУЧИТЕ СВОИ!;Самый лучший выбор семян на станции!;Также доступны определенные сорта грибов, больше для знатоков! Получите сертификат сегодня!"
	product_ads = "Мы любим растения!;Выращивай урожай!;Расти, детка, расти!;Ой, да, сын!"
	icon_state = "seeds"
	light_mask = "seeds-light-mask"
	products = list(/obj/item/seeds/aloe = 3,
					/obj/item/seeds/ambrosia = 3,
					/obj/item/seeds/apple = 3,
					/obj/item/seeds/banana = 3,
					/obj/item/seeds/berry = 3,
					/obj/item/seeds/cabbage = 3,
					/obj/item/seeds/carrot = 3,
					/obj/item/seeds/cherry = 3,
					/obj/item/seeds/chanter = 3,
					/obj/item/seeds/chili = 3,
					/obj/item/seeds/cocoapod = 3,
					/obj/item/seeds/coffee = 3,
					/obj/item/seeds/cotton = 3,
					/obj/item/seeds/corn = 3,
					/obj/item/seeds/eggplant = 3,
					/obj/item/seeds/garlic = 3,
					/obj/item/seeds/grape = 3,
					/obj/item/seeds/grass = 3,
					/obj/item/seeds/lemon = 3,
					/obj/item/seeds/lime = 3,
					/obj/item/seeds/onion = 3,
					/obj/item/seeds/orange = 3,
					/obj/item/seeds/peas = 3,
					/obj/item/seeds/pineapple = 3,
					/obj/item/seeds/potato = 3,
					/obj/item/seeds/poppy = 3,
					/obj/item/seeds/pumpkin = 3,
					/obj/item/seeds/wheat/rice = 3,
					/obj/item/seeds/soya = 3,
					/obj/item/seeds/sugarcane = 3,
					/obj/item/seeds/sunflower = 3,
					/obj/item/seeds/tea = 3,
					/obj/item/seeds/tobacco = 3,
					/obj/item/seeds/tomato = 3,
					/obj/item/seeds/tower = 3,
					/obj/item/seeds/watermelon = 3,
					/obj/item/seeds/wheat = 3,
					/obj/item/seeds/whitebeet = 3)
	contraband = list(/obj/item/seeds/amanita = 2,
					/obj/item/seeds/glowshroom = 2,
					/obj/item/seeds/liberty = 2,
					/obj/item/seeds/nettle = 2,
					/obj/item/seeds/plump = 2,
					/obj/item/seeds/reishi = 2,
					/obj/item/seeds/cannabis = 3,
					/obj/item/seeds/starthistle = 2,
					/obj/item/seeds/random = 2)
	premium = list(/obj/item/reagent_containers/spray/waterflower = 1)
	refill_canister = /obj/item/vending_refill/hydroseeds
	default_price = PAYCHECK_PRISONER
	extra_price = PAYCHECK_ASSISTANT
	payment_department = ACCOUNT_SRV

/obj/item/vending_refill/hydroseeds
	machine_name = "MegaSeed Servitor"
	icon_state = "refill_plant"
