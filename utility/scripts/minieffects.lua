--[[
	Custom modifications Copyright (C) 2018 Ken L., Original Work.	
	Custom modifications Copyright (C) December 2018 onwards Styrmir, code and graphics modified by Styrmir from Original Work and other sources. Changelog available in Features and Changes document.	

	Licensed under the GPL Version 3 license.
	http://www.gnu.org/licenses/gpl.html
	This script is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	This script is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.
]]--

local BUTTON_SIZE = 25; 
local BUTTON_MARGIN = 5; 
local FRAME_XMARGIN = 12; 
local FRAME_YMARGIN = 12; 
--local FRAME_TOPGAP = 31; 
local FRAME_TOPGAP = 0; 


--[[
	Build our button matrix as well as custom effect list. We do this on Init,
	as the size of our effects list will vary. Note the hack to get at the
	subwindow size parameters as it will only return the bounded parameters
	of the subwindow as defined in the parent control. 
]]--
function onInit()
	if DataCommon and DataCommon.conditions then

		local btn,posX,posY,properName,sEffect1,lastY; 
		local offsetW = FRAME_XMARGIN;
		local offsetH = FRAME_YMARGIN; 
		local sW =  placement[1]['size'][1]['width'][1]; 
		local sH =  placement[1]['size'][1]['height'][1]; 
		--Debug.console('width ' .. sW .. ' height ' .. sH); 
		local widthLimit = math.floor((sW-2*FRAME_XMARGIN)/(BUTTON_SIZE+BUTTON_MARGIN*2)); 
		local heightLimit = math.floor((sH-2*FRAME_YMARGIN-FRAME_TOPGAP)/(BUTTON_SIZE+BUTTON_MARGIN*2)); 
		local max_icons = widthLimit*heightLimit; 
		--Debug.console('width limit: ' .. widthLimit .. ' height limit: ' .. heightLimit .. ' max: ' .. max_icons); 
		--for i=1, #DataCommon.conditions do
		for i=1, #DataCommon.conditions do
			-- if we have a value in DataCommon.condcomps[<value>]
			-- use that icon
			properName = DataCommon.conditions[i]:gsub('%-',''); 
			sIcon = DataCommon.condcomps[properName][1];
			--Debug.console('condition -> ' .. properName .. ' icon? : ' .. tostring(sIcon)); 
			if sIcon and i <= max_icons then
				btn = createControl("button_icon_effect",properName); 
				btn.setStateIcons('0',sIcon,sIcon); 
				btn.setTooltipText(DataCommon.conditions[i]); 
				--get the geometric coordinates
				posX,posY = getGridCoordinates(i,sW,sH,widthLimit,heightLimit); 
				--Debug.console('condition -> ' .. properName .. ' X : ' .. posX .. ' Y : ' .. posY); 
				btn.setStaticBounds(posX,posY,BUTTON_SIZE,BUTTON_SIZE); 
				-- add our effect to the button (script within button definitino)
				sEffect1 = StringManager.capitalize(DataCommon.conditions[i]);
				btn.setEffect(sEffect1);

				-- track this so we know where to place our list as our list
				-- size will vary, and we're placing absolutely
				lastY = posY; 
			end
		end

		-- place our 'content anchor' then create our list
		local ctlAnchor = createControl('anchor_minieffect','contentanchor'); 
		ctlAnchor.setStaticBounds(0,lastY+(BUTTON_SIZE+BUTTON_MARGIN*2),1,1); 
		local ctlCustomEffects = createControl('mini_list_effects','list'); 
		local ctlCustomEffectsFilter = createControl('filter_mini_effect','filter'); 

		ctlCustomEffectsFilter.setStaticBounds(35,lastY+(BUTTON_SIZE+BUTTON_MARGIN*2+15),155,20); 
		ctlCustomEffects.setStaticBounds(20,lastY+(BUTTON_SIZE+BUTTON_MARGIN*2+15)+40,180,215); 

		-- setup our filter since we had a delated creation
		-- go through each of our list's elements and apply the filter
		ctlCustomEffects.applyFilter(true);  
		--[[
		local tCustomEffectsElements = ctlCustomEffects.getWindows(); 
		for _,elem in pairs(tCustomEffectsElements) do
			Debug.console('init!'); 
		end
		]]--
	end
end

--[[
	Given the w/h, their limits, and the button number, get the grid coordinates
	assuming fill from top left to bottom right
]]--
function getGridCoordinates(numIcon, width, height, widthLimit, heightLimit)
	local row,colum,x,y;

	row = math.floor(numIcon/widthLimit);
	column = numIcon%widthLimit; 

	x = FRAME_XMARGIN + (numIcon%widthLimit-1)*(BUTTON_SIZE+BUTTON_MARGIN*2);
	y = FRAME_YMARGIN + FRAME_TOPGAP + math.floor(numIcon/widthLimit)*(BUTTON_SIZE+BUTTON_MARGIN*2); 

	if column == 0 then
		x = FRAME_XMARGIN + (BUTTON_SIZE+BUTTON_MARGIN*2)*(widthLimit-1); 
	end

	if numIcon%widthLimit == 0 then
		y = FRAME_YMARGIN + FRAME_TOPGAP + (BUTTON_SIZE+BUTTON_MARGIN*2)*(row-1); 
	end

	return x,y; 
end
