require("utilities");

function Client_PresentSettingsUI(rootParent)
	--be vigilant of referencing clientGame.Us when it ==nil for spectators, b/c they CAN initiate this function

	local UImain = UI.CreateVerticalLayoutGroup (rootParent).SetFlexibleWidth(1);

    if (Mod.Settings.NukeEnabled == true) then
        UI.CreateLabel (UImain).SetText("[NUKE]").SetColor(getColourCode("card play heading"));

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
        UI.CreateLabel (UImain).SetText(strNukeDesc);

        UI.CreateLabel (UImain).SetText("\nEpicenter damage (%): " .. Mod.Settings.NukeCardMainTerritoryDamage);
        UI.CreateLabel (UImain).SetText("Epicenter fixed damage: " .. Mod.Settings.NukeCardMainTerritoryFixedDamage);
        UI.CreateLabel (UImain).SetText("Bordering territory damage (%): " .. Mod.Settings.NukeCardConnectedTerritoryDamage);
        UI.CreateLabel (UImain).SetText("Bordering territory fixed damage: " .. Mod.Settings.NukeCardConnectedTerritoryFixedDamage);
        if (Mod.Settings.NukeCardMainTerritoryDamage < 0 or Mod.Settings.NukeCardMainTerritoryFixedDamage < 0 or Mod.Settings.NukeCardConnectedTerritoryDamage < 0 or Mod.Settings.NukeCardConnectedTerritoryFixedDamage < 0) then
            UI.CreateLabel (UImain).SetText("Note: Negative damage values indicate a healing effect.");
        end
        UI.CreateLabel (UImain).SetText("Blast range (levels): " .. Mod.Settings.NukeCardNumLevelsConnectedTerritoriesToSpreadTo);
        UI.CreateLabel (UImain).SetText("Damage reduction with spread (%): " .. Mod.Settings.NukeCardConnectedTerritoriesSpreadDamageDelta);
        UI.CreateLabel (UImain).SetText("Friendly fire (can harm yourself): " .. tostring(Mod.Settings.NukeFriendlyfire));
        UI.CreateLabel (UImain).SetText("Implementation phase: " .. Mod.Settings.NukeImplementationPhase);
        UI.CreateLabel (UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.NukeCardPiecesNeeded);
        UI.CreateLabel (UImain).SetText("Minimum pieces awarded per turn: " .. tostring (Mod.Settings.NukePiecesPerTurn or 1));
        UI.CreateLabel (UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.NukeCardStartPieces);
        UI.CreateLabel (UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.NukeCardWeight);
    end

    if (Mod.Settings.PestilenceEnabled == true) then
        UI.CreateLabel (UImain).SetText("\n[PESTILENCE]").SetColor(getColourCode("card play heading"));
        -- UI.CreateLabel (UImain).SetText("Spread a debilitating plague across enemy territories to slowly weaken their forces.");
		local strPlural_units = "";
		local strPlural_duration = "";
		if (Mod.Settings.PestilenceDuration > 1) then strPlural_duration = "s"; end
		if (Mod.Settings.PestilenceStrength > 1) then strPlural_units = "s"; end
		UI.CreateLabel (UImain).SetText("Invoke pestilence on another player, reducing each of their territories by " ..Mod.Settings.PestilenceStrength.. " unit"..strPlural_units.. " at the end of the turn for " ..Mod.Settings.PestilenceDuration.. " turn"..strPlural_duration.. ".\n\nIf a territory is reduced to 0 armies, it will turn neutral.\n\nSpecial units are not affected by Pestilence, and will prevent a territory from turning to neutral.");
		UI.CreateLabel (UImain).SetText("\nPestilence timing (card is played on turn X):\n• (Turn X) - Pestilence is invoked, targeted player is notified");
		UI.CreateLabel (UImain).SetText("• (Turn X+1) - targeted player receives a reminder warning order");
		UI.CreateLabel (UImain).SetText("• (Turn X+2) - targeted player is impacted by Pestilence at the end of the turn");
        UI.CreateLabel (UImain).SetText("\nDuration: " .. Mod.Settings.PestilenceDuration);
        UI.CreateLabel (UImain).SetText("Strength: " .. Mod.Settings.PestilenceStrength);
        UI.CreateLabel (UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.PestilencePiecesNeeded);
        UI.CreateLabel (UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.PestilenceStartPieces);
        UI.CreateLabel (UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.PestilencePiecesPerTurn);
        UI.CreateLabel (UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.PestilenceCardWeight);
    end

    if (Mod.Settings.IsolationEnabled == true) then
        UI.CreateLabel (UImain).SetText("\n[ISOLATION]").SetColor(getColourCode("card play heading"));
        UI.CreateLabel (UImain).SetText("Temporarily isolate a territory to prevent attacks, transfers or airlifts in or out of the territory.");
        UI.CreateLabel (UImain).SetText("\nDuration: " .. Mod.Settings.IsolationDuration);
        if (Mod.Settings.IsolationDuration == -1) then 
            UI.CreateLabel (UImain).SetText("(-1 indicates that isolation remains permanently)");
        end
        UI.CreateLabel (UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.IsolationPiecesNeeded);
        UI.CreateLabel (UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.IsolationStartPieces);
        UI.CreateLabel (UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.IsolationCardWeight);
    end

    if (Mod.Settings.ShieldEnabled == true) then
        UI.CreateLabel (UImain).SetText("\n[SHIELD]").SetColor(getColourCode("card play heading"));
        UI.CreateLabel (UImain).SetText("Deploy a immovable defensive unit that absorbs all incoming regular damage to the territory and prevents territory capture. Shields also protect against the following types of special attacks:\nSpecial damage types Shield defends against:\nBomb, Airstrike, Nuke, Tornado, Earthquake, Pestilence");
        UI.CreateLabel (UImain).SetText("\nDuration: " .. Mod.Settings.ShieldDuration);
        if (Mod.Settings.ShieldDuration == -1) then 
            UI.CreateLabel (UImain).SetText("(-1 indicates that the shield remains permanently)");
        end
        UI.CreateLabel (UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.ShieldPiecesNeeded);
        UI.CreateLabel (UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.ShieldStartPieces);
        UI.CreateLabel (UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.ShieldPiecesPerTurn);
        UI.CreateLabel (UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.ShieldCardWeight);
    end

    if (Mod.Settings.PhantomEnabled == true) then
        UI.CreateLabel (UImain).SetText("\n[PHANTOM]").SetColor(getColourCode("card play heading"));
        UI.CreateLabel (UImain).SetText("Deploy a unit that absorbs light to obscure enemy visibility wherever it goes. Units attacking from the presence of a phantom carry the darkness with them.");
        UI.CreateLabel (UImain).SetText("\nDuration: " .. Mod.Settings.PhantomDuration);
        if (Mod.Settings.PhantomDuration == -1) then
            UI.CreateLabel (UImain).SetText("(-1 indicates that the phantom remains permanently)");
        end
        local strFogLevel = "Normal Fog (can't see units or owner of territory)";
        if (Mod.Settings.PhantomFogLevel == WL.StandingFogLevel.OwnerOnly) then strFogLevel = "Light Fog (can see owner of territory but not units)";
        elseif (Mod.Settings.PhantomFogLevel == WL.StandingFogLevel.Visible) then strFogLevel = "Fully Visible (can see owner and any units on the territory)"; --this should never happen; only options on the configure page are Light & Normal Fog
        elseif (Mod.Settings.PhantomFogLevel == WL.StandingFogLevel.Fogged) then strFogLevel = "Normal Fog (can't see units or owner of territory)";
 		else strFogLevel = " [invalid Phantom Fog Level settings]. ";
		end
        UI.CreateLabel (UImain).SetText("Fog level: " .. strFogLevel);
		local intFogModPriority = tonumber (Mod.Settings.PhantomFogModPriority or 8000);
		UI.CreateLabel (UImain).SetFlexibleWidth(1).SetText ("Phantom FogMod Priority: " .. tostring (intFogModPriority));
		if (intFogModPriority >= 9000) then --this causes territory owner to become unable to see own units on the territory
			UI.CreateLabel (UImain).SetFlexibleWidth(1).SetText ("  (territory owners cannot see own units; if game is not Commerce, impacted playes will be unable to submit turn and will boot)");
		elseif (intFogModPriority >= 6000) then			
			UI.CreateLabel (UImain).SetFlexibleWidth(1).SetText ("  (Phantom fog will override visibility provided by Special Units, or by Spy, Reconnaissance or Surveillance cards)");
		elseif (intFogModPriority >= 3000) then
			UI.CreateLabel (UImain).SetFlexibleWidth(1).SetText ("  (Phantom fog will override visibility provided by Spy, Reconnaissance or Surveillance cards, but not visibility provided by Special Units)");
		else
			UI.CreateLabel (UImain).SetFlexibleWidth(1).SetText ("  (Phantom fog will not override visibility provided by Spy, Reconnaissance or Surveillance cards, nor that provided by Special Units)");
		end

		UI.CreateLabel (UImain).SetText("\nNumber of pieces to divide the card into: " .. Mod.Settings.PhantomPiecesNeeded);
        UI.CreateLabel (UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.PhantomStartPieces);
        UI.CreateLabel (UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.PhantomPiecesPerTurn);
        UI.CreateLabel (UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.PhantomCardWeight);
    end

    if (Mod.Settings.MonolithEnabled == true) then
        UI.CreateLabel (UImain).SetText("\n[MONOLITH]").SetColor(getColourCode("card play heading"));
        UI.CreateLabel (UImain).SetText("Construct an immovable monument that prevents enemy capture but leaves units on the territory unprotected.");
        UI.CreateLabel (UImain).SetText("\nDuration: " .. Mod.Settings.MonolithDuration);
        UI.CreateLabel (UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.MonolithPiecesNeeded);
        UI.CreateLabel (UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.MonolithStartPieces);
        UI.CreateLabel (UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.MonolithPiecesPerTurn);
        UI.CreateLabel (UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.MonolithCardWeight);
    end

    if (Mod.Settings.NeutralizeEnabled == true) then
        UI.CreateLabel (UImain).SetText("\n[NEUTRALIZE]").SetColor(getColourCode("card play heading"));
        UI.CreateLabel (UImain).SetText("Convert an enemy territory to neutral.");
        UI.CreateLabel (UImain).SetText("\nDuration: " .. Mod.Settings.NeutralizeDuration);
        UI.CreateLabel (UImain).SetText("Can use on Commander: " .. tostring(Mod.Settings.NeutralizeCanUseOnCommander));
        UI.CreateLabel (UImain).SetText("Can use on Special Units: " .. tostring(Mod.Settings.NeutralizeCanUseOnSpecials));
        UI.CreateLabel (UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.NeutralizePiecesNeeded);
        UI.CreateLabel (UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.NeutralizeStartPieces);
        UI.CreateLabel (UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.NeutralizePiecesPerTurn);
        UI.CreateLabel (UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.NeutralizeCardWeight);
    end

    if (Mod.Settings.DeneutralizeEnabled == true) then
        UI.CreateLabel (UImain).SetText("\n[DENEUTRALIZE]").SetColor(getColourCode("card play heading"));
        UI.CreateLabel (UImain).SetText("Claim a neutral territory.");
        UI.CreateLabel (UImain).SetText("Deneutralize range: " ..tostring ((Mod.Settings.DeneutralizeRange ~= nil and Mod.Settings.DeneutralizeRange < 4000 and Mod.Settings.DeneutralizeRange) or "Unlimited"));
        local horz = UI.CreateHorizontalLayoutGroup (UImain);
		UI.CreateLabel (horz).SetText("Deneutralize execution phase: " ..tostring (WL.TurnPhase.ToString (Mod.Settings.DeneutralizeImplementationPhase or WL.TurnPhase.Gift)));
		UI.CreateButton (horz).SetText ("[?1]").SetColor (getColourCode ("subheading")).SetOnClick (showPopUpTurnPhaseDescriptions_UIalert);
		UI.CreateButton (horz).SetText ("[?2]").SetColor (getColourCode ("subheading")).SetOnClick (function () showPopUpTurnPhaseDescriptions_StylishDialog (gameRefresh_Game); end);
		--UI.Alert (gameRefresh_Game.Us.ID); --a test to check if gameRefresh_Game has a valid non-nil value

		UI.CreateLabel (UImain).SetText("\nNumber of pieces to divide the card into: " .. Mod.Settings.DeneutralizePiecesNeeded);
        UI.CreateLabel (UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.DeneutralizePiecesPerTurn);
        UI.CreateLabel (UImain).SetText("Can use on natural neutrals: " .. tostring(Mod.Settings.DeneutralizeCanUseOnNaturalNeutrals));
        UI.CreateLabel (UImain).SetText("Can use on neutralized territories: " .. tostring(Mod.Settings.DeneutralizeCanUseOnNeutralizedTerritories));
        UI.CreateLabel (UImain).SetText("Can assign to self: " .. tostring(Mod.Settings.DeneutralizeCanAssignToSelf));
        UI.CreateLabel (UImain).SetText("Can assign to another player: " .. tostring(Mod.Settings.DeneutralizeCanAssignToAnotherPlayer));
        UI.CreateLabel (UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.DeneutralizeCardWeight);
    end

    if (Mod.Settings.CardBlockEnabled == true) then
        UI.CreateLabel (UImain).SetText("\n[CARD BLOCK]").SetColor(getColourCode("card play heading"));
        UI.CreateLabel (UImain).SetText("Prevent an opponent from playing cards.");
        UI.CreateLabel (UImain).SetText("\nDuration: " .. Mod.Settings.CardBlockDuration);
        UI.CreateLabel (UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.CardBlockPiecesNeeded);
        UI.CreateLabel (UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.CardBlockStartPieces);
        UI.CreateLabel (UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.CardBlockPiecesPerTurn);
        UI.CreateLabel (UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.CardBlockCardWeight);
    end

    if (Mod.Settings.CardPiecesEnabled == true) then
        UI.CreateLabel (UImain).SetText("\n[CARD PIECES]").SetColor(getColourCode("card play heading"));
        UI.CreateLabel (UImain).SetText("Redeem this card to receive additional whole cards and/or card pieces.");
        UI.CreateLabel (UImain).SetText("\nNumber of whole cards to grant: " .. Mod.Settings.CardPiecesNumWholeCardsToGrant);
        UI.CreateLabel (UImain).SetText("Number of card pieces to grant: " .. Mod.Settings.CardPiecesNumCardPiecesToGrant);
        UI.CreateLabel (UImain).SetText("Pieces needed to form a whole card: " .. Mod.Settings.CardPiecesPiecesNeeded);
        UI.CreateLabel (UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.CardPiecesStartPieces);
        UI.CreateLabel (UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.CardPiecesCardWeight);
    end

    if (Mod.Settings.AirstrikeEnabled == true) then
        UI.CreateLabel (UImain).SetText("\n[AIRSTRIKE]").SetColor(getColourCode("card play heading"));
        UI.CreateLabel (UImain).SetText("Use an airlift to attack an enemy. Send armies from one of your territories to anywhere on the map");
		UI.CreateLabel (UImain).SetText("\nDeployment yield (%): "..Mod.Settings.AirstrikeDeploymentYield);
		UI.CreateLabel (UImain).SetText("• % of units that are killed during Airstrike execution\n     - they participate in the attack but die afterward\n     - they are considered to be shot out of the air on the way down");
		UI.CreateLabel (UImain).SetText("• 100%: all units deploy effectively\n     - no units die due to Deployment Yield");
		UI.CreateLabel (UImain).SetText("• 75%: only 75% of units deploy effectively\n     - 25% die during deployment after contributing to the attack");
		UI.CreateLabel (UImain).SetText("• Special Units aren't impacted by this setting\n     - Special Units never die during deployment\n     - but they can still be killed during the attack");

		UI.CreateLabel (UImain).SetText("\nMove units with airlift cards: " ..tostring (Mod.Settings.AirstrikeMoveUnitsWithAirliftCard));
        if (Mod.Settings.AirstrikeMoveUnitsWithAirliftCard == true) then UI.CreateLabel (UImain).SetText("• uses airlift cards to move units, creates the standard airlift travel arrow (DOES NOT WORK with mods Late Airlifts or Tranport Only Airlifts)");
        else UI.CreateLabel (UImain).SetText("• moves units using mod code; does not create airlift travel arrows -- works with mods Late Airlifts or Transport Only Airlifts");
        end

        UI.CreateLabel (UImain).SetText ("\nCan send regular armies: ".. tostring (Mod.Settings.AirstrikeCanSendRegularArmies));
        UI.CreateLabel (UImain).SetText ("Can send Special Units: ".. tostring (Mod.Settings.AirstrikeCanSendSpecialUnits));
        UI.CreateLabel (UImain).SetText ("Can target neutrals: " .. tostring(Mod.Settings.AirstrikeCanTargetNeutrals));
        UI.CreateLabel (UImain).SetText ("Can target players: " .. tostring(Mod.Settings.AirstrikeCanTargetPlayers));
        UI.CreateLabel (UImain).SetText ("Can target fogged territories: " .. tostring(Mod.Settings.AirstrikeCanTargetFoggedTerritories));
        UI.CreateLabel (UImain).SetText ("Can target structures: ".. tostring (Mod.Settings.AirstrikeCanTargetStructures));
        UI.CreateLabel (UImain).SetText ("Can target Special Units: ".. tostring (Mod.Settings.AirstrikeCanTargetSpecialUnits));
        UI.CreateLabel (UImain).SetText ("Can target Commanders: ".. tostring (Mod.Settings.AirstrikeCanTargetCommanders));
        UI.CreateLabel (UImain).SetText ("Number of pieces to divide the card into: " .. Mod.Settings.AirstrikePiecesNeeded);
        UI.CreateLabel (UImain).SetText ("Pieces given to each player at the start: " .. Mod.Settings.AirstrikeStartPieces);
        UI.CreateLabel (UImain).SetText ("Minimum pieces awarded per turn: 1"); -- .. Mod.Settings.AirstrikePiecesPerTurn); <-- this property doesn't exist yet, forgot to implement it
        UI.CreateLabel (UImain).SetText ("Card weight (how common the card is): " .. Mod.Settings.AirstrikeCardWeight);
    end

    if (Mod.Settings.ForestFireEnabled == true) then
        UI.CreateLabel (UImain).SetText("\n[WILDFIRE]").SetColor(getColourCode("card play heading"));
        UI.CreateLabel (UImain).SetText("Ignite a fire that gradually spreads to neighboring territories.");
        UI.CreateLabel (UImain).SetText("\nDuration: " .. Mod.Settings.ForestFireDuration);
        UI.CreateLabel (UImain).SetText("Spread range: " .. tostring (Mod.Settings.ForestFireSpreadRange or 5)); --get Spread Range from Mod.Settings, default to 5
		UI.CreateLabel (UImain).SetText("% damage: " .. tostring (Mod.Settings.ForestFireDamagePercent or 0)); --get % Damage amount from Mod.Settings, default to 0
		UI.CreateLabel (UImain).SetText("Fixed damage: " .. tostring (Mod.Settings.ForestFireDamage or 15)); --get Fixed Damage amount from Mod.Settings, default to 25
		UI.CreateLabel (UImain).SetText("% reduction with spread: " .. tostring (Mod.Settings.ForestFireDamageDeltaWithSpread or 25)); --get Fixed Damage amount from Mod.Settings, default to 25
		UI.CreateLabel (UImain).SetText("Affects neutrals: " .. tostring ((Mod.Settings.ForestFireAffectNeutrals == nil) and true or Mod.Settings.ForestFireAffectNeutrals)); --get AffectsNeutrals boolean value from Mod.Settings, default to true
		UI.CreateLabel (UImain).SetText("Friendly fire: " .. tostring ((Mod.Settings.ForestFireAllowFriendlyFire == nil) and true or Mod.Settings.ForestFireAllowFriendlyFire)); --get AffectsNeutrals boolean value from Mod.Settings, default to true
        UI.CreateLabel (UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.ForestFirePiecesNeeded);
        UI.CreateLabel (UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.ForestFirePiecesPerTurn);
        UI.CreateLabel (UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.ForestFireStartPieces);
        UI.CreateLabel (UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.ForestFireCardWeight);
	end

    if (Mod.Settings.EarthquakeEnabled == true) then
        UI.CreateLabel (UImain).SetText("\n[EARTHQUAKE]").SetColor(getColourCode("card play heading"));
        UI.CreateLabel (UImain).SetText("Trigger a seismic event that damages all territories in a bonus.");
        UI.CreateLabel (UImain).SetText("\nDuration: " .. Mod.Settings.EarthquakeDuration);
        UI.CreateLabel (UImain).SetText("Strength: " .. Mod.Settings.EarthquakeStrength);
        UI.CreateLabel (UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.EarthquakePiecesNeeded);
        UI.CreateLabel (UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.EarthquakeStartPieces);
        UI.CreateLabel (UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.EarthquakePiecesPerTurn);
        UI.CreateLabel (UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.EarthquakeCardWeight);
    end

    if (Mod.Settings.TornadoEnabled == true) then
        UI.CreateLabel (UImain).SetText("\n[TORNADO]").SetColor(getColourCode("card play heading"));
        UI.CreateLabel (UImain).SetText("Summon a tornado to damage a territory. The first turn of tornado does double damage.");
        UI.CreateLabel (UImain).SetText("\nDuration: " .. Mod.Settings.TornadoDuration);
        UI.CreateLabel (UImain).SetText("Strength: " .. Mod.Settings.TornadoStrength);
        UI.CreateLabel (UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.TornadoPiecesNeeded);
        UI.CreateLabel (UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.TornadoStartPieces);
        UI.CreateLabel (UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.TornadoPiecesPerTurn);
        UI.CreateLabel (UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.TornadoCardWeight);
    end

    if (Mod.Settings.QuicksandEnabled == true) then
        UI.CreateLabel (UImain).SetText("\n[QUICKSAND]").SetColor(getColourCode("card play heading"));
        UI.CreateLabel (UImain).SetText("Transform a territory into quicksand that prevents units from leaving the area. Units trapped in quicksand will sustain additional damage from attackers, and will do reduced damage to their attackers.");
        UI.CreateLabel (UImain).SetText("\nDuration: " .. Mod.Settings.QuicksandDuration);
        UI.CreateLabel (UImain).SetText("Block entry into territory: " .. tostring(Mod.Settings.QuicksandBlockEntryIntoTerritory));
        UI.CreateLabel (UImain).SetText("Block airlifts into territory: " .. tostring(Mod.Settings.QuicksandBlockAirliftsIntoTerritory));
        UI.CreateLabel (UImain).SetText("Block airlifts from territory: " .. tostring(Mod.Settings.QuicksandBlockAirliftsFromTerritory));
        UI.CreateLabel (UImain).SetText("Block exit from territory: " .. tostring(Mod.Settings.QuicksandBlockExitFromTerritory));
        UI.CreateLabel (UImain).SetText("Defender damage taken modifier: " .. Mod.Settings.QuicksandDefenderDamageTakenModifier .."x");
        UI.CreateLabel (UImain).SetText("Attacker damage taken modifier: " .. Mod.Settings.QuicksandAttackerDamageTakenModifier .."x");
        UI.CreateLabel (UImain).SetText("Number of pieces to divide the card into: " .. Mod.Settings.QuicksandPiecesNeeded);
        UI.CreateLabel (UImain).SetText("Pieces given to each player at the start: " .. Mod.Settings.QuicksandStartPieces);
        UI.CreateLabel (UImain).SetText("Minimum pieces awarded per turn: " .. Mod.Settings.QuicksandPiecesPerTurn);
        UI.CreateLabel (UImain).SetText("Card weight (how common the card is): " .. Mod.Settings.QuicksandCardWeight);
    end
end