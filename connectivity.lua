--[[
Program description:
Checks connectivity
Simulates reseting disconnected device after every nth failure
Sends email notification at appropriate timing
]]--


sleep(100)
enableDebug()

-- Global variables  
FXPingFailCount=0
FXRelayCount=0
-- PVPingFailCount=0
-- PVRelayCount=0
RouterPingFailCount=0 
RouterRelayCount=0
ModemPingFailCount=0
ModemRelayCount=0
EmailSent = 0
PingRetries = 10 -- How many times to ping before resetting
RelayRetries = 3 -- How many times to reset device before giving up
NewPingFile = true
PingRunLoop = true -- allow one pass through 30 second loop
PingFileName = "/usb/"..Year.."-"..Month.."-"..Date.."PingLog.txt"

if reg.register20 == 0 then
  pulse("io.relay5",5)
  pulse("io.relay4",125)
  reg.register20 = 1
end

------------------------------Functions
function NewPingFileFunc()
h=file.open(PingFileName,"a")  -- change to fileopen for Lua, with emluation function.
h:write(Year.."-"..Month.."-"..Date.."PingLog\n")
h:write("FXPingFailCount,RouterPingFailCount,ModemPingFailCount\n")
h:close()
end -- function

function emailFunc(recipient,subject, messagebody)
  emailDef = {                                     --send email notification of generator start 
    rcpt = recipient,
    subj = subject,
    body = messagebody
    }
  email(emailDef)
end --function emailFunc

--os.remove(PingFileName) -- keeping this here just in case

------------------------------Main loop
while true do 

  --Begin short duration loop.
  if  Minute % 5 == 0 then -- Loop Every 5 Minutes
    if PingRunLoop then -- allow one run through loop
      print("") -- demarc new loop
      print ("Pinging at: "..Hour..":"..Minute..":"..Second)


----------------------------Router 
    if ping("192.168.60.1",5) == 1 then
      print("router ping succeeded")
      if RouterPingFailCount > 2 then -- must be back on-line
        emailFunc("usr.minister","Router Ping Failure.  Willow back on line.", "")
        RouterRelayCount=0
      end -- if RouterPingCount > 2
        RouterPingFailCount=0  
    else  -- not on line
        RouterPingFailCount=RouterPingFailCount+1
	print("Router ping fail")
	print("Ping count = ",RouterPingFailCount)
    end -- pingresult == 1 then
    ------time for action
    if RouterPingFailCount >= PingRetries and RouterPingFailCount % PingRetries == 0  then -- nth failure
        pulse("io.relay4",5)
        print("pulsing relay")
        i=file.open(PingFileName,"a")  
        i:write("Pulse relay 4\n")
        i:close()
        RouterRelayCount = RouterRelayCount + 1
    end -- RouterPingCount > 2…
 
----------------------------Internet 
   if ping("192.168.60.1",5) == 1 then  -- don't even bother to check modem unless router is on-line
      if ping("8.8.8.8",5) == 1 then
        if ModemPingFailCount > PingRetries then -- must have been off-line
          emailFunc("usr.minister","Modem Ping Failure. Willow back on line.", "")
          ModemRelayCount=0
        end -- if ModemPingCount > 2
         ModemPingFailCount=0 
      else  -- not on line
          print("Modem ping failed")
          print("Ping fail count = ",ModemPingFailCount)
        ModemPingFailCount=ModemPingFailCount+1
      end -- pingresult == 1 then
      ------time for action
      if ModemPingFailCount >= PingRetries and ModemPingFailCount % PingRetries == 0 and ModemRelayCount < RelayRetries then -- nth failure
        pulse("io.relay5",5)
        pulse("io.relay4",120)
        i=file.open(PingFileName,"a")  
        i:write("Pulse relay 4 and 5\n")
        i:close()
        ModemRelayCount = ModemRelayCount + 1
      end -- ModemPingCount > … 
    end --pingresult=ping("192.168.60.1",5) 
    
    ----------------------------FX Mate
    if ping("192.168.60.1",5) == 1 then -- don't even bother to check Mate unless router is on-line  
      if ping("192.168.60.101",5) == 1 then
        FXPingFailCount=0 
      else 
        FXPingFailCount=FXPingFailCount+1
      end -- pingresult...
      ------time for action
      if FXPingFailCount >= PingRetries and FXPingFailCount % PingRetries == 0 and FXRelayCount < RelayRetries then -- nth failure
        pulse("io.relay2",5)
        i=file.open(PingFileName,"a")  
        i:write("Pulse relay 2\n")
        i:close()
        FXRelayCount = FXRelayCount + 1
        emailFunc("usr.minister","FX Ping Failure.", "")
       end -- FXPingCount > PingRetries...
     end --pingresult=ping("192.168.60.1",5) 

----------------------------PV Mate 
    --  if ping("192.168.60.1",5) == 1 then -- don't even bother to check Mate unless router is on-line  
    --   if ping("192.168.60.102",5) == 1 then
    --     PVPingFailCount=0 
    --   else  -- not on line
    --     PVPingFailCount=PVPingFailCount+1 
    --   end -- pingresult 
    --   ------time for action
    --   if PVPingFailCount >= PingRetries and PVPingFailCount % PingRetries == 0 and PVRelayCount < RelayRetries then -- nth failure
    --     pulse("io.relay3",5)
    --     i=file.open(PingFileName,"a")  
    --     i:write("Pulse relay 3\n")
    --     i:close()
    --     PVRelayCount = PVRelayCount + 1
    --     emailFunc("usr.minister","PV Ping Failure.", "")
    --   end -- PVpingCount > PingRetries...
    --  end --pingresult=ping("192.168.60.1",5) 
    

---------------------------------Write lines in the file
      i=file.open(PingFileName,"a")  
      i:write(string.format("%02d",Hour))
      i:write(":")
      i:write(string.format("%02d",Minute))
      i:write(":")
      i:write(string.format("%02d",Second))
      i:write(",")
      i:write(FXPingFailCount)
      i:write(",")
      -- i:write(PVPingFailCount)
      -- i:write(",")
      i:write(RouterPingFailCount)
      i:write(",")
      i:write(ModemPingFailCount)
      i:write("\n")
      i:close()
      PingRunLoop = false -- lock door
    end -- if PingRunLoop == false

  else
    PingRunLoop= true -- If not increment of 5 minutes, unlock door
  end -- if  Minute % 5 == 0
  
   ---------------------------------Midnight
      if Hour < 1 and Minute == 0  then 
        if NewPingFile then -- allows only one pass through this if statement
          PingFileName = "/usb/"..Year.."-"..Month.."-"..Date.."PingLog.txt"
          NewPingFileFunc()
          NewPingFile = false -- lock door
          
        end -- if NewPingFile
      else
        NewPingFile = true -- unlock door
      end-- Midnight NewFile
  
end -- do while...