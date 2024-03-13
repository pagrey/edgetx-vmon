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
local SensorTwo = "RxBt-"
local SensorThree = "RxBt+"
local is_telemetry = false

-- Battery parameters

local BatteryCells = 2
local VoltageOffset = 3.3
local VoltageMax = 4.2
local VoltageAlarm = 3.8

-- Alarm voltage flashes the sensor name when below this threshold

-- RSSI threshold values

local RSSI_HIGH = 89
local RSSI_MED = 74
local RSSI_LOW = 59
local RSSI_CRITICAL = 44 -- alert_low is used here

-- Nothing to configure below this point

local BatteryVoltage, BatteryVoltageHigh, BatteryVoltageLow
local rssi, alarm_low, alarm_crit
local RunClock = 0
local BackgroundClock = 0
local batt_id, batt_low_id, batt_high_id

-- display parameters

local Telemetry_H = 38
local Telemetry_W = 74
local Margin = 2
local Title_Indent = 10
local Indent = 4
local DBL_H = 16
local SML_H = 8
local MID_H = 12
local Time_X = 53
local RSSI_W = 38
local Signal_H = LCD_H-DBL_H*2-MID_H

--local rxbt = loadScript("/SCRIPTS/TELEMETRY/VMON/rxbt.lua")
--local gt = rxbt()

local function getTelemetryId(name)
 field = getFieldInfo(name)
 if getFieldInfo(name) then return field.id end
  return -1
end

local function backgroundTelemetry()
  BatteryVoltage = getValue(batt_id)
  BatteryVoltageHigh = getValue(batt_high_id)
  BatteryVoltageLow = getValue(batt_low_id)
  rssi, alarm_low, alarm_crit = getRSSI()
end

local function initTelemetry()
  is_telemetry = getTelemetryId(SensorOne) > -1
  if (is_telemetry) then
    VoltageAlarm = (VoltageAlarm-VoltageOffset)*BatteryCells*100
    VoltageMax = VoltageMax*BatteryCells*100
    VoltageOffset = VoltageOffset*BatteryCells*100
    VoltageRange = VoltageMax-VoltageOffset
    batt_id = getTelemetryId(SensorOne) 
    batt_low_id = getTelemetryId(SensorTwo)
    batt_high_id = getTelemetryId(SensorThree)
    backgroundTelemetry()
  end
end

local function drawRSSI(x, y, w, h)
    -- Draw RSSI
    local barwidth = (w-Margin*5)/4
    local SignalBars = -1
    if rssi > alarm_crit then
      lcd.drawText( Telemetry_W+Indent+Margin*2, DBL_H+Telemetry_H+Margin, "RSSI")
      lcd.drawText(lcd.getLastPos(), DBL_H+Telemetry_H+Margin, ":")
      lcd.drawNumber(lcd.getLastPos(), DBL_H+Telemetry_H+Margin, rssi)
    else
      lcd.drawText( Telemetry_W+Indent+Margin*2, DBL_H+Telemetry_H+Margin, "RSSI", BLINK)
      lcd.drawText(lcd.getLastPos(), DBL_H+Telemetry_H+Margin, ":",BLINK)
      lcd.drawNumber(lcd.getLastPos(), DBL_H+Telemetry_H+Margin, rssi,BLINK)
    end
    if rssi > RSSI_HIGH then
      SignalBars = 3
    elseif rssi > RSSI_MED then
      SignalBars = 2
    elseif rssi > RSSI_LOW then
      SignalBars = 1
    elseif rssi > alarm_low then
      SignalBars = 0
    end
    while SignalBars > -1 do
     lcd.drawFilledRectangle( (x)+(SignalBars)*(barwidth+Margin*2), y-h+(3-SignalBars)*(h/4), barwidth, h-(3-SignalBars)*(h/4))
      SignalBars = SignalBars - 1
    end
end

local function drawTelemetry(x, y, w, h)
  local Butn_W = 3
  local Butn_H = 7
  local VoltageScaled
  if (BatteryVoltage*100 < VoltageOffset ) then
    VoltageScaled = 0
  elseif (BatteryVoltage*100 > VoltageMax) then
    VoltageScaled = VoltageRange
  else
    VoltageScaled = BatteryVoltage*100 - VoltageOffset
  end
  local SignalBars = math.floor((12 * VoltageScaled / VoltageRange)+0.1) 
  lcd.drawFilledRectangle(x, y, w, h)
  lcd.drawFilledRectangle(x+Margin, y+DBL_H+Margin*2, w-Margin*2-Butn_W, h-DBL_H-Margin*3)
  lcd.drawFilledRectangle(x+w-Margin-Butn_W, y+DBL_H+Margin+Butn_H, Butn_W, Butn_H)
  while SignalBars > 0 do
   lcd.drawFilledRectangle(x+Margin*2+(SignalBars-1)*5, y+DBL_H+Margin*3, Butn_W, h-DBL_H-Margin*5)
   SignalBars = SignalBars - 1
  end 
  lcd.drawText(Indent+w-Margin, y+Margin, "V", DBLSIZE + RIGHT + INVERS)
  lcd.drawNumber(lcd.getLastLeftPos()-Margin, y+Margin, BatteryVoltage*10, DBLSIZE + PREC1 + RIGHT + INVERS)
  if (VoltageScaled > VoltageAlarm) then
    lcd.drawText(x, y+h+Margin, SensorOne)
  else
    lcd.drawText(x, y+h+Margin, SensorOne, BLINK)
  end
  lcd.drawText(lcd.getLastPos(), y+h+Margin, ":")
  lcd.drawNumber(lcd.getLastPos(), y+h+Margin, BatteryCells)
  lcd.drawText(lcd.getLastPos(), y+h+Margin, "S")
end

local function drawBasicScreen()
    lcd.clear()
    -- Draw title and background
    lcd.drawText(Title_Indent, 0, model.getInfo()['name'], DBLSIZE)
    -- Draw time
    lcd.drawText(Time_X, LCD_H-SML_H+1, string.format("%02d", getDateTime()['hour']))
    lcd.drawText(lcd.getLastPos(), LCD_H-SML_H+1, ":", BLINK)
    lcd.drawText(lcd.getLastPos(), LCD_H-SML_H+1, string.format("%02d", getDateTime()['min']))

end

local function drawMainScreen()
    -- Draw telemetry
    drawTelemetry(Indent, DBL_H, Telemetry_W, Telemetry_H)

    -- Draw timer
    local timer_name = model.getTimer(0).name
    if (timer_name ~= "") then
      lcd.drawText(LCD_W-Indent-Margin, DBL_H-SML_H+Margin, timer_name, SMLSIZE + RIGHT)
      lcd.drawTimer(Telemetry_W+Indent+Margin*2, DBL_H+1, model.getTimer(0).value, DBLSIZE)
    end

    -- Draw RSSI
    drawRSSI(Telemetry_W+Indent+Margin*2, DBL_H+Telemetry_H, RSSI_W, LCD_H-DBL_H*2-MID_H)
end

local function run(event)
  -- run is called periodically only when screen is visible
  if(is_telemetry) then
    if (RunClock % 2 == 0) then
      drawBasicScreen()
      drawMainScreen()
      if (RunClock % 16 == 0) then
        backgroundTelemetry()
        RunClock = 0
      end
    end
    RunClock = RunClock + 1
  else
    drawBasicScreen()
    lcd.drawText(Indent, DBL_H+Margin, "Waiting for telemetry...")
    initTelemetry()
  end
end

return { run = run }
