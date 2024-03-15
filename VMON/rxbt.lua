-- OpenTX Lua script
-- Battery TELEMETRY using RxBt
-- Place this file in SD Card > /SCRIPTS/TELEMETRY/VMON
-- This script requires vmon.lua
-- Designed for 128x64 B&W displays like the Radiomaster Boxer
--
-- https://github.com/pagrey
--
-- Make sure you match the sensor name to the senor name on the TX
-- you can edit them here or on the TX as long as they match
--

-- Battery parameters

local BatteryCells = 2
local VoltageOffset = 3.3
local VoltageMax = 4.2
local VoltageAlarm = 3.8

local SensorOne = "RxBt"
local SensorTwo = "RxBt-"
local SensorThree = "RxBt+"

local function getTelemetryId(name)
 field = getFieldInfo(name)
 if getFieldInfo(name) then return field.id end
  return -1
end


local function initTelemetry()
  local telemetry = { }
  telemetry = {
    BatteryId = getTelemetryId(SensorOne),
    BatteryLowId = getTelemetryId(SensorTwo),
    BatteryHighId = getTelemetryId(SensorThree),
    VoltageAlarm = (VoltageAlarm-VoltageOffset)*BatteryCells*100,
    VoltageMax = VoltageMax*BatteryCells*100,
    VoltageOffset = VoltageOffset*BatteryCells*100,
    VoltageRange = 100
  }
  telemetry.VoltageRange = telemetry.VoltageMax-telemetry.VoltageOffset
  return telemetry
end

local function updateTelemetry(telemetry)
  local data = { }
  data = {
    BatteryVoltage = getValue(telemetry.BatteryId),
    BatteryVoltageHigh = getValue(telemetry.BatteryHighId),
    BatteryVoltageLow = getValue(telemetry.BatteryLowId),
  }
  return data
end

local function drawTelemetry(telemetry, d)
  local data = updateTelemetry(telemetry)
  local VoltageScaled
  if (data.BatteryVoltage*100 < telemetry.VoltageOffset ) then
    VoltageScaled = 0
  elseif (data.BatteryVoltage*100 > telemetry.VoltageMax) then
    VoltageScaled = telemetry.VoltageRange
  else               
    VoltageScaled = data.BatteryVoltage*100 - telemetry.VoltageOffset
  end  
  local BatteryBar = math.floor(((d.TELEMETRY_W-d.MARGIN*2-d.BUTTON_W+d.MARGIN)/(d.BUTTON_W+d.MARGIN) * VoltageScaled / telemetry.VoltageRange)) 
  -- start drawing
  lcd.drawFilledRectangle(d.MARGIN, d.DBL_FONT_SIZE, d.TELEMETRY_W, d.TELEMETRY_H)
  lcd.drawFilledRectangle(d.MARGIN+d.MARGIN, d.DBL_FONT_SIZE+d.DBL_FONT_SIZE+d.MARGIN*2, d.TELEMETRY_W-d.MARGIN*2-d.BUTTON_W, d.TELEMETRY_H-d.DBL_FONT_SIZE-d.MARGIN*3)    
  lcd.drawFilledRectangle(d.MARGIN+d.TELEMETRY_W-d.MARGIN-d.BUTTON_W, d.DBL_FONT_SIZE+d.DBL_FONT_SIZE+d.MARGIN+d.BUTTON_H, d.BUTTON_W, d.BUTTON_H)
  while BatteryBar > 0 do
   lcd.drawFilledRectangle(d.MARGIN+d.MARGIN*2+(BatteryBar-1)*(d.BUTTON_W+d.MARGIN), d.DBL_FONT_SIZE+d.DBL_FONT_SIZE+d.MARGIN*3, d.BUTTON_W, d.TELEMETRY_H-d.DBL_FONT_SIZE-d.MARGIN*5)
   BatteryBar = BatteryBar - 1
  end 
  lcd.drawText(d.INDENT+d.TELEMETRY_W-d.MARGIN*2, d.DBL_FONT_SIZE+d.MARGIN, "V",
 DBLSIZE + RIGHT + INVERS)
  lcd.drawNumber(lcd.getLastLeftPos()-d.MARGIN, d.DBL_FONT_SIZE+d.MARGIN, data.BatteryVoltage*10, DBLSIZE + PREC1 + RIGHT + INVERS)
  if (VoltageScaled > telemetry.VoltageAlarm) then
    lcd.drawText(d.MARGIN, d.DBL_FONT_SIZE+d.TELEMETRY_H+d.MARGIN, SensorOne)
  else
    lcd.drawText(d.MARGIN, d.DBL_FONT_SIZE+d.TELEMETRY_H+d.MARGIN, SensorOne, BLINK)
  end
  lcd.drawText(lcd.getLastPos(), d.DBL_FONT_SIZE+d.TELEMETRY_H+d.MARGIN, ":")
  lcd.drawNumber(lcd.getLastPos(), d.DBL_FONT_SIZE+d.TELEMETRY_H+d.MARGIN,BatteryCells)
  lcd.drawText(lcd.getLastPos(), d.DBL_FONT_SIZE+d.TELEMETRY_H+d.MARGIN, "S")
end

return initTelemetry, updateTelemetry, drawTelemetry
