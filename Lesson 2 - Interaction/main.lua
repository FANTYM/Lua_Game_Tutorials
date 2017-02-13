keysTable = {}

timePool = 0
timeStep = 1 / 30
gameTime = 0

gameObjects = {}
nextObjectIndex = 0

letterSpeed = 5

function love.load()

end

function love.draw()

	for key, value in pairs(gameObjects) do
		love.graphics.print(value.char, value.pos.x, value.pos.y)
	end
end

function love.update(deltaTime)
   
	timePool = timePool + deltaTime

	while (timePool >= timeStep) do
		
		gameTime = gameTime + timeStep
		timePool = timePool - timeStep

		for key, value in pairs(gameObjects) do
			
			-- value.pos.y = value.pos.y - letterSpeed
			-- instead of the above line we need to add the velocity to the position
			value.pos.x = value.pos.x + value.vel.x
			value.pos.y = value.pos.y + value.vel.y
			
			-- if value.pos.y < 0 then
			--	value = nil
			-- end	
			-- now instead of removing the character when it's out of the screen, we'll reverse it's velocity, x or y 
			-- depending on which side of the screen it's exiting
			
			-- if the y position is less than 0 or greater than the screen width, reverse y velocity
			if (value.pos.y < 0) or
			   (value.pos.y > love.graphics.getHeight()) then
				-- revese the y velocity
				value.vel.y = value.vel.y * -1
			end
			
			-- if the x position is less than 0 or greater than the screen width, reverse x velocity
			if (value.pos.x < 0) or
			   (value.pos.x > love.graphics.getWidth()) then
				-- revese the x velocity
				value.vel.x = value.vel.x * -1
			end
		end
		
	end
	
end

function love.keypressed( key )
   
   keysTable[key] = true

   -- for easier readability we'll split this function call into multiple lines
   -- we are adding the last variable to the function call, velocity
   -- this will be a random number between -letterSpeed to +letterSpeed, on x, and y
   -- to do this we take the take -letterSpeed and add a random number from 0 to letterSpeed * 2
   -- we'll also make the letters start in the middle of the screen
   newObject(key, 
			 newVector(love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.5 ),
			 newVector(-letterSpeed + (math.random() * (letterSpeed * 2)), -letterSpeed + (math.random() * (letterSpeed * 2))))
   
end

function love.keyreleased( key )
	
	keysTable[key] = false

end

-- We are adding new functionality to this program, so we need to add a new variable
-- to the function, we are going to now have a velocity (speed and direction of travel)
-- we will also update where this funciton is called from, or we'll get errors
-- velocity is a vector just like position, but we'll use it diffently
function newObject(character, position, velocity)

	local newObj = {}
	newObj.char = character
	newObj.pos = position
	newObj.vel = velocity
	
	gameObjects[nextObjectIndex] = newObj
	
	nextObjectIndex = nextObjectIndex + 1
	
end

function newVector(xPos, yPos)
	
	local newVectorTable = {}
	newVectorTable.x = xPos
	newVectorTable.y = yPos
	
	return newVectorTable

end
