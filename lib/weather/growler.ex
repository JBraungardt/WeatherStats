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
      for year <- 2000..2022, month <- 1..12 do
        {year, month}
      end

    month_to_fetch = part_1 ++ part_2 ++ [{2023, 1}]

    month_to_fetch
    |> Enum.map(fn {year, month} ->
      fetch(id, "1.#{month}.#{year}")
      |> Enum.filter(&Record.is_valid/1)
    end)
    |> List.flatten()
    |> Enum.sort(fn %Record{date: date_1}, %Record{date: date_2} ->
      Date.compare(date_1, date_2) == :lt
    end)
    |> Enum.dedup()
    |> FileUtil.write_to_bin_file("data/#{city}.bin")
    |> FileUtil.write_to_json_file("data/#{city}.json")
  end

  def fetch(id, date, number_of_weeks \\ 6) do
    IO.puts("fetching #{date}")

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
end
