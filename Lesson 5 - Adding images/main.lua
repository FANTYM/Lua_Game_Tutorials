keysTable = {}

timePool = 0
timeStep = 1 / 30
gameTime = 0

gameObjects = {}
nextObjectIndex = 0

gameCells = {}
cellSize = 20

letterSpeed = 5

function love.load()
	
	local cellCountX = math.ceil(love.graphics.getWidth() / cellSize)
	local cellCountY = math.ceil(love.graphics.getHeight() / cellSize)
	local cellsPadding = 2
	
	for x = -cellsPadding, cellCountX + cellsPadding do
		gameCells[x] = {}
		for y = -cellsPadding, cellCountY + cellsPadding do
			gameCells[x][y] = {}
		end
	end

end

function love.draw()

	for key, value in pairs(gameObjects) do

		local objMin = getMin(value)
		
		love.graphics.setColor(255,255,255,255)
		
		love.graphics.print(value.char, objMin.x, objMin.y)
		
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
		
	end
	
end

function love.keypressed( key )
   
   keysTable[key] = true

   newObject(key, 
			 newVector(love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.5 ),
			 newVector(-letterSpeed + (math.random() * (letterSpeed * 2)), -letterSpeed + (math.random() * (letterSpeed * 2))), 
			 15)
   
end

function love.keyreleased( key )
	
	keysTable[key] = false

end

function newObject(character, position, velocity, timeToLive)

	local curFont = love.graphics.getFont()
	
	local newObj = {}
	newObj.id = nextObjectIndex
	newObj.created = gameTime
	newObj.TTL = timeToLive
	newObj.char = character
	newObj.pos = position
	newObj.vel = velocity
	newObj.width = curFont:getWidth(character)
	newObj.height = curFont:getHeight()
	
	gameObjects[nextObjectIndex] = newObj
	
	nextObjectIndex = nextObjectIndex + 1
	
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
		
		if not gameCells[value.x] then
			gameCells[value.x] = {}
		end
		
		if not gameCells[value.x][value.y] then
			gameCells[value.x][value.y] = {}
		end
		if gameCells[value.x][value.y][obj.id] then
			gameCells[value.x][value.y][obj.id] = nil
		end
	end
	
end

function placeInCells(obj)

	local cellList = getCellList(obj)
	
	for key, value in pairs(cellList) do
	
		if not gameCells[value.x] then
			gameCells[value.x] = {}
		end
		
		if not gameCells[value.x][value.y] then
			gameCells[value.x][value.y] = {}
		end
		
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