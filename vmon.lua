-- OpenTX Lua script
-- Battery and RSS TELEMETRY
-- Place this file in SD Card copy on your computer > /SCRIPTS/TELEMETRY/
-- Designed for 128x64 B&W displays like the Radiomaster Boxer
--
-- https://github.com/pagrey
--
-- Make sure you match the sensor name to the senor name on the TX
-- you can edit them here or on the TX as long as they match
--

local SensorOne = "RxBt"
-- local SensorTwo = "RSSI"
-- SensorTwo can be used instead of getRSSI() for RSS1, RSS2 or TRSS

-- Battery parameters

local BatteryCells = 2
local VoltageOffset = 3.3
local VoltageMax = 4.2
local VoltageAlarm = 3.8

-- Alarm voltage flashes the sensor name when below this threshold

-- RSSI threshold values

local RSS_A = 89
local RSS_B = 74
local RSS_C = 59
local RSS_D = 44 -- alert_low is used here

-- Nothing to configure below this point

local BatteryVoltage
-- local RSS = 0
local rssi, alarm_low, alarm_crit
local RunClock = 0
local BackgroundClock = 0
local batt_id
-- local rssi_id

-- display parameters

local Batt_H = 21
local Batt_W = 69
local Margin = 2
local Indent = 9
local DBL_H = 16
local SML_H = 8
local MID_H = 12
local Butn_W = 3
local Butn_H = 7
local Time_X = 53
local Signal_W = 7
local Signal_H = 20

local function drawBattery(x, y, w, h, v, r)
  local SignalBars = math.floor((12 * v / r)+0.1) 
  lcd.drawFilledRectangle( x, y, w - Butn_W, h )
  lcd.drawFilledRectangle(x + w - Margin - 1 , y + Butn_H - Margin, Butn_W, Butn_H)
  while SignalBars > 0 do
   lcd.drawFilledRectangle( x+2+(SignalBars -1)*5, y + Margin, Butn_W, Batt_H - Margin*4)
   SignalBars = SignalBars - 1
  end 
end

local function init()
  -- init is called once when model is loaded
  VoltageAlarm = (VoltageAlarm-VoltageOffset)*BatteryCells*100
  VoltageMax = VoltageMax*BatteryCells*100
  VoltageOffset = VoltageOffset*BatteryCells*100
  VoltageRange = VoltageMax-VoltageOffset
  -- BatteryVoltage = getValue(SensorOne)
  batt_id = getFieldInfo(SensorOne).id 
  BatteryVoltage = getValue(batt_id)
  rssi, alarm_low, alarm_crit = getRSSI()
  -- RSS = getValue(SensorTwo)
  -- rssi_id = getFieldInfo(SensorTwo).id 
  -- RSS = getValue(rssi_id)
end

local function background()
  -- background is called periodically
  if (BackgroundClock % 16 == 0) then
    -- BatteryVoltage = getValue(SensorOne)
    BatteryVoltage = getValue(batt_id)
    rssi, alarm_low, alarm_crit = getRSSI()
    BackgroundClock = 0
  end
  BackgroundClock = BackgroundClock + 1
end

local function run(event)
  -- run is called periodically only when screen is visible

  if (RunClock % 2 == 0) then
    local SignalBars = -1
    local VoltageScaled

--  RSS = getValue(SensorTwo)
--  RSS = getValue(rssi_id)

    if (BatteryVoltage*100 < VoltageOffset ) then
      VoltageScaled = 0
    elseif (BatteryVoltage*100 > VoltageMax) then
  	VoltageScaled = VoltageRange
    else
      VoltageScaled = BatteryVoltage*100 - VoltageOffset
    end

    -- LCD / Display code
    lcd.clear()

    -- Draw title and background
    lcd.drawText( Indent+1, 0, model.getInfo()['name'], DBLSIZE)
    lcd.drawFilledRectangle(Indent, DBL_H, Batt_W, DBL_H+Batt_H)

    -- Draw battery
    drawBattery( Indent+Margin, DBL_H+DBL_H+Margin, Batt_W-Margin-Margin, Batt_H-Margin-Margin, VoltageScaled, VoltageRange)

    -- Draw voltage
    lcd.drawText( Batt_W+Indent-1, DBL_H+1, "V", DBLSIZE + RIGHT + INVERS)
    lcd.drawNumber( lcd.getLastLeftPos()-Margin, DBL_H+1, BatteryVoltage*10, DBLSIZE + PREC1 + RIGHT + INVERS)
    if (VoltageScaled > VoltageAlarm) then
      lcd.drawText( Indent, DBL_H+DBL_H+Batt_H+Margin, SensorOne)
    else
      lcd.drawText( Indent, DBL_H+DBL_H+Batt_H+Margin, SensorOne, BLINK)
    end

    -- Draw timer
    -- lcd.drawText( Batt_W+Indent+Margin*2, DBL_H+DBL_H, model.getTimer(0).name)
    lcd.drawTimer( Batt_W+Indent+Margin*2, DBL_H+1, model.getTimer(0).value, DBLSIZE)

    -- Draw time
    lcd.drawText( Time_X, LCD_H-SML_H+1, string.format("%02d", getDateTime()['hour']))
    lcd.drawText( lcd.getLastPos(), LCD_H-SML_H+1, ":", BLINK)
    lcd.drawText( lcd.getLastPos(), LCD_H-SML_H+1, string.format("%02d", getDateTime()['min']))

      -- Draw RSSI
    if rssi > alarm_crit then
      lcd.drawText( Batt_W+Indent+Margin*2, DBL_H+DBL_H+Batt_H+Margin, "RSSI")
      lcd.drawText(lcd.getLastPos(), DBL_H+DBL_H+Batt_H+Margin, ":")
      lcd.drawNumber(lcd.getLastPos(), DBL_H+DBL_H+Batt_H+Margin, rssi)
    else
      lcd.drawText( Batt_W+Indent+Margin*2, DBL_H+DBL_H+Batt_H+Margin, "RSSI", BLINK)
      lcd.drawText(lcd.getLastPos(), DBL_H+DBL_H+Batt_H+Margin, ":",BLINK)
      lcd.drawNumber(lcd.getLastPos(), DBL_H+DBL_H+Batt_H+Margin, rssi,BLINK)
    end
    if rssi > RSS_A then
      SignalBars = 3
    elseif rssi > RSS_B then
      SignalBars = 2
    elseif rssi > RSS_C then
      SignalBars = 1
    elseif rssi > alarm_low then
      SignalBars = 0
    end
    while SignalBars > -1 do
    lcd.drawFilledRectangle( (Batt_W+Indent+Margin*2)+(SignalBars)*(Signal_W+Margin*2), DBL_H+DBL_H+Batt_H-Signal_H+(3-SignalBars)*(Signal_H/4), Signal_W, Signal_H-(3-SignalBars)*(Signal_H/4))
    SignalBars = SignalBars - 1
    end
    RunClock = 0
  end
  RunClock = RunClock + 1
end

return { run = run, background = background, init = init }
