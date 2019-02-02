defmodule Weather do
  # id: 31, Bremen
  # id: "P131" Schonungen - Mainberg
  defdelegate download_history(id, city), to: Weather.Growler

  defdelegate calc_avgs(city), to: Weather.Stats

  def stats_for_month(id, month, year) do
    Weather.Growler.fetch(id, "1.#{month + 1}.#{year}")
    |> Enum.filter(&(month == &1.date.month))
    |> Weather.Stats.process_month()
  end
end
