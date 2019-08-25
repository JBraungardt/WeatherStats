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

  def show_stats_for_current_month() do
    now = DateTime.utc_now()

    show_stats_for_month(now.month, now.year)
  end

  def show_stats_for_month(month, year) do
    IO.puts("Schweinfurt")

    stats_for_month("P131", month, year)
    |> IO.inspect()

    IO.puts("")

    IO.puts("Bremen")

    stats_for_month(31, month, year)
    |> IO.inspect()

    nil
  end
end

Weather.show_stats_for_current_month()
