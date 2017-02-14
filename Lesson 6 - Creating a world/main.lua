keysTable = {}

-- should have put this in sooner, we don't want our keys repeating super fast
-- so we'll use these variables to control how fast the repeat happens
lastKeyPress = 0
-- we'll set it to repeat every 10th of a seccond or 10 times a second
keyRepeatRate = 0.1

timePool = 0
timeStep = 1 / 30
gameTime = 0

gameObjects = {}
nextObjectIndex = 0

gameCells = {}
cellSize = 100

-- Because we are changing from pixels per frame, to pixels per second, we need to 
-- increase this value, our monster guy is 48x48 pixels, so let's make it move
-- twice it's full size per second, or 96 pixels per second
objectSpeed = 96


function love.load()
	
	-- Now we're going to add a new variable, gravity
	-- this will give us a sense of being somewhere instead of just floating around
	-- the screen goes from 0,0 to width, height (600,600), which means if we want
	-- things to fall down we need to increase their y value, so gravity should being
	-- (0, gravityStrength), real gravity is 9.8 meters per second, in our would it's
	-- as strong or as weak as we like, to get this looking right we need to give our world
	-- some scale, let's say our guy is 2 meters tall, that sets our scale at 
	-- 48 pixels = 2 meters, with that scale gravity would be (9.8 / 2) * 48
	-- which is 235.2 pixels per second
	gravity = newVector(0,235.2)
	
	
	-- next we need something for  our guy to stand on, here we'll make objects
	-- to represent the ground.	
	for x = 0, 9 do
		
		newObject("top_middle.png", 
		          newVector(x * 64, love.graphics.getHeight() - 32),
				  newVector(0,0),
				  false,
				  -1)
		
	end

end

function love.draw()

	love.graphics.clear( 0, 64, 255, 255 )

	for key, value in pairs(gameObjects) do

		local objMin = getMin(value)
		
		love.graphics.draw( value.image, objMin.x, objMin.y )
		
	end
	
end

function love.update(deltaTime)
   
	timePool = timePool + deltaTime

	while (timePool >= timeStep) do
		
		gameTime = gameTime + timeStep
		timePool = timePool - timeStep
		
		-- clear cells so it can be rebuild after moving things.
		gameCells = {}
		
		for key, value in pairs(gameObjects) do
			
			-- I found a bug, by trying to remove the points from the cell list
			-- it was missing some and leaving behind "ghosts" that would still
			-- colide with things, but not be draw, since we build the cell list
			-- each frame we can just clear it before we do our game object loop
			--removeFromCells(value)
			
			-- since we don't want our ground to go away we need
			-- a way to specify objects that are permanant.
			-- if an object's TTL is -1 we don't kill it here.
				
			if gameTime > (value.created + value.TTL) and 
				not (value.TTL == -1) then
				
				gameObjects[key] = nil
				
			else
				-- we need to make some chages in the game loop
				-- up till now we've been doing our updates as a number
				-- per frame, but we want more control so now we'll change
				-- it velocity and gravity are per second
				-- we achieve this by multiplying velocity and gravity by
				-- our time step, which is a fraction of a second.
				-- we'll also check if an object can move, if it can't
				-- then we don't apply velocity or gravity.
				
				if value.canMove then
					value.pos.x = value.pos.x + (value.vel.x * timeStep)
					value.pos.y = value.pos.y + (value.vel.y * timeStep)
					
					-- here's where we'll add gravity, even though we are only using
					-- gravity in the y direction we'll do x and y so the code is 
					-- reuseable later, or if we wanna mess with gravity in the game.
					value.pos.x = value.pos.x + (gravity.x * timeStep)
					value.pos.y = value.pos.y + (gravity.y * timeStep)
				end
				
				placeInCells(value)				

				-- we remove the checks for objects leaving the screen
				-- our world should be expansive, also we will have objects
				-- to represent the ground
				--local objMin = getMin(value)
				--local objMax = getMax(value)
				
				--if (objMin.y < 0) or
				--   (objMax.y > love.graphics.getHeight()) then
				--	value.vel.y = value.vel.y + (gravity.y * -timeStep)
				--end
				
				--if (objMin.x < 0) or
				--  (objMax.x > love.graphics.getWidth()) then
				--	value.vel.x = value.vel.x * -1
				--end
				
				checkForCollisions(value)
				
			end
		end
		
		-- here we add the key repeat limiting code
		-- we check if the game time is past the last press plus the repeat rate
		-- if so we update the last key press time to now, and run the keys
		if gameTime > lastKeyPress + keyRepeatRate then
			lastKeyPress = gameTime
			for key, value in pairs(keysTable) do
				
				if value then
					
					if key == "space" then
						newObject("character_frame_1.png", 
								  newVector(love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.5 ),
								  -- we remove the initial velocity on the y axis, because gravity will take
								  -- as soon as we create the object
								  newVector(-objectSpeed + (math.random() * (objectSpeed * 2)),0), 
								  true,
								  15)
					end
					
				end
			
			end
		end
	end
	
end

function love.keypressed( key )
   
   keysTable[key] = true

end

function love.keyreleased( key )
	
	keysTable[key] = false

end

-- we need to add a new argument to this function to specify if an object can move
-- or not, if it can't move we won't adjust it's position or velocity
-- in our collision response.
-- we also can't forget to update all the calls to this function
function newObject(imageName, position, velocity, objCanMove, timeToLive)
	
	local newObj = {}
	newObj.id = nextObjectIndex
	-- We'll check this key when we are resolving collisions
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

-- we are no longer using this function because it's buggy and not 
-- needed
--function removeFromCells(obj)
--	
--	local cellList = getCellList(obj)
--
--	for key, value in pairs(cellList) do
--		
--		validateCell(value)
--		
--		if gameCells[value.x][value.y][obj.id] then
--			gameCells[value.x][value.y][obj.id] = nil
--		end
--	end
--	
--end

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
						
						-- I've modified this part of the collison response so
						-- our un moveable objects don't respond to collisions
						-- and i've adjusted the amount of energy transfer to
						-- 50%
	
						if objTwo.canMove then
							objTwo.vel.x = objTwo.vel.x + (obj.vel.x * 0.5)
							obj.vel.x = obj.vel.x * -0.5
						else
							-- if we hit an unmoveable object on the x axis we
							-- stop the velocity on the x axis and add in one frame
							-- worth of anti gravity
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
							-- if we hit an unmoveable object on the y axis we
							-- stop the velocity on the y axis and add in one frame
							-- worth of anti gravity
							obj.vel.y = (-gravity.y * timeStep)
						end
						
						
					end
				end
			end
		end
	end

end
