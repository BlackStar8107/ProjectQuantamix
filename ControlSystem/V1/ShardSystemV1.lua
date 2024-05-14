
-- Can't actually log this because this is done before log init
function getConfig()
    local configName = "Shard.ini"
    local configBool = fs.exists(configName)
    if configBool then
        local configFile = fs.open(configName,"r")
        local configRaw = configFile.readAll()
        local config = textutils.unserialiseJSON(configRaw)
        configFile.close()
        return config
    else
        local configRaw = {
            serverId = 5,
            log_name = "Shard.log",
            debug = false,
            protocol = "Shard"
        }
        local configFile = fs.open(configName,"w")
        local config = textutils.serialiseJSON(configRaw)
        configFile.write(config)
        configFile.close()
        return configRaw
    end
end

-- Literally a Generic func to make sure rednet is on
function setModem()

    local modemOpen = rednet.isOpen() -- I hate that this is how I have to do it

    if not modemOpen then
        peripheral.find("modem",rednet.open)
        log("Modem opened.","INFO")
        reportStatus()
        return true

    elseif modemOpen then
        log("Modem was already open!","WARN")
        reportStatus()
        return true

    else
        return false -- This is here JUST IN CASE
    end
end

-- Basically a test to make sure we can send pings to the server
-- This is UDP so we don't know if the server recieves
function reportStatus()
    local sendBool = rednet.send(config.serverId, "Shard is now online!", config.protocol)
    log("Sending shard ping!", "INFO")
    if not sendBool then
        log("Unknown Error sending shard ping!", "ERROR")
        error("Unable to send shard ping!")
        printError("TERMINATING")
        shell.exit()
    end
end

function sendReport(inputTable)
    local text = textutils.serialiseJSON(inputTable)
    local sendBool = rednet.send(config.serverId,"0|"..text.."|"..os.getComputerID(),config.protocol)
    log("Sending shard report0!", "INFO")
    if not sendBool then -- If this doesn't work maybe panic basically
        log("Unknown Error sending shard report!", "ERROR")
        error("Unable to send shard ping!")
        printError("Attempting to reconfigure modem!")
        -- Hoping a reset will work else it'll die
        setModem()
        reportStatus()
    end
end

-- Turns out I debug recursive tables lots.. joy
function printTable(table, doPrint)
    for k,v in pairs(table) do
        if type(v) == "table" then
            log(k.." "..type(v))
            printTable(v)
        elseif type(v) == "string" then
            if doPrint ~= nil and doPrint then
                print(k,v)
            end
            log(k.." "..v)
        else
            if doPrint ~= nil and doPrint then
                print(k,v)
            end
            log(k.." "..type(v))
        end
    end
end

-- So discovered I don't actually need this because we can already serialise
-- But I like it so it stays >:)
function compileTable(table)
    local index = 1
    local holder = "{"
    while true do
       if type(table[index]) == "function" then
          index = index + 1
       elseif type(table[index]) == "table" then
          holder = holder..compileTable(table[index])
       elseif type(table[index]) == "number" then
          holder = holder..tostring(table[index])
       elseif type(table[index]) == "string" then
          holder = holder.."\""..table[index].."\""
       elseif table[index] == nil then
          holder = holder.."nil"
       elseif type(table[index]) == "boolean" then
          holder = holder..(table[index] and "true" or "false")
       end
       if index + 1 > #table then
         break
       end
       holder = holder..","
       index = index + 1
    end
    return holder.."}"
 end

-- No idea how but turns out this can fail sometimes
function initLog()
    local file = fs.open(config.log_name, "w")
    if file == nil or type(file) == "string" then
        printError("Error initialising log!")
        if type(file) == "string" then
            error("Traceback: "..file)
        end
        printError("TERMINATING")
        shell.exit()
    else
        file.close()
        log("Logging Started!","INFO")
    end
end

-- Just writes to a log file
-- Although not strict on this, I propose the following:
-- DEBUG -> INFO -> WARN -> ERROR
-- Debug being weird shit we might want to know to follow the program eg.. changes in variables during equations
-- Info being similar but destinctivly important eg.. outputs of functions
-- Warn being something already set or other oddities eg.. Things being configured correctly? Like modems
-- Error being.. well an error something wrong eg.. Looks wrong to have nothing here :3
function log(text, level)
    local file = fs.open(config.log_name,"a")
    if (level == nil or level == "DEBUG") and config.debug then
        file.write(os.date("%F - %T").." || ".."DEBUG".." >> "..text.."\n")
    elseif level ~= nil then
        file.write(os.date("%F - %T").." || "..level.." >> "..text.."\n")
    end
    file.close()
end

-- I am using directions imagining the computer like so (looking top down):
--   N
-- E C W
--   S
--
function getInputs()
    -- If there is a null input it will always return as 0
    cables = {
        North = {input = redstone.getBundledInput("back"), binary = {}},
        West = {input = redstone.getBundledInput("left"), binary = {}},
        South = {input = redstone.getBundledInput("front"), binary = {}},
        East = {input = redstone.getBundledInput("right"), binary = {}}
    }

    for dir, obj in pairs(cables) do
        obj.binary = dump_b16_2(obj.input) -- Returns our TABLE of binary
    end

    printTable(cables)
    if config.debug then
        print(compileTable(cables))
    end

    return cables
end

-- Turns decimal to binary
-- RETURNS A TABLE
-- Currently goes from LARGEST base to SMALLEST base
function dump_b16_2(n)
    local table = {}
    local i = 0

    i = math.log(n) / math.log(2)

    log("i : "..i)

    for j = math.floor ( i + 1), 0 , -1 do
        log("j : "..j)
        table[#table + 1] = math.floor(n / 2 ^ j)
        log("new table val : "..table[#table])
        n = n % 2 ^ j
        log("n : "..n)
    end

    -- This SHOULD pad out or trim our values down to ~8 bits
    if #table - 8  ~= 0 then
        local new_table = {}
        if #table > 8 then
            log("Table larger than 8!", "WARN")
            log("Table size: "..#table, "WARN")
            for i = #table - 8, #table, 1 do
                new_table[#new_table + 1] = table[i]
                log("new table val: "..new_table[#new_table])
            end
        elseif #table < 8 then
            log("Table smaller than 8!", "WARN")
            log("Table size: "..#table, "WARN")
            for i = 1, 8 - #table do
                new_table[#new_table + 1] = 0
                log("New table val: "..i..">"..new_table[#new_table],"INFO")
            end

            for i = 1, #table do
                new_table[#new_table + 1] = table[i]
                log("New table val: "..i..">"..new_table[#new_table],"INFO")
            end
        end
        table = new_table
    end

    return table
end

-- Big spooky main init point
function main()

    _G.config = getConfig()

    initLog()

    setModem()
    
    while true do
        if os.pullEvent("redstone") == "redstone" then 
            local cableInputs = getInputs()
            sendReport(cableInputs)
        end
    end
end


main()