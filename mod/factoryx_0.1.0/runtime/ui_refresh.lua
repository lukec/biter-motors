local UiRefresh = {
  interval_ticks = 300
}

function UiRefresh.should_refresh(last_tick, now_tick)
  return not last_tick or now_tick - last_tick >= UiRefresh.interval_ticks
end

return UiRefresh
