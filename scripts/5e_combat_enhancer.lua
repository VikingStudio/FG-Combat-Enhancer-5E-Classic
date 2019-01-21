--  Please see the COPYRIGHT.txt file included with this distribution for attribution and copyright information.

--[[
	on Init
]]--

-- Global Constants --

-- Underlay colors for tokens on the map. First two numbers/letters refer to the alpha channel or transparency levels.
-- Alpha channel (ranging from 0-255) in hex, opacity at 40% = 66, 30% = 4D , 20% = 33, 10% = 1A.
-- The opacity is set to 20% by default, but is now modifyable on the fly in the Settings menu.
-- You can change the three colors here by changing the 6 characters after the first 2 (the alpha channel).
TOKENUNDERLAYCOLOR_1 = "3300FF00"; -- Tokens active turn. 
TOKENUNDERLAYCOLOR_2 = "33F9FF44"; -- Token added to battlemap, but not on combat tracker.
TOKENUNDERLAYCOLOR_3 = "330000FF"; -- Token mouse over hover.




function onInit()	
	Token.onClickDown = onClickDown;	
	-- Token.onDrag = dynamicShadows	
	--Token.onDoubleClick = openTokenInformationWindow;	

	registerMenuItems();
	updateUnderlayOpacity();
	DB.addHandler("options.CE_UOP", "onUpdate", updateUnderlayOpacity);		
end


-- changes the FM token underlay opacity to reflect selection in Settings menu
function updateUnderlayOpacity()
	local opacitySetting = OptionsManager.getOption('CE_UOP');	
	
	-- if no setting is found, return the 20% opacity settubg as it's the default
	if (opacitySetting == nil) or (opacitySetting == '') then
		opacitySetting = 'option_val_20'; 
	end

	-- Underlay colors for tokens on the map. First two numbers/letters refer to the alpha channel or transparency levels.
	-- Alpha channel (ranging from 0-255) in hex, opacity at 40% = 66, 30% = 4D , 20% = 33, 10% = 1A.
	local hexAlphaTable =
	{
		['option_val_100'] = 'FF',
		['option_val_90'] = 'E6',
		['option_val_80'] = 'CC',
		['option_val_70'] = 'B3',
		['option_val_60'] = '99',
		['option_val_50'] = '80',
		['option_val_40'] = '66',
		['option_val_30'] = '4D',
		['option_val_20'] = '33',
		['option_val_10'] = '1A',
	}

	-- replace alpha channel with new setting (first two characters)	
	TOKENUNDERLAYCOLOR_1 = hexAlphaTable[opacitySetting] .. string.sub(TOKENUNDERLAYCOLOR_1, 3)	
	TOKENUNDERLAYCOLOR_2 = hexAlphaTable[opacitySetting] .. string.sub(TOKENUNDERLAYCOLOR_2, 3)
	TOKENUNDERLAYCOLOR_3 = hexAlphaTable[opacitySetting] .. string.sub(TOKENUNDERLAYCOLOR_3, 3)	
end


-- Delete token / and CT entry on mouse click.
-- Use: Mouse Left-click Token on combat map while holding down either 'Alt' or 'Alt+Ctrl'
-- Pre: Token on combat map
-- Post: Token removed from combat map (Alt) or combat map and combat tracker (Atl+Ctrl)
-- NOTE: button (number), Returns a numerical value indicating the button pressed (1 = left, 2 = middle, 4 = button 4, 5 = button 5). Right button is used for radial menus.
function onClickDown( token, button, image ) 	
	-- TEST SECTION
	--bringInterfaceToFront();
	--applyRangedWeaponModifiers();	
	--pingExpandingCircle()
	-- END OF TEST SECTION


	-- Deletes token from combat map, if Alt held on left mouse click.
	if (Input.isAltPressed() == true) and (User.isHost() == true) and (button==1) then
		local nodeCT = CombatManager.getCTFromToken(token);
		token.delete();		

		-- Deletes token from combat tracker if Ctrl was also held on click.
		if (Input.isControlPressed() == true) then
			if nodeCT then -- only attempt delete if there is a CT entry
				nodeCT.delete();					
			end				
		end
	end		

	-- Code below works, but for now leaving it as double-click on token, as this is the default behaviour of FG.
	-- Opens up NPC dialogue sheet if ctrl + left mouse click on token
	--[[
	if (Input.isControlPressed() == true) and (User.isHost() == true) and (button==1) then		
		--Debug.chat('open NPC sheet');
		onDoubleClick(token, image);		
	end	
	]]--	

	-- Allow players to move their own tokens with middle mouse button press when tokens are locked.
	-- Possibly add this as a menu option to allow or disallow.
	--if button == 2 then
		-- token move on path defined during locked stage
	--	owner = getTokenPlayer( token );
	--end
end


-- Add menu items to the Settings menu, pertaining to the 5e Combat Enhancer extension.
function registerMenuItems() 
	-- 20% opacity default	
	OptionsManager.registerOption2("CE_UOP", false, "option_header_5ecombatenhancer", "option_gm_underlay", "option_entry_cycler",
		{ labels = "100%|90%|80%|70%|60%|50%|40%|30%|20% (best)|10%", values = "option_val_100|option_val_90|option_val_80|option_val_70|option_val_60|option_val_50|option_val_40|option_val_30|option_val_20|option_val_10", default = "option_val_20" })		
	OptionsManager.registerOption2("CE_RBS", false, "option_header_5ecombatenhancer", "option_render_blood_splatter_on_death", "option_entry_cycler",
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" })
	OptionsManager.registerOption2("CE_DSOD", false, "option_header_5ecombatenhancer", "option_draw_skull_on_death", "option_entry_cycler",
		{ labels = "option_val_off", values = "off", baselabel = "option_val_on", baseval = "on", default = "on" })
	OptionsManager.registerOption2("CE_DBOT", false, "option_header_5ecombatenhancer", "option_draw_blood_on_token", "option_entry_cycler",
		{ labels = "option_val_off", values = "off", baselabel = "option_val_on", baseval = "on", default = "on" })
	OptionsManager.registerOption2("CE_CTFNPC", false, "option_header_5ecombatenhancer", "option_fade_ct_npc_on_death", "option_entry_cycler",
		{ labels = "option_val_off", values = "off", baselabel = "option_val_on", baseval = "on", default = "on" })		
	OptionsManager.registerOption2("CE_BFSITF", false, "option_header_5ecombatenhancer", "option_bring_full_screen_interface_to_front", "option_entry_cycler",
		{ labels = "option_val_off", values = "off", baselabel = "option_val_on", baseval = "on", default = "on" })			
	OptionsManager.registerOption2("CE_BSS", false, "option_header_5ecombatenhancer", "option_blood_splatter_scaling", "option_entry_cycler",
		{ labels = "default|default x 1.25|default x 1.5|default x 1.75|default x 2|default x 2.5|default x 3", values = "default|default_1|default_2|default_3|default_4|default_5|default_6", default = "default_1" })
end


-- bring chat window and modifiers stack on top of the full screen background image
function bringInterfaceToFront()	
	Debug.chat('bringing chat and modifiers to front');
	
	-- From CoreRPG /desktop/desktop_classes.xml :
	--<windowclass name="chat">
	--<windowclass name="modifierstack">
	-- From CoreRPG base.xml :
	--<script name="ModifierStack" file="desktop/scripts/modifierstack.lua" />
	--<script name="ChatManager" file="scripts/manager_chat.lua" />

	local bringInterfaceToFront = OptionsManager.getOption('CE_BFSITF'); -- Settings > 5e Combat Enhancer > Chat and modifiers on top (full screen)

	if bringInterfaceToFront == 'on' then		
		local wChat = Interface.findWindow('chat', '');
		local wModifiers = Interface.findWindow('modifierstack', '');
		local wImage = Interface.findWindow('imagewindow', '');

		Debug.chat('wChat', wChat);
		Debug.chat('wModifiers', wModifiers);
		Debug.chat('wImage', wImage);

		--wChat.setVisible(true);
		--wModifiers.setVisible(true);
		
		wChat.bringToFront(); 
		--wImage.bringToFront();
		wModifiers.bringToFront();
	end
end	

-- a modified Token.onDrag event, for handling dynamic shadows
function dynamicShadows( token, mouseButton, x, y, dragdata )
	Debug.chat('token ', token)	
	--local image = UpdatedImageWindow.image
	Debug.chat('controls ', image)	
	local gridType = image.getGridType() -- only work with square hexes for simplicy to begin with
	local gridSize = image.getGridSize()
	local gridOffset = image.getGridOffset()
	local maskTool = image.getMaskTool()
	local maskLayer = image.hasMask()

	image.setMaskEnabled(true)
	image.setDrawingSize(500,500, 50, 50)
	-- make selection
	-- mask or unmask
	image.setMaskTool(unmaskelection) --Valid values are "maskselection" and "unmaskelection

	--Debug.chat('image ', image, ' gridType ', gridType)		
end


-- Open record when token is double clicked (direct copy from CoreRPG.pak FG v3.3.7, function onDoubleClick(tokenMap, vImage))
function openTokenInformationWindow(tokenMap, vImage)			
	local nodeCT = CombatManager.getCTFromToken(tokenMap);
	if nodeCT then
		if User.isHost() then
			local sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
			if sRecord ~= "" then
				Interface.openWindow(sClass, sRecord);				
			else
				Interface.openWindow(sClass, nodeCT);				
			end
		else
			if (DB.getValue(nodeCT, "friendfoe", "") == "friend") then
				local sClass, sRecord = DB.getValue(nodeCT, "link", "", "");
				if sClass == "charsheet" then
					if sRecord ~= "" and DB.isOwner(sRecord) then
						Interface.openWindow(sClass, sRecord);						
					else
						ChatManager.SystemMessage(Interface.getString("ct_error_openpclinkedtokenwithoutaccess"));
					end
				else
					local nodeActor;
					if sRecord ~= "" then
						nodeActor = DB.findNode(sRecord);
					else
						nodeActor = nodeCT;
					end
					if nodeActor then
						local w = Interface.openWindow(sClass, nodeActor);						
						w.bringToFront();
					else
						ChatManager.SystemMessage(Interface.getString("ct_error_openotherlinkedtokenwithoutaccess"));
					end
				end
				vImage.clearSelectedTokens();
			end
		end
	end
end


-- Ctrl click on map, timed function that draws circles ever larger (up to a set point), while deleting previous, to indicate a pinged location. 
-- Giving the impression of a timed expanding circle.
-- PointerToolkit  using scripts/pointer_toolkit.lua
function pingExpandingCircle()
	local startTime = os.time()
	local endTime = startTime+90
	Debug.chat('startTime', startTime)
	--while os.time() <= endTime do
	--	Debug.chat('timer', os.time())
		-- draw expanding vector circle on map
	--end	
end


-- Return owner for character sheet connected to Token
function getTokenPlayer(token)	
	local nodeCT = CombatManager.getCTFromToken(token);
	if nodeCT then
		local owner = nodeCT.getOwner();
		Debug.console('modifications>getTokenPlayer, nodeCt owner:', owner);
		--- DB.isOwner( nodeid )
		
		if User.isHost() then
		end	
		if not User.isHost() then
		end
	end				
end


-- determine and apply ranged modifers if any on ranged attacks by the active actor in the CT, to one selected target
function applyRangedWeaponModifiers() 
		-- get node from active actor in CT, CombatManager.getActiveCT()
		-- get their target(s) node(s) from the CT
		-- return distance and adjacent between the two using, TokenManager2.getDistance(nodeAttacker, nodeTarget)
		-- when attack done check distance, 
		-- if adjacent and attack ranged, apply disadvantage; 
		-- if attack ranged and not adjacent, check range, if between medium and max ranged apply disadvantage, if beyond max range, autofail / cancel attack
	
			
		local targets = token.getTargets();
		local nodeToken = '---'; -- DB.findNode(token)  returns invalid parameter
		local nodeTarget = DB.findNode(targets[1]);	
		local activeCTNode = CombatManager.getActiveCT();
		local tokenId = token.getId();
		local tokenContainerNode = token.getContainerNode();
		--local targetContainerNode = token.getContainerNode();
	
		Debug.chat('activeCTNode', activeCTNode, 'targets', targets, 'token', token, 'nodeToken', nodeToken, 'nodeTarget', nodeTarget, 'tokenContainerNode', tokenContainerNode);
	
--[[
		function getDistance(nodeAttacker, nodeTarget)
			if nodeAttacker and nodeTarget then
				local tokenAttacker = CombatManager.getTokenFromCT(CombatManager.asNodeCTName(nodeAttacker))
				local tokenTarget = CombatManager.getTokenFromCT(CombatManager.asNodeCTName(nodeTarget))
]]--
		local nDistance, bAdjacent = TokenManager2.getDistance( token, nodeTarget ); --function getDistance(nodeAttacker, nodeTarget)		
		Debug.chat('nDistance', nDistance, 'bAdjacent', bAdjacent);				
end