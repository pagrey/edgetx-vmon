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
local SensorFour = "Pres"
local is_rxbt = false
local is_vario = false
local varioData = {}
local VARIO_DATA_LENGTH = 40 --temp
local VARIO_SAMPLES = 3

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
local MARGIN = 2
local TITLE_INDENT = 10
local INDENT = 4
local DBL_FONT_SIZE = 16
local SML_FONT_SIZE = 8
local MID_FONT_SIZE = 12
local TIME_INDENT = 53
local RSSI_W = 38
local Signal_H = LCD_H-DBL_FONT_SIZE*2-MID_FONT_SIZE

--local rxbt = loadScript("/SCRIPTS/TELEMETRY/VMON/rxbt.lua")
--local gt = rxbt()

local function getTelemetryId(name)
 field = getFieldInfo(name)
 if getFieldInfo(name) then return field.id end
  return -1
end

local function backgroundRXBT()
  BatteryVoltage = getValue(batt_id)
  BatteryVoltageHigh = getValue(batt_high_id)
  BatteryVoltageLow = getValue(batt_low_id)
  rssi, alarm_low, alarm_crit = getRSSI()
end

local function backgroundVario()
      for i=VARIO_DATA_LENGTH,1,-1 do
	varioData[i] = varioData[i-1]
      end 
      varioData[0] = math.random(-6,6)
end

local function initTelemetry()
  is_rxbt = getTelemetryId(SensorOne) > -1
  is_vario = getTelemetryId(SensorFour) > -1
  if (is_vario) then
    for i=0,VARIO_DATA_LENGTH do
      varioData[i] = math.random(-6,6)
    end
  end
  if (is_rxbt) then
    VoltageAlarm = (VoltageAlarm-VoltageOffset)*BatteryCells*100
    VoltageMax = VoltageMax*BatteryCells*100
    VoltageOffset = VoltageOffset*BatteryCells*100
    VoltageRange = VoltageMax-VoltageOffset
    batt_id = getTelemetryId(SensorOne) 
    batt_low_id = getTelemetryId(SensorTwo)
    batt_high_id = getTelemetryId(SensorThree)
    backgroundRXBT()
  end
end

local function drawRSSI(x, y, w, h)
    -- Draw RSSI
    local barwidth = (w-MARGIN*5)/4
    local SignalBars = -1
    if rssi > alarm_crit then
      lcd.drawText( Telemetry_W+INDENT+MARGIN*2, DBL_FONT_SIZE+Telemetry_H+MARGIN, "RSSI")
      lcd.drawText(lcd.getLastPos(), DBL_FONT_SIZE+Telemetry_H+MARGIN, ":")
      lcd.drawNumber(lcd.getLastPos(), DBL_FONT_SIZE+Telemetry_H+MARGIN, rssi)
    else
      lcd.drawText( Telemetry_W+INDENT+MARGIN*2, DBL_FONT_SIZE+Telemetry_H+MARGIN, "RSSI", BLINK)
      lcd.drawText(lcd.getLastPos(), DBL_FONT_SIZE+Telemetry_H+MARGIN, ":",BLINK)
      lcd.drawNumber(lcd.getLastPos(), DBL_FONT_SIZE+Telemetry_H+MARGIN, rssi,BLINK)
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
     lcd.drawFilledRectangle( (x)+(SignalBars)*(barwidth+MARGIN*2), y-h+(3-SignalBars)*(h/4), barwidth, h-(3-SignalBars)*(h/4))
      SignalBars = SignalBars - 1
    end
end

local function drawVario(x, y, w, h)
  local data_points = w / (MARGIN*3)
  for i=0, data_points-1 do
	lcd.drawFilledRectangle(x+w-MARGIN*2-i*(MARGIN*3), y+h/2+varioData[i], MARGIN*2, MARGIN*2)
  end
  lcd.drawLine(x, y+h/2, x+w, y+h/2, DOTTED, FORCE)
  lcd.drawText(x, y+h+MARGIN, "Vspd")
  lcd.drawText(lcd.getLastPos(), y+h+MARGIN, ":")
  local avg = 0
  for i=0, VARIO_SAMPLES do
    avg = avg + varioData[i]
  end
  avg = avg/VARIO_SAMPLES 
  lcd.drawNumber(lcd.getLastPos(), y+h+MARGIN, avg)
end

local function drawRXBT(x, y, w, h)
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
  lcd.drawFilledRectangle(x+MARGIN, y+DBL_FONT_SIZE+MARGIN*2, w-MARGIN*2-Butn_W, h-DBL_FONT_SIZE-MARGIN*3)
  lcd.drawFilledRectangle(x+w-MARGIN-Butn_W, y+DBL_FONT_SIZE+MARGIN+Butn_H, Butn_W, Butn_H)
  while SignalBars > 0 do
   lcd.drawFilledRectangle(x+MARGIN*2+(SignalBars-1)*5, y+DBL_FONT_SIZE+MARGIN*3, Butn_W, h-DBL_FONT_SIZE-MARGIN*5)
   SignalBars = SignalBars - 1
  end 
  lcd.drawText(INDENT+w-MARGIN, y+MARGIN, "V", DBLSIZE + RIGHT + INVERS)
  lcd.drawNumber(lcd.getLastLeftPos()-MARGIN, y+MARGIN, BatteryVoltage*10, DBLSIZE + PREC1 + RIGHT + INVERS)
  if (VoltageScaled > VoltageAlarm) then
    lcd.drawText(x, y+h+MARGIN, SensorOne)
  else
    lcd.drawText(x, y+h+MARGIN, SensorOne, BLINK)
  end
  lcd.drawText(lcd.getLastPos(), y+h+MARGIN, ":")
  lcd.drawNumber(lcd.getLastPos(), y+h+MARGIN, BatteryCells)
  lcd.drawText(lcd.getLastPos(), y+h+MARGIN, "S")
end

local function drawBasicScreen()
    lcd.clear()
    -- Draw title and background
    lcd.drawText(TITLE_INDENT, 0, model.getInfo()['name'], DBLSIZE)
    -- Draw time
    lcd.drawText(TIME_INDENT, LCD_H-SML_FONT_SIZE+1, string.format("%02d", getDateTime()['hour']))
    lcd.drawText(lcd.getLastPos(), LCD_H-SML_FONT_SIZE+1, ":", BLINK)
    lcd.drawText(lcd.getLastPos(), LCD_H-SML_FONT_SIZE+1, string.format("%02d", getDateTime()['min']))

end

local function drawMainScreen()
    -- Draw telemetry
    if(is_vario) then
      drawVario(INDENT, DBL_FONT_SIZE, Telemetry_W, Telemetry_H)
    elseif(is_rxbt) then
      drawRXBT(INDENT, DBL_FONT_SIZE, Telemetry_W, Telemetry_H)
    end

    -- Draw timer
    local timer_name = model.getTimer(0).name
    if (timer_name ~= "") then
      lcd.drawText(LCD_W-INDENT-MARGIN, DBL_FONT_SIZE-SML_FONT_SIZE+MARGIN, timer_name, SMLSIZE + RIGHT)
      lcd.drawTimer(Telemetry_W+INDENT+MARGIN*2, DBL_FONT_SIZE+1, model.getTimer(0).value, DBLSIZE)
    end

    -- Draw RSSI
    drawRSSI(Telemetry_W+INDENT+MARGIN*2, DBL_FONT_SIZE+Telemetry_H, RSSI_W, LCD_H-DBL_FONT_SIZE*2-MID_FONT_SIZE)
end

local function run(event)
  -- run is called periodically only when screen is visible
  if(is_rxbt) then
    if (RunClock % 2 == 0) then
      drawBasicScreen()
      drawMainScreen()
      if (RunClock % 16 == 0) then
        backgroundRXBT()
	backgroundVario()
        RunClock = 0
      end
    end
    RunClock = RunClock + 1
  else
    drawBasicScreen()
    lcd.drawText(INDENT, DBL_FONT_SIZE+MARGIN, "Waiting for telemetry...")
    initTelemetry()
  end
end

return { run = run }
