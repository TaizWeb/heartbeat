require("lib/heartbeat")

function love.load()
	windowWidth = love.graphics.getWidth()
	windowHeight = love.graphics.getHeight()
	love.window.setTitle("Heartbeat")
	love.keyboard.setKeyRepeat(true)
	love.filesystem.setIdentity("heartbeat")
	Heartbeat.createPlayer(Player, 100, 100)
	Heartbeat.newEntity(Zombie, 200, 100)
	Heartbeat.newTile(Stone, 25, 25)
	Heartbeat.newItem(Brick, 100, 200)
	Heartbeat.editor.isActive = true
	-- Perhaps add a thing to heartbeat to catalog? Maybe not because editor
	Heartbeat.tilesList = {Stone, Platform}
	Heartbeat.entitiesList = {Zombie}
	Heartbeat.itemsList = {Brick}
	Heartbeat.dialog.speakers = {"MM", "MC"}
	Heartbeat.levelWidth = windowWidth
	Heartbeat.levelHeight = windowHeight
end

Editor = {}
Editor.isActive = false

Player = {
	x = 100,
	y = 100,
	height = 50,
	width = 25 
}

Zombie = {
	id = "zombie",
	height = 50,
	width = 25,
	health = 20,
	attack = 1
}

Brick = {
	id = "brick",
	height = 10,
	width = 10
}

function Brick.onPickup(this)
	Heartbeat.removeItem(this)
	Heartbeat.player.addInventoryItem(this)
	for i=1,#Heartbeat.player.inventory do
		print(Heartbeat.player.inventory[i].id .. " " .. Heartbeat.player.inventory[i].count)
	end
	print("Picked up brick!")
end

function Zombie.behaivor(this)
	this.x = this.x + 50
end

Stone = {
	id = "stone",
	width = 25,
	height = 25,
	isSolid = true
}

Platform = {
	id = "platform",
	width = 25,
	height = 10,
	isPlatform = true
}

function love.keypressed(key, scancode, isrepeat)
	if (key == "e" and not Heartbeat.editor.commandMode) then
		Heartbeat.editor.isActive = not Heartbeat.editor.isActive
	end
	if (key == "a") then
		Heartbeat.dialog.openDialog("template")
	end
	if (Heartbeat.editor.isActive) then
		Heartbeat.editor.handleInput(key)
	end
	if (key == "z") then
		Heartbeat.jump(Heartbeat.player)
	end
end

function love.mousepressed(x, y, button, istouch, presses)
	if (Heartbeat.editor.isActive) then
		Heartbeat.editor.handleInput(button)
	end
end

function love.update(dt)
	if (love.keyboard.isDown("left")) then
		Heartbeat.player.dx = -5
		Heartbeat.player.isCrouched = false
		Heartbeat.player.isUp = false
	elseif (love.keyboard.isDown("right")) then
		Heartbeat.player.dx = 5
		Heartbeat.player.isCrouched = false
		Heartbeat.player.isUp = false
	else
		Heartbeat.player.dx = 0
	end
end

function love.draw()
	Heartbeat.beat()
end

