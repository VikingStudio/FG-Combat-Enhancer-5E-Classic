--  Please see the COPYRIGHT.txt file included with this distribution for attribution and copyright information.


--[[
	Insert our NPC ID option into the options menu
]]--

function onInit()
	registerOptions(); 
end

function registerOptions()
	OptionsManager.registerOption2("NPID", false, "option_header_game", "option_label_NPID", "option_entry_cycler",
			{ labels = "option_val_on", values = "on", baselabel = "option_val_off", baseval = "off", default = "off" });
end
