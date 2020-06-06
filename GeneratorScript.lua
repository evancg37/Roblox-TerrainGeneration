--World Generator Script - V1.5
--EvanTheBuilder 2/16/2019

--Changenotes:

--V1.5
--Replaced height randomization system with heightmap generation
--Created sine function objects parameterization 
--Greatly reduced time it takes to generate maps
--Adjusted tree color randomization
--Rewrote region conversion system
--Reintroduced deserts

--V1.4
--Increased maximum grid size
--^-Modified lake plate creation 

--V1.3
--Improved near-plate algorithm by adding naming scheme to plates
--Significantly reduced time to spawn lakes 
--Switched to Region-based lake and desert spawning **Obsoleted**
--^--Created height variation algorithm
--^--Added water and beach finding functionality based on height
--Added color variation to land
--Removed old code

--Todo:
--Improve height variation: More natural, better maps, central lakes/rivers 
--Add more plants
--Add weather
--Add buildings
--Add critters
--Add scenery
--Add more terrains
--Improve trees
--Create map GUI 

NOISE = 3
HEIGHT_MAX = 14
WATER_HEIGHT = workspace.WaterHeight

LAKE_SPREAD = 0.4
DESERT_SPREAD = 0.2

DEMOPOS = Vector3.new(1022, 201, 988)

PLATESIZE = workspace.PlateSize
GRIDSIZE = workspace.GridSize

plates = workspace.Plates
waters = workspace.Waters
trees = workspace.MouseIgnores.Trees
regions = workspace.Regions
waterbase = workspace:FindFirstChild("WaterPlate")

baseplate = Instance.new("Part")
baseplate.Anchored = true
baseplate.TopSurface = 0
baseplate.BottomSurface = 0
baseplate.Material = Enum.Material.Grass
baseplate.BrickColor = BrickColor.Green()

------------------------------------------------------------------------
--Base Grid Creation

function getRandomPlate(model)
	if model == nil then model = plates end
	local allplates = model:GetChildren()
	if #allplates > 0 then
		return allplates[math.random(1, #allplates)]
	else 
		return nil 
	end
end

function spawnGrid_Heightmap(heightmap)
	local gridsize = GRIDSIZE.Value
	print ("Spawning " .. gridsize * gridsize .. " plates")
	local rows = {}
	local cols = {}
	for i = 1, gridsize do
		table.insert(rows, {}) --Init the rows and cols tables to have empty tables
	end
	for i = 1, gridsize do
		table.insert(cols, {})
	end
	for i = 1, #heightmap do
		for j = 1, #(heightmap[i]) do
			if heightmap[i][j] > WATER_HEIGHT.Value + 0.3 then
				local plate = baseplate:Clone()
				local height = math.max(WATER_HEIGHT.Value, heightmap[i][j])
				--print ("Height: " .. height)
				plate.Size = Vector3.new(PLATESIZE.Value, height, PLATESIZE.Value)
				plate.Position = Vector3.new((i-1)*PLATESIZE.Value, plate.Size.Y/2, (j-1)*PLATESIZE.Value)
				plate.Color = Color3.new(0.1, 0.6 - 0.18*math.random(), 0.1)
				plate.Name = string.format("%d,%d", i, j)
				plate.Parent = plates
				table.insert(rows[i], plate) --Insert into the y row this plate
				table.insert(cols[j], plate) --Insert into the x column this plate
			end
		end
	end
	return rows, cols 
end

--Create the actual plate parts
function spawnGrid()
	local gridsize = GRIDSIZE.Value
	print ("Spawning " .. gridsize * gridsize .. " plates")
	local rows = {}
	local cols = {}
	for i = 1, gridsize do
		table.insert(rows, {}) --Init the rows and cols tables to have empty tables
	end
	for i = 1, gridsize do
		table.insert(cols, {})
	end
	for x = 1, gridsize do
		for y = 1, gridsize do
			local plate = baseplate:Clone()
			local height = math.random(HEIGHT_MAX-NOISE, HEIGHT_MAX)
			plate.Size = Vector3.new(PLATESIZE.Value, height, PLATESIZE.Value)
			plate.Position = Vector3.new((x-1)*PLATESIZE.Value, height/2, (y-1)*PLATESIZE.Value)
			plate.Color = Color3.new(0.1, 0.6 - 0.18*math.random(), 0.1)
			plate.Name = string.format("%d,%d", x, y)
			plate.Parent = plates
			table.insert(cols[x], plate) --Insert into the x column this plate
			table.insert(rows[y], plate) --Insert into the y row this plate
		end
	end
	return rows, cols
end

--We can name each plate according to a coordinate system. 
--For example, the plate at 125,103 is to the left of plate 126,103
function getNearPlates_Coordinate(plate, parent)
	local comma = string.find(plate.Name, ",")
	local lefthalf = tonumber(string.sub(plate.Name, 0, comma-1))
	local righthalf = tonumber(string.sub(plate.Name, comma+1)) --Get coordinate of plate
	local tab = {}
	for x = -1, 1 do
		for y = -1, 1 do
			if not (x == 0 and y == 0) then --Except in the middle...
				table.insert(tab, parent:FindFirstChild(string.format("%d,%d",lefthalf+x, righthalf+y))) --Insert into the table the corresponding plate that should be in that posiiton
			end
		end
	end
	return tab
end

-------------------------------------------------------------------------------
--Regions

-- Get all plates that may be a part of this map
function getAllPlates() 
	return plates:GetChildren()
end

--Find beaches determined by the sealevel
function findBeaches(sealevel)
	local m = Instance.new("Model")
	m.Name = "Beaches"
	m.Parent = regions
	for _, plate in pairs(getAllPlates()) do
		if plate.Size.Y < WATER_HEIGHT.Value + 7 then
			plate.Parent = m
		end
	end
	convertRegion(m, "beach")
end

--Create randomly spawned deserts
function spawnDeserts(size)
	local numdeserts = 6 + 7*math.random()
	for i = 1, numdeserts do
		local desert = createRegion("Desert"..i, DESERT_SPREAD, size)
		if #desert:GetChildren() > 0 then
			convertRegion(desert, "desert")
		else
			desert:Destroy()
		end
	end
end

--Select a region of plates using randomization and the getNear method
function createRegion(name, spread, size)
	local m = Instance.new("Model")
	m.Name = name
	m.Parent = regions
	local searchplate = nil
	local startplate = getRandomPlate()
	searchplate = startplate
	local numplates = math.random(size, size^1.4)
	local madeplates = 0
	while madeplates < numplates do
		if searchplate ~= nil and plates ~= nil then
			local nears = getNearPlates_Coordinate(searchplate, plates) --Get tiles near the selected or last plate
			if #nears ~= 0 then --If there are near tiles,
				for _, plate in pairs (nears) do --For each one of them
					if math.random() > spread then --remove them by chance
						plate.Parent = m
						madeplates = madeplates + 1
					end
				end
				searchplate = nears[math.random(1, #nears)] --The next plate to search for is a random one of the removed ones
			else --If there are no near tiles near this plate...
				madeplates = madeplates + 2 --Increase faster as we are almost out of space in this region 
			end
		else
			madeplates = madeplates + 1
		end
	end
	return m
end

function convertRegion(region, regiontype)
	local color = BrickColor.New("Magenta") --Defaults
	local material = Enum.Material.SmoothPlastic
	if regiontype == "desert" then
		color = BrickColor.New("Burlap")
		material = Enum.Material.Slate
	elseif regiontype == "beach" then
		color = BrickColor.New("Cashmere")
		material = Enum.Material.Sand
	end
	local getplates = region:GetChildren()
	for _, plate in pairs(getplates) do
		plate.BrickColor = color
		plate.Material = material
	end
end

----------------------------------------------------------------------------------------
--Heightmap Generation

--Create randomly parameterized mathematical step function
function createRandomFunc(dir)
	local amp = 20 + (36*math.random())
	local shift = 0.01 + (0.05*math.random())
	local start = math.random() * 2 * math.pi
	local newfunc = {i=0,direction=dir}
	newfunc.getvalue = function()
		local result = amp * math.sin(start + newfunc.i)
		newfunc.i = newfunc.i + shift
		return result
	end
	print (string.format("Created func with direction %s and amp %f and shift %f and start %f", dir, amp, shift, start))
	return newfunc
end

--Create a heightmap object
function newHeightmap()
	local rows = {}
	for i = 1, GRIDSIZE.Value do
		rows[i] = {}
		for j = 1, GRIDSIZE.Value do
			rows[i][j] = HEIGHT_MAX
		end
	end
	return rows
end

--Print out a heightmap table
function printHeightmap(heightmap)
	print "Heightmap:\n["
	for i = 1, #heightmap do
		local str = ""
		local avg = 0
		--Calculate average height
		for i = 1, #heightmap do
			for j = 1, #(heightmap[i]) do
				avg = avg + heightmap[i][j]
			end
		end
		avg = avg / (GRIDSIZE.Value * GRIDSIZE.Value)
	
		for j = 1, #(heightmap[i]) do
			local char = "-"
			if heightmap[i][j] - avg > 6 then
				char = "?"
			end
			if heightmap[i][j] - avg > 10 then
				char = "¯"
			end
			if heightmap[i][j] - avg < -5 then
				char = "_"
			end
			str = str .. string.format("%s, ", char)
		end
		print (string.format("\v{ %s }", string.sub(str, 0, string.len(str) - 1)))
	end	
	print "]"
end

--Generate a randomly parameterized heightmap
function generateHeightmap()
	print "Generating heightmap..."
	local heightmap = newHeightmap()
	local funcs = {}
	for i = 1, 2 do
		table.insert(funcs, createRandomFunc(1))
		table.insert(funcs, createRandomFunc(2))
	end
	for _, func in pairs (funcs) do --For every function we are given,
		for i = 1, #heightmap do --For every col in the grid,
			local amt = func.getvalue() --Increase the values in each column
			for j = 1, #heightmap do    --down the line by amount amt.
				if func.direction == 1 then --Change correct one depending on row or col
					heightmap[i][j] = heightmap[i][j] + amt + math.random() * NOISE --Increase the col direction
				else
					heightmap[j][i] = heightmap[j][i] + amt + math.random() * NOISE --Increase the row direction
				end
				
			end
		end
	end
	return heightmap
end

---------------------------------------------------------------
--Trees and Vegetation

function createTree(pos)
	local m = Instance.new("Model")
	m.Name = "Tree"
	local trunkheight = 8 + math.random() * 12
	local trunksize = 2.5 + math.random() * 2.5
	local layerheight = 2 + math.random() * 4.5
	local layernum = math.random(4, 6)
	local layerwidth = 2 + math.random() * 3
	local trunk = Instance.new("Part")
	trunk.Name = "Trunk"
	local leafcolor = Color3.new(0.07 + 0.06*math.random(), 0.35+0.2*math.random(), 0)
	local trunkcolor = Color3.new(0.15 + 0.12*math.random(), 0.14+0.06*math.random(), 0.05)
	trunk.Color = trunkcolor
	trunk.Material = Enum.Material.Wood
	trunk.Anchored = true
	trunk.Size = Vector3.new(trunksize, trunkheight, trunksize)
	trunk.Parent = m
	trunk.Position = Vector3.new(pos.X, pos.Y + trunk.Size.Y/2, pos.Z)
	m.PrimaryPart = trunk
	local newpos = Vector3.new(trunk.Position.X, trunk.Position.Y + trunk.Size.Y / 2, trunk.Position.Z)
	for i = 1, layernum do
		local layer = Instance.new("Part")
		layer.Name = "Leaf"
		layer.Anchored = true
		layer.Color = leafcolor
		layer.Material = Enum.Material.Grass
		layer.Size = Vector3.new((layernum+1-i) * layerwidth, layerheight,(layernum+1-i) *layerwidth) -- Starts at layernum +1 and goes down to i, times layer width to create decaying trunk sizes
		layer.Parent = m
		layer.Position = Vector3.new(newpos.X, newpos.Y + layer.Size.Y / 2, newpos.Z)
		newpos = Vector3.new(layer.Position.X, layer.Position.Y + layer.Size.Y/2, layer.Position.Z)
	end
	--print (string.format("Created tree with trunkheight: %s  trunksize: %s\nlayerheight: %s  layernum: %s   layerwidth: %s", trunkheight, trunksize, layerheight, layernum, layerwidth))
	m.Parent = trees
	return m
end

function addTreesToPlate(plate, num)
	local count = 0
	local opos = plate.Position
	for i = 1, num do
		local deltax = math.random() * PLATESIZE.Value/2
		local deltaz = math.random() * PLATESIZE.Value/2
		if math.random() > 0.5 then -- Half chance that the tree will go the other direction
			deltax = deltax * -1
		end
		if math.random() > 0.5 then
			deltaz = deltaz * -1
		end
		local newpos = Vector3.new(opos.X + deltax, opos.Y + plate.Size.Y/2, opos.Z + deltaz)
		createTree(newpos)
		count = count + 1
	end
	return count
end

function spawnForests(freq, region)
	print "Spawning forests..."
	local getplates = region:GetChildren()
	local treecount = 0
	for _, plate in pairs(getplates) do
		if math.random() > 0.7 - (freq/50) then
			treecount = treecount + addTreesToPlate(plate, 1)
		end
	end
	print ("Spawned " .. treecount .. " trees")
end

------------------------------------------------------------------
-- Controls and Main

controls = workspace.Controls
debounce = true

function main()
	if debounce then
		debounce = false
		controls.Execute.Button.BrickColor = BrickColor.Yellow()
		print "Clearing"
		wait(0.5)
		local treefreq = controls.TreeChanger.Value.Value
		regions:ClearAllChildren()
		plates:ClearAllChildren()
		trees:ClearAllChildren()
		print "Regenerating"
		local hm = generateHeightmap()
		--printHeightmap(hm)
		spawnGrid_Heightmap(hm)
		findBeaches()
		spawnDeserts(64)
		spawnForests(treefreq, plates)
		print "Regenerated - New terrain gen"
		controls.Execute.Button.BrickColor = BrickColor.DarkGray()
		wait(0.5)
		controls.Execute.Button.BrickColor = BrickColor.Green()
	end
	debounce = true
end

controls.Execute.Button.ClickDetector.MouseClick:Connect(main)

wait(1)
math.randomseed(tick())

main()