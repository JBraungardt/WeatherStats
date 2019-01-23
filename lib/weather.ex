defmodule Weather do
  # id: 31, Bremen
  # id: "P131" Schonungen - Mainberg
  defdelegate download_history(id, city), to: Weather.Growler

  defdelegate calc_avgs(city), to: Weather.Stats
end
