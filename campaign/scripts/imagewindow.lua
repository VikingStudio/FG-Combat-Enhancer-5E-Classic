--  Please see the COPYRIGHT.txt file included with this distribution for attribution and copyright information.


local MIN_WIDTH = 200;
local MIN_HEIGHT = 200;
local SMALL_WIDTH = 500;
local SMALL_HEIGHT = 500;

local g_SyncSemaphore = true; 
local IMAGEDATA_WIDTH = 200;

function onInit()
	saveImageAndImageDataPositions();

	onLockChanged();
	onNameUpdated();

	updateDisplay();
	
	if not User.isHost() then
		DB.addHandler(DB.getPath(getDatabaseNode(), "locked"), "onUpdate", onLockChanged);
	end
	
	registerMenuItem(Interface.getString("image_menu_size"), "imagesize", 3);
	local x, y = image.getImageSize()
	if (x > 500) or (y > 500) then
		registerMenuItem(Interface.getString("image_menu_sizesmall"), "imagesizesmall", 3, 1)
	end
	registerMenuItem(Interface.getString("image_menu_sizeoriginal"), "imagesizeoriginal", 3, 2);
	registerMenuItem(Interface.getString("image_menu_sizevertical"), "imagesizevertical", 3, 4);
	registerMenuItem(Interface.getString("image_menu_sizehorizontal"), "imagesizehorizontal", 3, 5);
	
	-- set image scroll and zoom handlers
	image.onZoom = syncToImageViewpoint;
	image.onScroll = syncToImageViewpoint;
	features_image.onZoom = syncToFeaturesImageViewpoint;
	features_image.onScroll = syncToFeaturesImageViewpoint;
	play_image.onZoom = syncToPlayImageViewpoint;
	play_image.onScroll = syncToPlayImageViewpoint;	

	--imageLayerShortcuts = imageLayerDBNode.getChild("shortcuts");
	
	if User.isHost()  then
		-- make the toolbar visible 
		--toggle_toolbars.setVisible(true);
		
		--Enable/show the top play layer when the image is first opened.
		showLayer("play");

		--local x, y, zoom = play_image.getViewpoint();
		--Debug.console("imagewindow.lua: onInit.  play_image viewpoint before syncToImageDrawingSize = " .. x .. ", " .. y .. " x " .. zoom);		
		
		-- synchronise all layer to base image size
		syncToImageDrawingSize();
		
		-- determine if base image has a grid - copy it to the play image layer
		syncToImageGrid();
		
		--local iw, ih = image.getImageSize();
		--local fw, fh = features_image.getImageSize();
		--local pw, ph = play_image.getImageSize();
		--Debug.console("Image sizes.  Image = " .. iw .. ", " .. ih .. ".  Features = " .. fw .. ", " .. fh .. ". Play = " .. pw .. ", " .. ph);
		
		
		-- determine if base image has a mask, disable and enable mask on play image layer
		-- Note: Masking only works on the base layer as this is the only layer that is an actual image.  No need for the sync to image mask code.
		--syncToImageMask();
		
		-- Set the initial image viewpoint to be 0,0 and zoom of 1.  This resolves zoom level inconsistencies when first opening and zooming an image.
		-- After this FG will read any previously saved viewpoint from the campaign windowstate.xml file - so this is only relevant the first time an image is opened.

		-- set features and base image (middle and bottom layers) to identical viewpoint
		features_image.setViewpoint(0, 0, 1);
		image.setViewpoint(0, 0, 1);
		-- Synch to the grid for the originating viewpoint - this is needed to keep the zoom levels correct across all layers.
		play_image.setViewpoint(0, 0, 1);

	end	
	ImageManager.registerImage(features_image);
	ImageManager.registerImage(play_image);
	-- *** End Extension Code ***
	
	ImageManager.registerImage(image);
end

function onClose()
	--Debug.console("Running imagewindow.onClose");
	-- *** Extension Code ***
	ImageManager.unregisterImage(features_image);
	ImageManager.unregisterImage(play_image);
	-- *** End Extension Code ***
	
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
	if header.subwindow then
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
	if User.isHost() then
		--bShowToolbar = not WindowManager.getReadOnlyState(nodeRecord);
		bShowToolbar = true; 
	else
		local nDefault = 0;
		if nodeRecord and nodeRecord.getModule() then
			nDefault = 1;
		end
		--bShowToolbar = (DB.getValue(nodeRecord, "locked", nDefault) == 0);
		bShowToolbar = true; 
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
			
			-- Extension
			features_image.setStaticBounds(nImageLeft, nImageTop, nImageRight, nImageBottom);				
			play_image.setStaticBounds(nImageLeft, nImageTop, nImageRight, nImageBottom);
			-- ***				
			
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
	if header.subwindow and header.subwindow.link then
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

-- Extension

function showLayer(layername)
	if layername == "play" then
		-- Enable and set visible: play (top), Disable and set visible: features (middle) and image (bottom) image
		play_image.setEnabled(true);
		play_image.setVisible(true);
		features_image.setEnabled(false);
		features_image.setVisible(true);
		image.setEnabled(false);
		image.setVisible(true);
		
		-- Remove any token shadows set on the base layer
		--LayerTokenManager.removeLayerTokens(self, "image");	
		-- Remove any token shadows on the feature layer
		--LayerTokenManager.removeLayerTokens(self, "features_image");		
	elseif layername == "features" then
		-- Disable and set invisible: play (top) image, Enable and set visible: features (middle) image, Disable and set visible: image (bottom) image
		play_image.setEnabled(false);
		play_image.setVisible(true);
		features_image.setEnabled(true);
		features_image.setVisible(true);
		image.setEnabled(false);
		image.setVisible(true);
		
		-- Remove any token shadows set on the base layer
		--LayerTokenManager.removeLayerTokens(self, "image");
		-- Add token shadows for this layer
		--LayerTokenManager.showLayerTokens(self, "play_image", "features_image");
	else
		-- Disable and set invisible: play (top) and features (middle) images, Enable and set visible: image (bottom) image
		play_image.setEnabled(false);
		play_image.setVisible(true);
		features_image.setEnabled(false);
		features_image.setVisible(true);
		image.setEnabled(true);
		image.setVisible(true);
		
		-- Remove any token shadows on the feature layer
		--LayerTokenManager.removeLayerTokens(self, "features_image");		
		-- Show tokens from player layer - pass window instance (self) to toolkit function
		--LayerTokenManager.showLayerTokens(self, "play_image", "image");
		--LayerTokenManager.showLayerTokens(self, "features_image", "image");
	end
end

function layerEnabled()
	--Debug.console("imagewindow.lua: layerEnabled");
	if image.isEnabled() then
		return "image";
	elseif features_image.isEnabled() then
		return "features_image";
	elseif play_image.isEnabled() then
		return "play_image";
	else
		return "";
	end
end

function syncToImageGrid()
	-- Determine if base image has a grid
	 if image.hasGrid() then
		-- Copy base image (bottom layer) grid to features_image (middle layer) and play_image (top layer) 
		features_image.setGridType(image.getGridType());
		features_image.setGridSize(image.getGridSize());
		features_image.setGridOffset(image.getGridOffset());
		
		play_image.setGridType(image.getGridType());
		play_image.setGridSize(image.getGridSize());
		play_image.setGridOffset(image.getGridOffset());
		
		
		-- Disable base image (bottom layer) grid
		--image.setGridSize(0);
	end
end

function syncToPlayImageGrid(layercontrol)

	if User.isHost() then
		-- determine if this is a new grid being added on any layer
		if layercontrol then
			if layercontrol.hasGrid() and not play_image.hasGrid() then
				-- Copy the current image control (layercontrol) grid to all layers
				play_image.setGridType(layercontrol.getGridType());
				play_image.setGridSize(layercontrol.getGridSize());
				play_image.setGridOffset(layercontrol.getGridOffset());		
				
				features_image.setGridType(layercontrol.getGridType());
				features_image.setGridSize(layercontrol.getGridSize());
				features_image.setGridOffset(layercontrol.getGridOffset());
				
				image.setGridType(layercontrol.getGridType());
				image.setGridSize(layercontrol.getGridSize());
				image.setGridOffset(layercontrol.getGridOffset());	
				
				return;
			elseif layercontrol.hasGrid() then
				-- Copy play_image (top layer) grid to features_image (middle layer) and base layer (image) 

				features_image.setGridType(play_image.getGridType());
				features_image.setGridSize(play_image.getGridSize());
				features_image.setGridOffset(play_image.getGridOffset());
				
				image.setGridType(play_image.getGridType());
				image.setGridSize(play_image.getGridSize());
				image.setGridOffset(play_image.getGridOffset());
				return;
			end
		end

		 if play_image.hasGrid() then
			-- Copy play_image (top layer) grid to features_image (middle layer) and base layer (image) 
			features_image.setGridType(play_image.getGridType());
			features_image.setGridSize(play_image.getGridSize());
			features_image.setGridOffset(play_image.getGridOffset());
			
			image.setGridType(play_image.getGridType());
			image.setGridSize(play_image.getGridSize());
			image.setGridOffset(play_image.getGridOffset());
		else
			--play_image layer does not have grid - disable grid on all layers.
			removeGrid();
		end
	end
end

function removeGrid()
	--Debug.console("imagewindow.lua: removeGrid");
	-- Disable the grid on all layers
	if User.isHost() then
		play_image.setGridSize(0);
		features_image.setGridSize(0);
		image.setGridSize(0);
	end
end

function syncToImageMask()
	-- Determine if base image has a mask
	
	-- NOTE: Masking only works on the base layer.  Cannot mask a layer that is not composed of an image.
	
	 if image.hasMask() then
		-- print("Mask detected");
		-- Enable play image (top layer) mask
		play_image.setMaskEnabled(true);
		-- Disable base image (bottom layer) mask
		-- 
		-- image.setMaskEnabled(false);
	end
end

--[[
	Semaphore controls for g_SyncSemaphore
]]--
function acquireSyncLock()
	if g_SyncSemaphore then
		g_SyncSemaphore = false; 
		return true; 
	end
	return false; 
end

function releaseSyncLock()
	g_SyncSemaphore = true; 
end


function syncToImageViewpoint()
	--Debug.console("syncToImageViewpoint");
	if acquireSyncLock() then
		-- Determine base image viewpoint
		local x, y, zoom = image.getViewpoint();
		if x and y and zoom then
			--Debug.console('Zooming to image: ' .. x .. ':' .. y .. ':' .. zoom); 
			-- set play and feature images (top and middle layers) to identical viewpoint
			features_image.setViewpoint(x, y, zoom);
			play_image.setViewpoint(x, y, zoom);
			image.setViewpoint(x, y, zoom);
		end
		releaseSyncLock(); 
	end
end

function syncToFeaturesImageViewpoint()
	--Debug.console("syncToFeaturesImageViewpoint");
	if acquireSyncLock() then
		-- Determine features_image viewpoint
		local x, y, zoom = features_image.getViewpoint();
		if x and y and zoom then
			--Debug.console('Zooming to features: ' .. x .. ':' .. y .. ':' .. zoom); 
			-- set play and base image (top and bottom layers) to identical viewpoint
			image.setViewpoint(x, y, zoom);
			play_image.setViewpoint(x, y, zoom);
			features_image.setViewpoint(x, y, zoom);
		end
		releaseSyncLock(); 
	end
end

function syncToPlayImageViewpoint()
	--Debug.console("syncToPlayImageViewpoint");
	if acquireSyncLock() then
		-- Determine play_image viewpoint
		local x, y, zoom = play_image.getViewpoint();
		if x and y and zoom then
			--Debug.console('Zooming to play: ' .. x .. ':' .. y .. ':' .. zoom); 
			-- set features and base image (middle and bottom layers) to identical viewpoint
			features_image.setViewpoint(x, y, zoom);
			image.setViewpoint(x, y, zoom);
			play_image.setViewpoint(x, y, zoom);
		end
		releaseSyncLock(); 
	end 
end

function syncToImageDrawingSize()
	-- Determine base image size
	local w, h = image.getImageSize();
	--Debug.console("syncToImageDrawingSize - " .. w .. ", " .. h);
	if w and h then
		--Debug.console("Setting drawing size.");
		-- set play and feature images (top and middle layers) to identical size
		features_image.setDrawingSize(w, h, 0, 0);
		play_image.setDrawingSize(w, h, 0, 0);
	end
end

function onShare()
	--syncToImageViewpoint();
end

function notifyUpdate()
	syncToImageViewpoint();
	return true;
end


