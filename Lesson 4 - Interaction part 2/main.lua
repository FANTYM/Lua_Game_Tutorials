keysTable = {}

timePool = 0
timeStep = 1 / 30
gameTime = 0

gameObjects = {}
nextObjectIndex = 0

-- Were adding a table to track groups of entites that are close to each other
-- this will make checking for collisions more efficeint
-- other wise we need to every object against every other object
gameCells = {}
-- This variable sets how big we want our cells, this is an intuitive number, and should
-- be adjusted till it get's good results
cellSize = 20

letterSpeed = 5

-- Now we need to use this function to initalize our gameCells
function love.load()
	
	-- Calculate the number of cells wide and tall, and round them up so we cover all areas
	-- math.ceil takes a number and rounds it up the next whole number 10.5 = 11
	local cellCountX = math.ceil(love.graphics.getWidth() / cellSize)
	local cellCountY = math.ceil(love.graphics.getHeight() / cellSize)
	local cellsPadding = 2
	
	-- we use this for statment to count up from one number to another
	-- we'll pad this so we don't error out on edge cases
	for x = -cellsPadding, cellCountX + cellsPadding do
		-- use x for the first index in the gameCells table, and make that a table
		gameCells[x] = {}
		for y = -cellsPadding, cellCountY + cellsPadding do
			-- now we do the same with the y value inside of gameCells[x]
			-- we will use this table to hold a list objects that are in that cell
			gameCells[x][y] = {}
		end
	end

end

function love.draw()

	for key, value in pairs(gameObjects) do
		-- because the default position is the upper left of the object we need to draw
		-- it at it's minimum point, which centers the object on it's pos
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
			-- here we call the function to remove the object(value) from any cells
			-- that it is currently in.
			removeFromCells(value)
			
			if gameTime > (value.created + value.TTL) then
				gameObjects[key] = nil
			else
				value.pos.x = value.pos.x + value.vel.x
				value.pos.y = value.pos.y + value.vel.y
				
				-- now we call the function to put the object in to any cells it's part of				
				placeInCells(value)				
				
				-- we will increase the accuracy of our boundry collisions by checking the
				-- objects minimum point (upper left corner) and it's maximum (botom right corner)
				-- this also puts our position in the middle of object
				-- This would be a lot to rewrite over and over, so we'll make a function to get the
				-- minimum and maximum points
				
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
				
				-- here we will check for collions between this object and any object in the
				-- cells that it's part of.
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

-- now we are going to make our objects solid, they will no longer pass through each other
-- instead they will bounce after hitting each other.
-- to do this we need them to have boundries, we will achieve this by getting the letter size
-- from a couple of internal functions, love.graphics.getFont to get the current font and
-- then the font's functions getWidth and getHeight for the actual character size
function newObject(character, position, velocity, timeToLive)

	local curFont = love.graphics.getFont()
	
	local newObj = {}
	-- We need to track the object's index so we can use it in our gameCells
	-- so we create a new entry in the object's table and assign it the nextObjectIndex
	-- which is always increasing and will not duplicate
	newObj.id = nextObjectIndex
	newObj.created = gameTime
	newObj.TTL = timeToLive
	newObj.char = character
	newObj.pos = position
	newObj.vel = velocity
	-- Since the font characters aren't all the same width, we need to tell it what character we
	-- are using
	newObj.width = curFont:getWidth(character)
	-- However the font is all certain height (including line spacing)
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

-- Function for getting minimum of an object, all we have to pass is the object
function getMin(obj)
	
	local objMin = newVector(0,0)
	objMin.x = obj.pos.x - (obj.width * 0.5)
	objMin.y = obj.pos.y - (obj.height * 0.5)
	
	return objMin
	
end

-- Function for getting minimum of an object, all we have to pass is the object
function getMax(obj)
	
	local objMax = newVector(0,0)
	objMax.x = obj.pos.x + (obj.width * 0.5)
	objMax.y = obj.pos.y + (obj.height * 0.5)
	
	return objMax
	
end

-- Function to calculate what cell/cells an object is in
function getCellList(obj)
	
	-- these variable hold the min and max values for the bounding box of the object
	local objMin = getMin(obj)
	local objMax = getMax(obj)
	-- This variable is a table to hold the cells that the four corners of the box are in
	local cellList = {}
	
	-- create a new vector for each point
	-- top left(min), bottom right(max), top right, bottom left
	-- then divide each by the cell size to get which cell it's in
	-- we round it off because we don't want decimals since we are using
	-- the cell numbers to index a table
	cellList["tl"] = newVector(math.ceil(objMin.x / cellSize), math.ceil(objMin.y / cellSize))
	cellList["br"] = newVector(math.ceil(objMax.x / cellSize), math.ceil(objMax.y / cellSize))
	cellList["tr"] = newVector(math.ceil(objMax.x / cellSize), math.ceil(objMin.y / cellSize))
	cellList["bl"] = newVector(math.ceil(objMin.x / cellSize), math.ceil(objMax.y / cellSize))
	
	-- check if the top left cell is the same as any others
	-- if it is then we drop it.
	if vecEqual(cellList["tl"], cellList["br"]) or
	   vecEqual(cellList["tl"], cellList["tr"]) or	
	   vecEqual(cellList["tl"], cellList["bl"]) then
		cellList["tl"] = nil
	end
	-- now we continue to check the remaing points to see if we can drop them too
	if vecEqual(cellList["br"], cellList["tr"]) or	
	   vecEqual(cellList["br"], cellList["bl"]) then
		cellList["br"] = nil
	end
	-- we do this to return the cell list without duplicates
	if vecEqual(cellList["tr"], cellList["bl"]) then
		cellList["tr"] = nil
	end
	   
	return cellList

end

-- This function takes two vector tables and compares them to see if they are the same
function vecEqual(vecOne, vecTwo)

	-- if either one is not a value, then they are not the same, return false
	if not vecOne then return false end
	if not vecTwo then return false end
	
	-- if the x values on one and two are the same
	-- and so are the y value then they are the same, return true
	if vecOne.x == vecTwo.x then
		if vecOne.y == vecTwo.y then

			return true
		end
	end
	
	-- otherwise they are different, return false
	return false
	
end

-- This function will remove the object from any cells it's currently in
function removeFromCells(obj)
	
	-- this variable is the list of cells this object is in
	local cellList = getCellList(obj)

	-- we run through the cell list, making sure the cell is valid( is a table)
	-- if it's not a table we fix it
	for key, value in pairs(cellList) do
		
		-- check if the x value has a table entry
		-- if not create a table at the x value
		if not gameCells[value.x] then
			gameCells[value.x] = {}
		end
		
		-- next we do the same check for the y value
		-- we don't do it all at the same time incase the x is valid and y is not
		if not gameCells[value.x][value.y] then
			gameCells[value.x][value.y] = {}
		end
		-- finally we check if the y table has an entry at the obj.id if it does
		-- we set it to nil to remove it from the cell
		if gameCells[value.x][value.y][obj.id] then
			gameCells[value.x][value.y][obj.id] = nil
		end
	end
	
end

-- this function will place an object in any cells it has a corner in 
function placeInCells(obj)

	-- We get the cell list in to a variable
	local cellList = getCellList(obj)
	
	-- we run through the cell list, making sure we have valid tables
	for key, value in pairs(cellList) do
	
		-- check the cell table for the x value
		if not gameCells[value.x] then
			gameCells[value.x] = {}
		end
		
		-- check the cell table for the y value
		if not gameCells[value.x][value.y] then
			gameCells[value.x][value.y] = {}
		end
		
		-- put the object at obj.id in the y table.
		gameCells[value.x][value.y][obj.id] = obj
		
	end
	
end

-- This function take an object and check if it's colliding with any other objects
-- in the cells that it occupies
-- for this function we are using a technique called separating axis theorem
-- which states that is you can sparate the objects at all they are not touching
-- so we check if half the width of one plus the half of the width of the other
-- is larger than the distance between the middles of the two objects
-- we also do this for the heights, if the half are greater on both the objects
-- are colliding, then we separate them using the smaller of the overlaps
function checkForCollisions(obj)

	-- We get the list of cells this object is in
	local cellList = getCellList(obj)
	
	-- Get the object's half width and half height
	local objHalfWidth = obj.width * 0.5
	local objHalfHeight = obj.height * 0.5
	
	-- we loop through the cellList
	for key, value in pairs(cellList) do
		-- for each cell we loop through the contents checking for collisions
		for k, objTwo in pairs(gameCells[value.x][value.y]) do
			-- we check if the object id is the same as the object we found
			-- if it is we do nothing, otherwise we check for the collision
			-- betweent the two objects
			if not (obj.id == objTwo.id) then
				-- We get the half width and half height of the other object
				local objTwoHalfWidth = objTwo.width * 0.5
				local objTwoHalfHeight = objTwo.height * 0.5
				-- We also need the distances between the middles of the objects
				-- on each axis
				local xDist = math.abs(obj.pos.x - objTwo.pos.x) 
				local yDist = math.abs(obj.pos.y - objTwo.pos.y) 
				
				-- Here we check if the half width added together are greater
				-- than the the x distance of the object positions 
				-- then we check if the half heights added together are greater 
				-- than the y distance of the object positions
				-- if so we have a collision and we need to resolve it.
				if ((objHalfWidth + objTwoHalfWidth) >= xDist) and
				   ((objHalfHeight + objTwoHalfHeight) >= yDist) then
				   
				   -- Here we calculate the width and height overlaps
				   -- we use these to pick which way we want to separate the objects
				   local widthOverlap = ((objHalfWidth + objTwoHalfWidth) - xDist)
				   local heightOverlap = ((objHalfHeight + objTwoHalfHeight) - yDist)
				   
				   -- Resolve collisions
				   -- in this part we use the overlap to pick our separation direction
					if (widthOverlap < heightOverlap) then
						
						-- we need to separate the objects on the x axis
						-- if the obj is on the right of the center of the
						-- second object then we push the obj to the right
						-- the amount of the over lap
						-- otherwise we move the object left 
						if obj.pos.x > objTwo.pos.x then
							obj.pos.x = obj.pos.x + widthOverlap
						else
							obj.pos.x = obj.pos.x - widthOverlap
						end
						
						-- here we add 1/4 of the x velocity of the first object to the 
						-- second, then we reverse the velocity of the object on the x axis
						-- but only at 3/4 it's former speed
						objTwo.vel.x = objTwo.vel.x + (obj.vel.x * 0.25)
						obj.vel.x = obj.vel.x * -0.75
						
						
					else
						
						-- we need to separate the objects on the y axis
						-- if the obj is below the center of the
						-- second object then we push the obj down by
						-- the amount of the over lap
						-- otherwise we move the object upwards 
						if obj.pos.y > objTwo.pos.y then
							obj.pos.y = obj.pos.y + heightOverlap	
						else
							obj.pos.y = obj.pos.y - heightOverlap
						end
					
						-- here we add 1/4 of the y velocity of the first object to the 
						-- second, then we reverse the velocity of the object on the y axis
						-- but only at 3/4 it's former speed
						objTwo.vel.y = objTwo.vel.y + (obj.vel.y * 0.25)
						obj.vel.y = obj.vel.y * -0.75
						
					end
				end
			end
		end
	end

end