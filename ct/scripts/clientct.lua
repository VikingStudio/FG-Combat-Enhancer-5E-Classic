-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	Interface.onHotkeyActivated = onHotkey;
	
	OptionsManager.registerCallback("WNDC", onOptionWNDCChanged);
	OptionsManager.registerCallback("CTSI", onOptionCTSIChanged);
end

function onClose()
	OptionsManager.unregisterCallback("WNDC", onOptionWNDCChanged);
	OptionsManager.unregisterCallback("CTSI", onOptionCTSIChanged);
end

function onOptionWNDCChanged()
	for _,v in pairs(getWindows()) do
		v.onHealthChanged();
	end
end

function onOptionCTSIChanged()
	for _,v in pairs(getWindows()) do
		v.updateDisplay();
	end
	applySort();
end

function onSortCompare(w1, w2)
	return CombatManager.onSortCompare(w1.getDatabaseNode(), w2.getDatabaseNode());
end

function onHotkey(draginfo)
	local sDragType = draginfo.getType();
	if sDragType == "combattrackernextactor" then
		CombatManager.notifyEndTurn();
		return true;
	end
end

function onFilter(w)
	if w.friendfoe.getStringValue() == "friend" then
		return true;
	end
	if w.tokenvis.getValue() ~= 0 then
		return true;
	end
	return false;
end

function onDrop(x, y, draginfo)
	local w = getWindowAt(x,y);
	if w then
		local nodeWin = w.getDatabaseNode();
		if nodeWin then
			return CombatManager.onDrop("ct", nodeWin.getNodeName(), draginfo);
		end
	end
end

function onClickRelease(button, x, y)
	if Input.isControlPressed() then
		local w = getWindowAt(x, y);
		if w then
			TargetingManager.toggleClientCTTarget(w.getDatabaseNode());
		end

		return true;
	end
end
