require("heartbeat")

function love.load()
	windowWidth = love.graphics.getWidth()
	windowHeight = love.graphics.getHeight()
	love.window.setTitle("Heartbeat")
	love.keyboard.setKeyRepeat(true)
	--love.filesystem.setIdentity("project-proton")
	Heartbeat.createPlayer(0, 0, 25, 50)
	Heartbeat.newEntity("zombie", 100, 10, zombie, 5, 5, 50, 50)
	Heartbeat.newTile("stone", 0, 250, 25, 25)
end

function zombie(this)
	this.x = this.x + 50
end

Editor = {}
Editor.isActive = false

Player = {
	x = 100,
	y = 100,
	height = 100,
	width = 100
}

function love.keypressed(key, scancode, isrepeat)
	if (not Editor.isActive) then
		print("Game mode")
	else
		print("Pause Mode")
	end
	if (key == "return") then
		Editor.isActive = not Editor.isActive
	end
end

function love.update(dt)

end

function love.draw()
	Heartbeat.beat()
end

