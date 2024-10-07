sample_size = 0.1

function round(rnumber, number) return tonumber(string.format(rnumber,number)) end

while true do
    x1, y1, z1 = gps.locate()
    sleep(sample_size)
    
    x2, y2, z2 = gps.locate()
    sleep(sample_size)
    
    distance1 = math.abs(math.sqrt((x1 - x2)^2 + (y1 - y2)^2 + (z1 - z2)^2))
    print(round("%.2f",(distance1/sample_size)),"m/s - Speed")
    sleep(sample_size)
    
    x1, y1, z1 = gps.locate()
    sleep(sample_size)
    
    x2, y2, z2 = gps.locate()
    sleep(sample_size)
    
    distance2 = math.abs(math.sqrt((x1 - x2)^2 + (y1 - y2)^2 + (z1 - z2)^2))
    --print(distance2/sample_size, "m/s - Speed")
    
    velocityDif = distance1 - distance2
    --print(velocityDif/sample_size, "m/s^2 - Accel")
    sleep(sample_size)
end  
