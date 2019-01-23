defmodule Weather.Record do
  @derive Jason.Encoder
  defstruct [:date, :min_temp, :max_temp, :avg_temp, :rain, :sun, :wind]

  def new(str_list) when is_list(str_list) do
    [date, min, max, avg, rain, sun, wind] = str_list

    %Weather.Record{
      date: parse_date(date),
      min_temp: parse_float(min),
      max_temp: parse_float(max),
      avg_temp: parse_float(avg),
      rain: parse_float(rain),
      sun: parse_float(sun),
      wind: parse_float(wind)
    }
  end

  def is_valid(%Weather.Record{avg_temp: -999.0}), do: false
  def is_valid(_), do: true

  defp parse_float(str) do
    String.replace(str, ",", ".")
    |> Float.parse()
    |> case do
      {number, ""} -> number
      :error -> nil
    end
  end

  defp parse_date(str) do
    <<day::binary-size(2), ".", month::binary-size(2), ".", year::binary-size(4)>> = str

    {:ok, date} =
      Date.new(String.to_integer(year), String.to_integer(month), String.to_integer(day))

    date
  end
end
