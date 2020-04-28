require("camera")

Heartbeat = {
	gravity = .5,
	entities = {},
	tiles = {},
	items = {}
}

function Heartbeat.draw(object)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.rectangle("fill", Camera.convert("x", object.x), Camera.convert("y", object.y), object.width, object.height)
end

function Heartbeat.createPlayer(x, y, width, height)
	Heartbeat.player = {x = x, y = y, dx = 0, dy = 0, height = height, width = width, health = 0, attack = 0}
end

function Heartbeat.drawPlayer()
	Heartbeat.draw(Heartbeat.player)
end

function Heartbeat.doPlayer()
	Heartbeat.player.dy = Heartbeat.player.dy + Heartbeat.gravity
	Heartbeat.checkCollisions(Heartbeat.player)
end

-- Entity code
function Heartbeat.newEntity(name, health, attack, behaivor, x, y, width, height)
	Heartbeat.entities[#Heartbeat.entities+1] = {name = name, health = health, attack = attack, behaivor = behaivor, x = x, y = y, width = width, height = height, dx = 0, dy = 0}
end

function Heartbeat.drawEntities()
	for i=1,#Heartbeat.entities do
		Heartbeat.draw(Heartbeat.entities[i])
	end
end

function Heartbeat.doEntities()
	for i=1,#Heartbeat.entities do
		local entity = Heartbeat.entities[i]
		entity.behaivor(entity)
		entity.dy = entity.dy + Heartbeat.gravity
		Heartbeat.checkCollisions(entity)
	end
end

function Heartbeat.newTile(name, x, y, width, height)
	Heartbeat.tiles[#Heartbeat.tiles+1] = {name = name, x = x, y = y, width = width, height = height}
end

function Heartbeat.drawTiles()
	for i=1,#Heartbeat.tiles do
		Heartbeat.draw(Heartbeat.tiles[i])
	end
end

function Heartbeat.checkCollisions(entity)
	local attemptedX = entity.x + entity.dx
	local attemptedY = entity.y + entity.dy
	local collisionX = false
	local collisionY = false

	for i=1,#Heartbeat.tiles do
		-- Apply only to solid blocks
		--if (Tiles[Level.tiles[i].id].category == "block") then
		if (entity.x < Heartbeat.tiles[i].x + 25 and entity.x + entity.width > Heartbeat.tiles[i].x and attemptedY < Heartbeat.tiles[i].y + 25 and attemptedY + entity.height > Heartbeat.tiles[i].y) then
			entity.dy = 0
			entity.isFalling = false
			collisionY = true
		end
		if (attemptedX < Heartbeat.tiles[i].x + 25 and attemptedX + entity.width > Heartbeat.tiles[i].x and entity.y < Heartbeat.tiles[i].y + 25 and entity.y + entity.height > Heartbeat.tiles[i].y) then
			collisionX = true
		end
		--end
	end

	-- Applying Forces
	if (not collisionY) then
		entity.y = entity.y + entity.dy
	end
	if (not collisionX) then
		entity.x = entity.x + entity.dx
	end
end

-- Heartbeat's main function
function Heartbeat.beat()
	Heartbeat.drawEntities()
	Heartbeat.doEntities()
	Heartbeat.drawTiles()
	Heartbeat.drawPlayer()
	Heartbeat.doPlayer()
end

