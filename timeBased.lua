-- Script performs: 
-- Provides time data to all other scripts
-- Runs generator in AM based on Start and Stop times
-- Runs generator in PM based on Start time and Stop time and battery voltage over set time
-- Reset registers in case of reboot.  Added 3/24/17.
-- Hi Russell!  Thanks for your help:)
reg.register11 = 6 -- AM Start Hour
reg.register12 = 1 -- AM Start Minute. Normally 0. Flag for reboot.
reg.register13 = 8 -- AM Stop Hour
reg.register14 = 0 -- AM Stop Minute
reg.register15 = 17 -- PM Start Hour
reg.register16 = 0 -- PM Start Minute
reg.register17 = 23 -- PM Stop Hour
reg.register18 = 0 -- PM Stop Min
reg.register5 = 60 -- Target volts
reg.register6 = 120 -- Target minutes

-------------Functions relevant to CBW and Lua
function printfunc(text) print(text) end

-------------Variables relateve to CBW and Lua
local MinuteLoop = true
local MinAtTarget = reg.register7

while true do
    -- Refresh Global variables to service other scripts
    -- currentTime =  os.date("*t") --Uncomment for Lua version    
    currentTime = time.now() -- Uncomment for CBW version
    currentTime = time.getComponents(currentTime) -- Uncomment for CBW version
    Second = currentTime.sec
    Minute = currentTime.min
    Hour = currentTime.hour
    Date = currentTime.mday
    Month = currentTime.month
    Year = currentTime.year
    Day = currentTime.wday

    -- Refresh Local Variables for this script
    local BattV = io.battV
    local AMStartHour = reg.register11
    local AMStartMinute = reg.register12
    local AMStopHour = reg.register13
    local AMStopMinute = reg.register14
    local PMStartHour = reg.register15
    local PMStartMinute = reg.register16
    local PMStopHour = reg.register17
    local PMStopMinute = reg.register18
    local TargetV = reg.register5
    local TargetMin = reg.register6
    local DayMinute = Hour * 60 + Minute
    reg.register1 = io.battV -- CBW
    reg.register2 = io.startCallV -- CBW
    if Second == 0 then -- every minute loop
        if MinuteLoop then -- one time through every minute loop
            printfunc(" ")
            printfunc("Time based process.  " .. Hour .. ":" .. Minute .. ":" ..
                          Second)
            -- printfunc("DayMinute = "..DayMinute)
            -- printfunc("StartMinute = "..AMStartHour*60+AMStartMinute.." or "..PMStartHour*60+PMStartMinute)
            -- printfunc("StopMinute = "..AMStopHour*60+AMStopMinute.." or "..PMStopHour*60+PMStopMinute)

            -- AM start       
            if DayMinute == AMStartHour * 60 + AMStartMinute then
                -- io.relay1 = 1--CBW
                -- printfunc("        Generator Start")
                MinAtTarget = 0
                reg.register7 = MinAtTarget
                -- AM Start

                -- AM Stop
            elseif DayMinute == AMStopHour * 60 + AMStopMinute then
                -- io.relay1 = 0 --CBW
                -- printfunc("        Generator Stop")
                -- AM Stop

                -- PM Start
            elseif DayMinute == PMStartHour * 60 + PMStartMinute then
                -- io.relay1 = 1 --CBW
                -- printfunc("        Generator Start")
                MinAtTarget = 0
                reg.register7 = MinAtTarget
                -- PM Start   

                -- PM Stop on voltage
            elseif MinAtTarget > TargetMin then -- System Charge parameters must be set to achieve this goal
                MinAtTarget = MinAtTarget - 1
                -- io.relay1 = 0 --CBW
                -- printfunc("        Generator Stop")
                -- PM Stop

                -- PM Stop on time
            elseif DayMinute == PMStopHour * 60 + PMStopMinute then
                -- io.relay1 = 0 --CBW
                -- printfunc("        Generator Stop")
                -- PM Stop      

            end --  test for start and stop conditions

            if BattV >= TargetV then --
                MinAtTarget = MinAtTarget + 1
                reg.register7 = MinAtTarget
                -- printfunc("Min at target: "..MinAtTarget)
            end -- if BattV >= TargetV
        end -- if Minute then
        MinuteLoop = false -- after once through, close the door
    else
        MinuteLoop = true
    end -- if Seond == 0 (Once-a-Minute Loop)

end -- while true
