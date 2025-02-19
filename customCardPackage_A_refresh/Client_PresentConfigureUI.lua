--[[
Client_PresentConfigureUI (Client_PresentConfigureUI.lua) - player checks mod on Create Game page
Client_SaveConfigureUI (Client_SaveConfigureUI.lua) - player click Submit on Mod page with this mod
Client_PresentSettingsUI (Client_PresentSettingsUI.lua) - player opens Game Settings panel of a game
Client_PresentMenuUI (Client_PresentMenuUI.lua) - player clicks on the mod button in the Game menu
Client_GameOrderCreated (Client_GameOrderCreated.lua) - player creates an order in the client
Client_GameCommit (Client_GameCommit.lua) - player clicks the Commit button in the client
Client_GameRefresh (Client_GameRefresh.lua) - whenever the client gets data about this game from the server
Client_PresentCommercePurchaseUI (Client_PresentCommercePurchaseUI.lua) - player clicks the "Build" button (Commerce game)

TODOs:
- TEST GAME: https://www.warzone.com/MultiPlayer?GameID=40398835
	- Tested and working: Nuke & Card Block, they're working fine, including showing that Nuke doesn't affect Specials; so we don't need to test those anymore (feel free to cast Nukes but let's not do Card Blocks anymore as it stops us from doing more card tests, lol)
	- Still to test: Card Pieces, Pestilence
	- Somewhat tested:
		- Neutralize - 	confirm that stuff reverts back to normal state after X turns
		- Deneutralize - We've tested Deneutralize on natural neutrals, and it works fine, but go ahead and test it on a territory that has been neutralized (maybe take over a Commander); I neutralized this territory Ocean 18 so I'll deneutralize that this turn
		- Isolation - confirm it's blocking movements/airlifts & appropriate messages
		- Quicksand - confirm it's blocking movements/airlifts & appropriate messages 
		- Tornados - Idle power structure shows up; confirm it disappears; damage is OK, confirm is ends at proper time
		- Earthquake - no visual; damage is OK, confirm is ends at proper time
		- Shields - confirm that no damage is taken by units + any damage to attackers
		- Monolith - confirm that it doesn't protect units but protects territory from being taken
	- Change back after TEST GAME is complete: ~line 308 in Server_AdvanceTurn.lua:
						--result.AttackingArmiesKilled = WL.Armies.Create(math.floor(result.AttackingArmiesKilled.NumArmies*Mod.Settings.QuicksandAttackDamageGivenModifier+0.5));
						--result.DefendingArmiesKilled = WL.Armies.Create(math.floor(result.DefendingArmiesKilled.NumArmies*Mod.Settings.QuicksandDefendDamageTakenModifier+0.5));
						result.AttackingArmiesKilled = WL.Armies.Create(math.floor(result.AttackingArmiesKilled.NumArmies*0.5+0.5));
						result.DefendingArmiesKilled = WL.Armies.Create(math.floor(result.DefendingArmiesKilled.NumArmies*1.5+0.5));
						--&&& change me back to the 1st two lines! this is for THE TESTING GAME ONLY b/c the original values are 0's!

- Implement NOW:

- issues to resolve before publishing:
	- change Pestilence alert from UI.Alert to a regular popup with "I understand/I'm ready (will popup a notification on Turn Commit but otherwise will leave you alone and not nag-warn you again)" button & "Remind me again in 10 mins" button
	--*** rename these (after TEST GAME w/MP/Rex is done) to QuicksandDefenderDamageTakenModifier & QuicksandAttackerDamageGivenModifier so it's clear how it applies to the 'result' of an order
		--Mod.Settings.QuicksandDefendDamageTakenModifier = 1.5; --increase damage taken by defender 50% while in quicksand
		--Mod.Settings.QuicksandAttackDamageGivenModifier = 0.5; --reduce damage given by defender 50% while in quicksand
	- desc for Earthquake - add damage to message
	- Quicksand - message "0x damage" - fix the desc
	- nuke - damage rounding down? 10 taking 25%+5 went to 3 which means 2.5 rounded to 2, then +5=7 to get to 3
	- Isolation move skip - use jumplocation to show the territory isolation area
	- Neutralize special - isn't disappearing @ end of duration
	- Pestilence - actually just delay the PlayCard operation until the ACTUAL HIT turn; do the warning in advance, play the card on the appropriate turn to align with Active Cards
	- Isolation - after playing, dialog stays open - close it down!
	- Quicksand - for the combat, instead of doing a full manual attack, perhaps can just subtract x% damage from the attacking units & add y% damage to the defending units on the combat record
	- tornados - multiple tornados on same territory create multiple 'power' structures, but (A) don't do multiple damage hits, (B) only 1 structure is removed @ end; this is b/c it's put into a table by element of that territory, so each overwrites each other to make just 1 entry, hmmmm
	- add Card Hold - restrict # of cards that can be held for X turns
	- add Conceal - cast fog (light?) on a territory (bonus?) to everyone but self
	- add Phantom - unit spawns for X turns that clouds vision to others of anything on the same territory it resides on
	- add Portal/Nydus Canal - create a structure (which building?) for X turns  (or permanent? or make it so territory owner can demolish it [takes 1 turn to do so]) that enables units to travel from 1 portal to another
	- create table/routines to auto-remove special units after X turns; not specific to any card, any card can use it
		- also ensures that if the special is removed @ end of turn, it is replaced
	- Isolation move skip - suppress 1st skip order; no value in it
	- Pestilence - in player selection list, remove players that have been casted on BY YOU already this turn; can't control by others (even if they put it in, they may cancel it)
	- @ end of turn, check if the territories for Isolation/Quicksand are missing special unit visual aids and if so, recreate them
	- ask Fizz to allow negative #'s for specials' power?
	- separate cards into a few different mods; already have the max 5 special unit images per mod for Isolation, Neutralize, Shield, Monolith, Quicksand, so no room to make special unit images for Tornado, Earthquake, Forest Fire
		- mod 1: Nuke, Pestilence, Isolation, Airstrike, Shield, Monolith
		- mod 2: Card Block, Card Pieces, Card Hold (future), Neutralize, Deneutralize
		- mod 3: Quicksand, Tornado, Earthquake, Forest Fire, ?
	- Tornado - add damage reduction % config item, so can make it a permanent tornado that slowly fades away over time
	- Earthquake - add damage reduction % config item, so can make it a permanent tornado that slowly fades away over time
	- Forest Fire - add damage reduction % config item, so it can reduce in damage (or increase) as it spreads
		- change FF "Duration" to "Spread range"
	- add a table for "special unit placements"; for visual cue items such as Isolation, Quicksand, Neutralize, etc - where it's just an indicator of the effect, not a controlable unit
		- this table tracks the units, their IDs and locations, and checks @ end of turn if they are where they should be, and if missing (if destroyed), recreate them; they can't move so no concerns with them being on another territory (exception if something like Swap Territories moves them, etc)
	- Isolation Special - can be blockaded; then there's no visual indicator; write code to detect this, recreate it & update the appropriate IsolationData record with it
	- see if can catch "Shield wore off" order; same for Monolith, Isolation, etc; Pestilence has funny count b/c of Warning turn
	- Pestilence - submit duration+1 as WZ card duration? it'll show up 1 turn early but end on time; or as now, show up early but then end 1 turn early
		OR store Pesti order in table & put in customOrder, but don't call playCard until the warning turn is over and the actual HIT turn is here
	- ISOLATION expirations BROKEN ???
	check for SHIELD, MONOLITH
	- on mod config screen, add blurb beside or beneath checkbox to indicate what each card does; keep mod description short b/c it appends that to top of the mod config screen
	- Pestilence - don't notify Eliminated users that they're being pestilenced; and don't bother implementing it on eliminated users either, just pop the record off
	- any other items to notify in Game_Refresh? there are other duration items but none as comprehensive as Pesti; maybe Earthquake? It won't turn stuff neutral so not as catastrophic
	- disable Neutralize on Commanders, maybe all specials? test with AIs gifted specials - unless Fizz fixes -> going to fix in next update, yay! So don't bother disabling them
	- implement Quicksand - it's essentially a 1-way Isolation (block attack/transfers FROM targetTerritory but not TO) with a different special that causes increased damage, test with the damage field @ -50% instead of +ve
	- implement Tornado - it's essentially a 1-territory Pestilence
	- Nuke - document that negative values = Nuclear healing bombs
	- Monolith - add a Monolith special unit for X turns; does 0 damage with infinite defense BUT combat order is LAST; so it protects nothing but never dies itself thus perfectly protects a territory, can be airlifted? can't be gifted
		- other units can move, live, die on the territory, but the Monolith never dies, so the territory can never be captured by an enemy
	- Shield - add a Shield special unit; the opposite of the Monolith; a unit that does no damage, can't die but is FIRST in combat order; so blocks all normal damage from attacks/bombs/anything that does attacks against armies (.AddArmies)
	- for reference: krinid userID=1058239
	- trying to bring up Menu (wth?) in MP (why is it even there?) generates error trying to reference Game.Us -> which is blank for players not in the game (JK_3 tried it and he's not in the game)
	- Shield description not clear - most users don't understand combat order
	- Monolith - description not complete; can't be killed is clear but not clear that it doesn't protect units
	
- issues to deal with in later version:
	- need to stop SHIELD from moving!
	- Neutralize - if territory is captured but goes Neutral again, it reverts back to original owner; not sure if this is ok or not; hmmm
	- need to stop anything else from moving? other specials? tornado? etc
	- ensure that the "checks" (Pesti/Isolation/CardBlock/etc) aren't running all the time; only do them if there is appropriate data for them (publicGameData) and the card is enabled, else just skip it, certainly don't search for data for every user every turn when it's clear there is none
	- ensure GLOBAL variables aren't going wild; SP behaves differently than MP, recall
	- do some value checking to ensure that things like Isolation Duration is not negative, etc; in SaveConfig
	- check all MOD files for other code, confirm if updates/removals/etc are required
	- check out Fizzer Utitilies function in TankCardMod
	- CAN'T do yet - get rid of 1 of the 2 card order entries; ideally have official Card play order @ top where it belongs, skip the attack order
	- add WEIGHT to the card piece configs
	- add Implementation Phase to more cards
	- most cards missing "# of pieces per turn" UI / setDefault / cardCallBack implementation (oopsie)
	- write code to check for presence of Special Units in moves, namely attack/transfer/airlift moves, and cancel order and replace with order w/o the special - is this necessary? Can't move at all, so just cancel whole move (current state for Isolate) & can't move at all for Neutrals
	- Neutralize
		- add Client side checks for Specials/Commander; similar to Diplo, let player play it if they want; depending on TurnPhase of Neutralize vs other operatoins, maybe player will get the specials off the territory by the time the Neutralize implements
		- finish code to SKIP Neutralizes with specials/commanders in play; code detects it, just needs to actually skip it now
		- AIs cause errors by trying to move units/specials that went neutral - add check to Server_TurnAdvance_Order, cancel order if AI tries to move units from a territory it doesn't own (doh!)
			- ^^^didn't work, game errored out before order was received in Server_TurnAdvance_Order; try looking in Server_TurnAdvance_Start
		- do checks in Server hooks for Neutralize/Deneutralize to ensure that the orders make sense, ie: are casting Neutralize on an owned territory and Deneutralize on a neutral; in case something changed since client check/block hacking
		- add Rex request for "blockade" functionality - to increase armies on the neutral before reverting back to the original amount when it reverts or deneutralizes
		- add a turnPhase implementation - early/later in move
		- Skip orders which can't be executed and would waste resources, eg: airlift on a neutralized territory, don't consume the card, not fair
		- Revert after X turns; is there a FUNC for this? Or is it just manual?
		- Duration -- not accurate; assumption is that it starts from END OF TURN, and thus duration=1 that starts at BEGINNING OF TURN actually ends up being duration 2, eg: T1 start w/duration 1 assumes T1 end of turn thus expires T2 end of turn = 2 turns impacted
		   ^^ feature request to change this?
		   ^^ additional feature request - add event (function) to catch the "card effect wears off" orders; they appear in Advance Turn order list but are never sent to Server_Advance_Turn so can't act on them
		- Add config setting to add Blockade functionality, ie: multiple units by a factor
		- Add config setting that when duration ends and it reverts to units that it goes back to orig armies or multiplied by some factor, recommended <=1.0 but allows >1.0 for crazy junk
		- Add config to set whether it happens at beginning of turn (like EB) or at end of turn (like regular B)
		- Add config whether it works if there are (A) Specials, (B) Structures on the territory
		- ensure Duration is a whole number (>=0), no negatives; same for all cards with Duration
	- Deneutralize
		- add config to specify % loss of units when turning to active territory
			--> ensure correctly implements the reduction from Neutralized territory if the "blockade" functionality is enabled
			--> then additionally apply the % configurable reduction is that config option is enable
		- what happens to Specials on the target territory if Deneutralized to a different player? Notably commander!
		- add a turnPhase implementation - early/later in move
	- Isolation - add checkbox to indicate whether isolation happens @ start of current turn (and affects that turn) or @ end of current turn (and affect starts next turn)
	- use Client side code to checks Orders entered in order to popup note when attacking/transferring to/from Isolated territory or out of Quicksand territory
- improvements to make before publishing:
	- miscellaneous settings - enable Sanction plays on self, enable Sanction plays on others
	- for all cards, add the current missing "num piece to earn per turn" option/setting; currently it defaults to 1 for all (oopsie)
	- change PhaseOrder play point for each card in PlayCard invocation to whatever makes sense for that card
	- add "Jump to Event" aspect to each order (eg: territory being Nuked/Isolated/etc)
	- add some headlines to the popup card play dialogs; they just say "Mod: Custom Card Package v2" (change the name!) --> add a blurb so it's clear that it's Nuke/Iso/Pesti/etc
	- update text on orders derived from PlayCard; can't change position in order list (yet) so just make it a generic "plays discard" type of message
	- Isolation
		- add Client order check when inputs an order to/from an Isolated territory
		- add configuration to block IN moves, OUT moves, airlifts, gifts, deployments
		- hmmm, add configurable attack/damage buff change aspect and this has same function as Quicksand (hmmmm)
	- Pestilence
		- configure to permit X turns in advance of time of card of play; default is 1, 0 is current turn card is played
		- configure for 0->turns to neutral, Yes/No/only if no Specials/Even if there are specials/only if there is a structure/etc
		- config to allow for multiple turns; configurable for crescendo/decrescendo effect
		- change Pesti player selection dialog o Fizz-style full-width style
		- allow negative damage to deliver on the healing bomb requests?
]]

require("UI_Events");
require("utilities");

function Client_PresentConfigureUI(rootParent)
	--[[the following code was used for Game/Mod menu settings; that function has different input parameters: function Client_PresentMenuUI(rootParent, setMaxSize, setScrollable, game, close, refreshed)
	setMaxSize(500, 600); --this only applies to the Game/Mod menus
    
    if refreshed and Close ~= nil and RefreshFunction ~= nil then
        Close();
        RefreshFunction();
        RefreshFunction = nil;
        Close = close;
        return;
    end
    
	print ("init rootparent");
    Init();
    colors = GetColors();
    Game = game;
    Close = close;
    CancelClickIntercept = true;
	]]

	setDefaultValues(); --set defaults for Mod.Settings values if they don't have values already from previous invocation/saved template/etc
	create_card_checkbox_UI_controls (rootParent); --create checkboxes, 1 for each Card to enable/disable appropriately
	update_all_card_UI_display();
	updateModSettingsFromUI(); -- update Mod.Settings values with UI values if the UIs are enabled/populated
end

function create_card_checkbox_UI_controls (rootParent)
	GlobalRoot=nil;
    GlobalRoot = CreateVert(rootParent).SetFlexibleWidth(1);
    Init();
    DestroyWindow();

	local MainModUI = CreateWindow(CreateVert(GlobalRoot).SetFlexibleWidth(1));

	CreateLabel(MainModUI).SetText("Select which cards to enable:").SetColor("#FFFFFF");

	vertNukeSettingsHeading = CreateVert(MainModUI);
	NukeCardCheckbox = CreateCheckBox(vertNukeSettingsHeading).SetText("Nuke").SetIsChecked(Mod.Settings.NukeEnabled).SetOnValueChanged(function() nukeCheckboxClicked() end).SetInteractable (true); --.SetColor ("#FFFFFF");

	vertPestiSettingsHeading = CreateVert(MainModUI);
	PestilenceCheckbox = CreateCheckBox(vertPestiSettingsHeading).SetText("Pestilence").SetIsChecked(Mod.Settings.PestilenceEnabled).SetOnValueChanged(function() pestilenceCheckboxClicked() end).SetInteractable(true);

	vertIsolationSettingsHeading = CreateVert(MainModUI);
	IsolationCardCheckbox = CreateCheckBox(vertIsolationSettingsHeading).SetText("Isolation").SetIsChecked(Mod.Settings.IsolationEnabled).SetOnValueChanged(function() isolationCheckboxClicked() end).SetInteractable(true);

	vertShieldSettingsHeading = CreateVert(MainModUI);
    ShieldCardCheckbox = CreateCheckBox(vertShieldSettingsHeading).SetText("Shield").SetIsChecked(Mod.Settings.ShieldEnabled).SetOnValueChanged(function() shieldCheckboxClicked() end).SetInteractable(true);

	vertMonolithSettingsHeading = CreateVert(MainModUI);
	MonolithCardCheckbox = CreateCheckBox(vertMonolithSettingsHeading).SetText("Monolith").SetIsChecked(Mod.Settings.MonolithEnabled).SetOnValueChanged(function() monolithCheckboxClicked() end).SetInteractable(true);

	vertNeutralizeSettingsHeading = CreateVert(MainModUI);
	NeutralizeCardCheckbox = CreateCheckBox(vertNeutralizeSettingsHeading).SetText("Neutralize").SetIsChecked(Mod.Settings.NeutralizeEnabled).SetOnValueChanged(function() neutralizeCheckboxClicked() end).SetInteractable(true);

	vertDeneutralizeSettingsHeading = CreateVert(MainModUI);
	DeneutralizeCardCheckbox = CreateCheckBox(vertDeneutralizeSettingsHeading).SetText("Deneutralize").SetIsChecked(Mod.Settings.DeneutralizeEnabled).SetOnValueChanged(function() deneutralizeCheckboxClicked() end).SetInteractable(true);

	vertCardBlockSettingsHeading = CreateVert(MainModUI);
	CardBlockCardCheckbox = CreateCheckBox(vertCardBlockSettingsHeading).SetText("Card Block").SetIsChecked(Mod.Settings.CardBlockEnabled).SetOnValueChanged(function() cardBlockCheckboxClicked() end).SetInteractable(true);

	vertCardPiecesSettingsHeading = CreateVert(MainModUI);
	CardPiecesCardCheckbox = CreateCheckBox(vertCardPiecesSettingsHeading).SetText("Card Pieces").SetIsChecked(Mod.Settings.CardPiecesEnabled).SetOnValueChanged(function() cardPiecesCheckboxClicked() end).SetInteractable(true);
	
	vertTornadoSettingsHeading = CreateVert(MainModUI);
	TornadoCardCheckbox = CreateCheckBox(vertTornadoSettingsHeading).SetText("Tornado").SetIsChecked(Mod.Settings.TornadoEnabled).SetOnValueChanged(function() tornadoCheckboxClicked() end).SetInteractable(true);
	
	vertQuicksandSettingsHeading = CreateVert(MainModUI);
	QuicksandCardCheckbox = CreateCheckBox(vertQuicksandSettingsHeading).SetText("Quicksand").SetIsChecked(Mod.Settings.QuicksandEnabled).SetOnValueChanged(function() quicksandCheckboxClicked() end).SetInteractable(true);

	vertEarthquakeSettingsHeading = CreateVert(MainModUI);
	EarthquakeCardCheckbox = CreateCheckBox(vertEarthquakeSettingsHeading).SetText("Earthquake").SetIsChecked(Mod.Settings.EarthquakeEnabled).SetOnValueChanged(function() earthquakeCheckboxClicked() end).SetInteractable(true);
	
	vertAirstrikeSettingsHeading = CreateVert(MainModUI);
	CreateLabel(vertAirstrikeSettingsHeading).SetText ("- - - - - Coming soon - - - - -");
	AirstrikeCardCheckbox = CreateCheckBox(vertAirstrikeSettingsHeading).SetText("Airstrike").SetIsChecked(Mod.Settings.AirstrikeEnabled).SetOnValueChanged(function() airstrikeCheckboxClicked() end).SetInteractable(true);

	vertForestFireSettingsHeading = CreateVert(MainModUI);
	ForestFireCardCheckbox = CreateCheckBox(vertForestFireSettingsHeading).SetText("Forest Fire").SetIsChecked(Mod.Settings.ForestFireEnabled).SetOnValueChanged(function() forestFireCheckboxClicked() end).SetInteractable(true);
end

function update_all_card_UI_display()
	--call the functions for each Card type to update the UI; this is necessary for when the cards are enabled already and the Mod Settings menu is opened; eg: from a saved template or just going back into Mods after Submitting
	nukeCheckboxClicked();
	pestilenceCheckboxClicked();
	isolationCheckboxClicked();
	shieldCheckboxClicked();
	monolithCheckboxClicked();
	neutralizeCheckboxClicked();
	deneutralizeCheckboxClicked();
	cardBlockCheckboxClicked();
	cardPiecesCheckboxClicked();
	tornadoCheckboxClicked();
	quicksandCheckboxClicked();
	airstrikeCheckboxClicked();
	forestFireCheckboxClicked();
	earthquakeCheckboxClicked();
end

function cardBlockCheckboxClicked()
    print("Card Block card checkbox clicked");
    Mod.Settings.CardBlockEnabled = CardBlockCardCheckbox.GetIsChecked();
    if (CardBlockCardCheckbox.GetIsChecked() == false) then
        if (vertCardBlockSettingsDetails ~= nil) then
            updateModSettingsFromUI();
            UI.Destroy(vertCardBlockSettingsDetails);
        end
    else
        vertCardBlockSettingsDetails = CreateVert(vertCardBlockSettingsHeading);
        local UIcontainer = vertCardBlockSettingsDetails;
        local horzCardBlockDuration = CreateHorz(UIcontainer);
        CreateLabel(horzCardBlockDuration).SetText("Duration: ");
        CardBlockDuration = CreateNumberInputField(horzCardBlockDuration).SetSliderMinValue(1).SetSliderMaxValue(5).SetValue(Mod.Settings.CardBlockDuration).SetWholeNumbers(true).SetInteractable(true);
       
		local horzCardBlockPiecesNeeded = CreateHorz(UIcontainer);
        CreateLabel(horzCardBlockPiecesNeeded).SetText("Number of pieces to divide the card into: ");
        CardBlockPiecesNeeded = CreateNumberInputField(horzCardBlockPiecesNeeded).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.CardBlockPiecesNeeded).SetWholeNumbers(true).SetInteractable(true);
        
		local horzCardBlockStartPieces = CreateHorz(UIcontainer);
        CreateLabel(horzCardBlockStartPieces).SetText("Pieces given to each player at the start: ");
        CardBlockStartPieces = CreateNumberInputField(horzCardBlockStartPieces).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.CardBlockStartPieces).SetWholeNumbers(true).SetInteractable(true);
        
		local horzCardBlockPiecesPerTurn = CreateHorz(UIcontainer);
        CreateLabel(horzCardBlockPiecesPerTurn).SetText("Minimum pieces awarded per turn: ");
        CardBlockPiecesPerTurn = CreateNumberInputField(horzCardBlockPiecesPerTurn).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.CardBlockPiecesPerTurn).SetWholeNumbers(true).SetInteractable(true);

		local horzCardBlockCardWeight = CreateHorz(UIcontainer);
		CreateLabel(horzCardBlockCardWeight).SetText("Card weight: ");
		CardBlockCardWeight = CreateNumberInputField(horzCardBlockCardWeight).SetSliderMinValue(0).SetSliderMaxValue(10).SetValue(Mod.Settings.CardBlockCardWeight).SetWholeNumbers(false).SetInteractable(true);		
	end
end

-- EARTHQUAKE UI: similar to Pestilence UI.
function earthquakeCheckboxClicked()
    print("Earthquake card checkbox clicked");
    Mod.Settings.EarthquakeEnabled = EarthquakeCardCheckbox.GetIsChecked();
    if (EarthquakeCardCheckbox.GetIsChecked() == false) then
        if (vertEarthquakeSettingsDetails ~= nil) then
            updateModSettingsFromUI();
            UI.Destroy(vertEarthquakeSettingsDetails);
        end
    else
        vertEarthquakeSettingsDetails = CreateVert(vertEarthquakeSettingsHeading);
        local UIcontainer = vertEarthquakeSettingsDetails;
        local horzEarthquakeDuration = CreateHorz(UIcontainer);
        CreateLabel(horzEarthquakeDuration).SetText("Duration: ");
        EarthquakeDuration = CreateNumberInputField(horzEarthquakeDuration).SetSliderMinValue(1).SetSliderMaxValue(5).SetValue(Mod.Settings.EarthquakeDuration).SetWholeNumbers(true).SetInteractable(true);

		local horzEarthquakeStrength = CreateHorz(UIcontainer);
        CreateLabel(horzEarthquakeStrength).SetText("Strength: ");
        EarthquakeStrength = CreateNumberInputField(horzEarthquakeStrength).SetSliderMinValue(1).SetSliderMaxValue(100).SetValue(Mod.Settings.EarthquakeStrength).SetWholeNumbers(true).SetInteractable(true);

		local horzEarthquakePiecesNeeded = CreateHorz(UIcontainer);
        CreateLabel(horzEarthquakePiecesNeeded).SetText("Number of pieces to divide the card into: ");
        EarthquakePiecesNeeded = CreateNumberInputField(horzEarthquakePiecesNeeded).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.EarthquakePiecesNeeded).SetWholeNumbers(true).SetInteractable(true);

		local horzEarthquakeStartPieces = CreateHorz(UIcontainer);
        CreateLabel(horzEarthquakeStartPieces).SetText("Pieces given to each player at the start: ");
        EarthquakeStartPieces = CreateNumberInputField(horzEarthquakeStartPieces).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.EarthquakeStartPieces).SetWholeNumbers(true).SetInteractable(true);

		local horzEarthquakePiecesPerTurn = CreateHorz(UIcontainer);
        CreateLabel(horzEarthquakePiecesPerTurn).SetText("Minimum pieces awarded per turn: ");
        EarthquakePiecesPerTurn = CreateNumberInputField(horzEarthquakePiecesPerTurn).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.EarthquakePiecesPerTurn).SetWholeNumbers(true).SetInteractable(true);

		local horzEarthquakeCardWeight = CreateHorz(UIcontainer);
		CreateLabel(horzEarthquakeCardWeight).SetText("Card weight: ");
		EarthquakeCardWeight = CreateNumberInputField(horzEarthquakeCardWeight).SetSliderMinValue(0).SetSliderMaxValue(10).SetValue(Mod.Settings.EarthquakeCardWeight).SetWholeNumbers(false).SetInteractable(true);
	end
end

-- TORNADO UI: similar to Pestilence UI.
function tornadoCheckboxClicked()
    print("Tornado card checkbox clicked");
    Mod.Settings.TornadoEnabled = TornadoCardCheckbox.GetIsChecked();
    if (TornadoCardCheckbox.GetIsChecked() == false) then
        if (vertTornadoSettingsDetails ~= nil) then
            updateModSettingsFromUI();
            UI.Destroy(vertTornadoSettingsDetails);
        end
    else
        vertTornadoSettingsDetails = CreateVert(vertTornadoSettingsHeading);
        local UIcontainer = vertTornadoSettingsDetails;
        local horzTornadoDuration = CreateHorz(UIcontainer);
        CreateLabel(horzTornadoDuration).SetText("Duration: ");
        TornadoDuration = CreateNumberInputField(horzTornadoDuration).SetSliderMinValue(1).SetSliderMaxValue(5).SetValue(Mod.Settings.TornadoDuration).SetWholeNumbers(true).SetInteractable(true);
        CreateLabel(horzTornadoDuration).SetText("(use -1 to make Tornados permanent)");

		local horzTornadoStrength = CreateHorz(UIcontainer);
        CreateLabel(horzTornadoStrength).SetText("Strength: ");
        TornadoStrength = CreateNumberInputField(horzTornadoStrength).SetSliderMinValue(1).SetSliderMaxValue(25).SetValue(Mod.Settings.TornadoStrength).SetWholeNumbers(true).SetInteractable(true);

		local horzTornadoPiecesNeeded = CreateHorz(UIcontainer);
        CreateLabel(horzTornadoPiecesNeeded).SetText("Number of pieces to divide the card into: ");
        TornadoPiecesNeeded = CreateNumberInputField(horzTornadoPiecesNeeded).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.TornadoPiecesNeeded).SetWholeNumbers(true).SetInteractable(true);

		local horzTornadoStartPieces = CreateHorz(UIcontainer);
        CreateLabel(horzTornadoStartPieces).SetText("Pieces given to each player at the start: ");
        TornadoStartPieces = CreateNumberInputField(horzTornadoStartPieces).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.TornadoStartPieces).SetWholeNumbers(true).SetInteractable(true);

		local horzTornadoPiecesPerTurn = CreateHorz(UIcontainer);
        CreateLabel(horzTornadoPiecesPerTurn).SetText("Minimum pieces awarded per turn: ");
        TornadoPiecesPerTurn = CreateNumberInputField(horzTornadoPiecesPerTurn).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.TornadoPiecesPerTurn).SetWholeNumbers(true).SetInteractable(true);

		local horzTornadoCardWeight = CreateHorz(UIcontainer);
		CreateLabel(horzTornadoCardWeight).SetText("Card weight: ");
		TornadoCardWeight = CreateNumberInputField(horzTornadoCardWeight).SetSliderMinValue(0).SetSliderMaxValue(10).SetValue(Mod.Settings.TornadoCardWeight).SetWholeNumbers(false).SetInteractable(true);		
	end
end

-- QUICKSAND UI: similar to Isolation UI.
function quicksandCheckboxClicked()
    print("Quicksand card checkbox clicked");
    Mod.Settings.QuicksandEnabled = QuicksandCardCheckbox.GetIsChecked();
    if (QuicksandCardCheckbox.GetIsChecked() == false) then
        if (vertQuicksandSettingsDetails ~= nil) then
            updateModSettingsFromUI();
            UI.Destroy(vertQuicksandSettingsDetails);
        end
    else
		vertQuicksandSettingsDetails = CreateVert(vertQuicksandSettingsHeading);
        local UIcontainer = vertQuicksandSettingsDetails;
        local horzQuicksandDuration = CreateHorz(UIcontainer);
        CreateLabel(horzQuicksandDuration).SetText("Duration: ");
        QuicksandDuration = CreateNumberInputField(horzQuicksandDuration).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.QuicksandDuration).SetWholeNumbers(true).SetInteractable(true);
        
		local horzQuicksandBlockEntry = CreateHorz(UIcontainer);
        QuicksandBlockEntryIntoTerritory = CreateCheckBox(horzQuicksandBlockEntry).SetText("Block entry into territory").SetIsChecked(Mod.Settings.QuicksandBlockEntryIntoTerritory).SetInteractable(true);
        
		local horzQuicksandBlockAirliftIn = CreateHorz(UIcontainer);
        QuicksandBlockAirliftsIntoTerritory = CreateCheckBox(horzQuicksandBlockAirliftIn).SetText("Block airlifts into territory").SetIsChecked(Mod.Settings.QuicksandBlockAirliftsIntoTerritory).SetInteractable(true);
       
		local horzQuicksandBlockAirliftOut = CreateHorz(UIcontainer);
        QuicksandBlockAirliftsFromTerritory = CreateCheckBox(horzQuicksandBlockAirliftOut).SetText("Block airlifts from territory").SetIsChecked(Mod.Settings.QuicksandBlockAirliftsFromTerritory).SetInteractable(true);
        
		local horzQuicksandBlockExit = CreateHorz(UIcontainer);
        QuicksandBlockExitFromTerritory = CreateCheckBox(horzQuicksandBlockExit).SetText("Block exit from territory").SetIsChecked(Mod.Settings.QuicksandBlockExitFromTerritory).SetInteractable(true);
        
		local horzQuicksandDefendMod = CreateHorz(UIcontainer);
        CreateLabel(horzQuicksandDefendMod).SetText("FUTURE IMPLEMENTATION - Defend damage modifier: ");
        QuicksandDefendDamageTakenModifier = CreateNumberInputField(horzQuicksandDefendMod).SetSliderMinValue(0.1).SetSliderMaxValue(2.0).SetValue(Mod.Settings.QuicksandDefendDamageTakenModifier).SetWholeNumbers(false).SetInteractable(true);
        
		local horzQuicksandAttackMod = CreateHorz(UIcontainer);
        CreateLabel(horzQuicksandAttackMod).SetText("FUTURE IMPLEMENTATION - Attack damage modifier: ");
        QuicksandAttackDamageGivenModifier = CreateNumberInputField(horzQuicksandAttackMod).SetSliderMinValue(0.1).SetSliderMaxValue(2.0).SetValue(Mod.Settings.QuicksandAttackDamageGivenModifier).SetWholeNumbers(false).SetInteractable(true);
        
		local horzQuicksandPiecesNeeded = CreateHorz(UIcontainer);
        CreateLabel(horzQuicksandPiecesNeeded).SetText("Number of pieces to divide the card into: ");
        QuicksandPiecesNeeded = CreateNumberInputField(horzQuicksandPiecesNeeded).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.QuicksandPiecesNeeded).SetWholeNumbers(true).SetInteractable(true);
        
		local horzQuicksandStartPieces = CreateHorz(UIcontainer);
        CreateLabel(horzQuicksandStartPieces).SetText("Pieces given to each player at the start: ");
        QuicksandStartPieces = CreateNumberInputField(horzQuicksandStartPieces).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.QuicksandStartPieces).SetWholeNumbers(true).SetInteractable(true);
        
		local horzQuicksandPiecesPerTurn = CreateHorz(UIcontainer);
        CreateLabel(horzQuicksandPiecesPerTurn).SetText("Minimum pieces awarded per turn: ");
        QuicksandPiecesPerTurn = CreateNumberInputField(horzQuicksandPiecesPerTurn).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.QuicksandPiecesPerTurn).SetWholeNumbers(true).SetInteractable(true);

		local horzQuicksandCardWeight = CreateHorz(UIcontainer);
		CreateLabel(horzQuicksandCardWeight).SetText("Card weight: ");
		QuicksandCardWeight = CreateNumberInputField(horzQuicksandCardWeight).SetSliderMinValue(0).SetSliderMaxValue(10).SetValue(Mod.Settings.QuicksandCardWeight).SetWholeNumbers(false).SetInteractable(true);		
	end
end

function shieldCheckboxClicked()
    print("Shield card checkbox clicked");
    
    Mod.Settings.ShieldEnabled = ShieldCardCheckbox.GetIsChecked();
    
    if (ShieldCardCheckbox.GetIsChecked() == false) then
        print("clear Shield settings from UI");
        
        if (vertShieldSettingsDetails ~= nil) then
            print("destroy Shield UI items");
            updateModSettingsFromUI();
            UI.Destroy(vertShieldSettingsDetails);
        else
            print("DON'T destroy Shield UI items");
        end
    else
        print("create vert");
        vertShieldSettingsDetails = CreateVert(vertShieldSettingsHeading);
        local UIcontainer = vertShieldSettingsDetails;
        
        horzShieldDuration = CreateHorz(UIcontainer);
        CreateLabel(horzShieldDuration).SetText("Duration: ");
        CreateLabel(UIcontainer).SetText("(use -1 to make permanent; caution: may prevent some games from ending)");
        ShieldDuration = CreateNumberInputField(horzShieldDuration).SetSliderMinValue(1).SetSliderMaxValue(5).SetValue(Mod.Settings.ShieldDuration).SetWholeNumbers(true).SetInteractable(true);
        
        horzShieldPiecesNeeded = CreateHorz(UIcontainer);
        CreateLabel(horzShieldPiecesNeeded).SetText("Number of pieces to divide the card into: ");
        ShieldPiecesNeeded = CreateNumberInputField(horzShieldPiecesNeeded).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.ShieldPiecesNeeded).SetWholeNumbers(true).SetInteractable(true);
        
        horzShieldStartPieces = CreateHorz(UIcontainer);
        CreateLabel(horzShieldStartPieces).SetText("Pieces given to each player at the start: ");
        ShieldStartPieces = CreateNumberInputField(horzShieldStartPieces).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.ShieldStartPieces).SetWholeNumbers(true).SetInteractable(true);
        
        horzShieldPiecesPerTurn = CreateHorz(UIcontainer);
        CreateLabel(horzShieldPiecesPerTurn).SetText("Minimum pieces awarded per turn: ");
        ShieldPiecesPerTurn = CreateNumberInputField(horzShieldPiecesPerTurn).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.ShieldPiecesPerTurn).SetWholeNumbers(true).SetInteractable(true);
        
        horzShieldCardWeight = CreateHorz(UIcontainer);
        CreateLabel(horzShieldCardWeight).SetText("Card weight (how common the card is): ");
        ShieldCardWeight = CreateNumberInputField(horzShieldCardWeight).SetSliderMinValue(0).SetSliderMaxValue(10).SetValue(Mod.Settings.ShieldCardWeight).SetWholeNumbers(false).SetInteractable(true);
    end
end

function monolithCheckboxClicked()
	print("Monolith card checkbox clicked");

	Mod.Settings.MonolithEnabled = MonolithCardCheckbox.GetIsChecked();

	if (MonolithCardCheckbox.GetIsChecked() == false) then
		print("clear Monolith settings from UI");

		if (vertMonolithSettingsDetails ~= nil) then
			print("destroy Monolith UI items");
			updateModSettingsFromUI();
			UI.Destroy(vertMonolithSettingsDetails);
		else
			print("DON'T destroy Monolith UI items");
		end
	else
		print("create vert");
		vertMonolithSettingsDetails = CreateVert(vertMonolithSettingsHeading);
		UIcontainer = vertMonolithSettingsDetails;

		horzMonolithDuration = CreateHorz(UIcontainer);

		CreateLabel(horzMonolithDuration).SetText("Duration: ");
		CreateLabel(UIcontainer).SetText("(use -1 to make permanent; but be cautioned that this may prevent some games from ending, because you can never eliminate a territory where a Monolith is present)");
		MonolithDuration = CreateNumberInputField(horzMonolithDuration).SetSliderMinValue(1).SetSliderMaxValue(5).SetValue(Mod.Settings.MonolithDuration).SetWholeNumbers(true).SetInteractable(true);

		horzMonolithPiecesNeeded = CreateHorz(UIcontainer);
		CreateLabel(horzMonolithPiecesNeeded).SetText("Number of pieces to divide the card into: ");
		MonolithPiecesNeeded = CreateNumberInputField(horzMonolithPiecesNeeded).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.MonolithPiecesNeeded).SetWholeNumbers(true).SetInteractable(true);

		horzMonolithStartPieces = CreateHorz(UIcontainer);
		CreateLabel(horzMonolithStartPieces).SetText("Pieces given to each player at the start: ");
		MonolithStartPieces = CreateNumberInputField(horzMonolithStartPieces).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.MonolithStartPieces).SetWholeNumbers(true).SetInteractable(true);

		horzMonolithPiecesPerTurn = CreateHorz(UIcontainer);
		CreateLabel(horzMonolithPiecesPerTurn).SetText("Minimum pieces awarded per turn: ");
		MonolithPiecesPerTurn = CreateNumberInputField(horzMonolithPiecesPerTurn).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.MonolithPiecesPerTurn).SetWholeNumbers(true).SetInteractable(true);

		horzMonolithCardWeight = CreateHorz(UIcontainer);
		CreateLabel(horzMonolithCardWeight).SetText("Card weight (how common the card is): ");
		MonolithCardWeight = CreateNumberInputField(horzMonolithCardWeight).SetSliderMinValue(0).SetSliderMaxValue(10).SetValue(Mod.Settings.MonolithCardWeight).SetWholeNumbers(false).SetInteractable(true);
	end
end

function neutralizeCheckboxClicked()
	local win = "neutralizeCheckboxClicked";
	print("neutralizeCheckboxClicked");
	Mod.Settings.NeutralizeEnabled = NeutralizeCardCheckbox.GetIsChecked();

	if (NeutralizeCardCheckbox.GetIsChecked() == false) then
		print("clear Neutralize settings from UI");

		if (vertNeutralizeSettingsDetails ~= nil) then
			print("destroy Neutralize UI items");
			updateModSettingsFromUI();
			UI.Destroy(vertNeutralizeSettingsDetails);
		else
			print("DON'T destroy Neutralize UI items");
		end
	else
		print("create vert");
		vertNeutralizeSettingsDetails = CreateVert(vertNeutralizeSettingsHeading);
		UIcontainer = vertNeutralizeSettingsDetails;
		print("create hori");

		print("NeutralizeCanUseOnCommander="..tostring(Mod.Settings.NeutralizeCanUseOnCommander));
        print("NeutralizeCanUseOnSpecials="..tostring(Mod.Settings.NeutralizeCanUseOnSpecials));
        print("DeneutralizeCanUseOnCommander="..tostring(Mod.Settings.NeutralizeCanUseOnCommander));
        print("DeneutralizeCanUseOnSpecials="..tostring(Mod.Settings.NeutralizeCanUseOnSpecials));

		print("create label");
		horzNeutralizeDuration = CreateHorz(UIcontainer);
		CreateLabel(horzNeutralizeDuration).SetText("Duration: ");
		NeutralizeCardDuration = CreateNumberInputField(horzNeutralizeDuration).SetSliderMinValue(1).SetSliderMaxValue(5).SetValue(Mod.Settings.NeutralizeDuration).SetWholeNumbers(true).SetInteractable(true);
		CreateLabel(UIcontainer).SetText("(Use -1 to make Neutralize permanent)"); --"; be careful with this setting as it can make a game impossible to finish depending on the other game settings)");
		--is permanent Neutralize capable of creating a situation where a game can't conclude? Commander game, 2 players each have 1 territory only with Commander on it, they Neutralize each other; they are either both eliminated or both play on but can't move b/c Commanders are on Neutral territories
		--don't think so b/c once they lose their last territories, it's gg; whichever goes to 0 territories first loses

		horzNeutralizeCanUseOnCommander = CreateHorz(UIcontainer);
		NeutralizeCanUseOnCommander = CreateCheckBox(horzNeutralizeCanUseOnCommander).SetIsChecked(Mod.Settings.NeutralizeCanUseOnCommander).SetInteractable(true).SetText("Can use on Commander");
		horzNeutralizeCanUseOnSpecials = CreateHorz(UIcontainer);
		NeutralizeCanUseOnSpecials = CreateCheckBox(horzNeutralizeCanUseOnSpecials).SetIsChecked(Mod.Settings.NeutralizeCanUseOnSpecials).SetInteractable(true).SetText("Can use on Special Units");

		horzNeutralizePiecesNeeded = CreateHorz(UIcontainer);
		CreateLabel(horzNeutralizePiecesNeeded).SetText("Number of pieces to divide the card into: ");
		NeutralizePiecesNeeded = CreateNumberInputField(horzNeutralizePiecesNeeded).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.NeutralizePiecesNeeded).SetWholeNumbers(true).SetInteractable(true);

		horzNeutralizeStartPieces = CreateHorz(UIcontainer);
		CreateLabel(horzNeutralizeStartPieces).SetText("Pieces given to each player at the start: ");
		NeutralizeStartPieces = CreateNumberInputField(horzNeutralizeStartPieces).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.NeutralizeStartPieces).SetWholeNumbers(true).SetInteractable(true);

		local horzNeutralizeCardWeight = CreateHorz(UIcontainer);
		CreateLabel(horzNeutralizeCardWeight).SetText("Card weight: ");
		NeutralizeCardWeight = CreateNumberInputField(horzNeutralizeCardWeight).SetSliderMinValue(0).SetSliderMaxValue(10).SetValue(Mod.Settings.NeutralizeCardWeight).SetWholeNumbers(false).SetInteractable(true);		
	end
	print("Neutralize card checkbox clicked")
end

function deneutralizeCheckboxClicked()
	local win = "deneutralizeCheckboxClicked";
	print("deneutralizeCheckboxClicked");
	Mod.Settings.DeneutralizeEnabled = DeneutralizeCardCheckbox.GetIsChecked();
	print("DeneutralizeEnabled==" .. tostring(Mod.Settings.DeneutralizeEnabled) .. "::");
	print("Mod.Settings.DeneutralizeCanUseOnNeutralizedTerritories==" .. tostring(Mod.Settings.DeneutralizeCanUseOnNeutralizedTerritories) .. "::");

	if (DeneutralizeCardCheckbox.GetIsChecked() == false) then
		print("clear Deneutralize settings from UI");

		if (vertDeneutralizeSettingsDetails ~= nil) then
			print("destroy Deneutralize UI items");
			updateModSettingsFromUI();
			UI.Destroy(vertDeneutralizeSettingsDetails);
		else
			print("DON'T destroy Deneutralize UI items");
		end
	else
		print("create vert");
		vertDeneutralizeSettingsDetails = CreateVert(vertDeneutralizeSettingsHeading);
		UIcontainer = vertDeneutralizeSettingsDetails;
		print("create hori");

		DeneutralizeDetailslineCardDesc = CreateVert(UIcontainer);
		CreateLabel(DeneutralizeDetailslineCardDesc).SetText("Assign ownership of a neutral territory to a player.\n");

		horzDeneutralizeCanUseOnNaturalNeutrals = CreateHorz(UIcontainer);
		DeneutralizeCanUseOnNaturalNeutrals = CreateCheckBox(horzDeneutralizeCanUseOnNaturalNeutrals).SetIsChecked(Mod.Settings.DeneutralizeCanUseOnNaturalNeutrals).SetInteractable(true).SetText("Can use on natural neutrals (not caused by Neutralize)");

		horzDeneutralizeCanUseOnNeutralizedTerritories = CreateHorz(UIcontainer);
		DeneutralizeCanUseOnNeutralizedTerritories = CreateCheckBox(horzDeneutralizeCanUseOnNeutralizedTerritories).SetIsChecked(Mod.Settings.DeneutralizeCanUseOnNeutralizedTerritories).SetInteractable(true).SetText("Can use on Neutralized territories");

		--set UI controls for Assign to self & Assign to another player to be non-interactive (greyed out) and default values to True & False respectively
		--not implementing these options at this time, so default to assign Deneutralize action to self only
		horzDeneutralizeCanAssignToSelf = CreateHorz(UIcontainer);
		DeneutralizeCanAssignToSelf = CreateCheckBox(horzDeneutralizeCanAssignToSelf).SetIsChecked(Mod.Settings.DeneutralizeCanAssignToSelf).SetInteractable(false).SetText("Can assign to self");
		--DeneutralizeCanAssignToSelf = CreateCheckBox(horzDeneutralizeCanAssignToSelf).SetIsChecked(Mod.Settings.DeneutralizeCanAssignToSelf).SetInteractable(false).SetText("Can assign to self");

		horzDeneutralizeCanAssignToAnotherPlayer = CreateHorz(UIcontainer);
		DeneutralizeCanAssignToAnotherPlayer = CreateCheckBox(horzDeneutralizeCanAssignToAnotherPlayer).SetIsChecked(Mod.Settings.DeneutralizeCanAssignToAnotherPlayer).SetInteractable(false).SetText("Can assign to another player");
		--DeneutralizeCanAssignToAnotherPlayer = CreateCheckBox(horzDeneutralizeCanAssignToAnotherPlayer).SetIsChecked(Mod.Settings.DeneutralizeCanAssignToAnotherPlayer).SetInteractable(true).SetText("Can assign to another player");

		horzDeneutralizeCardPiecesNeeded = CreateHorz(UIcontainer);
		CreateLabel (horzDeneutralizeCardPiecesNeeded).SetText("Number of pieces to divide the card into: ")
		DeneutralizeCardPiecesNeeded = CreateNumberInputField(horzDeneutralizeCardPiecesNeeded).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.DeneutralizePiecesNeeded).SetWholeNumbers(true).SetInteractable(true);

		horzDeneutralizeCardStartPieces = CreateHorz(UIcontainer);
		CreateLabel (horzDeneutralizeCardStartPieces).SetText("Pieces given to each player at the start: ")
		DeneutralizeCardStartPieces = CreateNumberInputField(horzDeneutralizeCardStartPieces).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.DeneutralizeStartPieces).SetWholeNumbers(true).SetInteractable(true);

		local horzDeneutralizeCardWeight = CreateHorz(UIcontainer);
		CreateLabel(horzDeneutralizeCardWeight).SetText("Card weight: ");
		DeneutralizeCardWeight = CreateNumberInputField(horzDeneutralizeCardWeight).SetSliderMinValue(0).SetSliderMaxValue(10).SetValue(Mod.Settings.DeneutralizeCardWeight).SetWholeNumbers(false).SetInteractable(true);		
	end
	print("Deneutralize card checkbox clicked")
	print("Mod.Settings.DeneutralizeCanUseOnNeutralizedTerritories==" .. tostring(Mod.Settings.DeneutralizeCanUseOnNeutralizedTerritories) .. "::");
end

function cardPiecesCheckboxClicked()
    -- Add your logic for Card Pieces card checkbox click here
    print("Card Pieces card checkbox clicked")
	local win = "cardPiecesCheckboxClicked";
	print("START cardPiecesCheckboxClicked");
	Mod.Settings.CardPiecesEnabled = CardPiecesCardCheckbox.GetIsChecked();
	print("CardPiecesCardCheckbox.GetIsChecked() == " .. tostring(CardPiecesCardCheckbox.GetIsChecked()).."::");
	print("Mod.Settings.CardPiecesEnabled == " .. tostring(Mod.Settings.CardPiecesEnabled).."::");

	if (CardPiecesCardCheckbox.GetIsChecked() == false) then
		print("clear Card Pieces settings from UI");

		if (CardPiecesDetailsline1 ~= nil) then
			print("destroy Card Pieces UI items");
			updateModSettingsFromUI();
			UI.Destroy(vertCardPiecesSettingsDetails);
		else
			print("DON'T destroy Card Pieces UI items");
		end
	else
		print("create vert");
		vertCardPiecesSettingsDetails = CreateVert(vertCardPiecesSettingsHeading);
		UIcontainer = vertCardPiecesSettingsDetails;
		print("create hori");
		CardPiecesDetailslineCardDesc = CreateHorz(UIcontainer);
		CardPiecesDetailsline1 = CreateHorz(UIcontainer);
		CardPiecesDetailsline2 = CreateHorz(UIcontainer);
		CardPiecesDetailsline3 = CreateHorz(UIcontainer);
		CardPiecesDetailsline4 = CreateHorz(UIcontainer);
		CardPiecesDetailsline5 = CreateHorz(UIcontainer);
		CardPiecesDetailsline6 = CreateHorz(UIcontainer);

		CreateLabel(CardPiecesDetailslineCardDesc).SetText("This card will grant you cards or pieces of other cards used in the game. It cannot be played to receive cards or pieces of the Card Piece card itself.\n");
		CreateLabel(CardPiecesDetailsline1).SetText("[FOR THE CARDS RECEIVED WHEN PLAYING a Card Piece card]");

		CreateLabel(CardPiecesDetailsline2).SetText("   Number of whole cards to grant: ");
		CardPiecesNumWholeCardsToGrant = CreateNumberInputField(CardPiecesDetailsline2).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.CardPiecesNumWholeCardsToGrant).SetWholeNumbers(true).SetInteractable(true);

		CreateLabel(CardPiecesDetailsline3).SetText("   Number of card pieces to grant:  ");
		CardPiecesNumCardPiecesToGrant = CreateNumberInputField(CardPiecesDetailsline3).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.CardPiecesNumCardPiecesToGrant).SetWholeNumbers(true).SetInteractable(true);

		CreateLabel(CardPiecesDetailsline4).SetText("[FOR COLLECTING the Card Piece card itself]");

		CreateLabel(CardPiecesDetailsline5).SetText("   Pieces needed to form a whole card: ");
		CardPiecesPiecesNeeded = CreateNumberInputField(CardPiecesDetailsline5).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.CardPiecesPiecesNeeded).SetWholeNumbers(true).SetInteractable(true);

		CreateLabel(CardPiecesDetailsline6).SetText("   Pieces given to each player at the start: ");
		CardPiecesStartPieces = CreateNumberInputField(CardPiecesDetailsline6).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.CardPiecesStartPieces).SetWholeNumbers(true).SetInteractable(true);

		local horzCardPiecesCardWeight = CreateHorz(UIcontainer);
		CreateLabel(horzCardPiecesCardWeight).SetText("Card weight: ");
		CardPiecesCardWeight = CreateNumberInputField(horzCardPiecesCardWeight).SetSliderMinValue(0).SetSliderMaxValue(10).SetValue(Mod.Settings.CardPiecesCardWeight).SetWholeNumbers(false).SetInteractable(true);		
	end
	print("END   Card Pieces card checkbox clicked")
end

function airstrikeCheckboxClicked()
	local win = "airstrikeCheckboxClicked";
	Mod.Settings.AirstrikeEnabled = AirstrikeCardCheckbox.GetIsChecked();

	if (AirstrikeCardCheckbox.GetIsChecked() == false) then
		print("clear Airstrike settings from UI");

		if (AirstrikeDetailsline1 ~= nil) then
			print("destroy Airstrike UI items");
			updateModSettingsFromUI();
			UI.Destroy(vertAirstrikeSettingsDetails);
		else
			print("DON'T destroy Airstrike UI items");
		end
	else
		print("create vert");
		vertAirstrikeSettingsDetails = CreateVert(vertAirstrikeSettingsHeading);
		UIcontainer = vertAirstrikeSettingsDetails;
		print("create hori");
		AirstrikeDetailsline1 = CreateHorz(UIcontainer);
		AirstrikeDetailsline2 = CreateHorz(UIcontainer);
		AirstrikeDetailsline3 = CreateHorz(UIcontainer);
		AirstrikeDetailsline4 = CreateHorz(UIcontainer);
		AirstrikeDetailsline5 = CreateHorz(UIcontainer);

		AirstrikeCanTargetNeutrals = CreateCheckBox(AirstrikeDetailsline1).SetIsChecked(Mod.Settings.AirstrikeCanTargetNeutrals).SetInteractable(true).SetText("Can target neutrals");
		AirstrikeCanTargetPlayers = CreateCheckBox(AirstrikeDetailsline2).SetIsChecked(Mod.Settings.AirstrikeCanTargetPlayers).SetInteractable(true).SetText("Can target players");
		AirstrikeCanTargetFoggedTerritories = CreateCheckBox(AirstrikeDetailsline3).SetIsChecked(Mod.Settings.AirstrikeCanTargetFoggedTerritories).SetInteractable(true).SetText("Can target fogged territories");

		CreateLabel(AirstrikeDetailsline4).SetText("Number of pieces to divide the card into: ");
		AirstrikeCardPiecesNeeded = CreateNumberInputField(AirstrikeDetailsline4).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.AirstrikePiecesNeeded).SetWholeNumbers(true).SetInteractable(true);

		CreateLabel(AirstrikeDetailsline5).SetText("Pieces given to each player at the start: ");
		AirstrikeCardStartPieces = CreateNumberInputField(AirstrikeDetailsline5).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.AirstrikeStartPieces).SetWholeNumbers(true).SetInteractable(true);

		local horzAirstrikeCardWeight = CreateHorz(UIcontainer);
		CreateLabel(horzAirstrikeCardWeight).SetText("Card weight: ");
		AirstrikeCardWeight = CreateNumberInputField(horzAirstrikeCardWeight).SetSliderMinValue(0).SetSliderMaxValue(10).SetValue(Mod.Settings.AirstrikeCardWeight).SetWholeNumbers(false).SetInteractable(true);		
	end
	print("Airstrike card checkbox clicked")
end

function forestFireCheckboxClicked()
	local win = "forestFireCheckboxClicked";
	Mod.Settings.ForestFireEnabled = ForestFireCardCheckbox.GetIsChecked();

	if (ForestFireCardCheckbox.GetIsChecked() == false) then
		print("clear Forest Fire settings from UI");

		if (ForestFireDetailsline1 ~= nil) then
			print("destroy Forest Fire UI items");
			updateModSettingsFromUI();
			UI.Destroy(vertForestFireSettingsDetails);
		else
			print("DON'T destroy Forest Fire UI items");
		end
	else
		print("create vert");
		vertForestFireSettingsDetails = CreateVert(vertForestFireSettingsHeading);
		UIcontainer = vertForestFireSettingsDetails;
		print("create hori");
		ForestFireDetailsline1 = CreateHorz(UIcontainer);
		ForestFireDetailsline2 = CreateHorz(UIcontainer);
		ForestFireDetailsline3 = CreateHorz(UIcontainer);
		print("create label");
		CreateLabel(ForestFireDetailsline1).SetText("Duration: ");
		ForestFireCardDuration = CreateNumberInputField(ForestFireDetailsline1).SetSliderMinValue(1).SetSliderMaxValue(5).SetValue(Mod.Settings.ForestFireDuration).SetWholeNumbers(true).SetInteractable(true);

		CreateLabel(ForestFireDetailsline2).SetText("Number of pieces to divide the card into: ");
		ForestFireCardPiecesNeeded = CreateNumberInputField(ForestFireDetailsline2).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.ForestFirePiecesNeeded).SetWholeNumbers(true).SetInteractable(true);

		CreateLabel(ForestFireDetailsline3).SetText("Pieces given to each player at the start: ");
		ForestFireCardStartPieces = CreateNumberInputField(ForestFireDetailsline3).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.ForestFireStartPieces).SetWholeNumbers(true).SetInteractable(true);

		local horzForestFireCardWeight = CreateHorz(UIcontainer);
		CreateLabel(horzForestFireCardWeight).SetText("Card weight: ");
		ForestFireCardWeight = CreateNumberInputField(horzForestFireCardWeight).SetSliderMinValue(0).SetSliderMaxValue(10).SetValue(Mod.Settings.ForestFireCardWeight).SetWholeNumbers(false).SetInteractable(true);		
	end
	print("Forest Fire card checkbox clicked")
end

function nukeCheckboxClicked ()
	local win = "nukeCheckboxClicked";
	print ("nukeCheckboxClicked");

	Mod.Settings.NukeEnabled = NukeCardCheckbox.GetIsChecked();

	if (Mod.Settings.NukeEnabled==false) then
		--clear Nuke settings from UI
		print ("clear Nuke settings from UI");

		if (vertNukeSettingsDetails ~= nil) then
			print ("destroy Nuke UI items");
			updateModSettingsFromUI(); -- before destroying UI, update Mod.Settings with latest UI values
			--DestroyWindow ("vertNukeSettingsDetails");
			UI.Destroy (vertNukeSettingsDetails); --destroy the UI container that contains all Nuke settings
		else
			print ("DON'T destroy Nuke UI items");
		end
	else
		vertNukeSettingsDetails = CreateVert(vertNukeSettingsHeading);
		--vertNukeSettingsDetails = CreateVert(addHorizontalBufferSpacing (vertNukeSettingsHeading));
		--CreateWindow (vertNukeSettingsHeading, "vertNukeSettingsDetails");
		--CreateSubWindow (vertNukeSettingsHeading, "vertNukeSettingsDetails", vertNukeSettingsHeading);
		UIcontainer = CreateVert(vertNukeSettingsDetails);
		--UIcontainer = CreateVert(CreateHorz(CreateHorz(CreateHorz(CreateHorz(vertNukeSettingsDetails)))));

		horzNukeCardMainTerritoryDamage = CreateHorz (UIcontainer);
		CreateLabel(horzNukeCardMainTerritoryDamage).SetText("[Epicenter]");
		vertA = CreateVert (horzNukeCardMainTerritoryDamage);
		CreateLabel(vertA).SetText("Damage (%): ");
		NukeCardMainTerritoryDamage = CreateNumberInputField(vertA).SetSliderMinValue(0).SetSliderMaxValue(100).SetValue(Mod.Settings.NukeCardMainTerritoryDamage).SetWholeNumbers(true).SetInteractable(true);
		vertB = CreateVert (horzNukeCardMainTerritoryDamage);
		CreateLabel(vertB).SetText("Fixed damage: ");
		NukeCardMainTerritoryFixedDamage = CreateNumberInputField(vertB).SetSliderMinValue(0).SetSliderMaxValue(100).SetValue(Mod.Settings.NukeCardMainTerritoryFixedDamage).SetWholeNumbers(true).SetInteractable(true);

		--horzNukeCardMainTerritoryFixedDamage = CreateHorz(UIcontainer);
		--horzNukeCardConnectedTerritoryFixedDamage = CreateHorz(UIcontainer);

		horzNukeCardConnectedTerritoryDamage = CreateHorz (UIcontainer);
		CreateLabel(horzNukeCardConnectedTerritoryDamage).SetText("[Bordering\nterritories]");
		vertC = CreateVert (horzNukeCardConnectedTerritoryDamage);
		CreateLabel(vertC).SetText("Damage (%): ");
		NukeCardConnectedTerritoryDamage = CreateNumberInputField(vertC).SetSliderMinValue(0).SetSliderMaxValue(100).SetValue(Mod.Settings.NukeCardConnectedTerritoryDamage).SetWholeNumbers(true).SetInteractable(true);
		vertD = CreateVert (horzNukeCardConnectedTerritoryDamage);
		CreateLabel(vertD).SetText("Fixed damage: ");
		NukeCardConnectedTerritoryFixedDamage = CreateNumberInputField(vertD).SetSliderMinValue(0).SetSliderMaxValue(100).SetValue(Mod.Settings.NukeCardConnectedTerritoryFixedDamage).SetWholeNumbers(true).SetInteractable(true);

		CreateLabel(UIcontainer).SetText("Specify the % damage each of the epicenter and bordering territories will sustain. Fixed damage can also be specified either in place or in addition to % damage. If both are specified, fixed damage will apply after % damage has been applied.");


--[[		horzNukeCardMainTerritoryDamage = CreateHorz (UIcontainer);
		CreateLabel(horzNukeCardMainTerritoryDamage).SetText("[% damage]");
		vertA = CreateVert (horzNukeCardMainTerritoryDamage);
		CreateLabel(vertA).SetText("Epicenter (%): ");
		NukeCardMainTerritoryDamage = CreateNumberInputField(vertA).SetSliderMinValue(0).SetSliderMaxValue(100).SetValue(Mod.Settings.NukeCardMainTerritoryDamage).SetWholeNumbers(true).SetInteractable(true);

		vertB = CreateVert (horzNukeCardMainTerritoryDamage);
		CreateLabel(vertB).SetText("Bordering territories (%): ");
		horzNukeCardMainTerritoryDamage = CreateHorz (UIcontainer);
		NukeCardConnectedTerritoryDamage = CreateNumberInputField(vertB).SetSliderMinValue(0).SetSliderMaxValue(100).SetValue(Mod.Settings.NukeCardConnectedTerritoryDamage).SetWholeNumbers(true).SetInteractable(true);

		horzNukeCardConnectedTerritoryDamage = CreateHorz (UIcontainer);
		CreateLabel(horzNukeCardConnectedTerritoryDamage).SetText("[Fixed damage done by nuke]\n");
		CreateLabel(horzNukeCardConnectedTerritoryDamage).SetText("Bordering territories (%): ");
		CreateLabel(horzNukeCardConnectedTerritoryDamage).SetText("Epicenter: ");

		

		horzNukeCardMainTerritoryFixedDamage = CreateHorz(UIcontainer);
		NukeCardMainTerritoryFixedDamage = CreateNumberInputField(horzNukeCardMainTerritoryFixedDamage).SetSliderMinValue(0).SetSliderMaxValue(100).SetValue(Mod.Settings.NukeCardMainTerritoryFixedDamage).SetWholeNumbers(true).SetInteractable(true);

		--horzNukeCardConnectedTerritoryFixedDamage = CreateHorz(UIcontainer);
		CreateLabel(horzNukeCardMainTerritoryFixedDamage).SetText("Bordering territories:");
		NukeCardConnectedTerritoryFixedDamage = CreateNumberInputField(horzNukeCardMainTerritoryFixedDamage).SetSliderMinValue(0).SetSliderMaxValue(100).SetValue(Mod.Settings.NukeCardConnectedTerritoryFixedDamage).SetWholeNumbers(true).SetInteractable(true);
]]


		--[[CreateLabel(UIcontainer).SetText("[% damage done by nuke]");
		horzNukeCardMainTerritoryDamage = CreateHorz (UIcontainer);
		CreateLabel(horzNukeCardMainTerritoryDamage).SetText("Epicenter (%): ");
		NukeCardMainTerritoryDamage = CreateNumberInputField(horzNukeCardMainTerritoryDamage).SetSliderMinValue(0).SetSliderMaxValue(100).SetValue(Mod.Settings.NukeCardMainTerritoryDamage).SetWholeNumbers(true).SetInteractable(true);

		--horzNukeCardConnectedTerritoryDamage = CreateHorz (UIcontainer);
		CreateLabel(horzNukeCardMainTerritoryDamage).SetText("Bordering territories (%): ");
		NukeCardConnectedTerritoryDamage = CreateNumberInputField(horzNukeCardMainTerritoryDamage).SetSliderMinValue(0).SetSliderMaxValue(100).SetValue(Mod.Settings.NukeCardConnectedTerritoryDamage).SetWholeNumbers(true).SetInteractable(true);

		CreateLabel(UIcontainer).SetText("[Fixed damage done by nuke]\n");
		horzNukeCardMainTerritoryFixedDamage = CreateHorz(UIcontainer);
		CreateLabel(horzNukeCardMainTerritoryFixedDamage).SetText("Epicenter: ");
		NukeCardMainTerritoryFixedDamage = CreateNumberInputField(horzNukeCardMainTerritoryFixedDamage).SetSliderMinValue(0).SetSliderMaxValue(100).SetValue(Mod.Settings.NukeCardMainTerritoryFixedDamage).SetWholeNumbers(true).SetInteractable(true);

		--horzNukeCardConnectedTerritoryFixedDamage = CreateHorz(UIcontainer);
		CreateLabel(horzNukeCardMainTerritoryFixedDamage).SetText("Bordering territories:");
		NukeCardConnectedTerritoryFixedDamage = CreateNumberInputField(horzNukeCardMainTerritoryFixedDamage).SetSliderMinValue(0).SetSliderMaxValue(100).SetValue(Mod.Settings.NukeCardConnectedTerritoryFixedDamage).SetWholeNumbers(true).SetInteractable(true);
]]

		--[[horzNukeCardMainTerritoryDamage = CreateHorz (UIcontainer);
		CreateLabel(horzNukeCardMainTerritoryDamage).SetText("Damage - Epicenter (%): ");
		NukeCardMainTerritoryDamage = CreateNumberInputField(horzNukeCardMainTerritoryDamage).SetSliderMinValue(0).SetSliderMaxValue(100).SetValue(Mod.Settings.NukeCardMainTerritoryDamage).SetWholeNumbers(true).SetInteractable(true);

		horzNukeCardMainTerritoryFixedDamage = CreateHorz(UIcontainer);
		CreateLabel(horzNukeCardMainTerritoryFixedDamage).SetText("Fixed damage - Epicenter: \n(in addition to % damage, also applies a fixed amount of damage)");
		NukeCardMainTerritoryFixedDamage = CreateNumberInputField(horzNukeCardMainTerritoryFixedDamage).SetSliderMinValue(0).SetSliderMaxValue(100).SetValue(Mod.Settings.NukeCardMainTerritoryFixedDamage).SetWholeNumbers(true).SetInteractable(true);

		horzNukeCardConnectedTerritoryDamage = CreateHorz (UIcontainer);
		CreateLabel(horzNukeCardConnectedTerritoryDamage).SetText("Damage - Bordering territories (%): ");
		NukeCardConnectedTerritoryDamage = CreateNumberInputField(horzNukeCardConnectedTerritoryDamage).SetSliderMinValue(0).SetSliderMaxValue(100).SetValue(Mod.Settings.NukeCardConnectedTerritoryDamage).SetWholeNumbers(true).SetInteractable(true);

		horzNukeCardConnectedTerritoryFixedDamage = CreateHorz(UIcontainer);
		CreateLabel(horzNukeCardConnectedTerritoryFixedDamage).SetText("Fixed damage - Bordering territories: \n(in addition to % damage, also applies a fixed amount of damage)");
		NukeCardConnectedTerritoryFixedDamage = CreateNumberInputField(horzNukeCardConnectedTerritoryFixedDamage).SetSliderMinValue(0).SetSliderMaxValue(100).SetValue(Mod.Settings.NukeCardConnectedTerritoryFixedDamage).SetWholeNumbers(true).SetInteractable(true);
]]
		CreateHorz(UIcontainer); --use as a vertical spacer between this and next item so it's clear which element the description text belongs to
		horzNukeCardNumLevelsConnectedTerritoriesToSpreadTo = CreateHorz (UIcontainer);
		CreateLabel(horzNukeCardNumLevelsConnectedTerritoriesToSpreadTo).SetText("Blast range:"); --" \n(how many territories damage spreads to; 0=only impacts epicenter territory)");
		NukeCardNumLevelsConnectedTerritoriesToSpreadTo = CreateNumberInputField(horzNukeCardNumLevelsConnectedTerritoriesToSpreadTo).SetSliderMinValue(0).SetSliderMaxValue(5).SetValue(Mod.Settings.NukeCardNumLevelsConnectedTerritoriesToSpreadTo).SetWholeNumbers(true).SetInteractable(true);
		CreateLabel(UIcontainer).SetText("(how many territories damage spreads to; 0=only impacts epicenter territory)");
		CreateHorz(UIcontainer); --use as a vertical spacer between this and next item so it's clear which element the description text belongs to

		horzNukeCardConnectedTerritoriesSpreadDamageDelta = CreateHorz (UIcontainer);
		CreateLabel(horzNukeCardConnectedTerritoriesSpreadDamageDelta).SetText("Damage reduction with spread (%):"); --" \n(damage is reduced with each step from epicenter)");
		NukeCardConnectedTerritoriesSpreadDamageDelta = CreateNumberInputField(horzNukeCardConnectedTerritoriesSpreadDamageDelta).SetSliderMinValue(0).SetSliderMaxValue(100).SetValue(Mod.Settings.NukeCardConnectedTerritoriesSpreadDamageDelta).SetWholeNumbers(true).SetInteractable(true);
		CreateLabel(UIcontainer).SetText("(damage is reduced with each step from epicenter)");
		CreateHorz(UIcontainer); --use as a vertical spacer between this and next item so it's clear which element the description text belongs to
		
		horzNukeFriendlyfire = CreateHorz(UIcontainer);
		NukeFriendlyfire = CreateCheckBox(horzNukeFriendlyfire).SetIsChecked(Mod.Settings.NukeFriendlyfire).SetInteractable(true).SetText("Friendly fire (can harm yourself)");

		horzNukeImplementationPhase = CreateHorz(UIcontainer);
		CreateLabel(horzNukeImplementationPhase).SetText("Turn phase where nukes are executed:");
		NukeImplementationPhase = CreateButton(horzNukeImplementationPhase).SetInteractable(true).SetText(Mod.Settings.NukeImplementationPhase).SetOnClick(Nuke_turnPhaseButton_clicked);
		--[[ Following are the actual WZ in-game turn phase sequence order as per https://www.warzone.com/wiki/Turn_phases; reference in code via WL.TurnPhase. prefix, eg: WL.TurnPhase.BombCards, etc
		---| 'CardsWearOff' # Cards wearing off turn phase  <--- is this true? seems to happen late in turn, between receiving card pieces & receiving gold (tested for Sanctions wearing off)
		---| 'Purchase' # Purchase turn phase
		---| 'Discards' # Discard cards turn phase
		---| 'OrderPriorityCards' # Priority card turn phase
		---| 'SpyingCards' # Spy card turn phase
		---| 'ReinforcementCards' # Reinforcement card turn phase
		---| 'Deploys' # Deploy turn phase
		---| 'BombCards' # Bomb card turn phase
		---| 'EmergencyBlockadeCards' # Emergency blockade card turn phase
		---| 'Airlift' # Airlift turn phase
		---| 'Gift' # Gift card turn phase
		---| 'Attacks' # Attack / transfer turn phase
		---| 'BlockadeCards' # Blockade card turn phase
		---| 'DiplomacyCards' # Diplomacy card turn phase  <--- identified myself (krinid) via experimentation; not documented on https://www.warzone.com/wiki/Turn_phases
		---| 'SanctionCards' # Sanction card turn phase
		---| 'ReceiveCards' # Receive cards turn phase
		---| 'ReceiveGold' # Receive gold turn phase <--- not sure if this is an official phase, but in Commerce games, it occurs after receiving card pieces; not documented on https://www.warzone.com/wiki/Turn_phases]]
		
		horzNukeCardPiecesNeeded = CreateHorz (UIcontainer);
		CreateLabel(horzNukeCardPiecesNeeded).SetText("Number of pieces to divide the card into: ");
		NukeCardPiecesNeeded = CreateNumberInputField(horzNukeCardPiecesNeeded).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.NukeCardPiecesNeeded).SetWholeNumbers(true).SetInteractable(true);

		horzNukeCardStartPieces = CreateHorz (UIcontainer);
		CreateLabel(horzNukeCardStartPieces).SetText("Pieces given to each player at the start: ");
		NukeCardStartPieces = CreateNumberInputField(horzNukeCardStartPieces).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.NukeCardStartPieces).SetWholeNumbers(true).SetInteractable(true);

		horzNukeCardWeight = CreateHorz(UIcontainer);
		CreateLabel(horzNukeCardWeight).SetText("Card weight (how common the card is): ");
		NukeCardWeight = CreateNumberInputField(horzNukeCardWeight).SetSliderMinValue(1).SetSliderMaxValue(100).SetValue(Mod.Settings.NukeCardWeight).SetWholeNumbers(true).SetInteractable(true);

	end
end

function Nuke_turnPhaseButton_clicked ()
	print ("turnPhase button clicked");

	WLturnPhases_PromptFromList = {}
	for k,v in pairs(WLturnPhases()) do
		print ("newObj item=="..k,v.."::");
		table.insert (WLturnPhases_PromptFromList, {text=k, selected=function () Nuke_turnPhase_selected({name=k,value=v}); end});
	end

	UI.PromptFromList ("Select turn phase where Nukes will occur.\n\nThe default is BombCards, which means that Nukes will impact their targets during the same phase as Bombs, which is after deployments, but before emergency blockade cards.\n\nIf you're not sure, the recommendation is to leave it at BombCards.", WLturnPhases_PromptFromList);
end

function Nuke_turnPhase_selected (turnPhase)
	print ("turnPhase selected=="..tostring(turnPhase));
	print ("turnPhase selected:: name=="..turnPhase.name.."::value=="..turnPhase.value.."::value from WLturnPhases=="..WLturnPhases()[turnPhase.name].."::");
	printObjectDetails (turnPhase, "turnPhase stuff", "[Nuke turnPhase config]");
	NukeImplementationPhase.SetText (turnPhase.name);
end

function isolationCheckboxClicked()
	local win = "isolationConfig";

	print("isolationCheckboxClicked");

	updateModSettingsFromUI();
	print("[ums kanryou]");

	Mod.Settings.IsolationEnabled = IsolationCardCheckbox.GetIsChecked();

	print("icc post IsolationDuration==" .. Mod.Settings.IsolationDuration .. "::");
	print("icc post IsolationNumPiecesNeeded==" .. Mod.Settings.IsolationPiecesNeeded .. "::");
	print("icc post IsolationStartingCardPieceQty==" .. Mod.Settings.IsolationStartPieces .. "::");

	if (IsolationCardCheckbox.GetIsChecked() == false) then
		--clear Isolation settings from UI
		print("clear Isolation settings from UI");

		if (vertIsolationSettingsDetails ~= nil) then
			print("destroy ISO UI items");
			updateModSettingsFromUI(); -- before destroying UI, update Mod.Settings with latest UI values
			UI.Destroy(vertIsolationSettingsDetails); -- destroy UI container containing all Isolation settings
		else
			print("DON'T destroy ISO UI items");
		end
	else
		--show Isolation settings in UI
		print("show ISO settings in UI");
		vertIsolationSettingsDetails = CreateVert(vertIsolationSettingsHeading);
		UIcontainer = vertIsolationSettingsDetails;

		horzIsolationDuration = CreateHorz(UIcontainer);
		CreateLabel(horzIsolationDuration).SetText("Duration: ");
		IsolationDuration = CreateNumberInputField(horzIsolationDuration).SetSliderMinValue(1).SetSliderMaxValue(5).SetValue(Mod.Settings.IsolationDuration).SetWholeNumbers(true).SetInteractable(true);
		CreateLabel (UIcontainer).SetText ("(Use -1 to make Isolation permanent; be careful with this setting as it can make a game impossible to finish depending on the other game settings)");

		horzIsolationNumPiecesNeeded = CreateHorz(UIcontainer);
		CreateLabel(horzIsolationNumPiecesNeeded).SetText("Number of pieces to divide the card into: ");
		IsolationNumPiecesNeeded = CreateNumberInputField(horzIsolationNumPiecesNeeded).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.IsolationPiecesNeeded).SetWholeNumbers(true).SetInteractable(true);

		horzIsolationStartingCardPieceQty = CreateHorz(UIcontainer);
		CreateLabel(horzIsolationStartingCardPieceQty).SetText("Pieces given to each player at the start: ");
		IsolationStartingCardPieceQty = CreateNumberInputField(horzIsolationStartingCardPieceQty).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.IsolationStartPieces).SetWholeNumbers(true).SetInteractable(true);

		local horzIsolationCardWeight = CreateHorz(UIcontainer);
		CreateLabel(horzIsolationCardWeight).SetText("Card weight: ");
		IsolationCardWeight = CreateNumberInputField(horzIsolationCardWeight).SetSliderMinValue(0).SetSliderMaxValue(10).SetValue(Mod.Settings.IsolationCardWeight).SetWholeNumbers(false).SetInteractable(true);
	end
end

function setDefaultValues()
	print ("SET DEFAULT VALUES] START");
	--print ("sdv settings.PestCardIn1=="..tostring(Mod.Settings.PestilenceEnabled));
	--print ("sdv settings.PestCardStrength1=="..tostring(Mod.Settings.PestilenceStrength));
	--print ("sdv Mod.Settings.PestilenceEnabled1.5=="..tostring(Mod.Settings.PestilenceEnabled));

	if (Mod.Settings.IsolationEnabled == nil) then -- Isolation has not been enabled yet, so no values in Mod.Settings for Pestilence, thus set to defaults
		Mod.Settings.IsolationEnabled = false;
		Mod.Settings.IsolationDuration = 1;      --default isolation duration is 1
		Mod.Settings.IsolationPiecesNeeded = 10; --default isolation pieces needed is 4
		Mod.Settings.IsolationStartPieces = 1;   --default isolation start pieces is 1
        Mod.Settings.IsolationCardWeight = 1.0;  --default isolation card weight is 1
	end

	if (Mod.Settings.NukeEnabled == nil) then -- Nuke has not been enabled yet, so no values in Mod.Settings for Pestilence, thus set to defaults
		Mod.Settings.NukeEnabled = false;
		Mod.Settings.NukeCardMainTerritoryDamage = 50;      --default nuke main territory damage is 50
		Mod.Settings.NukeCardMainTerritoryFixedDamage = 5;  -- default fixed damage for main territory is 5
		Mod.Settings.NukeCardConnectedTerritoryDamage = 25; --default nuke connected territory damage is 25
		Mod.Settings.NukeCardConnectedTerritoryFixedDamage = 5;  -- default fixed damage for connected territories is 5
		Mod.Settings.NukeCardNumLevelsConnectedTerritoriesToSpreadTo = 3; -- default nuke blast range is 3 (spreads 3 territories out from epicenter)
		Mod.Settings.NukeCardConnectedTerritoriesSpreadDamageDelta = 25;  -- default damage reduction is 25% with each step away from epicenter
		Mod.Settings.NukeFriendlyfire = true;               --default nuke friendly fire is enabled
		Mod.Settings.NukeImplementationPhase = "BombCards"; --default to BombCards, which means nuke damage occurs during the same phase as Bomb cards
		Mod.Settings.NukeCardPiecesNeeded = 10;             --default nuke pieces needed is 10
		Mod.Settings.NukeCardStartPieces = 1;               --default nuke start pieces is 1
		Mod.Settings.NukeCardPiecesPerTurn = 1;             --default nuke pieces per turn is 1
		Mod.Settings.NukeCardWeight = 1.0;                  --default nuke card weight is 1
	end

	if (Mod.Settings.PestilenceEnabled == nil) then -- Pestilence has not been enabled yet, so no values in Mod.Settings for Pestilence, thus set to defaults
		Mod.Settings.PestilenceEnabled = false;
		Mod.Settings.PestilenceDuration = 1;       --default pestilence duration is 1
		Mod.Settings.PestilenceStrength = 1;       --default pestilence strength is 1
		Mod.Settings.PestilencePiecesNeeded = 10;  --default pestilence pieces needed is 10
		Mod.Settings.PestilenceStartPieces = 1;    --default pestilence start pieces is 1
		Mod.Settings.PestilencePiecesPerTurn = 1;  --default pestilence pieces per turn is 1
		Mod.Settings.PestilenceCardWeight = 1.0;   -- default nuke card weight is 1
		--future use :: straight damage each turn vs increasing to max @ final duration turn vs start at max and taper down
	end

	--delme / delete me - or fix to eradicate the occasional need for this
	--[[Mod.Settings.TornadoEnabled = nil;
	Mod.Settings.EarthquakeEnabled = nil;
	Mod.Settings.CardPiecesEnabled = nil;
	Mod.Settings.ShieldCardWeight = nil;
	Mod.Settings.IsolationCardWeight = 1.0;
	IsolationCardWeight = 1;
	Mod.Settings.ShieldCardWeight = 1.0;
	Mod.Settings.MonolithCardWeight = 1.0;
	Mod.Settings.NeutralizeCardWeight = 1.0;
	Mod.Settings.DeneutralizeCardWeight = 1.0;
	Mod.Settings.CardBlockCardWeight = 1.0;
	Mod.Settings.CardPiecesCardWeight = 1.0;
	Mod.Settings.TornadoStrength = 1.0;
	Mod.Settings.TornadoCardWeight = 1.0;
	Mod.Settings.QuicksandCardWeight = 1.0;
	Mod.Settings.ForestFireCardWeight = 1.0;
	Mod.Settings.AirstrikeCardWeight = 1.0;
	Mod.Settings.EarthquakeStrength = 1.0;
	Mod.Settings.EarthquakeCardWeight = 1.0;]]

	if (Mod.Settings.ShieldEnabled == nil) then
        Mod.Settings.ShieldEnabled = false;
        Mod.Settings.ShieldDuration = 2;
        Mod.Settings.ShieldPiecesNeeded = 10;
        Mod.Settings.ShieldStartPieces = 1;
        Mod.Settings.ShieldPiecesPerTurn = 1;
        Mod.Settings.ShieldCardWeight = 1.0;
    end

	if (Mod.Settings.MonolithEnabled == nil) then
		Mod.Settings.MonolithEnabled = false;
		Mod.Settings.MonolithDuration = 5;
		Mod.Settings.MonolithPiecesNeeded = 10;
		Mod.Settings.MonolithStartPieces = 1;
		Mod.Settings.MonolithPiecesPerTurn = 1;
		Mod.Settings.MonolithCardWeight = 1.0;
	end

	if (Mod.Settings.TornadoEnabled == nil) then
		Mod.Settings.TornadoEnabled = false;
		Mod.Settings.TornadoDuration = 3;
		Mod.Settings.TornadoStrength = 10;
		Mod.Settings.TornadoPiecesNeeded = 10;
		Mod.Settings.TornadoStartPieces = 1;
		Mod.Settings.TornadoPiecesPerTurn = 1;
		Mod.Settings.TornadoCardWeight = 1.0;
	end

	if (Mod.Settings.EarthquakeEnabled == nil) then
		Mod.Settings.EarthquakeEnabled = false;
		Mod.Settings.EarthquakeDuration = 3;
		Mod.Settings.EarthquakeStrength = 5;
		Mod.Settings.EarthquakePiecesNeeded = 10;
		Mod.Settings.EarthquakeStartPieces = 1;
		Mod.Settings.EarthquakePiecesPerTurn = 1;
		Mod.Settings.EarthquakeCardWeight = 1.0;
	end

	if (Mod.Settings.QuicksandEnabled == nil) then
		Mod.Settings.QuicksandEnabled = false;
		Mod.Settings.QuicksandDuration = 3;
		Mod.Settings.QuicksandBlockEntryIntoTerritory = false;
		Mod.Settings.QuicksandBlockAirliftsIntoTerritory = false;
		Mod.Settings.QuicksandBlockAirliftsFromTerritory = true;
		Mod.Settings.QuicksandBlockExitFromTerritory = true;
		Mod.Settings.QuicksandDefendDamageTakenModifier = 1.5; --increase damage taken by defender 50% while in quicksand
		Mod.Settings.QuicksandAttackDamageGivenModifier = 0.5; --reduce damage given by defender 50% while in quicksand
		Mod.Settings.QuicksandPiecesNeeded = 10;
		Mod.Settings.QuicksandStartPieces = 1;
		Mod.Settings.QuicksandPiecesPerTurn = 1;
		Mod.Settings.QuicksandCardWeight = 1.0;
	end

	if (Mod.Settings.CardBlockEnabled == nil) then
		Mod.Settings.CardBlockEnabled = false;
		Mod.Settings.CardBlockDuration = 3;
		Mod.Settings.CardBlockPiecesNeeded = 10;
		Mod.Settings.CardBlockStartPieces = 1;
		Mod.Settings.CardBlockPiecesPerTurn = 1;
		Mod.Settings.CardBlockCardWeight = 1.0;
	end

	if (Mod.Settings.CardPiecesEnabled == nil) then
		Mod.Settings.CardPiecesEnabled = false;
		Mod.Settings.CardPiecesNumWholeCardsToGrant = 1;
		Mod.Settings.CardPiecesNumCardPiecesToGrant = 1;
		Mod.Settings.CardPiecesPiecesNeeded = 10;
		Mod.Settings.CardPiecesStartPieces = 1;
		Mod.Settings.CardPiecesPiecesPerTurn = 1;
		Mod.Settings.CardPiecesCardWeight = 1.0;
	end

	if (Mod.Settings.NeutralizeEnabled == nil) then
		Mod.Settings.NeutralizeEnabled = false;
		Mod.Settings.NeutralizeDuration = 3;
		Mod.Settings.NeutralizeCanUseOnCommander = false;
		Mod.Settings.NeutralizeCanUseOnSpecials = false;
		Mod.Settings.NeutralizePiecesNeeded = 10;
		Mod.Settings.NeutralizeStartPieces = 1;
		Mod.Settings.NeutralizePiecesPerTurn = 1;
		Mod.Settings.NeutralizeCardWeight = 1.0;
	end

	if (Mod.Settings.DeneutralizeEnabled == nil) then
		Mod.Settings.DeneutralizeEnabled = false;
		Mod.Settings.DeneutralizePiecesNeeded = 10;
		Mod.Settings.DeneutralizeStartPieces = 1;
		Mod.Settings.DeneutralizePiecesPerTurn = 1;
		Mod.Settings.DeneutralizeCanUseOnNeutralizedTerritories = true;
		Mod.Settings.DeneutralizeCanUseOnNaturalNeutrals = true;
		Mod.Settings.DeneutralizeCanAssignToSelf = true;
		Mod.Settings.DeneutralizeCanAssignToAnotherPlayer = false; --set to False for now; not implementing this option at this point; will only assign territory to self
		Mod.Settings.DeneutralizeCardWeight = 1.0;
	end

	if (Mod.Settings.AirstrikeEnabled == nil) then
		Mod.Settings.AirstrikeEnabled = false;
		Mod.Settings.AirstrikeCanTargetNeutrals = true;
		Mod.Settings.AirstrikeCanTargetPlayers = true;
		Mod.Settings.AirstrikeCanTargetFoggedTerritories = true;
		Mod.Settings.AirstrikePiecesNeeded = 10;
		Mod.Settings.AirstrikeStartPieces = 1;
		Mod.Settings.AirstrikePiecesPerTurn = 1;
		Mod.Settings.AirstrikeCardWeight = 1.0;
	end

	if (Mod.Settings.ForestFireEnabled == nil) then
		Mod.Settings.ForestFireEnabled = false;
		Mod.Settings.ForestFireDuration = 3;
		Mod.Settings.ForestFirePiecesNeeded = 10;
		Mod.Settings.ForestFireStartPieces = 1;
		Mod.Settings.ForestFirePiecesPerTurn = 1;
		Mod.Settings.ForestFireCardWeight = 1.0;
	end

	print ("SET DEFAULT VALUES] END");
end

--update Mod.Settings values with the values in the UI controls; check if the controls are present, and if so grab the values (else don't, b/c values will be nil and will generate error)
function updateModSettingsFromUI()
	if vertPestiSettingsDetails ~= nil then   --if the UI for Pestilence settings is up, capture the values into Mod.Settings (in case the UI elements are destroyed)
		Mod.Settings.PestilenceDuration = PestilenceDuration.GetValue();
		Mod.Settings.PestilenceStrength = PestCardStrength.GetValue();
		Mod.Settings.PestilencePiecesNeeded = PestNumPiecesNeeded.GetValue();
		Mod.Settings.PestilenceStartPieces = PestStartingCardPieceQty.GetValue();
		Mod.Settings.PestilencePiecesPerTurn = PestilencePiecesPerTurn.GetValue();
		Mod.Settings.PestilenceCardWeight = PestilenceCardWeight.GetValue();
	end

	--if ShieldCardCheckbox.GetIsChecked() then
	if vertShieldSettingsDetails ~= nil then
        Mod.Settings.ShieldDuration = ShieldDuration.GetValue();
        Mod.Settings.ShieldPiecesNeeded = ShieldPiecesNeeded.GetValue();
        Mod.Settings.ShieldStartPieces = ShieldStartPieces.GetValue();
        Mod.Settings.ShieldPiecesPerTurn = ShieldPiecesPerTurn.GetValue();
        Mod.Settings.ShieldCardWeight = ShieldCardWeight.GetValue();
    end

    -- Update Card Block settings
    if vertCardBlockSettingsDetails ~= nil then
        Mod.Settings.CardBlockDuration = CardBlockDuration.GetValue();
        Mod.Settings.CardBlockPiecesNeeded = CardBlockPiecesNeeded.GetValue();
        Mod.Settings.CardBlockStartPieces = CardBlockStartPieces.GetValue();
        Mod.Settings.CardBlockPiecesPerTurn = CardBlockPiecesPerTurn.GetValue();
		Mod.Settings.CardBlockCardWeight = CardBlockCardWeight.GetValue();
    end

	-- Update Card Pieces settings
    if vertCardPiecesSettingsDetails ~= nil then
        Mod.Settings.CardPiecesNumWholeCardsToGrant = CardPiecesNumWholeCardsToGrant.GetValue();
        Mod.Settings.CardPiecesNumCardPiecesToGrant = CardPiecesNumCardPiecesToGrant.GetValue();
        Mod.Settings.CardPiecesPiecesNeeded = CardPiecesPiecesNeeded.GetValue();
        Mod.Settings.CardPiecesStartPieces = CardPiecesStartPieces.GetValue();
        Mod.Settings.CardPiecesCardWeight = CardPiecesCardWeight.GetValue();
    end

    -- Update Earthquake settings (similar to Pestilence but for seismic effects)
    if vertEarthquakeSettingsDetails ~= nil then
        Mod.Settings.EarthquakeDuration = EarthquakeDuration.GetValue();
        Mod.Settings.EarthquakeStrength = EarthquakeStrength.GetValue();
        Mod.Settings.EarthquakePiecesNeeded = EarthquakePiecesNeeded.GetValue();
        Mod.Settings.EarthquakeStartPieces = EarthquakeStartPieces.GetValue();
        Mod.Settings.EarthquakePiecesPerTurn = EarthquakePiecesPerTurn.GetValue();
		Mod.Settings.EarthquakeCardWeight = EarthquakeCardWeight.GetValue();
    end

    -- Update Tornado settings (similar to Pestilence but for a tornado effect)
    if vertTornadoSettingsDetails ~= nil then
        Mod.Settings.TornadoDuration = TornadoDuration.GetValue();
        Mod.Settings.TornadoStrength = TornadoStrength.GetValue();
        Mod.Settings.TornadoPiecesNeeded = TornadoPiecesNeeded.GetValue();
        Mod.Settings.TornadoStartPieces = TornadoStartPieces.GetValue();
        Mod.Settings.TornadoPiecesPerTurn = TornadoPiecesPerTurn.GetValue();
		Mod.Settings.TornadoCardWeight = TornadoCardWeight.GetValue();
    end

    -- Update Quicksand settings (similar to Isolation but with a quicksand twist)
    if vertQuicksandSettingsDetails ~= nil then
        Mod.Settings.QuicksandDuration = QuicksandDuration.GetValue();
        Mod.Settings.QuicksandBlockEntryIntoTerritory = QuicksandBlockEntryIntoTerritory.GetIsChecked();
        Mod.Settings.QuicksandBlockAirliftsIntoTerritory = QuicksandBlockAirliftsIntoTerritory.GetIsChecked();
        Mod.Settings.QuicksandBlockAirliftsFromTerritory = QuicksandBlockAirliftsFromTerritory.GetIsChecked();
        Mod.Settings.QuicksandBlockExitFromTerritory = QuicksandBlockExitFromTerritory.GetIsChecked();
        Mod.Settings.QuicksandDefendDamageTakenModifier = QuicksandDefendDamageTakenModifier.GetValue();
        Mod.Settings.QuicksandAttackDamageGivenModifier = QuicksandAttackDamageGivenModifier.GetValue();
        Mod.Settings.QuicksandPiecesNeeded = QuicksandPiecesNeeded.GetValue();
        Mod.Settings.QuicksandStartPieces = QuicksandStartPieces.GetValue();
        Mod.Settings.QuicksandPiecesPerTurn = QuicksandPiecesPerTurn.GetValue();
		Mod.Settings.QuicksandCardWeight = QuicksandCardWeight.GetValue();
    end

	if vertNukeSettingsDetails ~= nil then   --if the UI for Nuke settings is up, capture the values into Mod.Settings (in case the UI elements are destroyed)
		Mod.Settings.NukeCardMainTerritoryDamage = NukeCardMainTerritoryDamage.GetValue ();
		Mod.Settings.NukeCardMainTerritoryFixedDamage = NukeCardMainTerritoryFixedDamage.GetValue();
		Mod.Settings.NukeCardConnectedTerritoryFixedDamage = NukeCardConnectedTerritoryFixedDamage.GetValue();
		Mod.Settings.NukeCardConnectedTerritoryDamage = NukeCardConnectedTerritoryDamage.GetValue();
		Mod.Settings.NukeCardNumLevelsConnectedTerritoriesToSpreadTo = NukeCardNumLevelsConnectedTerritoriesToSpreadTo.GetValue()
		Mod.Settings.NukeCardConnectedTerritoriesSpreadDamageDelta = NukeCardConnectedTerritoriesSpreadDamageDelta.GetValue();
		Mod.Settings.NukeImplementationPhase = NukeImplementationPhase.GetText();
		Mod.Settings.NukeFriendlyfire = NukeFriendlyfire.GetIsChecked();
		Mod.Settings.NukeCardPiecesNeeded = NukeCardPiecesNeeded.GetValue();
		Mod.Settings.NukeCardStartPieces = NukeCardStartPieces.GetValue();
		Mod.Settings.NukeCardWeight = NukeCardWeight.GetValue();
	end

	if vertMonolithSettingsDetails ~= nil then   --if the UI for Monolith settings is up, capture the values into Mod.Settings (in case the UI elements are destroyed)
		Mod.Settings.MonolithDuration = MonolithDuration.GetValue();
		Mod.Settings.MonolithPiecesNeeded = MonolithPiecesNeeded.GetValue();
		Mod.Settings.MonolithStartPieces = MonolithStartPieces.GetValue();
		Mod.Settings.MonolithPiecesPerTurn = MonolithPiecesPerTurn.GetValue();
		Mod.Settings.MonolithCardWeight = MonolithCardWeight.GetValue();
	end

	if vertIsolationSettingsDetails ~= nil then   --if the UI for Isolation settings is up, capture the values into Mod.Settings (in case the UI elements are destroyed)
		Mod.Settings.IsolationDuration = IsolationDuration.GetValue();
		Mod.Settings.IsolationPiecesNeeded = IsolationNumPiecesNeeded.GetValue();
		Mod.Settings.IsolationStartPieces = IsolationStartingCardPieceQty.GetValue();
		Mod.Settings.IsolationCardWeight = IsolationCardWeight.GetValue();
	end

	if vertNeutralizeSettingsDetails ~= nil then
		Mod.Settings.NeutralizeDuration = NeutralizeCardDuration.GetValue();
		Mod.Settings.NeutralizeCanUseOnCommander = NeutralizeCanUseOnCommander.GetIsChecked();
		Mod.Settings.NeutralizeCanUseOnSpecials = NeutralizeCanUseOnSpecials.GetIsChecked();
		Mod.Settings.NeutralizePiecesNeeded = NeutralizePiecesNeeded.GetValue();
		Mod.Settings.NeutralizeStartPieces = NeutralizeStartPieces.GetValue();
		Mod.Settings.NeutralizeCardWeight = NeutralizeCardWeight.GetValue();
	end

	if vertDeneutralizeSettingsDetails ~= nil then
		Mod.Settings.DeneutralizePiecesNeeded = DeneutralizeCardPiecesNeeded.GetValue();
		Mod.Settings.DeneutralizeStartPieces = DeneutralizeCardStartPieces.GetValue();
		Mod.Settings.DeneutralizeCanUseOnNaturalNeutrals = DeneutralizeCanUseOnNaturalNeutrals.GetIsChecked();
		Mod.Settings.DeneutralizeCanUseOnNeutralizedTerritories = DeneutralizeCanUseOnNeutralizedTerritories.GetIsChecked();
		Mod.Settings.DeneutralizeCanAssignToSelf = DeneutralizeCanAssignToSelf.GetIsChecked();
		Mod.Settings.DeneutralizeCanAssignToAnotherPlayer = DeneutralizeCanAssignToAnotherPlayer.GetIsChecked();
		Mod.Settings.DeneutralizeCardWeight = DeneutralizeCardWeight.GetValue();
	end

	if AirstrikeSettingsDetails ~= nil then
		Mod.Settings.AirstrikeCanTargetNeutrals = AirstrikeCanTargetNeutrals.GetIsChecked();
		Mod.Settings.AirstrikeCanTargetPlayers = AirstrikeCanTargetPlayers.GetIsChecked();
		Mod.Settings.AirstrikeCanTargetFoggedTerritories = AirstrikeCanTargetFoggedTerritories.GetIsChecked();
		Mod.Settings.AirstrikePiecesNeeded = AirstrikeCardPiecesNeeded.GetValue();
		Mod.Settings.AirstrikeStartPieces = AirstrikeCardStartPieces.GetValue();
		Mod.Settings.AirstrikeCardWeight = AirstrikeCardWeight.GetValue();
	end

	if ForestFireSettingsDetails ~= nil then
		Mod.Settings.ForestFireDuration = ForestFireCardDuration.GetValue();
		Mod.Settings.ForestFirePiecesNeeded = ForestFireCardPiecesNeeded.GetValue();
		Mod.Settings.ForestFireStartPieces = ForestFireCardStartPieces.GetValue();
		Mod.Settings.ForestFireCardWeight = ForestFireCardWeight.GetValue();
	end
end

function pestilenceCheckboxClicked()
	local win = "pestilenceCheckboxClicked";
	print("pestilenceCheckboxClicked");

	Mod.Settings.PestilenceEnabled = PestilenceCheckbox.GetIsChecked();

	if (PestilenceCheckbox.GetIsChecked() == false) then
		print("clear Pesti settings from UI");

		if (vertPestiSettingsDetails ~= nil) then
			print("destroy Pesti UI items");
			updateModSettingsFromUI();
			UI.Destroy(vertPestiSettingsDetails);
		else
			print("DON'T destroy Pesti UI items");
		end
	else
		print("create vert");
		vertPestiSettingsDetails = CreateVert(vertPestiSettingsHeading);
		UIcontainer = vertPestiSettingsDetails;
		print("create hori");

		horzPestilenceDuration = CreateHorz(UIcontainer);
		CreateLabel(horzPestilenceDuration).SetText("Duration: ");
		PestilenceDuration = CreateNumberInputField(horzPestilenceDuration).SetSliderMinValue(1).SetSliderMaxValue(5).SetValue(Mod.Settings.PestilenceDuration).SetWholeNumbers(true).SetInteractable(true);

		horzPestCardStrength = CreateHorz(UIcontainer);
		CreateLabel(horzPestCardStrength).SetText("Strength: ");
		PestCardStrength = CreateNumberInputField(horzPestCardStrength).SetSliderMinValue(1).SetSliderMaxValue(5).SetValue(Mod.Settings.PestilenceStrength).SetWholeNumbers(true).SetInteractable(true);

		horzPestNumPiecesNeeded = CreateHorz(UIcontainer);
		CreateLabel(horzPestNumPiecesNeeded).SetText("Number of pieces to divide the card into: ");
		PestNumPiecesNeeded = CreateNumberInputField(horzPestNumPiecesNeeded).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.PestilencePiecesNeeded).SetWholeNumbers(true).SetInteractable(true);

		horzPestilencePiecesPerTurn = CreateHorz(UIcontainer);
		CreateLabel(horzPestilencePiecesPerTurn).SetText("Minimum pieces awarded per turn: ");
		PestilencePiecesPerTurn = CreateNumberInputField(horzPestilencePiecesPerTurn).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.PestilencePiecesPerTurn).SetWholeNumbers(true).SetInteractable(true);

		horzPestStartingCardPieceQty = CreateHorz(UIcontainer);
		CreateLabel(horzPestStartingCardPieceQty).SetText("Pieces given to each player at the start: ");
		PestStartingCardPieceQty = CreateNumberInputField(horzPestStartingCardPieceQty).SetSliderMinValue(1).SetSliderMaxValue(10).SetValue(Mod.Settings.PestilenceStartPieces).SetWholeNumbers(true).SetInteractable(true);

		-- Add a weight setting for the Pestilence card
		horzPestilenceWeight = CreateHorz(UIcontainer);
		CreateLabel(horzPestilenceWeight).SetText("Card weight: ");
		PestilenceCardWeight=1.0;Mod.Settings.PestilenceCardWeight=1.0;
		PestilenceCardWeight = CreateNumberInputField(horzPestilenceWeight).SetSliderMinValue(0).SetSliderMaxValue(10).SetValue(Mod.Settings.PestilenceCardWeight).SetWholeNumbers(false).SetInteractable(true);
	end
	print("Pestilence card checkbox clicked")
end
