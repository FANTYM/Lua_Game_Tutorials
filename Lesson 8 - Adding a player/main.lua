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
-- Yet another speed variable, this time it controls the player speed
playerSpeed = 192

-- We are adding a variable to track the x scale of the player, this will allow us to flip the image
-- to face the direction we are moving
-- 1 faces right, because the original image does
-- -1 faces left, which is opposite of it's original state
playerXScale = 1

function love.load()
	
	gameCamera = newVector(0,0)
	
	screenOffset = newVector(love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.5)

	gravity = newVector(0,235.2)
	
	for x = -10, 10 do
		
		newObject("top_middle.png",
		          newVector(x * 64, 32),
				  newVector(0,0),
				  false,
				  -1)
		
	end
	
	-- We need to track our player object so we don't need to look it up every time
	-- that we need to do something with it.
	-- to do this we'll change the newObject function to return the object it creates
	-- instead of just putting it in the world.
	
	player = newObject("player.png",
					   newVector(0, -112),
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
					-- we add an if to look for the player, and when we draw it we need to give more arguments
					-- to the draw function to set the scale
					if value.id == player.id then
						love.graphics.draw( value.image, 
											screenOffset.x + gameCamera.x + objMin.x, 
											screenOffset.y + gameCamera.y + objMin.y,
											0, -- this is the rotation of the image we are not using right now
											playerXScale, -- this flips the image left/right
											1, -- we have to set this or it will use the x scale for both 
											player.width * 0.5 ) -- we move the origin to the middle of player
																 -- in this function call so it flips in the center
																 -- of the image
					else
						love.graphics.draw( value.image, 
											screenOffset.x + gameCamera.x + objMin.x, 
											screenOffset.y + gameCamera.y + objMin.y )
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
					
					-- found another bug, i should be apply gravity to the velocity
					-- not the position.
					--value.pos.x = value.pos.x + (gravity.x * timeStep)
					--value.pos.y = value.pos.y + (gravity.y * timeStep)
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
						-- we need to move the player up just a tiny bit, one step of gravity 
						-- should do it, otherwise the collison code stops the y movement
						if player.onGround then
							player.pos.y = player.pos.y - (gravity.y * timeStep)
							player.onGround = false
							-- to sucessfuly jump we need to give the player an upward force
							-- that is greater than gravity, since gravity is applied in fractions of
							-- a second we can jump by applying 1 second of revesed gravity
							
							player.vel.y = player.vel.y + -gravity.y
						end
						
						--gameCamera.y = gameCamera.y + (cameraSpeed * timeStep)
					end
					
				end
			
			end
		end
		
		-- We are also changing the arrow keys to move the player and not the camera
		-- we'll add to the players velocity while these keys are pressed.
		
		-- we don't want the player jumping too much so we'll move the up key to 
		-- inside the key rate limited section
		
		-- since our player can't crouch we don't need the down key
		--if keysTable["down"] then
			--gameCamera.y = gameCamera.y - (cameraSpeed * timeStep)
		--end
		
		if keysTable["left"] then
			player.vel.x = player.vel.x - (playerSpeed * timeStep)
			playerXScale = -1
			--gameCamera.x = gameCamera.x + (cameraSpeed * timeStep)
		end
		
		if keysTable["right"] then
			player.vel.x = player.vel.x + (playerSpeed * timeStep)
			playerXScale = 1
			--gameCamera.x = gameCamera.x - (cameraSpeed * timeStep)
		end
		
		-- now we set the gameCamera to the same inverted position of the player
		-- this make the camera follow the player around
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

-- We add a return statement to this function which make it pass what we tell it
-- back to the calling line else where in the program
-- We do not need to do anything with the return value if we don't want to
-- We also will add a new key to track when an object is on the ground
-- we'll use this check if a player can jump, and to see if we need to raise
-- the player to keep it from sticking to the ground.
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
							-- we set the onGround key to true here, this lets us
							-- know which objects are resting on the ground
							obj.onGround = true
						end											
					end
				end
			end
		end
	end
end