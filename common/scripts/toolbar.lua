--[[
	'Fantasy Grounds' is a trademark of SmiteWorks USA, LLC. 'Fantasy Grounds' is Copyright 2004-2014 SmiteWorks USA LLC.
	The CoreRPG ruleset and all included files are copyright 2004-2013, Smiteworks USA LLC.
]]--

local nButtons = 0;
local aButtons = {};

local nButtonSize = 20;
local nButtonHorzMargin = 1;
local nButtonVertMargin = 2;

function onInit()
	if parameters then
		if parameters[1].horzmargin then
			nButtonHorzMargin = tonumber(parameters[1].horzmargin[1]) or nButtonHorzMargin;
		end
		if parameters[1].vertmargin then
			nButtonVertMargin = tonumber(parameters[1].vertmargin[1]) or nButtonVertMargin;
		end
		if parameters[1].buttonsize then
			nButtonSize = tonumber(parameters[1].buttonsize[1]) or nButtonSize;
		end
	end

	if button and type(button[1]) == "table" then
		for k, v in ipairs(button) do
			if v.id and v.icon then
				local sID = v.id[1];
				local sIcon = v.icon[1];

				local sTooltip = "";
				if v.tooltipres then
					sTooltip = Interface.getString(v.tooltipres[1]);
				elseif v.tooltip then
					sTooltip = v.tooltip[1];
				end

				addButton(sID, sIcon, sTooltip);
			end
		end
	end
	
	if self.onValueChanged then
		self.onValueChanged();
	end
end

function addButton(sID, sIcon, sTooltip)
	local bToggle = false;
	if toggle then
		bToggle = true;
	end
	
	local button = window.createControl("toolbar_button", sID);
	if button then
		local x = nButtonHorzMargin + (nButtons * (nButtonSize + nButtonHorzMargin));
		nButtons = nButtons + 1;

		local nBarWidth = x + nButtonSize + nButtonHorzMargin;
		setAnchoredWidth(nBarWidth);
		setAnchoredHeight(nButtonSize + (2 * nButtonVertMargin));
		local w,h = getSize();

		button.setAnchor("left", getName(), "left", "absolute", x);
		button.setAnchor("top", getName(), "top", "absolute", nButtonVertMargin);
		button.setAnchoredWidth(nButtonSize);
		button.setAnchoredHeight(nButtonSize);

		button.configure(self, sID, sIcon, sTooltip, bToggle);
		
		aButtons[sID] = button;

		if isVisible() then
			button.setVisible(true);
		end
	end
end

function setActive(target)
	for id, button in pairs(aButtons) do
		if id == target then
			button.setValue(1);
		else
			button.setValue(0);
		end
	end
end

function highlightAll()
	for id, button in pairs(aButtons) do
		button.setValue(1);
	end
end

function setVisibility(bVisible)
	setVisible(bVisible);
	
	for id, button in pairs(aButtons) do
		button.setVisible(bVisible);
	end
end
