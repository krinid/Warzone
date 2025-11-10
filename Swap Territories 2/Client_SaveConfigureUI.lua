-- This file was copied as part of the implementation of https://github.com/DanWaLes/Warzone/tree/main/mods/libs/AutoSettingsFiles
-- Original source: https://github.com/DanWaLes/Warzone/tree/main/mods/libs/AutoSettingsFiles/code/Client_SaveConfigureUI.lua
-- Copyright (c) 2023-2025 https://github.com/DanWaLes
-- Licensed under the MIT License: https://opensource.org/license/mit

require('__settings');

local function isVersionOrHigher(version)
	return WL and WL.IsVersionOrHigher and WL.IsVersionOrHigher(version);
end

local errMsg;
local settingValues;
local modDevMadeError = false;
local customCardSettings;
local canUseUIElementIsDestroyed;
local canUseCustomCards;

function Client_SaveConfigureUI(alert, addCard)
	errMsg = nil;
	settingValues = {};
	customCardSettings = {};
	canUseUIElementIsDestroyed = isVersionOrHigher('5.21');
	canUseCustomCards = isVersionOrHigher('5.34.1');

	if type(getSettings) ~= 'function' then
		getSettings = function()
			return nil;
		end;
	end

	local settings = getSettings();

	csc(settings);

	if modDevMadeError then
		settingValues = {};
		errMsg = 'The mod developer made an error while adding settings';
	end

	if errMsg then
		alert(errMsg);

		return;
	end

	for settingName, settingValue in pairs(settingValues) do
		Mod.Settings[settingName] = settingValue;
	end

	function getCardGameSetting(setting, key)
		local value = setting.cardGameSettingsMap[key];

		if type(value) == 'string' then
			value = Mod.Settings[value];
		end

		return value;
	end

	if type(addCard) == 'function' then
		for i, setting in ipairs(customCardSettings) do
			local duration = getCardGameSetting(setting, 'ActiveOrderDuration') or -1;
			local expireBehavior = getCardGameSetting(setting, 'ActiveCardExpireBehavior');

			if duration  <= 0 then
				duration = -1
				expireBehavior = nil;
			end

			local cardId = addCard(
				setting.customCardName,
				setting.customCardDescription,
				setting.customCardImageFilename,
				getCardGameSetting(setting, 'NumPieces'),
				getCardGameSetting(setting, 'MinimumPiecesPerTurn'),
				getCardGameSetting(setting, 'InitialPieces'),
				getCardGameSetting(setting, 'Weight'),
				duration,
				expireBehavior
			);

			Mod.Settings[setting.name] = cardId;
		end
	end

	return true;
end

function csc(settings)
	if type(settings) ~= 'table' then
		modDevMadeError = true;
	end

	if modDevMadeError then
		return;
	end

	for _, setting in ipairs(settings) do
		if type(setting) ~= 'table' then
			modDevMadeError = true;

			return;
		end

		if setting.isTemplate then
			Mod.Settings[setting.name] = GLOBALS[setting.name];

			local n = 1;

			while n < (Mod.Settings[setting.name] + 1) do
				local toAdd = setting.get(n);

				cscDoSetting(toAdd);
				n = n + 1;
			end
		else
			cscDoSetting(setting);
		end
	end
end

function cscDoSetting(setting)
	if setting.isCustomCard then
		if not canUseCustomCards then
			return;
		end

		if setting.usesSettings then
			csc(setting.settings);
		end

		table.insert(customCardSettings, setting);
		return;
	end

	if setting.inputType == 'radio' then
		-- explicitly written to in Client_PresentConfigureUI if the value has ever been changed from the default

		if not Mod.Settings[setting.name] then
			Mod.Settings[setting.name] = setting.defaultValue;
		end

		return;
	end

	local settingVal;

	if setting.inputType == 'bool' then
		settingVal = access(setting, 'GetIsChecked');
	elseif setting.inputType == 'text' then
		settingVal = access(setting, 'GetText');

		local length = #settingVal;
		local tooLong = setting.charLimit and (length > setting.charLimit);
		local notEntered = length < 1;

		if tooLong or notEntered then
			if errMsg == nil then
				errMsg = '';
			end

			if errMsg ~= '' then
				errMsg = errMsg .. '\n';
			end

			errMsg = errMsg .. setting.label .. ' must be ';

			if tooLong then
				errMsg = errMsg .. 'less than ' .. setting.charLimit .. ' character';

				if setting.charLimit > 1 then
					errMsg = errMsg + 's';
				end

				errMsg = errMsg .. ' long';
			else
				errMsg = errMsg .. ' entered';
			end
		end
	else
		settingVal = access(setting, 'GetValue');

		if setting.inputType == 'float' then
			settingVal = round(settingVal, setting.dp);
		end

		local absoluteMax = setting.absoluteMax or setting.maxValue;
		local absoluteMin = setting.absoluteMin or setting.minValue;
		local usingMax = type(setting.absoluteMax) == 'number' and settingVal > setting.maxValue;
		local usingMin = type(setting.absoluteMin) == 'number' and settingVal < setting.minValue;
		local isTooHigh = settingVal > absoluteMax;
		local isTooLow = settingVal < absoluteMin;

		if isTooLow or isTooHigh then
			if errMsg == nil then
				errMsg = '';
			end

			if errMsg ~= '' then
				errMsg = errMsg .. '\n';
			end

			errMsg = errMsg .. setting.label .. ' must be ';

			if isTooLow and not usingMin then
				errMsg = errMsg .. 'greater than ' .. tostring(setting.minValue);
			elseif isTooHigh and not usingMax then
				errMsg = errMsg .. 'less than ' .. tostring(setting.maxValue);
			else
				errMsg = errMsg .. 'between ' .. tostring(absoluteMin) .. ' and ' .. tostring(absoluteMax);
			end
		end
	end

	settingValues[setting.name] = settingVal;

	if settingVal and setting.inputType == 'bool' and setting.subsettings then
		csc(setting.subsettings);
	end
end

function access(setting, fn)
	-- check if the element for the setting is destroyed before trying to access any of its functions

	-- if destroyed might not be able to access the value
	-- so use the defaultValue fallback

	local value = Mod.Settings[setting.name];

	if value == nil then
		value = setting.defaultValue;
	end

	local el = GLOBALS[setting.name];

	if canUseUIElementIsDestroyed then
		if not UI.IsDestroyed(el) then
			value = el[fn]();
		end	
	else
		-- no ui elements are destroyed if UI.IsDestroyed is not an option
		-- so safe to set the value as long as the element exists

		if el then
			value = el[fn]();
		end
	end

	if value == nil then
		print('access(setting, fn) result is nil');
		print('setting.name = ' .. setting.name);
		print('fn = ' .. fn);
	end

	return value;
end

-- This function was adapted from the Lua-users wiki
-- Original source: http://lua-users.org/wiki/SimpleRound
-- Author: Unknown (Unable to determine the original author)
-- Copyright: Unknown (Assumed to be permissively licensed, such as MIT)
-- Adaptions:
-- Rename parameter 1 from `num` to `n`
-- Rename parameter 2 from `numDecimalPlaces` to `dp`
-- Whitespace changes
function round(n, dp)
	local multi = 10 ^ (dp or 0);

	return math.floor(n * multi + 0.5) / multi;
end