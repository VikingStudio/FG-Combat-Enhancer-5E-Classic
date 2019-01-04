--[[
	'Fantasy Grounds' is a trademark of SmiteWorks USA, LLC. 'Fantasy Grounds' is Copyright 2004-2014 SmiteWorks USA LLC.
	The CoreRPG ruleset and all included files are copyright 2004-2013, Smiteworks USA LLC.
]]--

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

-- RECORD TYPE FORMAT
-- 		["recordtype"] = { 
--			bExport = <bool>,
-- 			bHidden = <bool>,
-- 			bID = <bool>,
--			bNoCategories = <bool>,
--			bAllowClientEdit = <bool>,
-- 			aDataMap = <table of strings>, 
-- 			aDisplayIcon = <table of 2 strings>, 
--			fToggleIndex = <function>
-- 			sListDisplayClass = <string>,
-- 			sRecordDisplayClass = <string>,
--			aRecordDisplayCLasses = <table of strings>,
--			fRecordDisplayClass = <function>,
--			aGMListButtons = <table of templates>,
-- 		},
--
-- FIELDS ADDED FROM STRING DATA
-- 		sDisplayText = Interface.getString(library_recordtype_label_ .. sRecordType)
-- 		sEmptyNameText = Interface.getString(library_recordtype_empty_ .. sRecordType)
--
-- 		*FIELDS ADDED FROM STRING DATA (only when bID set)*
-- 		sEmptyUnidentifiedNameText = Interface.getString(library_recordtype_empty_nonid_ .. sRecordType)
--
-- RECORD TYPE LEGEND
--		bExport = Optional. Same as nExport = 1. Boolean indicating whether record should be exportable in the library export window for the record type.
--		nExport = Optional. Overriden by bExport. Number indicating number of data paths which are exportable in the library export window for the record type.
--			NOTE: See aDataMap for bExport/nExport are handled for target campaign data paths vs. reference data paths (editable vs. read-only)
--		bExportNoReadOnly = Optional. Similar to bExport. Boolean indicating whether record should be exportable in the library export window for the record type, but read only option in export is ignored.
--		sExportListDisplayClass = Optional. When exporting records, the list link created for records to be accessed from the library will use this display class. (Default is reference_list)
--		bExportListSkip = Optional. When exporting records, a list link is normally created for the records to be accessed from the library. This option skips creation of the list and link.
--		bHidden = Optional. Boolean indicating whether record should be displayed in library, and when show aLl records in sidebar selected.
-- 		bID = Optional. Boolean indicating whether record is identifiable or not (currently only items and images)
--		bNoCateories = Optional. Disable display and usage of category information.
--		bAllowClientEdit = Optional. Allow clients to add/delete records in the list that they own.
--		aDataMap = Required. Table of strings. defining the valid data paths for records of this type
--			NOTE: For bExport/nExport, that number of data paths from the beginning of the data map list will be used as the source for exporting 
--				and the target data paths will be the same in the module. (i.e. default campaign data paths, editable).
--				The next nExport data paths in the data map list will be used as the export target data paths for read-only data paths for the 
--				matching source data path.
--			EX: { "item", "armor", "weapon", "reference.items", "reference.armors", "reference.weapons" } with a nExport of 3 would mean that
--				the "item", "armor" and "weapon" data paths would be exported to the matching "item", "armor" and "weapon" data paths in the module by default.
--				If the reference data path option is selected, then "item", "armor" and "weapon" data paths would be exported to 
--				"reference.items", "reference.armors", and "reference.weapons", respectively.
--		aDisplayIcon = Required. Table of strings. Provides icon resource names for sidebar/library buttons for this record type (normal and pressed icon resources)
--		fToggleIndex = Optional. Function. This function will be called when the sidebar/library button is pressed for this record type. If not defined, a default master list window will be toggled.
--		sListDisplayClass = Optional. String. Class to use when displaying this record in a list. If not defined, a default class will be used.
--		sRecordDisplayClass = Required (or aRecordDisplayClasses/fRecordDisplayClass defined). String. Class to use when displaying this record in detail.
--		aRecordDisplayClasses = Required (or sRecordDisplayClass/fRecordDisplayClass defined). Table of strings. List of valid display classes for records of this type. Use fRecordDisplayClass to specify which one to use for a given path.
--		fRecordDisplayClass = Required (or sRecordDisplayClass/aRecordDisplayClasses defined). Function. Function called when requesting to display this record in detail.
--		aGMListButtons = Optional. Table of templates. A list of control templates created and added to the master list window for this record type.
--
--		sDisplayText = Required. String Resource. Text displayed in library and tooltips to identify record type textually.
--		sEmptyNameText = Optional. String Resource. Text displayed in name field of record list and detail classes, when name is empty.
--		sEmptyUnidentifiedNameText = Optional. String Resource. Text displayed in nonid_name field of record list and detail classes, when nonid_name is empty. Only used if bID flag set.
--

function toggleCharRecordIndex()
	local sDisplayIndex;
	if User.isLocal() then
		sDisplayIndex = "charselect_local";
	elseif User.isHost() then
		sDisplayIndex = "charselect_host";
	else
		sDisplayIndex = "charselect_client";
	end
	Interface.toggleWindow(sDisplayIndex, "charsheet");
end

aRecords = {
	["effect"] = {
		bExport = true,
		bExportListSkip = true,
		bHidden = true,
		aDataMap = { "effects" },
	},
	["modifier"] = {
		bExport = true,
		bExportListSkip = true,
		bHidden = true,
		aDataMap = { "modifiers" },
	},
	
	["charsheet"] = { 
		sExportPath = "pregencharsheet";
		sExportListClass = "pregencharselect";
		aDataMap = { "charsheet" }, 
		aDisplayIcon = { "button_characters", "button_characters_down" },
		fToggleIndex = toggleCharRecordIndex,
		-- sRecordDisplayClass = "charsheet", 
	},
	["note"] = { 
		bNoCategories = true,
		sEditMode = "play",
		aDataMap = { "notes" }, 
		aDisplayIcon = { "button_notes", "button_notes_down" },
		sListDisplayClass = "masterindexitem_note",
		-- sRecordDisplayClass = "note", 
	},

	["story"] = { 
		bExport = true,
		aDataMap = { "encounter", "reference.encounters" }, 
		aDisplayIcon = { "button_book", "button_book_down" },
		sRecordDisplayClass = "encounter", 
		aGMListButtons = { "button_storytemplate" },
		},
	["storytemplate"] = { 
		bExport = true,
		bHidden = true,
		aDataMap = { "storytemplate", "reference.storytemplates" }, 
		-- sRecordDisplayClass = "storytemplate", 
		},
	["quest"] = { 
		bExport = true,
		aDataMap = { "quest", "reference.quests" }, 
		aDisplayIcon = { "button_quests", "button_quests_down" },
		-- sRecordDisplayClass = "quest", 
	},
	["image"] = { 
		bExportNoReadOnly = true,
		bID = true,
		aDataMap = { "image", "reference.images" }, 
		aDisplayIcon = { "button_maps", "button_maps_down" }, 
		sListDisplayClass = "masterindexitem_id",
		sRecordDisplayClass = "imagewindow",
		aGMListButtons = { "button_folder_image", "button_store_image" },
	},
	["npc"] = { 
		bExport = true,
		bID = true,
		aDataMap = { "npc", "reference.npcs" }, 
		aDisplayIcon = { "button_people", "button_people_down" },
		sListDisplayClass = "masterindexitem_id",
		-- sRecordDisplayClass = "npc", 
	},
	["battle"] = { 
		bExport = true,
		aDataMap = { "battle", "reference.battles" }, 
		aDisplayIcon = { "button_encounters", "button_encounters_down" },
		-- sRecordDisplayClass = "battle", 
		aGMListButtons = { "button_battlerandom" },
	},
	["battlerandom"] = { 
		bExport = true,
		bHidden = true,
		aDataMap = { "battlerandom", "reference.battlerandoms" }, 
		-- sRecordDisplayClass = "battlerandom", 
	},
	["item"] = { 
		bExport = true,
		bID = true,
		aDataMap = { "item", "reference.items" }, 
		aDisplayIcon = { "button_items", "button_items_down" }, 
		sListDisplayClass = "masterindexitem_id",
		-- sRecordDisplayClass = "item",
		},
	["treasureparcel"] = { 
		bExport = true,
		aDataMap = { "treasureparcels", "reference.treasureparcels" }, 
		aDisplayIcon = { "button_parcels", "button_parcels_down" },
		-- sRecordDisplayClass = "treasureparcel", 
	},
	["table"] = { 
		bExport = true,
		aDataMap = { "tables", "reference.tables" }, 
		aDisplayIcon = { "button_tables", "button_tables_down" },
		-- sRecordDisplayClass = "table", 
		aGMEditButtons = { "button_add_table_guided" };
	},
	["vehicle"] = { 
		bExport = true,
		aDataMap = { "vehicle", "reference.vehicles" }, 
		aDisplayIcon = { "button_vehicles", "button_vehicles_down" },
		-- sRecordDisplayClass = "vehicle", 
		aGMListButtons = { "button_vehicle_type" };
		aCustomFilters = {
			["Type"] = { sField = "type" },
		},
	},
};

aListViews = {
	["vehicle"] = {
		["bytype"] = {
			sTitleRes = "vehicle_grouped_title_bytype",
			aColumns = {
				{ sName = "name", sType = "string", sHeadingRes = "vehicle_grouped_label_name", nWidth=200 },
				{ sName = "cost", sType = "string", sHeadingRes = "vehicle_grouped_label_cost", nWidth=80, bCentered=true },
				{ sName = "weight", sType = "number", sHeadingRes = "vehicle_grouped_label_weight", sTooltipRes="vehicle_grouped_tooltip_weight", bCentered=true },
				{ sName = "speed", sType = "string", sHeadingRes = "vehicle_grouped_label_speed", sTooltipRes="vehicle_grouped_tooltip_speed", nWidth=100, bCentered=true },
			},
			aFilters = {},
			aGroups = { { sDBField = "type" } },
			aGroupValueOrder = {},
		},
	},
};

function initialize()
	sFilterValueYes = Interface.getString("library_recordtype_filter_yes");
	sFilterValueNo = Interface.getString("library_recordtype_filter_no");
	sFilterValueEmpty = Interface.getString("library_recordtype_filter_empty");
	
	for kRecordType,vRecord in pairs(aRecords) do
		vRecord.sDisplayText = Interface.getString("library_recordtype_label_" .. kRecordType);
		vRecord.sEmptyNameText = Interface.getString("library_recordtype_empty_" .. kRecordType);
		if vRecord.bID then
			vRecord.sEmptyUnidentifiedNameText = Interface.getString("library_recordtype_empty_nonid_" .. kRecordType);
		end
		vRecord.sExportDisplayText = Interface.getString("library_recordtype_export_" .. kRecordType);
		if vRecord.sExportDisplayText == "" then vRecord.sExportDisplayText = vRecord.sDisplayText; end
		
		local aMappings = getMappings(kRecordType);
		if aMappings and (#aMappings > 0) then
			local rExport = {};
			rExport.name = kRecordType;
			rExport.label = vRecord.sExportDisplayText;
			if vRecord.sExportListClass then
				rExport.listclass = vRecord.sExportListClass;
			elseif not vRecord.bExportListSkip then
				rExport.listclass = "reference_list";
			end

			local sDisplayClass = getRecordDisplayClass(kRecordType);
			if vRecord.sExportPath then
				rExport.source = aMappings[1];
				rExport.export = vRecord.sExportPath;
				rExport.exportref = vRecord.sExportPath;
			elseif vRecord.bExportNoReadOnly then
				rExport.source = aMappings[1];
				rExport.export = aMappings[1];
				rExport.exportref = aMappings[1];
			elseif vRecord.bExport then
				rExport.source = aMappings[1];
				rExport.export = aMappings[1];
				rExport.exportref = aMappings[2];
			elseif vRecord.nExport then
				local aExportMappings = {};
				local aExportRefMappings = {};
				for i = 1, vRecord.nExport do
					if aMappings[i] then
						table.insert(aExportMappings, aMappings[i]);
					end
					if aMappings[vRecord.nExport + i] then
						table.insert(aExportRefMappings, aMappings[vRecord.nExport + i]);
					end
				end
				if #aExportMappings > 0 then
					rExport.source = aExportMappings;
					rExport.export = aExportMappings;
					rExport.exportref = aExportRefMappings;
				end
			end
			
			if rExport.source then
				ExportManager.registerExportNode(rExport);
			end
		end
	end
end

function getRecordTypes()
	local aRecordTypes = {};
	for kRecordType,vRecord in pairs(aRecords) do
		table.insert(aRecordTypes, kRecordType);
	end
	table.sort(aRecordTypes);
	return aRecordTypes;
end
function getRecordTypeInfo(sRecordType)
	return aRecords[sRecordType];
end
function setRecordTypeInfo(sRecordType, rRecordType)
	aRecords[sRecordType] = rRecordType;
end
function overrideRecordTypeInfo(sRecordType, rRecordType)
	if aRecords[sRecordType] then
		for k,v in pairs(rRecordType) do
			aRecords[sRecordType][k] = v;
		end
	else
		aRecords[sRecordType] = rRecordType;
	end
end
function getRecordTypeFromPath(sPath)
	for kRecordType,vRecord in pairs(aRecords) do
		if vRecord.aDataMap and vRecord.aDataMap[1] and vRecord.aDataMap[1] == sPath then
			return kRecordType;
		end
	end
	return "";
end
function getRecordTypeFromRecordPath(sRecord)
	local sRecordSansModule = StringManager.split(sRecord, "@")[1];
	local aRecordPathSansModule = StringManager.split(sRecordSansModule, ".");
	if #aRecordPathSansModule > 0 then aRecordPathSansModule[#aRecordPathSansModule] = nil; end
	local sRecordListSansModule = table.concat(aRecordPathSansModule, ".");
	for kRecordType,vRecord in pairs(aRecords) do
		if vRecord.aDataMap then
			for _,vMapping in ipairs(vRecord.aDataMap) do
				if vMapping == sRecordListSansModule then
					return kRecordType;
				end
			end
		end
	end
	return "";
end

function isHidden(sRecordType)
	if aRecords[sRecordType] then
		if aRecords[sRecordType].bHidden then
			return true;
		end
	end
	return false;
end

function getDisplayIcons(sRecordType)
	if aRecords[sRecordType] then
		if aRecords[sRecordType].aDisplayIcon then
			return unpack(aRecords[sRecordType].aDisplayIcon);
		end
	end
	return "";
end
function getDisplayText(sRecordType)
	if aRecords[sRecordType] then
		return aRecords[sRecordType].sDisplayText;
	end
	return "";
end

function getRootMapping(sRecordType)
	if aRecords[sRecordType] then
		local sType = type(aRecords[sRecordType].aDataMap);
		if sType == "table" then
			return aRecords[sRecordType].aDataMap[1];
		elseif sType == "string" then
			return aRecords[sRecordType].aDataMap;
		end
	end
end
function getMappings(sRecordType)
	if aRecords[sRecordType] then
		local sType = type(aRecords[sRecordType].aDataMap);
		if sType == "table" then
			return aRecords[sRecordType].aDataMap;
		elseif sType == "string" then
			return { aRecords[sRecordType].aDataMap };
		end
	end
	return {};
end
function getIndexDisplayClass(sRecordType)
	if aRecords[sRecordType] then
		return (aRecords[sRecordType].sListDisplayClass or "");
	end
	return "";
end
function getIndexButtons(sRecordType)
	if aRecords[sRecordType] then
		if User.isHost() then
			return (aRecords[sRecordType].aGMListButtons or {});
		else
			return (aRecords[sRecordType].aPlayerListButtons or {});
		end
	end
	return {};
end
function addIndexButton(sRecordType, sButtonTemplate)
	if (sButtonTemplate or "") == "" then
		return;
	end
	if aRecords[sRecordType] then
		if User.isHost() then
			if not aRecords[sRecordType].aGMListButtons then
				aRecords[sRecordType].aGMListButtons = {};
			end
			if not StringManager.contains(aRecords[sRecordType].aGMListButtons, sButtonTemplate) then
				table.insert(aRecords[sRecordType].aGMListButtons, sButtonTemplate);
			end
		else
			if not aRecords[sRecordType].aPlayerListButtons then
				aRecords[sRecordType].aPlayerListButtons = {};
			end
			if not StringManager.contains(aRecords[sRecordType].aPlayerListButtons, sButtonTemplate) then
				table.insert(aRecords[sRecordType].aPlayerListButtons, sButtonTemplate);
			end
		end
	end
end
function getEditButtons(sRecordType)
	if aRecords[sRecordType] then
		if User.isHost() then
			return (aRecords[sRecordType].aGMEditButtons or {});
		else
			return (aRecords[sRecordType].aPlayerEditButtons or {});
		end
	end
	return {};
end
function getCustomFilters(sRecordType)
	if aRecords[sRecordType] then
		return (aRecords[sRecordType].aCustomFilters or {});
	end
	return {};
end
function getEmptyNameText(sRecordType)
	if aRecords[sRecordType] then
		return aRecords[sRecordType].sEmptyNameText;
	end
	return "";
end
function getEmptyUnidentifiedNameText(sRecordType)
	if aRecords[sRecordType] then
		return aRecords[sRecordType].sEmptyUnidentifiedNameText;
	end
	return "";
end

function getRecordDisplayClass(sRecordType, sPath)
	if aRecords[sRecordType] then
		if aRecords[sRecordType].fRecordDisplayClass then
			return aRecords[sRecordType].fRecordDisplayClass(sPath);
		elseif aRecords[sRecordType].aRecordDisplayClasses then
			return aRecords[sRecordType].aRecordDisplayClasses[1];
		elseif aRecords[sRecordType].sRecordDisplayClass then
			return aRecords[sRecordType].sRecordDisplayClass;
		else
			return sRecordType;
		end
	end
	return "";
end
function isRecordDisplayClass(sRecordType, sClass)
	if aRecords[sRecordType] then
		if aRecords[sRecordType].fIsRecordDisplayClass then
			return aRecords[sRecordType].fIsRecordDisplayClass(sClass);
		elseif aRecords[sRecordType].aRecordDisplayClasses then
			return StringManager.contains(aRecords[sRecordType].aRecordDisplayClasses, sClass);
		elseif aRecords[sRecordType].sRecordDisplayClass then
			return (aRecords[sRecordType].sRecordDisplayClass == sClass);
		else
			return (sRecordType == sClass);
		end
	end
	return false;
end
function getRecordTypeFromDisplayClass(sClass)
	for kRecordType,vRecordType in pairs(aRecords) do
		if isRecordDisplayClass(kRecordType, sClass) then
			return kRecordType;
		end
	end
	return "";
end

function isIdentifiable(sRecordType, vNode)
	if aRecords[sRecordType] then
		if aRecords[sRecordType].bID then
			if aRecords[sRecordType].fIsIdentifiable then
				return aRecords[sRecordType].fIsIdentifiable(vNode);
			else
				return true;
			end
		end
	end
	return false;
end
function getIDOption(sRecordType)
	if aRecords[sRecordType] and aRecords[sRecordType].sIDOption then
		return aRecords[sRecordType].sIDOption;
	end
	return "";
end
function getIDState(sRecordType, vNode, bIgnoreHost)
	local bID = true;
	
	if isIdentifiable(sRecordType, vNode) then
		if aRecords[sRecordType].fGetIDState then
			bID = aRecords[sRecordType].fGetIDState(vNode, bIgnoreHost);
		else
			if (bIgnoreHost or not User.isHost()) then
				bID = (DB.getValue(vNode, "isidentified", 1) == 1);
			end
		end
	end
	
	return bID, true;
end

function getCustomData(sRecordType, sKey)
	if aRecords[sRecordType] and aRecords[sRecordType].aCustom then
		return aRecords[sRecordType].aCustom[sKey];
	end
	return nil;
end
function setCustomData(sRecordType, sKey, v)
	if aRecords[sRecordType] then
		if not aRecords[sRecordType].aCustom then
			aRecords[sRecordType].aCustom = {};
		end
		aRecords[sRecordType].aCustom[sKey] = v;
	end
end

function allowCategories(sRecordType)
	if aRecords[sRecordType] then
		if aRecords[sRecordType].bNoCategories then
			return false;
		end
	end
	return true;
end
function allowEdit(sRecordType)
	if aRecords[sRecordType] then
		local vEditMode = aRecords[sRecordType].sEditMode;
		if vEditMode then
			if vEditMode == "play" then
				return not User.isLocal();
			elseif vEditMode == "none" then
				return false;
			end
		end

		-- Default behavior (host only editing, no local or player)
		if User.isHost() then
			return true;
		end
	end
	return false;
end

--
--	LIST VIEW FUNCTIONS
--

function setListView(sRecordType, sListView, aListView)
	if not aListViews[sRecordType] then
		aListViews[sRecordType] = {};
	end
	aListViews[sRecordType][sListView] = aListView;
end
function getListView(sRecordType, sListView)
	if not aListViews[sRecordType] or not aListViews[sRecordType][sListView] then
		return nil;
	end
	return aListViews[sRecordType][sListView];
end

--
--	GROUPED LIST FUNCTIONS
--

local aCustomFilterHandlers = {};
function setCustomFilterHandler(sKey, f)
	aCustomFilterHandlers[sKey] = f;
end
function getCustomFilterValue(sKey, vRecord, vDefault)
	if aCustomFilterHandlers[sKey] then
		return aCustomFilterHandlers[sKey](vRecord, vDefault);
	end
	return vDefault;
end

--
--	FILTER LIST FUNCTIONS
--

local aCustomGroupOutputHandlers = {};
function setCustomGroupOutputHandler(sKey, f)
	aCustomGroupOutputHandlers[sKey] = f;
end
function getCustomGroupOutput(sKey, vGroupValue)
	if aCustomGroupOutputHandlers[sKey] then
		return aCustomGroupOutputHandlers[sKey](vGroupValue);
	end
	return vGroupValue;
end

