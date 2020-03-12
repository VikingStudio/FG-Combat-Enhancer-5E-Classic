--  Please see the COPYRIGHT.txt file included with this distribution for attribution and copyright information.

-- Stores the token instances from the player layer when a lower layer is being viewed.
-- Used to track onMove events to reposition lower layer token "shadows"
local tokensPlayerLayer = nil;

function onInit()
	super.onInit()
	
	if not User.isHost() then
		DB.addHandler(DB.getPath(getDatabaseNode(), "locked"), "onUpdate", onLockChanged);
	end	

	onStateChanged()

	registerMenuItem(Interface.getString("resize_to_grid"), "pointer_square", 3, 8)

	-- set image scroll and zoom handlers
	image.onZoom = syncToImageViewpoint
	image.onScroll = syncToImageViewpoint
	features_image.onZoom = syncToFeaturesImageViewpoint
	features_image.onScroll = syncToFeaturesImageViewpoint
	play_image.onZoom = syncToPlayImageViewpoint
	play_image.onScroll = syncToPlayImageViewpoint

	--imageLayerShortcuts = imageLayerDBNode.getChild("shortcuts")

	if User.isHost()  then
		-- make the toolbar visible 
		--toggle_toolbars.setVisible(true)

		-- Enable/show the top play layer when the image is first opened.
		-- If the image is read only, enable the bottom image layer.
		local nodeReadOnly = getDatabaseNode().isReadOnly();
		if nodeReadOnly then
			Debug.console("Image node is read only - enabling image layer");
			--Input.onControl = onControl;
			showLayer("image")
		else
			showLayer("play")
		end
		

		--local x, y, zoom = play_image.getViewpoint()
		--Debug.console("imagewindow.lua: onInit.  play_image viewpoint before syncToImageDrawingSize = " .. x .. ", " .. y .. " x " .. zoom)

		-- synchronise all layer to base image size
		syncToImageDrawingSize()

		-- determine if base image has a grid - copy it to the play image layer
		syncToImageGrid()

		--local iw, ih = image.getImageSize()
		--local fw, fh = features_image.getImageSize()
		--local pw, ph = play_image.getImageSize()
		--Debug.console("Image sizes.  Image = " .. iw .. ", " .. ih .. ".  Features = " .. fw .. ", " .. fh .. ". Play = " .. pw .. ", " .. ph)


		-- determine if base image has a mask, disable and enable mask on play image layer
		-- Note: Masking only works on the base layer as this is the only layer that is an actual image.  No need for the sync to image mask code.
		--syncToImageMask()

		-- Set the initial image viewpoint to be 0,0 and zoom of 1.  This resolves zoom level inconsistencies when first opening and zooming an image.
		-- After this FG will read any previously saved viewpoint from the campaign windowstate.xml file - so this is only relevant the first time an image is opened.
		if not synclocked then
			synclocked = true
			-- set features and base image (middle and bottom layers) to identical viewpoint
			features_image.setViewpoint(0, 0, 1)
			image.setViewpoint(0, 0, 1)
			-- Synch to the grid for the originating viewpoint - this is needed to keep the zoom levels correct across all layers.
			play_image.setViewpoint(0, 0, 1)
			synclocked = false
		end

	end
	ImageManager.registerImage(features_image)
	ImageManager.registerImage(play_image)
end


function setTokensPlayerLayerMoveHandler()
	tokensPlayerLayer = self.play_image.getTokens();
	if tokensPlayerLayer then
		for k,v in pairs(tokensPlayerLayer) do
			-- Only track moves for named tokens (more than likely tokens from combat tracker records).
			if v.getName() ~= "" then
				v.onMove = playLayerTokenMoved;
			end
		end
	end
end


function playLayerTokenMoved(movedTokenInstance)
	if movedTokenInstance and movedTokenInstance.getName() ~= "" then
		local posX, posY = movedTokenInstance.getPosition();
		local playLayerTokenName = "xPL " .. movedTokenInstance.getName();
		local imageLayercontrol = self.image;
		if layerEnabled() == "features_image" then
			imageLayercontrol = self.features_image;
		end
		-- find token on lower layer
		for k, v in pairs(imageLayercontrol.getTokens()) do
			Debug.console("playLayerTokenMoved.  playLayerTokenName, imageLayerTokenName = ", playLayerTokenName, v.getName());
			if v.getName() == playLayerTokenName then
				v.setPosition(posX, posY);
				break;
			end
		end
		
	end
end


function onClose()
	ImageManager.unregisterImage(features_image)
	ImageManager.unregisterImage(play_image)
	
	if not User.isHost() then
		DB.removeHandler(DB.getPath(getDatabaseNode(), "locked"), "onUpdate", onLockChanged);
	end	

	super.onClose()
end

function onToolbarChanged()
	if super and super.onToolbarChanged then
		super.onToolbarChanged()
	end
	syncLayerSizeToBaseImage();
end

function onLockChanged()
	onStateChanged();
end


function syncLayerSizeToBaseImage()
	Debug.console("syncLayerSizeToBaseImage...");
	
	-- sync play and features images to base image size which is set in super.onStageChanged
	local nImageLeft, nImageTop, nImageRight, nImageBottom = image.getStaticBounds()
	--Debug.console("Image bounds are: " .. nImageLeft, nImageTop, nImageRight, nImageBottom);
	if nImageLeft then
		features_image.setStaticBounds(nImageLeft, nImageTop, nImageRight, nImageBottom)
		play_image.setStaticBounds(nImageLeft, nImageTop, nImageRight, nImageBottom)
	end	
end

function onStateChanged()
	if super and super.onStateChanged then
		super.onStateChanged()
	end	
	
	syncLayerSizeToBaseImage();

--	if toolbar then
--		local bShowToolbar = false
--		local nodeRecord = getDatabaseNode()
--		if User.isHost() then
--			bShowToolbar = not WindowManager.getReadOnlyState(nodeRecord)
--		else
--			local nDefault = 0
--			if nodeRecord and nodeRecord.getModule() then
--				nDefault = 1
--			end
--			bShowToolbar = (DB.getValue(nodeRecord, "locked", nDefault) == 0)
--		end
--		if bShowToolbar ~= toolbar.isVisible() then
--			local nImageLeft, nImageTop, nImageRight, nImageBottom = image.getStaticBounds()
--			if nImageLeft then
--				features_image.setStaticBounds(nImageLeft, nImageTop, nImageRight, nImageBottom)
--				play_image.setStaticBounds(nImageLeft, nImageTop, nImageRight, nImageBottom)
--			end
--		end
--	end
end

function onMenuSelection(item, subitem)
	if item == 3 and subitem == 8 then
		playerWindowOpened()
		return true
	end

	super.onMenuSelection(item, subitem)
end

--
-- Enhanced images extension
--

function showLayer(layername)
	if layername == "play" then
		-- Enable and set visible: play (top), Disable and set visible: features (middle) and image (bottom) image
		play_image.setEnabled(true)
		play_image.setVisible(true)
		features_image.setEnabled(false)
		features_image.setVisible(true)
		image.setEnabled(false)
		image.setVisible(true)

		-- Remove any token shadows set on the base layer
		LayerTokenManager.removeLayerTokens(self, "image")
		-- Remove any token shadows on the feature layer
		LayerTokenManager.removeLayerTokens(self, "features_image")
		-- Clear token instances for play layer as we're back on that layer
		tokensPlayerLayer = nil;		
	elseif layername == "features" then
		-- Disable and set invisible: play (top) image, Enable and set visible: features (middle) image, Disable and set visible: image (bottom) image
		play_image.setEnabled(false)
		play_image.setVisible(false)
		features_image.setEnabled(true)
		features_image.setVisible(true)
		image.setEnabled(false)
		image.setVisible(true)

		-- Remove any token shadows set on the base layer
		LayerTokenManager.removeLayerTokens(self, "image")
		-- Add token shadows for this layer
		setTokensPlayerLayerMoveHandler();
		LayerTokenManager.showLayerTokens(self, "play_image", "features_image")
	else
		-- Disable and set invisible: play (top) and features (middle) images, Enable and set visible: image (bottom) image
		play_image.setEnabled(false)
		play_image.setVisible(false)
		features_image.setEnabled(false)
		features_image.setVisible(false)
		image.setEnabled(true)
		image.setVisible(true)

		-- Remove any token shadows on the feature layer
		LayerTokenManager.removeLayerTokens(self, "features_image")
		-- Show tokens from player layer - pass window instance (self) to toolkit function
		setTokensPlayerLayerMoveHandler();
		LayerTokenManager.showLayerTokens(self, "play_image", "image")
		LayerTokenManager.showLayerTokens(self, "features_image", "image")
	end
end

function layerEnabled()
	--Debug.console("imagewindow.lua: layerEnabled")
	if image.isEnabled() then
		return "image"
	elseif features_image.isEnabled() then
		return "features_image"
	elseif play_image.isEnabled() then
		return "play_image"
	else
		return ""
	end
end

function syncToImageGrid()
	-- Determine if base image has a grid
	 if image.hasGrid() then
		-- Copy base image (bottom layer) grid to features_image (middle layer) and play_image (top layer) 
		features_image.setGridType(image.getGridType())
		features_image.setGridSize(image.getGridSize())
		features_image.setGridOffset(image.getGridOffset())

		play_image.setGridType(image.getGridType())
		play_image.setGridSize(image.getGridSize())
		play_image.setGridOffset(image.getGridOffset())


		-- Disable base image (bottom layer) grid
		--image.setGridSize(0)
	end
end

function syncToPlayImageGrid(layercontrol)

	if User.isHost() then
		-- determine if this is a new grid being added on any layer
		if layercontrol then
			if layercontrol.hasGrid() and not play_image.hasGrid() then
				-- Copy the current image control (layercontrol) grid to all layers
				play_image.setGridType(layercontrol.getGridType())
				play_image.setGridSize(layercontrol.getGridSize())
				play_image.setGridOffset(layercontrol.getGridOffset())

				features_image.setGridType(layercontrol.getGridType())
				features_image.setGridSize(layercontrol.getGridSize())
				features_image.setGridOffset(layercontrol.getGridOffset())

				image.setGridType(layercontrol.getGridType())
				image.setGridSize(layercontrol.getGridSize())
				image.setGridOffset(layercontrol.getGridOffset())

				return
			elseif layercontrol.hasGrid() then
				-- Copy play_image (top layer) grid to features_image (middle layer) and base layer (image) 

				features_image.setGridType(play_image.getGridType())
				features_image.setGridSize(play_image.getGridSize())
				features_image.setGridOffset(play_image.getGridOffset())

				image.setGridType(play_image.getGridType())
				image.setGridSize(play_image.getGridSize())
				image.setGridOffset(play_image.getGridOffset())
				return
			end
		end

		 if play_image.hasGrid() then
			-- Copy play_image (top layer) grid to features_image (middle layer) and base layer (image) 
			features_image.setGridType(play_image.getGridType())
			features_image.setGridSize(play_image.getGridSize())
			features_image.setGridOffset(play_image.getGridOffset())

			image.setGridType(play_image.getGridType())
			image.setGridSize(play_image.getGridSize())
			image.setGridOffset(play_image.getGridOffset())
		else
			--play_image layer does not have grid - disable grid on all layers.
			removeGrid()
		end
	end
end

function removeGrid()
	--Debug.console("imagewindow.lua: removeGrid")
	-- Disable the grid on all layers
	if User.isHost() then
		play_image.setGridSize(0)
		features_image.setGridSize(0)
		image.setGridSize(0)
	end
end

function syncToImageMask()
	-- Determine if base image has a mask

	-- NOTE: Masking only works on the base layer.  Cannot mask a layer that is not composed of an image.

	 if image.hasMask() then
		-- print("Mask detected")
		-- Enable play image (top layer) mask
		play_image.setMaskEnabled(true)
		-- Disable base image (bottom layer) mask
		-- 
		-- image.setMaskEnabled(false)
	end
end

function syncToImageViewpoint()
	--Debug.console("syncToImageViewpoint")
	if not synclocked then
		synclocked = true
		-- Determine base image viewpoint
		local x, y, zoom = image.getViewpoint()
		if x and y and zoom then
			-- set play and feature images (top and middle layers) to identical viewpoint
			features_image.setViewpoint(x, y, zoom)
			play_image.setViewpoint(x, y, zoom)
			-- Synch to the grid for the originating viewpoint - this is needed to keep the zoom levels correct across all layers.
			image.setViewpoint(x, y, zoom)
		end
		synclocked = false
	end
end

function syncToFeaturesImageViewpoint()
	--Debug.console("syncToFeaturesImageViewpoint")
	if not synclocked then
		synclocked = true
		-- Determine features_image viewpoint
		local x, y, zoom = features_image.getViewpoint()
		if x and y and zoom then
			-- set play and base image (top and bottom layers) to identical viewpoint
			image.setViewpoint(x, y, zoom)
			play_image.setViewpoint(x, y, zoom)
			-- Synch to the grid for the originating viewpoint - this is needed to keep the zoom levels correct across all layers.
			features_image.setViewpoint(x, y, zoom)
		end
		synclocked = false
	end
end

function syncToPlayImageViewpoint()
	--Debug.console("syncToPlayImageViewpoint")
	if not synclocked then
		synclocked = true
		-- Determine play_image viewpoint
		local x, y, zoom = play_image.getViewpoint()
		if x and y and zoom then
			-- set features and base image (middle and bottom layers) to identical viewpoint
			features_image.setViewpoint(x, y, zoom)
			image.setViewpoint(x, y, zoom)
			-- Synch to the grid for the originating viewpoint - this is needed to keep the zoom levels correct across all layers.
			play_image.setViewpoint(x, y, zoom)
		end
		synclocked = false
	end 
end

function syncToImageDrawingSize()
	-- Determine base image size
	local w, h = image.getImageSize()
	--Debug.console("syncToImageDrawingSize - " .. w .. ", " .. h)
	if w and h then
		--Debug.console("Setting drawing size.")
		-- set play and feature images (top and middle layers) to identical size
		features_image.setDrawingSize(w, h, 0, 0)
		play_image.setDrawingSize(w, h, 0, 0)
	end
end

function onShare()
	--syncToImageViewpoint()
end

function notifyUpdate()
	syncToImageViewpoint()
	return true
end

-- Player Image Auto Size Extension code

function playerWindowOpened()
	--Debug.console("imagewindow.lua:playerWindowOpened.")

	local cw, ch = image.getSize()
	--Debug.console("image.getSize = " .. cw .. ", " .. ch)
	local nMarginLeft, nMarginTop = image.getPosition()
	--Debug.console("image.getPosition = " .. nMarginLeft .. ", " .. nMarginTop)

	local ww, wh = getSize()
	--Debug.console("window.getSize = " .. ww .. ", " .. wh)

	local nMarginRight = ww - nMarginLeft - cw
	local nMarginBottom = wh - nMarginTop - ch
	--Debug.console("nMarginRight = " .. nMarginRight .. ", nMarginBottom = " .. nMarginBottom)

	local iX, iY = image.getImageSize()
	--Debug.console("image.getImageSize = " .. iX .. ", " .. iY)

	local imageGridSize = image.getGridSize()
	if imageGridSize == 0 then
		return
	end
	local XInches = iX / imageGridSize
	local YInches = iY / imageGridSize
	Debug.console("Image grid = " .. imageGridSize .. "pixels.  Dimension in inches = " ..  XInches .. ", " .. YInches)

	-- Get TV size from DB
	local setTVSize = 0
	local tvSizeDBNode = DB.findNode("extension_data.tvsize")
	if tvSizeDBNode then
		setTVSize = tvSizeDBNode.getValue()
	else
		local msg = {}
		msg.font = "systemfont"
		msg.text = "Cannot find TV size set in database.  Please set TV size through the chat window using: /tvsize [TV size in inches] [TV height (Y) resolution in pixels]"
		Comm.addChatMessage(msg)
		return
	end

	-- Get TV size from DB
	local tvResolution = 0
	local tvResolutionDBNode = DB.findNode("extension_data.tvresolution")
	if tvResolutionDBNode then
		tvResolution = tvResolutionDBNode.getValue()
	else
		local msg = {}
		msg.font = "systemfont"
		msg.text = "Cannot find TV resolution set in database.  Please set TV size through the chat window using: /tvsize [TV size in inches] [TV height (Y) resolution in pixels]"
		Comm.addChatMessage(msg)
		return
	end

	-- Calculate the TV width and height - based off a 16:9 format TV.
	local tvWidth = setTVSize * 0.87157552765421
	local tvHeight = setTVSize * 0.490261259680549

	local tvPixelsPerInch = tvResolution / tvHeight
	--Debug.console("TV dimensions in inches for " .. setTVSize .. " inches = " .. tvWidth .. ", " .. tvHeight .. ". At " .. tvPixelsPerInch .. " Pixels per inch.")

	-- Setting total window size based off image control bounds of 21,58,-27,-29
	--local wX = iX + 48
	--local wY = iY + 87

	-- Window reported size
	local wrX, wrY = getSize()
	--Debug.console("imagewindow.lua: Window reported size = " .. wrX .. ", " .. wrY .. ".  Calculated from image = " .. wX .. ", " .. wY .. ".")

	-- Calculate scale factor - only need to do this in one dimension.  We'll use Y (height) si we can set the TV resolution using standard 1080, 720, etc. notation.
	local scaleFactor = tvPixelsPerInch / imageGridSize

--	local newWX = math.floor(wX * scaleFactor)
--	local newWY = math.floor(wY * scaleFactor)

	-- Calculate new window size - based off scaled image and margins between the image control and the edge of the window - these can be dynamic (toolbar shown/hidden, for example).
	local newWX = math.floor(iX * scaleFactor + nMarginLeft + nMarginRight)
	local newWY = math.floor(iY * scaleFactor + nMarginTop + nMarginBottom)

	-- Set the image size - need to do this before setting the scale factor.  What if image size is larger than before?
	--Debug.console("Setting new size = " .. newWX .. ", " .. newWY)
	setSize(newWX, newWY)

	-- Set the image zoom factor
	--Debug.console("Setting new scale = " .. scaleFactor)
	image.setViewpoint(1, 1, scaleFactor)

	--Debug.console("Setting new size = " .. newWX .. ", " .. newWY)
	--setSize(newWX, newWY)

	-- Set the newly resized window position to be top left of the desktop
	setPosition(1, 1)

end

function onMove()
	playerWindowOpened()
end





