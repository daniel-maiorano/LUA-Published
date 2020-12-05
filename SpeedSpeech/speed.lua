-- Speed Speech.lua

collectgarbage()
--------------------------------------------------------------------------------
-- Locals for application
local trans11, altSwitch, speSe, speSeId, speSePa, minSpeed,spUnit,rep

local sensorLalist = { "..." }
local sensorIdlist = { "..." }
local sensorPalist = { "..." }
local unitsList = { "m/s","km/h","ft/s","mph","kt." }
local repList = { "on change","every second","every 2 seconds","every 3 seconds" }
local prevSpeed
local prevTime
--------------------------------------------------------------------------------
-- Read and set translations
local function setLanguage()
    local lng=system.getLocale()
    local file = io.readall("Apps/Lang/speeds.json")
    local obj = json.decode(file)
    if(obj) then
        trans11 = obj[lng] or obj[obj.default]
    end
end
--------------------------------------------------------------------------------
-- Read available sensors for user to select
local function readSensors()
    local sensors = system.getSensors()
    local format = string.format
    local insert = table.insert
    local fmt=""
    for i, sensor in ipairs(sensors) do
        if (sensor.label ~= "") then
        	if(sensor.param==0) then fmt="%s" else fmt="   %s" end
            insert(sensorLalist, format(fmt, sensor.label))
            insert(sensorIdlist, format("%s", sensor.id))
            insert(sensorPalist, format("%s", sensor.param))
        end
    end
end
----------------------------------------------------------------------
-- Actions when settings changed
local function altSwitchChanged(value)
    local pSave = system.pSave
	altSwitch = value
	pSave("altSwitch", value)
end
--------------------------------------------------------------------------------
-- Min Speed
local function minSpeedChanged(value)
    local pSave = system.pSave
	minSpeed = value
	pSave("minSpeed", value)
end
--------------------------------------------------------------------------------
-- Units
local function unitsChanged(value)
    local pSave = system.pSave
	spUnit = value
	pSave("spUnit", value)
end
--------------------------------------------------------------------------------
-- Repetition
local function repChanged(value)
    local pSave = system.pSave
	rep = value
	pSave("rep", value)
end
--------------------------------------------------------------------------------
-- Sensor Changed
local function sensorChanged(value)
    local pSave = system.pSave
    local format = string.format
    speSe = value
    speSeId = format("%s", sensorIdlist[speSe])
    speSePa = format("%s", sensorPalist[speSe])
    if (speSeId == "...") then
        speSeId = 0
        speSePa = 0 
    end
    pSave("speSe", value)
    pSave("speSeId", speSeId)
    pSave("speSePa", speSePa)
end

--------------------------------------------------------------------------------
-- Draw the main form (Application inteface)
local function initForm()
    local fw = tonumber(string.format("%.2f", system.getVersion()))
    if(fw >= 4.22)then
        local form, addRow, addLabel = form, form.addRow ,form.addLabel
        local addIntbox, addCheckbox = form.addIntbox, form.addCheckbox
        local addSelectbox, addInputbox = form.addSelectbox, form.addInputbox
        
        addRow(1)
        addLabel({label="---     WhiteBox Speed Speech    ---",font=FONT_BIG})
        
        addRow(2)
        addLabel({label=trans11.speedSensor, width=220})
        addSelectbox(sensorLalist, speSe, true, sensorChanged)
        
        addRow(2)
        addLabel({label=trans11.sw, width=220})
        addInputbox(altSwitch, true, altSwitchChanged) 
        
        addRow(2)
        addLabel({label=trans11.minSpeedTr, width=220})
        addIntbox(minSpeed, -0, 10000, 0, 0, 1, minSpeedChanged)
        
        addRow(2)
        addLabel({label=trans11.units, width=220})
        addSelectbox(unitsList, spUnit, false, unitsChanged)
        
        addRow(2)
        addLabel({label=trans11.repet, width=220})
        addSelectbox(repList, rep, true, repChanged)
        
        addRow(1)
        addLabel({label="WhiteBox - v."..speedAnnVersion.." ", font=FONT_MINI, alignRight=true})
        else
        local addRow, addLabel = form.addRow ,form.addLabel
        addRow(1)
        addLabel({label="Please update, min. fw 4.22 required!"})
    end
end


local function init(code)
    prevTime=0
    prevSpeed=0
    local pLoad = system.pLoad
	altSwitch = pLoad("altSwitch")
    minSpeed = pLoad("minSpeed", 0)
    speSe = pLoad("speSe", 0)
    speSeId = pLoad("speSeId", 0)
    speSePa = pLoad("speSePa", 0)
    spUnit =pLoad("spUnit",1)
    rep = pLoad("rep",1)

    system.registerForm(1, MENU_APPS, trans11.appName, initForm)
    readSensors()
    collectgarbage()
end

-- Loop function is called in regular intervals
local function loop()
	local swi  = system.getInputsVal(altSwitch)
    local sensor = system.getSensorByID(speSeId, speSePa)
    
    if (swi and swi == 1) then
		if(sensor and sensor.valid) then
          value=sensor.value
          factor=1
		  if(sensor.unit=="m/s") then factor=1 end
          if(sensor.unit=="km/h") then factor=0.2777 end
          if(sensor.unit=="kmh") then factor=0.2777 end
		  if(sensor.unit=="ft/s") then factor=0.3048 end
		  if(sensor.unit=="mph") then factor=0.44704 end
		  if(sensor.unit=="kt.") then factor=0.514444 end
		  if(spUnit==2) then value=value*factor*3.6 end
		  if(spUnit==3) then value=value*factor*3.28084 end
		  if(spUnit==4) then value=value*factor*2.23694 end
		  if(spUnit==5) then valuee=value*factor*1.94384 end
		  	  
		  if(value>minSpeed) then
			value=value-(value%10)
		  end
		  if((rep==1 and prevSpeed ~= value) or (rep>1 and prevTime<system.getTime())) then
			if(not system.isPlayback()) then
			  system.playNumber(value,0)
			  prevSpeed=value
			  prevTime=system.getTime()-1+rep
			end
		  end
		end
    end 
    
end
-- Application interface
--------------------------------------------------------------------------------
speedAnnVersion = "1.0"
setLanguage()
collectgarbage()
return {init = init, loop = loop, author = "DM", version = speedAnnVersion, name = "Speed Speech"}