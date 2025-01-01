defmodule Weather.Growler do
  alias Weather.Record
  alias Weather.FileUtil

  @download_url "https://www.wetterkontor.de/de/wetter/deutschland/rueckblick.asp"

  def download_history(id, city) do
    part_1 =
      for year <- 1950..1999, month <- 1..12 do
        {year, month}
      end

    part_2 =
      for year <- 2000..2024, month <- 1..12 do
        {year, month}
      end

    month_to_fetch = part_1 ++ part_2 ++ [{2025, 1}]

    month_to_fetch
    |> get_data_for_months(id)
    |> FileUtil.write_to_bin_file("data/#{city}.bin")
    |> FileUtil.write_to_json_file("data/#{city}.json")
  end

  def download_history_for_year(id, city, year) do
    month_to_fetch = for month <- 1..12, do: {year, month}

    (month_to_fetch ++ [{year + 1, 1}])
    |> get_data_for_months(id)
    |> Enum.filter(fn %Record{date: date} -> date.year == year end)
    |> FileUtil.write_to_bin_file("data/#{city}_#{year}.bin")
    |> FileUtil.write_to_json_file("data/#{city}_#{year}.json")
  end

  def fetch(id, date) do
    IO.puts("fetching #{date}")

    number_of_weeks = 6

    resp =
      Req.get!(@download_url,
        params: [id: id, datum: date, t: number_of_weeks]
      )

    Floki.parse_document!(resp.body)
    |> Floki.find("#extremwerte tbody tr td")
    |> Enum.map(&Floki.text/1)
    |> Enum.chunk_every(8)
    |> Enum.map(&Record.new/1)
  end

  defp get_data_for_months(months, id) do
    months
    |> Enum.map(fn {year, month} ->
      fetch(id, "1.#{month}.#{year}")
      |> Enum.filter(&Record.is_valid/1)
    end)
    |> List.flatten()
    |> Enum.sort(fn %Record{date: date_1}, %Record{date: date_2} ->
      Date.compare(date_1, date_2) == :lt
    end)
    |> Enum.dedup()
  end
end
