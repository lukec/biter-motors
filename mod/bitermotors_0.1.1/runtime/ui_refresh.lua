local UiRefresh = {
  interval_ticks = 300,
  progress_interval_ticks = 1800
}

function UiRefresh.should_refresh(last_tick, now_tick)
  return not last_tick or now_tick - last_tick >= UiRefresh.interval_ticks
end

function UiRefresh.should_refresh_progress(last_tick, now_tick)
  return not last_tick or now_tick - last_tick >= UiRefresh.progress_interval_ticks
end

return UiRefresh
