/datum/species/abductor
	name = "\improper Abductor" //PARIAH MODULAR EDIT
	id = SPECIES_ABDUCTOR
	say_mod = "gibbers"
	sexes = FALSE
	species_traits = list(NOBLOOD,NOEYESPRITES)
	inherent_traits = list(
		TRAIT_ADVANCEDTOOLUSER,
		TRAIT_CAN_STRIP,
		TRAIT_VIRUSIMMUNE,
		TRAIT_CHUNKYFINGERS,
		TRAIT_NOHUNGER,
		TRAIT_NOBREATH,
	)
	mutanttongue = /obj/item/organ/tongue/abductor
	changesource_flags = MIRROR_BADMIN | WABBAJACK | MIRROR_PRIDE | MIRROR_MAGIC | RACE_SWAP | ERT_SPAWN | SLIME_EXTRACT
	ass_image = 'icons/ass/assgrey.png'
//PARIAH MODULAR EDIT START
	species_chest = /obj/item/bodypart/chest/abductor
	species_head = /obj/item/bodypart/head/abductor
	species_l_arm = /obj/item/bodypart/l_arm/abductor
	species_r_arm = /obj/item/bodypart/r_arm/abductor
	species_l_leg = /obj/item/bodypart/l_leg/abductor
	species_r_leg = /obj/item/bodypart/r_leg/abductor
//PARIAH MODULAR EDIT END
/datum/species/abductor/on_species_gain(mob/living/carbon/C, datum/species/old_species)
	. = ..()
	var/datum/atom_hud/abductor_hud = GLOB.huds[DATA_HUD_ABDUCTOR]
	abductor_hud.add_hud_to(C)

	C.set_safe_hunger_level()

/datum/species/abductor/on_species_loss(mob/living/carbon/C)
	. = ..()
	var/datum/atom_hud/abductor_hud = GLOB.huds[DATA_HUD_ABDUCTOR]
	abductor_hud.remove_hud_from(C)
