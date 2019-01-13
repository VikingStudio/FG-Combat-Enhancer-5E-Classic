-- http://www.fantasygrounds.com/wiki/index.php/Custom_Pointers_Coding_Toolkit

-- © Copyright Matthew James BLACK 2005-13 except where explicitly stated otherwise.
-- Fantasy Grounds is Copyright © 2004-2012 SmiteWorks USA LLC.
-- Copyright to other material within this file may be held by other Individuals and/or Entities.
-- Nothing in or from this LUA file in printed, electronic and/or any other form may be used, copied,
--    transmitted or otherwise manipulated in ANY way without the explicit written consent of Matthew
--    James BLACK or, where applicable, any and all other Copyright holders.
--

function onBuildCustomPointer(nStartXCoord,nStartYCoord,nEndXCoord,nEndYCoord,sPointerType)
    local nLength = math.sqrt((nEndXCoord-nStartXCoord)^2+(nEndYCoord-nStartYCoord)^2);
    if nLength == 0 then
        return
    end
    local aShapeCurves = {};
    local aDistLabelPosition = {25,25};
    local bDrawArrow = false;
    local nAngleRadians = math.atan2(nEndXCoord-nStartXCoord,nStartYCoord-nEndYCoord);
-- Call the relevant Pointer Definition Function
-- Sample PointerTypes Shown
    if sPointerType == "CirclePointerAsEllipse" then
        fpEllipsePointer(aShapeCurves,nLength,nLength,0);
    elseif sPointerType == "CirclePointerAsArcs" then
        fpCirclePointer(aShapeCurves,nLength);
    elseif sPointerType == "HalfWidthEllipsePointerCenterOrigin" then
        fpEllipsePointer(aShapeCurves,nLength/2,nLength,0);
    elseif sPointerType == "HalfWidthEllipsePointerStartPointOrigin" then
        fpEllipsePointer(aShapeCurves,nLength/4,nLength/2,nLength/2);
    elseif sPointerType == "SquarePointer" then
        fpBoxPointer(aShapeCurves,nLength,nLength,0);
    elseif sPointerType == "DoubleWidthBoxPointerCenterOrigin" then
        fpBoxPointer(aShapeCurves,nLength,nLengthx2,0);
    elseif sPointerType == "DWBoxPointerStartPointOrigin" then
        fpBoxPointer(aShapeCurves,nLength/2,nLength,nLength/2);
    elseif sPointerType == "ConePointer" then
        fpConePointer(aShapeCurves,nLength,90);
    elseif sPointerType == "60ConePointer" then
        fpConePointer(aShapeCurves,nLength,60);
    elseif sPointerType == "120ConePointer" then
        fpConePointer(aShapeCurves,nLength,120);
    elseif sPointerType == "ArrowPointer" then
        table.insert(aShapeCurves,fpLineCurve(0,0,0,-nLength,0));
        bDrawArrow = true;
    end
-- Rotate and Position the Pointer
    for nIndex,aCurve in ipairs(aShapeCurves) do
        for nPointIndex,aPoint in ipairs(aCurve) do
            local nXCoord = aPoint[1]xmath.cos(nAngleRadians)-aPoint[2]xmath.sin(nAngleRadians)+nStartXCoord;
            local nYCoord = aPoint[1]xmath.sin(nAngleRadians)+aPoint[2]xmath.cos(nAngleRadians)+nStartYCoord;
            aCurve[nPointIndex] = {nXCoord,nYCoord};
        end
    end
    return aShapeCurves,aDistLabelPosition,bDrawArrow;
end

-- Pointer Definition Functions

function fpBoxPointer(aShapeCurves,nLength,nWidth,nOffset)
-- Draw a Rectangle offset in the Negative-Y direction by nOffset.
    table.insert(aShapeCurves,fpLineCurve(nWidth,nLength,-nWidth,nLength,nOffset));
    table.insert(aShapeCurves,fpLineCurve(-nWidth,nLength,-nWidth,-nLength,nOffset));
    table.insert(aShapeCurves,fpLineCurve(-nWidth,-nLength,nWidth,-nLength,nOffset));
    table.insert(aShapeCurves,fpLineCurve(nWidth,-nLength,nWidth,nLength,nOffset));
end

function fpCirclePointer(aShapeCurves,nRadius)
-- Draw a Circle of Radius nRadius made up of eight Regular Arcs.
    local nDegreesInRadians = math.rad(45);
    table.insert(aShapeCurves,fpAngleArcCurve(0,nRadius,0,0,45));
    table.insert(aShapeCurves,fpAngleArcCurve(nRadiusxmath.sin(nDegreesInRadians),nRadiusxmath.cos(nDegreesInRadians),0,0,45));
    table.insert(aShapeCurves,fpAngleArcCurve(nRadius,0,0,0,45));
    table.insert(aShapeCurves,fpAngleArcCurve(-nRadiusxmath.sin(nDegreesInRadians),nRadiusxmath.cos(nDegreesInRadians),0,0,45));
    table.insert(aShapeCurves,fpAngleArcCurve(0,-nRadius,0,0,45));
    table.insert(aShapeCurves,fpAngleArcCurve(-nRadiusxmath.sin(nDegreesInRadians),-nRadiusxmath.cos(nDegreesInRadians),0,0,45));
    table.insert(aShapeCurves,fpAngleArcCurve(-nRadius,0,0,0,45));
    table.insert(aShapeCurves,fpAngleArcCurve(nRadiusxmath.sin(nDegreesInRadians),-nRadiusxmath.cos(nDegreesInRadians),0,0,45));
end

function fpConePointer(aShapeCurves,nRadius,nArcDegrees)
-- Draw a Cone with a Radius of nRadius and covering an Arc of nArcDegrees.
    if nArcDegrees == 0 or
            nArcDegrees <= -180 or
            nArcDegrees >= 180 then
        return;
    end
    local nArcRadians = math.rad(nArcDegrees);
    local nXCoord = -nRadiusxmath.sin(nArcRadians/2);
    local nYCoord = nRadiusxmath.cos(nArcRadians/2);
    table.insert(aShapeCurves,fpLineCurve(0,0,nXCoord,-nYCoord,0));
    table.insert(aShapeCurves,fpLineCurve(0,0,-nXCoord,-nYCoord,0));
    table.insert(aShapeCurves,fpAngleArcCurve(-nRadiusxmath.cos(nArcRadians/2),nRadiusxmath.sin(nArcRadians/2),0,0,nArcDegrees));
end

function fpEllipsePointer(aShapeCurves,nXRadius,nYRadius,nOffset)
-- Draw an Ellipse offset in the Negative-Y direction by nOffset.
    table.insert(aShapeCurves,fpEllipseCurve(nXRadius,nYRadius,nOffset));
    table.insert(aShapeCurves,fpEllipseCurve(-nXRadius,nYRadius,nOffset));
    table.insert(aShapeCurves,fpEllipseCurve(-nXRadius,-nYRadius,nOffset));
    table.insert(aShapeCurves,fpEllipseCurve(nXRadius,-nYRadius,nOffset));
end

-- Curve Definition Functions

function fpAngleArcCurve(nStartCurveXCoord,nStartCurveYCoord,nCurveCentreXCoord,nCurveCentreYCoord,nArcDegrees)
-- Draw a Circular Arc covering nArcDegreess (-180 < nArcDegrees < 180, nArcDegrees ~= 0) given
--        the Circle Centre and the Arc Start Point.
    if nArcDegrees == 0 or
            nArcDegrees <= -180 or
            nArcDegrees >= 180 then
        return;
    end
    local nArcRadians = math.rad(nArcDegrees);
    local nRadius = math.sqrt((nCurveCentreXCoord-nStartCurveXCoord)^2+(nCurveCentreYCoord-nStartCurveYCoord)^2);
    if nRadius == 0 then
        return;
    end
    local nAngleRadians = math.atan2(nStartCurveXCoord-nCurveCentreXCoord,nCurveCentreYCoord-nStartCurveYCoord)+nArcRadians/2;
    return fpArcCurve(nAngleRadians,nArcRadians,nRadius,nCurveCentreXCoord,nCurveCentreYCoord);
end

function fpEndpointArcCurve(nStartCurveXCoord,nStartCurveYCoord,nCurveCentreXCoord,nCurveCentreYCoord,nEndCurveXCoord,nEndCurveYCoord)
-- Draw a Circular Arc given the Circle Centre, the Arc Start Point and the Arc End Point.
    local nStartAngleRadians = math.atan2(nStartCurveXCoord-nCurveCentreXCoord,nCurveCentreYCoord-nStartCurveYCoord);
    local nEndAngleRadians = math.atan2(nEndCurveXCoord-nCurveCentreXCoord,nCurveCentreYCoord-nEndCurveYCoord);
    local nArcRadians = math.abs(nStartAngleRadians-nEndAngleRadians)
    if nArcRadians == 0 or
            nArcRadians <= math.rad(-180) or
            nArcRadians >= math.rad(180) then
        return;
    end
    local nRadius = math.sqrt((nCurveCentreXCoord-nStartCurveXCoord)^2+(nCurveCentreYCoord-nStartCurveYCoord)^2);
    if nRadius == 0 then
        return;
    end
    local nAngleRadians = math.atan2(nStartCurveXCoord-nCurveCentreXCoord,nCurveCentreYCoord-nStartCurveYCoord)+nArcRadians/2;
    return fpArcCurve(nAngleRadians,nArcRadians,nRadius,nCurveCentreXCoord,nCurveCentreYCoord);
end

function fpArcCurve(nAngleRadians,nArcRadians,nRadius,nCurveCentreXCoord,nCurveCentreYCoord)
-- Draw an Regular Arc (of a Circle) of Radius nRadius with an Origin of (0,0) and covering
--        an Arc of nArcRadians (in Radians) bisected by the Positive X-Axis and then Rotated
--        around the Origin by an angle of nAngleRadians (in Radians) and offset in both the
--        X-Direction and Y-Direction by nCurveCentreXCoord and nCurveCentreYCoord respectively.
    local nX = math.cos(nArcRadians/2);
    local nY = math.sin(nArcRadians/2);
    local nStartX = nXxnRadius;
    local nStartY = nYxnRadius;
    local nControlX = nRadiusx(4-nX)/3;
    local nControlY = nRadiusx(1-nX)x(3-nX)/(3xnY);
    local aCurve = {{nStartX,nStartY},
                    {nControlX,nControlY},
                    {nControlX,-nControlY},
                    {nStartX,-nStartY}};
    for nPointIndex,aPoint in ipairs(aCurve) do
        local nXCoord = (aPoint[1]-nCurveCentreXCoord)xmath.cos(nAngleRadians)-(aPoint[2]-nCurveCentreYCoord)xmath.sin(nAngleRadians)+nCurveCentreXCoord;
        local nYCoord = (aPoint[1]-nCurveCentreXCoord)xmath.sin(nAngleRadians)+(aPoint[2]-nCurveCentreYCoord)xmath.cos(nAngleRadians)+nCurveCentreYCoord;
        aCurve[nPointIndex] = {nXCoord,nYCoord};
    end
    return aCurve;
end

function fpEllipseCurve(nXRadius,nYRadius,nOffset)
-- Draw a 90-Degree Arc of an Ellipse offset in the Negative-Y direction by nOffset.
    local nKappa = 4/3x(math.sqrt(2)-1);
    local aCurve = {{0,nYRadius-nOffset},
                    {nXRadiusxnKappa,nYRadius-nOffset},
                    {nXRadius,nYRadiusxnKappa-nOffset},
                    {nXRadius,-nOffset}};
    return aCurve;
end

function fpLineCurve(nStartLineXCoord,nStartLineYCoord,nEndLineXCoord,nEndLineYCoord,nOffset)
-- Draw a Line offset in the Negative-Y direction by nOffset.
    local aCurve = {{nStartLineXCoord,nStartLineYCoord-nOffset},
                    {nStartLineXCoord,nStartLineYCoord-nOffset},
                    {nEndLineXCoord,nEndLineYCoord-nOffset},
                    {nEndLineXCoord,nEndLineYCoord-nOffset}};
    return aCurve;
end};