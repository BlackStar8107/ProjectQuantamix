delay = 0.1
roundS = "%.2f"

function round(rnumber, number) return tonumber(string.format(rnumber,number)) end

function calcDist(c1, c2) return math.abs( math.sqrt( (c1[1] - c2[1]) ^ 2 + (c1[2] - c2[2]) ^ 2 + (c1[3] - c2[3]) ^ 2 ) ) end

function calcCoords() c1 = {gps.locate()} sleep(delay) c2 = {gps.locate()} return calcDist(c1,c2) end

function getDist() local c1 = {gps.locate()} sleep(delay) local c2 = {gps.locate()} return calcDist(c1,c2) end

function checkTerminate()
    local event = os.pullEventRaw("terminate")
    if event == "terminate" then
        term.setCursorPos(1,3)
        term.setTextColour(colours.yellow)
        term.write("> ")
        term.setTextColour(colours.red)
        term.write("END OF PROGRAM")
        term.setTextColour(colours.white)
        term.setCursorPos(1,4)
    end
end

function main()
    term.clear()
    while true do
        local dist1 = getDist() / delay

        term.setCursorPos(1,1)
        local dist2 = getDist() / delay
        print(round(roundS,dist2), "m/s - Speed          ") -- Final V

        print(round(roundS,dist2 - dist1), "m/s^2 - Accel          ")
    end
end

parallel.waitForAny( checkTerminate, main )