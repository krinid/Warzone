@echo off
setlocal EnableDelayedExpansion

REM copy customCardPackage_A_refresh\Client*.lua "customCardPack - Utility - Shield, Monolith, Neutralize, Deneutralize" /y
REM copy customCardPackage_A_refresh\Server*.lua "customCardPack - Utility - Shield, Monolith, Neutralize, Deneutralize" /y
REM copy customCardPackage_A_refresh\utilities.lua "customCardPack - Utility - Shield, Monolith, Neutralize, Deneutralize" /y

REM copy customCardPackage_A_refresh\Client*.lua "customCardPack - OG refresh - Nuke, Pestilence, Isolation" /y
REM copy customCardPackage_A_refresh\Server*.lua "customCardPack - OG refresh - Nuke, Pestilence, Isolation" /y
REM copy customCardPackage_A_refresh\utilities.lua "customCardPack - OG refresh - Nuke, Pestilence, Isolation" /y

REM copy customCardPackage_A_refresh\Client*.lua "customCardPack - Disasters - Quicksand, Tornado, Earthquake, Forest Fire" /y
REM copy customCardPackage_A_refresh\Server*.lua "customCardPack - Disasters - Quicksand, Tornado, Earthquake, Forest Fire" /y
REM copy customCardPackage_A_refresh\utilities.lua "customCardPack - Disasters - Quicksand, Tornado, Earthquake, Forest Fire" /y

REM copy customCardPackage_A_refresh\Client*.lua "customCardPack - Card Actions - Card Block, Card Piece, Card Hold" /y
REM copy customCardPackage_A_refresh\Server*.lua "customCardPack - Card Actions - Card Block, Card Piece, Card Hold" /y
REM copy customCardPackage_A_refresh\utilities.lua "customCardPack - Card Actions - Card Block, Card Piece, Card Hold" /y

:: Define sources (files or folders)
set sources[0]=customCardPackage_A_refresh\Client*.lua
set sources[1]=customCardPackage_A_refresh\Server*.lua
set sources[2]=customCardPackage_A_refresh\utilities.lua
set sources[3]=customCardPackage_A_refresh\DataConverter.lua

:: Define destinations (must be existing folders)
set destinations[0]=customCardPack - Card Actions - Card Block, Card Piece, Card Hold
set destinations[1]=customCardPack - Disasters - Quicksand, Tornado, Earthquake, Forest Fire
set destinations[2]=customCardPack - OG refresh - Nuke, Pestilence, Isolation
set destinations[3]=customCardPack - Utility - Shield, Monolith, Neutralize, Deneutralize

:: Get source and destination counts
set sourceCount=3
set destinationCount=3

:: Loop through each destination
for /L %%d in (0,1,%destinationCount%) do (
    set "dest=!destinations[%%d]!"
    echo.
    REM echo Copying to destination: !dest!

    :: Loop through each source
    for /L %%s in (0,1,%sourceCount%) do (
        set "src=!sources[%%s]!"
        if exist "!src!" (
            REM echo SOURCE: !src!   DEST: !dest!
            xcopy "!src!" "!dest!\" /E /I /Y /H
        ) else (
            echo   WARNING: Source !src! does not exist
        )
    )
)

REM pause