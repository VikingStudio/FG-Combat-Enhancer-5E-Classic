-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

local MIN_WIDTH = 200;
local MIN_HEIGHT = 200;
local SMALL_WIDTH = 500;
local SMALL_HEIGHT = 500;

local IMAGEDATA_WIDTH = 250;

function onInit()
	if getClass() == "imagepanelwindow" then
		registerMenuItem(Interface.getString("windowshare"), "windowshare", 7, 7);
	else
		registerMenuItem(Interface.getString("image_menu_size"), "imagesize", 3);
		local x, y = image.getImageSize()
		if (x > 500) or (y > 500) then
			registerMenuItem(Interface.getString("image_menu_sizesmall"), "imagesizesmall", 3, 1)
		end
		registerMenuItem(Interface.getString("image_menu_sizeoriginal"), "imagesizeoriginal", 3, 2);
		registerMenuItem(Interface.getString("image_menu_sizevertical"), "imagesizevertical", 3, 4);
		registerMenuItem(Interface.getString("image_menu_sizehorizontal"), "imagesizehorizontal", 3, 5);
	end
	
	saveImageAndImageDataPositions();

	onLockChanged();
	onNameUpdated();
	updateDisplay();

	if not User.isHost() then
		DB.addHandler(DB.getPath(getDatabaseNode(), "locked"), "onUpdate", onLockChanged);
	end
	
	ImageManager.registerImage(image);
end

function onClose()
	ImageManager.unregisterImage(image);

	if not User.isHost() then
		DB.removeHandler(DB.getPath(getDatabaseNode(), "locked"), "onUpdate", onLockChanged);
	end
end

function onLockChanged()
	onStateChanged();
	if DB.getValue(getDatabaseNode(), "locked", 0) == 0 then
		showImageData();
	else
		hideImageData();
	end
end

function onIDChanged()
	onStateChanged();
	onNameUpdated();
end

function onStateChanged()
	if header and header.subwindow then
		header.subwindow.update();
	end
	updateToolbarState();
end

function updateDisplay()
	if Interface.getVersion() >= 4 then return; end
	if not toolbar then return; end
	
	if toolbar.subwindow then
		toolbar.subwindow.update();
	end
end

function onCursorModeChanged()
	if Interface.getVersion() >= 4 then return; end
	if not toolbar then return; end

	if toolbar.subwindow then
		toolbar.subwindow.toolbar_draw.onValueChanged();
		toolbar.subwindow.toggle_targetselect.updateDisplay();
		toolbar.subwindow.toggle_select.updateDisplay();
	end
end

function onGridStateChanged()
	updateDisplay();
end

local bImagePositionsInitialized = false;
local nImageLeft, nImageTop, nImageRight, nImageBottom;
function saveImageAndImageDataPositions()
	if Interface.getVersion() < 4 then return; end
	nImageLeft, nImageTop, nImageRight, nImageBottom = image.getStaticBounds();
	nImageRight2 = nImageRight - IMAGEDATA_WIDTH;
	bImagePositionsInitialized = true;
end

function showImageData()
	if Interface.getVersion() < 4 then return; end
	if not bImagePositionsInitialized then return; end
	image.setStaticBounds(nImageLeft, nImageTop, nImageRight2, nImageBottom);
	imagedata.setVisible(true);
end

function hideImageData()
	if Interface.getVersion() < 4 then return; end
	if not bImagePositionsInitialized then return; end
	image.setStaticBounds(nImageLeft, nImageTop, nImageRight, nImageBottom);
	imagedata.setVisible(false);
end

function updateToolbarState()
	if Interface.getVersion() >= 4 then return; end
	if not toolbar then return; end
	
	local bShowToolbar = false;
	local nodeRecord = getDatabaseNode();
	if getClass() ~= "imagewindow" then
		bShowToolbar = true;
	elseif User.isHost() then
		bShowToolbar = not WindowManager.getReadOnlyState(nodeRecord);
	else
		local nDefault = 0;
		if nodeRecord and nodeRecord.getModule() then
			nDefault = 1;
		end
		bShowToolbar = (DB.getValue(nodeRecord, "locked", nDefault) == 0);
	end
	
	if bShowToolbar ~= toolbar.isVisible() then
		local nImageLeft, nImageTop, nImageRight, nImageBottom = image.getStaticBounds();
		if nImageLeft then
			local nWindowWidth,nWindowHeight = getSize();
			local _, nOriginalHeight = getWindowSizeAtOriginalImageSize();
			local nToolbarLeft, nToolbarTop, nToolbarRight, nToolbarHeight = toolbar.getStaticBounds();
			if bShowToolbar then
				nImageTop = nToolbarTop + nToolbarHeight;
			else
				nImageTop = nToolbarTop;
			end
			image.setStaticBounds(nImageLeft, nImageTop, nImageRight, nImageBottom);
			
			if nWindowHeight == nOriginalHeight then
				if bShowToolbar then
					setSize(nWindowWidth, nWindowHeight + nToolbarHeight);
				else
					setSize(nWindowWidth, nWindowHeight - nToolbarHeight);
				end
			end
		end
		toolbar.setVisible(bShowToolbar);
	end
end

function onNameUpdated()
	local nodeRecord = getDatabaseNode();
	local bID = LibraryData.getIDState("image", nodeRecord);
	
	local sTooltip = "";
	if bID then
		sTooltip = DB.getValue(nodeRecord, "name", "");
		if sTooltip == "" then
			sTooltip = Interface.getString("library_recordtype_empty_image")
		end
	else
		sTooltip = DB.getValue(nodeRecord, "nonid_name", "");
		if sTooltip == "" then
			sTooltip = Interface.getString("library_recordtype_empty_nonid_image")
		end
	end
	setTooltipText(sTooltip);
	if header and header.subwindow and header.subwindow.link then
		header.subwindow.link.setTooltipText(sTooltip);
	end
end

function onMenuSelection(item, subitem)
	if item == 3 then
		if subitem == 1 then
			local w,h = getWindowSizeAtSmallImageSize();
			setSize(w, h);
			image.setViewpoint(0,0,0);
		elseif subitem == 2 then
			local w,h = getWindowSizeAtOriginalImageSize();
			setSize(w, h);
			image.setViewpoint(0,0,1);
		elseif subitem == 4 then
			local w,h = getWindowSizeAtOriginalHeight();
			setSize(w, h);
			image.setViewpoint(0,0,0.1);
		elseif subitem == 5 then
			local w,h = getWindowSizeAtOriginalWidth();
			setSize(w, h);
			image.setViewpoint(0,0,0.1);
		end
	elseif item == 7 then
		if subitem == 7 then
			share();
		end
	end
end

function getWindowSizeAtSmallImageSize()
	local iw, ih = image.getImageSize();
	local cw, ch = image.getSize();
	local nMarginLeft, nMarginTop = image.getPosition();
	local ww, wh = getSize();
	local nMarginRight = ww - nMarginLeft - cw;
	local nMarginBottom = wh - nMarginTop - ch;

	local w = iw + nMarginLeft + nMarginRight;
	local h = ih + nMarginTop + nMarginBottom;
	if w > SMALL_WIDTH then
		w = SMALL_WIDTH;
	end
	if h > SMALL_HEIGHT then
		h = SMALL_HEIGHT;
	end
	
	return w,h;
end

function getWindowSizeAtOriginalImageSize()
	local iw, ih = image.getImageSize();
	local cw, ch = image.getSize();
	local nMarginLeft, nMarginTop = image.getPosition();
	local ww, wh = getSize();
	local nMarginRight = ww - nMarginLeft - cw;
	local nMarginBottom = wh - nMarginTop - ch;

	local w = iw + nMarginLeft + nMarginRight;
	local h = ih + nMarginTop + nMarginBottom;
	if w < MIN_WIDTH then
		local fScaleW = (MIN_WIDTH/w);
		w = w * fScaleW;
		h = h * fScaleW;
	end
	if h < MIN_HEIGHT then
		local fScaleH = (MIN_HEIGHT/h);
		w = w * fScaleH;
		h = h * fScaleH;
	end
	
	return w,h;
end

function getWindowSizeAtOriginalHeight()
	local iw, ih = image.getImageSize();
	local cw, ch = image.getSize();
	local nMarginLeft, nMarginTop = image.getPosition();
	local ww, wh = getSize();
	local nMarginRight = ww - nMarginLeft - cw;
	local nMarginBottom = wh - nMarginTop - ch;

	local w = cw + nMarginLeft + nMarginRight;
	local h = ((ih/iw)*cw) + nMarginTop + nMarginBottom;
	
	return w,h;
end

function getWindowSizeAtOriginalWidth()
	local iw, ih = image.getImageSize();
	local cw, ch = image.getSize();
	local nMarginLeft, nMarginTop = image.getPosition();
	local ww, wh = getSize();
	local nMarginRight = ww - nMarginLeft - cw;
	local nMarginBottom = wh - nMarginTop - ch;

	local w = ((iw/ih)*ch) + nMarginLeft + nMarginRight;
	local h = ch + nMarginTop + nMarginBottom;
	
	return w,h;
end
