-- OpenTX Lua script
-- Battery and RSS TELEMETRY
-- Place this file in SD Card copy on your computer > /SCRIPTS/TELEMETRY/
-- Designed for 128x64 B&W displays like the Radiomaster Boxer
--
-- https://github.com/pagrey
--

-- Sensor name

local SensorOne = "RxBt"

-- RSSI threshold values
-- low and critical are read from the radio

local RSSI_HIGH = 89
local RSSI_MED = 74

local RunClock = 0
local is_telemetry = false
local is_debug = false

-- display constants
local DISPLAY_CONST = { }
DISPLAY_CONST = {
  TELEMETRY_H = 38,
  TELEMETRY_W = 74,
  MARGIN = 2,
  INDENT = 4,
  TITLE_INDENT = 10,
  TIME_INDENT = 53,
  DBL_FONT_SIZE = 16,
  SML_FONT_SIZE = 8,
  MID_FONT_SIZE = 12,
  RSSI_W = 38
}

local function getTelemetryId(name)
 field = getFieldInfo(name)
 if getFieldInfo(name) then return field.id end
  return -1
end

local function initTelemetry()

-- Battery parameters

  local BatteryCells, VoltageAlarm, VoltageOffset
  local VoltageMax = 4.2

-- Model cell count and battery thresholds

  local OneCell = {
    DLG950 = true
  }
  local ModelInfo = model.getInfo()
  if (OneCell[ModelInfo.name]) then
    BatteryCells = 1
    VoltageAlarm = 3.4
    VoltageOffset = 3.0
  else
    BatteryCells = 2
    VoltageAlarm = 3.4
    VoltageOffset = 3.0
  end 
  local telemetry = { }
  telemetry = {
    BatteryId = getTelemetryId(SensorOne),
    BatteryLowId = getTelemetryId(SensorOne .. "-"),
    BatteryHighId = getTelemetryId(SensorOne .. "+"),
    VoltageAlarm = (VoltageAlarm-VoltageOffset)*BatteryCells*100,
    VoltageMax = VoltageMax*BatteryCells*100,
    VoltageOffset = VoltageOffset*BatteryCells*100,
    VoltageRange = 100
  }
  telemetry.VoltageRange = telemetry.VoltageMax-telemetry.VoltageOffset
  local data = { }
  return telemetry, data
end

local function updateTelemetry(telemetry, data)
  data = {
    BatteryVoltage = getValue(telemetry.BatteryId),
    BatteryVoltageHigh = getValue(telemetry.BatteryHighId),
    BatteryVoltageLow = getValue(telemetry.BatteryLowId),
  }
  return data
end

local function drawTelemetry(telemetry, data, d)
  local BUTTON_W = 3 
  local BUTTON_H = 7
  local SEGMENTS = 9
  local BatteryWidth = d.TELEMETRY_W-d.MARGIN*3-BUTTON_W 
  local SegmentWidth = math.floor(BatteryWidth/SEGMENTS)
  local VoltageScaled
  if (data.BatteryVoltage*100 < telemetry.VoltageOffset ) then
    VoltageScaled = 0
  elseif (data.BatteryVoltage*100 > telemetry.VoltageMax) then
    VoltageScaled = telemetry.VoltageRange
  else               
    VoltageScaled = data.BatteryVoltage*100 - telemetry.VoltageOffset
  end  
  local BatteryBar = math.floor(SEGMENTS * VoltageScaled / telemetry.VoltageRange) 
  -- start drawing
  lcd.drawFilledRectangle(d.MARGIN, d.DBL_FONT_SIZE, d.TELEMETRY_W, d.TELEMETRY_H)
  lcd.drawFilledRectangle(d.MARGIN+d.MARGIN, d.DBL_FONT_SIZE+d.DBL_FONT_SIZE+d.MARGIN*2, d.TELEMETRY_W-d.MARGIN*2-BUTTON_W, d.TELEMETRY_H-d.DBL_FONT_SIZE-d.MARGIN*3)    
  lcd.drawFilledRectangle(d.MARGIN+d.TELEMETRY_W-d.MARGIN-BUTTON_W, d.DBL_FONT_SIZE+d.DBL_FONT_SIZE+d.MARGIN+BUTTON_H, BUTTON_W, BUTTON_H)
  while BatteryBar > 0 do
   lcd.drawFilledRectangle(d.MARGIN*3+(BatteryBar-1)*(SegmentWidth), d.DBL_FONT_SIZE+d.DBL_FONT_SIZE+d.MARGIN*3, SegmentWidth-d.MARGIN, d.TELEMETRY_H-d.DBL_FONT_SIZE-d.MARGIN*5)
   BatteryBar = BatteryBar - 1
  end 
  lcd.drawText(d.INDENT+d.TELEMETRY_W-d.MARGIN*2, d.DBL_FONT_SIZE+d.MARGIN, "V", DBLSIZE + RIGHT + INVERS)
  lcd.drawNumber(lcd.getLastLeftPos()-d.MARGIN, d.DBL_FONT_SIZE+d.MARGIN, data.BatteryVoltage*10, DBLSIZE + PREC1 + RIGHT + INVERS)
  if (VoltageScaled > telemetry.VoltageAlarm) then
    lcd.drawText(d.MARGIN, d.DBL_FONT_SIZE+d.TELEMETRY_H+d.MARGIN, SensorOne)
  else
    lcd.drawText(d.MARGIN, d.DBL_FONT_SIZE+d.TELEMETRY_H+d.MARGIN, SensorOne, BLINK)
  end
  lcd.drawText(lcd.getLastPos(), d.DBL_FONT_SIZE+d.TELEMETRY_H+d.MARGIN, ":")
  lcd.drawNumber(lcd.getLastPos(), d.DBL_FONT_SIZE+d.TELEMETRY_H+d.MARGIN,telemetry.VoltageMax/420)
  lcd.drawText(lcd.getLastPos(), d.DBL_FONT_SIZE+d.TELEMETRY_H+d.MARGIN, "S")
end


local function drawBasicScreen(d)
    lcd.clear()
    -- Draw title and background
    lcd.drawText(d.TITLE_INDENT, 0, model.getInfo()['name'], DBLSIZE)
    -- Draw time
    lcd.drawText(d.TIME_INDENT, LCD_H-d.SML_FONT_SIZE+1, string.format("%02d", getDateTime()['hour']))
    lcd.drawText(lcd.getLastPos(), LCD_H-d.SML_FONT_SIZE+1, ":", BLINK)
    lcd.drawText(lcd.getLastPos(), LCD_H-d.SML_FONT_SIZE+1, string.format("%02d", getDateTime()['min']))
    -- Draw timer
    local timer_name = model.getTimer(0).name
    if (timer_name ~= "") then
      --lcd.drawText(LCD_W-d.INDENT-d.MARGIN, d.DBL_FONT_SIZE-d.SML_FONT_SIZE+d.MARGIN, timer_name, SMLSIZE + RIGHT)
      lcd.drawTimer(d.TELEMETRY_W+d.INDENT+d.MARGIN*2, d.DBL_FONT_SIZE+1, model.getTimer(0).value, DBLSIZE)
    end
end

local function drawRSSI(d)
  local barwidth = (d.RSSI_W-d.MARGIN*5)/4
  local SignalBars = -1
  local h = LCD_H-d.DBL_FONT_SIZE*2-d.MID_FONT_SIZE
  local rssi, alarm_low, alarm_crit = getRSSI()
  if rssi > alarm_crit then
    lcd.drawText(d.TELEMETRY_W+d.INDENT+d.MARGIN*2, d.DBL_FONT_SIZE+d.TELEMETRY_H+d.MARGIN, "RSSI")
    lcd.drawText(lcd.getLastPos(), d.DBL_FONT_SIZE+d.TELEMETRY_H+d.MARGIN, ":")
    lcd.drawNumber(lcd.getLastPos(), d.DBL_FONT_SIZE+d.TELEMETRY_H+d.MARGIN, rssi)
  else
    lcd.drawText(d.TELEMETRY_W+d.INDENT+d.MARGIN*2, d.DBL_FONT_SIZE+d.TELEMETRY_H+d.MARGIN, "RSSI", BLINK)
    lcd.drawText(lcd.getLastPos(), d.DBL_FONT_SIZE+d.TELEMETRY_H+d.MARGIN, ":",BLINK)
    lcd.drawNumber(lcd.getLastPos(), d.DBL_FONT_SIZE+d.TELEMETRY_H+d.MARGIN, rssi,BLINK)
  end
  if rssi > RSSI_HIGH then
    SignalBars = 3
  elseif rssi > RSSI_MED then
    SignalBars = 2
  elseif rssi > alarm_low then
    SignalBars = 1
  elseif rssi > alarm_crit then
    SignalBars = 0
  end
  while SignalBars > -1 do
    lcd.drawFilledRectangle( (d.TELEMETRY_W+d.INDENT+d.MARGIN*2)+(SignalBars)*(barwidth+d.MARGIN*2), (d.DBL_FONT_SIZE+d.TELEMETRY_H)-h+(3-SignalBars)*(h/4), barwidth, h-(3-SignalBars)*(h/4))
    SignalBars = SignalBars - 1
  end
end

local function drawStandbyScreen(d)
    lcd.drawText(d.INDENT, d.TELEMETRY_H, "Waiting for telemetry...")
end

local function run(event)
  -- run is called periodically only when screen is visible
  if(is_telemetry) then
    drawBasicScreen(DISPLAY_CONST)
    drawRSSI(DISPLAY_CONST)
    drawTelemetry(telemetry, data, DISPLAY_CONST)
    if (is_debug) then
      lcd.drawText(LCD_W,0,getAvailableMemory(),SMLSIZE + RIGHT)
    end
    if (RunClock % 16 == 0) then
      data = updateTelemetry(telemetry, data)
      RunClock = 0
    end
    RunClock = RunClock + 1
  else
    -- init
    drawBasicScreen(DISPLAY_CONST)
    drawStandbyScreen(DISPLAY_CONST)
    local ModelInfo = model.getInfo()
    telemetry, data  = initTelemetry()
    data = updateTelemetry(telemetry, data)
    is_telemetry = telemetry.BatteryId > 0
  end
end

return { run = run }
