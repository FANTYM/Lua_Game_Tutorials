keysTable = {}
lastKeyPress = 0
keyRepeatRate = 0.1

timePool = 0
timeStep = 1 / 30
gameTime = 0

gameObjects = {}
nextObjectIndex = 0

gameCells = {}
cellSize = 128

objectSpeed = 96
cameraSpeed = 96
playerSpeed = 192

playerXScale = 1

-- Here we add a variable to state how big(wide/long) we want the level
levelLength = 100
-- We'll need to set a boundry for the height, a maximum height
maxHeight = 10
-- there are lots of ways to generate a level, i'm going to use a goal height
-- variable, and raise and lower the ground by one each step till it hits that goal
goalHeight = math.floor(math.random() * maxHeight)
-- We also need to track what the current height we are at.
currentHeight = 0

function love.load()
	
	gameCamera = newVector(0,0)
	
	screenOffset = newVector(love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.5)
	
	-- Gravity feel's a little floaty, let's increase it
	gravity = newVector(0,400)
	
	for x = -(levelLength * 0.5), (levelLength * 0.5) do
		
		-- here we check if our currentHeight has reached the goal height
		-- if it has we need to pick a new goalHeight otherwise we will increase
		-- or decrease the current height by one
		if goalHeight == currentHeight then
			goalHeight = math.floor(math.random() * maxHeight)
		else
			-- we need to check if we are moving up or down
			if goalHeight > currentHeight then
				currentHeight = currentHeight + 1
			else
				currentHeight = currentHeight - 1
			end
		end
		
		newObject("top_middle.png",
		          newVector(x * 64, currentHeight * 64),
				  newVector(0,0),
				  false,
				  -1)
				  
		newObject("middle.png",
		          newVector(x * 64, (currentHeight + 1) * 64),
				  newVector(0,0),
				  false,
				  -1)
		
	end
	
	-- we'll also set the players staring place to the farthest
	-- left of the level and because we know the starting value is
	-- always 1 or 0, (starts at 0 and get's one added or doesn't change)
	player = newObject("player.png",
					   newVector(-(levelLength * 0.5) * 64, -97),
					   newVector(0,0),
					   true,
					   -1)

end

function love.draw()

	love.graphics.clear( 0, 64, 255, 255 )
	
	local cellsWide = math.ceil((love.graphics.getWidth() / cellSize) * 0.5) 
	local cellsTall = math.ceil((love.graphics.getHeight() / cellSize) * 0.5) 
	local invertedCamera = newVector(gameCamera.x * -1, gameCamera.y * -1)
	local cameraCell = getCellFromPos(invertedCamera)
	local drawnObjects = {}
	local drawnCount = 0

	for x = -cellsWide, cellsWide do
		for y = -cellsTall, cellsTall do

			validateCell(newVector(cameraCell.x + x, cameraCell.y + y))

			for key, value in pairs(gameCells[cameraCell.x + x][cameraCell.y + y]) do

				if not drawnObjects[key] then
					drawnCount = drawnCount + 1

					drawnObjects[key] = true
					
					local objMin = getMin(value)
					-- after discovering another bug, we'll be moving the object offset
					-- to center it on it's position to the draw call
					if value.id == player.id then
						love.graphics.draw( value.image, 
											screenOffset.x + gameCamera.x + value.pos.x, 
											screenOffset.y + gameCamera.y + value.pos.y,
											0,
											playerXScale,
											1,
											value.width * 0.5, 
											value.height * 0.5) 
					else
						love.graphics.draw( value.image, 
											screenOffset.x + gameCamera.x + value.pos.x, 
											screenOffset.y + gameCamera.y + value.pos.y,
											0,
											1,
											1,
											value.width * 0.5, 
											value.height * 0.5)
					end
				end
			
			end

		
		end
	end
		
end

function love.update(deltaTime)
   
	timePool = timePool + deltaTime

	while (timePool >= timeStep) do
		
		gameTime = gameTime + timeStep
		timePool = timePool - timeStep
		
		gameCells = {}
		
		for key, value in pairs(gameObjects) do
			
			if gameTime > (value.created + value.TTL) and 
				not (value.TTL == -1) then
				
				gameObjects[key] = nil
				
			else
				if value.canMove then

					value.pos.x = value.pos.x + (value.vel.x * timeStep)
					value.pos.y = value.pos.y + (value.vel.y * timeStep)

					value.vel.x = value.vel.x + (gravity.x * timeStep)
					value.vel.y = value.vel.y + (gravity.y * timeStep)

				end
				
				placeInCells(value)				

				checkForCollisions(value)
				
			end
		end
		
		if gameTime > lastKeyPress + keyRepeatRate then
			lastKeyPress = gameTime
			for key, value in pairs(keysTable) do
				
				if value then
					
					if key == "space" then
						
						newObject("character_frame_1.png", 
								  newVector(0, -800),
								  newVector(-objectSpeed + (math.random() * (objectSpeed * 2)),0), 
								  true,
								  15)
					end
					
					if key == "up" then
						if player.onGround then
							player.pos.y = player.pos.y - (gravity.y * timeStep)
							player.onGround = false
							-- our jumps seem a bit high, let's apply less gravity
							player.vel.y = player.vel.y + -(gravity.y * 0.625)
						end
					end
					
				end
			
			end
		end
		
		if keysTable["left"] then
			player.vel.x = player.vel.x - (playerSpeed * timeStep)
			playerXScale = -1
		end
		
		if keysTable["right"] then
			player.vel.x = player.vel.x + (playerSpeed * timeStep)
			playerXScale = 1
		end
		
		gameCamera = newVector(player.pos.x * -1, player.pos.y * -1)
	end
	
end

function love.keypressed( key )
   
   keysTable[key] = true
   print(key)

end

function love.keyreleased( key )
	
	keysTable[key] = false

end

function newObject(imageName, position, velocity, objCanMove, timeToLive)
	
	local newObj = {}
	newObj.id = nextObjectIndex
	newObj.canMove = objCanMove
	newObj.created = gameTime
	newObj.onGround = false
	newObj.TTL = timeToLive
	newObj.image = love.graphics.newImage(imageName)
	newObj.pos = position
	newObj.vel = velocity
	newObj.width = newObj.image:getWidth()
	newObj.height = newObj.image:getHeight()
	
	gameObjects[nextObjectIndex] = newObj
	
	nextObjectIndex = nextObjectIndex + 1
	
	return newObj
	
end

function validateCell(cellPos)

	if not gameCells[cellPos.x] then
		gameCells[cellPos.x] = {}
	end
	
	if not gameCells[cellPos.x][cellPos.y] then
		gameCells[cellPos.x][cellPos.y] = {}
	end

end

function newVector(xPos, yPos)
	
	local newVectorTable = {}
	newVectorTable.x = xPos
	newVectorTable.y = yPos
	
	return newVectorTable

end

function getMin(obj)
	
	local objMin = newVector(0,0)
	objMin.x = obj.pos.x - (obj.width * 0.5)
	objMin.y = obj.pos.y - (obj.height * 0.5)
	
	return objMin
	
end

function getMax(obj)
	
	local objMax = newVector(0,0)
	objMax.x = obj.pos.x + (obj.width * 0.5)
	objMax.y = obj.pos.y + (obj.height * 0.5)
	
	return objMax
	
end

function getCellFromPos(pos)

	return newVector(math.ceil(pos.x / cellSize), math.ceil(pos.y / cellSize))

end

function getCellList(obj)
	
	local objMin = getMin(obj)
	local objMax = getMax(obj)
	local cellList = {}
	
	cellList["tl"] = newVector(math.ceil(objMin.x / cellSize), math.ceil(objMin.y / cellSize))
	cellList["br"] = newVector(math.ceil(objMax.x / cellSize), math.ceil(objMax.y / cellSize))
	cellList["tr"] = newVector(math.ceil(objMax.x / cellSize), math.ceil(objMin.y / cellSize))
	cellList["bl"] = newVector(math.ceil(objMin.x / cellSize), math.ceil(objMax.y / cellSize))
	
	if vecEqual(cellList["tl"], cellList["br"]) or
	   vecEqual(cellList["tl"], cellList["tr"]) or	
	   vecEqual(cellList["tl"], cellList["bl"]) then
		cellList["tl"] = nil
	end
	if vecEqual(cellList["br"], cellList["tr"]) or	
	   vecEqual(cellList["br"], cellList["bl"]) then
		cellList["br"] = nil
	end
	if vecEqual(cellList["tr"], cellList["bl"]) then
		cellList["tr"] = nil
	end
	   
	return cellList

end

function vecEqual(vecOne, vecTwo)

	if not vecOne then return false end
	if not vecTwo then return false end
	
	if vecOne.x == vecTwo.x then
		if vecOne.y == vecTwo.y then

			return true
		end
	end
	
	return false
	
end

function placeInCells(obj)

	local cellList = getCellList(obj)
	
	for key, value in pairs(cellList) do
	
		validateCell(value)
		
		gameCells[value.x][value.y][obj.id] = obj
		
	end
	
end

function checkForCollisions(obj)

	local cellList = getCellList(obj)
	
	local objHalfWidth = obj.width * 0.5
	local objHalfHeight = obj.height * 0.5
	
	for key, value in pairs(cellList) do
		for k, objTwo in pairs(gameCells[value.x][value.y]) do
			if not (obj.id == objTwo.id) and
			        obj.canMove then
					
				local objTwoHalfWidth = objTwo.width * 0.5
				local objTwoHalfHeight = objTwo.height * 0.5
				local xDist = math.abs(obj.pos.x - objTwo.pos.x) 
				local yDist = math.abs(obj.pos.y - objTwo.pos.y) 
				
				if ((objHalfWidth + objTwoHalfWidth) >= xDist) and
				   ((objHalfHeight + objTwoHalfHeight) >= yDist) then
				   
				   local widthOverlap = ((objHalfWidth + objTwoHalfWidth) - xDist)
				   local heightOverlap = ((objHalfHeight + objTwoHalfHeight) - yDist)
				   
					if (widthOverlap < heightOverlap) then
						
						if obj.pos.x > objTwo.pos.x then
							obj.pos.x = obj.pos.x + widthOverlap
						else
							obj.pos.x = obj.pos.x - widthOverlap
						end
	
						if objTwo.canMove then
							objTwo.vel.x = objTwo.vel.x + (obj.vel.x * 0.5)
							obj.vel.x = obj.vel.x * -0.5
						else
							obj.vel.x = (-gravity.x * timeStep)
						end
												
					else
						
						if obj.pos.y > objTwo.pos.y then
							obj.pos.y = obj.pos.y + heightOverlap	
						else
							obj.pos.y = obj.pos.y - heightOverlap
						end
					
						if objTwo.canMove then	
							objTwo.vel.y = objTwo.vel.y + (obj.vel.y * 0.5)
							obj.vel.y = obj.vel.y * -0.5
						else
							obj.vel.y = (-gravity.y * timeStep)
							obj.onGround = true
						end											
					end
				end
			end
		end
	end
end