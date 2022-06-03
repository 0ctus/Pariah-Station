/datum/computer_file/program/contract_uplink
	filename = "contractor uplink"
	filedesc = "Syndicate Contractor Uplink"
	category = PROGRAM_CATEGORY_MISC
	program_icon_state = "assign"
	extended_desc = "A standard, Syndicate issued system for handling important contracts while on the field."
	size = 10
	requires_ntnet = FALSE
	available_on_ntnet = FALSE
	unsendable = TRUE
	undeletable = TRUE
	tgui_id = "SyndContractor"
	program_icon = "tasks"
	/// Error message if there is one
	var/error = ""
	/// If the info screen is displayed or not
	var/info_screen = TRUE
	/// If the contract uplink's been assigned to a person yet
	var/assigned = FALSE
	/// If this is the first opening of the tablet
	var/first_load = TRUE

/datum/computer_file/program/contract_uplink/run_program(mob/living/user)
	. = ..(user)

/datum/computer_file/program/contract_uplink/ui_act(action, params)
	. = ..()
	if(.)
		return

	var/mob/living/user = usr
	var/obj/item/computer_hardware/hard_drive/small/syndicate/hard_drive = computer.all_components[MC_HDD]

	switch(action)
		if("PRG_contract-accept")
			var/contract_id = text2num(params["contract_id"])

			// Set as the active contract
			hard_drive.antag_data.contractor_hub.assigned_contracts[contract_id].status = CONTRACT_STATUS_ACTIVE
			hard_drive.antag_data.contractor_hub.current_contract = hard_drive.antag_data.contractor_hub.assigned_contracts[contract_id]

			program_icon_state = "single_contract"
			return TRUE
		if("PRG_login")
			var/datum/antagonist/antag_data = user.mind.has_antag_datum(/datum/antagonist)

			if (!antag_data)
				user.playsound_local(user, 'sound/machines/uplinkerror.ogg', 50)
				to_chat(user, span_warning("ERROR: Unauthorized user!"))
				return FALSE
			// Only play greet sound, and handle contractor hub when assigning for the first time.
			if (!antag_data.contractor_hub)
				user.playsound_local(user, 'sound/effects/contractstartup.ogg', 100, FALSE)
				antag_data.contractor_hub = new
				antag_data.contractor_hub.create_hub_items()

			// Stops any topic exploits such as logging in multiple times on a single system.
			if (!assigned)
				antag_data.contractor_hub.create_contracts(antag_data.owner)

				hard_drive.antag_data = antag_data

				program_icon_state = "contracts"
				assigned = TRUE
			return TRUE
		if("PRG_call_extraction")
			if (hard_drive.antag_data.contractor_hub.current_contract.status != CONTRACT_STATUS_EXTRACTING)
				if (hard_drive.antag_data.contractor_hub.current_contract.handle_extraction(user))
					user.playsound_local(user, 'sound/effects/confirmdropoff.ogg', 100, TRUE)
					hard_drive.antag_data.contractor_hub.current_contract.status = CONTRACT_STATUS_EXTRACTING

					program_icon_state = "extracted"
				else
					user.playsound_local(user, 'sound/machines/uplinkerror.ogg', 50)
					error = "Either both you or your target aren't at the dropoff location, or the pod hasn't got a valid place to land. Clear space, or make sure you're both inside."
			else
				user.playsound_local(user, 'sound/machines/uplinkerror.ogg', 50)
				error = "Already extracting... Place the target into the pod. If the pod was destroyed, this contract is no longer possible."

			return TRUE
		if("PRG_contract_abort")
			var/contract_id = hard_drive.antag_data.contractor_hub.current_contract.id

			hard_drive.antag_data.contractor_hub.current_contract = null
			hard_drive.antag_data.contractor_hub.assigned_contracts[contract_id].status = CONTRACT_STATUS_ABORTED

			program_icon_state = "contracts"

			return TRUE
		if("PRG_redeem_TC")
			if (hard_drive.antag_data.contractor_hub.contract_TC_to_redeem)
				var/obj/item/stack/telecrystal/crystals = new /obj/item/stack/telecrystal(get_turf(user),
															hard_drive.antag_data.contractor_hub.contract_TC_to_redeem)
				if(ishuman(user))
					var/mob/living/carbon/human/H = user
					if(H.put_in_hands(crystals))
						to_chat(H, span_notice("Your payment materializes into your hands!"))
					else
						to_chat(user, span_notice("Your payment materializes onto the floor."))

				hard_drive.antag_data.contractor_hub.contract_paid_out += hard_drive.antag_data.contractor_hub.contract_TC_to_redeem
				hard_drive.antag_data.contractor_hub.contract_TC_to_redeem = 0
				return TRUE
			else
				user.playsound_local(user, 'sound/machines/uplinkerror.ogg', 50)
			return TRUE
		if ("PRG_clear_error")
			error = ""
			return TRUE
		if("PRG_set_first_load_finished")
			first_load = FALSE
			return TRUE
		if("PRG_toggle_info")
			info_screen = !info_screen
			return TRUE
		if ("buy_hub")
			if (hard_drive.antag_data.owner.current == user)
				var/item = params["item"]

				for (var/datum/contractor_item/hub_item in hard_drive.antag_data.contractor_hub.hub_items)
					if (hub_item.name == item)
						hub_item.handle_purchase(hard_drive.antag_data.contractor_hub, user)
			else
				error = "Invalid user... You weren't recognised as the user of this system."

/datum/computer_file/program/contract_uplink/ui_data(mob/user)
	var/list/data = list()
	var/obj/item/computer_hardware/hard_drive/small/syndicate/hard_drive = computer.all_components[MC_HDD]
	var/screen_to_be = null

	data["first_load"] = first_load

	if (hard_drive && hard_drive.antag_data != null)
		var/datum/antagonist/traitor/antag_data = hard_drive.antag_data
		data += get_header_data()

		if (antag_data.contractor_hub.current_contract)
			data["ongoing_contract"] = TRUE
			screen_to_be = "single_contract"
			if (antag_data.contractor_hub.current_contract.status == CONTRACT_STATUS_EXTRACTING)
				data["extraction_enroute"] = TRUE
				screen_to_be = "extracted"
			else
				data["extraction_enroute"] = FALSE
		else
			data["ongoing_contract"] = FALSE
			data["extraction_enroute"] = FALSE

		data["logged_in"] = TRUE
		data["station_name"] = GLOB.station_name
		data["redeemable_tc"] = antag_data.contractor_hub.contract_TC_to_redeem
		data["earned_tc"] = antag_data.contractor_hub.contract_paid_out
		data["contracts_completed"] = antag_data.contractor_hub.contracts_completed
		data["contract_rep"] = antag_data.contractor_hub.contract_rep

		data["info_screen"] = info_screen

		data["error"] = error

		for (var/datum/contractor_item/hub_item in antag_data.contractor_hub.hub_items)
			data["contractor_hub_items"] += list(list(
				"name" = hub_item.name,
				"desc" = hub_item.desc,
				"cost" = hub_item.cost,
				"limited" = hub_item.limited,
				"item_icon" = hub_item.item_icon
			))

		for (var/datum/syndicate_contract/contract in antag_data.contractor_hub.assigned_contracts)
			if(!contract.contract)
				stack_trace("Syndiate contract with null contract objective found in [antag_data.owner]'s contractor hub!")
				contract.status = CONTRACT_STATUS_ABORTED
				continue

			data["contracts"] += list(list(
				"target" = contract.contract.target,
				"target_rank" = contract.target_rank,
				"payout" = contract.contract.payout,
				"payout_bonus" = contract.contract.payout_bonus,
				"dropoff" = contract.contract.dropoff,
				"id" = contract.id,
				"status" = contract.status,
				"message" = contract.wanted_message
			))

		var/direction
		if (antag_data.contractor_hub.current_contract)
			var/turf/curr = get_turf(user)
			var/turf/dropoff_turf
			data["current_location"] = "[get_area_name(curr, TRUE)]"

			for (var/turf/content in antag_data.contractor_hub.current_contract.contract.dropoff.contents)
				if (isturf(content))
					dropoff_turf = content
					break

			if(curr.z == dropoff_turf.z) //Direction calculations for same z-level only
				direction = uppertext(dir2text(get_dir(curr, dropoff_turf))) //Direction text (East, etc). Not as precise, but still helpful.
				if(get_area(user) == antag_data.contractor_hub.current_contract.contract.dropoff)
					direction = "LOCATION CONFIRMED"
			else
				direction = "???"

			data["dropoff_direction"] = direction

	else
		data["logged_in"] = FALSE

	program_icon_state = screen_to_be
	update_computer_icon()
	return data
