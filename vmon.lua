-- EdgeTX Lua script
-- Battery and RSS TELEMETRY
-- Place this file in SD Card copy on your computer > /SCRIPTS/TELEMETRY/
-- Designed for 128x64 B&W displays
--
-- https://github.com/pagrey
--

-- RSSI threshold values
-- low and critical are read from the radio

local RSSI_HIGH = 89
local RSSI_MED = 74

-- Cell count range

local CELLS = {"1S","2S","3S","4S"}
local battery_cells = 2
local SENSORS = {"RxBt","A1"}
local active_sensor = 1

-- Cell count for known models

local ModelCellCount = {
  DLG950 = 1,
  Radian = 3
}

local battery_cache
local sensor_cache

local run_clock = 0
local is_telemetry = false
local is_debug = false
local is_menu_visible = false
local is_cells_changed = false
local is_cells_edit = false
local is_sensor_edit = false
local is_sensor_changed = false
local is_item_one = true

-- Display constants

local DISPLAY_CONST = {
  TELEMETRY_H = 38,
  TELEMETRY_W = 74,
  MARGIN = 2,
  INDENT = 4,
  TITLE_INDENT = 10,
  TIME_INDENT = 53,
  DBL_FONT_SIZE = 16,
  SML_FONT_SIZE = 8,
  MID_FONT_SIZE = 12,
  RSSI_W = 38,
  MODEL_NAME = model.getInfo()['name'],
  TIMER_NAME = model.getTimer(0).name
}

local function getTelemetryId(name)
  field = getFieldInfo(name)
  if getFieldInfo(name) then return field.id end
  return -1
end

local function initTelemetry()

-- Battery parameters

  local VoltageMax = 4.2
  local VoltageAlarm = 3.4
  local VoltageOffset = 3.0

-- Custom default battery cell count for models

  if not is_cells_changed then
    local model_cell_count = ModelCellCount[model.getInfo()['name']]
    if model_cell_count then
      battery_cells = model_cell_count
    end
  end

-- Telemetry values

  local AdjustedBatteryCells = battery_cells*100
  local AdjustedVoltageMax = VoltageMax*AdjustedBatteryCells
  local AdjustedVoltageOffset = VoltageOffset*AdjustedBatteryCells
  local AdjustedVoltageRange = AdjustedVoltageMax-AdjustedVoltageOffset

  local telemetry = {
    BatteryId = getTelemetryId(SENSORS[active_sensor]),
    BatteryLowId = getTelemetryId(SENSORS[active_sensor] .. "-"),
    BatteryHighId = getTelemetryId(SENSORS[active_sensor] .. "+"),
    VoltageAlarm = (VoltageAlarm-VoltageOffset)*AdjustedBatteryCells,
    VoltageMax = AdjustedVoltageMax,
    VoltageOffset = AdjustedVoltageOffset,
    VoltageRange = AdjustedVoltageRange
  }
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
  -- Start drawing
  lcd.drawFilledRectangle(d.MARGIN, d.DBL_FONT_SIZE, d.TELEMETRY_W, d.TELEMETRY_H)
  lcd.drawFilledRectangle(d.MARGIN+d.MARGIN, d.DBL_FONT_SIZE+d.DBL_FONT_SIZE+d.MARGIN*2, d.TELEMETRY_W-d.MARGIN*2-BUTTON_W, d.TELEMETRY_H-d.DBL_FONT_SIZE-d.MARGIN*3)
  lcd.drawFilledRectangle(d.MARGIN+d.TELEMETRY_W-d.MARGIN-BUTTON_W, d.DBL_FONT_SIZE+d.DBL_FONT_SIZE+d.MARGIN+BUTTON_H, BUTTON_W, BUTTON_H)
  while BatteryBar > 0 do
    lcd.drawFilledRectangle(d.MARGIN*3+(BatteryBar-1)*(SegmentWidth), d.DBL_FONT_SIZE+d.DBL_FONT_SIZE+d.MARGIN*3, SegmentWidth-d.MARGIN, d.TELEMETRY_H-d.DBL_FONT_SIZE-d.MARGIN*5)
    BatteryBar = BatteryBar - 1
  end
  lcd.drawText(d.INDENT+d.TELEMETRY_W-d.MARGIN*2, d.DBL_FONT_SIZE+d.MARGIN, "V", DBLSIZE + RIGHT + INVERS)
  lcd.drawNumber(lcd.getLastLeftPos()-d.MARGIN, d.DBL_FONT_SIZE+d.MARGIN, data.BatteryVoltage*10, DBLSIZE + PREC1 + RIGHT + INVERS)
  if VoltageScaled > 0 then
    if (VoltageScaled > telemetry.VoltageAlarm) then
      lcd.drawText(d.MARGIN, d.DBL_FONT_SIZE+d.TELEMETRY_H+d.MARGIN, SENSORS[active_sensor])
    else
      lcd.drawText(d.MARGIN, d.DBL_FONT_SIZE+d.TELEMETRY_H+d.MARGIN, SENSORS[active_sensor], BLINK)
    end
    lcd.drawText(lcd.getLastPos(), d.DBL_FONT_SIZE+d.TELEMETRY_H+d.MARGIN, ":"..battery_cells.."S")
  else
    lcd.drawText(d.MARGIN + 1, d.DBL_FONT_SIZE+d.TELEMETRY_H+d.MARGIN, CELLS[battery_cells]..":"..SENSORS[active_sensor], SMLSIZE + INVERS)
  end
end

local function drawBasicScreen(d)
  lcd.clear()
  -- Draw title and background
  lcd.drawText(d.TITLE_INDENT, 0, d.MODEL_NAME, DBLSIZE)
  -- Draw time
  lcd.drawText(d.TIME_INDENT, LCD_H-d.SML_FONT_SIZE+1, string.format("%02d", getDateTime()['hour']))
  lcd.drawText(lcd.getLastPos(), LCD_H-d.SML_FONT_SIZE+1, ":", BLINK)
  lcd.drawText(lcd.getLastPos(), LCD_H-d.SML_FONT_SIZE+1, string.format("%02d", getDateTime()['min']))
  -- Draw timer
  if (d.TIMER_NAME ~= "") then
    --lcd.drawText(LCD_W-d.INDENT-d.MARGIN, d.DBL_FONT_SIZE-d.SML_FONT_SIZE+d.MARGIN, d.TIMER_NAME, SMLSIZE + RIGHT)
    lcd.drawTimer(d.TELEMETRY_W+d.INDENT+d.MARGIN*2, d.DBL_FONT_SIZE+1, model.getTimer(0).value, DBLSIZE)
  end
end

local function drawRSSI(d)
  local barwidth = (d.RSSI_W-d.MARGIN*5)/4
  local SignalBars = -1
  local h = LCD_H-d.DBL_FONT_SIZE*2-d.MID_FONT_SIZE
  local rssi, alarm_low, alarm_crit = getRSSI()
  if rssi > alarm_crit then
    lcd.drawText(d.TELEMETRY_W+d.INDENT+d.MARGIN*2, d.DBL_FONT_SIZE+d.TELEMETRY_H+d.MARGIN, "RSSI:")
    lcd.drawNumber(lcd.getLastPos(), d.DBL_FONT_SIZE+d.TELEMETRY_H+d.MARGIN, rssi)
  elseif rssi > 0 then
    lcd.drawText(d.TELEMETRY_W+d.INDENT+d.MARGIN*2, d.DBL_FONT_SIZE+d.TELEMETRY_H+d.MARGIN, "RSSI:", BLINK)
    lcd.drawNumber(lcd.getLastPos(), d.DBL_FONT_SIZE+d.TELEMETRY_H+d.MARGIN, rssi,BLINK)
  else
    lcd.drawText(d.TELEMETRY_W+d.INDENT+d.MARGIN*2, d.DBL_FONT_SIZE+d.TELEMETRY_H+d.MARGIN, "RSSI:00", SMLSIZE + INVERS)
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
  lcd.drawText(d.INDENT, d.TELEMETRY_H, "Waiting for "..SENSORS[active_sensor].."...") 
end

local function drawMenu(d)
  lcd.drawFilledRectangle(d.INDENT*2,d.INDENT*2,d.TELEMETRY_W+d.INDENT*4,d.SML_FONT_SIZE*2+d.MID_FONT_SIZE*2+d.INDENT*3,ERASE)
  lcd.drawRectangle(d.INDENT*2,d.INDENT*2,d.TELEMETRY_W+d.INDENT*4,d.SML_FONT_SIZE*2+d.MID_FONT_SIZE*2+d.INDENT*3)
  lcd.drawText(d.INDENT*3,d.INDENT*3,"Battery Cells",SMLSIZE)
  lcd.drawText(d.INDENT*3,d.INDENT*3+d.SML_FONT_SIZE+d.MID_FONT_SIZE,"Sensor Name",SMLSIZE)

  if is_item_one then
    lcd.drawCombobox(d.INDENT*3,d.INDENT*3+d.SML_FONT_SIZE,d.TELEMETRY_W,CELLS,battery_cache-1,INVERS)
  else
    lcd.drawCombobox(d.INDENT*3,d.INDENT*3+d.SML_FONT_SIZE,d.TELEMETRY_W,CELLS,battery_cache-1)
  end

  if is_item_one then
    lcd.drawCombobox(d.INDENT*3,d.INDENT*3+d.SML_FONT_SIZE*2+d.MID_FONT_SIZE,d.TELEMETRY_W,SENSORS,sensor_cache-1)
  else
    lcd.drawCombobox(d.INDENT*3,d.INDENT*3+d.SML_FONT_SIZE*2+d.MID_FONT_SIZE,d.TELEMETRY_W,SENSORS,sensor_cache-1,INVERS)
  end

  if is_sensor_edit then
    lcd.drawCombobox(d.INDENT*3,d.INDENT*3+d.SML_FONT_SIZE*2+d.MID_FONT_SIZE,d.TELEMETRY_W,SENSORS,sensor_cache-1,BLINK)
  end
  if is_cells_edit then
    lcd.drawCombobox(d.INDENT*3,d.INDENT*3+d.SML_FONT_SIZE,d.TELEMETRY_W,CELLS,battery_cache-1,BLINK)
  end
end

local function run(event)
  -- run is called periodically only when screen is visible
  if event == nil then
    error("Cannot be run as a widget script!")
    return 2
  else
    if event ~= 0 then
      if event == EVT_VIRTUAL_ENTER then
	if is_menu_visible then
          if is_cells_edit then
            battery_cells = battery_cache
	    is_menu_visible = false
	    is_cells_changed = true
            is_cells_edit = false
          elseif is_sensor_edit then
            active_sensor = sensor_cache
	    is_menu_visible = false
	    is_sensor_changed = true
            is_sensor_edit = false
          else
            if is_item_one then
              is_cells_edit = true
            else
              is_sensor_edit = true
            end
          end
	else
	  is_menu_visible = true
          battery_cache = battery_cells
          sensor_cache = active_sensor
	end
      elseif event == EVT_VIRTUAL_INC then
	if is_cells_edit then
	  battery_cache = battery_cache % #CELLS + 1
        elseif is_sensor_edit then
          sensor_cache = sensor_cache % #SENSORS + 1
        elseif is_menu_visible then
         is_item_one = not is_item_one 
	end
      elseif event == EVT_VIRTUAL_DEC then
	if is_cells_edit then
	  battery_cache = (battery_cache - 2) % #CELLS + 1
        elseif is_sensor_edit then
	  sensor_cache = (sensor_cache - 2) % #SENSORS + 1
        elseif is_menu_visible then
         is_item_one = not is_item_one 
	end
      elseif event == EVT_VIRTUAL_EXIT then
	is_menu_visible = false
        is_cells_edit = false
        is_sensor_edit = false
      end
    end
    if(is_telemetry) then
      drawBasicScreen(DISPLAY_CONST)
      drawRSSI(DISPLAY_CONST)
      drawTelemetry(telemetry, data, DISPLAY_CONST)
      if (is_debug) then
	lcd.drawText(LCD_W,0,getAvailableMemory(),SMLSIZE + RIGHT)
      end
      if (is_menu_visible) then
	drawMenu(DISPLAY_CONST)
      end
      if (run_clock % 16 == 0) then
	if is_cells_changed or is_sensor_changed then 
	  telemetry, data  = initTelemetry()
	  data = updateTelemetry(telemetry, data) 
	  is_cells_changed = false
	  is_sensor_changed = false
	  run_clock = 0
	else
	  data = updateTelemetry(telemetry, data)
	  run_clock = 0
	end
      end
      run_clock = run_clock + 1
    else
      -- Init telemetry
      drawBasicScreen(DISPLAY_CONST)
      drawStandbyScreen(DISPLAY_CONST)
      telemetry, data  = initTelemetry()
      data = updateTelemetry(telemetry, data)
      is_telemetry = telemetry.BatteryId > 0
    end
  end
end

return { run = run }
