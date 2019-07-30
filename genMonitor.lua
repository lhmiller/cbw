--Monitors generator operation for:
--Generator starting if call-for-start occurs or Generator stopping if call-for-start stops (mismatch)
--Generator run time exceeding preset limit
--Battery Voltage fails to rise after generator start
--When loading script expect false Gen Start and/or Error messages

sleep(5000) -- Required to avoid errors, not sure why

--Variables
local GenRunMinutes = reg.register10
local MismatchCounter = 0
local SecondLoop = true -- allow one pass through 30 second loop
local NewGenFile = true -- allow one pass through midnight routine
local GenChargeStartVolts = reg.register8

--os.remove(GenLogFileName)  -- Comment out once script is running correctly

--------------------------Functions
function newGenFileFunc()
  h=file.open(GenLogFileName,"a")  -- change to fileopen for Lua
  h:write(Year.."-"..Month.."-"..Date.."GenLog\n")
  h:write("Time,GenStartCall,GenRunPrev,GenRun,BatteryVolts,GenChargeStartVolts,Relay1\n")
  h:close()
end -- function newGenFile

function emailFunc(recipient,subject, messagebody)
  emailDef = {                                     --send email notification of generator start 
    rcpt = recipient,
    subj = subject,
    body = messagebody
    }
  email(emailDef)
end --function emailFunc

--------------------------once through
if io.startCallV > 6 then -- establish boolean for Call-for-start signal to match existing conditions.
  GenStartCall = false
else
  GenStartCall = true
end -- if io.startCallV > 6

if io.input1 == 1 then -- establish boolean for generator run to match existing conditions.
  GenRun = true
else  
  GenRun = false
end -- if io.input1 == 1
  GenRunPrev = GenRun
      
GenLogFileName = "/usb/"..Year.."-"..Month.."-"..Date.."GenLog.txt"

--------------------------Main Loop
while true do

  if Second == 15  then -- every 1 minute routine

    if SecondLoop then  -- allows only one pass through loop each cycle.
    
      if io.startCallV > 6 then -- establish boolean for Call-for-start signal each loop
        GenStartCall = false
      else
        GenStartCall = true
      end -- if io.startCallV > 6

      if io.input1 == 1 then -- establish boolean for generator run each loop
        GenRun = true
      else  
        GenRun = false
      end -- if io.input1 == 1
      
      print() -- for debug console
      print("GenMon 1 minute Logging at: "..string.format("%02d",Hour)..":"..string.format("%02d",Minute)..":"..string.format("%02d",Second))

-- write to log file.  Close at end of loop.

      h=file.open(GenLogFileName,"a")  
      h:write(string.format("%02d",Hour))
      h:write(":")
      h:write(string.format("%02d",Minute))
      h:write(":")
      h:write(string.format("%02d",Second))
      h:write(",")
      h:write(tostring(GenStartCall))
      h:write(",")
      h:write(tostring(GenRunPrev))
      h:write(",")
      h:write(tostring(GenRun))
      h:write(",")
      h:write(string.format("%.2f",reg.register1))
      h:write(",")
      h:write(string.format("%.2f",GenChargeStartVolts))
      h:write(",")
      h:write(io.relay1)
      h:write("\n")

------------------------Gen start or stop section.

      if GenRunPrev == false and GenRun == true then     -- Gen started since last cycle
        h:write("Gen start\n")
        GenChargeStartVolts = PrevBatteryVolts            --mark voltage just prior to generator start
        reg.register8 = PrevBatteryVolts
        MinAtTarget = 0 -- Reset this value regardles of which system starts gen
        reg.register7 = MinAtTarget
        emailFunc("usr.minister","Gen Start.", "Battery volts before start="..string.format("%.2f",PrevBatteryVolts))
        GenRunMinutes = 0
      end -- GenRunPrev == false and GenRun == true

      if GenRunPrev == true and GenRun == false  then -- Gen just stopped since last cycle
        h:write("Gen stop\n")
        emailFunc("usr.minister","Gen Stop.", "Battery volts at stop="..string.format("%.2f",PrevBatteryVolts)..". Generator ran "..GenRunMinutes.."minutes.")
      end --GenRunPrev == true and GenRun == false

------------------------Mismatch section. Mismatch means call for start does not match run status.

      if GenStartCall ~= GenRun then  -- Gen not repsonding to call signal.
        MismatchCounter = MismatchCounter + 1
        h:write("Mismatch "..MismatchCounter.."\n")
        if MismatchCounter > 3 and MismatchCounter % 10 == 0 and MismatchCounter < 8  then -- must really be a mismatch, alert every 10 minutes for 4 times
        emailFunc("usr.minister","Gen Mismatch Failure.", "Call for Start does not match gen-run status.")
        end -- MismatchCounter > 3 and MismatchCounter % 20 == 0
      else
        MismatchCounter = 0
      end -- if GenStartCall ~= GenRun

------------------------Gen run-time section.  Establishes run timer and then alerts if time exceeded.
------------------------Also checks to see if battery volts increase by 2 in first 2 minutes of run time.

      if GenRun == true then
         GenRunMinutes = GenRunMinutes + 1  -- presumes routine runs every 1 minute
      end  -- if GenRun == true

      if GenRunMinutes > 480 and GenRunMinutes % 30 == 0 then  -- Excessive run time. Email every 10 minutes
        h:write("Gen Run Time Exceeds time limit "..GenRunMinutes.."\n")
        --emailFunc("usr.minister","Gen Run Time Exceeds 8 hours.", "Gen run minutes= "..GenRunMinutes)
      end -- GenRunMinutes > 480 and GenRunMinutes % 10 == 0
      
      if GenRunMinutes == 2 and GenChargeStartVolts > reg.register1 - 2 then  -- BattV did not increase 2 volts in 2 minutes.  Charge function not working
        h:write("Gen charge failure. "..string.format("%.2f",reg.register1).."\n") -- CBW did not like the reg.register1
        emailFunc("usr.minister","Charge State Failure.", "Global Charge setting may not be correct.")
      end  -- GenRunMinutes == 2 and GenChargeStartVolts > reg.register1 - 2


------------------------Establish states at end of cycle.

      GenRunPrev = GenRun -- Establish existing state at end of cycle
      PrevBatteryVolts = reg.register1 -- Establish existing volts at end of cycle
      reg.register10 = GenRunMinutes
      h:close()

 ---------------------------------Midnight, create new file
 
  if Hour == 0 and Minute == 0  then 
    if NewGenFile then -- allows only one pass through this if statement
      GenLogFileName = "/usb/"..Year.."-"..Month.."-"..Date.."GenLog.txt"
      newGenFileFunc()
      NewGenFile = false
    end -- NewGenFile == false
   else
      NewGenFile = true
   end --Hour == 0 and Minute == 
  end-- Midnight NewFile
  
  SecondLoop = false  -- allows only one pass through loop each cycle.
  else
    SecondLoop= true -- opend for pass through next loop cycle.
  end -- 1 minute cycle
end -- do while...