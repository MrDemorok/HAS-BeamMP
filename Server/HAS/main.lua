local settings = {
	language = "pl",
	roundSeconds = 300,
	hideSeconds = 30,
	countdownSeconds = 5,
	colorPulse = false,
}

local state = {
	gameRunning = false,
	phase = "idle",
	players = {},
}

local messages = {
	pl = {
		help = "Komendy: /has start | stop | language [pl|en] | settings [round|hide|countdown] [sekundy] | settings pulse [on|off] | help",
		started = "Runda HAS rozpocznie się za %d sekund.",
		noPlayers = "Nie można rozpocząć: potrzebnych jest co najmniej 2 graczy z pojazdem.",
		alreadyRunning = "Runda HAS już trwa.",
		notRunning = "Runda HAS nie jest uruchomiona.",
		stopped = "Runda HAS została zatrzymana.",
		invalidLanguage = "Język musi być ustawiony na pl albo en.",
		languageSet = "Język HAS ustawiony na polski.",
		settingSet = "Ustawienie %s zmieniono na %d sekund.",
		invalidSetting = "Użycie: /has settings [round|hide|countdown] [sekundy] lub /has settings pulse [on|off].",
		invalidValue = "Wartość musi być liczbą całkowitą większą od zera.",
		languageInfo = "Aktualny język: %s. Użyj /has language pl albo /has language en.",
		pulseUsage = "Użycie: /has settings pulse [on|off].",
		pulseSet = "Miganie koloru pojazdów szukających: %s.",
		unknownCommand = "Nieznana komenda. Wpisz /has help.",
	},
	en = {
		help = "Commands: /has start | stop | language [pl|en] | settings [round|hide|countdown] [seconds] | settings pulse [on|off] | help",
		started = "HAS round starts in %d seconds.",
		noPlayers = "Cannot start: at least 2 players with vehicles are required.",
		alreadyRunning = "A HAS round is already running.",
		notRunning = "No HAS round is running.",
		stopped = "The HAS round has been stopped.",
		invalidLanguage = "Language must be pl or en.",
		languageSet = "HAS language set to English.",
		settingSet = "Setting %s changed to %d seconds.",
		invalidSetting = "Usage: /has settings [round|hide|countdown] [seconds] or /has settings pulse [on|off].",
		invalidValue = "Value must be a positive whole number.",
		languageInfo = "Current language: %s. Use /has language pl or /has language en.",
		pulseUsage = "Usage: /has settings pulse [on|off].",
		pulseSet = "Seeker vehicle color pulse: %s.",
		unknownCommand = "Unknown command. Type /has help.",
	},
}

local settingNames = {
	pl = {round = "rundy", hide = "chowania", countdown = "odliczania"},
	en = {round = "round", hide = "hiding", countdown = "countdown"},
}

local function sendPrivate(playerID, message)
	MP.SendChatMessage(playerID, message)
end

local function broadcastNotice(kind, playerName, seconds)
	MP.TriggerClientEventJson(-1, "has_notice", {
		kind = kind,
		playerName = playerName,
		seconds = seconds,
		language = settings.language,
	})
end

local function broadcastState()
	state.settings = {
		colorPulse = settings.colorPulse,
	}
	MP.TriggerClientEventJson(-1, "has_state", state)
end

local function finishRound(winner)
	if not state.gameRunning then
		return
	end

	state.gameRunning = false
	state.phase = "ended"
	state.winner = winner
	state.secondsLeft = 0
	broadcastNotice(winner == "seekers" and "seekersWin" or "hidersWin")
	broadcastState()
	state = {
		gameRunning = false,
		phase = "idle",
		players = {},
		language = settings.language,
	}
end

local function beginHiding()
	state.phase = "hiding"
	state.secondsLeft = settings.hideSeconds
	broadcastNotice("seekerChosen", state.seekerName)
	broadcastState()
end

local function startRound(senderID)
	if state.gameRunning then
		sendPrivate(senderID, messages[settings.language].alreadyRunning)
		return
	end

	local players = {}
	for playerID, playerName in pairs(MP.GetPlayers()) do
		if MP.IsPlayerConnected(playerID) and MP.GetPlayerVehicles(playerID) then
			players[playerName] = {
				id = playerID,
				isSeeker = false,
				caught = false,
			}
		end
	end

	local names = {}
	for playerName in pairs(players) do
		names[#names + 1] = playerName
	end
	if #names < 2 then
		sendPrivate(senderID, messages[settings.language].noPlayers)
		return
	end

	local seekerName = names[math.random(#names)]
	players[seekerName].isSeeker = true

	state = {
		gameRunning = true,
		phase = "countdown",
		players = players,
		seekerName = seekerName,
		playerCount = #names,
		foundCount = 1,
		secondsLeft = settings.countdownSeconds,
		roundSeconds = settings.roundSeconds,
		hideSeconds = settings.hideSeconds,
		language = settings.language,
	}
	broadcastNotice("roundStarting", seekerName, settings.countdownSeconds)
	broadcastState()
	sendPrivate(senderID, string.format(messages[settings.language].started, settings.countdownSeconds))
end

local function stopRound(senderID)
	if not state.gameRunning then
		sendPrivate(senderID, messages[settings.language].notRunning)
		return
	end

	state.gameRunning = false
	state.phase = "ended"
	state.winner = "stopped"
	broadcastNotice("roundStopped")
	broadcastState()
	state = {
		gameRunning = false,
		phase = "idle",
		players = {},
		language = settings.language,
	}
	sendPrivate(senderID, messages[settings.language].stopped)
end

local function handleCommand(senderID, message)
	local command = string.match(message, "^%s*/[hH][aA][sS]%s*(.*)$")
	if command == nil then
		return false
	end

	local args = {}
	for token in string.gmatch(command, "%S+") do
		args[#args + 1] = string.lower(token)
	end

	local languageMessages = messages[settings.language]
	local subcommand = args[1] or "help"
	if subcommand == "help" then
		sendPrivate(senderID, languageMessages.help)
	elseif subcommand == "start" then
		startRound(senderID)
	elseif subcommand == "stop" then
		stopRound(senderID)
	elseif subcommand == "language" then
		if not args[2] then
			sendPrivate(senderID, string.format(languageMessages.languageInfo, settings.language))
		elseif args[2] ~= "pl" and args[2] ~= "en" then
			sendPrivate(senderID, languageMessages.invalidLanguage)
		else
			settings.language = args[2]
			state.language = settings.language
			broadcastState()
			sendPrivate(senderID, messages[settings.language].languageSet)
		end
	elseif subcommand == "settings" then
		local setting = args[2]
		if setting == "pulse" then
			if args[3] ~= "on" and args[3] ~= "off" then
				sendPrivate(senderID, languageMessages.pulseUsage)
			else
				settings.colorPulse = args[3] == "on"
				local pulseState = settings.language == "pl"
					and (settings.colorPulse and "włączone" or "wyłączone")
					or (settings.colorPulse and "enabled" or "disabled")
				sendPrivate(senderID, string.format(languageMessages.pulseSet, pulseState))
				broadcastState()
			end
			return true
		end
		local value = tonumber(args[3])
		if not setting or not settings[setting .. "Seconds"] then
			sendPrivate(senderID, languageMessages.invalidSetting)
			return true
		end
		if not value or value < 1 or value % 1 ~= 0 then
			sendPrivate(senderID, languageMessages.invalidValue)
			return true
		end
		settings[setting .. "Seconds"] = value
		sendPrivate(senderID, string.format(languageMessages.settingSet, settingNames[settings.language][setting], value))
	else
		sendPrivate(senderID, languageMessages.unknownCommand)
	end
	return true
end

function hasChatMessageHandler(senderID, senderName, message)
	if handleCommand(senderID, message) then
		return 1
	end
end

function hasContactHandler(senderID, data)
	if not state.gameRunning or state.phase ~= "round" then
		return
	end

	local targetID = tonumber(data)
	if not targetID then
		return
	end
	local seekerName = MP.GetPlayerName(senderID)
	local targetName = MP.GetPlayerName(targetID)
	if not seekerName or not targetName then
		return
	end
	local seeker = state.players[seekerName]
	local target = state.players[targetName]
	if not seeker or not target or not targetName or target.caught or not seeker.isSeeker then
		return
	end

	target.caught = true
	target.isSeeker = true
	target.caughtBy = seekerName
	state.foundCount = state.foundCount + 1
	broadcastNotice("playerCaught", targetName)

	if state.foundCount >= state.playerCount then
		finishRound("seekers")
	else
		broadcastState()
	end
end

function hasPlayerDisconnected(playerID)
	if not state.gameRunning then
		return
	end
	local playerName
	for name, player in pairs(state.players) do
		if player.id == playerID then
			playerName = name
			break
		end
	end
	if not playerName then
		return
	end
	local player = state.players[playerName]
	if player.isSeeker then
		state.players[playerName] = nil
		local remainingSeekers = 0
		for _, remainingPlayer in pairs(state.players) do
			if remainingPlayer.isSeeker then
				remainingSeekers = remainingSeekers + 1
			end
		end
		if remainingSeekers == 0 then
			finishRound("hiders")
			return
		end
	elseif not player.caught then
		player.caught = true
		player.isSeeker = true
		state.foundCount = state.foundCount + 1
		broadcastNotice("playerCaught", playerName)
	end
	state.players[playerName] = nil
	if state.foundCount >= state.playerCount then
		finishRound("seekers")
	else
		broadcastState()
	end
end

function hasVehicleDeleted(playerID)
	if not state.gameRunning then
		return
	end
	local playerName = MP.GetPlayerName(playerID)
	local player = playerName and state.players[playerName]
	if not player or player.caught or player.isSeeker or MP.GetPlayerVehicles(playerID) then
		return
	end
	player.caught = true
	player.isSeeker = true
	state.foundCount = state.foundCount + 1
	broadcastNotice("playerCaught", playerName)
	if state.foundCount >= state.playerCount then
		finishRound("seekers")
	else
		broadcastState()
	end
end

function hasTimer()
	if not state.gameRunning then
		return
	end

	state.secondsLeft = state.secondsLeft - 1
	if state.phase == "countdown" and state.secondsLeft <= 0 then
		beginHiding()
	elseif state.phase == "hiding" and state.secondsLeft <= 0 then
		state.phase = "round"
		state.secondsLeft = state.roundSeconds
		broadcastNotice("hidingEnded")
		broadcastState()
	elseif state.phase == "round" and state.secondsLeft <= 0 then
		finishRound("hiders")
	else
		broadcastState()
	end
end

function hasRequestState(playerID)
	MP.TriggerClientEventJson(playerID, "has_state", state)
end

MP.RegisterEvent("onChatMessage", "hasChatMessageHandler")
MP.RegisterEvent("has_contact", "hasContactHandler")
MP.RegisterEvent("onPlayerDisconnect", "hasPlayerDisconnected")
MP.RegisterEvent("onVehicleDeleted", "hasVehicleDeleted")
MP.RegisterEvent("has_requestState", "hasRequestState")
MP.RegisterEvent("second", "hasTimer")
MP.CancelEventTimer("second")
MP.CreateEventTimer("second", 1000)
