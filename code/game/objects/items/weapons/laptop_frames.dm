/obj/item/weapon/laptopframe
	name = "laptop frame"
	desc = "A portable console frame that can be loaded with a console board to easily deploy on the field. Deploying the frame will cause it to secure itself firmly into the ground and draw power from the room to function until it is collapsed and deactivated for easy storage. Activate in hand then select an adjacent tile or table to deploy./ Drag yourself onto the laptop to undeploy back to portable mode."
	icon = 'icons/obj/laptop.dmi'
	icon_state = "laptop"
	var/initial_icon = "laptop"
	//inhand_states = list("left_hand" = 'icons/mob/in-hand/left/laptops.dmi', "right_hand" = 'icons/mob/in-hand/right/laptops.dmi')
	//item_state
	flags = FPRINT
	var/obj/item/weapon/circuitboard/circuit = null
	var/diskdrive_open = FALSE
	//var/list/obj/item/weapon/circuitboard/module_list = null //in case a non-programmable laptop can store more than a single circuit module it will let the user pick from this list to designate as the active circuit before deploying
	//var/obj/item/weapon/cell/connected_cell = null //store a powercell to draw power from.
	var/deployready = FALSE


//laptop frames hold path to circuit
//they deploy into laptops which are functionally like consoles
//while in deployed state, the frame is stored within the console, some console procs will check for non-null values to treat as a special laptop.
//
//laptops do not enter broken state like consoles, instead they explode and are obliterated if damaged severaly
//


/obj/item/weapon/laptopframe/proc/examine_modules(var/mob/user)
	if(circuit)
		if(deployready)
			to_chat(user, "<span class='good'> It is ready to deploy with [circuit.name].</span>")
		else
			to_chat(user, "<span class='good'> Activate in hand to deploy with [circuit.name].</span>")
	else
		to_chat(user, "<span class='warning'> There is no circuit board installed.</span>")
	//if(connected_cell)
	//	to_chat(user, "<span class='good'>The battery meter reads: [round(connected_cell.percent(),1)]%</span>")
	//else
	//	to_chat(user, "<span class='warning'> There is no battery inserted.</span>")
	return


/obj/item/weapon/laptopframe/examine(var/mob/user)
	. = ..()
	//examine_modules(user)


/obj/item/weapon/laptopframe/proc/deploy_frame(mob/user, turf/T)
	if (do_after(user, src, 5))
		if(!circuit.build_path) // the board has been soldered away!
			to_chat(user, "<span class='warning'>You deploy the monitor, but nothing turns on! Perhaps the circuitboard is busted...</span>")
			return
		var/B = new src.circuit.build_path ( get_turf(T) )
		to_chat(user, "<span class='notice'>You deploy the portable console frame.</span>")
		//TODO playsound
		if(circuit.powernet)
			B:powernet = circuit.powernet
		if(circuit.id_tag)
			B:id_tag = circuit.id_tag
		if(circuit.records)
			B:records = circuit.records
		if(circuit.frequency)
			B:frequency = circuit.frequency
		if(istype(circuit,/obj/item/weapon/circuitboard/supplycomp))
			var/obj/machinery/computer/supplycomp/SC = B
			var/obj/item/weapon/circuitboard/supplycomp/C = circuit
			SC.can_order_contraband = C.contraband_enabled
		else if(istype(circuit,/obj/item/weapon/circuitboard/arcade))
			var/obj/machinery/computer/arcade/arcade = B
			var/obj/item/weapon/circuitboard/arcade/C = circuit
			arcade.import_game_data(C)
		var/obj/machinery/MA = B
		if(istype(MA))
			MA.power_change()
		if(istype(MA,/obj/machinery/computer))
			var/obj/machinery/computer/CM = MA
			src.transfer_fingerprints_to(CM)
			//CM.connected_cell = src.connected_cell
		qdel(src)
		return

/obj/item/weapon/laptopframe/preattack(atom/A, mob/user, proximity_flag)
	if(deployready)
		to_chat(user, "deploy ready pass.")//debug
		if(proximity_flag)
			to_chat(user, "proximity check pass.")//debug
			if(istype(A,/turf/unsimulated/floor) || istype(A,/turf/simulated/floor))
				var/turf/T = A
				deploy_frame(user,T)
			else if(istype(A,/obj/structure/table))
				var/obj/structure/table/T = A
				deploy_frame(user,get_turf(T))
			else
				return


/obj/item/weapon/laptopframe/dropped()
	..()
	//reset deploy ready if it leaves users hands
	if(deployready)
		deployready = FALSE


/obj/item/weapon/laptopframe/attack_self(mob/user as mob)
	//TODO - replace with NanoUI interface
	toggle_deploy(user)
	..()



/obj/item/weapon/laptopframe/proc/toggle_deploy(mob/user as mob)
	if(!deployready)
		deployready = TRUE
		to_chat(user, "Laptop is ready to deploy. Select a nearby table or floor tile to use.")
		return
	if(deployready)
		deployready = FALSE
		to_chat(user, "Laptop is no longer ready to deploy.")
		return


//obj/item/weapon/laptopframe/attack_self(mob/user as mob)
	//ui_interact(user)

/obj/item/weapon/laptopframe/verb/openUI(mob/user) //DEBUG
	ui_interact(user)

/obj/item/weapon/laptopframe/ui_interact(mob/user, ui_key = "main", var/datum/nanoui/ui = null, var/force_open = 1)
	var/list/data = list()
	if(circuit)
		data["circuitName"] = "[circuit.name]"
	else
		data["circuitName"] = "No circuitboard loaded!"
	data["deployReady"] = deployready
	 // update the ui with data if it exists, returns null if no ui is passed/found or if force_open is 1/true
	ui = nanomanager.try_update_ui(user, src, ui_key, ui, data, force_open)
	if(!ui)
    	// the ui does not exist, so we'll create a new() one
		// for a list of parameters and their descriptions see the code docs in \code\modules\nano\nanoui.dm
		ui = new(user, src, ui_key, "laptop.tmpl", "Laptop UI", 520, 410)
		// when the ui is first opened this is the data it will use
		ui.set_initial_data(data)
		// open the new ui window
		ui.open()

obj/item/weapon/laptopframe/Topic(href, href_list)
	if(..())
		return FALSE
	if(href_list["toggle_deploy"])
		toggle_deploy(usr)
		return TRUE

/*
  // this is the data which will be sent to the ui, it must be a list
  var/list/data = list()
  // we'll add some simple data here as an example
  data["myName"] = name
  data["myDesc"] = desc
  data["circuitEmpty"] = "No Circuitboard Loaded"
  data["circuitName"] =
  //if(circuit)
  //data["circuitName"] = circuit.name

  data["assocList"] = list("key1" = "Value1", "key2" = "Value2")

  // the backslash tells the compiler to ignore the carriage return, treating the easy-to-read format as a single line.
  data["arrayOfAssocLists"] = list(\
    list("key1" = "ValueA1", "key2" = "ValueA2"),\
    list("key1" = "ValueB1", "key2" = "ValueB2"),\
    list("key1" = "ValueC1", "key2" = "ValueC2")
  )

  data["emptyArray"] = list()

*/





//custom cams
//obj/item/weapon/circuitboard/

//obj/machinery/computer/

//custom records
//obj/item/weapon/circuitboard/

//obj/machinery/computer/





//obj/item/weapon/laptopframe/portable_paramedic_cmc



	//modules:
	//crew monitoring console
	//surgery console
	//medical records

//obj/item/weapon/laptopframe/portable_power_monitor


////////Forensic Scanner Briefcase////////
/obj/item/weapon/laptopframe/portable_forensic_frame
	//Forensic scanner made to look like an unassuming briefcase for the complete SPY feel.
	name = "briefcase"
	desc = "It's made of AUTHENTIC faux-leather and has a price-tag still attached. Its owner must be a real professional."
	inhand_states = list("left_hand" = 'icons/mob/in-hand/left/backpacks_n_bags.dmi', "right_hand" = 'icons/mob/in-hand/right/backpacks_n_bags.dmi')
	icon = 'icons/obj/storage/storage.dmi'
	icon_state = "briefcase"
	force = 8.0
	throw_speed = 1
	throw_range = 4
	w_class = W_CLASS_LARGE
	hitsound = "swing_hit"
	var/examine_held = "<span class='notice'> This briefcase secretly houses a hidden state of the art forensics machine that can be deployed anywhere in the field.</span>"


/obj/item/weapon/circuitboard/forensic_computer/portable_forensic_console
	name = "Circuit board (Portable Forensics Console)"
	build_path = /obj/machinery/computer/forensic_scanning/portable_forensic_console


/obj/item/weapon/laptopframe/portable_forensic_frame/New()
	src.circuit = new /obj/item/weapon/circuitboard/forensic_computer/portable_forensic_console

//alt click to deploy
/obj/item/weapon/laptopframe/portable_forensic_frame/AltClick(mob/user)
	deploy_frame(user, get_turf(src))


//closeup examine
/obj/item/weapon/laptopframe/portable_forensic_frame/examine(var/mob/user)
	. = ..()
	if(src in user.held_items || istype(user, /mob/dead))
		to_chat(user, examine_held)
		examine_modules(user)


//The deployed laptop console
/obj/machinery/computer/forensic_scanning/portable_forensic_console
	name = "Portable High-Res Forensic Scanning Computer"
	icon = 'icons/obj/laptop.dmi'
	density = 0
	var/obj/item/weapon/laptopframe/laptopholder = /obj/item/weapon/laptopframe/portable_forensic_frame
	computer_flags = NO_ONOFF_ANIMS

/obj/machinery/computer/forensic_scanning/portable_forensic_console/togglePanelOpen(var/obj/item/toggleitem, mob/user, var/obj/item/weapon/circuitboard/CC = null)
	togglePanelOpenLaptop(toggleitem,user,CC)

/obj/machinery/computer/forensic_scanning/portable_forensic_console/proc/undeploy_laptop(mob/user)
	to_chat(user, "<span class='notice'>You begin to undeploy \the [src].</span>")
	var/obj/item/weapon/laptopframe/L = new src.laptopholder (src.loc)
	src.transfer_fingerprints_to(L)
	for (var/obj/C in src)
		C.forceMove(src.loc)
	qdel(src)
	return

/obj/machinery/computer/forensic_scanning/portable_forensic_console/set_broken()
	//explode upon breaking? why? because you have to protect your dinky little laptop. Also this way laptops have some drawback compared to reliable old consoles.
	visible_message("<span class='danger'>\The [src] blows apart!</span>")
	spark(src)
	explosion(loc,-1,-1,0)
	for (var/obj/C in src)
		C.forceMove(src.loc)
	qdel(src)

/obj/machinery/computer/forensic_scanning/portable_forensic_console/examine(var/mob/user)
	..()
	to_chat(user, "<span class='notice'> Undeploy with right click.</span>")

/obj/machinery/computer/forensic_scanning/portable_forensic_console/AltClick(mob/user)
	if (do_after(user, src, 5))
		undeploy_laptop(user)

/obj/machinery/computer/forensic_scanning/portable_forensic_console/proc/togglePanelOpenLaptop(var/obj/item/toggleitem, mob/user, var/obj/item/weapon/circuitboard/CC = null)
	toggleitem.playtoolsound(src, 50)
	undeploy_laptop(user)


/obj/machinery/computer/forensic_scanning/portable_forensic_console/Topic(href,href_list)
	..()
	switch(href_list["operation"])
		if("undeploy laptop")
			undeploy_laptop(usr)