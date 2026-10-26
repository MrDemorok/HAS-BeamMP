local M = {}
local gameState = {gameRunning = false, players = {}}

local function setGameState(newState)
	gameState = newState
end

local function updateGFX()
	if not gameState.gameRunning then
		return
	end
	if not mapmgr or not mapmgr.objectCollisionIds then
		return
	end

	local ownVehicleID = obj:getId()
	local ownPosition = obj:getCenterPosition()
	local ownLength = obj:getInitialLength()

	for _, otherVehicleID in pairs(mapmgr.objectCollisionIds) do
		if otherVehicleID ~= ownVehicleID then
			local otherPosition = obj:getObjectCenterPosition(otherVehicleID)
			local otherLength = obj:getObjectInitialLength(otherVehicleID)
			if otherPosition and ownPosition:distance(otherPosition) < ((ownLength + otherLength) / 2) * 1.1 then
				obj:queueGameEngineLua(
					"if has then has.sendContact(" .. tostring(otherVehicleID) .. ") end"
				)
			end
		end
	end
end

M.setGameState = setGameState
M.updateGFX = updateGFX

return M
