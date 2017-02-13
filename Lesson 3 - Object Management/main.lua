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
			
			-- check if the gameTime has passed the created time + time to live on the object
			-- if it's over then we delete/remove the object by setting it to nil
			-- other wise (else) we just move it around like usual.
			if gameTime > (value.created + value.TTL) then
				gameObjects[key] = nil
			else
				value.pos.x = value.pos.x + value.vel.x
				value.pos.y = value.pos.y + value.vel.y
				if (value.pos.y < 0) or
				   (value.pos.y > love.graphics.getHeight()) then
					value.vel.y = value.vel.y * -1
				end
				
				if (value.pos.x < 0) or
				   (value.pos.x > love.graphics.getWidth()) then
					value.vel.x = value.vel.x * -1
				end
			end
		end
		
	end
	
end

function love.keypressed( key )
   
   keysTable[key] = true

   -- We need to add the last variable to this function call, time to live, time to live is in seconds.
   -- we'll just make everything live for 5 seconds
   newObject(key, 
			 newVector(love.graphics.getWidth() * 0.5, love.graphics.getHeight() * 0.5 ),
			 newVector(-letterSpeed + (math.random() * (letterSpeed * 2)), -letterSpeed + (math.random() * (letterSpeed * 2))), 
			 5)
   
end

function love.keyreleased( key )
	
	keysTable[key] = false

end

-- This time we need to add two new variables to the object, but only one to the function definition
-- we need to track when the object was created and how long it needs to stay alive
-- To know when to kill/dispose of the object we also need to know when it was created
-- we'll use the gameTime when this funciton is called
-- we call the timeToLive on the object TTL for short.
-- dont' forget to update the calls to this function, or ERRORS!!!
function newObject(character, position, velocity, timeToLive)

	local newObj = {}
	newObj.created = gameTime
	newObj.TTL = timeToLive
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
