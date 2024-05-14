
-- VARS
serverId = 0
debug = false
log_name = "Shard.log"

-- Literally a Generic func to make sure rednet is on
function setModem()

    local modemOpen = rednet.isOpen() -- I hate that this is how I have to do it

    if not modemOpen then
        peripheral.find("modem",rednet.open)
        log("Modem opened.","INFO")
        return true

    elseif modemOpen then
        log("Modem was already open!","WARN")
        return true

    else
        return false -- This is here JUST IN CASE
    end
end

-- Turns out I debug recursive tables lots.. joy
function printTable(table)
    for k,v in pairs(table) do
        if type(v) == "table" then
            log(k.." "..type(v))
            printTable(v)
        elseif type(v) == "string" then
            print(k,v)
            log(k.." "..v)
        else
            print(k,v)
            log(k.." "..type(v))
        end
    end
end

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
 
function tableToString(tab)
    local serializedValues = {}
    local value, serializedValue
    for i=1,#tab do
      value = tab[i]
      serializedValue = type(value)=='table' and serialize(value) or value
      table.insert(serializedValues, serializedValue)
    end
    local out = string.format("{ %s }", table.concat(serializedValues, ', ') )
    log(out,"INFO")
    return out
end

-- No idea how but turns out this can fail sometimes
function initLog()
    local file = fs.open(log_name, "w")
    if file == nil or type(file) == "string" then
        printError("Error initialising log!")
        if type(file) == "string" then
            printError("Traceback: "..file)
        end
        shell.exit()
    else
        file.close()
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
    local file = fs.open(log_name,"a")
    if (level == nil or level == "DEBUG") and debug then
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

    if debug then
        printTable(cables)
        print(compileTable(cables))
    end
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

    initLog()

    setModem()
    
    while true do
        if os.pullEvent("redstone") == "redstone" then 
            getInputs()
        end
    end
end

main()