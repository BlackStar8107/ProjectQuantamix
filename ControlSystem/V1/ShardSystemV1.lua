
-- VARS
serverId = 0
 
-- Literally a Generic func to make sure rednet is on
function setModem()
    local modem = peripheral.find("modem")
    local modemOpen = rednet.isOpen(modem)

    if not modemOpen then
        rednet.open(modem)
        return true

    elseif modemOpen then
        return true

    else
        return false -- This is here JUST IN CASE
    end
end

-- I am using directions imagining the computer like so (looking top down):
--   N
-- E C W
--   S
--

function getInputs()
    -- Hypothetically there may be blank side so a table SHOULD let us ignore this
    inputs = {
        North = redstone.getBundledInput("back"),
        West = redstone.getBundledInput("left"),
        South = redstone.getBundledInput("front"),
        East = redstone.getBundledInput("right")
    }

    -- for i, v in pairs(inputs) do
    --     print(i .. " > ".. v)
    -- end

    values = {
        North = dump_b16_2(redstone.getBundledInput("back")),
        West = dump_b16_2(redstone.getBundledInput("left")),
        South = dump_b16_2(redstone.getBundledInput("front")),
        East = dump_b16_2(redstone.getBundledInput("right"))
    }

    for i, v in pairs(values) do
        print(i)
        for j, b in pairs(v) do
            print(j .. " > ".. b)
        end
    end

end

-- Turns decimal to binary
-- RETURNS A TABLE
-- Currently goes from LARGEST base to SMALLEST base
function dump_b16_2(n)
    local table = {}
    local i = 0

    i = math.log(n) / math.log(2)

    for j = math.floor ( i + 1), 0 , -1 do
        table[#table + 1] = math.floor(n / 2 ^ j)
        n = n % 2 ^ j
    end

    return table
end
 
--  dump_b16(65535)
getInputs()