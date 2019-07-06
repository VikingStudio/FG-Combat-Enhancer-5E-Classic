--  Please see the COPYRIGHT.txt file included with this distribution for attribution and copyright information.


-- Global Constants --

-- Underlay colors for tokens on the map. First two numbers/letters refer to the alpha channel or transparency levels.
-- Alpha channel (ranging from 0-255) in hex, opacity at 40% = 66, 30% = 4D , 20% = 33, 10% = 1A.
-- The opacity is set to 20% by default, but is now modifiable on the fly in the Settings menu.
-- You can change the three colors here by changing the 6 characters after the first 2 (the alpha channel).
TOKENUNDERLAYCOLOR_1 = "3300FF00"; -- Tokens active turn. 
TOKENUNDERLAYCOLOR_2 = "33F9FF44"; -- Token added to battlemap, but not on combat tracker.
TOKENUNDERLAYCOLOR_3 = "330000FF"; -- Token mouse over hover.



function onInit()	
	Token.onClickDown = onClickDown;	
	--Comm.onReceiveOOBMessage = processCommand;	
	--Token.onDoubleClick = openTokenInformationWindow;		
	--OptionsManager.onOptionChanged = onOptionChangedMenuSwitch;
	registerMenuItems();
	updateUnderlayOpacity();
	DB.addHandler("options.CE_UOP", "onUpdate", updateUnderlayOpacity);			
end



-- Add menu items to the Settings menu, pertaining to the 5e Combat Enhancer extension.
function registerMenuItems() 	
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
	OptionsManager.registerOption2("CE_CFNPC", false, "option_header_5ecombatenhancer", "option_fade_npc_effect_icons_on_death", "option_entry_cycler",
		{ labels = "option_val_off", values = "off", baselabel = "option_val_on", baseval = "on", default = "on" })					
	OptionsManager.registerOption2("CE_BSS", false, "option_header_5ecombatenhancer", "option_blood_splatter_scaling", "option_entry_cycler",
		{ labels = "default|default x 0.5|default x 0.75|default x 1.25|default x 1.5|default x 1.75|default x 2", values = "default|default_1|default_2|default_3|default_4|default_5|default_6", default = "default" })
	OptionsManager.registerOption2("CE_TES", false, "option_header_5ecombatenhancer", "option_token_effect_size", "option_entry_cycler",
		{ labels = "tiny|small|medium", values = "option_tiny|option_small|option_medium", default = "option_medium" })
		-- { labels = "tiny|small|medium|large|huge|gargantuan", values = "option_tiny|option_small|option_medium|option_large|option_huge|option_gargantuan", default = "option_medium" })
	OptionsManager.registerOption2("CE_TEMN", false, "option_header_5ecombatenhancer", "option_token_effects_max_number", "option_entry_cycler",
		{ labels = "1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|17|18|19|20", values = "1|2|3|4|5|6|7|8|9|10|11|12|13|14|15|16|17|18|19|20", default = "20" })		
--	OptionsManager.registerOption2("CE_BFSITF", false, "option_header_5ecombatenhancer", "option_bring_full_screen_interface_to_front", "option_entry_cycler",
--		{ labels = "option_val_off", values = "off", baselabel = "option_val_on", baseval = "on", default = "on" })				
	OptionsManager.registerOption2("CE_HFS", false, "option_header_5ecombatenhancer", "option_height_font_size", "option_entry_cycler",
		{ labels = "small|medium|large", values = "option_small|option_medium|option_large", default = "option_medium" })		
	OptionsManager.registerOption2("CE_ARM", false, "option_header_5ecombatenhancer", "option_automatic_ranged_modifiers", "option_entry_cycler",
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "on" })		
	OptionsManager.registerOption2("CE_SNIA", false, "option_header_5ecombatenhancer", "option_skip_non_initiatived_actor", "option_entry_cycler",
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "on" })		
	OptionsManager.registerOption2("CE_FR", false, "option_header_5ecombatenhancer", "option_flanking_rules", "option_entry_cycler",
		{ labels = "Advantage|+1|+2|+5", values = "option_val_on|option_val_1|option_val_2|option_val_on_5", baselabel = "option_val_off", baseval = "option_val_off", default = "option_val_off" })	
	OptionsManager.registerOption2("CE_HHB", false, "option_header_5ecombatenhancer", "option_horizontal_health_bars", "option_entry_cycler",
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "on" })							
	OptionsManager.registerOption2("CE_RMM", false, "option_header_5ecombatenhancer", "option_ranged_melee_modifier", "option_entry_cycler",
		{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "on" })											
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
end



-- return integer width of token condition tokens, depending on the Settings menu item selected
function getTokenEffectWidth()
	local tokenWidth = 58; -- default original condition icon width, can't go above this unless I increase size of graphics
	local tokenSizeSelection = OptionsManager.getOption("CE_TES"); --option_tiny|option_small|option_medium
	
	if tokenSizeSelection == 'option_tiny' then
		tokenWidth = 20;
	elseif tokenSizeSelection == 'option_small' then
		tokenWidth = 32;
	elseif tokenSizeSelection == 'option_medium' then
		tokenWidth = 58;
	-- the below won't be usable unless enlargened icon graphics are used to replace the original, currently not part of the menu options		
	elseif tokenSizeSelection == 'option_large' then
		tokenWidth = 70;
	elseif tokenSizeSelection == 'option_huge' then
		tokenWidth = 100;
	elseif tokenSizeSelection == 'option_gargantuan' then
		tokenWidth = 150;		
	end		

	return tokenWidth;
end


-- return integer of the maximum number of token effects, depending on the Settings menu item selected
function getMaxTokenEffects()
	local tokenEffectsMax = 20; -- default original number of effects
	tokenEffectsMax = OptionsManager.getOption("CE_TEMN"); -- options 1 - 20
	
	return tonumber(tokenEffectsMax);
end



-- Open record when token is shift-left clicked (direct copy from CoreRPG.pak FG v3.3.7, function onDoubleClick(tokenMap, vImage))
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



------------------------------------------------------------- TEST DEVELOPMENT FUNCTIONS BELOW, NOT USED IN LIVE BUILD ------------------------


-- TEST FUNCTION
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





-- TEST FUNCTION
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


-- TEST FUNCTION
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





-- TEST FUNCTION
-- function to handle custom chat commands
function processCommand( tabledata )	
	Debug.console(tabledate);
end


-- TEST FUNCTION
-- origin: CoreRPG/scripts/manager_options.lua
-- updated to refresh widgets for health bars when that menu option is toggled between horizontal and vertical health bars
function onOptionChangedMenuSwitch(nodeOption)
	local sKey = nodeOption.getName();
	if not User.isLocal() then
		CampaignRegistry["Opt" .. sKey] = getOption(sKey);
	end

--	local bHorizontalHealthBars = OptionsManager.getOption('CE_HHB');
--	if bHorizontalHealthBars == "on" then

--	else
--	end

	makeCallback(sKey);
end