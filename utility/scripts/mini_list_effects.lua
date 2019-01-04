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

local sFocus = "name";

function onInit()
	if newfocus then
		sFocus = newfocus[1];
	end
end

function onListChanged()
	update();
end

function update()
	local sEdit = getName() .. "_iedit";
	if window[sEdit] then
		local bEdit = (window[sEdit].getValue() == 1);
		for _,w in ipairs(getWindows()) do
			w.idelete.setVisibility(bEdit);
		end
	end
end

function onClickDown(button, x, y)
	if not isReadOnly() and getDatabaseNode().isOwner() then
		return true;
	end
end

function onClickRelease(button, x, y)
	if not isReadOnly() and getDatabaseNode().isOwner() then
		if getWindowCount() == 0 then
			addEntry(true);
		end
		return true;
	end
end

function addEntry(bFocus)
	local w = createWindow();
	if bFocus then
		w[sFocus].setFocus();
	end
	return w;
end

function onMenuSelection(selection)
	if selection == 5 then
		window.filter.setValue();
		addEntry();
	end
end

function onFilter(w)
	if window.filter then
		local sFilter = window.filter.getValue();
		local dbNode = w.getDatabaseNode(); 
		--Debug.console('minifilter: ' .. w.getClass() .. ' -- ' .. sFilter); 
		if sFilter ~= "" then
			if not w.label.getValue():upper():find(sFilter:upper(), 1, true) then
				return false;
			end
		end
		if not User.isHost() and DB.getValue(dbNode,'isgmonly',0) == 1 then
			return false;
		end
		return true;
	else
		--Debug.console('filter not ready!'); 
	end
end

