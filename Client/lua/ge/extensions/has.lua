local M = {}
local hasBlur = require("client/postFx/hasBlur")

local gameState = {gameRunning = false, phase = "idle", players = {}}
local savedColors = {}
local resetActions = {
	"recover_vehicle",
	"recover_vehicle_alt",
	"recover_to_last_road",
}
local hardBlockedActions = {
	"dropPlayerAtCamera",
	"dropPlayerAtCameraNoReset",
	"reload_all_vehicles",
	"loadHome",
	"saveHome",
	"reset_all_physics",
	"reset_physics",
}
local reloadActions = {"reload_vehicle"}
local movementActions = {"accelerate", "brake", "steering", "parkingbrake", "gearUp", "gearDown"}
local roundRestrictedActions = {
	"toggleCamera",
	"switch_camera",
	"switch_camera_next",
	"switch_camera_prev",
	"switch_camera_previous",
	"switchCamera",
	"nextCamera",
	"previousCamera",
	"toggleMenues",
	"vehicle_selector",
	"switchVehicle",
	"nextVehicle",
	"previousVehicle",
}
local resetFilter = "hasNoVehicleReset"
local hardResetFilter = "hasNoTeleportOrReset"
local reloadFilter = "hasNoVehicleReload"
local movementFilter = "hasVehicleLock"
local roundRestrictionFilter = "hasRoundRestrictions"
local lockedVehicleID
local returningToLockedVehicle = false
local stationarySeconds = 0
local hudTimer = 0
local nicknamesHidden = false
local notices = {
	pl = {
		roundStarting = "Wylosowano szukającego: %s. Start rundy za %d s.",
		seekerChosen = "%s szuka! Chowający mają czas na schowanie.",
		hidingEnded = "Koniec czasu na chowanie! Szukający rusza.",
		playerCaught = "%s został złapany i teraz pomaga szukać!",
		seekersWin = "Szukający wygrali! Wszyscy zostali znalezieni.",
		hidersWin = "Chowający wygrali! Czas rundy się skończył.",
		roundStopped = "Runda HAS została zatrzymana.",
	},
	en = {
		roundStarting = "The seeker is %s. The round starts in %d seconds.",
		seekerChosen = "%s is seeking! Hiders have time to hide.",
		hidingEnded = "Hiding time is over! The seeker is released.",
		playerCaught = "%s was caught and is now helping the seekers!",
		seekersWin = "The seekers win! Everyone has been found.",
		hidersWin = "The hiders win! Time ran out.",
		roundStopped = "The HAS round has been stopped.",
	},
}

local blueColor = Point4F(0.08, 0.25, 1, 1)

local function getLocalPlayerName()
	return MPConfig and MPConfig.getNickname and MPConfig.getNickname() or nil
end

local function getRole()
	local playerName = getLocalPlayerName()
	return playerName and gameState.players and gameState.players[playerName] or nil
end

local function restoreColors()
	if not MPVehicleGE then
		savedColors = {}
		return
	end
	for _, vehicle in pairs(MPVehicleGE.getVehicles()) do
		local saved = savedColors[vehicle.gameVehicleID]
		local object = be:getObjectByID(vehicle.gameVehicleID)
		if saved and object then
			if saved.color then object.color = saved.color end
			if saved.palette0 then object.colorPalette0 = saved.palette0 end
			if saved.palette1 then object.colorPalette1 = saved.palette1 end
		end
	end
	savedColors = {}
end

local function clearFilters()
	core_input_actionFilter.setGroup(resetFilter, resetActions)
	core_input_actionFilter.addAction(0, resetFilter, false)
	core_input_actionFilter.setGroup(hardResetFilter, hardBlockedActions)
	core_input_actionFilter.addAction(0, hardResetFilter, false)
	core_input_actionFilter.setGroup(reloadFilter, reloadActions)
	core_input_actionFilter.addAction(0, reloadFilter, false)
	core_input_actionFilter.setGroup(movementFilter, movementActions)
	core_input_actionFilter.addAction(0, movementFilter, false)
	core_input_actionFilter.setGroup(roundRestrictionFilter, roundRestrictedActions)
	core_input_actionFilter.addAction(0, roundRestrictionFilter, false)
	stationarySeconds = 0
end

local function resetEffects()
	restoreColors()
	if MPVehicleGE then
		MPVehicleGE.hideNicknames(false)
	end
	nicknamesHidden = false
	if hasBlur then
		hasBlur.setEnabled(false)
	end
	clearFilters()
end

local function receiveState(data)
	local newState = type(data) == "string" and jsonDecode(data) or data
	if type(newState) ~= "table" then
		log("E", "has", "Received invalid game state from server")
		return
	end

	local wasRunning = gameState.gameRunning
	gameState = newState
	M.gameState = gameState

	if be and be.queueAllObjectLua then
		be:queueAllObjectLua("if has then has.setGameState(" .. serialize(gameState) .. ") end")
	end

	if not gameState.gameRunning then
		lockedVehicleID = nil
		resetEffects()
	elseif not wasRunning then
		savedColors = {}
		stationarySeconds = 0
		lockedVehicleID = be and be:getPlayerVehicleID(0) or nil
	end
end

local function showNotice(data)
	local notice = type(data) == "string" and jsonDecode(data) or data
	if type(notice) ~= "table" then
		log("E", "has", "Received invalid notice from server")
		return
	end

	local language = notice.language == "en" and "en" or "pl"
	local text = notices[language][notice.kind]
	if not text then
		return
	end
	if notice.kind == "roundStarting" then
		text = string.format(text, notice.playerName or "", notice.seconds or 5)
	elseif notice.kind == "seekerChosen" or notice.kind == "playerCaught" then
		text = string.format(text, notice.playerName or "")
	end
	guihooks.message({txt = text}, 5, "has.notice")
end

local function requestState()
	if TriggerServerEvent then
		TriggerServerEvent("has_requestState", "state")
	end
end

local function sendContact(remoteVehicleID)
	if not MPVehicleGE or not TriggerServerEvent then
		return
	end
	local ownVehicleID = be:getPlayerVehicleID(0)
	if not ownVehicleID or not MPVehicleGE.isOwn(ownVehicleID) then
		return
	end
	local ownVehicle = MPVehicleGE.getVehicleByGameID(ownVehicleID)
	local remoteVehicle = MPVehicleGE.getVehicleByGameID(remoteVehicleID)
	if not ownVehicle or not remoteVehicle then
		return
	end
	local ownRole = gameState.players and gameState.players[ownVehicle.ownerName]
	local remoteRole = gameState.players and gameState.players[remoteVehicle.ownerName]
	if ownRole and ownRole.isSeeker and remoteRole and not remoteRole.caught then
		local serverVehicleID = MPVehicleGE.getServerVehicleID(remoteVehicleID)
		local remotePlayerID = serverVehicleID and string.match(serverVehicleID, "^(%d+)%-%d+$")
		if remotePlayerID then
			TriggerServerEvent("has_contact", remotePlayerID)
		end
	end
end

local function enforceVehicleLock()
	if not gameState.gameRunning or returningToLockedVehicle or not MPVehicleGE then
		return
	end

	local currentVehicleID = be:getPlayerVehicleID(0)
	if not currentVehicleID then
		return
	end
	if not lockedVehicleID then
		lockedVehicleID = currentVehicleID
		return
	end
	if currentVehicleID == lockedVehicleID then
		return
	end

	local lockedVehicle = be:getObjectByID(lockedVehicleID)
	if lockedVehicle and MPVehicleGE.isOwn(lockedVehicleID) then
		returningToLockedVehicle = true
		be:enterVehicle(0, lockedVehicle)
		returningToLockedVehicle = false
	else
		lockedVehicleID = currentVehicleID
	end
end

local function onPreRender(dt)
	if not gameState.gameRunning or not MPVehicleGE then
		return
	end

	enforceVehicleLock()
	local me = getRole()
	local currentVehicleID = be:getPlayerVehicleID(0)
	local currentVehicle = currentVehicleID and be:getObjectByID(currentVehicleID)
	local isLocked = gameState.phase == "countdown"
		or (gameState.phase == "hiding" and me and not me.caught and me.isSeeker)
	local isHider = me and not me.isSeeker and not me.caught

	if gameState.phase ~= "countdown" then
		if not nicknamesHidden then
			MPVehicleGE.hideNicknames(true)
			nicknamesHidden = true
		end
	end

	if hasBlur then
		hasBlur.setEnabled(gameState.phase == "hiding" and me and me.isSeeker and not me.caught or false)
	end

	if isLocked and currentVehicle then
		core_input_actionFilter.setGroup(movementFilter, movementActions)
		core_input_actionFilter.addAction(0, movementFilter, true)
	elseif currentVehicle then
		core_input_actionFilter.setGroup(movementFilter, movementActions)
		core_input_actionFilter.addAction(0, movementFilter, false)
	end

	if isHider and currentVehicle then
		local speed = currentVehicle:getVelocity():length()
		if speed < 0.1 then
			stationarySeconds = math.min(10, stationarySeconds + dt)
		else
			stationarySeconds = 0
		end
	end
	local blockRecovery = isHider == true and currentVehicle ~= nil and stationarySeconds < 10
	core_input_actionFilter.setGroup(resetFilter, resetActions)
	core_input_actionFilter.addAction(0, resetFilter, blockRecovery)
	core_input_actionFilter.setGroup(hardResetFilter, hardBlockedActions)
	core_input_actionFilter.addAction(0, hardResetFilter, me ~= nil)
	core_input_actionFilter.setGroup(reloadFilter, reloadActions)
	core_input_actionFilter.addAction(0, reloadFilter, blockRecovery)
	core_input_actionFilter.setGroup(roundRestrictionFilter, roundRestrictedActions)
	core_input_actionFilter.addAction(0, roundRestrictionFilter, true)

	local roleColorsActive = gameState.phase ~= "countdown"
	local pulse = roleColorsActive and gameState.settings and gameState.settings.colorPulse
		and (0.5 + 0.5 * math.sin(os.clock() * 3)) or 1
	for _, vehicle in pairs(MPVehicleGE.getVehicles()) do
		local player = gameState.players and gameState.players[vehicle.ownerName]
		if roleColorsActive and player and player.isSeeker then
			local object = be:getObjectByID(vehicle.gameVehicleID)
			if object then
				local vehicleID = vehicle.gameVehicleID
				local saved = savedColors[vehicleID]
				if not saved then
					saved = {
						color = object.color,
						palette0 = object.colorPalette0,
						palette1 = object.colorPalette1,
					}
					savedColors[vehicleID] = saved
				end
				local amount = pulse
				object.color = Point4F(
					saved.color.x * (1 - amount) + blueColor.x * amount,
					saved.color.y * (1 - amount) + blueColor.y * amount,
					saved.color.z * (1 - amount) + blueColor.z * amount,
					saved.color.w
				)
				object.colorPalette0 = object.color
				object.colorPalette1 = object.color
			end
		end
	end

	hudTimer = hudTimer + dt
	if hudTimer >= 1 then
		hudTimer = 0
		if gameState.phase == "round" then
			local foundText
			if gameState.language == "en" then
				foundText = string.format("Found %d/%d   %02d:%02d", gameState.foundCount, gameState.playerCount,
					math.floor(gameState.secondsLeft / 60), gameState.secondsLeft % 60)
			else
				foundText = string.format("Znalezieni %d/%d   %02d:%02d", gameState.foundCount, gameState.playerCount,
					math.floor(gameState.secondsLeft / 60), gameState.secondsLeft % 60)
			end
			guihooks.message({txt = foundText}, 1, "has.roundStatus")
		elseif gameState.phase == "hiding" then
			local hidingText = gameState.language == "en"
				and string.format("Hiding time: %d seconds", gameState.secondsLeft)
				or string.format("Czas na schowanie: %d s", gameState.secondsLeft)
			guihooks.message({txt = hidingText}, 1, "has.roundStatus")
		elseif gameState.phase == "countdown" then
			local countdownText = gameState.language == "en"
				and string.format("Round starts in %d seconds", gameState.secondsLeft)
				or string.format("Start rundy za %d s", gameState.secondsLeft)
			guihooks.message({txt = countdownText}, 1, "has.roundStatus")
		end
		if isHider and currentVehicle then
			if stationarySeconds >= 10 then
				local repairText = gameState.language == "en"
					and "You can recover your vehicle now"
					or "Możesz teraz naprawić pojazd"
				guihooks.message({txt = repairText}, 1, "has.repairStatus")
			else
				local secondsUntilRepair = math.ceil(10 - stationarySeconds)
				local repairText = gameState.language == "en"
					and string.format("Stop to recover your vehicle: %d seconds", secondsUntilRepair)
					or string.format("Zatrzymaj się, aby naprawić pojazd: %d s", secondsUntilRepair)
				guihooks.message({txt = repairText}, 1, "has.repairStatus")
			end
		elseif me and me.isSeeker then
			local repairText = gameState.language == "en"
				and "As a seeker, you can recover your vehicle anytime"
				or "Jako szukający możesz naprawić pojazd w każdej chwili"
			guihooks.message({txt = repairText}, 1, "has.repairStatus")
		else
			guihooks.message({txt = ""}, 0, "has.repairStatus")
		end
	end
end

local function onVehicleSwitched(oldVehicleID, newVehicleID, player)
	if gameState.gameRunning and gameState.phase ~= "countdown" and MPVehicleGE then
		MPVehicleGE.hideNicknames(true)
		nicknamesHidden = true
	end
end

local function onExtensionUnloaded()
	resetEffects()
end

if MPGameNetwork then
	AddEventHandler("has_state", receiveState)
	AddEventHandler("has_notice", showNotice)
end

requestState()

M.onPreRender = onPreRender
M.onVehicleSwitched = onVehicleSwitched
M.onExtensionUnloaded = onExtensionUnloaded
M.sendContact = sendContact
M.gameState = gameState
M.onInit = function()
	setExtensionUnloadMode(M, "manual")
end

return M
