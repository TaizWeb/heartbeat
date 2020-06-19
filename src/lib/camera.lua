-- On keypress, shift all tiles to the direction at the player's speed
-- Keep player in center unless approaching room bounds
Camera = {
	x = 0,
	y = 0
}

-- Add x and y directions
function Camera.update()
	Camera.x = Heartbeat.player.x - (windowWidth / 2)
	Camera.y = Heartbeat.player.y - (windowHeight / 2)
	-- Checking the bounds of the level
	if (Camera.x < 0) then
		Camera.x = 0
	end
	if (Camera.y < 0) then
		Camera.y = 0
	end
	if (Camera.x > (Heartbeat.levelWidth - windowWidth)) then
		Camera.x = Heartbeat.levelWidth - windowWidth
	end
	if (Camera.y > (Heartbeat.levelHeight - windowHeight)) then
		Camera.y = Heartbeat.levelHeight - windowHeight
	end
end

function Camera.convert(axis, value)
	if (axis == "x") then
		return value - Camera.x
	elseif (axis == "y") then
		return value - Camera.y
	else
		print("Invalid conversion")
	end
end

