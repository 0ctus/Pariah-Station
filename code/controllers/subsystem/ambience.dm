/// The subsystem used to play ambience to users every now and then, makes them real excited.
SUBSYSTEM_DEF(ambience)
	name = "Ambience"
	flags = SS_BACKGROUND|SS_NO_INIT
	priority = FIRE_PRIORITY_AMBIENCE
	runlevels = RUNLEVEL_GAME | RUNLEVEL_POSTGAME
	wait = 1 SECONDS
	///Assoc list of listening client - next ambience time
	var/list/ambience_listening_clients = list()
	var/list/client_old_areas = list()
	///Cache for sanic speed :D
	var/list/currentrun = list()

/datum/controller/subsystem/ambience/fire(resumed)
	if(!resumed)
		currentrun = ambience_listening_clients.Copy()
	var/list/cached_clients = currentrun

	while(cached_clients.len)
		var/client/client_iterator = cached_clients[cached_clients.len]
		cached_clients.len--

		//Check to see if the client exists and isn't held by a new player
		var/mob/client_mob = client_iterator.mob
		if(isnull(client_iterator) || isnewplayer(client_mob))
			ambience_listening_clients -= client_iterator
			client_old_areas -= client_iterator
			continue

		//Check to see if the client-mob is in a valid area
		var/area/current_area = get_area(client_mob)
		if(!current_area) //Something's gone horribly wrong
			stack_trace("[key_name(client_mob)] has somehow ended up in nullspace. WTF did you do")
			ambience_listening_clients -= client_iterator
			continue

		if(!(current_area.forced_ambience && (client_old_areas?[client_iterator] != current_area)))
			if(ambience_listening_clients[client_iterator] > world.time)
				continue

		//Run play_ambience() on the client-mob, and set it's ambience cooldown relative to the length of the sound played.
		ambience_listening_clients[client_iterator] = world.time + current_area.play_ambience(client_mob)

		//We REALLY don't want runtimes in SSambience
		if(client_iterator)
			client_old_areas[client_iterator] = current_area

		if(MC_TICK_CHECK)
			return

///Attempts to play an ambient sound to a mob, returning the cooldown in deciseconds
/area/proc/play_ambience(mob/M, sound/override_sound)
	var/turf/T = get_turf(M)
	var/sound/new_sound = override_sound || pick(ambientsounds)
	new_sound = sound(new_sound, channel = CHANNEL_AMBIENCE)
	M.playsound_local(T, new_sound, 33, TRUE, channel = CHANNEL_AMBIENCE)
	return rand(min_ambience_cooldown, max_ambience_cooldown) + (new_sound.len * 10) //Convert to deciseconds

/datum/controller/subsystem/ambience/proc/remove_ambience_client(client/to_remove)
	ambience_listening_clients -= to_remove
	client_old_areas -= to_remove
	currentrun -= to_remove

/area/maintenance
	min_ambience_cooldown = 10 SECONDS
	max_ambience_cooldown = 20 SECONDS
	ambientsounds = list(
	'sound/machines/airlock_alien_prying.ogg',
	'sound/voice/hiss1.ogg',
	'sound/voice/hiss2.ogg',
	'sound/voice/hiss3.ogg',
	'sound/voice/hiss4.ogg',
	'sound/voice/hiss5.ogg',
	'sound/voice/hiss6.ogg',
	'sound/voice/lowHiss1.ogg',
	'sound/voice/lowHiss2.ogg',
	'sound/voice/lowHiss3.ogg',
	'sound/voice/lowHiss4.ogg',
	'sound/ambience/maintambience.ogg',
	)

	var/static/list/minecraft_cave_noises = list(
	'sound/machines/airlock.ogg',
	'sound/voice/snap.ogg',
	'sound/effects/clownstep1.ogg',
	'sound/effects/clownstep2.ogg',
	'sound/items/welder.ogg',
	'sound/items/welder2.ogg',
	'sound/items/crowbar.ogg',
	'sound/items/deconstruct.ogg',
	'sound/ambience/source_holehit3.ogg',
	'sound/ambience/cavesound3.ogg',
	'sound/ambience/Cave1.ogg',
	)

/area/maintenance/play_ambience(mob/M, sound/override_sound)
	if(!M.has_light_nearby() && prob(0.1))
		return ..(M, pick(minecraft_cave_noises))

	return ..()
