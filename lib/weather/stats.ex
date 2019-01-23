defmodule Weather.Stats do
  alias Weather.Record
  alias Weather.FileUtil

  def calc_avgs(city) do
    stats_per_month =
      FileUtil.read_bin_file("data/#{city}.bin")
      |> Enum.chunk_by(fn %Record{date: date} ->
        <<start::binary-size(7), _rest::binary>> = Date.to_string(date)
        start
      end)
      |> Task.async_stream(&process_month/1)
      |> Enum.map(fn {:ok, result} -> result end)
      |> FileUtil.write_to_json_file("data/#{city}_stats.json")

    # strip the first month as his data is incomplete
    [_ | rest] = Enum.reverse(stats_per_month)

    rest
    |> Enum.group_by(fn %{date: date} -> String.slice(date, 5, 2) end)
    |> Map.to_list()
    |> Task.async_stream(&calc_month_avg/1)
    |> Enum.map(fn {:ok, result} -> result end)
    |> FileUtil.write_to_json_file("data/#{city}_stats_avg.json")
  end

  defp process_month(days) do
    [%Record{date: date} | _] = days
    <<year_month::binary-size(7), _rest::binary>> = Date.to_string(date)

    Enum.reduce(
      days,
      %{date: year_month, sun: 0, rain: 0, avg_temp: [], max_temp: [], min_temp: []},
      fn day, accu ->
        %{sun: sunny_hours, rain: rain_amount, avg_temp: temp, max_temp: max, min_temp: min} = day

        accu
        |> add_to_list(:avg_temp, temp)
        |> add_to_list(:max_temp, max)
        |> add_to_list(:min_temp, min)
        |> sum(:sun, sunny_hours)
        |> sum(:rain, rain_amount)
      end
    )
    |> calc_and_set_average(:avg_temp)
    |> Map.update!(:max_temp, &Enum.max(&1))
    |> Map.update!(:min_temp, &Enum.min(&1))
    |> Map.update!(:sun, &Float.round(&1, 1))
    |> Map.update!(:rain, &Float.round(&1, 1))
  end

  defp calc_month_avg({month, data}) do
    avgs =
      data
      |> Enum.reduce(
        %{avg_temp: [], avg_rain: [], avg_sun: []},
        fn %{avg_temp: t, rain: r, sun: s}, accu ->
          accu
          |> add_to_list(:avg_temp, t)
          |> add_to_list(:avg_rain, r)
          |> add_to_list(:avg_sun, s)
        end
      )
      |> calc_and_set_average(:avg_temp)
      |> calc_and_set_average(:avg_sun)
      |> calc_and_set_average(:avg_rain)

    %{month => avgs}
  end

  defp add_to_list(map, key, new_value) do
    Map.update!(map, key, &[new_value | &1])
  end

  defp sum(map, _key, nil), do: map

  defp sum(map, key, new_value) do
    Map.update!(map, key, &(new_value + &1))
  end

  defp calc_and_set_average(map, key) do
    Map.update!(map, key, &((Enum.sum(&1) / length(&1)) |> Float.round(1)))
  end
end
