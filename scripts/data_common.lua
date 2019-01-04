-- 'Fantasy Grounds' is a trademark of SmiteWorks USA, LLC. 'Fantasy Grounds' is Copyright 2004-2014 SmiteWorks USA LLC.
-- The CoreRPG ruleset and all included files are copyright 2004-2013, Smiteworks USA LLC.

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

rsname = "PFRPG";
rsversion = 1;

function isPFRPG()
	return true;
end

-- Abilities (database names)
abilities = {
	"strength",
	"dexterity",
	"constitution",
	"intelligence",
	"wisdom",
	"charisma"
};

ability_ltos = {
	["strength"] = "STR",
	["dexterity"] = "DEX",
	["constitution"] = "CON",
	["intelligence"] = "INT",
	["wisdom"] = "WIS",
	["charisma"] = "CHA"
};

ability_stol = {
	["STR"] = "strength",
	["DEX"] = "dexterity",
	["CON"] = "constitution",
	["INT"] = "intelligence",
	["WIS"] = "wisdom",
	["CHA"] = "charisma"
};

-- Basic class values (not display values)
classes = {
	"barbarian",
	"bard",
	"cleric",
	"druid",
	"fighter",
	"monk",
	"paladin",
	"ranger",
	"rogue",
	"sorcerer",
	"warlock",
	"wizard",
};

-- Values for wound comparison
healthstatusfull = "healthy";
healthstatushalf = "bloodied";
healthstatuswounded = "wounded";

-- Values for alignment comparison
alignment_lawchaos = {
	["lawful"] = 1,
	["chaotic"] = 3,
	["lg"] = 1,
	["ln"] = 1,
	["le"] = 1,
	["cg"] = 3,
	["cn"] = 3,
	["ce"] = 3,
};
alignment_goodevil = {
	["good"] = 1,
	["evil"] = 3,
	["lg"] = 1,
	["le"] = 3,
	["ng"] = 1,
	["ne"] = 3,
	["cg"] = 1,
	["ce"] = 3,
};

-- Values for size comparison
creaturesize = {
	["tiny"] = 1,
	["small"] = 2,
	["medium"] = 3,
	["large"] = 4,
	["huge"] = 5,
	["gargantuan"] = 6,
	["t"] = 1,
	["s"] = 2,
	["m"] = 3,
	["l"] = 4,
	["h"] = 5,
	["g"] = 6,
};

-- Values for creature type comparison
creaturedefaulttype = "humanoid";
creaturehalftype = "half-";
creaturehalftypesubrace = "human";
creaturetype = {
	"aberration",
	"beast",
	"celestial",
	"construct",
	"dragon",
	"elemental",
	"fey",
	"fiend",
	"giant",
	"humanoid",
	"monstrosity",
	"ooze",
	"plant",
	"undead",
};
creaturesubtype = {
	"aarakocra",
	"bullywug",
	"demon",
	"devil",
	"dragonborn",
	"dwarf",
	"elf", 
	"gith",
	"gnoll",
	"gnome", 
	"goblinoid",
	"grimlock",
	"halfling",
	"human",
	"kenku",
	"kuo-toa",
	"kobold",
	"lizardfolk",
	"living construct",
	"merfolk",
	"orc",
	"quaggoth",
	"sahuagin",
	"shapechanger",
	"thri-kreen",
	"titan",
	"troglodyte",
	"yuan-ti",
	"yugoloth",
};

-- Values supported in effect conditionals
conditionaltags = {
};

-- Conditions supported in effect conditionals and for token widgets
conditions = {
	"blinded", 
	"charmed",
	"cursed",
	"deafened",
	"encumbered",
	"frightened", 
	"grappled", 
	"incapacitated",
	"incorporeal",
	"intoxicated",
	"invisible", 
	"paralyzed",
	"petrified",
	"poisoned",
	"prone", 
	"ready",
	"restrained",
	"stable", 
	"stunned",
	"turned",
	"unconscious"
};

-- Bonus/penalty effect types for token widgets
bonuscomps = {
	"INIT",
	"CHECK",
	"AC",
	"ATK",
	"DMG",
	"HEAL",
	"SAVE",
	"STR",
	"CON",
	"DEX",
	"INT",
	"WIS",
	"CHA",
};

-- Bonus/penalty effect types for token widgets
bonuscomps_icon = {
	["INIT"] = {"cond_bonus_init","cond_penalty_init","cond_bonus_more_init","cond_penalty_more_init"},
	["CHECK"] = {"cond_bonus_abil","cond_penalty_abil","cond_bonus_more_abil","cond_penalty_more_abil"},
	["AC"] = {"cond_bonus_ac","cond_penalty_ac","cond_bonus_more_ac","cond_penalty_more_ac"},
	["ATK"] = {"cond_bonus_atk","cond_penalty_atk","cond_bonus_more_atk","cond_penalty_more_atk"},

	["DMG"] = {"cond_bonus_dmg","cond_penalty_dmg","cond_bonus_more_dmg","cond_penalty_more_dmg"},
	["DMGS"] = {"cond_bonus_dmg","cond_penalty_dmg","cond_bonus_more_dmg","cond_penalty_more_dmg"},
	["HEAL"] = {"cond_bonus_heal","cond_penalty_heal","cond_bonus_more_heal","cond_penalty_more_heal"},
	["SAVE"] = {"cond_bonus_sav","cond_penalty_sav","cond_bonus_more_sav","cond_penalty_more_sav"},
	["SKILL"] = {"cond_bonus_skill","cond_penalty_skill","cond_bonus_more_skill","cond_penalty_more_skill"},
	["STR"] = {"cond_bonus_str","cond_penalty_str","cond_bonus_more_str","cond_penalty_more_str"},
	["CON"] = {"cond_bonus_con","cond_penalty_con","cond_bonus_more_con","cond_penalty_more_con"},
	["DEX"] = {"cond_bonus_dex","cond_penalty_dex","cond_bonus_more_dex","cond_penalty_more_dex"},
	["INT"] = {"cond_bonus_int","cond_penalty_int","cond_bonus_more_int","cond_penalty_more_int"},
	["WIS"] = {"cond_bonus_wis","cond_penalty_wis","cond_bonus_more_wis","cond_penalty_more_wis"},
	["CHA"] = {"cond_bonus_cha","cond_penalty_cha","cond_bonus_more_cha","cond_penalty_more_cha"},

};


-- Condition effect types for token widgets
condcomps = {
	["blinded"] = {"cond_blinded","cond_blinded_more",""},
	["charmed"] = {"cond_charmed","","cond_charmed_more",""},
	["cursed"] = {"cond_curse","","cond_cursed_more",""},
	["deafened"] = {"cond_deafened","","cond_deafened_more",""},
	["encumbered"] = {"cond_encumbered","","cond_encumbered_more",""},
	["exhausted"] = {"cond_exhausted","","cond_exhausted_more",""},
	["frightened"] = {"cond_frightened","","cond_frightened_more",""},
	["grappled"] = {"cond_grappled","","cond_grappled_more",""},
	["incapacitated"] = {"cond_helpless","","cond_helpless_more",""},
	["incorporeal"] = {"cond_incorporeal","","cond_incorporeal_more",""},
	["intoxicated"] = {"cond_intoxicated","","cond_intoxicated_more",""},
	["invisible"] = {"cond_invisible","","cond_invisible_more",""},
	["paralyzed"] = {"cond_paralyzed","","cond_paralyzed_more",""},
	["petrified"] = {"cond_petrified","","cond_petrified_more",""},
	["poisoned"] = {"cond_poison","","cond_poison_more",""},
	["prone"] = {"cond_prone","","cond_prone_more",""},
	["ready"] = {"cond_ready","","cond_ready_more"},
	["restrained"] = {"cond_restrained","","cond_restraitned_more",""},
	["stable"] = {"cond_stable","","cond_stable_more",""},
	["stunned"] = {"cond_stunned","","cond_stunned_more",""},
	["turned"] = {"cond_turned","","cond_turned_more",""},
	["unconscious"] = {"cond_unconscious","","cond_unconscious_more",""},
};

-- extra condition comps
condcomps_extra = {
	["cover"] = {"cond_cover","","cond_cover_more",""},
	["scover"] = {"cond_scover","","cond_scover_more",""},
	["advinit"] = {"cond_advinit","","cond_advinit_more",""},
	["disinit"] = {"cond_disinit","","cond_disinit_more",""},
	["advatk"] = {"cond_advatk","cond_advatk_more",""},
	["disatk"] = {"cond_disatk","","cond_disatk_more",""},
	["grantadvatk"] = {"cond_grantadvatk","","cond_grantadvatk_more",""},
	["grantdisatk"] = {"cond_grantdisatk","","cond_grantdisatk_more",""},
	["advsav"] = {"cond_advsav","","cond_advsav_more",""},
	["dissav"] = {"cond_dissav","","cond_dissave_more",""},
	["advchk"] = {"cond_advchk","","cond_advchk_more",""},
	["dischk"] = {"cond_dischk","","cond_dischk_more",""},
	["advskill"] = {"cond_advskill","","cond_advskill_more",""},
	["disskill"] = {"cond_disskill","","cond_disskill_more",""},
	["advdeath"] = {"cond_advdeath","","cond_advdeath_more",""},
	["disdeath"] = {"cond_disdeath","","cond_disdeath_more",""},
	["(c)"] = {"cond_concentration","","cond_concentration_more",""},
	["magic resistance"] = {"cond_magicresist","","cond_magicresist_more",""}
}; 

-- Other visible effect types for token widgets
othercomps = {
	["COVER"] = {"cond_cover","","cond_cover_more",""},
	["SCOVER"] = {"cond_scover","","cond_scover_more",""},
	["IMMUNE"] = {"cond_immune","","cond_immune_more",""},
	["RESIST"] = {"cond_resist","","cond_resist_more",""},
	["VULN"] = {"cond_vuln","","cond_vuln_more",""},
	["REGEN"] = {"cond_regen","","cond_regen",""},
	["DMGO"] = {"cond_ongoing","","cond_ongoing_more",""},
	["DMGTYPE"] = {"cond_dmgtype","","cond_dmgtype_more",""},
	["ADVATK"] = {"cond_advatk","cond_advatk_more",""},
	["DISATK"] = {"cond_disatk","","cond_disatk_more",""},
	["GRANTADVATK"] = {"cond_grantadvatk","","cond_grantadvatk_more",""},
	["GRANTDISATK"] = {"cond_grantdisatk","","cond_grantdisatk_more",""},
	["ADVSAV"] = {"cond_advsav","","cond_advsav_more",""},
	["DISSAV"] = {"cond_dissav","","cond_dissave_more",""},
	["ADVCHK"] = {"cond_advchk","","cond_advchk_more",""},
	["DISCHK"] = {"cond_dischk","","cond_dischk_more",""},
	["ADVSKILL"] = {"cond_advskill","","cond_advskill_more",""},
	["DISSKILL"] = {"cond_disskill","","cond_disskill_more",""},
	["EXHAUSTION"] = {"cond_exhausted","","cond_exhausted_more",""},
	["RCHG"] = {"cond_recharge","","cond_recharge_more",""}
};

-- Other visible effect types (extra icons)
othercomps_extra_icon = {
	["COVER"] = {"cond_cover","","cond_cover_more",""},
	["SCOVER"] = {"cond_scover","","cond_scover_more",""},
	["IMMUNE"] = {"cond_immune","","cond_immune_more",""},
	["RESIST"] = {"cond_resist","","cond_resist_more",""},
	["VULN"] = {"cond_vuln","","cond_vuln_more",""},
	["REGEN"] = {"cond_regen","","cond_regen",""},
	["FLIGHT"] = {"cond_flight","","cond_flight_more",""},
	["DMGO"] = {"cond_ongoing","","cond_ongoing_more",""},
	["DMGTYPE"] = {"cond_dmgtype","","cond_dmgtype_more",""},
	["ADVINIT"] = {"cond_advinit","","cond_adv_init_more",""},
	["DISINIT"] = {"cond_disinit","","cond_disinit_more",""},
	["ADVATK"] = {"cond_advatk","cond_advatk_more",""},
	["DISATK"] = {"cond_disatk","","cond_disatk_more",""},
	["GRANTADVATK"] = {"cond_grantadvatk","","cond_grantadvatk_more",""},
	["GRANTDISATK"] = {"cond_grantdisatk","","cond_grantdisatk_more",""},
	["ADVSAV"] = {"cond_advsav","","cond_advsav_more",""},
	["DISSAV"] = {"cond_dissav","","cond_dissave_more",""},
	["ADVCHK"] = {"cond_advchk","","cond_advchk_more",""},
	["DISCHK"] = {"cond_dischk","","cond_dischk_more",""},
	["ADVSKILL"] = {"cond_advskill","","cond_advskill_more",""},
	["DISSKILL"] = {"cond_disskill","","cond_disskill_more",""},
	["ADVDEATH"] = {"cond_advdeath","","cond_advdeath_more",""},
	["DISDEATH"] = {"cond_disdeath","","cond_disdeath_more",""},
	["EXHAUSTION"] = {"cond_exhausted","","cond_exhausted_more",""},
	["(C)"] = {"cond_concentration","","cond_concentration_more",""},
	["RCHG"] = {"cond_recharge","","cond_recharge_more",""}
};


-- Exhaustion levels as an icon
exhaustion = {
	{"cond_exhausted_1","","cond_exhausted_1_more"},
	{"cond_exhausted_2","","cond_exhausted_2_more"},
	{"cond_exhausted_3","","cond_exhausted_3_more"},
	{"cond_exhausted_4","","cond_exhausted_4_more"},
	{"cond_exhausted_5","","cond_exhausted_5_more"},
	{"cond_exhausted_6","","cond_exhausted_6_more"}
};

-- Effect components which can be targeted
targetableeffectcomps = {
	"COVER",
	"SCOVER",
	"AC",
	"SAVE",
	"ATK",
	"DMG",
	"IMMUNE",
	"VULN",
	"RESIST"
};

connectors = {
	"and",
	"or"
};

-- Range types supported
rangetypes = {
	"melee",
	"ranged"
};

-- Damage types supported
dmgtypes = {
	"acid",		-- ENERGY TYPES
	"cold",
	"fire",
	"force",
	"lightning",
	"necrotic",
	"poison",
	"psychic",
	"radiant",
	"thunder",
	"adamantine", 	-- WEAPON PROPERTY DAMAGE TYPES
	"bludgeoning",
	"cold-forged iron",
	"magic",
	"piercing",
	"silver",
	"slashing",
	"critical", -- SPECIAL DAMAGE TYPES
};

specialdmgtypes = {
	"critical",
};

-- Bonus types supported in power descriptions
bonustypes = {
};
stackablebonustypes = {
};

function onInit()
	-- Classes
	class_nametovalue = {
		[Interface.getString("class_value_barbarian")] = "barbarian",
		[Interface.getString("class_value_bard")] = "bard",
		[Interface.getString("class_value_cleric")] = "cleric",
		[Interface.getString("class_value_druid")] = "druid",
		[Interface.getString("class_value_fighter")] = "fighter",
		[Interface.getString("class_value_monk")] = "monk",
		[Interface.getString("class_value_paladin")] = "paladin",
		[Interface.getString("class_value_ranger")] = "ranger",
		[Interface.getString("class_value_rogue")] = "rogue",
		[Interface.getString("class_value_sorcerer")] = "sorcerer",
		[Interface.getString("class_value_warlock")] = "warlock",
		[Interface.getString("class_value_wizard")] = "wizard",
	};

	class_valuetoname = {
		["barbarian"] = Interface.getString("class_value_barbarian"),
		["bard"] = Interface.getString("class_value_bard"),
		["cleric"] = Interface.getString("class_value_cleric"),
		["druid"] = Interface.getString("class_value_druid"),
		["fighter"] = Interface.getString("class_value_fighter"),
		["monk"] = Interface.getString("class_value_monk"),
		["paladin"] = Interface.getString("class_value_paladin"),
		["ranger"] = Interface.getString("class_value_ranger"),
		["rogue"] = Interface.getString("class_value_rogue"),
		["sorcerer"] = Interface.getString("class_value_sorcerer"),
		["warlock"] = Interface.getString("class_value_warlock"),
		["wizard"] = Interface.getString("class_value_wizard"),
	};

	-- Skills
	skilldata = {
		[Interface.getString("skill_value_acrobatics")] = { lookup = "acrobatics", stat = 'dexterity' },
		[Interface.getString("skill_value_animalhandling")] = { lookup = "animalhandling", stat = 'wisdom' },
		[Interface.getString("skill_value_arcana")] = { lookup = "arcana", stat = 'intelligence' },
		[Interface.getString("skill_value_athletics")] = { lookup = "athletics", stat = 'strength' },
		[Interface.getString("skill_value_deception")] = { lookup = "deception", stat = 'charisma' },
		[Interface.getString("skill_value_history")] = { lookup = "history", stat = 'intelligence' },
		[Interface.getString("skill_value_insight")] = { lookup = "insight", stat = 'wisdom' },
		[Interface.getString("skill_value_intimidation")] = { lookup = "intimidation", stat = 'charisma' },
		[Interface.getString("skill_value_investigation")] = { lookup = "investigation", stat = 'intelligence' },
		[Interface.getString("skill_value_medicine")] = { lookup = "medicine", stat = 'wisdom' },
		[Interface.getString("skill_value_nature")] = { lookup = "nature", stat = 'intelligence' },
		[Interface.getString("skill_value_perception")] = { lookup = "perception", stat = 'wisdom' },
		[Interface.getString("skill_value_performance")] = { lookup = "performance", stat = 'charisma' },
		[Interface.getString("skill_value_persuasion")] = { lookup = "persuasion", stat = 'charisma' },
		[Interface.getString("skill_value_religion")] = { lookup = "religion", stat = 'intelligence' },
		[Interface.getString("skill_value_sleightofhand")] = { lookup = "sleightofhand", stat = 'dexterity' },
		[Interface.getString("skill_value_stealth")] = { lookup = "stealth", stat = 'dexterity', disarmorstealth = 1 },
		[Interface.getString("skill_value_survival")] = { lookup = "survival", stat = 'wisdom' },
	};

	-- Party sheet drop down list data
	psabilitydata = {
		Interface.getString("strength"),
		Interface.getString("dexterity"),
		Interface.getString("constitution"),
		Interface.getString("intelligence"),
		Interface.getString("wisdom"),
		Interface.getString("charisma"),
	};

	-- Party sheet drop down list data
	psskilldata = {
		Interface.getString("skill_value_acrobatics"),
		Interface.getString("skill_value_animalhandling"),
		Interface.getString("skill_value_arcana"),
		Interface.getString("skill_value_athletics"),
		Interface.getString("skill_value_deception"),
		Interface.getString("skill_value_history"),
		Interface.getString("skill_value_insight"),
		Interface.getString("skill_value_intimidation"),
		Interface.getString("skill_value_investigation"),
		Interface.getString("skill_value_medicine"),
		Interface.getString("skill_value_nature"),
		Interface.getString("skill_value_perception"),
		Interface.getString("skill_value_performance"),
		Interface.getString("skill_value_persuasion"),
		Interface.getString("skill_value_religion"),
		Interface.getString("skill_value_sleightofhand"),
		Interface.getString("skill_value_stealth"),
		Interface.getString("skill_value_survival"),
	};
end
