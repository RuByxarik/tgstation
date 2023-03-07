/obj/item/reagent_containers/blood
	name = "blood pack"
	desc = "Contains blood used for transfusion. Must be attached to an IV drip."
	icon = 'icons/obj/medical/bloodpack.dmi'
	icon_state = "bloodpack"
	volume = 200
	var/blood_type = null
	var/unique_blood = null
	var/labelled = FALSE
	fill_icon_thresholds = list(10, 20, 30, 40, 50, 60, 70, 80, 90, 100)

/obj/item/reagent_containers/blood/Initialize(mapload)
	. = ..()
	if(blood_type != null)
		reagents.add_reagent(unique_blood ? unique_blood : /datum/reagent/blood, 200, list("viruses"=null,"blood_DNA"=null,"blood_type"=blood_type,"resistances"=null,"trace_chem"=null))
		update_appearance()

/// Handles updating the container when the reagents change.
/obj/item/reagent_containers/blood/on_reagent_change(datum/reagents/holder, ...)
	var/datum/reagent/blood/new_reagent = holder.has_reagent(/datum/reagent/blood)
	if(new_reagent && new_reagent.data && new_reagent.data["blood_type"])
		blood_type = new_reagent.data["blood_type"]
	else if(holder.has_reagent(/datum/reagent/consumable/liquidelectricity))
		blood_type = "LE"
	else
		blood_type = null
	return ..()

/obj/item/reagent_containers/blood/update_name(updates)
	. = ..()
	if(labelled)
		return
	name = "blood pack[blood_type ? " - [blood_type]" : null]"

/obj/item/reagent_containers/blood/random
	icon_state = "random_bloodpack"

/obj/item/reagent_containers/blood/random/Initialize(mapload)
	icon_state = "bloodpack"
	blood_type = pick("A+", "A-", "B+", "B-", "O+", "O-", "L")
	return ..()

/obj/item/reagent_containers/blood/a_plus
	blood_type = "A+"

/obj/item/reagent_containers/blood/a_minus
	blood_type = "A-"

/obj/item/reagent_containers/blood/b_plus
	blood_type = "B+"

/obj/item/reagent_containers/blood/b_minus
	blood_type = "B-"

/obj/item/reagent_containers/blood/o_plus
	blood_type = "O+"

/obj/item/reagent_containers/blood/o_minus
	blood_type = "O-"

/obj/item/reagent_containers/blood/lizard
	blood_type = "L"

/obj/item/reagent_containers/blood/ethereal
	blood_type = "LE"
	unique_blood = /datum/reagent/consumable/liquidelectricity

/obj/item/reagent_containers/blood/universal
	blood_type = "U"

/obj/item/reagent_containers/blood/attackby(obj/item/tool, mob/user, params)
	if (istype(tool, /obj/item/pen) || istype(tool, /obj/item/toy/crayon))
		if(!user.can_write(tool))
			return
		var/custom_label = tgui_input_text(user, "What would you like to label the blood pack?", "Blood Pack", name, MAX_NAME_LEN)
		if(!user.can_perform_action(src))
			return
		if(user.get_active_held_item() != tool)
			return
		if(custom_label)
			labelled = TRUE
			name = "blood pack - [custom_label]"
			balloon_alert(user, "new label set")
		else
			labelled = FALSE
			update_name()
	else
		return ..()

/obj/item/reagent_containers/blood/attack(mob/user, mob/user, def_zone)
	if(reagents.total_volume > 0)
		if(user != user)
			user.visible_message(
				span_notice("[user] forces [user] to drink from the [src]."),
				span_notice("You put the [src] up to [user]'s mouth."),
			)
			if(!do_after(user, 5 SECONDS, src))
				return
		else
			if(!do_after(user, 1 SECONDS, src))
				return
			user.visible_message(
				span_notice("[user] puts the [src] up to their mouth."),
				span_notice("You take a sip from the [src]."),
			)
		// Safety: In case you spam clicked the blood bag on yourself, and it is now empty (below will divide by zero)
		if(reagents.total_volume <= 0)
			return
		if(IS_BLOODSUCKER(user))
			var/datum/antagonist/bloodsucker/bloodsuckerdatum = user.mind.has_antag_datum(/datum/antagonist/bloodsucker)
			bloodsuckerdatum.AddBloodVolume(5)
			var/mob/living/carbon/H = user
			SEND_SIGNAL(src, COMSIG_GLASS_DRANK, user, user)
			addtimer(CALLBACK(reagents, /datum/reagents.proc/trans_to, user, 500, TRUE, TRUE, FALSE, user, FALSE, INGEST), 5)
			if(H.blood_volume >= bloodsuckerdatum.max_blood_volume)
				to_chat(user, span_notice("You are full, and can't consume more blood"))
				return
		else
			SEND_SIGNAL(src, COMSIG_GLASS_DRANK, user, user)
			addtimer(CALLBACK(reagents, /datum/reagents.proc/trans_to, user, 5, TRUE, TRUE, FALSE, user, FALSE, INGEST), 5)
		playsound(user.loc, 'sound/items/drink.ogg', rand(10,50), 1)
	return ..()
