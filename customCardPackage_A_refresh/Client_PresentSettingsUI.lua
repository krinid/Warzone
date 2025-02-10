function Client_PresentSettingsUI(rootParent)
	root = rootParent;

	if(Mod.Settings.PestilenceEnabled)then
		UI.CreateLabel(rootParent).SetText('[Pestilence Card Settings]');
		CreateLine('Number of pieces to divide the card into: ', Mod.Settings.PestilencePiecesNeeded,10,false);
		CreateLine('Card pieces given to each player at the start: ', Mod.Settings.PestilenceStartPieces,1,false);
		CreateLine('Strength: ', Mod.Settings.PestilenceStrength,1,false);
		CreateLine('(Pestilence will do this amount of damage to all territories of the player it is cast on) ', '','',false);
		UI.CreateLabel(rootParent).SetText(' ');
	end
	if(Mod.Settings.NukeEnabled ~= nil and Mod.Settings.NukeEnabled)then
		UI.CreateLabel(rootParent).SetText('[Nuke Card Settings]');
		CreateLine('Number of pieces to divide the card into: ', Mod.Settings.NukeCardPiecesNeeded,10,false);
		CreateLine('Card pieces given to each player at the start: ', Mod.Settings.NukeCardStartPieces,1,false);
		CreateLine('Territories hit by a nuke take that much damage: ', Mod.Settings.NukeCardMainTerritoryDamage,50,false);
		CreateLine('Connected Territories to a nuke take that much damage: ', Mod.Settings.NukeCardConnectedTerritoryDamage,25,false);
		CreateLine('Players can harm themselves: ', Mod.Settings.Friendlyfire,true,true);
		if(Mod.Settings.AfterDeployment)then
			UI.CreateLabel(rootParent).SetText('Territories get nuked AFTER Deployment but before Gift and Blockade Cards take effect').SetColor('#FF0000');
		else
			UI.CreateLabel(rootParent).SetText('Territories get nuked BEFORE Deployment').SetColor('#FF0000');
		end
		UI.CreateLabel(rootParent).SetText(' ');
	end
	if(Mod.Settings.IsolationEnabled ~= nil and Mod.Settings.IsolationEnabled)then
		UI.CreateLabel(rootParent).SetText('[Isolation Card Settings]');
		CreateLine('Number of pieces to divide the card into: ', Mod.Settings.IsolationPiecesNeeded,4,false);
		CreateLine('Card pieces given to each player at the start: ', Mod.Settings.IsolationStartPieces,1,false);
		CreateLine('Number of turns the effect will last: ', Mod.Settings.IsolationDuration,1,false);
		UI.CreateLabel(rootParent).SetText(' ');
	end
end
function booltostring(variable)
	if(variable)then
		return "Yes";
	else
		return "No";
	end
end
function CreateLine(settingname,variable,default,important)
	local lab = UI.CreateLabel(root);
	if(default == true or default == false)then
		lab.SetText(settingname .. booltostring(variable,default));
	else
		if(variable == nil)then
			lab.SetText(settingname .. default);
		else
			lab.SetText(settingname .. variable);
		end
	end
	if(variable ~= nil and variable ~= default)then
		if(important == true)then
			lab.SetColor('#FF0000');
		else
			lab.SetColor('#FFFF00');
		end
	end
end
function booltostring(variable,default)
	if(variable == nil)then
		if(default)then
			return "Yes";
		else
			return "No";
		end
	end
	if(variable)then
		return "Yes";
	else
		return "No";
	end
end
