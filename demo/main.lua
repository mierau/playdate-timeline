import "CoreLibs/graphics"
import "CoreLibs/crank"
import "../timeline"

local graphics <const> = playdate.graphics
local geometry <const> = playdate.geometry

local REFRESH_RATE = 50.0
local dt <const> = 1.0 / REFRESH_RATE -- time that passes each frame.

local scrubber_rect = geometry.rect.new(20, 240 - (10 + 20), 400 - (20 * 2), 10)
local scrubber_track_line = geometry.lineSegment.new(scrubber_rect.x + scrubber_rect.height / 2, scrubber_rect.y + scrubber_rect.height / 2, scrubber_rect.x + scrubber_rect.width - scrubber_rect.height / 2, scrubber_rect.y + scrubber_rect.height / 2)
local font_height <const> = graphics.getSystemFont():getHeight()

-- SETUP
playdate.display.setRefreshRate(REFRESH_RATE)

-- CREATE TIMELINE
-- Notice we start the title card a half second in.
local timeline = Timeline()
timeline:addRange("title card", 0.5, 2.0, function(range_info, range_progress)
	print("Title card progress:", range_progress)
end)
-- Use append to tack another time range onto the end of the timeline.
timeline:appendRange("card 1", 3.0, function(range_info, range_progress)
	print("Card 1 progress:", range_progress)
end)
timeline:appendRange("card 2", 4.0, function(range_info, range_progress)
	print("Card 2 progress:", range_progress)
end)
timeline:appendRange("end card", 1.5, function(range_info, range_progress)
	print("End card progress:", range_progress)
end)

-- MAIN LOOP
function playdate.update()
	-- Pause timeline when A is held.
	timeline:setPaused(playdate.buttonIsPressed(playdate.kButtonA))
	
	-- Allow seeking through timeline with left and right buttons.
	local time_delta = 0.0
	if playdate.buttonIsPressed(playdate.kButtonLeft) then
		time_delta -= 0.1
	end
	if playdate.buttonIsPressed(playdate.kButtonRight) then
		time_delta += 0.1
	end
	
	-- Allow seeking through timeline with crank.
	local crank_ticks = playdate.getCrankTicks(360)
	time_delta += crank_ticks * 0.025
	
	-- Move timeline.
	timeline:update(dt + time_delta)
	
	-- Draw presentation.
	graphics.clear(graphics.kColorWhite)
	
	-- Detect which card to draw based on which timeline range is active.
	if timeline:isRangeActive("title card") then
		drawTitleCard(timeline:getRangeProgress("title card"))
	elseif timeline:isRangeActive("card 1") then
		drawCard1(timeline:getRangeProgress("card 1"))
	elseif timeline:isRangeActive("card 2") then
		drawCard2(timeline:getRangeProgress("card 2"))
	elseif timeline:isRangeActive("end card") or timeline:isAtEnd() then
		drawEndCard(timeline:getRangeProgress("end card"))
	end
	
	-- Draw timeline play head.
	local timeline_progress = timeline:getProgress()
	local timeline_point = scrubber_track_line:pointOnLine(timeline_progress * scrubber_track_line:length())
	graphics.setColor(graphics.kColorXOR)
	graphics.fillRoundRect(scrubber_rect, 5)
	graphics.fillCircleAtPoint(timeline_point, 3)
end

function drawTitleCard(progress)
	local title_text <const> = "Welcome to Timeline"
	local text_to_draw = string.sub(title_text, 1, math.floor(#title_text * (progress * 3)))
	local fill_height = 240 * math.min(1.0, progress * 10)
	
	graphics.setColor(graphics.kColorBlack)
	graphics.fillRect(0, 120 - fill_height / 2, 400, fill_height)
	
	if #text_to_draw > 0 then
		graphics.setImageDrawMode(graphics.kDrawModeNXOR)
		graphics.setFont(graphics.getFont("bold"))
		graphics.drawTextAligned(text_to_draw, 200, 120 - font_height / 2, kTextAlignment.center)
	end
end

function drawCard1(progress)
	local title_text <const> = "Use left or right buttons or crank..."
	local text_to_draw = string.sub(title_text, 1, math.floor(#title_text * (progress * 3)))
	
	graphics.clear(graphics.kColorBlack)
	
	if #text_to_draw > 0 then
		graphics.setImageDrawMode(graphics.kDrawModeNXOR)
		graphics.setFont(graphics.getFont("bold"))
		graphics.drawTextAligned(text_to_draw, 200, 120 - font_height / 2, kTextAlignment.center)
	end
end

function drawCard2(progress)
	local title_text <const> = "...to scrub through this demo."
	local text_to_draw = string.sub(title_text, 1, math.floor(#title_text * (progress * 3)))
	
	graphics.clear(graphics.kColorBlack)
	
	if #text_to_draw > 0 then
		graphics.setImageDrawMode(graphics.kDrawModeNXOR)
		graphics.setFont(graphics.getFont("bold"))
		graphics.drawTextAligned(text_to_draw, 200, 120 - font_height / 2, kTextAlignment.center)
	end
end

function drawEndCard(progress)
	local title_text <const> = "fin."
	local text_to_draw = string.sub(title_text, 1, math.floor(#title_text * progress))
	
	local fill_opacity = math.min(1.0, progress * 2)
	
	graphics.setColor(graphics.kColorBlack)
	graphics.setDitherPattern(fill_opacity)
	graphics.fillRect(0, 0, 400, 240)
	
	if #text_to_draw > 0 then
		graphics.setImageDrawMode(graphics.kDrawModeNXOR)
		graphics.setFont(graphics.getFont("bold"))
		graphics.drawTextAligned(text_to_draw, 200, 120 - font_height / 2, kTextAlignment.center)
	end
end