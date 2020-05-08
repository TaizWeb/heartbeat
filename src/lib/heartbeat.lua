require("lib/camera")
require("lib/split")

-- TODO: Add a thing in heartbeat's init to create the levels folder if it doesn't exist
Heartbeat = {
	-- The gravitational constant, can be overridden for individual things by setting their own gravity parameter
	gravity = .5,
	-- Editor code
	editor = {
		isActive = false,
		mode = "tile",
		currentTile = "stone",
		currentEntity = "zombie",
		commandModeLine = ""
	},
	levelWidth = 0,
	levelHeight = 0,
	-- These will be set manually on startup
	tilesList = {},
	entitesList = {},
	itemsList = {},
	rooms = {},
	-- The currently loaded objects
	entities = {},
	tiles = {},
	items = {},
}

-- draw: Accepts two parameters, the object, and an optional texture. Without a texture the hitbox will be drawn.
function Heartbeat.draw(object)
	love.graphics.setColor(1, 1, 1, 1)
	if (texture ~= nil) then
		love.graphics.draw(texture, Camera.convert("x", object.x), Camera.convert("y", Camera.y), object.rotation, object.scaleX, object.scaleY, object.offsetX, object,offsetY)
	else
		love.graphics.rectangle("fill", Camera.convert("x", object.x), Camera.convert("y", object.y), object.width, object.height)
	end
end

-- createPlayer: Creates the player object and loads it into Heartbeat
function Heartbeat.createPlayer(object, x, y)
	Heartbeat.player = {
		x = x,
		y = y,
		dx = 0,
		dy = 0,
		height = object.height,
		width = object.width,
		health = 0,
		attack = 0,
		health = health,
		jumpFrames = 0,
		jumpCooldown = 0
	}
end

-- drawPlayer: Draws the player to the screen
function Heartbeat.drawPlayer()
	if (Player.draw ~= nil) then
		Player.draw()
	else
		Heartbeat.draw(Heartbeat.player)
	end
end

-- doPlayer: Updates the player's dy/dx and moves them
function Heartbeat.doPlayer()
	Heartbeat.player.dy = Heartbeat.player.dy + Heartbeat.gravity
	Heartbeat.checkCollisions(Heartbeat.player)
end

-- newEntity: Initializes and loads the entity into Heartbeat
function Heartbeat.newEntity(object, x, y)
	Heartbeat.entities[#Heartbeat.entities+1] = {
		id = object.id,
		x = x,
		y = y,
		originalX = object.x,
		originalY = object.y,
		dx = 0,
		dy = 0,
		width = object.width,
		height = object.height,
		health = object.health,
		attack = object.attack,
		behaivor = object.behaivor
	}
end

-- drawEntities: Draws all the entities to the screen
function Heartbeat.drawEntities()
	for i=1,#Heartbeat.entities do
		if (Heartbeat.entities[i].draw ~= nil) then
			Heartbeat.entities[i].draw()
		else
			Heartbeat.draw(Heartbeat.entities[i])
		end
	end
end

-- doEntities: Performs the entities AI if they have them, and checks their collisions
function Heartbeat.doEntities()
	for i=1,#Heartbeat.entities do
		local entity = Heartbeat.entities[i]
		if (entity ~= nil) then
			if (entity.behaivor ~= nil) then
				entity.behaivor(entity)
			end
			entity.dy = entity.dy + Heartbeat.gravity
			Heartbeat.checkCollisions(entity)
		end
	end
end

-- newTile: Initializes a new tile and loads it into Heartbeat
function Heartbeat.newTile(object, x, y)
	local isNewTile = true
	for i=1,#Heartbeat.tiles do
		-- If tile currently exists, set isNewTile to false
		if (Heartbeat.tiles[i].x == x and Heartbeat.tiles[i].y == y and Heartbeat.tiles[i].id == Heartbeat.editor.currentTile) then
			isNewTile = false
		end
	end
	if (isNewTile) then
		Heartbeat.tiles[#Heartbeat.tiles+1] = {
			id = object.id,
			x = x,
			y = y,
			width = object.width,
			height = object.height,
			texture = object.texture
		}
	end
end

-- drawTiles: Draws the tiles to the screen
function Heartbeat.drawTiles()
	for i=1,#Heartbeat.tiles do
		Heartbeat.draw(Heartbeat.tiles[i])
	end
end

function Heartbeat.lookupTile(id)
	for i=1,#Heartbeat.tilesList do
		if (id == Heartbeat.tilesList[i].id) then
			return Heartbeat.tilesList[i]
		end
	end
end

function Heartbeat.lookupEntity(id)
	for i=1,#Heartbeat.entitiesList do
		if (id == Heartbeat.entitiesList[i].id) then
			return Heartbeat.entitiesList[i]
		end
	end
end

function Heartbeat.editor.drawEditor()
	if (Heartbeat.editor.isActive) then
		if (Heartbeat.editor.mode == "tile") then
			Heartbeat.debugLine = "Current Tile: " .. Heartbeat.lookupTile(Heartbeat.editor.currentTile).id .. "\n"
		elseif (Heartbeat.editor.mode == "entity") then
			Heartbeat.debugLine = "Current Entity: " .. Heartbeat.lookupEntity(Heartbeat.editor.currentEntity).id .. "\n"
		elseif (Heartbeat.editor.mode == "item") then
			Heartbeat.debugLine = "Current Item: " .. Heartbeat.lookupItem(Heartbeat.editor.currentItem).id .. "\n"
		end
		-- Drawing current tile/entity/item info
		love.graphics.setColor(1, 1, 1, 1)
		love.graphics.print(Heartbeat.debugLine)
		-- Drawing the commandModeLine
		if (Heartbeat.editor.commandMode) then
			love.graphics.setColor(0, 1, 0, 1)
			love.graphics.print(":" .. Heartbeat.editor.commandModeLine, 0, windowHeight - 20)
		end
		-- Drawing the cursor
		love.graphics.setColor(1, 1, 1, .5)
		love.graphics.rectangle("fill", math.floor(love.mouse.getX() / 25) * 25, math.floor(love.mouse.getY() / 25) * 25, 25, 25)
	end
end

function Heartbeat.editor.handleInput(key)
	if (Heartbeat.editor.commandMode) then
		if (key == "return") then
			Heartbeat.editor.executeCommand()
			Heartbeat.editor.commandModeLine = ""
			Heartbeat.editor.commandMode = false
		elseif (key == "backspace") then
				Heartbeat.editor.commandModeLine = Heartbeat.editor.commandModeLine:sub(1, -2)
		else
			if (key == "space") then
				key = " "
			-- Removing invalid characters
			elseif (key == "lshift" or key == "rshift" or key == "capslock"
				or key == "lalt" or key == "ralt" or key == "tab"
				or key == "lctrl" or key == "rctrl" or key == "up"
				or key == "down" or key == "left" or key == "right"
				or key == "escape" or key == "m1" or key == "m2") then
				key = ""
			end
			Heartbeat.editor.commandModeLine = Heartbeat.editor.commandModeLine .. key
		end
	end
	-- Handle mouse click, place tile/entity/item
	if (key == 1) then
		local snapx = math.floor((love.mouse.getX() + Camera.x) / 25) * 25
		local snapy = math.floor((love.mouse.getY() + Camera.y) / 25) * 25
		if (Heartbeat.editor.mode == "tile") then
			local tileInfo = Heartbeat.lookupTile(Heartbeat.editor.currentTile)
			Heartbeat.newTile(tileInfo, snapx, snapy)
		end
		if (Heartbeat.editor.mode == "entity") then
			local entityInfo = Heartbeat.lookupEntity(Heartbeat.editor.currentEntity)
			Heartbeat.newEntity(entityInfo, snapx, snapy)
		end
	end
	-- Handle swapping between tile/entity/item
	if (key == "down") then
		if (Heartbeat.editor.mode == "tile") then
			Heartbeat.editor.mode = "entity"
		elseif (Heartbeat.editor.mode == "entity") then
			Heartbeat.editor.mode = "item"
		end
	end
	if (key == "up") then
		if (Heartbeat.editor.mode == "entity") then
			Heartbeat.editor.mode = "tile"
		elseif (Heartbeat.editor.mode == "item") then
			Heartbeat.editor.mode = "entity"
		end
	end
	-- Enable command mode, for saving/reading
	if (key == ";") then
		Heartbeat.editor.commandMode = true
	end
end

function Heartbeat.editor.executeCommand()
	-- :w <levelname> (writes level to file)
	if (Heartbeat.editor.commandModeLine:sub(1, 1) == "w") then
		if (currentLevel == "" and Heartbeat.editor.commandModeLine:len() < 2) then
			print("Error: No level name defined.\n Usage: :w <filename>")
		else
			local args = split(Heartbeat.editor.commandModeLine, " ")
			Heartbeat.editor.saveLevel(args[2])
		end
	-- :o <filename> (reads level from file)
	elseif (Heartbeat.editor.commandModeLine:sub(1, 1) == "o") then
		if (Heartbeat.editor.commandModeLine:len() > 2) then
			Heartbeat.clear()
			local args = split(Heartbeat.editor.commandModeLine, " ")
			Heartbeat.editor.readLevel(args[2])
		end
	-- :set <height/width> (sets level height/width)
	elseif (Heartbeat.editor.commandModeLine:sub(1, 3) == "set") then
		local args = split(Heartbeat.editor.commandModeLine, " ")
		if (args[2] == "height") then
			Heartbeat.levelHeight = args[3]
			print("Level height set to " .. args[3])
		elseif (args[2] == "width") then
			Heartbeat.levelWidth = args[3]
			print("Level width set to " .. args[3])
		else
			print("Error: Invalid arguments.\nUsage: set <variable> <value>")
		end
	-- :clear (clears level)
	elseif (Heartbeat.editor.commandModeLine:sub(1, 5) == "clear") then
		Heartbeat.clear()
	-- :list (Prints all the levels to the commandline
	elseif (Heartbeat.editor.commandModeLine:sub(1, 4) == "list") then
		local levelList = love.filesystem.getDirectoryItems("levels")		for i=1,#levelList do
		print("Levels:")
			print(levelList[i])
		end
	else
		print("Error. Command not found.")
	end
end

function Heartbeat.editor.saveLevel(levelName)
	levelName = "levels/" .. levelName -- Writing levels to the levels directory
	-- Creating a file 'levelName' and adding the width/height
	love.filesystem.write(levelName, Heartbeat.levelWidth .. " " .. Heartbeat.levelHeight .. "\n")
	-- Write the doors to the file
	love.filesystem.append(levelName, "DOORS\n")
	for i=1,#Heartbeat.rooms do
		love.filesystem.append(levelName, Heartbeat.rooms[i].x .. " " .. Heartbeat.rooms[i].y .. " " .. Heartbeat.rooms[i].location .. " " .. Heartbeat.rooms[i].newX .. " " .. Heartbeat.rooms[i].newY .. "\n")
	end
	-- Write the tiles to the file
	love.filesystem.append(levelName, "TILES\n")
	for i=1,#Heartbeat.tiles do
		love.filesystem.append(levelName, Heartbeat.tiles[i].x .. " " .. Heartbeat.tiles[i].y .. " " .. Heartbeat.tiles[i].id .. "\n")
	end
	-- Write the entities to the file
	love.filesystem.append(levelName, "ENTITIES\n")
	for i=1,#Heartbeat.entities do
		love.filesystem.append(levelName, Heartbeat.entities[i].x .. " " .. Heartbeat.entities[i].y .. " " .. Heartbeat.entities[i].id .. "\n")
	end
	-- Print success message
	print("Written '" .. levelName .. "' to file.")
end

function Heartbeat.editor.readLevel(levelName)
	local rawLevelData = love.filesystem.read("levels/" .. levelName)
	-- Check if file exists
	if (rawLevelData == nil) then
		print("File '" .. levelName .. "' not found.")
		return
	end

	local levelLines = split(rawLevelData, "\n")

	-- Extracting the dimensions of the level
	local levelDimensions = split(levelLines[1], " ")
	Heartbeat.levelWidth = tonumber(levelDimensions[1])
	Heartbeat.levelHeight = tonumber(levelDimensions[2])

	-- Values needed for the loops
	local levelLineData
	local i = 3 -- For door loop (line 1 is dimensions, 2 is a title, so 3 is where we start)
	local j = 0 -- For tile loop
	local k = 0 -- For item loop

	-- Load the doors
	for i=i,#levelLines do
		if (levelLines[i] == "TILES") then
			j = i+1 -- To skip the TILES line
			break
		end
		levelLineData = split(levelLines[i], " ")
		Heartbeat.rooms = {}
		Heartbeat.rooms[#Level.rooms+1] = {x = tonumber(levelLineData[1]), y = tonumber(levelLineData[2]), location = levelLineData[3], newX = tonumber(levelLineData[4]), newY = tonumber(levelLineData[5])}
	end

	-- Load the tiles
	for j=j,#levelLines do
		if (levelLines[j] == "ENTITIES") then
			k = j+1 -- To skip the ENTITIES line
			break
		end
		levelLineData = split(levelLines[j], " ")
		local tile = Heartbeat.lookupTile(levelLineData[3])
		local tileData = {
			id = tile.id,
			width = tile.width,
			height = tile.height
		}
		Heartbeat.newTile(tileData, tonumber(levelLineData[1]), tonumber(levelLineData[2]))
		--Heartbeat.tiles[Level.tileCount+1] = {x = tonumber(levelLineData[1]), y = tonumber(levelLineData[2]), id = tonumber(levelLineData[3])}
	end

	-- Load the entities
	for k=k,#levelLines-1 do -- -1 to avoid EOF
		--if (levelLines[i] == "ITEMS") then
			--l = k
			--break
		--end
		levelLineData = split(levelLines[k], " ")
		local entity = Heartbeat.lookupEntity(levelLineData[3])
		local entityData = {
			id = entity.id,
			height = entity.height,
			width = entity.width,
			health = entity.health,
			attack = entity.attack
		}
		Heartbeat.newEntity(entityData, tonumber(levelLineData[1]), tonumber(levelLineData[2]))
		--Heartbeat.spawnEntity(tonumber(levelLineData[1]), tonumber(levelLineData[2]), tonumber(levelLineData[3]))
	end
	print("Loaded '" .. levelName .. "' successfully.")
end

-- clear: Clears all the entities and tiles
function Heartbeat.clear()
	Heartbeat.tiles = {}
	Heartbeat.entities = {}
end

-- checkCollisions: Checks the collisions of all the entities against the tiles
function Heartbeat.checkCollisions(entity)
	local attemptedX = entity.x + entity.dx
	local attemptedY = entity.y + entity.dy
	local collisionX = false
	local collisionY = false

	for i=1,#Heartbeat.tiles do
		if (entity.x < Heartbeat.tiles[i].x + Heartbeat.tiles[i].width and entity.x + entity.width > Heartbeat.tiles[i].x and attemptedY < Heartbeat.tiles[i].y + Heartbeat.tiles[i].height and attemptedY + entity.height > Heartbeat.tiles[i].y) then
			entity.dy = 0
			entity.isFalling = false
			collisionY = true
		end
		if (attemptedX < Heartbeat.tiles[i].x + Heartbeat.tiles[i].width and attemptedX + entity.width > Heartbeat.tiles[i].x and entity.y < Heartbeat.tiles[i].y + Heartbeat.tiles[i].height and entity.y + entity.height > Heartbeat.tiles[i].y) then
			collisionX = true
		end
	end

	-- Applying Forces
	if (not collisionY) then
		entity.y = entity.y + entity.dy
	end
	if (not collisionX) then
		entity.x = entity.x + entity.dx
	end
end

-- checkEntityCollisons: Compares two entities, returns true if they collide
function Heartbeat.checkEntityCollision(entity1, entity2)
	if (Camera.convert("x", entity1.x) < Camera.convert("x", entity2.x) + entity2.width and ((Camera.convert("x", entity1.x) + entity1.width) > (Camera.convert("x", entity2.x))) and Camera.convert("y", entity1.y) < Camera.convert("y", entity2.y) + entity2.height and ((Camera.convert("y", entity1.y) + entity1.height) > (Camera.convert("y", entity2.y)))) then
		return true
	else
		return false
	end
end

-- setDimensions: Sets the dimensions of the level
function Heartbeat.setDimensions(width, height)
	Heartbeat.levelWidth = width
	Heartbeat.levelHeight = height
end

-- drawBackground: Draws the background, currently supports only solid colors
function Heartbeat.drawBackground()
	love.graphics.setColor(0, 0, 0, 1)
	love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)
end

-- Heartbeat's main function
function Heartbeat.beat()
	if (not Heartbeat.editor.isActive) then
		Heartbeat.doEntities()
		Heartbeat.doPlayer()
	end
	Heartbeat.drawBackground()
	Heartbeat.drawTiles()
	Heartbeat.drawEntities()
	Heartbeat.drawPlayer()
	Heartbeat.editor.drawEditor()
end

