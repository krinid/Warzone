
function Client_PresentSettingsUI(rootParent)
	if (Mod.Settings.killPercentage == 0) then
		if (Mod.Settings.delayed) then
			if (Mod.Settings.armiesKilled == 1) then
				UI.CreateLabel(rootParent).SetText("The bomb card kills one enemy troop. The effect happens at the end of your turn.");
			else
				UI.CreateLabel(rootParent).SetText("The bomb card kills ".. Mod.Settings.armiesKilled.." enemy troops. The effect happens at the end of your turn.");
			end
		else
			if (Mod.Settings.armiesKilled == 1) then
				UI.CreateLabel(rootParent).SetText("The bomb card kills one troop.");
			else
			UI.CreateLabel(rootParent).SetText("The bomb card kills ".. Mod.Settings.armiesKilled.." troops.");
			end
		end
	else
		if (Mod.Settings.delayed) then
			UI.CreateLabel(rootParent).SetText("The bomb card kills " .. Mod.Settings.killPercentage .. "% of enemy armies on targeted territory at the end of your turn.");
		else
			UI.CreateLabel(rootParent).SetText("The bomb card kills " .. Mod.Settings.killPercentage .. "% of enemy armies on targeted territory.");
		end
		UI.CreateLabel(rootParent).SetText("Note, that this rounds up (if the card were to kill 0.5 troops, it would have killed 1 troop).");
		if (Mod.Settings.armiesKilled ~= 0) then
			if (Mod.Settings.armiesKilled == 1) then
				UI.CreateLabel(rootParent).SetText("After that, the card kills one additional troop.");
			else
			UI.CreateLabel(rootParent).SetText("After that, the card kills ".. Mod.Settings.armiesKilled.." additional troops.");
			end
		end
	end
	if (Mod.Settings.specialUnits) then
		UI.CreateLabel(rootParent).SetText("If all troops are killed, targeted territory turns neutral, unless there is at least one special unit in the territory. This mod will create fake discard orders.");
	else
		UI.CreateLabel(rootParent).SetText("If all troops are killed, targeted territory turns neutral. This mod will create fake discard orders.");

	end
end

