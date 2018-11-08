defmodule Ale8583.BlockReader do
  @moduledoc """
  MODULE Ale8583.BlockReader contains functions for read file configuration.


  """
  def read!(device) do
    do_read!(device, [])
  end

  defp do_read!(device, acc) do
    case IO.read(device, :line) do
      :eof ->
        {:ok, acc |> addlist()}

      {:error, reason} ->
        {:error, reason}

      data when is_binary(data) ->
        case Ale8583.TermParser.parse(data) do
          {:ok, dat_conver} ->
            do_read!(device, [dat_conver | acc])

          _ ->
            do_read!(device, [acc])
        end
    end
  end

  defp addlist(list) do
    do_addlist(list, [])
  end

  defp do_addlist([{i, dat} | tail], list) do
    if i == :bs || i == :bp do
      do_addlist(tail, list ++ ["#{i}": dat])
    else
      do_addlist(tail, list ++ ["c#{i}": dat])
    end
  end

  defp do_addlist([], list) do
    list
  end
end
