--[[
MAX_TEMPERATURE = 10000
REACTOR_OUTPUT_MULT = 10
REACTOR_FUEL_USAGE_MULT = 5
INT_MAX_VALUE = 2147483647

local reactorInfo = reactor.getReactorInfo()
local coreSat = reactorInfo.energySaturation / reactorInfo.maxEnergySaturation
local negCSat = (1 - coreSat) * 99
local temp50 = math.min( (reactorInfo.temperature / MAX_TEMPERATURE) *50, 99)
local tFuel = reactorInfo.maxFuelConversion
local convLVL = ((reactorInfo.fuelConversion / tFuel) * 1.3) - 0.3

-- TEMP CALC --
local tempOffset = 444.7
local tempRiseExpo = (negCSat * negCSat * negCSat) / (100 - negCSat) + tempOffset
local tempRiseResist = (temp50 * temp50 * temp50 * temp50) / (100 - temp50)
local riseAmount = (tempRiseExpo - (tempRiseResist * (1 - convLVL)) + convLVL * 1000) / 10000

-- ENERGY CALC --
local baseMaxRFt = (reactorInfo.maxEnergySaturation / 1000) * REACTOR_OUTPUT_MULT * 1.5 * 10
local maxRFt = baseMaxRFt * (1 + (convLVL * 2))
local generationRate = (1 - coreSat) * maxRFt
local pred_saturation = reactorInfo.energySaturation + generationRate

-- SHIELD CALC --
local tempDrainFactor = 0
if reactorInfo.temperature > 8000 then
    tempDrainFactor = 1 + ((reactorInfo.temperature - 8000) * (reactorInfo.temperature - 8000) * 0.0000025) 
elseif reactorInfo.temperature > 2000 then
    tempDrainFactor = 1 
elseif reactorInfo.temperature > 1000 then 
    tempDrainFactor = (reactorInfo.temperature - 1000) / 1000 
else 
    tempDrainFactor = 0
end

local fieldDrainMath = math.min(tempDrainFactor * math.max(0.01, (1 - coreSat)) * (baseMaxRFt / 10.923556), INT_MAX_VALUE)

local fieldNegPercent = 1 - (reactorInfo.fieldStrength / reactorInfo.maxFieldStrength);
local fieldInputRate = (reactorInfo.fieldDrainRate / fieldNegPercent);
local shieldCharge_pred = reactorInfo.fieldStrength - (math.min(reactorInfo.fieldDrainRate, reactorInfo.fieldStrength));
--]]

--[[
GOAL:
    1. Shielding above 1%
    2. Temp around 8000
    3. Saturation low or less than 100%
--]]

--[[
           _      _____  __  _____  _______      ______                           _       ______                _               _____             _             _ _           
          (_)    |  _  |/  ||  _  ||___  ( )     |  _  \                         (_)      | ___ \              | |             /  __ \           | |           | | |          
  ___ _ __ _ ___  \ V / `| || |/' |   / /|/ ___  | | | |_ __ __ _  ___ ___  _ __  _  ___  | |_/ /___  __ _  ___| |_ ___  _ __  | /  \/ ___  _ __ | |_ _ __ ___ | | | ___ _ __ 
 / __| '__| / __| / _ \  | ||  /| |  / /   / __| | | | | '__/ _` |/ __/ _ \| '_ \| |/ __| |    // _ \/ _` |/ __| __/ _ \| '__| | |    / _ \| '_ \| __| '__/ _ \| | |/ _ \ '__|
| (__| |  | \__ \| |_| |_| |\ |_/ /./ /    \__ \ | |/ /| | | (_| | (_| (_) | | | | | (__  | |\ \  __/ (_| | (__| || (_) | |    | \__/\ (_) | | | | |_| | | (_) | | |  __/ |   
 \___|_|  |_|___/\_____/\___/\___/ \_/     |___/ |___/ |_|  \__,_|\___\___/|_| |_|_|\___| \_| \_\___|\__,_|\___|\__\___/|_|     \____/\___/|_| |_|\__|_|  \___/|_|_|\___|_|   
                                                                                                                                                                              
--]]

-- SETTINGS
-- INPUT_GATE is the flux gate that is pointing INTO the reactor
-- OUTPUT_GATE is the flux gate the is pointing OUT of the reactor
INPUT_GATE_NAME = "flow_gate_1"
OUTPUT_GATE_NAME = "flow_gate_0"

-- CHARGE_RATE is just how much power you want to shove into the reactor when it is charging
-- Note: More power = faster startup
-- Default: 1,000,000
CHARGE_RATE = 1000000

-- MAX_OUTPUT is the maximum energy the reactor will eventually try to pull out
MAX_OUTPUT = 10000000

-- TEMP_TARGET is the target the script will aim to hit
-- MIN_SHIELD is the lowest the script will allow the shield to fall to
TEMP_TARGET = 8000
MIN_SHIELD = 15

-- FAILSAFE enables the auto failsafe on the reactor
FAILSAFE = false

--[[
    DO NOT EDIT ANYTHING BELOW THIS POINT!
    ONLY EDIT SOMETHING IF YOU KNOW WHAT YOU ARE DOING!
--]]

-- VARS FOR GLOBAL
reactor = ""
input_gate = ""
output_gate = ""
MAX_TEMPERATURE = 10000
REACTOR_OUTPUT_MULT = 10
REACTOR_FUEL_USAGE_MULT = 5
INT_MAX_VALUE = 2147483647

-- Registers Peripherals
function find_peripheral(find_type)
    local name_list = peripheral.getNames()
    local i, name
    for i, name in pairs(name_list) do
        if peripheral.getType(name) == find_type then
            return peripheral.wrap(name)
            end
        end
    return null
end

function write_text(text)
    local x,y = term.getCursorPos()
    term.setCursorPos(1,y+1)
    term.write("CDRC > " .. text)
end

function write_error(text)
    local c_colour = term.getTextColour()
    term.clear()
    term.setCursorPos(1,1)
    term.setTextColour(colours.red)
    term.write("CDRC > ERROR: " .. text)
    term.setTextColour(c_colour)
    shell.exit()
end

function register_peripherals()
    reactor = find_peripheral("draconic_reactor")
    input_gate = peripheral.wrap(INPUT_GATE_NAME)
    output_gate = peripheral.wrap(OUTPUT_GATE_NAME)

    -- Check that they are valid error if not
    if reactor == null then
        write_error("REACTOR SETUP INVALID")
    else
        write_text("REACTOR SETUP LOADED!")
    end
    if input_gate == null then
        write_error("INPUT GATE SETUP INVALID")
    else
        write_text("INPUT GATE SETUP LOADED!")
    end
    if output_gate == null then
        write_error("OUTPUT GATE SETUP INVALID")
    else
        write_text("OUTPUT GATE SETUP LOADED!")
    end
end

function get_reactor_info()
    return reactor.getReactorInfo()
end

function round(exact, quantum)
    local quant,frac = math.modf(exact/quantum)
    return quantum * (quant + (frac > 0.5 and 1 or 0))
end

function wait_tick(num)
    sleep(num/20)
end

function newline()
    local x,y = term.getCursorPos()
    term.setCursorPos(1,y+1)
end
function progress_bar(percent, text)
    -- Percent is between 0-10
    -- Every 10% a new marker shows
    term.clearLine()
    local x,y = term.getCursorPos()
    term.setCursorPos(1,y)
    term.write("[".. string.rep("#",round(percent ,1)) ..string.rep("-",round(10-percent ,1)) .."] " .. text)
end

-- This should sucessfully start the reactor
function startup()
    -- These shouldn't be enabled but just in case no need to do it again
    if not input_gate.getOverrideEnabled() then
        input_gate.setOverrideEnabled(true)
    end
    if not output_gate.getOverrideEnabled() then
        output_gate.setOverrideEnabled(true)
    end

    local reactorInfo = get_reactor_info()

    if not reactorInfo.failSafe and FAILSAFE then
        reactor.toggleFailSafe()
    end

    output_gate.setFlowOverride(0)
    input_gate.setFlowOverride(CHARGE_RATE)
    
    newline()
    reactor.chargeReactor() -- Start the charge
    while reactorInfo.temperature < 2000 do
        reactorInfo = get_reactor_info()
        progress_bar((reactorInfo.temperature / 2000) * 10, "TEMP TARGET - "..tostring(reactorInfo.temperature))
        wait_tick(1)
    end
end

function check_state()
    local reactorInfo = get_reactor_info()
    if reactorInfo.status == "charged" or reactorInfo.status == "running" or reactorInfo.status == "online" then
        return true
    else
        return false
    end
end

-- After starting this should take over to handle running paramaters
function running()
    reactor.activateReactor()
    term.clear()
    term.setCursorPos(1,1)
    while check_state() do
        local reactorInfo = get_reactor_info()
        term.setCursorPos(1,1)

        calc_output() -- This should keep the reactor at a constant saturation rate
        calc_shield()
        --input_gate.setFlowOverride(calc_shield()) -- Works out shield cost to meet / remain at target
        progress_bar( (reactorInfo.fieldStrength / reactorInfo.maxFieldStrength) * 10 , "Containment Strength - "..reactorInfo.fieldStrength)
        newline()
        progress_bar( (reactorInfo.temperature / TEMP_TARGET) * 10, "Temperature - "..reactorInfo.temperature)
        newline()
        write_text("Generating :"..tostring(reactorInfo.generationRate - reactorInfo.fieldDrainRate).." RF/t")

        if (reactorInfo.fuelConversion / reactorInfo.maxFuelConversion) * 100 > 90 then
            reactor.stopReactor()
        end
        wait_tick(1)
    end
end

function calc_shield()
    local reactorInfo = get_reactor_info()
    local Min_Shield_Val = reactorInfo.maxFieldStrength*(MIN_SHIELD/100)
    if reactorInfo.fieldStrength < Min_Shield_Val then
        input_gate.setFlowOverride(reactorInfo.fieldDrainRate * 1.3)
    elseif reactorInfo.fieldStrength > Min_Shield_Val then
        input_gate.setFlowOverride(reactorInfo.fieldDrainRate * 0.8)
    else
        input_gate.setFlowOverride(reactorInfo.fieldDrainRate)
    end
end

-- Let us predict power required for shield!
function calc_shield_broke()
    local reactorInfo = get_reactor_info()
    local tempDrainFactor = 0
    if reactorInfo.temperature > 8000 then
        tempDrainFactor = 1 + ((reactorInfo.temperature - 8000) * (reactorInfo.temperature - 8000) * 0.0000025) 
    elseif reactorInfo.temperature > 2000 then
        tempDrainFactor = 1 
    elseif reactorInfo.temperature > 1000 then 
        tempDrainFactor = (reactorInfo.temperature - 1000) / 1000 
    else 
        tempDrainFactor = 0
    end

    local coreSat = reactorInfo.energySaturation / reactorInfo.maxEnergySaturation
    local baseMaxRFt = (reactorInfo.maxEnergySaturation / 1000) * REACTOR_OUTPUT_MULT * 1.5 * 10
    local fieldDrainMath = math.min(tempDrainFactor * math.max(0.01, (1 - coreSat)) * (baseMaxRFt / 10.923556), INT_MAX_VALUE)

    local fieldNegPercent = ( (reactorInfo.maxFieldStrength * (MIN_SHIELD / 100) ) / reactorInfo.maxFieldStrength);
    local fieldInputRate = (fieldDrainMath / fieldNegPercent);

    return fieldInputRate
end

function calc_output()
    local reactorInfo = get_reactor_info()

    if reactorInfo.temperature < TEMP_TARGET and (reactorInfo.energySaturation / reactorInfo.maxEnergySaturation) * 100  > 10 then -- Temp is colder than we want
        -- Bigger value better
        -- Gets smaller closer to target
        --local change_val = (reactorInfo.generationRate * (TEMP_TARGET / reactorInfo.temperature)) + reactorInfo.fieldDrainRate
        --local change_val = (reactorInfo.generationRate * 1.1) + reactorInfo.fieldDrainRate
        local temp_error = ( (TEMP_TARGET - reactorInfo.temperature) / ( (TEMP_TARGET + reactorInfo.temperature) / 2 ) ) * 5 + 1
        local change_val = (reactorInfo.generationRate + reactorInfo.fieldDrainRate) * temp_error
        output_gate.setFlowOverride(change_val)

    elseif (reactorInfo.energySaturation / reactorInfo.maxEnergySaturation) * 100 <= 10 then
        write_text("Warning: Saturation LOW")
        output_gate.setFlowOverride(0)
        newline()
    elseif reactorInfo.temperature > TEMP_TARGET then -- Too Hot!
        -- Smaller value better
        --local change_val = reactorInfo.generationRate * ((TEMP_TARGET / reactorInfo.temperature) * .8) + reactorInfo.fieldDrainRate
        
        --local change_val = reactorInfo.generationRate * .9 + reactorInfo.fieldDrainRate
        local temp_error = ( (TEMP_TARGET - reactorInfo.temperature) / ( (TEMP_TARGET + reactorInfo.temperature) / 2 ) ) * 5 + 1
        local change_val = (reactorInfo.generationRate + reactorInfo.fieldDrainRate) * temp_error
        output_gate.setFlowOverride(change_val)
    else
        output_gate.setFlowOverride(reactorInfo.generationRate + reactorInfo.fieldDrainRate)
    end
end

function shutdown()
    reactor.stopReactor()
    local reactorInfo = get_reactor_info()
    term.clear()
    term.setCursorPos(1,1)
    write_text("Please wait for reactor to cool down.")
    input_gate.setFlowOverride(reactorInfo.fieldDrainRate * 2)
    output_gate.setFlowOverride(0)
    newline()
    local x,y = term.getCursorPos()
    local current_temp = reactorInfo.temperature
    while reactorInfo.status == "stopping" do
        reactorInfo = get_reactor_info()
        if reactorInfo.fieldStrength < 50000000 and reactorInfo.fieldDrainRate < 50000000 then
            input_gate.setFlowOverride(reactorInfo.fieldDrainRate * 1.2)
        end

        if (reactorInfo.energySaturation / reactorInfo.maxEnergySaturation) * 100 > 75 then
            local drain_error = ( ( (reactorInfo.maxEnergySaturation*.75) - reactorInfo.energySaturation ) / ( ( (reactorInfo.maxEnergySaturation*.75) + reactorInfo.energySaturation ) / 2 ) ) + 1
            output_gate.setFlowOverride((reactorInfo.generationRate + reactorInfo.fieldDrainRate) * drain_error)
        else
            local drain_error = ( ( (reactorInfo.maxEnergySaturation*.75) - reactorInfo.energySaturation ) / ( ( (reactorInfo.maxEnergySaturation*.75) + reactorInfo.energySaturation ) / 2 ) ) + 1
            output_gate.setFlowOverride( (reactorInfo.generationRate + reactorInfo.fieldDrainRate) * drain_error )
        end
        term.setCursorPos(1,y)
        progress_bar( (reactorInfo.temperature / current_temp) * 10, "Cooling Progress - "..tostring(reactorInfo.temperature) )
        newline()
        term.setCursorPos(1,y+1)
        progress_bar( (reactorInfo.fieldStrength / 50000000) * 10, "Containment Strength - "..tostring(reactorInfo.fieldStrength) )
        wait_tick(1)
    end
    input_gate.setOverrideEnabled(false)
    output_gate.setOverrideEnabled(false)
    newline()
    write_text("End of Program!")
    newline()
end
-- MAIN
register_peripherals()

local reactorInfo = get_reactor_info()

if reactorInfo.status == "offline" or reactorInfo.status == "cold" or reactorInfo.status == "warming_up" or reactorInfo.status == "cooling" then
    startup()
    running()
    shutdown()
elseif reactorInfo.status == "charged" or reactorInfo.status == "running" or reactorInfo.status == "online" then
    running()
    shutdown()
else
    shutdown()
end