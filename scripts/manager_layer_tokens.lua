--  Please see the COPYRIGHT.txt file included with this distribution for attribution and copyright information.
--  Custom modifications Copyright Zeus from FG, unknown license.

-- Enhanced layer extension - layer token manager function.
-- toolkit to show token "shadows" on lower layers to aid in feature token placement and masking

function showLayerTokens(windowinstance, sourcelayer, targetlayer)
	local sourceLayerScale = 1;
	local targetLayerScale = 1;
	local targetViewpointZoom = 1;
	local sourceViewpointZoom = 1;
	-- Get all tokens on the source layer and the layer token scale
	local aSourceLayerTokens, tokenIdentifier;
	if sourcelayer == "play_image" then
		-- Get the play_image layer global token scale
		sourceLayerScale = windowinstance.play_image.getTokenScale();
		-- Get image zoom level
		_, _, sourceViewpointZoom = windowinstance.play_image.getViewpoint();
		aSourceLayerTokens = windowinstance.play_image.getTokens();
		-- xPL has a space after in order to have readable tooltip names.  this space will be removed by FG if there is no previous token name to leave "xPL"
		tokenIdentifier = "xPL ";
	elseif sourcelayer == "features_image" then
		-- Get the features_image layer global token scale
		sourceLayerScale = windowinstance.features_image.getTokenScale();
		-- Get image zoom level
		_, _, sourceViewpointZoom = windowinstance.features_image.getViewpoint();		
		aSourceLayerTokens = windowinstance.features_image.getTokens();
		-- xFL has a space after in order to have readable tooltip names.  this space will be removed by FG if there is no previous token name to leave "xFL"
		tokenIdentifier = "xFL ";
	else
		-- no valid source layer passed, exit function
		return 0;
	end		

	-- Get the token scale for the target layer
	if targetlayer == "image" then
		-- Get the image layer global token scale
		targetLayerScale = windowinstance.image.getTokenScale();
		-- Get image zoom level
		_, _, targetViewpointZoom = windowinstance.image.getViewpoint();
	elseif targetlayer == "features_image" then
		-- Get the features_image layer global token scale
		targetLayerScale = windowinstance.features_image.getTokenScale();
		-- Get image zoom level
		_, _, targetViewpointZoom = windowinstance.features_image.getViewpoint();		
	else
		-- no valid image layer passed, exit function
		return 0;
	end	
	
	if targetLayerScale == nil then 
		targetLayerScale = 1 * targetViewpointZoom;
	end
	if sourceLayerScale == nil then 
		sourceLayerScale = 1 * sourceViewpointZoom;
	end
	
	--Debug.console("Image zoom levels.  Source = " .. sourceViewpointZoom .. ", Target = " .. targetViewpointZoom);
	
	-- Set overall image scale factor - the factor needed to scale the local token shadow based off source and target image global token scale
	local imageScaleFactor = targetLayerScale / sourceLayerScale;
	
	--Debug.console("Source image token scale = " .. sourceLayerScale .. ", target image token scale = " .. targetLayerScale .. ", scale factor = " .. imageScaleFactor);
	
	for _,vToken in ipairs(aSourceLayerTokens) do
		local sourceLayerTokenPrototype = vToken.getPrototype();
		local tokenX, tokenY = vToken.getPosition();
		local tokenName = vToken.getName();
		local newImageLayerToken;
		local tokenScale = vToken.getScale();
		local tokenOrientation = vToken.getOrientation();

		-- Add token shadow to the specified layer
		if targetlayer == "image" then
			-- Get the image layer global token scale
			targetLayerScale = windowinstance.image.getTokenScale();		
			newImageLayerToken = windowinstance.image.addToken(sourceLayerTokenPrototype, tokenX, tokenY);
		elseif targetlayer == "features_image" then
			-- Get the image layer global token scale
			targetLayerScale = windowinstance.features_image.getTokenScale();		
			newImageLayerToken = windowinstance.features_image.addToken(sourceLayerTokenPrototype, tokenX, tokenY);
		else
			-- no valid image layer passed, exit function
			return 0;
		end		
		
		-- "xPL " added to token name to differentiate between eXtension added Player Player tokens and tokens already on the layer.  Needed for removing when the layer is left.
		newImageLayerToken.setName(tokenIdentifier .. tokenName);
		
		-- Set the token scale to be the same as the original token - allows large, huge, etc. creatures to be shown correctly.  Apply scaling factor for different in global layer token scale.
		newImageLayerToken.setScale(tokenScale * imageScaleFactor);
		
		-- Set the token orientation
		newImageLayerToken.setOrientation(tokenOrientation);
		
		-- Token not visible to client - and also shows the token slightly transparent to indicate that the token is not from the currently selected layer.
		newImageLayerToken.setVisible(false);
	end
end

function removeLayerTokens(windowinstance, layer)
	local aLayerTokens;
	if layer == "image" then
		aLayerTokens = windowinstance.image.getTokens();
	elseif layer == "features_image" then
		aLayerTokens = windowinstance.features_image.getTokens();
	else
		-- no valid image layer passed, exit function
		return 0;
	end

	-- Iterate through each token on the layer and delete those that start with "xPL" or "xFL" as these are play layer and feature layer token "shadows" respectively.
	for _,vToken in ipairs(aLayerTokens) do
		if string.sub(vToken.getName(), 1, 3) == "xPL" or string.sub(vToken.getName(), 1, 3) == "xFL"then
			vToken.delete();
		end
	end
end
