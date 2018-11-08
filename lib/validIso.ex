defmodule Ale8583.ValidISO do
  require Logger

  @moduledoc """
  MODULE Ale8583.ValidUSI contains functions for ISO validation/format/decode/code  .
  """

  @doc """

  Function for EBCDIC decode .

  """
  def decode_ebcdic(bit_map_list, list, iso) do
    do_decode_ebcdic(bit_map_list, list, iso, [])
  end

  defp do_decode_ebcdic([], _, iso_new, acc) do
    {:ok, acc, iso_new}
  end

  defp do_decode_ebcdic(
         [head | tail],
         list,
         {:iso, iso, {bit_map_p, bit_map_s, flag_bm_sec, iso_conf}, status},
         acc
       ) do
    atom_key = "c" <> Integer.to_string(head)

    case List.keyfind(iso_conf, String.to_atom(atom_key), 0) do
      {_, map} ->
        case atom_key do
          "c1" ->
            do_decode_ebcdic(
              tail,
              list,
              {:iso, iso, {bit_map_p, bit_map_s, flag_bm_sec, iso_conf}, status},
              acc
            )

          _ ->
            case get_field_ebcdic_to_string(head, list, map) do
              {:ok, new_list, value} ->
                iso_new = Ale8583.addField({head, value},
                {:iso, iso, {bit_map_p, bit_map_s, flag_bm_sec, iso_conf}, status})
                do_decode_ebcdic(tail, new_list, iso_new, acc ++ ["c#{head}": value])

              {:error, message} ->
                {:error, "",
                 {:iso, iso, {bit_map_p, bit_map_s, flag_bm_sec, iso_conf},
                  {:error, "  Error in do_decode_bitmap:  #{message}."}}}
            end
        end

      _ ->
        {:error, "",
         {:iso, iso, {bit_map_p, bit_map_s, flag_bm_sec, iso_conf},
          {:error, "Error field #{head} doesn't exist in configuration file."}}}
    end
  end

  def decode_ascci(bit_map_list, string, iso) do
    do_decode_ascci(bit_map_list, string, iso, [])
  end

  defp do_decode_ascci([], _, iso_new, acc) do
    {:ok, acc, iso_new}
  end

  defp do_decode_ascci(
         [head | tail],
         list,
         {:iso, iso, {bit_map_p, bit_map_s, flag_bm_sec, iso_conf}, status},
         acc
       ) do
    atom_key = "c" <> Integer.to_string(head)

    case List.keyfind(iso_conf, String.to_atom(atom_key), 0) do
      {_, map} ->
        {iso_new, new_list, value}  =
        case get_field_ebcdic_to_string(head, list, map) do
          {:ok, new_list, value} ->
            {Ale8583.addField(
                {head, value},
                {:iso, iso, {bit_map_p, bit_map_s, flag_bm_sec, iso_conf}, status}
              ), new_list, value}
          _ ->
            {{:iso, iso, {bit_map_p, bit_map_s, flag_bm_sec, iso_conf}, status}, list, nil}
        end
        {:iso, _, _, status_b} = iso_new
        case status_b do
          {:ok, _} ->
            do_decode_ascci(tail, new_list, iso_new, acc ++ ["c#{head}": value])
          {:error, message} ->
            Logger.error(" :error, Error to addField:  #{message}.")
            {:error, "",
             {:iso, iso, {bit_map_p, bit_map_s, flag_bm_sec, iso_conf},
              {:error, "  Error to addField:  #{message}."}}}
        end
      _ ->
        {:error, "",
         {:iso, iso, {bit_map_p, bit_map_s, flag_bm_sec, iso_conf},
          {:error,
           "Error field #{head} doesn't exist in configuration file [ #{inspect(iso_conf)} ]."}}}
    end
  end

  defp get_field_ebcdic_to_string(key, list_data, map) do
    length = Kernel.length(list_data)

    length_value =
      cond do
        map.var_length == 0 ->
          map.length

        map.var_length == 2 && length >= 2 ->
          # str_length=String.slice(string,0,2)
          [a, b | _tail] = list_data

          str_length =
            case map.code do
              :ascii ->
                List.to_string([a, b])

              :ebcdic ->
                [a, b] |> Ale8583.Convert.ebcdic_to_ascii() |> List.to_string()
            end

          case Regex.match?(~r/^[0-9]+$/, str_length) do
            true ->
              String.to_integer(str_length) + 2

            false ->
              -2
          end

        map.var_length == 3 && length >= 3 ->
          [a, b, c | _tail] = list_data

          str_length =
            case map.code do
              :ascii ->
                List.to_string([a, b, c])

              :ebcdic ->
                [a, b, c] |> Ale8583.Convert.ebcdic_to_ascii() |> List.to_string()

              :bin ->
                [a, b, c] |> Ale8583.Convert.ebcdic_to_ascii() |> List.to_string()

              :exc_mc_48 ->
                [a, b, c] |> Ale8583.Convert.ebcdic_to_ascii() |> List.to_string()
            end

          case Regex.match?(~r/^[0-9]+$/, str_length) do
            true ->
              String.to_integer(str_length) + 3

            false ->
              -2
          end

        true ->
          -1
      end
      get_field_ebcdic_to_string_sec(map, length_value, length, list_data, key)
  end

  def valid({key, value}, map) when key in 1..128 do
   # Logger.debug(" key #{inspect(key)} - value: #{inspect(value)} - map: #{inspect(map)} ")
    var =
      cond do
        map.var_length == 0 ->
          if String.length(value) != map.length do
            {:error, "#{key} Error in length, should be #{map.length}."}
          else
            {:ok, "OK"}
          end

        map.var_length == 2 || map.var_length == 3 ->
          int_multi =
          case map.code do
            :bin ->
              map.length * 2
            _ ->
              map.length
          end
          if String.length(value) - map.var_length > int_multi do
            {:error,
             "#{key} Error in length, should be #{String.length(value) - map.var_length} > #{
               int_multi}, data: #{value} ."}
          else
            {:ok, "OK"}
          end

        true ->
          {:error, "#{key} Error var_length in configuration iso file,  should be  0 or 2 or 3."}
      end
    {status, _} = var
    if status == :ok do
      do_valid(map.type, key, value )
    else
      var
    end
  end
  def valid({key, _}, _) do
    {:error, "Out range 1..128 #{inspect(key)}"}
  end
  def do_valid(type, key, value) do
      cond do
        type == "B" ->
          case Regex.match?(~r/^[0-9A-Fa-f]+$/, value) do
            true ->
              {:ok, "OK"}

            false ->
              {:error, "#{key} Error data type should be [0-9A-Fa-f] value#{value}\"."}
          end

        type == "N" ->
          case Regex.match?(~r/^[0-9]+$/, value) do
            true ->
              {:ok, "OK"}

            false ->
              {:error, "#{key} Error data type should be [0-9] value#{value}\"."}
          end

        type == "AN" ->
          case Regex.match?(~r/^[0-9A-Za-z]+$/, value) do
            true ->
              {:ok, "OK"}

            false ->
              {:error, "#{key} Error data type should be [0-9A-Za-z] value#{value}\"."}
          end

        type == "ANS" ->
          {:ok, "OK"}

        type ->
          {:error, "#{key} Error type in configuration iso file,  should be N or AN or ANS."}
      end
    end
    defp get_field_ebcdic_to_string_sec(map, length_value, length, list_data, key) do

      cond do
        length_value != -2 && length_value != -1 && length >= length_value ->
          # value= String.slice(string, 0, length_value )
          length_value =
            if map.code == :bin && map.var_length == 0 do
              Kernel.trunc(length_value / 2)
            else
              length_value
            end

          list_value = Enum.take(list_data, length_value)
          value = get_field_ebcdic_to_string_sec2(map, list_value)

          case valid({key, value}, map) do
            {:ok, _} ->
              {:ok, Enum.slice(list_data, length_value, Kernel.length(list_data)), value}

            {:error, msg_error} ->
              {:error, msg_error}
          end

        length_value == -2 ->
          {:error,
           " Error in field #{key} : <field>#{inspect(list_data)}</field>  length is not numeric: \"#{
             length_value
           }\" ."}

        length_value == -1 ->
          {:error,
           " Error in field #{key} : <field>#{inspect(list_data)}</field>  length should be var_length  #{
             map.var_length
           } and length should be <= #{map.length} ."}

        true ->
          {:error,
           " Error in field #{key} : length field for <field>#{inspect(list_data)}</field>   is less to length_value #{
             length_value
           }, check configure var_length:  #{map.var_length} and length should be <= #{map.length} ."}
      end
    end
    defp get_field_ebcdic_to_string_sec2(map, list_value) do
      cond do
        map.code == :ascii ->
          List.to_string(list_value)

        map.code == :ebcdic ->
          list_value |> Ale8583.Convert.ebcdic_to_ascii() |> List.to_string()

        map.code == :bin && map.var_length == 3  ->
            [a, b, c | tail] = list_value
            str_temp = tail |> Ale8583.Convert.bin_to_ascii() |> List.to_string()
            str_temp2 = [a, b, c] |> Ale8583.Convert.ebcdic_to_ascii() |> List.to_string()
            str_temp2 <> str_temp

        map.code == :bin && map.var_length != 3 ->
          list_value |> Ale8583.Convert.bin_to_ascii() |> List.to_string()

        :exc_mc_48 ->
          [a, b, c | tail] = list_value
          str_temp = tail |> Ale8583.Convert.exc_mc_48_to_ascii() |> List.to_string()
          str_temp2 = [a, b, c] |> Ale8583.Convert.ebcdic_to_ascii() |> List.to_string()
          str_temp2 <> str_temp

      end
    end
end
