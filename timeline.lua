import "CoreLibs/object"

class("Timeline").extends()

function Timeline:init()
  self.time_blocks = {}
  self.current_time = 0
  self.duration = 0
  self.paused = false
  self.completion_callback = nil
  self.loop_start_time = nil
  self.loop_end_time = nil
end

function Timeline:reset()
  self:removeAllRanges()
  self:gotoBeginning()
end

-- !- Update

function Timeline:update(dt)
  if self.paused then
    return
  end
  
  local previous_time <const> = self.current_time
  
  self.current_time = math.min(self.duration, math.max(0.0, self.current_time + dt))
  
  -- Loop back if looping enabled
  if self.loop_end_time ~= nil and self.current_time >= self.loop_end_time then
    self.current_time = self.loop_start_time
  end
  
  -- Determine which blocks are at the current time and call their callback with the progress within that block of time.
  for _, block in pairs(self.time_blocks) do
    local previous_block_progress <const> = block.progress
    if self.current_time >= block.start_time and self.current_time < block.end_time then
      local progress = (self.current_time - block.start_time) / block.duration
      block.progress = math.max(math.min(progress, 1.0), 0.0)
      block.active = true
    elseif self.current_time >= block.end_time then
      block.progress = 1.0
      block.active = false
    elseif self.current_time < block.start_time then
      block.progress = 0.0
      block.active = false
    end
    block.progress_changed = (previous_block_progress ~= block.progress)
    if block.callback and block.progress_changed then
      block.callback(block, block.progress)
    end
  end
    
  if self.completion_callback and self.current_time ~= previous_time and self.current_time >= self.duration then
    self.completion_callback()
  end
end

-- !- Properties

function Timeline:setCompletion(callback)
  self.completion_callback = callback
end

function Timeline:setPaused(paused)
  self.paused = paused
end

function Timeline:isPaused()
  return self.paused
end

function Timeline:isAtEnd()
  return (self:getProgress() == 1.0)
end

function Timeline:getTime()
  return self.current_time
end

function Timeline:getProgress()
  return math.min(1.0, math.max(0.0, self.current_time / self.duration))
end

function Timeline:setLoopRange(start_time, end_time)
  self.loop_start_time = start_time
  self.loop_end_time = end_time
end

function Timeline:removeLoopRange()
  self.loop_start_time = nil
  self.loop_end_time = nil
end


-- !- Seek

function Timeline:gotoTime(time)
  self.current_time = time
end

function Timeline:gotoBeginning()
  self.current_time = 0.0
end

function Timeline:gotoEnd()
  self.current_time = self.duration
end

function Timeline:getDuration()
  return self.duration
end

function Timeline:gotoStartOfRange(name)
  local time_range = self.time_blocks[name]

  if time_range ~= nil then
    self.current_time = time_range.start_time
  end
  
  return (time_range ~= nil)
end

function Timeline:gotoNextRange(filter_callback)
  local next_time = nil
  
  -- Find the smallest start time greater than the current time
  for _, block in pairs(self.time_blocks) do
    if block.start_time > self.current_time then
      if next_time == nil or block.start_time < next_time then
        if filter_callback == nil or filter_callback(block) == true then
          next_time = block.start_time
        end
      end
    end
  end
  
  -- Only update current_time if a next block is found
  if next_time ~= nil then
    self.current_time = next_time
  end
  
  return (next_time ~= nil)
end

function Timeline:gotoPreviousRange(filter_callback)
  local previous_time = nil
  
  -- Find the largest start time that is less than the current time and ensure the current time is not within that block
  for _, block in pairs(self.time_blocks) do
    if block.start_time < self.current_time and self.current_time >= block.end_time then
      if previous_time == nil or block.start_time > previous_time then
        if filter_callback == nil or filter_callback(block) == true then
          previous_time = block.start_time
        end
      end
    end
  end
  
  -- Only update current_time if a previous block is found
  if previous_time ~= nil then
    self.current_time = previous_time
  end
  
  return (previous_time ~= nil)
end

-- !- Ranges

function Timeline:getRange(name)
  return self.time_blocks[name]
end

function Timeline:addRange(name, start_time, duration, callback, context)
  if duration == 0.0 then
    return nil
  end
  
  local new_block = {
    name = name,
    active = false,
    start_time = start_time,
    end_time = start_time + duration,
    duration = duration,
    callback = callback,
    progress = 0.0,
    progress_changed = false,
    context = context
  }
  
  self.time_blocks[name] = new_block
  self:recalculateDuration()
  
  return new_block
end

function Timeline:appendRange(name, duration, callback, context)
  return self:addRange(name, self:getDuration(), duration, callback, context)
end

function Timeline:removeRange(name)
  self.time_blocks[name] = nil
  self:recalculateDuration()
end

function Timeline:removeAllRanges()
  self.time_blocks = {}
  self:recalculateDuration()
end

function Timeline:getRangesAtTime(time, filter_callback)
  local blocks = {}
  
  for _, block in pairs(self.time_blocks) do
    if time >= block.start_time and time < block.end_time then
      if filter_callback == nil or filter_callback(block) == true then
        blocks[block.name] = block
      end
    end
  end
  
  return blocks
end

function Timeline:getCurrentRanges(filter_callback)
  return self:getRangesAtTime(self.current_time, filter_callback)
end

function Timeline:isRangeActive(name)
  local r = self.time_blocks[name]
  if not r then
    return false
  end
  return r.active
end

function Timeline:getRangeProgress(name)
  local r = self.time_blocks[name]
  if not r then
    return 0.0
  end
  return r.progress
end

-- !- Utility

function Timeline:recalculateDuration()
  local total_duration = 0
  
  -- Find the maximum end time among all blocks
  for _, block in pairs(self.time_blocks) do
    total_duration = math.max(total_duration, block.end_time)
  end
  
  self.duration = total_duration
end

-- !- Debug

function Timeline:print()
  -- Create an array to hold the time blocks for sorting
  local blocks = {}
  for _, block in pairs(self.time_blocks) do
    table.insert(blocks, block)
  end
  
  -- Sort the blocks by their start time
  table.sort(blocks, function(a, b)
    return a.start_time < b.start_time
  end)
  
  -- Print details of each block
  print(#blocks, "ranges in timeline")
  for _, block in pairs(blocks) do
    print(block.name, block.progress, block.start_time, block.end_time)
  end
  print("\n\n")
end