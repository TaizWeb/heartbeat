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
		currentTile = 1,
		currentEntity = 1,
		currentItem = 1,
		commandModeLine = ""
	},
	dialog = {
		isOpen = false,
		font = love.graphics.newFont(20),
		speaker = nil,
		portrait = nil,
		dialogLines = {},
		dialogIndex = 0,
		-- What appears in the text box
		printedLines = {},
		dialogCharacter = 0,
		currentLine = "",
		speakers = {},
		portraits = {}
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
	player = {}
}

-- draw: Accepts two parameters, the object, and an optional texture. Without a texture the hitbox will be drawn.
function Heartbeat.draw(object)
	love.graphics.setColor(1, 1, 1, 1)
	if (object.texture ~= nil) then
		love.graphics.draw(object.texture, Camera.convert("x", object.x), Camera.convert("y", object.y), object.rotation, object.scaleX, object.scaleY, object.offsetX, object.offsetY)
	else
		love.graphics.rectangle("fill", Camera.convert("x", object.x), Camera.convert("y", object.y), object.width, object.height)
	end
end

-- createPlayer: Creates the player object and loads it into Heartbeat
function Heartbeat.createPlayer(object, x, y)
	Heartbeat.player.x = x
	Heartbeat.player.y = y
	Heartbeat.player.dx = 0
	Heartbeat.player.dy = 0
	Heartbeat.player.height = object.height
	Heartbeat.player.width = object.width
	Heartbeat.player.health = object.health
	Heartbeat.player.attack = object.attack
	Heartbeat.player.walkFrames = 0
	Heartbeat.player.jumpFrames = 0
	Heartbeat.player.jumpCooldown = 0
	Heartbeat.player.inventory = {}
	Heartbeat.player.forwardFace = true
	Heartbeat.player.cooldownFrames = 0
end

-- drawPlayer: Draws the player to the screen
function Heartbeat.drawPlayer()
	if (Player.draw ~= nil) then
		Player.draw(Heartbeat.player)
	else
		Heartbeat.draw(Heartbeat.player)
	end
end

-- doPlayer: Updates the player's dy/dx and moves them
function Heartbeat.doPlayer()
	Heartbeat.player.dy = Heartbeat.player.dy + Heartbeat.gravity
	Heartbeat.checkCollisions(Heartbeat.player)
	for i=1,#Heartbeat.items do
		if (Heartbeat.checkEntityCollision(Heartbeat.items[i], Heartbeat.player)) then
			local item = Heartbeat.items[i]
			if (item.onPickup ~= nil) then
				item.onPickup(item)
			end
		end
	end
end

function Heartbeat.jump(entity)
	if (not entity.isFalling) then
		entity.dy = -11
		entity.isFalling = true
	end
end

-- newEntity: Initializes and loads the entity into Heartbeat
function Heartbeat.newEntity(object, x, y)
	local isNewEntity = true
	for i=1,#Heartbeat.entities do
		-- If tile currently exists, set isNewTile to false
		if (Heartbeat.entities[i].x == x and Heartbeat.entities[i].y == y) then
			isNewEntity = false
		end
	end
	if (isNewEntity) then
		Heartbeat.entities[#Heartbeat.entities+1] = {
			id = object.id,
			texture = object.texture,
			x = x,
			y = y,
			originalX = object.x,
			originalY = object.y,
			dx = 0,
			dy = 0,
			width = object.width,
			height = object.height,
			rotation = object.rotation,
			health = object.health,
			attack = object.attack,
			behaivor = object.behaivor,
			onCollision = object.onCollision,
			onDeath = object.onDeath,
			draw = object.draw,
			isEnemy = object.isEnemy,
			forwardFace = object.forwardFace,
			movementFrames = object.movementFrames
		}
	end
	if (object.isNPC) then
		Heartbeat.entities[#Heartbeat.entities].isNPC = true
	end
end

-- drawEntities: Draws all the entities to the screen
function Heartbeat.drawEntities()
	for i=1,#Heartbeat.entities do
		if (Heartbeat.entities[i].draw ~= nil) then
			Heartbeat.entities[i].draw(Heartbeat.entities[i])
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
			local collidedObject = Heartbeat.checkCollisions(entity)
			if (collidedObject ~= nil and entity.onCollision ~= nil) then
				entity.onCollision(entity, collidedObject)
			end
		end
	end
	Heartbeat.player.cooldownFrames = Heartbeat.player.cooldownFrames - 1
end

function Heartbeat.updateEntityHealth(this, value)
	if (value <= 0) then
		if (this.onDeath ~= nil) then
			this.onDeath(this)
		end
		Heartbeat.removeEntity(this)
	end
	this.health = value
end

function Heartbeat.removeEntity(entity)
	for i=1,#Heartbeat.entities do
		if (entity == Heartbeat.entities[i]) then
			table.remove(Heartbeat.entities, i)
		end
	end
end

-- newTile: Initializes a new tile and loads it into Heartbeat
function Heartbeat.newTile(object, x, y)
	local isNewTile = true
	for i=1,#Heartbeat.tiles do
		-- If tile currently exists, set isNewTile to false
		if (Heartbeat.tiles[i].x == x and Heartbeat.tiles[i].y == y) then
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
			texture = object.texture,
			scaleX = object.scaleX,
			scaleY = object.scaleY,
			offsetX = object.offsetX,
			offsetY = object.offsetY,
			isSolid = object.isSolid,
			isPlatform = object.isPlatform,
			isSlope = object.isSlope
		}
	end
end

-- drawTiles: Draws the tiles to the screen
function Heartbeat.drawTiles()
	for i=1,#Heartbeat.tiles do
		Heartbeat.draw(Heartbeat.tiles[i])
	end
end

function Heartbeat.removeTile(tile)
	for i=1,#Heartbeat.tiles do
		if (tile == Heartbeat.tiles[i]) then
			table.remove(Heartbeat.tiles, i)
		end
	end
end

function Heartbeat.newItem(object, x, y)
	local isNewItem = true
	for i=1,#Heartbeat.items do
		-- If tile currently exists, set isNewTile to false
		if (Heartbeat.items[i].x == x and Heartbeat.items[i].y == y) then
			isNewItem = false
		end
	end
	if (isNewItem) then
		Heartbeat.items[#Heartbeat.items+1] = {
			id = object.id,
			x = x,
			y = y,
			dx = 0,
			dy = 0,
			width = object.width,
			height = object.height,
			texture = object.texture,
			scaleX = object.scaleX,
			scaleY = object.scaleY,
			onPickup = object.onPickup
		}
	end
end

function Heartbeat.drawItems()
	for i=1,#Heartbeat.items do
		Heartbeat.draw(Heartbeat.items[i])
	end
end

function Heartbeat.removeItem(item)
	for i=1,#Heartbeat.items do
		if (item == Heartbeat.items[i]) then
			table.remove(Heartbeat.items, i)
		end
	end
end

function Heartbeat.player.addInventoryItem(item)
	if (#Heartbeat.player.inventory == 0) then
		Heartbeat.player.inventory[#Heartbeat.player.inventory+1] = {id = item.id, count = 1}
		return
	end
	local inventoryIndex = Heartbeat.player.hasInventoryItem(item)
	if (inventoryIndex ~= -1) then
		Heartbeat.player.inventory[inventoryIndex].count = Heartbeat.player.inventory[inventoryIndex].count + 1
	else
		Heartbeat.player.inventory[#Heartbeat.player.inventory+1].id = item.id
	end
end

function Heartbeat.player.removeInventoryItem(item)
	local inventoryIndex = Heartbeat.player.hasInventoryItem(item)
	if (inventoryIndex ~= -1) then
		table.remove(Heartbeat.player.inventory, inventoryIndex)
	else
		print("Heartbeat Error: Player has no item of id '" .. item.id .."'")
	end
end

function Heartbeat.player.hasInventoryItem(item)
	for i=1,#Heartbeat.player.inventory do
		if (Heartbeat.player.inventory[i].id == item.id) then
			return i
		else
			return -1
		end
	end
end

function Heartbeat.player.updateHealth(value)
	if (Heartbeat.player.cooldownFrames <= 0 and not Heartbeat.dialog.isOpen) then
		if (value <= 0) then
			Heartbeat.player.killPlayer()
		end
		Heartbeat.player.health = value
		Heartbeat.player.cooldownFrames = 30
	end
end

function Heartbeat.player.killPlayer()
	print("You died, try again.")
	--love.event.quit()
	if (Player.onDeath ~= nil) then
		Player.onDeath()
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

function Heartbeat.lookupItem(id)
	for i=1,#Heartbeat.itemsList do
		if (id == Heartbeat.itemsList[i].id) then
			return Heartbeat.itemsList[i]
		end
	end
end

function Heartbeat.dialog.openDialog(dialog, afterFunc)
	if (afterFunc ~= nil) then
		Heartbeat.dialog.afterFunc = afterFunc
	end
	if (not Heartbeat.dialog.isOpen) then
		-- Load the speech file and split it
		local rawDialog = love.filesystem.read("dialog/" .. dialog .. ".txt")
		Heartbeat.dialog.dialogLines = split(rawDialog, "\n")
		Heartbeat.dialog.dialogIndex = 0
		Heartbeat.dialog.printedLines = {}
		Heartbeat.dialog.isOpen = true
		Heartbeat.dialog.nextLine()
	else
		Heartbeat.dialog.nextLine()
	end
end

function Heartbeat.dialog.nextLine()
	Heartbeat.dialog.currentLine = Heartbeat.dialog.dialogLines[Heartbeat.dialog.dialogIndex+1]
	Heartbeat.dialog.dialogCharacter = 0
	Heartbeat.dialog.printedLines = {}
	Heartbeat.dialog.dialogIndex = Heartbeat.dialog.dialogIndex + 1
	-- Out of bounds check
	if (Heartbeat.dialog.currentLine == nil or Heartbeat.dialog.currentLine == "") then
		Heartbeat.dialog.isOpen = false
		if (Heartbeat.dialog.afterFunc ~= nil) then
			Heartbeat.dialog.afterFunc()
		end
		return
	end

	-- Removing newlines
	local strippedString = ""
	for i=1,string.len(Heartbeat.dialog.currentLine) do
		if (string.sub(Heartbeat.dialog.currentLine, i, i) ~= "\n") then
			strippedString = strippedString .. string.sub(Heartbeat.dialog.currentLine, i, i)
		end
	end
	Heartbeat.dialog.currentLine = strippedString

	if (string.sub(Heartbeat.dialog.currentLine, 1, 1) == "[") then
		for i=1,#Heartbeat.dialog.speakers do
			if (Heartbeat.dialog.currentLine == "[" .. Heartbeat.dialog.speakers[i] .. "]") then
				Heartbeat.dialog.speaker = Heartbeat.dialog.speakers[i]
				Heartbeat.dialog.nextLine()
				-- Add portrait later
			end
		end
	end
end

function Heartbeat.dialog.drawDialog()
	-- Drawing background
	love.graphics.setColor(0, 0, .5, .8)
	love.graphics.rectangle("fill", 0, windowHeight - 150, windowWidth, 150)
	love.graphics.rectangle("fill", 0, windowHeight - 180, 100, 30)
	-- Drawing outline
	love.graphics.setColor(0, 0, 1, .8)
	love.graphics.rectangle("line", 0, windowHeight - 150, windowWidth, 150)
	love.graphics.rectangle("line", 0, windowHeight - 180, 100, 30)
	-- Drawing speaker
	if (Heartbeat.redText == nil) then
		love.graphics.setColor(1, 1, 1, 1)
	else
		love.graphics.setColor(1, 0, 0, 1)
	end
	love.graphics.print(Heartbeat.dialog.speaker, Heartbeat.dialog.font, 0, windowHeight - 180)
	-- Creating text lines
	local firstLine = string.sub(Heartbeat.dialog.currentLine, 0, Heartbeat.dialog.dialogCharacter)
	local previousLength = 0
	if (Heartbeat.dialog.printedLines[#Heartbeat.dialog.printedLines] ~= nil) then
		for i=1,#Heartbeat.dialog.printedLines do
			previousLength = previousLength + string.len(Heartbeat.dialog.printedLines[i])
		end
	end
	if (Heartbeat.dialog.font:getWidth(string.sub(Heartbeat.dialog.currentLine, previousLength, previousLength + Heartbeat.dialog.dialogCharacter)) > windowWidth - 200) then
		Heartbeat.dialog.printedLines[#Heartbeat.dialog.printedLines+1] = string.sub(Heartbeat.dialog.currentLine, previousLength + 1, previousLength + Heartbeat.dialog.dialogCharacter)
		Heartbeat.dialog.dialogCharacter = 0
	else
		Heartbeat.dialog.dialogCharacter = Heartbeat.dialog.dialogCharacter + 1
	end
	-- Print all lines
	for i=1,#Heartbeat.dialog.printedLines do
		if (i == #Heartbeat.dialog.printedLines) then
			love.graphics.print(string.sub(Heartbeat.dialog.currentLine, previousLength + 1, previousLength + Heartbeat.dialog.dialogCharacter), Heartbeat.dialog.font, 100, windowHeight - 150 + (i*30))
		end
		-- Print the in-progress line
		love.graphics.print(Heartbeat.dialog.printedLines[i], Heartbeat.dialog.font, 100, windowHeight - 150 + ((i-1)*30))
	end
	-- Fallback for if there's only one line
	if (#Heartbeat.dialog.printedLines == 0) then
		love.graphics.print(firstLine, Heartbeat.dialog.font, 100, windowHeight - 150)
	end
end

function Heartbeat.editor.drawEditor()
	local currentObject
	Heartbeat.debugLine = "\n\n\n"
	if (Heartbeat.editor.isActive) then
		if (Heartbeat.editor.mode == "tile") then
			Heartbeat.debugLine = Heartbeat.debugLine .. "Current Tile: " .. Heartbeat.tilesList[Heartbeat.editor.currentTile].id .. "\n"
			currentObject = Heartbeat.lookupTile(Heartbeat.tilesList[Heartbeat.editor.currentTile].id)
		elseif (Heartbeat.editor.mode == "entity") then
			Heartbeat.debugLine = Heartbeat.debugLine .. "Current Entity: " .. Heartbeat.entitiesList[Heartbeat.editor.currentEntity].id .. "\n"
			currentObject = Heartbeat.lookupEntity(Heartbeat.entitiesList[Heartbeat.editor.currentEntity].id)
		elseif (Heartbeat.editor.mode == "item") then
			Heartbeat.debugLine = Heartbeat.debugLine .. "Current Item: " .. Heartbeat.itemsList[Heartbeat.editor.currentItem].id .. "\n"
			currentObject = Heartbeat.lookupItem(Heartbeat.itemsList[Heartbeat.editor.currentItem].id)
		end
		Heartbeat.debugLine = Heartbeat.debugLine .. "Mouse Position: " .. love.mouse.getX() + Camera.x .. " " .. love.mouse.getY() + Camera.y .. "\n"
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
		local objectPreview = {
			height = currentObject.height,
			width = currentObject.width,
			texture = currentObject.texture
		}
		if (Heartbeat.editor.mode == "tile") then
			objectPreview.x = math.floor(love.mouse.getX() / 25) * 25
			objectPreview.y = math.floor(love.mouse.getY() / 25) * 25
		else
			objectPreview.x = love.mouse.getX()
			objectPreview.y = love.mouse.getY()
		end

		if (objectPreview.texture ~= nil) then
			Heartbeat.draw(objectPreview)
		else
			love.graphics.rectangle("fill", objectPreview.x, objectPreview.y, objectPreview.width, objectPreview.height)
		end
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
			local tileInfo = Heartbeat.tilesList[Heartbeat.editor.currentTile]
			Heartbeat.newTile(tileInfo, snapx, snapy)
		end
		if (Heartbeat.editor.mode == "entity") then
			local entityInfo = Heartbeat.entitiesList[Heartbeat.editor.currentEntity]
			Heartbeat.newEntity(entityInfo, love.mouse.getX() + Camera.x, love.mouse.getY() + Camera.y)
		end
		if (Heartbeat.editor.mode == "item") then
			local itemInfo = Heartbeat.itemsList[Heartbeat.editor.currentItem]
			Heartbeat.newItem(itemInfo, love.mouse.getX() + Camera.x, love.mouse.getY() + Camera.y)
		end
	end
	-- Handle right mouse click, remove tile
	if (key == 2) then
		if (Heartbeat.editor.mode == "tile") then
			for i=1,#Heartbeat.tiles do
				local snapx = math.floor((love.mouse.getX() + Camera.x) / 25) * 25
				local snapy = math.floor((love.mouse.getY() + Camera.y) / 25) * 25
				if (Heartbeat.tiles[i].x == snapx and Heartbeat.tiles[i].y == snapy) then
					table.remove(Heartbeat.tiles, i)
					--Level.tileCount = Level.tileCount - 1
					break
				end
			end
		end
		if (Heartbeat.editor.mode == "entity") then
			local mouseHitbox = {
				x = love.mouse.getX() + Camera.x,
				y = love.mouse.getY() + Camera.y,
				width = 1,
				height = 1,
			}
			for i=1,#Heartbeat.entities do
				if (Heartbeat.checkEntityCollision(mouseHitbox, Heartbeat.entities[i])) then
					table.remove(Heartbeat.entities, i)
					break
				end
			end
		end
		if (Heartbeat.editor.mode == "item") then
			local mouseHitbox = {
				x = love.mouse.getX() + Camera.x,
				y = love.mouse.getY() + Camera.y,
				width = 1,
				height = 1,
			}
			for i=1,#Heartbeat.items do
				if (Heartbeat.checkEntityCollision(mouseHitbox, Heartbeat.items[i])) then
					table.remove(Heartbeat.items, i)
					break
				end
			end
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
	if (key == "left") then
		if (Heartbeat.editor.mode == "tile" and Heartbeat.editor.currentTile > 1) then
			Heartbeat.editor.currentTile = Heartbeat.editor.currentTile -1
		end
		if (Heartbeat.editor.mode == "entity" and Heartbeat.editor.currentEntity > 1) then
			Heartbeat.editor.currentEntity = Heartbeat.editor.currentEntity -1
		end
		if (Heartbeat.editor.mode == "item" and Heartbeat.editor.currentItem > 1) then
			Heartbeat.editor.currentItem = Heartbeat.editor.currentItem - 1
		end
	end
	if (key == "right") then
		if (Heartbeat.editor.mode == "tile" and Heartbeat.editor.currentTile < #Heartbeat.tilesList) then
			Heartbeat.editor.currentTile = Heartbeat.editor.currentTile + 1
		end
		if (Heartbeat.editor.mode == "entity" and Heartbeat.editor.currentEntity < #Heartbeat.entitiesList) then
			Heartbeat.editor.currentEntity = Heartbeat.editor.currentEntity + 1
		end
		if (Heartbeat.editor.mode == "item" and Heartbeat.editor.currentItem < #Heartbeat.itemsList) then
			Heartbeat.editor.currentItem = Heartbeat.editor.currentItem + 1
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
			if (args[2] == nil or args[2] == "") then
				print("Error: No level name defined.\n Usage: :w <filename>")
				return
			end
			Heartbeat.editor.saveLevel(args[2])
		end
	-- :o <filename> (reads level from file)
	elseif (Heartbeat.editor.commandModeLine:sub(1, 1) == "o") then
		if (Heartbeat.editor.commandModeLine:len() > 2) then
			Heartbeat.clear()
			local args = split(Heartbeat.editor.commandModeLine, " ")
			Heartbeat.editor.readLevel(args[2])
		end
	-- :set <dimension> <value> (sets level height/width)
	elseif (Heartbeat.editor.commandModeLine:sub(1, 3) == "set") then
		local args = split(Heartbeat.editor.commandModeLine, " ")
		if (args[2] == "height") then
			Heartbeat.levelHeight = tonumber(args[3])
			print("Level height set to " .. args[3])
		elseif (args[2] == "width") then
			Heartbeat.levelWidth = tonumber(args[3])
			print("Level width set to " .. args[3])
		elseif (args[2] == "x") then
			Heartbeat.player.x = tonumber(args[3])
			print("Player x set to " .. args[3])
		elseif (args[2] == "y") then
			Heartbeat.player.y = tonumber(args[3])
			print("Player y set to " .. args[3])
		else
			print("Error: Invalid arguments.\nUsage: set <variable> <value>")
		end
	-- :room <destinationroom> <doorX> <doorY> <newroomX> <newroomY> (Creates a new door in a level)
	elseif (Heartbeat.editor.commandModeLine:sub(1, 4) == "room") then
		local args = split(Heartbeat.editor.commandModeLine, " ")
		if (args[6] == nil) then
			print("Usage: :room <destination> <doorX> <doorY> <newroomX> <newroomY>")
		end
		Heartbeat.rooms[#Heartbeat.rooms+1] = {
			location = args[2],
			x = tonumber(args[3]),
			y = tonumber(args[4]),
			newX = tonumber(args[5]),
			newY = tonumber(args[6])
		}
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
	-- Write the items to the file
	love.filesystem.append(levelName, "ITEMS\n")
	for i=1,#Heartbeat.items do
		love.filesystem.append(levelName, Heartbeat.items[i].x .. " " .. Heartbeat.items[i].y .. " " .. Heartbeat.items[i].id .. "\n")
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
	local k = 0 -- For entity loop
	local l = 0 -- For item loop

	-- Load the doors
	for i=i,#levelLines do
		if (levelLines[i] == "TILES") then
			j = i+1 -- To skip the TILES line
			break
		end
		levelLineData = split(levelLines[i], " ")
		Heartbeat.rooms[#Heartbeat.rooms+1] = {x = tonumber(levelLineData[1]), y = tonumber(levelLineData[2]), location = levelLineData[3], newX = tonumber(levelLineData[4]), newY = tonumber(levelLineData[5])}
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
			height = tile.height,
			texture = tile.texture,
			scaleX = tile.scaleX,
			scaleY = tile.scaleY,
			offsetX = tile.offsetX,
			offsetY = tile.offsetY,
			isSolid = tile.isSolid,
			isPlatform = tile.isPlatform,
			isSlope = tile.isSlope
		}
		-- Exceptions used to go here
		Heartbeat.newTile(tileData, tonumber(levelLineData[1]), tonumber(levelLineData[2]))
	end

	-- Load the entities
	for k=k,#levelLines do -- -1 to avoid EOF
		if (levelLines[k] == "ITEMS") then
			l = k+1
			break
		end
		levelLineData = split(levelLines[k], " ")
		local entity = Heartbeat.lookupEntity(levelLineData[3])
		local entityData = {
			id = entity.id,
			texture = entity.texture,
			height = entity.height,
			width = entity.width,
			health = entity.health,
			attack = entity.attack,
			draw = entity.draw,
			behaivor = entity.behaivor,
			onDeath = entity.onDeath,
			isEnemy = entity.isEnemy,
			onCollision = entity.onCollision,
			moveLeft = entity.moveleft,
			opacity = entity.opacity,
			movementFrames = entity.movementFrames
		}
		if (not (levelName == "cave10" and Player.flags.hasKilledFrog)) then
			Heartbeat.newEntity(entityData, tonumber(levelLineData[1]), tonumber(levelLineData[2]))
		end
	end
	-- Load the items
	for l=l,#levelLines-1 do
		levelLineData = split(levelLines[l], " ")
		local item = Heartbeat.lookupItem(levelLineData[3])
		local itemData = {
			id = item.id,
			height = item.height,
			width = item.width,
			onPickup = item.onPickup,
			texture = item.texture,
			scaleX = item.scaleX,
			scaleY = item.scaleY,
			draw = item.draw
		}

		if (
			not (levelName == "bunker5" and Player.flags.hasFirstMatter) and
			not (levelName == "bunker6" and Player.flags.hasFirstHealth) and
			not (levelName == "cave3" and Player.flags.hasSecondMatter) and
			not (levelName == "cave4" and Player.flags.hasSecondHealth) and
			not (levelName == "cave6" and Player.flags.hasThirdMatter) and
			not (levelName == "spider3" and Player.flags.hasThirdHealth) and
			not (levelName == "spider7" and Player.flags.hasFourthMatter)
		) then
			Heartbeat.newItem(itemData, tonumber(levelLineData[1]), tonumber(levelLineData[2]))
		end
	end

	Heartbeat.levelName = levelName
	print("Loaded '" .. levelName .. "' successfully.")
end

-- clear: Clears all the entities and tiles
function Heartbeat.clear()
	Heartbeat.tiles = {}
	Heartbeat.entities = {}
	Heartbeat.items = {}
	Heartbeat.rooms = {}
end

function Heartbeat.checkRooms()
	for i=1,#Heartbeat.rooms do
		if (Heartbeat.rooms[i] == nil) then return end -- Room changing duct tape
		if ((Heartbeat.player.x >= Heartbeat.rooms[i].x and Heartbeat.player.x <= Heartbeat.rooms[i].x + 25) and Heartbeat.player.y + Heartbeat.player.width >= Heartbeat.rooms[i].y and Heartbeat.player.y <= Heartbeat.rooms[i].y + 25) then
			Heartbeat.gotoRoom(Heartbeat.rooms[i].location, Heartbeat.rooms[i].newX, Heartbeat.rooms[i].newY)
		end
	end
end

function Heartbeat.gotoRoom(room, x, y)
	--if ((string.sub(room, 1, 1) == "s" or string.sub(room, 1, 1) == "b" or Heartbeat.levelName == "end") and Sounds.currentTheme ~= Sounds.bunker_theme) then
		--love.audio.stop()
		--love.audio.play(Sounds.bunker_theme)
		--Sounds.currentTheme = Sounds.bunker_theme
	--end
	--if ((string.sub(room, 1, 1) == "c") and Sounds.currentTheme ~= Sounds.cave_theme) then
		--love.audio.stop()
		--love.audio.play(Sounds.cave_theme)
		--Sounds.currentTheme = Sounds.cave_theme
	--end
	print("Room " .. room .. " loaded.")
	Heartbeat.clear()
	Heartbeat.editor.readLevel(room)
	Heartbeat.player.x = x
	Heartbeat.player.y = y
end

-- checkCollisions: Checks the collisions of all the entities against the tiles
function Heartbeat.checkCollisions(entity)
	local attemptedX = entity.x + entity.dx
	local attemptedY = entity.y + entity.dy
	local collisionX = false
	local collisionY = false
	local collidedObject = nil
	-- TODO: Rewrite this to just use checkEntityCollision

	for i=1,#Heartbeat.tiles do
		--if (Heartbeat.tiles[i].isSolid or (not Heartbeat.tiles[i].isSlope) or (Heartbeat.tiles[i].isPlatform and ((Heartbeat.player.y + Heartbeat.player.height) <= Heartbeat.tiles[i].y))) then
		if (Heartbeat.tiles[i].isSolid or (Heartbeat.tiles[i].isPlatform and ((Heartbeat.player.y + Heartbeat.player.height) <= Heartbeat.tiles[i].y))) then
			if (entity.x < Heartbeat.tiles[i].x + Heartbeat.tiles[i].width and entity.x + entity.width > Heartbeat.tiles[i].x and attemptedY < Heartbeat.tiles[i].y + Heartbeat.tiles[i].height and attemptedY + entity.height > Heartbeat.tiles[i].y) then
				entity.dy = 0
				entity.isFalling = false
				collisionY = true
				collidedObject = Heartbeat.tiles[i]
			end
			if (attemptedX < Heartbeat.tiles[i].x + Heartbeat.tiles[i].width and attemptedX + entity.width > Heartbeat.tiles[i].x and entity.y < Heartbeat.tiles[i].y + Heartbeat.tiles[i].height and entity.y + entity.height > Heartbeat.tiles[i].y) then
				collisionX = true
				collidedObject = Heartbeat.tiles[i]
			end
		end

		-- Slope handling
		if (Heartbeat.tiles[i].isSlope and Heartbeat.checkEntityCollision(Heartbeat.tiles[i], Heartbeat.player)) then
			-- Rewrite
			--local playerX = (Heartbeat.tiles[i].x + Heartbeat.tiles[i].width) - (Heartbeat.player.x + Heartbeat.player.width * .5)
			---- Seems the 1's polarity is different for the direction
			--Heartbeat.player.y = (1 * playerX) + Heartbeat.tiles[i].y - Heartbeat.tiles[i].height
			--Heartbeat.player.dy = 0

			-- Old
			if (Heartbeat.player.dx ~= 0) then
				local leftCheck = {
					x = Heartbeat.player.x - 1,
					y = Heartbeat.player.y,
					height = Heartbeat.player.height,
					width = 1
				}
				local rightCheck = {
					x = Heartbeat.player.x + Heartbeat.player.width + 1,
					y = Heartbeat.player.y,
					height = Heartbeat.player.height,
					width = 1
				}
				if (Heartbeat.checkEntityCollision(leftCheck, Heartbeat.tiles[i])) then
					-- Right slope
					if ((Heartbeat.player.y + Heartbeat.player.height) >= (Heartbeat.tiles[i].y + (Heartbeat.tiles[i].width/2))) then
						Heartbeat.player.y = Heartbeat.tiles[i].y - Heartbeat.player.height + (Heartbeat.tiles[i].width/2)
					end
					entity.dy = Heartbeat.player.dx
				end
				if (Heartbeat.checkEntityCollision(rightCheck, Heartbeat.tiles[i])) then
					-- Left slope
					if ((Heartbeat.player.y + Heartbeat.player.height) >= (Heartbeat.tiles[i].y + (Heartbeat.tiles[i].width/2))) then
						Heartbeat.player.y = Heartbeat.tiles[i].y - Heartbeat.player.height + (Heartbeat.tiles[i].width/2)
					end
					entity.dy = -1 * Heartbeat.player.dx
				end
				entity.isFalling = false
			else
				-- If the player is falling through the stairs, set their dy to 0
				if (entity.dy > 0) then
					entity.dy = 0
				end
			end
		end
	end

	-- Applying Forces
	if (not collisionY) then
		entity.y = entity.y + entity.dy
	end
	if (not collisionX) then
		entity.x = entity.x + entity.dx
	end

	-- A very special case of corner bugs
	-- I apologize.
	if (collisionX and collisionY) then
		-- Upper left corner
		if (Heartbeat.getTile(Heartbeat.player.x - 1, Heartbeat.player.y - 1) ~= nil) then
			Heartbeat.player.x = Heartbeat.player.x + 1
		-- Upper right corner
		elseif (Heartbeat.getTile(Heartbeat.player.x + Heartbeat.player.width + 1, Heartbeat.player.y - 1) ~= nil) then
			Heartbeat.player.x = Heartbeat.player.x - 1
		-- Bottom left corner
		elseif (Heartbeat.getTile(Heartbeat.player.x - 1, Heartbeat.player.y + Heartbeat.player.height + 1) ~= nil) then
			Heartbeat.player.y = Heartbeat.player.y - 1
		-- Bottom right corner
		elseif (Heartbeat.getTile(Heartbeat.player.x + Heartbeat.player.width + 1, Heartbeat.player.y + Heartbeat.player.height + 1) ~= nil) then
			Heartbeat.player.y = Heartbeat.player.y - 1
		end
	end

	-- Return a bool if they collided
	return collidedObject
end

-- checkEntityCollisons: Compares two entities, returns true if they collide
function Heartbeat.checkEntityCollision(entity1, entity2)
	-- Quick duct tape for if entity is removed during the loop
	if (entity1 == nil or entity2 == nil) then return end
	if (Camera.convert("x", entity1.x) < Camera.convert("x", entity2.x) + entity2.width and ((Camera.convert("x", entity1.x) + entity1.width) > (Camera.convert("x", entity2.x))) and Camera.convert("y", entity1.y) < Camera.convert("y", entity2.y) + entity2.height and ((Camera.convert("y", entity1.y) + entity1.height) > (Camera.convert("y", entity2.y)))) then
		return true
	else
		return false
	end
end

function Heartbeat.getTile(x, y)
	local checker = {
		x = x,
		y = y,
		width = 1,
		height = 1
	}

	for i=1,#Heartbeat.tiles do
		if (Heartbeat.checkEntityCollision(Heartbeat.tiles[i], checker)) then
			return Heartbeat.tiles[i]
		end
	end

	return nil
end

-- setDimensions: Sets the dimensions of the level
function Heartbeat.setDimensions(width, height)
	Heartbeat.levelWidth = width
	Heartbeat.levelHeight = height
end

function Heartbeat.setBackgroundColor(red, green, blue)
	Heartbeat.backgroundRed = red
	Heartbeat.backgroundGreen = green
	Heartbeat.backgroundBlue = blue
end

-- drawBackground: Draws the background, currently supports only solid colors
function Heartbeat.drawBackground()
	if (Heartbeat.backgroundRed ~= nil) then
		love.graphics.setColor(Heartbeat.backgroundRed, Heartbeat.backgroundBlue, Heartbeat.backgroundGreen, 1)
		love.graphics.rectangle("fill", 0, 0, windowWidth, windowHeight)
	end
end

-- Heartbeat's main function
function Heartbeat.beat()
	if (not Heartbeat.editor.isActive) then
		Heartbeat.doEntities()
		Heartbeat.doPlayer()
		Heartbeat.checkRooms()
	end
	Heartbeat.drawBackground()
	Heartbeat.drawTiles()
	Heartbeat.drawEntities()
	Heartbeat.drawItems()
	Heartbeat.drawPlayer()
	Heartbeat.editor.drawEditor()
	Camera.update()
	if (Heartbeat.dialog.isOpen) then
		Heartbeat.dialog.drawDialog()
	end
end

