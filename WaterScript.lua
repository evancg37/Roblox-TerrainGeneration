--Water V2.1 - EvanTheBuilder
--Requires a WaterPlate to exist

-----SETTINGS-----------------------
--Float and Buoyancy
BUOY_CONSTANT = 310
VEL_CONSTANT = 2000
VEL_GOAL = -1.5

--Sound
YVEL_SOUNDMAX = -300

if workspace:FindFirstChild("GridSize") then GRIDSIZE = workspace.GridSize end
if workspace:FindFirstChild("PlateSize") then PLATESIZE = workspace.PlateSize end
if workspace:FindFirstChild("WaterHeight") then WATER_HEIGHT = workspace.WaterHeight end
-----------------------------------

--Create lake plates to fill the entire grid of the map
function enableLakePlateMulti()
	local total_size = Vector3.new(GRIDSIZE.Value * PLATESIZE.Value, 1, GRIDSIZE.Value * PLATESIZE.Value)
	print (string.format("Creating lake plates. Total size: %d, %d", total_size.X, total_size.Z))
	local lakeplates = {}
	local xleft = total_size.X
	local xpos = 0
	local xsize
	local plate_positional = PLATESIZE.Value * -0.4
	while xleft > 0 do --Create cols
		local zpos = 0
		local zleft = total_size.Z
		local zsize = zleft
		if xleft > 2048 then xsize = 2048 else xsize = xleft end
		while zleft > 0 do
			if zleft > 2048 then zsize = 2048 else zsize = zleft end
			local size = Vector3.new(xsize, WATER_HEIGHT.Value-2, zsize)
			local pos = Vector3.new(xpos + xsize/2 + plate_positional, size.Y/2, zpos + zsize/2 + plate_positional)
			table.insert(lakeplates, createLakePlate(pos, size))
			zleft = zleft - zsize
			zpos = zpos + zsize
		end
		xleft = xleft - xsize
		xpos = xpos + xsize
	end
	return lakeplates
end

--Create large lake plate object
--WaterScript manages animation and behavior
function createLakePlate(pos, size)
	local p = Instance.new("Part")
	p.Name = "Waterplate"
	p.Parent = workspace.Waterplates
	p.Anchored = true
	p.CanCollide = false
	p.Transparency = 0.17
	p.Material = Enum.Material.Granite
	p.BrickColor = BrickColor.new("Bright bluish green")
	p.Size = size
	p.Position = pos
	return p
end

function getWaterPlateHeight(part)
	return part.Position.Y + 0.5 * part.Size.Y
end

function enableWaterPlateAnims()
	spawn(function ()
		local service = game:GetService("RunService")
		local modifier_i = 0.00375
		local modifier_j = 0.01
		local amplitude_height = 0.6
		local amplitude_color = 0.07
		local i = 0
		local j = 0
		
		service.Heartbeat:Connect(function(step)
			local WATER_HEIGHT = workspace.WaterHeight.Value
			local plates = workspace.Waterplates:GetChildren()
			for _, plate in pairs(plates) do --Modify the height and color of each plate
				plate.Size = Vector3.new(plate.Size.X, WATER_HEIGHT - amplitude_height*(1 + math.sin(i)/2), plate.Size.Z)
				plate.Position = Vector3.new(plate.Position.X, 0.5 + plate.Size.Y/2, plate.Position.Z)
				plate.Color = Color3.new(0, 0.7 - amplitude_color*math.sin(j), 1)
			end
			i = i + modifier_i
			j = j + modifier_j
			if i > 1e7 then 
				i = 0
			end
			if j > 1e7 then --Change our stuff after the modifiers
				j = 0
			end
		end)
	end)
	print "Enabled water animation"
end

function addSound(torso)
	local yvel = torso.Velocity.Y
	yvel = math.min(0, yvel) --Only negative
	yvel = math.max(YVEL_SOUNDMAX, yvel) --Capped by YVEL_SOUNDMAX 
	local s = Instance.new("Sound")
	s.Name = "Sploosh"
	s.Volume = 0.02 + 0.15*(yvel/YVEL_SOUNDMAX) + 0.05*math.random() --Get negative veloicty ouit of the max, and add to volume with this 
	s.SoundId = "rbxassetid://465500569"
	s.PlaybackSpeed = 1.05 - 0.3*(yvel/YVEL_SOUNDMAX)+0.1*math.random() --Get negative veolcity out of the max, and subtract from palyback speed
	s.Parent = torso
	s.PlayOnRemove = true
	s:Destroy()
end

	
function connectPlate(plate)
	plate.Touched:Connect(function(part)
		local human = part.Parent:FindFirstChild("Humanoid")
		if human then
			local torso = human.Parent:FindFirstChild("Torso")
			if not torso then 
				torso = human.Parent:FindFirstChild("UpperTorso")
			end
			if torso then
			local buoy = torso:FindFirstChild("Buoyancy")
			if not buoy then 
				buoy = Instance.new("BodyForce")
				buoy.Name = "Buoyancy"
				buoy.Parent = torso
				local count = 0
				spawn(function() 
					while count < 12 do
						wait()
						local dist = getWaterPlateHeight(plate) - torso.Position.Y
						if dist > 0 then
							--print ("Dist: " .. dist)
							buoy.Force = Vector3.new(0, 9.8 * BUOY_CONSTANT, 0)
						else
							buoy.Force = Vector3.new(0, 0, 0)
							count = count + 1
						end
						--print ("Buoy: " .. buoy.Force.Y)
					end
					buoy:Destroy()
					--print "Out of water"
				end)
			end 
			local vel = torso:FindFirstChild("VelocityHalf")
			--print ("Pos: " .. torso.Position.Y)
			if not vel and torso.Velocity.Y < 15*VEL_GOAL then --We are going down rapidly 
				--print "Contact"
				vel = Instance.new("BodyVelocity")
				vel.Velocity = Vector3.new(0, VEL_GOAL, 0)
				vel.Name = "VelocityHalf"
				vel.P = VEL_CONSTANT
				vel.MaxForce = Vector3.new(0, 1e8, 0)
				vel.Parent = torso
				addSound(torso)
				spawn(function()
					local count = 0
					while count < 4 do
						wait()
						if math.abs(torso.Velocity.Y - vel.Velocity.Y) < 2 then
							count = count + 2
						elseif math.abs(torso.Velocity.Y - vel.Velocity.Y) < 5 then
							count = count + 1
						end
						--print ("Vel: " .. vel.Velocity.Y .. "  Actual: " .. torso.Velocity.Y)
					end
					vel:Destroy()
					--print "Velocity reduced"
				end)
			end
		end
		end
	end)
	return plate
end

connectedplate = nil

--On a loop, check if there exists a plate
-- If there is, and we havent connected it yet to the services, do it and mark it as the connected plate
-- If there isnt, wait
-- If there is, but we have connected it, wait

waterplates = {}

function checkWaterplate(plate)
	for _, item in pairs (waterplates) do
		if item == plate then
			return true
		end
	end
	return false
end

enableLakePlateMulti()
enableWaterPlateAnims()

while true do 
	local foundplates = workspace.Waterplates:GetChildren()
	for _, plate in pairs(foundplates) do
		if not checkWaterplate(plate) then
			table.insert(waterplates, plate)
			connectPlate(plate)
		end
	end
	wait(0.5)
end