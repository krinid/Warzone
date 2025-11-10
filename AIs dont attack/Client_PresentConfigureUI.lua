-- This file was copied as part of the implementation of https://github.com/DanWaLes/Warzone/tree/main/mods/libs/AutoSettingsFiles
-- Original source: https://github.com/DanWaLes/Warzone/tree/main/mods/libs/AutoSettingsFiles/code/Client_PresentConfigureUI.lua
-- Copyright (c) 2023-2025 https://github.com/DanWaLes
-- Licensed under the MIT License: https://opensource.org/license/mit

require('__settings');

GLOBALS = {};

local function isVersionOrHigher(version)
	return WL and WL.IsVersionOrHigher and WL.IsVersionOrHigher(version);
end

local modDevMadeError = false;
local settingHelpAreas = {};
local canUseUIElementIsDestroyed;
local canUseCustomCards;
local canUseRadioButtons;
local appVersionCustomCards = '5.34.1';
local save = nil;

function Client_PresentConfigureUI(rootParent)
	canUseUIElementIsDestroyed = isVersionOrHigher('5.21');
	canUseCustomCards = isVersionOrHigher(appVersionCustomCards);
	canUseRadioButtons = isVersionOrHigher('5.34');
	save = function()
		-- save because destroying otherwise goes back to default setting values
		-- returns true if there isnt a error, false if there is an error

		return Client_SaveConfigureUI(UI.Alert);
	end

	if type(getSettings) ~= 'function' then
		getSettings = function()
			return nil;
		end;
	end

	local vert = UI.CreateVerticalLayoutGroup(rootParent);

	cpc(vert, getSettings());

	if not modDevMadeError then
		return;
	end

	UI.CreateLabel(vert).SetColor('#FF0000').SetText('The mod developer made an error while trying to add settings');
end

function cpc(parent, settings)
	if type(settings) ~= 'table' then
		modDevMadeError = true;
	end

	if modDevMadeError then
		return;
	end

	local vert = UI.CreateVerticalLayoutGroup(parent);

	for _, setting in ipairs(settings) do
		if type(setting) ~= 'table' then
			modDevMadeError = true;

			return;
		end

		if setting.isTemplate then
			cpcDoTemplate(setting, vert);
		else
			cpcDoSetting(setting, vert);
		end
	end
end

function cpcDoTemplate(setting, vert)
	GLOBALS[setting.name] = Mod.Settings[setting.name] or 0;

	local vert2 = UI.CreateVerticalLayoutGroup(vert);
	local i = 1;

	while i < (GLOBALS[setting.name] + 1) do
		cpcDoSetting(setting.get(i), vert2);
		i = i + 1;
	end

	local btn = UI.CreateButton(vert)
		.SetColor(setting.btnColor or '#00FF05')
		.SetText(setting.btnText);

	if setting.btnTextColor then
		btn.SetTextColor(setting.btnTextColor);
	end

	btn.SetOnClick(function()
		GLOBALS[setting.name] = GLOBALS[setting.name] + 1;
		cpcDoSetting(setting.get(GLOBALS[setting.name]), vert2);
	end);
end

function cpcDoSetting(setting, vert)
	if setting.isCustomCard then
		if not canUseCustomCards then
			UI.CreateLabel(vert).SetText('This mod uses custom cards.');
			UI.CreateLabel(vert).SetText('You must use update your app to at least version ' .. appVersionCustomCards .. ' to use custom card features in games.');

			return;
		end

		if setting.usesSettings then
			cpc(vert, setting.settings);
		end

		return;
	end

	local horz = UI.CreateHorizontalLayoutGroup(vert);
	local vert2 = UI.CreateVerticalLayoutGroup(vert);
	local initialSettingValue = Mod.Settings[setting.name];

	if initialSettingValue == nil then
		initialSettingValue = setting.defaultValue;
	end

	if setting.inputType == 'radio' then
		local horz1 = UI.CreateHorizontalLayoutGroup(horz);
		local vert3 = nil;
		local vert4 = nil;
		local vert5 = nil;
		local selectedCheckbox = nil;
		local selectedRadioButtonLabel = nil;
		local selectedRadioButtonHelp = nil;
		local selectedRadioButtonHelpHelpParent = nil;

		function getLabelFromOption(option)
			return (type(option) == 'string' and option) or option.label;
		end

		function getLabelColorFromOption(option)
			return (type(option) == 'table' and option.labelColor) or nil;
		end

		function updateLabelWithOption(option)
			local text = getLabelFromOption(option);
			local color = getLabelColorFromOption(option);

			selectedRadioButtonLabel.SetText(text);

			if color then
				selectedRadioButtonLabel.SetColor(color);
			end

			if selectedRadioButtonHelp then
				UI.Destroy(selectedRadioButtonHelp);
				UI.Destroy(selectedRadioButtonHelpHelpParent);
				selectedRadioButtonHelp = nil;
				settingHelpAreas[setting.name .. tostring(-1)] = nil;
			end

			if optionHasHelp(option) then
				selectedRadioButtonHelpHelpParent = UI.CreateVerticalLayoutGroup(vert3);
				selectedRadioButtonHelp = makeLabelHelpFromOption(horz1, selectedRadioButtonHelpHelpParent, option, -1);
			end
		end

		function makeLabelFromOption(parent, option)
			return createLabel(parent, {
				label = getLabelFromOption(option),
				labelColor = getLabelColorFromOption(option)
			});
		end

		function optionHasHelp(option)
			return type(option) == 'table' and option.help;
		end

		function makeLabelHelpFromOption(btnParent, helpParent, option, fakeSettingNameSuffix)
			if not optionHasHelp(option) then
				return;
			end

			-- make a fake setting so that createHelpBtn can be reused using option

			local fakeSetting = {
				name = setting.name .. tostring(fakeSettingNameSuffix),
				help = option.help
			};

			return createHelpBtn(btnParent, helpParent, fakeSetting);
		end

		function listAllOptions()
			local fnName = 'Create' .. ((canUseRadioButtons and 'RadioButton') or 'CheckBox');
			local radioBtnGroup;

			if not vert5 then
				vert5 = UI.CreateVerticalLayoutGroup(vert4);
			end

			if canUseRadioButtons then
				-- radio button group should not contain any children
				-- because it is not a layout group
				radioBtnGroup = UI.CreateRadioButtonGroup(vert5);
			end

			for a, option in ipairs(setting.controls) do
				local horz2 = UI.CreateHorizontalLayoutGroup(UI.CreateVerticalLayoutGroup(vert5));
				local i = a;
				local isSelectedCheckbox = i == initialSettingValue;
				local checkbox = UI[fnName](horz2)
					.SetText('')
					.SetIsChecked(isSelectedCheckbox);

				if canUseRadioButtons then
					checkbox.SetGroup(radioBtnGroup);
				end

				makeLabelFromOption(horz2, option);
				makeLabelHelpFromOption(horz2, UI.CreateVerticalLayoutGroup(vert5), option, a);

				if isSelectedCheckbox then
					Mod.Settings[setting.name] = i;
					selectedCheckbox = checkbox;

					if selectedRadioButtonLabel then
						updateLabelWithOption(option);
					end
				end

				checkbox.SetOnValueChanged(function()
					Mod.Settings[setting.name] = i;

					if selectedCheckbox then
						selectedCheckbox.SetIsChecked(false);
					end

					selectedCheckbox = checkbox;

					if selectedRadioButtonLabel then
						updateLabelWithOption(option);
					end
				end);
			end
		end

		createLabel(horz1, setting);
		createHelpBtn(horz1, UI.CreateVerticalLayoutGroup(vert2), setting);

		vert3 = UI.CreateVerticalLayoutGroup(vert2);
		vert4 = UI.CreateVerticalLayoutGroup(vert2);

		if canUseUIElementIsDestroyed then
			local initialSelectedOption = setting.controls[initialSettingValue];

			selectedRadioButtonLabel = makeLabelFromOption(horz1, initialSelectedOption);

			selectedRadioButtonHelpHelpParent = UI.CreateVerticalLayoutGroup(vert3);
			selectedRadioButtonHelp = makeLabelHelpFromOption(horz1, selectedRadioButtonHelpHelpParent, initialSelectedOption, -1);

			createExpandCollaseBtn(
				horz,
				true,
				function()
					-- if theres an error dont allow options to collapse

					return save();
				end,
				function()
					if not UI.IsDestroyed(vert5) then
						UI.Destroy(vert5);
						vert5 = nil;
					end
				end,
				listAllOptions
			);
		else
			listAllOptions();
		end
	elseif setting.inputType == 'bool' then
		-- colors dont take affect on checkbox labels
		-- so use empty checkbox label and make an actual label

		GLOBALS[setting.name] = UI.CreateCheckBox(horz)
			.SetText('')
			.SetIsChecked(initialSettingValue);

		createLabel(horz, setting);

		local vert3 = UI.CreateVerticalLayoutGroup(vert2);

		createHelpBtn(horz, UI.CreateVerticalLayoutGroup(vert3), setting);
		cpcDoSettingBoolSubsettings(setting, horz, vert3);
	else
		createLabel(horz, setting);
		createHelpBtn(horz, vert2, setting);

		if setting.inputType == 'text' then
			makeTextInput(setting, horz, initialSettingValue);
		elseif setting.inputType == 'int' or setting.inputType == 'float' then
			makeNumberInput(setting, horz, initialSettingValue);
		end
	end
end

function createLabel(parent, options)
	local label = UI.CreateLabel(parent).SetText(options.label);

	if options.labelColor then
		label.SetColor(options.labelColor);
	end

	return label;
end

function createHelpBtn(btnParent, helpParent, setting)
	if not setting.help then
		return;
	end

	-- not defining showHelp and hideHelp in this function because
	-- reference to createHelpBtn params needed to make sure that the click is called using correct references	

	return UI.CreateButton(btnParent)
		.SetText('?')
		.SetColor('#23A0FF')
		.SetOnClick(
			function()
				if not canUseUIElementIsDestroyed then
					if not settingHelpAreas[setting.name] then
						showHelp(setting, helpParent);
					end
				elseif UI.IsDestroyed(settingHelpAreas[setting.name]) then
					showHelp(setting, helpParent);
				else
					hideHelp(setting);
				end
			end
		);
end

function showHelp(setting, helpParent)
	settingHelpAreas[setting.name] = UI.CreateVerticalLayoutGroup(helpParent);
	setting.help(settingHelpAreas[setting.name]);
end

function hideHelp(setting)
	UI.Destroy(settingHelpAreas[setting.name]);
	settingHelpAreas[setting.name] = nil;
end

function createExpandCollaseBtn(parent, startCollapsed, onBeforeExpandOrCollapse, onCollapse, onExpand)
	local expandCollapseBtn = UI.CreateButton(parent);
	local startText = (startCollapsed and getExpandBtnLabelTxt()) or getCollapseBtnLabelTxt();
	local isCollapsed = startCollapsed;

	expandCollapseBtn.SetColor('#23A0FF');
	expandCollapseBtn.SetText(startText);
	expandCollapseBtn.SetOnClick(function()
		if not onBeforeExpandOrCollapse() then
			return;
		end

		if canUseUIElementIsDestroyed then
			if isCollapsed then
				expandCollapseBtn.SetText(getCollapseBtnLabelTxt());
			else
				expandCollapseBtn.SetText(getExpandBtnLabelTxt());
			end

			onCollapse();
		else
			expandCollapseBtn.SetText(getCollapseBtnLabelTxt());
		end

		if isCollapsed then
			onExpand();
		end

		isCollapsed = not isCollapsed;
	end);

	return expandCollapseBtn;
end

function cpcDoSettingBoolSubsettings(setting, horz, vert)
	if not setting.subsettings then
		return;
	end

	local expandCollapseBtn = nil;
	local subsettingEnabledOrDisabled;
	local vert2 = nil;
	local makeExpandCollapseBtn = function()
		expandCollapseBtn = createExpandCollaseBtn(
			horz,
			false,
			function()
				-- if theres an error dont allow settings to collapse

				return save();
			end,
			function()
				if not UI.IsDestroyed(vert2) then
					UI.Destroy(vert2);
					vert2 = nil;
				end
			end,
			subsettingEnabledOrDisabled
		);
	end

	subsettingEnabledOrDisabled = function()
		if not canUseUIElementIsDestroyed then
			if not expandCollapseBtn then
				makeExpandCollapseBtn();
			end

			if not vert2 then
				vert2 = UI.CreateVerticalLayoutGroup(vert);
				cpc(vert2, setting.subsettings);
			end
		elseif GLOBALS[setting.name].GetIsChecked() then
			if UI.IsDestroyed(expandCollapseBtn) then
				makeExpandCollapseBtn();
			end

			vert2 = UI.CreateVerticalLayoutGroup(vert);
			cpc(vert2, setting.subsettings);
		elseif not UI.IsDestroyed(vert2) then
			UI.Destroy(expandCollapseBtn);
			UI.Destroy(vert2);
		end
	end

	GLOBALS[setting.name].SetOnValueChanged(subsettingEnabledOrDisabled);

	if (
		canUseUIElementIsDestroyed or (
			not canUseUIElementIsDestroyed and (
				(GLOBALS[setting.name] and GLOBALS[setting.name].GetIsChecked()) or
				Mod.Settings[setting.name] == true or
				setting.defaultValue
			)
		)
	) then
		subsettingEnabledOrDisabled();
	end
end

function makeTextInput(setting, horz, initialSettingValue)
	GLOBALS[setting.name] = UI.CreateTextInputField(horz).SetText(initialSettingValue);

	if setting.placeholder then
		GLOBALS[setting.name].SetPlaceholderText(setting.placeholder);
	end

	if setting.charLimit then
		GLOBALS[setting.name].SetCharacterLimit(setting.charLimit);
	end
end

function makeNumberInput(setting, horz, initialSettingValue)
	GLOBALS[setting.name] = UI.CreateNumberInputField(horz);

	if setting.inputType == 'float' then
		GLOBALS[setting.name].SetWholeNumbers(false);
	end

	GLOBALS[setting.name]
		.SetSliderMinValue(setting.minValue)
		.SetSliderMaxValue(setting.maxValue)
		.SetValue(initialSettingValue);
end