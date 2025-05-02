require("utilities");
require("UI_Events");

function Client_PresentSettingsUI(rootParent)
	--be vigilant of referencing clientGame.Us when it ==nil for spectators, b/c they CAN initiate this function

	local UImain = CreateVert (rootParent).SetFlexibleWidth(1);

    if (Mod.Settings.NukeEnabled == true) then
        CreateLabel(UImain).SetText("[NUKE]").SetColor(getColourCode("card play heading"));

		local strNukeDesc = "Launch a nuke on any territory on the map. The explosion hits the epicenter and spreads outward."; -- You do not need to border the territory, nor do you need visibility to the territory.\n\nThe epicenter (targeted territory) will sustain " ..Mod.Settings.NukeCardMainTerritoryDamage .."% + ".. Mod.Settings.NukeCardMainTerritoryFixedDamage.." fixed damage.";
		--[[local strNukeDesc = "Launch a nuke on any territory on the map. You do not need to border the territory, nor do you need visibility to the territory.\n\nThe epicenter (targeted territory) will sustain " ..Mod.Settings.NukeCardMainTerritoryDamage .."% + ".. Mod.Settings.NukeCardMainTerritoryFixedDamage.." fixed damage.";
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

		-- &&& put note in here about "healing bomb nukes" for negative damage/delta values
		if (Mod.Settings.NukeCardMainTerritoryDamage < 0 or Mod.Settings.NukeCardConnectedTerritoryDamage < 0 or Mod.Settings.NukeCardMainTerritoryFixedDamage < 0 or Mod.Settings.NukeCardConnectedTerritoryFixedDamage < 0) then
				strNukeDesc = strNukeDesc .. "\n\nNegative damage has been configured, which transforms the result into a Healing Nuke. This will increase army counts on territories instead of reducing them.";
		end]]
        CreateLabel(UImain).SetText(strNukeDesc);
			
        CreateLabel(UImain).SetText("\nEpicenter damage (%): " .. Mod.Settings.NukeCardMainTerritoryDamage);
        CreateLabel(UImain).SetText("Epicenter fixed damage: " .. Mod.Settings.NukeCardMainTerritoryFixedDamage);
        CreateLabel(UImain).SetText("Bordering territory damage (%): " .. Mod.Settings.NukeCardConnectedTerritoryDamage);
        CreateLabel(UImain).SetText("Bordering territory fixed damage: " .. Mod.Settings.NukeCardConnectedTerritoryFixedDamage);
        if (Mod.Settings.NukeCardMainTerritoryDamage < 0 or Mod.Settings.NukeCardMainTerritoryFixedDamage < 0 or Mod.Settings.NukeCardConnectedTerritoryDamage < 0 or Mod.Settings.NukeCardConnectedTerritoryFixedDamage < 0) then
            CreateLabel(UImain).SetText("Note: Negative damage values indicate a healing effect.");
        end
        CreateLabel(UImain).SetText("Blast range (levels): " .. Mod.Settings.NukeCardNumLevelsConnectedTerritoriesToSpreadTo);
        CreateLabel(UImain).SetText("Damage reduction with spread (%): " .. Mod.Settings.NukeCardConnectedTerritoriesSpreadDamageDelta);
        CreateLabel(UImain).SetText("Friendly fire (can harm yourself): " .. tostring(Mod.Settings.NukeFriendlyfire));
        CreateLabel(UImain).SetText("Implementation phase: " .. Mod.Settings.NukeImplementationPhase);
        CreateLabel(UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.NukeCardPiecesNeeded);
        CreateLabel(UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.NukeCardStartPieces);
        CreateLabel(UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.NukeCardWeight);
    end

    if (Mod.Settings.PestilenceEnabled == true) then
        CreateLabel(UImain).SetText("\n[PESTILENCE]").SetColor(getColourCode("card play heading"));
        CreateLabel(UImain).SetText("Spread a debilitating plague across enemy territories to slowly weaken their forces.");
        CreateLabel(UImain).SetText("\nDuration: " .. Mod.Settings.PestilenceDuration);
        CreateLabel(UImain).SetText("Strength: " .. Mod.Settings.PestilenceStrength);
        CreateLabel(UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.PestilencePiecesNeeded);
        CreateLabel(UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.PestilenceStartPieces);
        CreateLabel(UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.PestilencePiecesPerTurn);
        CreateLabel(UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.PestilenceCardWeight);
    end

    if (Mod.Settings.IsolationEnabled == true) then
        CreateLabel(UImain).SetText("\n[ISOLATION]").SetColor(getColourCode("card play heading"));
        CreateLabel(UImain).SetText("Temporarily isolate a territory to prevent attacks, transfers or airlifts in or out of the territory.");
        CreateLabel(UImain).SetText("\nDuration: " .. Mod.Settings.IsolationDuration);
        if (Mod.Settings.IsolationDuration == -1) then 
            CreateLabel(UImain).SetText("(-1 indicates that isolation remains permanently)");
        end
        CreateLabel(UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.IsolationPiecesNeeded);
        CreateLabel(UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.IsolationStartPieces);
        CreateLabel(UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.IsolationCardWeight);
    end

    if (Mod.Settings.ShieldEnabled == true) then
        CreateLabel(UImain).SetText("\n[SHIELD]").SetColor(getColourCode("card play heading"));
        CreateLabel(UImain).SetText("Deploy a immovable defensive unit that absorbs all incoming regular damage to the territory and prevents territory capture.");
        CreateLabel(UImain).SetText("\nDuration: " .. Mod.Settings.ShieldDuration);
        if (Mod.Settings.ShieldDuration == -1) then 
            CreateLabel(UImain).SetText("(-1 indicates that the shield remains permanently)");
        end
        CreateLabel(UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.ShieldPiecesNeeded);
        CreateLabel(UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.ShieldStartPieces);
        CreateLabel(UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.ShieldPiecesPerTurn);
        CreateLabel(UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.ShieldCardWeight);
    end

    if (Mod.Settings.PhantomEnabled == true) then
        CreateLabel(UImain).SetText("\n[PHANTOM]").SetColor(getColourCode("card play heading"));
        CreateLabel(UImain).SetText("Deploy a unit that absorbs light to obscure enemy visibility wherever it goes. Units attacking from the presence of a phantom carry the darkness with them.");
        CreateLabel(UImain).SetText("\nDuration: " .. Mod.Settings.PhantomDuration);
        if (Mod.Settings.PhantomDuration == -1) then 
            CreateLabel(UImain).SetText("(-1 indicates that the phantom remains permanently)");
        end
        local strFogLevel = "Normal fog (can't see units or owner of territory)";
        if (Mod.Settings.PhantomFogLevel == WL.StandingFogLevel.OwnerOnly) then strFogLevel = "Light fog (can see owner of territory but not units)"; end
        CreateLabel(UImain).SetText("Fog level: " .. strFogLevel);
        CreateLabel(UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.PhantomPiecesNeeded);
        CreateLabel(UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.PhantomStartPieces);
        CreateLabel(UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.PhantomPiecesPerTurn);
        CreateLabel(UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.PhantomCardWeight);
    end

    if (Mod.Settings.MonolithEnabled == true) then
        CreateLabel(UImain).SetText("\n[MONOLITH]").SetColor(getColourCode("card play heading"));
        CreateLabel(UImain).SetText("Construct an immovable monument that prevents enemy capture but leaves units on the territory unprotected.");
        CreateLabel(UImain).SetText("\nDuration: " .. Mod.Settings.MonolithDuration);
        CreateLabel(UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.MonolithPiecesNeeded);
        CreateLabel(UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.MonolithStartPieces);
        CreateLabel(UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.MonolithPiecesPerTurn);
        CreateLabel(UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.MonolithCardWeight);
    end

    if (Mod.Settings.NeutralizeEnabled == true) then
        CreateLabel(UImain).SetText("\n[NEUTRALIZE]").SetColor(getColourCode("card play heading"));
        CreateLabel(UImain).SetText("Convert an enemy territory to neutral.");
        CreateLabel(UImain).SetText("\nDuration: " .. Mod.Settings.NeutralizeDuration);
        CreateLabel(UImain).SetText("Can use on Commander: " .. tostring(Mod.Settings.NeutralizeCanUseOnCommander));
        CreateLabel(UImain).SetText("Can use on Special Units: " .. tostring(Mod.Settings.NeutralizeCanUseOnSpecials));
        CreateLabel(UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.NeutralizePiecesNeeded);
        CreateLabel(UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.NeutralizeStartPieces);
        CreateLabel(UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.NeutralizePiecesPerTurn);
        CreateLabel(UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.NeutralizeCardWeight);
    end

    if (Mod.Settings.DeneutralizeEnabled == true) then
        CreateLabel(UImain).SetText("\n[DENEUTRALIZE]").SetColor(getColourCode("card play heading"));
        CreateLabel(UImain).SetText("Claim a neutral territory.");
        CreateLabel(UImain).SetText("\nNumber of pieces to divide the card into: " .. Mod.Settings.DeneutralizePiecesNeeded);
        CreateLabel(UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.DeneutralizeStartPieces);
        CreateLabel(UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.DeneutralizePiecesPerTurn);
        CreateLabel(UImain).SetText("Can use on natural neutrals: " .. tostring(Mod.Settings.DeneutralizeCanUseOnNaturalNeutrals));
        CreateLabel(UImain).SetText("Can use on neutralized territories: " .. tostring(Mod.Settings.DeneutralizeCanUseOnNeutralizedTerritories));
        CreateLabel(UImain).SetText("Can assign to self: " .. tostring(Mod.Settings.DeneutralizeCanAssignToSelf));
        CreateLabel(UImain).SetText("Can assign to another player: " .. tostring(Mod.Settings.DeneutralizeCanAssignToAnotherPlayer));
        CreateLabel(UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.DeneutralizeCardWeight);
    end

    if (Mod.Settings.CardBlockEnabled == true) then
        CreateLabel(UImain).SetText("\n[CARD BLOCK]").SetColor(getColourCode("card play heading"));
        CreateLabel(UImain).SetText("Prevent an opponent from playing cards.");
        CreateLabel(UImain).SetText("\nDuration: " .. Mod.Settings.CardBlockDuration);
        CreateLabel(UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.CardBlockPiecesNeeded);
        CreateLabel(UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.CardBlockStartPieces);
        CreateLabel(UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.CardBlockPiecesPerTurn);
        CreateLabel(UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.CardBlockCardWeight);
    end

    if (Mod.Settings.CardPiecesEnabled == true) then
        CreateLabel(UImain).SetText("\n[CARD PIECES]").SetColor(getColourCode("card play heading"));
        CreateLabel(UImain).SetText("Redeem this card to receive additional whole cards and/or card pieces.");
        CreateLabel(UImain).SetText("\nNumber of whole cards to grant: " .. Mod.Settings.CardPiecesNumWholeCardsToGrant);
        CreateLabel(UImain).SetText("Number of card pieces to grant: " .. Mod.Settings.CardPiecesNumCardPiecesToGrant);
        CreateLabel(UImain).SetText("Pieces needed to form a whole card: " .. Mod.Settings.CardPiecesPiecesNeeded);
        CreateLabel(UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.CardPiecesStartPieces);
        CreateLabel(UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.CardPiecesCardWeight);
    end

    if (Mod.Settings.AirstrikeEnabled == true) then
        CreateLabel(UImain).SetText("\n[AIRSTRIKE]").SetColor(getColourCode("card play heading"));
        CreateLabel(UImain).SetText("Conduct an aerial assault on any territory, bypassing normal borders.");
		CreateLabel(UImain).SetText("\nDeployment yield (%): "..Mod.Settings.AirstrikeDeploymentYield);
		CreateLabel(UImain).SetText("• % of units that are killed during Airstrike execution\n     - they participate in the attack but die afterward\n     - they are considered to be shot out of the air on the way down");
		CreateLabel(UImain).SetText("• 100%: all units deploy effectively\n     - no units die due to Deployment Yield");
		CreateLabel(UImain).SetText("• 75%: only 75% of units deploy effectively\n     - 25% die during deployment after contributing to the attack");
		CreateLabel(UImain).SetText("• Special Units aren't impacted by this setting\n     - Special Units never die during deployment\n     - but they can still be killed during the attack");

		UI.CreateLabel (UImain).SetText("\nMove units with airlift cards: " ..tostring (Mod.Settings.AirstrikeMoveUnitsWithAirliftCard));
        if (Mod.Settings.AirstrikeMoveUnitsWithAirliftCard == true) then UI.CreateLabel (UImain).SetText("• uses airlift cards to move units, creates the standard airlift travel arrow (DOES NOT WORK with mods Late Airlifts or Tranport Only Airlifts)");
        else UI.CreateLabel (UImain).SetText("• moves units using mod code; does not create airlift travel arrows -- works with mods Late Airlifts or Transport Only Airlifts");
        end

        CreateLabel (UImain).SetText ("\nCan send regular armies: ".. tostring (Mod.Settings.AirstrikeCanSendRegularArmies));
        CreateLabel (UImain).SetText ("Can send Special Units: ".. tostring (Mod.Settings.AirstrikeCanSendSpecialUnits));
        CreateLabel (UImain).SetText ("Can target neutrals: " .. tostring(Mod.Settings.AirstrikeCanTargetNeutrals));
        CreateLabel (UImain).SetText ("Can target players: " .. tostring(Mod.Settings.AirstrikeCanTargetPlayers));
        CreateLabel (UImain).SetText ("Can target fogged territories: " .. tostring(Mod.Settings.AirstrikeCanTargetFoggedTerritories));
        CreateLabel (UImain).SetText ("Can target structures: ".. tostring (Mod.Settings.AirstrikeCanTargetStructures));
        CreateLabel (UImain).SetText ("Can target Special Units: ".. tostring (Mod.Settings.AirstrikeCanTargetSpecialUnits));
        CreateLabel (UImain).SetText ("Can target Commanders: ".. tostring (Mod.Settings.AirstrikeCanTargetCommanders));
        CreateLabel (UImain).SetText ("Number of pieces to divide the card into: " .. Mod.Settings.AirstrikePiecesNeeded);
        CreateLabel (UImain).SetText ("Pieces given to each player at the start: " .. Mod.Settings.AirstrikeStartPieces);
        CreateLabel (UImain).SetText ("Minimum pieces awarded per turn: 1"); -- .. Mod.Settings.AirstrikePiecesPerTurn); <-- this property doesn't exist yet, forgot to implement it
        CreateLabel (UImain).SetText ("Card weight (how common the card is): " .. Mod.Settings.AirstrikeCardWeight);
    end

    if (Mod.Settings.ForestFireEnabled == true) then
        CreateLabel(UImain).SetText("\n[FOREST FIRE]").SetColor(getColourCode("card play heading"));
        CreateLabel(UImain).SetText("Ignite a fire that gradually spreads to neighboring territories.");
        CreateLabel(UImain).SetText("\nDuration: " .. Mod.Settings.ForestFireDuration);
        CreateLabel(UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.ForestFirePiecesNeeded);
        CreateLabel(UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.ForestFireStartPieces);
        CreateLabel(UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.ForestFireCardWeight);
    end

    if (Mod.Settings.EarthquakeEnabled == true) then
        CreateLabel(UImain).SetText("\n[EARTHQUAKE]").SetColor(getColourCode("card play heading"));
        CreateLabel(UImain).SetText("Trigger a seismic event that damages all territories in a bonus.");
        CreateLabel(UImain).SetText("\nDuration: " .. Mod.Settings.EarthquakeDuration);
        CreateLabel(UImain).SetText("Strength: " .. Mod.Settings.EarthquakeStrength);
        CreateLabel(UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.EarthquakePiecesNeeded);
        CreateLabel(UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.EarthquakeStartPieces);
        CreateLabel(UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.EarthquakePiecesPerTurn);
        CreateLabel(UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.EarthquakeCardWeight);
    end

    if (Mod.Settings.TornadoEnabled == true) then
        CreateLabel(UImain).SetText("\n[TORNADO]").SetColor(getColourCode("card play heading"));
        CreateLabel(UImain).SetText("Summon a tornado to damage a territory. The first turn of tornado does double damage.");
        CreateLabel(UImain).SetText("\nDuration: " .. Mod.Settings.TornadoDuration);
        CreateLabel(UImain).SetText("Strength: " .. Mod.Settings.TornadoStrength);
        CreateLabel(UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.TornadoPiecesNeeded);
        CreateLabel(UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.TornadoStartPieces);
        CreateLabel(UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.TornadoPiecesPerTurn);
        CreateLabel(UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.TornadoCardWeight);
    end

    if (Mod.Settings.QuicksandEnabled == true) then
        CreateLabel(UImain).SetText("\n[QUICKSAND]").SetColor(getColourCode("card play heading"));
        CreateLabel(UImain).SetText("Transform a territory into quicksand that prevents units from leaving the area. Units trapped in quicksand will sustain additional damage from attackers, and will do reduced damage to their attackers.");
        CreateLabel(UImain).SetText("\nDuration: " .. Mod.Settings.QuicksandDuration);
        CreateLabel(UImain).SetText("Block entry into territory: " .. tostring(Mod.Settings.QuicksandBlockEntryIntoTerritory));
        CreateLabel(UImain).SetText("Block airlifts into territory: " .. tostring(Mod.Settings.QuicksandBlockAirliftsIntoTerritory));
        CreateLabel(UImain).SetText("Block airlifts from territory: " .. tostring(Mod.Settings.QuicksandBlockAirliftsFromTerritory));
        CreateLabel(UImain).SetText("Block exit from territory: " .. tostring(Mod.Settings.QuicksandBlockExitFromTerritory));
        CreateLabel(UImain).SetText("Defender damage taken modifier: " .. Mod.Settings.QuicksandDefenderDamageTakenModifier .."x");
        CreateLabel(UImain).SetText("Attacker damage taken modifier: " .. Mod.Settings.QuicksandAttackerDamageTakenModifier .."x");
        CreateLabel(UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.QuicksandPiecesNeeded);
        CreateLabel(UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.QuicksandStartPieces);
        CreateLabel(UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.QuicksandPiecesPerTurn);
        CreateLabel(UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.QuicksandCardWeight);
    end

--[[	if (Mod.Settings.PestilenceEnabled == true) then
		CreateLabel(UImain).SetText("\n[PESTILENCE]").SetColor(getColourCode("card play heading"));
		CreateLabel(UImain).SetText("Duration: " .. Mod.Settings.PestilenceDuration);
		CreateLabel(UImain).SetText("Strength: " .. Mod.Settings.PestilenceStrength);
		CreateLabel(UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.PestilencePiecesNeeded);
		CreateLabel(UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.PestilenceStartPieces);
		CreateLabel(UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.PestilencePiecesPerTurn);
		CreateLabel(UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.PestilenceCardWeight);
	end

	if (Mod.Settings.IsolationEnabled == true) then
		CreateLabel(UImain).SetText("\n[ISOLATION]").SetColor(getColourCode("card play heading"));
		CreateLabel(UImain).SetText("Duration: " .. Mod.Settings.IsolationDuration);
		if (Mod.Settings.IsolationDuration == -1) then 
			CreateLabel(UImain).SetText("(-1 indicates that isolation remains permanently)");
		end
		CreateLabel(UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.IsolationPiecesNeeded);
		CreateLabel(UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.IsolationStartPieces);
		CreateLabel(UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.IsolationCardWeight);
	end

	if (Mod.Settings.ShieldEnabled == true) then
		CreateLabel(UImain).SetText("\n[SHIELD]").SetColor(getColourCode("card play heading"));
		CreateLabel(UImain).SetText("Duration: " .. Mod.Settings.ShieldDuration);
        if (Mod.Settings.ShieldDuration == -1) then CreateLabel(UImain).SetText("(-1 indicates that the shield remains permanently)"); end
		CreateLabel(UImain).SetText("Number of pieces to divide the card into: ".. Mod.Settings.ShieldPiecesNeeded);
        CreateLabel(UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.ShieldStartPieces);
        CreateLabel(UImain).SetText("Minimum pieces awarded per turn: ".. Mod.Settings.ShieldPiecesPerTurn);
        CreateLabel(UImain).SetText("Card weight (how common the card is): ".. Mod.Settings.ShieldCardWeight);
    end

	if (Mod.Settings.MonolithEnabled == true) then
		CreateLabel(UImain).SetText("\n[MONOLITH]").SetColor(getColourCode("card play heading"));
		CreateLabel(UImain).SetText("Duration: " .. Mod.Settings.MonolithDuration);
		CreateLabel(UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.MonolithPiecesNeeded);
		CreateLabel(UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.MonolithStartPieces);
		CreateLabel(UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.MonolithPiecesPerTurn);
		CreateLabel(UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.MonolithCardWeight);
	end

	if (Mod.Settings.NeutralizeEnabled == true) then
		CreateLabel(UImain).SetText("\n[NEUTRALIZE]").SetColor(getColourCode("card play heading"));
		CreateLabel(UImain).SetText("Duration: " .. Mod.Settings.NeutralizeDuration);
		CreateLabel(UImain).SetText("Can use on Commander: " .. tostring(Mod.Settings.NeutralizeCanUseOnCommander));
		CreateLabel(UImain).SetText("Can use on Special Units: " .. tostring(Mod.Settings.NeutralizeCanUseOnSpecials));
		CreateLabel(UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.NeutralizePiecesNeeded);
		CreateLabel(UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.NeutralizeStartPieces);
		CreateLabel(UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.NeutralizePiecesPerTurn);
		CreateLabel(UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.NeutralizeCardWeight);
	end

	if (Mod.Settings.DeneutralizeEnabled == true) then
		CreateLabel(UImain).SetText("\n[DENEUTRALIZE]").SetColor(getColourCode("card play heading"));
		CreateLabel(UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.DeneutralizePiecesNeeded);
		CreateLabel(UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.DeneutralizeStartPieces);
		CreateLabel(UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.DeneutralizePiecesPerTurn);
		CreateLabel(UImain).SetText("Can use on natural neutrals: " .. tostring(Mod.Settings.DeneutralizeCanUseOnNaturalNeutrals));
		CreateLabel(UImain).SetText("Can use on neutralized territories: " .. tostring(Mod.Settings.DeneutralizeCanUseOnNeutralizedTerritories));
		CreateLabel(UImain).SetText("Can assign to self: " .. tostring(Mod.Settings.DeneutralizeCanAssignToSelf));
		CreateLabel(UImain).SetText("Can assign to another player: " .. tostring(Mod.Settings.DeneutralizeCanAssignToAnotherPlayer));
		CreateLabel(UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.DeneutralizeCardWeight);
	end

	if (Mod.Settings.CardBlockEnabled == true) then
		CreateLabel(UImain).SetText("\n[CARD BLOCK]").SetColor(getColourCode("card play heading"));
		CreateLabel(UImain).SetText("Duration: " .. Mod.Settings.CardBlockDuration);
		CreateLabel(UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.CardBlockPiecesNeeded);
		CreateLabel(UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.CardBlockStartPieces);
		CreateLabel(UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.CardBlockPiecesPerTurn);
		CreateLabel(UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.CardBlockCardWeight);
	end

	if (Mod.Settings.CardPiecesEnabled == true) then
		CreateLabel(UImain).SetText("\n[CARD PIECES]").SetColor(getColourCode("card play heading"));
		CreateLabel(UImain).SetText("Number of whole cards to grant: " .. Mod.Settings.CardPiecesNumWholeCardsToGrant);
		CreateLabel(UImain).SetText("Number of card pieces to grant: " .. Mod.Settings.CardPiecesNumCardPiecesToGrant);
		CreateLabel(UImain).SetText("Pieces needed to form a whole card: " .. Mod.Settings.CardPiecesPiecesNeeded);
		CreateLabel(UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.CardPiecesStartPieces);
		CreateLabel(UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.CardPiecesCardWeight);
	end

	if (Mod.Settings.AirstrikeEnabled == true) then
		CreateLabel(UImain).SetText("\n[AIRSTRIKE]").SetColor(getColourCode("card play heading"));
		CreateLabel(UImain).SetText("Can target neutrals: " .. tostring(Mod.Settings.AirstrikeCanTargetNeutrals));
		CreateLabel(UImain).SetText("Can target players: " .. tostring(Mod.Settings.AirstrikeCanTargetPlayers));
		CreateLabel(UImain).SetText("Can target fogged territories: " .. tostring(Mod.Settings.AirstrikeCanTargetFoggedTerritories));
		CreateLabel(UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.AirstrikePiecesNeeded);
		CreateLabel(UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.AirstrikeStartPieces);
		CreateLabel(UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.AirstrikeCardWeight);
	end

	if (Mod.Settings.ForestFireEnabled == true) then
		CreateLabel(UImain).SetText("\n[FOREST FIRE]").SetColor(getColourCode("card play heading"));
		CreateLabel(UImain).SetText("Duration: " .. Mod.Settings.ForestFireDuration);
		CreateLabel(UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.ForestFirePiecesNeeded);
		CreateLabel(UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.ForestFireStartPieces);
		CreateLabel(UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.ForestFireCardWeight);
	end

	if (Mod.Settings.EarthquakeEnabled == true) then
		CreateLabel(UImain).SetText("\n[EARTHQUAKE]").SetColor(getColourCode("card play heading"));
		CreateLabel(UImain).SetText("Duration: " .. Mod.Settings.EarthquakeDuration);
		CreateLabel(UImain).SetText("Strength: " .. Mod.Settings.EarthquakeStrength);
		CreateLabel(UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.EarthquakePiecesNeeded);
		CreateLabel(UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.EarthquakeStartPieces);
		CreateLabel(UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.EarthquakePiecesPerTurn);
		CreateLabel(UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.EarthquakeCardWeight);
	end

	if (Mod.Settings.TornadoEnabled == true) then
		CreateLabel(UImain).SetText("\n[TORNADO]").SetColor(getColourCode("card play heading"));
		CreateLabel(UImain).SetText("Duration: " .. Mod.Settings.TornadoDuration);
		CreateLabel(UImain).SetText("Strength: " .. Mod.Settings.TornadoStrength);
		CreateLabel(UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.TornadoPiecesNeeded);
		CreateLabel(UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.TornadoStartPieces);
		CreateLabel(UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.TornadoPiecesPerTurn);
		CreateLabel(UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.TornadoCardWeight);
	end

	if (Mod.Settings.QuicksandEnabled == true) then
		CreateLabel(UImain).SetText("\n[QUICKSAND]").SetColor(getColourCode("card play heading"));
		CreateLabel(UImain).SetText("Duration: " .. Mod.Settings.QuicksandDuration);
		CreateLabel(UImain).SetText("Block entry into territory: " .. tostring(Mod.Settings.QuicksandBlockEntryIntoTerritory));
		CreateLabel(UImain).SetText("Block airlifts into territory: " .. tostring(Mod.Settings.QuicksandBlockAirliftsIntoTerritory));
		CreateLabel(UImain).SetText("Block airlifts from territory: " .. tostring(Mod.Settings.QuicksandBlockAirliftsFromTerritory));
		CreateLabel(UImain).SetText("Block exit from territory: " .. tostring(Mod.Settings.QuicksandBlockExitFromTerritory));
		CreateLabel(UImain).SetText("Defend damage modifier: " .. Mod.Settings.QuicksandDefenderDamageTakenModifier .."x");
		CreateLabel(UImain).SetText("Attack damage modifier: " .. Mod.Settings.QuicksandAttackerDamageTakenModifier .."x");
		CreateLabel(UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.QuicksandPiecesNeeded);
		CreateLabel(UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.QuicksandStartPieces);
		CreateLabel(UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.QuicksandPiecesPerTurn);
		CreateLabel(UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.QuicksandCardWeight);
	end]]
end