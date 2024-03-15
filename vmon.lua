-- OpenTX Lua script
-- Battery and RSS TELEMETRY
-- Place this file in SD Card copy on your computer > /SCRIPTS/TELEMETRY/
-- Designed for 128x64 B&W displays like the Radiomaster Boxer
--
-- https://github.com/pagrey
--

-- RSSI threshold values
-- low and critical are read from the radio

local RSSI_HIGH = 89
local RSSI_MED = 74

local rxbt = "/SCRIPTS/TELEMETRY/VMON/rxbt.lua"
local chunk, telemetry, data
local RunClock = 0
local is_telemetry = false
local is_debug = true

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
  TELEMETRY_H = 38,
  TELEMETRY_W = 74,
  BUTTON_W = 3, 
  BUTTON_H = 7,
  RSSI_W = 38
}

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
    local initTelemetry, updateTelemetry, drawTelemetry = chunk()
      drawBasicScreen(DISPLAY_CONST)
      drawRSSI(DISPLAY_CONST)
      drawTelemetry(telemetry, DISPLAY_CONST)
      if (is_debug) then
        lcd.drawText(LCD_W,0,getAvailableMemory(),SMLSIZE + RIGHT)
      end
      data = updateTelemetry(telemetry)
    if (RunClock % 16 == 0) then
      data = updateTelemetry(telemetry)
      RunClock = 0
    end
    RunClock = RunClock + 1
  else
    -- init
    drawBasicScreen(DISPLAY_CONST)
    drawStandbyScreen(DISPLAY_CONST)
    chunk = loadScript(rxbt)
    local initTelemetry, updateTelemetry, drawTelemetry = chunk()
    telemetry = initTelemetry()
    is_telemetry = telemetry.BatteryId > 0
  end
end

return { run = run }
