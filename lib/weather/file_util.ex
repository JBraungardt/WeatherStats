defmodule Weather.FileUtil do
  def write_to_json_file(list, file) do
    json = Jason.encode!(list, pretty: true)
    File.write!(file, json)
    list
  end

  def read_json_file(file_name) do
    file_name
    |> File.read!()
    |> Jason.decode!(keys: :atoms)
  end

  def write_to_bin_file(list, file) do
    bin = :erlang.term_to_binary(list)
    File.write!(file, bin)
    list
  end

  def read_bin_file(file_name) do
    file_name
    |> File.read!()
    |> :erlang.binary_to_term()
  end
end
