--  Please see the COPYRIGHT.txt file included with this distribution for attribution and copyright information.

function onValueChanged()
	local activelayer = window.parentcontrol.window.layerEnabled();
	
	local sTool = "";
	if activelayer == "play_image" then
		sTool = window.getImage().getCursorMode();
	elseif activelayer == "image" then
		sTool = window.parentcontrol.window.image.getCursorMode();
	end

	--valueToolEnable(activelayer)

	if sTool == "unmask" then
		setActive("unmask");
	elseif sTool == "draw" then
		setActive("paint");
	elseif sTool == "erase" then
		setActive("erase");
	else
		setActive("");
	end

	--[[
	if sTool == "unmask" and activelayer == "image" then
		setActive("unmask");
	elseif sTool == "draw" and activelayer == "play_image" then
		setActive("paint");
	elseif sTool == "erase" and activelayer == "play_image" then
		setActive("erase");
	else
		setActive("");
	end
	]]--
end

function valueToolEnable(activelayer)
	if activelayer == "play_image" then
		window.unmask.setStateIcons(0,"tool_mask_disabled_30"); 
		window.unmask.setStateIcons(1,"tool_mask_disabled_30"); 
		window.unmask.setStateColor(0,"dda0a0a0"); 
		window.paint.setStateIcons(0,"tool_paint_30"); 
		window.paint.setStateIcons(1,"tool_paint_30"); 
		window.paint.setStateColor(0,"60a0a0a0"); 
		window.erase.setStateIcons(0,"tool_erase_30"); 
		window.erase.setStateIcons(1,"tool_erase_30"); 
		window.erase.setStateColor(0,"60a0a0a0"); 
	elseif activelayer == "features_image" then
		window.unmask.setStateIcons(0,"tool_mask_disabled_30"); 
		window.unmask.setStateIcons(1,"tool_mask_disabled_30"); 
		window.unmask.setStateColor(0,"dda0a0a0"); 
		window.paint.setStateIcons(0,"tool_paint_disabled_30"); 
		window.paint.setStateIcons(1,"tool_paint_disabled_30"); 
		window.paint.setStateColor(0,"dda0a0a0"); 
		window.erase.setStateIcons(0,"tool_erase_disabled_30"); 
		window.erase.setStateIcons(1,"tool_erase_disabled_30"); 
		window.erase.setStateColor(0,"dda0a0a0"); 
	elseif activelayer == "image" then
		window.unmask.setStateIcons(0,"tool_mask_30"); 
		window.unmask.setStateIcons(1,"tool_mask_30"); 
		window.unmask.setStateColor(0,"60a0a0a0"); 
		window.paint.setStateIcons(0,"tool_paint_disabled_30"); 
		window.paint.setStateIcons(1,"tool_paint_disabled_30"); 
		window.paint.setStateColor(0,"dda0a0a0"); 
		window.erase.setStateIcons(0,"tool_erase_disabled_30"); 
		window.erase.setStateIcons(1,"tool_erase_disabled_30"); 
		window.erase.setStateColor(0,"dda0a0a0"); 
	end
end

function onButtonPress(id)
	local activelayer = window.parentcontrol.window.layerEnabled();
	
	local image = "";
--[[
	if activelayer == "play_image" then
		image = window.getImage();
	elseif activelayer == "image" then
		image = window.parentcontrol.window.image;
	end
--]]
	
	if id == "paint" then
		-- push to play image
		window.parentcontrol.window.showLayer('play'); 
		window.toolbar_layers.setActive('layer_play'); 
		image = window.getImage();
		if image.getCursorMode() ~= "draw" then
			image.setCursorMode("draw");
		else
			image.setCursorMode("");
		end
	elseif id == "erase" then
		-- push to play image
		window.parentcontrol.window.showLayer('play'); 
		window.toolbar_layers.setActive('layer_play'); 
		image = window.getImage();
		if image.getCursorMode() ~= "erase" then
			image.setCursorMode("erase");
		else
			image.setCursorMode("");
		end
	elseif id == "unmask" then
		Debug.chat('toolbar_draw > unmask pressed, active layer', activelayer);
		if activelayer == 'image' then
			-- push to play image (toggle)
			window.parentcontrol.window.showLayer('play'); 
			window.toolbar_layers.setActive('layer_play'); 
			image = window.getImage();
			if image.getCursorMode() == "unmask" then
				image.setCursorMode("");
			end
		else
			-- switch to image layer if not already selected upon unmask button press
			-- push to background
			window.parentcontrol.window.showLayer('image'); 
			window.toolbar_layers.setActive('layer_background'); 
			image = window.parentcontrol.window.image;
			if image.getCursorMode() ~= "unmask" then
				image.setMaskEnabled(true);
				image.setCursorMode("unmask");
			end
		end
	end
	onValueChanged();
end

