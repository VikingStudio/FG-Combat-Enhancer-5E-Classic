-- 
-- Please see the license.html file included with this distribution for 
-- attribution and copyright information.
--

function onInit()
	super.onInit()

	-- Set onZoom handler to do nothing
	self.onZoom = function() end
end

function onGridStateChanged(gridtype)
	if self.hasGrid() then
		window.syncToPlayImageGrid(self)
	else
		-- The grid has been turned off on this layer - turn it off across all layers
		window.removeGrid()
	end

	super.onGridStateChanged(gridtype)
end

function onTargetSelect(aTargets)
	-- Added to disable GM targeting on base and features layer
	if self.getName() ~= "play_image" then
		return true
	end

	super.onTargetSelect(aTargets)
end

--
-- Enhanced images extension
--

-- used to synch layers when "dragging" with the middle button - i.e. panning the image.
local last = {};

function getLastCoords()
	if last.x and last.y then
		return last.x, last.y;
	else
		return 0, 0;
	end
end

function updateLastCoords(x, y) 
	last.x = x;
	last.y = y;
end

function onClickDown(button, x, y)
    -- Determine if middle mouse button is clicked
	if button==2 then
	    -- update last x, y position with current coordinates
		last.x = x;
		last.y = y;
	end
end

function onClickRelease(button, x, y)
	--return false;
end

function onDragStart(button, x, y, dragdata)
	return onDrag(button, x, y, dragdata);
end

function onDrag(button, x, y, draginfo)
	-- Determine if middle mouse button is clicked
	if button == 2 then
		-- Determine drag distance since initial click
		local dx = x - (last.x or 0);
		local dy = y - (last.y or 0);
		-- Determine image viewpoint
		local nx, ny, zoom = getViewpoint();
		 -- update last x, y position with current coordinates
		updateLastCoords(x,y);

		if User.isHost() then
			-- set the new viewpoint based upon current viewpoint + drag distance
			window.image.setViewpoint(nx+dx, ny+dy, zoom);
			-- sync viewpoints for all layers
			window.syncToImageViewpoint();
		else
			-- set the new viewpoint based upon current viewpoint + drag distance
			window.play_image.setViewpoint(nx+dx, ny+dy, zoom);
			-- sync viewpoints for all layers
			window.syncToPlayImageViewpoint();
		end
		return true;
	end
end

