--  Please see the COPYRIGHT.txt file included with this distribution for attribution and copyright information.

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

