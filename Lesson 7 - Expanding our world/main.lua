keysTable = {}
lastKeyPress = 0
keyRepeatRate = 0.1

timePool = 0
timeStep = 1 / 300
gameTime = 0

gameObjects = {}
nextObjectIndex = 0

gameCells = {}
cellSize = 64

objectSpeed = 96
-- Here we add another another speed variable, this one will control camera speed
cameraSpeed = 100

function love.load()
	
	-- Now we need to add a variable for the camera in the gameCells
	-- when we change this variable it'll change what part of the world we are 
	-- looking at, we'll use this variable to offset our drawing, and limit 
	-- what we draw to the screen
	gameCamera = newVector(0,0)
	
	-- we'll also move 0,0 from the top left of the screen to the middle
	-- using this variable
	screenOffset = newVector(love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.5)

	gravity = newVector(0,235.2)
	
	for x = -10, 10 do
		
		newObject("top_middle.png",
				  -- since we are not trapped in the screen we'll change this to be
				  -- closer to the center of the world, and also not rely on the screen size
		          newVector(x * 64, 32),
				  newVector(0,0),
				  false,
				  -1)
		
	end

end

function love.draw()

	love.graphics.clear( 0, 64, 255, 255 )
	
	-- at the moment we are getting a list of all game object, on and off the screen
	-- now that we have a camera position we grab just the cells that are on screen
	-- and draw their contents.
	-- we cut cells wide and cells tall in half because we want to go both directions
	-- from our camera point (up/down) and (left/right) 
	local cellsWide = math.ceil((love.graphics.getWidth() / cellSize) * 0.5) 
	local cellsTall = math.ceil((love.graphics.getHeight() / cellSize) * 0.5) 
	-- we need to invert the camera position, because we allready inverted in in the
	-- camera movment code and now we must reverse that so it aligns with the world.
	local invertedCamera = newVector(gameCamera.x * -1, gameCamera.y * -1)
	-- Then we get what cell the camera is in.
	local cameraCell = getCellFromPos(invertedCamera)
	-- we use this to keep from drawing an object more than once if it's in 
	-- multiple cells
	local drawnObjects = {}
	local drawnCount = 0
	--for key, value in pairs(gameObjects) do
	
	-- we run through the cells from left of our camera, to right
	-- and up and down
	for x = -cellsWide, cellsWide do
		for y = -cellsTall, cellsTall do
			-- we validate the cell we are about to draw, otherwise if it's
			-- never had an object in it, it'll be null.
			validateCell(newVector(cameraCell.x + x, cameraCell.y + y))
			-- now we loop through the contents of the cell, checking if there's
			-- an entry in the drawnObjects table already, if not we draw it and add
			-- it to the drawnObjects table.
			for key, value in pairs(gameCells[cameraCell.x + x][cameraCell.y + y]) do

				if not drawnObjects[key] then
					drawnCount = drawnCount + 1

					-- set a true value to the drawnObjects table at the key, which is also the obj.id
					drawnObjects[key] = true
					
					local objMin = getMin(value)
					-- we add a few new variables to this function call to 
					-- offset the screen so 0,0 is centered, then we'll, add the game camera
					-- which offsets our view to the camera position, and finally we add the offset
					-- for our current object.
					love.graphics.draw( value.image, screenOffset.x + gameCamera.x + objMin.x, screenOffset.y + gameCamera.y + objMin.y )
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
					
					value.pos.x = value.pos.x + (gravity.x * timeStep)
					value.pos.y = value.pos.y + (gravity.y * timeStep)

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
								  -- we'll also change to creating the guys in a spot based of just world
								  -- coordinates since we are moving away from a static view of the world
								  newVector(0, -800),
								  newVector(-objectSpeed + (math.random() * (objectSpeed * 2)),0), 
								  true,
								  15)
					end
					
				end
			
			end
		end
		
		-- We check for these keys outside of the repeat rate limit to keep the movment smoot
		-- if we put it in the key rate limited if it'll be choppy.
		-- To do this we need to reference the key instead of just looping through
		-- all the keys again.
		
		-- Here we check for the arrow keys, and when they are pressed
		-- we move the camera around the world, cameraSpeed per second
		-- each key press, we divide timeStep by the keyRepeatRate to compesate
		-- for the repeat rate
		
		if keysTable["up"] then
			gameCamera.y = gameCamera.y + (cameraSpeed * timeStep)
		end
		
		if keysTable["down"] then
			gameCamera.y = gameCamera.y - (cameraSpeed * timeStep)
		end
		
		if keysTable["left"] then
			gameCamera.x = gameCamera.x + (cameraSpeed * timeStep)
		end
		
		if keysTable["right"] then
			gameCamera.x = gameCamera.x - (cameraSpeed * timeStep)
		end
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
	newObj.TTL = timeToLive
	newObj.image = love.graphics.newImage(imageName)
	newObj.pos = position
	newObj.vel = velocity
	newObj.width = newObj.image:getWidth()
	newObj.height = newObj.image:getHeight()
	
	gameObjects[nextObjectIndex] = newObj
	
	nextObjectIndex = nextObjectIndex + 1
	
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

-- We add a function to get what cell a point is in, we need this for the 
-- updated drawing function
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
						end											
					end
				end
			end
		end
	end
end