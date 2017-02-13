-- This variable holds a table that we put keys that are pressed in
keysTable = {}
-- This variable holds the time pool for the program loop
timePool = 0
-- This variable hold the time step, the amount of time we want to pass
-- durring each program loop, this will run the loop 30 times a second
timeStep = 1 / 30
-- This variable hold the total time the game has been running
-- if you stop/pause the game loop this will stop counting.
-- This will also be used to time events in the game
gameTime = 0

-- This variable is a table of game objects
-- for this lesson we will just draw the letter that was pushed
-- floating up from the bottom of the screen, when it's released
gameObjects = {}

-- This variable hold the index for the next object we make
-- we will add one each time an object is made so we don't over write
-- existing objects
nextObjectIndex = 0

-- This variable controls how many pixels the letters move in a single loop
letterSpeed = 5

-- This function is called when the program starts running
-- place instrucitons here that just need to run one timer
-- when the program starts.
function love.load()

end

-- This function is called constantly, every time the screen is
-- drawn, place instructions here to display text and graphics
function love.draw()
	-- here we loop through the gameObjects and draw them to the screen
	for key, value in pairs(gameObjects) do
		love.graphics.print(value.char, value.pos.x, value.pos.y)
	end
end

-- This functions is called constantly, every loop of the program.
-- Place instructions in this function to controll how the program
-- does things.
-- This functions provides you with a variable, deltaTime, that contains the amount
-- of time since the last run of this function.
function love.update(deltaTime)
   
	-- Add the deltaTime to the time pool
	timePool = timePool + deltaTime

	-- now we loop, loops repeat instrucitons until a given condition is met
	-- this one loops while the timePool is larger or equal to the time step
	while (timePool >= timeStep) do
		
		-- add the time step to the game time
		gameTime = gameTime + timeStep
		-- subtract the time step from the time pool
		timePool = timePool - timeStep
		
		-- Place instructions here than need to run every time step.
		
		-- We will loop through the gameObjects moving their position up x,y = (0, -1) each loop
		-- we loop through using a for loop and pairs
		-- this will give us two variables, key which is the index in the table
		-- and value which is the value associcated with the key,
		-- in this case key is the objectIndex number, and value is the table
		-- that holds the character and position
		-- we can ignore key for this, sometimes you'll use it if you have multiple
		-- tables with the same keys
		for key, value in pairs(gameObjects) do
			
			value.pos.y = value.pos.y - letterSpeed
			
			-- we check if the pos is off the screen then remove the 
			-- game object by setting it to nil (which is nothing)
			if value.pos.y < 0 then
				value = nil
			end	
		
		end
		
	end
	
end
-- This functions is called every time the user presses a key
-- it gets a variable containing the key that was pressed
function love.keypressed( key )
   
   -- set the position in the key table, indexed by the key, to true
   keysTable[key] = true
   
   -- we create a new game object using the current key, and a random width, just off the bottom of
   -- the screen.
   -- math.random() give a number between 0 and 1, ie(0.2, 0.4, etc)
   -- we multiply it by the largest value we want it to have, so in this case it'same
   -- 0 to screen width this is for the x value, think horizontal -----
   -- for the y value think vertical | we use the screen hight, plus 10 so it starts off screen
   newObject(key, newVector(math.random() * love.graphics.getWidth(), love.graphics.getHeight() + 10 ))
   
end

-- This functions is called every time the user stops pressing a key 
-- it gets a variable containing the key that was released
function love.keyreleased( key )
	
	-- set the position in the key table, indexed by the key, to false
	keysTable[key] = false

end


-- This function will be used to create gameObjects
function newObject(character, position)
	-- local variables are only accesisble from inside the function they are made
	-- without local it would be a global variable accesisble from anywhere in the program
	-- and that can cause errors.
	local newObj = {}
	newObj.char = character
	newObj.pos = position
	
	-- put the new object in the gameObjects table at position nextObjectIndex
	gameObjects[nextObjectIndex] = newObj
	
	-- next we increase the nextObjectIndex so we don't put the next object in the same spot.
	nextObjectIndex = nextObjectIndex + 1
	
end

-- This function creates a new position table and returns it
function newVector(xPos, yPos)
	
	local newVectorTable = {}
	newVectorTable.x = xPos
	newVectorTable.y = yPos
	
	return newVectorTable

end