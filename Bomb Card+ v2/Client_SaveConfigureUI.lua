require ('Bomb+ common');

function Client_SaveConfigureUI (alert, addCard)
	local killPercentage = killPercentageInput.GetValue();
	-- if killPercentage < 0 or killPercentage > 100 then alert ('The kill percentage must be set between 1 to 100'); end
	-- if killPercentage > 100 then alert ('The kill percentage must be <=100'); end
	Mod.Settings.killPercentage = killPercentage;
	--just use the %; >100% will have no effect; <0% will actually heal

	-- local delayed = cboxBombPhaseDelayed.GetIsChecked();
	-- if (delayed == nil) then delayed = false; end
    -- Mod.Settings.delayed = delayed;
    Mod.Settings.delayed = nil; --set this to nil to indicate that we're using the new methodology of Mod.Settings.BombImplementationPhase to indicate a proper WZ turn phase rather than just a delayed yes/no
	--NOTE: original Bomb+ mod uses Mod.Settings.delayed to indicated whether Bomb+ hits in BombCards phase (false) or ReceiveCards phase (true); in this case Mod.Settings.BombImplementationPhase == nil
	--      new Bomb+ mod sets Mod.Settings.delayed to nil and instead uses Mod.Settings.BombImplementationPhase to indicate the actual turn phase Bomb+ hits on, and it can be any available WZ TurnPhase

	--del me-- testing only
	-- Mod.Settings.BombImplementationPhase = nil;
	-- Mod.Settings.delayed = false; --Bomb+ hits in BombCards phase
	-- Mod.Settings.delayed = true; --Bomb+ hits in ReceiveCards phase

	-- UI.Alert (BombImplementationPhase.GetText (), WL.TurnPhase.ToString (Mod.Settings.BombImplementationPhase));
	--Mod.Settings.BombImplementationPhase is already set when selecting the turn phase, don't need to do anything here

	local armiesKilled = armiesKilledInput.GetValue();

	Mod.Settings.BombPlusPiecesNeeded = BombPlusCardPiecesNeeded.GetValue ();
	Mod.Settings.BombPlusStartPieces = BombPlusCardStartPieces.GetValue ();
	Mod.Settings.BombPlusPiecesPerTurn = BombPlusPiecesPerTurn.GetValue ();
	Mod.Settings.BombPlusCardWeight = BombPlusCardWeight.GetValue ();
	Mod.Settings.NumCitiesDestroyedByBombPlay = NIFnumCitiesDestroyedByBomb.GetValue ();

	--don't limit this; allow >1000 and negative bomb values; "healing bombs" in essence
	--if armiesKilled < 0 or armiesKilled > 1000 then alert('Armies killed must be set between 0 to 1000'); end
    Mod.Settings.armiesKilled = armiesKilled;

	Mod.Settings.EmptyTerritoriesGoNeutral = cboxEmptyTerritoriesGoNeutral.GetIsChecked();

	local specialUnits = specialUnitsInput.GetIsChecked();
	Mod.Settings.SpecialUnitsPreventNeutral = specialUnits;
	-- Mod.Settings.BombImplementationPhase = BombImplementationPhase.GetText();

	local strBombPlusDesc = get_BombPlus_description (); --"Target a neighbouring enemy territory to inflict ";
	-- if (Mod.Settings.killPercentage == 0 and Mod.Settings.armiesKilled == 0) then strBombPlusDesc = strBombPlusDesc .. "0 ";
	-- elseif (Mod.Settings.killPercentage ~= 0 and Mod.Settings.armiesKilled == 0) then strBombPlusDesc = strBombPlusDesc ..tostring (Mod.Settings.killPercentage).. "% ";
	-- elseif (Mod.Settings.killPercentage == 0 and Mod.Settings.armiesKilled ~= 0) then strBombPlusDesc = strBombPlusDesc ..tostring (Mod.Settings.armiesKilled).. " ";
	-- elseif (Mod.Settings.killPercentage ~= 0 and Mod.Settings.armiesKilled ~= 0) then strBombPlusDesc = strBombPlusDesc ..tostring (Mod.Settings.killPercentage).. "% and " ..tostring (Mod.Settings.armiesKilled).. " ";
	-- end

	-- strBombPlusDesc = strBombPlusDesc .. "damage.\n\n";

	-- if (Mod.Settings.EmptyTerritoriesGoNeutral == true) then strBombPlusDesc = strBombPlusDesc .. "If the target territory is reduced to 0 armies, it will turn neutral ";
	-- 	if (Mod.Settings.SpecialUnitsPreventNeutral == true) then strBombPlusDesc = strBombPlusDesc .."unless a Special Unit is present. ";
	-- 	else strBombPlusDesc = strBombPlusDesc .."and you will lose control of any Special Units present at that time. ";
	-- 	end
	-- end

	-- strBombPlusDesc = strBombPlusDesc .. "Special Units do not take damage.\n\nThis card will execute at the ";

	-- if (Mod.Settings.delayed == true) then strBombPlusDesc = strBombPlusDesc .. "end of the turn (after attack/transfer orders are processed).";
	-- else strBombPlusDesc = strBombPlusDesc .. "start of the turn (after deployments but before attacks).";
	-- end
	print (strBombPlusDesc);

	Mod.Settings.BombCardPlusID = addCard ("Bomb+ Card", strBombPlusDesc, "Bomb Card+ v2_130x180.png", Mod.Settings.BombPlusPiecesNeeded, Mod.Settings.BombPlusPiecesPerTurn, Mod.Settings.BombPlusStartPieces, Mod.Settings.BombPlusCardWeight);
	Mod.Settings.UseCustomCard = true; --indicate that this mod uses a custom card and not the built in Bomb Card; if this ==nil, then the game was created before this functionality was added, so continue using the default Bomb Card
end