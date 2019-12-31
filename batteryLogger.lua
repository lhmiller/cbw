-- Logging of battery parameters
enableDebug()
sleep(2000) -- allow timeBase script to update

-----------------Variables
local BattRunLoop = true -- allow one pass through 30 second loop
local NewBattFile = true -- allow one pass through midnight routine

------------------------Functions
function newBattFileFunc(FileName)
    g = file.open(FileName, "a") -- change to fileopen for Lua
    g:write(Year .. "-" .. Month .. "-" .. Date .. "BattLog\n")
    g:write("Time,battV,startCallV,HighToday,LowToday\n")
    g:close()
end -- function newGenFile

function emailFunc(recipient, subject, messagebody)
    emailDef = { -- send email notification of generator start 
        rcpt = recipient,
        subj = subject,
        body = messagebody
    }
    email(emailDef)
end -- function emailFunc

------------------------Run once
BattLogFileName = "/usb/" .. Year .. "-" .. Month .. "-" .. Date ..
                      "BatteryLog.txt"
-- os.remove(BattLogFileName) -- uncommnet as needed
------------------------Main loop
while true do
    ---------------------------------Midnight, create new file 
    if Hour == 0 and Minute == 2 then
        if NewBattFile then -- allows only one pass through this if statement.
            print()
            print("New battery log file being created")
            BattLogFileName = "/usb/" .. Year .. "-" .. Month .. "-" .. Date ..
                                  "BatteryLog.txt"
            print(BattLogFileName)
            newBattFileFunc(BattLogFileName)
            reg.register24 = reg.register1
            reg.register25 = reg.register1
            NewBattFile = false

        end -- if NewBattFile == false
    else
        NewBattFile = true
    end --  if Hour == 0 and Minute == 0
    ---------------------------------Logging cycle
    if Minute % 2 == 0 then -- every 2 minute logging
        if BattRunLoop then -- one loop
            ---------------------------------Write lines in the file
            g = file.open(BattLogFileName, "a")
            g:write(string.format("%02d", Hour))
            g:write(":")
            g:write(string.format("%02d", Minute))
            g:write(":")
            g:write(string.format("%02d", Second))
            g:write(",")
            g:write(string.format("%.2f", io.battV))
            g:write(",")
            g:write(string.format("%.2f", io.startCallV))
            g:write(",")
            g:write(string.format("%.2f", reg.register24))
            g:write(",")
            g:write(string.format("%.2f", reg.register25))
            g:write("\n")
            g:close()
            -- print for debug
            print()
            print("Battery Logging at " .. Hour .. ":" .. Minute .. ":" ..
                      Second)

            if io.battV > reg.register24 then -- High today
                reg.register24 = io.battV
            end

            if io.battV < reg.register25 then -- low today
                reg.register25 = io.battV
            end

            if io.battV < 46 and Minute % 5 == 0 then
                -- emailFunc("usr.minister","Battery voltage less than 46 volts", "")
            end

            BattRunLoop = false -- lock door      
        end -- if BattRunLoop == false 

    else
        BattRunLoop = true -- unlock door   
    end -- if Minute % 2 == 0   and Second == 0 
end -- while true  
