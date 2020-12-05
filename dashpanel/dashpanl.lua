-- require('mobdebug').start()
-- #############################################################################   
-- # Dash panel
-- # Daniel MAIORANO                  
-- # V1.0 - 2020-11-27: Initial release
-- #############################################################################

local trans11   -- Json object containing translation texts

local appVersion="1.0"
local cmdName
local cfg={}
local editCmd
local dashSizeSelected
local indCount
local indMax
local indFirstRow=4
local indMode
local imgGearUp
local imgGearDn
local imgFlap0
local imgFlapTo
local imgFlapLd

--------------------------------------------------------------------
-- Set Language
--------------------------------------------------------------------
local function setLanguage()
    local lng=system.getLocale()
    local file = io.readall("Apps/dashpanl/config.jsn")
    local obj = json.decode(file)
    if(obj) then
        trans11 = obj[lng] or obj[obj.default]
    end
end

--------------------------------------------------------------------
-- When command name changed
--------------------------------------------------------------------
local function cmdNameChanged(value)
    cfg.indicators[editCmd].name=value
end

--------------------------------------------------------------------
-- When switch changed
--------------------------------------------------------------------
local function onSwitchChanged(value)
    local swTable=system.getSwitchInfo(value)
    cfg.indicators[editCmd].command=swTable.label
    cfg.indicators[editCmd].switch=value
end

--------------------------------------------------------------------
-- On size changed
--------------------------------------------------------------------
local function onSizeChanged(value)
    system.unregisterTelemetry(1)
    dashSizeSelected=value
    cfg.size=value
    system.registerTelemetry(1,cfg.dashName,dashSizeSelected,showDash)
    if(cfg.size==1) then 
        indMax=1
    end
    if(cfg.size==2) then
        indMax=3
    end
end
--------------------------------------------------------------------
-- On indicator mode changed
--------------------------------------------------------------------
local function onIndModeChanged(value)
    cfg.indicators[editCmd].indMode=value
end
--------------------------------------------------------------------
-- On model changed
--------------------------------------------------------------------
local function onDashNameChange(value)
    cfg.dashName=value
end
--------------------------------------------------------------------
-- Main Form
--------------------------------------------------------------------
local function initForm(subForm)
    local fw = tonumber(string.format("%.2f", system.getVersion()))
    if(fw >= 4.22)then

        if(subForm==1) then
            if(indCount<indMax) then
                form.setButton(1, trans11.add, ENABLED)
            else
                form.setButton(1, trans11.add, DISABLED)
            end

            if(indCount>0)then
                form.setButton(2, trans11.del, ENABLED)
            else
                form.setButton(2, trans11.del, DISABLED)
            end

            form.setButton(5, trans11.sav, ENABLED)

            form.addRow(2)
            form.addLabel({label=trans11.dashName})
            form.addTextbox(cfg.dashName,20,onDashNameChange)

            form.addRow(2)
            form.addLabel({label=trans11.dashSize})
            form.addSelectbox(trans11.dashSizeList,dashSizeSelected,false,onSizeChanged,{width=190})

            form.addRow(1)
            form.addLabel({label=trans11.indList,enabled=false,font=FONT_BOLD})

            if(cmdName == nil) then
                cmdName=trans11.newLabel
            end
            -- print("Indicators:"..#cfg.indicators)
            for e, n in pairs(cfg.indicators) do
                form.addRow(2)
                form.addSpacer(15,10)
                form.addLink((function() editCmd=e form.reinit(2) end), {label = cfg.indicators[e].name})
            end

            form.addRow(1)
            form.addLabel({label=trans11.appName.." v."..appVersion.." ", font=FONT_MINI, alignRight=true})

        end

        if(subForm==2) then 
            form.setButton(5, "", ENABLED)

            form.addRow(2)
            form.addLabel({label=trans11.indName})
            form.addTextbox(cfg.indicators[editCmd].name,20,cmdNameChanged)
            
            form.addRow(2)
            form.addLabel({label=trans11.sw, width=220})
            form.addInputbox(cfg.indicators[editCmd].switch, true, onSwitchChanged) 

            form.addRow(2)
            form.addLabel({label=trans11.indMode})
            form.addSelectbox(trans11.indModeList,cfg.indicators[editCmd].indMode,false,onIndModeChanged)

            form.addLink((function() form.reinit(1) end), {label = trans11.menuLabelBack,font=FONT_BOLD})
            
            form.addRow(1)
            form.addLabel({label=trans11.appName.." v."..appVersion.." ", font=FONT_MINI, alignRight=true})
        end

    else
        form.addRow(1)
        form.addLabel({label="Please update, min. fw 4.22 required!"})
    end
end
--------------------------------------------------------------------
-- Key handler
--------------------------------------------------------------------
local function keyPressed(key)

    if (key == KEY_1) then
        if indCount < indMax then
            indCount = indCount + 1
            table.insert(cfg.indicators, indCount)
            cfg.indicators[indCount]={}
            cfg.indicators[indCount].name=trans11.newLabel
            cfg.indicators[indCount].command=nil
            cfg.indicators[indCount].indMode=1
            form.reinit(1)
        end
    end
    if (key == KEY_2) then

        local focus = form.getFocusedRow()

        if focus >= indFirstRow then
            if indCount > 0 then
                indCount = indCount - 1
                table.remove(cfg.indicators, focus - indFirstRow + 1)
                form.reinit(1)
            end
        end
    end

    if(key==KEY_5) then
        form.preventDefault()
        -- remove switchitem objects
        for e, n in pairs(cfg.indicators) do
            local pName="switch-"..cfg.indicators[e].command
            system.pSave(pName,cfg.indicators[e].switch)
            cfg.indicators[e].switch=nil
        end        
        local cfgtxt=json.encode(cfg)
        local obj=io.open(modelFile,"w")
        io.write(obj,cfgtxt)
        io.close(obj)
        -- reinsert switchitem objects
        for e, n in pairs(cfg.indicators) do
            local pName="switch-"..cfg.indicators[e].command
            cfg.indicators[e].switch=system.pLoad(pName,nil)
        end
    end

end

--------------------------------------------------------------------
-- Dummy
--------------------------------------------------------------------
local function printForm() end

--------------------------------------------------------------------
-- Dash print loop
--------------------------------------------------------------------
local function showDash(width,height)
    local pX=2
    local pY=2
    for e, n in pairs(cfg.indicators) do
        lcd.drawRectangle(pX,pY,19,19,5)   
        lcd.drawText(pX+3,pY+3,cfg.indicators[e].command,FONT_MINI) 
        lcd.drawText(pX+22,pY,cfg.indicators[e].name)

        if(cfg.indicators[e].indMode==1) then
            local swi  = system.getInputsVal(cfg.indicators[e].switch)
            if(swi and swi==1) then
                stateIcon=":ok"
            else
                stateIcon=":cross"
            end
            lcd.drawImage(pX+130,pY+3,stateIcon)
        end

        if(cfg.indicators[e].indMode==2) then
            if(imgGearDn==nil) then
                imgGearDn=lcd.loadImage("Apps/dashpanl/img/gear-down.png")
            end
            if(imgGearUp==nil) then
                imgGearUp=lcd.loadImage("Apps/dashpanl/img/gear-up.png")
            end
            local swi  = system.getInputsVal(cfg.indicators[e].switch)
            if(swi and swi==1) then
                lcd.drawImage(pX+126,pY,imgGearUp)
            else
                lcd.drawImage(pX+126,pY-1,imgGearDn)
            end
        end

        if(cfg.indicators[e].indMode==3) then
            if(imgFlap0==nil) then
                imgFlap0=lcd.loadImage("Apps/dashpanl/img/flap-0.png")
            end
            if(imgFlapTo==nil) then
                imgFlapTo=lcd.loadImage("Apps/dashpanl/img/flap-to.png")
            end
            if(imgFlapLd==nil) then
                imgFlapLd=lcd.loadImage("Apps/dashpanl/img/flap-ld.png")
            end            
            local swi  = system.getInputsVal(cfg.indicators[e].switch)
            if(swi and swi==1) then
                lcd.drawImage(pX+126,pY,imgFlap0)
            end
            if(swi and swi==0) then
                lcd.drawImage(pX+126,pY-1,imgFlapTo)
            end
            if(swi and swi==-1) then
                lcd.drawImage(pX+126,pY-1,imgFlapLd)
            end
        end
        pY=pY+23
    end
end
--------------------------------------------------------------------
-- Init function
--------------------------------------------------------------------
local function init()
    local appRoot="Apps/dashpanl/"

    modelFile=appRoot.."models/"..system.getProperty("ModelFile")
    local defaultModelFile=appRoot.."models/default.jsn"

    local file = io.readall(modelFile)
    if(file==nil) then
        file = io.readall(defaultModelFile)
    end
    
    cfg = json.decode(file)

    -- load switches from pSaved values
    for e, n in pairs(cfg.indicators) do
        local pLoadName="switch-"..cfg.indicators[e].command
        cfg.indicators[e].switch=system.pLoad(pLoadName,nil)
    end

    dashSizeSelected=cfg.size
    if(cfg.size==1) then 
        indMax=1
    end
    if(cfg.size==2) then
        indMax=3
    end
    indCount=#cfg.indicators
    system.registerTelemetry(1,cfg.dashName,dashSizeSelected,showDash)
    system.registerForm(1, MENU_APPS, trans11.appName, initForm, keyPressed, printForm)

end

setLanguage()
return { init=init, loop=loop, author="DM", version=appVersion,name=trans11.appName}