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
	Heartbeat.editor.isActive = true
	-- Perhaps add a thing to heartbeat to catalog? Maybe not because editor
	Heartbeat.tilesList = {Stone}
end

Editor = {}
Editor.isActive = false

Player = {
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

function Zombie.behaivor(this)
	this.x = this.x + 50
end

Stone = {
	id = "stone",
	width = 25,
	height = 25
}

function love.keypressed(key, scancode, isrepeat)
	if (key == "e") then
		Heartbeat.editor.isActive = not Heartbeat.editor.isActive
	end
	if (Heartbeat.editor.isActive) then
		Heartbeat.editor.handleInput(key)
	end
end

function love.mousepressed(x, y, button, istouch, presses)
	if (Heartbeat.editor.isActive) then
		Heartbeat.editor.handleInput(button)
	end
end

function love.update(dt)

end

function love.draw()
	Heartbeat.beat()
end

