require("lib/camera")
require("lib/split")

Heartbeat = {
	gravity = .5,
	editor = {
		isActive = false,
		currentTile = "stone"
	},
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
function Heartbeat.createPlayer(object)
	Heartbeat.player = {
		x = object.x,
		y = object.y,
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
function Heartbeat.newEntity(object)
	Heartbeat.entities[#Heartbeat.entities+1] = {
		id = object.id,
		x = object.x,
		y = object.y,
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
	Heartbeat.tiles[#Heartbeat.tiles+1] = {
		id = object.id,
		x = x,
		y = y,
		width = object.width,
		height = object.height,
		texture = object.texture
	}
end

-- drawTiles: Draws the tiles to the screen
function Heartbeat.drawTiles()
	for i=1,#Heartbeat.tiles do
		Heartbeat.draw(Heartbeat.tiles[i])
	end
end

function Heartbeat.lookupTile(id)
	for i=1,#Heartbeat.tilesList do
		print(Heartbeat.tilesList[i].id)
		if (id == Heartbeat.tilesList[i].id) then
			print("Found somethin")
			return Heartbeat.tilesList[i]
		end
	end
end

function Heartbeat.drawEditor()
	if (Heartbeat.editor.isActive) then
		love.graphics.setColor(1, 1, 1, .5)
		love.graphics.rectangle("fill", math.floor(love.mouse.getX() / 25) * 25, math.floor(love.mouse.getY() / 25) * 25, 25, 25)
	end
end

function Heartbeat.editor.handleInput(key)
	if (key ~= "e") then
		print(key)
	end
	if (key == 1) then
		local snapx = math.floor((love.mouse.getX() + Camera.x) / 25) * 25
		local snapy = math.floor((love.mouse.getY() + Camera.y) / 25) * 25
		local tileInfo = Heartbeat.lookupTile(Heartbeat.editor.currentTile)
		Heartbeat.newTile(tileInfo, snapx, snapy)
	end
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
	Heartbeat.drawEditor()
end

