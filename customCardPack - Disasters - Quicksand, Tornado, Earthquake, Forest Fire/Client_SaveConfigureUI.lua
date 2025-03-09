require("utilities");

function Client_SaveConfigureUI(alert, addCard)
	loadActiveModules_SaveConfigUI(); --load the code to identify which cards are active for this mod
	updateModSettingsFromUI(); -- update Mod.Settings values from the UI
	createCards_originalCCP_cards(alert, addCard);
	createCards_newCards(alert, addCard);
end

function loadActiveModules_SaveConfigUI ()
	--print ("activeModules loaded? "..tostring(activeModules~=nil));
	local strActiveModules = "";
	for k,_ in pairs(activeModules) do
		--print (k.."="..tostring(v));
		if (strActiveModules~="") then strActiveModules = strActiveModules..","..k;
		else strActiveModules = strActiveModules..k;
		end
	end
	print ("Active Modules: "..strActiveModules);

	Mod.Settings.ActiveModules = {}; --initialize this so assigning properties to it doesn't throw an error
	if (activeModules["Nuke"] == true) then Mod.Settings.ActiveModules.Nuke = true; end
	if (activeModules["Pestilence"] == true) then Mod.Settings.ActiveModules.Pestilence = true; end
	if (activeModules["Isolation"] == true) then Mod.Settings.ActiveModules.Isolation = true; end
	if (activeModules["Shield"] == true) then Mod.Settings.ActiveModules.Shield = true; end
	if (activeModules["Monolith"] == true) then Mod.Settings.ActiveModules.Monolith = true; end
	if (activeModules["Phantom"] == true) then Mod.Settings.ActiveModules.Phantom = true; end
	if (activeModules["Neutralize"] == true) then Mod.Settings.ActiveModules.Neutralize = true; end
	if (activeModules["Deneutralize"] == true) then Mod.Settings.ActiveModules.Deneutralize = true; end
	if (activeModules["Card Block"] == true) then Mod.Settings.ActiveModules.CardBlock = true; end
	if (activeModules["Card Pieces"] == true) then Mod.Settings.ActiveModules.CardPieces = true; end
	if (activeModules["Card Hold"] == true) then Mod.Settings.ActiveModules.CardHold = true; end
	if (activeModules["Tornado"] == true) then Mod.Settings.ActiveModules.Tornado = true; end
	if (activeModules["Quicksand"] == true) then Mod.Settings.ActiveModules.Quicksand = true; end
	if (activeModules["Airstrike"] == true) then Mod.Settings.ActiveModules.Airstrike = true; end
	if (activeModules["Forest Fire"] == true) then Mod.Settings.ActiveModules.ForestFire = true; end
	if (activeModules["Earthquake"] == true) then Mod.Settings.ActiveModules.Earthquake = true; end
end

function createCards_newCards(alert, addCard);
	--print ("START create new cards");

	if Mod.Settings.ShieldEnabled == true then
		print("Shield settings:")
		print("ShieldEnabled="..tostring(Mod.Settings.ShieldEnabled))
		print("ShieldDuration="..tostring(Mod.Settings.ShieldDuration))
		print("ShieldPiecesNeeded="..tostring(Mod.Settings.ShieldPiecesNeeded))
		print("ShieldStartPieces="..tostring(Mod.Settings.ShieldStartPieces))
		print("ShieldPiecesPerTurn="..tostring(Mod.Settings.ShieldPiecesPerTurn))
		print("ShieldWeight="..tostring(Mod.Settings.ShieldWeight))

		local strShieldDesc = "A special immovable unit deployed to a territory that does no damage but can't be killed and absorbs all incoming regular damage to the territory it resides on. A territory cannot be captured while a Shield unit resides on it. ";
		if (Mod.Settings.ShieldDuration == -1) then
			strShieldDesc = strShieldDesc .. "Shields never expire.";
		else
			strShieldDesc = strShieldDesc .. "Shields last " .. Mod.Settings.ShieldDuration .. " turn"..plural(Mod.Settings.ShieldDuration) .." before expiring.";
		end
		Mod.Settings.ShieldCardID = addCard("Shield", strShieldDesc, "shield_130x180.png", Mod.Settings.ShieldPiecesNeeded, Mod.Settings.ShieldPiecesPerTurn, Mod.Settings.ShieldStartPieces, Mod.Settings.ShieldCardWeight, Mod.Settings.ShieldDuration);
		Mod.Settings.ShieldDescription = strShieldDesc;
	end

	if Mod.Settings.MonolithEnabled == true then
		print("Monolith settings:")
		print("MonolithEnabled="..tostring(Mod.Settings.MonolithEnabled))
		print("MonolithDuration="..tostring(Mod.Settings.MonolithDuration))
		print("MonolithPiecesNeeded="..tostring(Mod.Settings.MonolithPiecesNeeded))
		print("MonolithStartPieces="..tostring(Mod.Settings.MonolithStartPieces))
		print("MonolithPiecesPerTurn="..tostring(Mod.Settings.MonolithPiecesPerTurn))
		print("MonolithWeight="..tostring(Mod.Settings.MonolithWeight))

		local strMonolithDesc = "A special immovable unit deployed to a territory that does no damage but cannot be killed. A territory cannot be captured while a Monolith unit resides on it, but the Monolith does not protect any units that are on the territory. All the units residing on the territory can be normally attacked and destroyed, and the Monolith will remain. ";
		if (Mod.Settings.MonolithDuration == -1) then
				strMonolithDesc = strMonolithDesc .. "Monoliths never expire.";
		else
				strMonolithDesc = strMonolithDesc .. "Monoliths last " ..Mod.Settings.MonolithDuration .." turn"..plural(Mod.Settings.MonolithDuration) .." before expiring.";
		end
		Mod.Settings.MonolithCardID = addCard("Monolith", strMonolithDesc, "monolith v2 130x180.png", Mod.Settings.MonolithPiecesNeeded, Mod.Settings.MonolithPiecesPerTurn, Mod.Settings.MonolithStartPieces, Mod.Settings.MonolithWeight, Mod.Settings.MonolithDuration);
	end

	if Mod.Settings.CardBlockEnabled == true then
		print("Card Block settings:")
		print("CardBlockEnabled="..tostring(Mod.Settings.CardBlockEnabled))
		print("CardBlockDuration="..tostring(Mod.Settings.CardBlockDuration))
		print("CardBlockPiecesNeeded="..tostring(Mod.Settings.CardBlockPiecesNeeded))
		print("CardBlockStartPieces="..tostring(Mod.Settings.CardBlockStartPieces))
		print("CardBlockPiecesPerTurn="..tostring(Mod.Settings.CardBlockPiecesPerTurn))

		local strCardBlockDesc = "Block an opponent from playing cards ";
		if (Mod.Settings.CardBlockDuration == -1) then
				strCardBlockDesc = strCardBlockDesc .. "permanently.";
		else
				strCardBlockDesc = strCardBlockDesc .. "for " .. Mod.Settings.CardBlockDuration .. " turn"..plural(Mod.Settings.CardBlockDuration)..".";
		end

		Mod.Settings.CardBlockCardID = addCard("Card Block", strCardBlockDesc, "Card Block_blueback_130x180.png", Mod.Settings.CardBlockPiecesNeeded, Mod.Settings.CardBlockPiecesPerTurn, Mod.Settings.CardBlockStartPieces, Mod.Settings.CardBlockCardWeight, Mod.Settings.CardBlockDuration);      
	end

	if Mod.Settings.CardPiecesEnabled == true then
		print("Card Pieces settings:")
		print("CardPiecesEnabled="..tostring(Mod.Settings.CardPiecesEnabled))
		print("CardPiecesNumWholeCardsToGrant="..tostring(Mod.Settings.CardPiecesNumWholeCardsToGrant))
		print("CardPiecesNumCardPiecesToGrant="..tostring(Mod.Settings.CardPiecesNumCardPiecesToGrant))
		print("CardPiecesPiecesNeeded="..tostring(Mod.Settings.CardPiecesPiecesNeeded))
		print("CardPiecesStartPieces="..tostring(Mod.Settings.CardPiecesStartPieces))
		print("CardPiecesPerTurn="..tostring(Mod.Settings.CardPiecesPerTurn))

		local strCardPiecesDesc = "Receive "..Mod.Settings.CardPiecesNumWholeCardsToGrant.." whole card".. plural(Mod.Settings.CardPiecesNumWholeCardsToGrant).." and "..Mod.Settings.CardPiecesNumCardPiecesToGrant.." card piece"..plural(Mod.Settings.CardPiecesNumCardPiecesToGrant).." of a card of your choice.\n\nCard Pieces cards cannot be used to redeem pieces of Card Piece cards or pieces.";
		Mod.Settings.CardPiecesCardID = addCard("Card Piece", strCardPiecesDesc, "Card Pieces_greenback_130x180.png", Mod.Settings.CardPiecesPiecesNeeded, Mod.Settings.CardPiecesPiecesPerTurn, Mod.Settings.CardPiecesStartPieces, Mod.Settings.CardPiecesCardWeight);      
	end

	if Mod.Settings.NeutralizeEnabled == true then
		print("Neutralize settings:")
		print("NeutralizeEnabled="..tostring(Mod.Settings.NeutralizeEnabled))
		print("NeutralizeDuration="..tostring(Mod.Settings.NeutralizeDuration))
		print("NeutralizeCanUseOnCommander="..tostring(Mod.Settings.NeutralizeCanUseOnCommander))
		print("NeutralizeCanUseOnSpecials="..tostring(Mod.Settings.NeutralizeCanUseOnSpecials))
		print("NeutralizePiecesNeeded="..tostring(Mod.Settings.NeutralizePiecesNeeded))
		print("NeutralizeStartPieces="..tostring(Mod.Settings.NeutralizeStartPieces))
		print("NeutralizePiecesPerTurn="..tostring(Mod.Settings.NeutralizePiecesPerTurn))

		local strNeutralizeDesc = "Turn a territory owned by a player to neutral ";
		if (Mod.Settings.NeutralizeDuration>=1) then
				strNeutralizeDesc = strNeutralizeDesc .. "for " .. Mod.Settings.NeutralizeDuration .. " turns. If it is still neutral at that time, it will revert ownership to the prior owner.";
		else
				strNeutralizeDesc = strNeutralizeDesc .. "permanently.";
		end

		strNeutralizeDesc = strNeutralizeDesc .. "\n\n";
		if (Mod.Settings.NeutralizeCanUseOnCommander == true and Mod.Settings.NeutralizeCanUseOnSpecials == true) then
				strNeutralizeDesc = strNeutralizeDesc .. "Territories with commanders or other special units can be targeted.";
		elseif (Mod.Settings.NeutralizeCanUseOnSpecials  == true) then
				strNeutralizeDesc = strNeutralizeDesc .. "Territories with commanders can't be targeted, but territories with other special units can be targeted.";
		elseif (Mod.Settings.NeutralizeCanUseOnCommander == true) then
				strNeutralizeDesc = strNeutralizeDesc .. "Territories with commanders can be targeted, but territories with other special units can't be targeted. ";
		else
				strNeutralizeDesc = strNeutralizeDesc .. "Territories with special units of any type including commanders can't be targeted.";
		end

		Mod.Settings.NeutralizeCardID = addCard("Neutralize", strNeutralizeDesc, "neutralize_greyback2_130x180.png", Mod.Settings.NeutralizePiecesNeeded, Mod.Settings.NeutralizePiecesPerTurn, Mod.Settings.NeutralizeStartPieces, Mod.Settings.NeutralizeCardWeight, Mod.Settings.NeutralizeDuration);
	end

	if Mod.Settings.DeneutralizeEnabled == true then
		print("Deneutralize settings:")
		print("DeneutralizeEnabled="..tostring(Mod.Settings.DeneutralizeEnabled))
		print("CanUseOnNeutralizedTerritories="..tostring(Mod.Settings.DeneutralizeCanUseOnNeutralizedTerritories))
		print("CanUseOnNaturalNeutrals="..tostring(Mod.Settings.DeneutralizeCanUseOnNaturalNeutrals))
		print("DeneutralizeCanUseOnCommander="..tostring(Mod.Settings.NeutralizeCanUseOnCommander))
		print("DeneutralizeCanUseOnSpecials="..tostring(Mod.Settings.NeutralizeCanUseOnSpecials))
		print("DeneutralizePiecesNeeded="..tostring(Mod.Settings.DeneutralizePiecesNeeded))
		print("DeneutralizeStartPieces="..tostring(Mod.Settings.DeneutralizeStartPieces))
		print("DeneutralizePiecesPerTurn="..tostring(Mod.Settings.DeneutralizePiecesPerTurn))

		local strDeneutralizeDesc = "Take ownership of a neutral territory. ";
		if ((Mod.Settings.DeneutralizeCanUseOnNeutralizedTerritories == true) and (Mod.Settings.DeneutralizeCanUseOnNaturalNeutrals == true)) then
				strDeneutralizeDesc = strDeneutralizeDesc .. "This can be done on either natural neutral territories, or territories that were Neutralized (used a Neutralize card).";
		elseif ((Mod.Settings.DeneutralizeCanUseOnNeutralizedTerritories == true) and (Mod.Settings.DeneutralizeCanUseOnNaturalNeutrals == false)) then
				strDeneutralizeDesc = strDeneutralizeDesc .. "This can only be done on territories that were Neutralized (used a Neutralize card).";
		elseif ((Mod.Settings.DeneutralizeCanUseOnNeutralizedTerritories == false) and (Mod.Settings.DeneutralizeCanUseOnNaturalNeutrals == true)) then
				strDeneutralizeDesc = strDeneutralizeDesc .. "This can only be done on natural neutral territories (started as neutrals, were blockaded, etc).";
		else
				--this means both settings are false, which doesn't make sense, the card would never be able to be played; spawn error and cancel
				alert('Deneutralize cards must apply to natural neutral territories, Neutralized territories by use of a Neutralize card, or both options.');
		end
		Mod.Settings.DeneutralizeCardID = addCard("Deneutralize", strDeneutralizeDesc, "deneutralize_greenback2_130x180.png", Mod.Settings.DeneutralizePiecesNeeded, Mod.Settings.DeneutralizePiecesPerTurn, Mod.Settings.DeneutralizeStartPieces, Mod.Settings.DeneutralizeCardWeight);
	end

	if Mod.Settings.EarthquakeEnabled == true then
		print("Earthquake settings:")
		print("EarthquakeEnabled="..tostring(Mod.Settings.EarthquakeEnabled))
		print("EarthquakeDuration="..tostring(Mod.Settings.EarthquakeDuration))
		print("EarthquakeStrength="..tostring(Mod.Settings.EarthquakeStrength))
		print("EarthquakeDeltaEachTurn="..tostring(Mod.Settings.EarthquakeDeltaEachTurn))
		print("EarthquakeAffectsNeutrals="..tostring(Mod.Settings.EarthquakeAffectsNeutrals))
		print("EarthquakePiecesNeeded="..tostring(Mod.Settings.EarthquakePiecesNeeded))
		print("EarthquakeStartPieces="..tostring(Mod.Settings.EarthquakeStartPieces))
		print("EarthquakePiecesPerTurn="..tostring(Mod.Settings.EarthquakePiecesPerTurn))

		local strEarthquakeDesc = "Invoke an earthquake that causes "..Mod.Settings.EarthquakeStrength.." damage to all territories in a selected bonus for " .. Mod.Settings.EarthquakeDuration .. " turn" .. plural(Mod.Settings.EarthquakeDuration) .. ". ";
		if (Mod.Settings.EarthquakeDuration == -1) then
		strEarthquakeDesc = strEarthquakeDesc .. "The effect is permanent.";
		end
		Mod.Settings.EarthquakeCardID = addCard("Earthquake", strEarthquakeDesc, "earthquake_130x180.png", Mod.Settings.EarthquakePiecesNeeded, Mod.Settings.EarthquakePiecesPerTurn, Mod.Settings.EarthquakeStartPieces, Mod.Settings.EarthquakeCardWeight, Mod.Settings.EarthquakeDuration);
	end

	if Mod.Settings.TornadoEnabled == true then
		print("Tornado settings:")
		print("TornadoEnabled="..tostring(Mod.Settings.TornadoEnabled))
		print("TornadoDuration="..tostring(Mod.Settings.TornadoDuration))
		print("TornadoStrength="..tostring(Mod.Settings.TornadoStrength))
		print("TornadoPiecesNeeded="..tostring(Mod.Settings.TornadoPiecesNeeded))
		print("TornadoStartPieces="..tostring(Mod.Settings.TornadoStartPieces))
		print("TornadoPiecesPerTurn="..tostring(Mod.Settings.TornadoNumPiecesPerTurn))

		local strTornadoDesc = "Cause a tornado to develop on a territory, causing ".. Mod.Settings.TornadoStrength.." damage ";
		if (Mod.Settings.TornadoDuration == -1) then
				strTornadoDesc = strTornadoDesc .. "per turn. The tornado continues permanently.";
		else
				strTornadoDesc = strTornadoDesc .. "for " .. Mod.Settings.TornadoDuration .. " turn" .. plural(Mod.Settings.TornadoDuration) .. ".";
		end
		strTornadoDesc = strTornadoDesc .. " The first turn of tornado will do double damage.";
		Mod.Settings.TornadoCardID = addCard("Tornado", strTornadoDesc, "tornado_130x180.png", Mod.Settings.TornadoPiecesNeeded, Mod.Settings.TornadoPiecesPerTurn, Mod.Settings.TornadoStartPieces, Mod.Settings.TornadoCardWeight, Mod.Settings.TornadoDuration);
	end

	if Mod.Settings.QuicksandEnabled == true then
		print("Quicksand settings:")
		print("QuicksandEnabled="..tostring(Mod.Settings.QuicksandEnabled))
		print("QuicksandDuration="..tostring(Mod.Settings.QuicksandDuration))
		print("QuicksandBlockEntryIntoTerritory="..tostring(Mod.Settings.QuicksandBlockEntryIntoTerritory))
		print("QuicksandBlockAirliftsIntoTerritory="..tostring(Mod.Settings.QuicksandBlockAirliftsIntoTerritory))
		print("QuicksandBlockAirliftsFromTerritory="..tostring(Mod.Settings.QuicksandBlockAirliftsFromTerritory))
		print("QuicksandBlockExitFromTerritory="..tostring(Mod.Settings.QuicksandBlockExitFromTerritory))
		print("QuicksandDefenderDamageTakenModifier="..tostring(Mod.Settings.QuicksandDefenderDamageTakenModifier))
		print("QuicksandAttackerDamageTakenModifier="..tostring(Mod.Settings.QuicksandAttackerDamageTakenModifier))
		print("QuicksandPiecesNeeded="..tostring(Mod.Settings.QuicksandPiecesNeeded))
		print("QuicksandStartPieces="..tostring(Mod.Settings.QuicksandStartPieces))
		print("QuicksandPiecesPerTurn="..tostring(Mod.Settings.QuicksandPiecesPerTurn))

		local strQuicksandDesc = "Transform a territory into quicksand ";
		if (Mod.Settings.QuicksandDuration == -1) then
				strQuicksandDesc = strQuicksandDesc .. "The effect is permanent.";
		else
				strQuicksandDesc = strQuicksandDesc .. "for " .. Mod.Settings.QuicksandDuration .. " turn" .. plural(Mod.Settings.QuicksandDuration) .. ".";
		end
		strQuicksandDesc = strQuicksandDesc .. "\n\nAttacks and transfers into the territory can still occur, but none can be executed from the territory while quicksand remains active. Units caught in quicksand do "..Mod.Settings.QuicksandAttackerDamageTakenModifier.."x less damage to attackers, and defending armies sustain "..Mod.Settings.QuicksandDefenderDamageTakenModifier.."x more damage when attacked.";
		Mod.Settings.QuicksandCardID = addCard("Quicksand", strQuicksandDesc, "quicksand_v3_130x180.png", Mod.Settings.QuicksandPiecesNeeded, Mod.Settings.QuicksandPiecesPerTurn, Mod.Settings.QuicksandStartPieces, Mod.Settings.QuicksandCardWeight, Mod.Settings.QuicksandDuration);
	end

	if Mod.Settings.AirstrikeEnabled == true then
		print("Airstrike settings:")
		print("AirstrikeEnabled="..tostring(Mod.Settings.AirstrikeEnabled))
		print("AirstrikeCanTargetNeutrals="..tostring(Mod.Settings.AirstrikeCanTargetNeutrals))
		print("AirstrikeCanTargetPlayers="..tostring(Mod.Settings.AirstrikeCanTargetPlayers))
		print("AirstrikeCanTargetFoggedTerritories="..tostring(Mod.Settings.AirstrikeCanTargetFoggedTerritories))
		print("AirstrikePiecesNeeded="..tostring(Mod.Settings.AirstrikePiecesNeeded))
		print("AirstrikeStartPieces="..tostring(Mod.Settings.AirstrikeStartPieces))
		print("AirstrikePiecesPerTurn="..tostring(Mod.Settings.AirstrikePiecesPerTurn))

		local strAirstrikeDesc = "Launch an attack on a territory that you don't need to border";
		Mod.Settings.AirstrikeCardID = addCard("Airstrike", strAirstrikeDesc, "airstrike_130x180.png", Mod.Settings.AirstrikePiecesNeeded, Mod.Settings.AirstrikePiecesPerTurn, Mod.Settings.AirstrikeStartPieces, Mod.Settings.AirstrikeCardWeight);
	end

	if Mod.Settings.ForestFireEnabled == true then
		print("Forest Fire settings:")
		print("ForestFireEnabled="..tostring(Mod.Settings.ForestFireEnabled))
		print("ForestFireDuration="..tostring(Mod.Settings.ForestFireDuration))
		print("ForestFireDamage="..tostring(Mod.Settings.ForestFireDamage))
		print("ForestFireDamageDeltaWithSpread="..tostring(Mod.Settings.ForestFireDamageDeltaWithSpread))
		print("ForestFireAffectsNeutrals="..tostring(Mod.Settings.ForestFireAffectsNeutrals))
		print("ForestFirePiecesNeeded="..tostring(Mod.Settings.ForestFirePiecesNeeded))
		print("ForestFireStartPieces="..tostring(Mod.Settings.ForestFireStartPieces))
		print("ForestFirePiecesPerTurn="..tostring(Mod.Settings.ForestFirePiecesPerTurn))

		local strForestFireDesc = "Start a forest fire that spreads farther each turn"; ---&&& add details of FF specs
		Mod.Settings.ForestFireCardID = addCard("Forest Fire", strForestFireDesc, "forest fire_130x180.png", Mod.Settings.ForestFirePiecesNeeded, Mod.Settings.ForestFirePiecesPerTurn, Mod.Settings.ForestFireStartPieces, Mod.Settings.ForestFireCardWeight, Mod.Settings.ForestFireDuration);
	end
	--print ("END   create new cards");
end

function createCards_originalCCP_cards (alert, addCard)
	-- create Nuke card
	if (Mod.Settings.NukeEnabled == true) then
		print ("Nuke settings:");
		print ("NukeCardEnabled="..tostring(Mod.Settings.NukeEnabled));
		print ("NukeCardMainTerritoryPercentDamage="..tostring(Mod.Settings.NukeCardMainTerritoryPercentDamage));
		print ("NukeCardMainTerritoryFixedDamage="..tostring(Mod.Settings.NukeCardMainTerritoryFixedDamage));
		print ("NukeCardConnectedTerritoryPercectDamage="..tostring(Mod.Settings.NukeCardConnectedTerritoryPerfectDamage));
		print ("NukeCardConnectedTerritoryFixedDamage="..tostring(Mod.Settings.NukeCardConnectedTerritoryFixedDamage));
		print ("NukeCardNumLevelsConnectedTerritoriesToSpreadTo="..tostring(Mod.Settings.NukeCardNumLevelsConnectedTerritoriesToSpreadTo));
		print ("NukeCardConnectedTerritoriesSpreadDamageDelta="..tostring(Mod.Settings.NukeCardConnectedTerritoriesSpreadDamageDelta));
		print ("NukeFriendlyfire="..tostring(Mod.Settings.NukeFriendlyfire));
		print ("NukeImplementationPhase="..tostring(Mod.Settings.NukeImplementationPhase)); -- when the Nuke occurs within the turn; refer to turn phases as per WL.xxx defintions
		print ("NukeCardPiecesNeeded="..tostring(Mod.Settings.NukeCardPiecesNeeded));
		print ("NukeCardStartPieces="..tostring(Mod.Settings.NukeCardStartPieces));
		print ("NukePiecesPerTurn="..tostring(Mod.Settings.NukePiecesPerTurn));
		print ("NukeCardWeight="..tostring(Mod.Settings.NukeCardWeight));

		--[[if(Mod.Settings.NukeCardMainTerritoryDamage<0 or Mod.Settings.NukeCardConnectedTerritoryDamage<0)then
				alert('Nuke damage must be positive, between 0% and 100% for both main and connected territory settings.');
		end]]
		--[[if (Mod.Settings.NukeCardMainTerritoryDamage>100 or Mod.Settings.NukeCardConnectedTerritoryDamage>100)then
				alert('Nuke damage must be positive, between 0% and 100% for both main and connected territory settings.');
		end]]

		local strNukeDesc = "Launch a nuke on any territory on the map. You do not need to border the territory, nor do you need visibility to the territory.\n\nThe epicenter (targeted territory) will sustain " ..Mod.Settings.NukeCardMainTerritoryDamage .."% + ".. Mod.Settings.NukeCardMainTerritoryFixedDamage.." fixed damage.";

		if Mod.Settings.NukeCardNumLevelsConnectedTerritoriesToSpreadTo ==0 then
				-- blast range == 0, so doesn't spread to any bordering territories
				strNukeDesc = strNukeDesc .. "\n\nNo damage is sustained by surrounding territories.";
		elseif Mod.Settings.NukeCardNumLevelsConnectedTerritoriesToSpreadTo ==1 then
				-- blast range == 1, so hits bordering territories but no further spread beyond those
				strNukeDesc = strNukeDesc .. "\n\nDirectly bordering territories will sustain " .. Mod.Settings.NukeCardConnectedTerritoryDamage .. "% + "..Mod.Settings.NukeCardConnectedTerritoryFixedDamage.." fixed damage. No territories beyond these will be impacted.";
		else  -- blast range is 1+
				-- blast range continues on beyond directly bordering territories
				strNukeDesc = strNukeDesc .. "\n\nDirectly bordering territories will sustain " .. Mod.Settings.NukeCardConnectedTerritoryDamage .. "% + "..Mod.Settings.NukeCardConnectedTerritoryFixedDamage.." fixed damage, and the effect will continue outward for an additional ".. tostring(Mod.Settings.NukeCardNumLevelsConnectedTerritoriesToSpreadTo-1).. " territories, reducing in amount by "..tostring(Mod.Settings.NukeCardConnectedTerritoriesSpreadDamageDelta).."% each time.";
		end

		if (Mod.Settings.NukeFriendlyfire==true) then
				strNukeDesc=strNukeDesc .. "\n\nFriendly Fire is enabled, so you will damage yourself if you own one of the impacted territories.";
		else
				strNukeDesc=strNukeDesc .. "\n\nFriendly Fire is disabled, so you are invulnerable to any damage from nukes you launch yourself.";
		end

		strNukeDesc=strNukeDesc .. "\n\nDamage from a nuke occurs during the "..Mod.Settings.NukeImplementationPhase.." phase of a turn.";

		if (Mod.Settings.NukeCardMainTerritoryDamage < 0 or Mod.Settings.NukeCardConnectedTerritoryDamage < 0 or Mod.Settings.NukeCardMainTerritoryFixedDamage < 0 or Mod.Settings.NukeCardConnectedTerritoryFixedDamage < 0) then
				strNukeDesc = strNukeDesc .. "\n\nNegative damage has been configured, which transforms the result into a Healing Nuke. This will increase army counts on territories instead of reducing them.";
		end

		Mod.Settings.NukeCardID = addCard("Nuke", strNukeDesc, "nuke_card_image_130x180.png", Mod.Settings.NukeCardPiecesNeeded, 1, Mod.Settings.NukeCardStartPieces, Mod.Settings.NukeCardWeight);
		if Mod.Settings.NukeCardID == nil then
				print ("Nuke cardID is nil");
		else
				print ("Nuke cardID="..tostring (Mod.Settings.PestCardID).."::"); 
		end
	end

	-- create Pestilence card
	if (Mod.Settings.PestilenceEnabled==true) then
		print ("Pestilence settings:");
		print ("PestCardEnabled="..tostring(Mod.Settings.PestilenceEnabled));
		print ("PestilenceDuration="..tostring(Mod.Settings.PestilenceDuration));
		print ("PestCardStrength="..tostring(Mod.Settings.PestilenceStrength));
		print ("PestCardPiecesNeeded="..tostring(Mod.Settings.PestilencePiecesNeeded));
		print ("PestCardStartPieces="..tostring(Mod.Settings.PestilenceStartPieces));
		print ("PestCardPiecesPerTurn="..tostring(Mod.Settings.PestilencePiecesPerTurn));
		print ("PestilenceCardWeight="..tostring(Mod.Settings.PestilenceCardWeight));

		local strPlural_units = "";
		local strPlural_duration = "";

		if (Mod.Settings.PestilenceDuration > 1) then strPlural_duration = "s"; end
		if (Mod.Settings.PestilenceStrength > 1) then strPlural_units = "s"; end
		local strPestilenceDesc = "Invoke pestilence on another player, reducing each of their territories by "..Mod.Settings.PestilenceStrength.." unit"..strPlural_units.." for " .. Mod.Settings.PestilenceDuration .. " turn"..strPlural_duration..".\n\nIf a territory is reduced to 0 armies, it will turn neutral.\n\nSpecial units are not affected by Pestilence, and will prevent a territory from turning to neutral.";

		--[[Mod.Settings.PestilencePiecesPerTurn = 1;
		-- Print the values of each variable
		print("Mod.Settings.PestilenceDuration:", Mod.Settings.PestilenceDuration)
		print("Mod.Settings.PestilencePiecesNeeded:", Mod.Settings.PestilencePiecesNeeded)
		print("Mod.Settings.PestilencePiecesPerTurn:", Mod.Settings.PestilencePiecesPerTurn)
		print("Mod.Settings.PestilenceStartPieces:", Mod.Settings.PestilenceStartPieces)
		print("strPestilenceDesc:", strPestilenceDesc)]]
		--Mod.Settings.PestilenceCardID = addCard("Pestilence", strPestilenceDesc, "pestilence_130x180.png", Mod.Settings.PestilencePiecesNeeded, Mod.Settings.PestilencePiecesPerTurn, Mod.Settings.PestilenceStartPieces, Mod.Settings.PestilenceCardWeight, Mod.Settings.PestilenceDuration+1); --create actual WZ card construct, Duration+1 b/c WZ counts from time of play which actually includes the Warning turn, so add 1 to get the full duration (so it shows up in Active Cards with accurate end turn data)
		Mod.Settings.PestilenceCardID = addCard("Pestilence", strPestilenceDesc, "pestilence_130x180.png", Mod.Settings.PestilencePiecesNeeded, Mod.Settings.PestilencePiecesPerTurn, Mod.Settings.PestilenceStartPieces, 1.0, Mod.Settings.PestilenceDuration); --create actual WZ card construct

		if Mod.Settings.PestilenceCardID == nil then
				print ("Pestilence cardID is nil");
		else
				print ("Pestilence cardID="..tostring (Mod.Settings.PestilenceCardID).."::"); 
		end
	end

	-- create Isolation card
	if (Mod.Settings.IsolationEnabled==true) then
		print ("Isolation settings:");
		print ("IsolationEnabled="..tostring(Mod.Settings.IsolationEnabled));
		print ("IsolationDuration="..tostring(Mod.Settings.IsolationDuration));
		print ("IsolationPiecesNeeded="..tostring(Mod.Settings.IsolationPiecesNeeded));
		print ("IsolationStartPieces="..tostring(Mod.Settings.IsolationStartPieces));
		print ("IsolationPiecesPerTurn="..tostring(Mod.Settings.IsolationPiecesPerTurn));

		local strIsolationDesc = "Isolate a territory ";

		if (Mod.Settings.IsolationDuration>=1) then
				strIsolationDesc = strIsolationDesc .. "for "..Mod.Settings.IsolationDuration.." turns.\n\nNo units can attack or transfer to or from the territory during this duration.";
		else
				strIsolationDesc = strIsolationDesc .. "permanently.\n\nNo units can attack or transfer to or from the territory after Isolation is invoked.";
		end

		Mod.Settings.IsolationCardID = addCard("Isolation", strIsolationDesc, "isolation_130x180.png", Mod.Settings.IsolationPiecesNeeded, 1, Mod.Settings.IsolationStartPieces, 1.0, Mod.Settings.IsolationDuration);
		--Mod.Settings.IsolationCardID = addCard("Isolation", strIsolationDesc, "isolation_130x180.png", Mod.Settings.IsolationPiecesNeeded, 1, Mod.Settings.IsolationStartPieces, 1.0, Mod.Settings.IsolationDuration);
		--print (strIsolationDesc);
	end

	-- if no cards are enabled, prompt user to enable one or disable mod (b/c it's not doing anything)
	--[[if (Mod.Settings.NukeEnabled==false and Mod.Settings.PestilenceEnabled==false and Mod.Settings.IsolationEnabled==false) then
				alert("There must be at least one card implemented. Disable this mod if you aren't going to use any of the functionality.");
	end]]
	--[[print (strNukeDesc);
	print (strPestilenceDesc);
	print (strIsolationDesc);]]
end