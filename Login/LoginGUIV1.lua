function pos(...) return term.setCursorPos(...) end
function cls(...) return term.clear() end
function tCol(...) return term.setTextColor(...) end
function bCol(...) return term.setBackgroundColor(...) end
function box(...) return paintutils.drawFilledBox(...) end
function line(...) return paintutils.drawLine(...) end

x,y = term.getSize()

function drawMenu()
    cls()
    pos(1,1)
    box(1,1,x,y,colors.lightBlue) --Background
    box(12,6,40,13,colors.gray) --Login Menu
    line(12,6,40,6,colors.lightGray) -- Top Bar
    line(38,6,40,6,colors.red) --Exit
    line(23,8,38,8,colors.black) --User Field
    line(23,10,38,10,colors.black) -- Pass Field
    line(14,12,20,12,colors.green) --Login
    
    tCol(colors.black)
    bCol(colors.red)
    pos(39,6)
    write("X")
    
    tCol(colors.yellow)
    bCol(colors.gray)
    pos(14,8)
    write("USERNAME")
    pos(14,10)
    write("PASSWORD")
    
    tCol(colors.black)
    bCol(colors.green)
    pos(15,12)
    write("LOGIN")
    
    tCol(colors.white)
    bCol(colors.black)
end

function checkLoginInfo()
    if fs.exits("login.info") then
        return true
    else
        return false
    end
end

function login(login, pass, logins)
    allowed = false
    for i = 1, table.getn(logins) do
        c_login = split(logins[i],"||")

        if login == c_login[1] and pass == c_login[2] then
            allowed = true
        end
    end

    if allowed then
        run = false
    end
end

function split (inputstr, sep)
    if sep == nil then
            sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
            table.insert(t, str)
    end
    return t
end

function main()
    drawMenu()

    logins = {}

    if run then

        loginInfo = fs.open("login.info", "r")

        while true do
            local line = loginInfo.readLine()
            if not line then break end

            logins[#logins + 1] = line
        end
        loginInfo.close()
    end

    while run do
    
        local event, button, mx, my = os.pullEvent()
        if event == "mouse_click" then
        
            if mx >= 23 and mx <= 38 and my == 8 and button == 1 then
                pos(23,8)
                user = read()
                pos(23,10)
                pass = read("*")
                -- login(user, pass)
                -- break
            
            elseif mx >= 23 and mx <= 38 and my == 10 and button == 1 then
                pos(23,10)
                pass = read("*")
                
            elseif mx >= 14 and mx <= 20 and my == 12 and button == 1 then
                login(user, pass, logins)
                -- break

            elseif mx >= 38 and mx <= 40 and my == 6 and button == 1 then
                os.shutdown()
                
            end
        end
    end 
end

run = checkLoginInfo
main()
cls()