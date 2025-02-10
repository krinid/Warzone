-- copied from https://github.com/DanWaLes/Warzone/tree/master/mods/libs/ui

-- shorthand function names

function Empty(parent)
	return UI.CreateEmpty(parent);
end

function Vert(parent)
	return UI.CreateVerticalLayoutGroup(parent);
end

function Horz(parent)
	return UI.CreateHorizontalLayoutGroup(parent);
end

function Label(parent)
	return UI.CreateLabel(parent);
end

function Btn(parent)
	return UI.CreateButton(parent);
end

function Checkbox(parent)
	return UI.CreateCheckBox(parent);
end

function TextInput(parent)
	return UI.CreateTextInputField(parent);
end

function NumInput(parent)
	return UI.CreateNumberInputField(parent);
end

-- useful structures

function Tabs(parent, dir, tabLabels, tabsClicked)
	local container = parent;

	if dir == Vert then
		container = Horz(parent);
	end

	local tabData = {
		tabsContainer = dir(container),
		tabBtns = {},
		selectedTab = nil,
		tabContents = nil,
	};

	tabData.tabClicked = function(label, main)
		if tabData.selectedTab then
			tabData.tabBtns[tabData.selectedTab].SetInteractable(true);
		end

		tabData.selectedTab = label;
		tabData.tabBtns[label].SetInteractable(false);

		if not UI.IsDestroyed(tabData.tabContents) then
			UI.Destroy(tabData.tabContents);
		end

		tabData.tabContents = Vert(container);

		main(tabData);
	end

	local map = {};
	tabData.clickTab = function(label)
		tabData.tabClicked(label, tabsClicked[map[label]]);
	end

	for i, label in ipairs(tabLabels) do
		map[label] = i;

		local tabBtn = Btn(tabData.tabsContainer).SetText(label);
		tabBtn.SetFlexibleWidth(1);
		tabBtn.SetOnClick(function() 
			tabData.clickTab(label);
		end);

		tabData.tabBtns[label] = tabBtn;
	end

	return tabData;
end
