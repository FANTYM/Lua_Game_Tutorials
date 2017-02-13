keysTable = {}

timePool = 0
timeStep = 1 / 30
gameTime = 0

gameObjects = {}
nextObjectIndex = 0

gameCells = {}
cellSize = 50

-- since we are no longer using letters we should rename our variable to be more descriptive.
--letterSpeed = 5
objectSpeed = 15

function love.load()
	
	-- I'm removing this section because we don't need to initalize the cells
	-- we can just check if a cell is valid before using it, we'll create a function for this.
	
	--local cellCountX = math.ceil(love.graphics.getWidth() / cellSize)
	--local cellCountY = math.ceil(love.graphics.getHeight() / cellSize)
	--local cellsPadding = 2
	
	--for x = -cellsPadding, cellCountX + cellsPadding do
	--	gameCells[x] = {}
	--	for y = -cellsPadding, cellCountY + cellsPadding do
	--		gameCells[x][y] = {}
	--	end
	--end

end

function love.draw()

	-- Here we add a function call to clear the screen and make it blueish
	-- this is because we have an image with black parts and it'll blend in 
	-- this function take four arguments, red (0-255), blue (0-255), green(0-255),
	-- and alpha (0-255)
	love.graphics.clear( 0, 64, 255, 255 )

	for key, value in pairs(gameObjects) do

		local objMin = getMin(value)
		
		--love.graphics.setColor(255,255,255,255)
		
		-- Here we need to change what drawing function we are using,
		-- because we are not using text character any more
		-- we will use love.graphics.draw which take a drawble (an image in this case)
		-- and position, it has other options too, however we don't need them so
		-- i won't get into it now. You can read about it on the wiki too
		--love.graphics.print(value.char, objMin.x, objMin.y)
		love.graphics.draw( value.image, objMin.x, objMin.y )
		
	end
	
end

function love.update(deltaTime)
   
	timePool = timePool + deltaTime

	while (timePool >= timeStep) do
		
		gameTime = gameTime + timeStep
		timePool = timePool - timeStep

		for key, value in pairs(gameObjects) do
			removeFromCells(value)
			
			if gameTime > (value.created + value.TTL) then
				gameObjects[key] = nil
			else
				value.pos.x = value.pos.x + value.vel.x
				value.pos.y = value.pos.y + value.vel.y
				
				placeInCells(value)				

				local objMin = getMin(value)
				local objMax = getMax(value)
				
				if (objMin.y < 0) or
				   (objMax.y > love.graphics.getHeight()) then
					value.vel.y = value.vel.y * -1
				end
				
				if (objMin.x < 0) or
				   (objMax.x > love.graphics.getWidth()) then
					value.vel.x = value.vel.x * -1
				end
				
				checkForCollisions(value)
				
			end
		end
		
		-- we are no longer using the key pressed for the character, so we need
		-- another way to create our objects.
		-- This for loop checks reads all the key entries in the keysTable
		-- if they key's value is true then we will check which key it is
		-- and we will create a new object if it was space.
		-- also if we hold the space bar down it will create a new object
		-- every timestep
		for key, value in pairs(keysTable) do
			
			if value then
				
				if key == "space" then
					-- For the first argument we now give it the file name of the image we
					-- want to use.
					-- in this case it's called, character_frame_1.png , it's frame 1 because we'll
					-- animated it later
					newObject("character_frame_1.png", 
							  newVector(love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.5 ),
							  newVector(-objectSpeed + (math.random() * (objectSpeed * 2)), -objectSpeed + (math.random() * (objectSpeed * 2))), 
							  15)
				end
				
			end
		
		end
		
	end
	
end

function love.keypressed( key )
   
   keysTable[key] = true

    -- we are removing the new object function call from key pressed and palacing
    -- it in the love.update, when the space bar is pressed.
    --newObject(key, 
	--		 newVector(love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.5 ),
	--		 newVector(-letterSpeed + (math.random() * (letterSpeed * 2)), -letterSpeed + (math.random() * (letterSpeed * 2))), 
	--		 15)
   
end

function love.keyreleased( key )
	
	keysTable[key] = false

end

-- We will be changing the first variable to an image name instead of
-- a character
-- we will need to go to each place we use this function and make sure
-- we are passing the correct information to this function.
function newObject(imageName, position, velocity, timeToLive)
	
	-- we don't need this variable because we are no longer using characters
	-- so we don't need the font information
	--local curFont = love.graphics.getFont()
	
	local newObj = {}
	newObj.id = nextObjectIndex
	newObj.created = gameTime
	newObj.TTL = timeToLive
	-- Removing this key from the object, we won't be drawing characters anymore
	-- we'll start drawing images
	-- newObj.char = character
	-- Adding an image key, it gets its it's value from a function
	-- that loads the image from a file as ImageData, which has useful function.
	newObj.image = love.graphics.newImage(imageName)
	newObj.pos = position
	newObj.vel = velocity
	-- we need to change where we get the width and height from
	-- since we are not using the font information.
	-- we will use the width and height funcitons of the ImageData
	newObj.width = newObj.image:getWidth()
	newObj.height = newObj.image:getHeight()
	
	gameObjects[nextObjectIndex] = newObj
	
	nextObjectIndex = nextObjectIndex + 1
	
end

-- This function will check if the requested cell is valid, if it's not
-- it will make it a valid cell
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

function removeFromCells(obj)
	
	local cellList = getCellList(obj)

	for key, value in pairs(cellList) do
		
		validateCell(value)
		
		if gameCells[value.x][value.y][obj.id] then
			gameCells[value.x][value.y][obj.id] = nil
		end
	end
	
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
			if not (obj.id == objTwo.id) then
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
						
						objTwo.vel.x = objTwo.vel.x + (obj.vel.x * 0.25)
						obj.vel.x = obj.vel.x * -0.75
						
						
					else
						
						if obj.pos.y > objTwo.pos.y then
							obj.pos.y = obj.pos.y + heightOverlap	
						else
							obj.pos.y = obj.pos.y - heightOverlap
						end
					
						objTwo.vel.y = objTwo.vel.y + (obj.vel.y * 0.25)
						obj.vel.y = obj.vel.y * -0.75
						
					end
				end
			end
		end
	end

end