defmodule Ale8583 do
  require Logger

  @msgs [
    "0100",
    "0190",
    "0110",
    "0120",
    "0130",
    "0200",
    "0210",
    "0220",
    "0230",
    "0400",
    "0410",
    "0420",
    "0421",
    "0430",
    "0800",
    "0810",
    "0620",
    "9100",
    "9190",
    "9110",
    "9120",
    "9130",
    "9200",
    "9210",
    "9220",
    "9230",
    "9400",
    "9410",
    "9420",
    "9421",
    "9430",
    "9800",
    "9810",
    "9620"
  ]
 # @staticFields [:MMDDhhmmss, :hhmmss, :MMDD, :YYMM]

  @moduledoc """
  Documentation for Ale8583, a formater for ISO - 8583 financial transaction standar .

  Examples:
  iex(1)> Ale8583.new({"0800","/Users/ale/testPrograms/ale8583/ale8583/ascii.iso.cfg"})
  {:iso ,.. {:ok, "OK"}}

  """
  @spec new({any(), any()}) :: {:error, [], <<_::704>>} | {:error, [], {}, <<_::64, _::_*8>> | {:error, <<_::64, _::_*8>>}} | {:iso, [{:bp, <<_::128>>} | {:bs, <<_::128>>} | {:header_prosa, <<>>} | {:mti, any()}, ...], {[any()], [any()], :flag_bm_sec_no, any()}, {:ok, <<_::16>>}}
  def new({mti, b}, headerProsa \\ "") do
    cond do
      is_bitstring(mti) && is_bitstring(b) ->
        Logger.info("-------------------------------------------------------------> :path")
        new(:path, {mti, b}, headerProsa)

      is_bitstring(mti) && is_list(b) ->
        Logger.info("-------------------------------------------------------------> :conf")
        new(:conf, {mti, b}, headerProsa)

      true ->
        {:error, [],
         "Error first mti should be bitstring type, second parameter should be list or bitstring ."}
    end
  end


  @doc """
  Function for validate if a field have in ISO.

  Returns `true` or `false`

  Examples

  """
  def haveInISO?({_, list_iso, {_, _, _, _}, _}, atom_field) do
    List.keymember?(list_iso, atom_field, 0)
  end

  @doc """

  Function for validate if a field have in bitmap.

  Returns `true` or `false`
  #Examples

  """
  def haveInBitMap?(str_bit_map, int_field) do
    list_bit_map = Ale8583.BitMap.get_list_bit_map(str_bit_map)
    #  Logger.debug " inspect #{inspect list_bit_map}"
    if int_field in list_bit_map do
        true
    else
        false
    end
  end

  @doc """

  Function for get field from iso  .

  Returns `value`

  Examples:
  iex(1)>iso_new = Ale8583.new({"0800","/Users/ale/testPrograms/ale8583/ale8583/ascii.iso.cfg"})
  {:iso, ... , {:ok, "OK"}}
  iex(18)> iso_new  = Ale8583.addField({ 3 , "012345"}, iso_new)
  iex(19)>  Ale8583.getField( :c3 , iso_new)
  {:ok, "012345"}

  """
  def getField(field, {:iso, list_iso, _, _}) do
    atom_key =
      case is_atom(field) do
        true ->
          field

        false ->
          String.to_atom("c" <> Integer.to_string(field))
      end

    case List.keymember?(list_iso, atom_key, 0) do
      false ->
        {:error, "Field #{atom_key} is'nt present, :getField->keymember"}

      true ->
        case List.keyfind(list_iso, atom_key, 0) do
          {_, value} ->
            {:ok, value}

          _ ->
            {:error, "Field #{atom_key} is'nt present, :getField->keyfind."}
        end
    end
  end

  @doc """
  Function for add field to ISO.

  Returns `iso`

  ##Examples

   iex(1)> iso_new=Ale8583.new({"0800","/Users/ale/testPrograms/ale8583/ale8583/ascii.iso.cfg"})
   {:iso, ...  {:ok, "OK"}}
   iex(3)> Ale8583.addField({3, "012345"}, iso_new)
   :ok

  """
  def addField(
        {key, value},
        {:iso, list_iso, {list_bit_map_p, list_bit_map_s, flag_bm_sec, list_iso_conf}, _}
      ) do

    {atom_key, key} =
      case is_atom(key) do
        true ->
          {key, key |> Atom.to_string() |> String.slice(1, 10) |> String.to_integer()}

        false ->
          {String.to_atom("c" <> Integer.to_string(key)), key}
      end

    value =
      if is_atom(value) == true do
        static_field(value)
      else
        value
      end

    case List.keyfind(list_iso_conf, atom_key, 0) do
      {_, map} ->
        case Ale8583.ValidISO.valid({key, value}, map) do
          {:ok, _} ->
            sec_add_field(key, atom_key, value, list_bit_map_p, list_bit_map_s, list_iso, flag_bm_sec, list_iso_conf)

          {:error, msg_error} ->
            Logger.error(" :error #{msg_error}")
            {:iso, list_iso, {list_bit_map_p, list_bit_map_s, flag_bm_sec, list_iso_conf},
             {:error, msg_error}}
        end
      _ ->
        {:iso, list_iso, {list_bit_map_p, list_bit_map_s, flag_bm_sec, list_iso_conf},
         {:error, "Error field #{key} doesn't exist in configuration file."}}
    end
  end

  defp static_field(static_atom) do
    case static_atom do
      :MMDDhhmmss ->
        date = DateTime.utc_now()

        # Logger.debug "MM:#{date.month}DD:#{date.day}HH:#{date.hour}mm:#{date.minute}ss:#{date.second}"
        "#{formatZero(date.month, 2)}#{formatZero(date.day, 2)}#{formatZero(date.hour, 2)}#{
          formatZero(date.minute, 2)
        }#{formatZero(date.second, 2)}"

      :hhmmss ->
        date = DateTime.utc_now()
        "#{formatZero(date.hour, 2)}#{formatZero(date.minute, 2)}#{formatZero(date.second, 2)}"

      :MMDD ->
        date = DateTime.utc_now()
        "#{formatZero(date.month, 2)}#{formatZero(date.day, 2)}"

      :YYMM ->
        date = DateTime.utc_now()
        yy = date.year - 2000
        "#{formatZero(yy, 2)}#{formatZero(date.month, 2)}"

      :auditNumber ->
        "#{formatZero(Enum.random(0..999_999), 6)}"

      :seqNumber ->
        "#{formatZero(Enum.random(0..999_999_999_999), 12)}"

      _ ->
        to_string(static_atom)
    end
  end

  def formatZero(int_value, int_zeros) do
    str_value = Integer.to_string(int_value)

    cond do
      String.length(str_value) == int_zeros ->
        str_value

      String.length(str_value) < int_zeros ->
        int_rest = int_zeros - String.length(str_value)
        to_string(for _ <- 1..int_rest, do: '0') <> str_value

      true ->
        Logger.warn(
          "El valor a formatear es mas grande del valor requerido ( #{String.length(str_value)} < #{
            int_zeros
          }), se procede a regresar el valor sin cumplir con el formato. "
        )

        str_value
    end
  end

  @doc """

  Function for validate if bitMap has bitMap secondary .

  Returns `true` or `false`

  Examples:
  iex(4)> Ale8583.have_bit_map_sec?("888812A088888888")
  true
  iex(5)> Ale8583.have_bit_map_sec?("688812A088888888")
  false

  """
  def have_bit_map_sec?(str_bit_map_p) do
    Ale8583.BitMap.haveBitMapSec?(str_bit_map_p)
  end

  @doc """

  Function for get raw data, witout length.

  Returns `raw`
  Examples
  iex(1)> iso_new=Ale8583.new({"0800","/Users/ale/testPrograms/ale8583/ale8583/ascii.iso.cfg"})
  {:iso,... {:ok, "OK"}}
  iex(3)> Ale8583.getTrama(iso_new)
  '08002000000000000000012345'
  """
  def getTrama({:iso, list_iso, {_, _, _, list_iso_conf}, _}) do
    {_, str_mti} = List.keyfind(list_iso, :mti, 0)
    {_, str_bp} = List.keyfind(list_iso, :bp, 0)
    {_, str_bs} = List.keyfind(list_iso, :bs, 0)
    {_, str_header_prosa} = List.keyfind(list_iso, :header_prosa, 0)
    # value=getAppendISO( list_iso, list_iso_conf)
    list = List.keydelete(list_iso, :mti, 0)
    list = List.keydelete(list, :bp, 0)
    list = List.keydelete(list, :bs, 0)
    list = List.keydelete(list, :header_prosa, 0)

    value =
      getAppendISO(
        Enum.sort_by(list, fn {atom, _} ->
          String.to_integer(String.slice(Atom.to_string(atom), 1..5))
        end),
        list_iso_conf
      )

    #Logger.debug("[#{str_mti}|#{str_bp}|#{str_bs}|#{inspect(value)}]")

    {_, map} = List.keyfind(list_iso_conf, :bp, 0)

    {str_bp, str_bs_bs, str_mti, str_header_prosa} =
      case map.code do
        :ascii ->
          {String.to_charlist(str_bp), String.to_charlist(str_bs), String.to_charlist(str_mti),
           String.to_charlist(str_header_prosa)}

        :ebcdic ->
          {str_bp |> String.to_charlist() |> Ale8583.Convert.ascii_to_ebcdic(),
           str_bs |> String.to_charlist() |> Ale8583.Convert.ascii_to_ebcdic(),
           str_mti |> String.to_charlist() |> Ale8583.Convert.ascii_to_ebcdic(), []}

        :bin ->
          {str_bp |> String.to_charlist() |> Ale8583.Convert.ascii_to_bin(),
           str_bs |> String.to_charlist() |> Ale8583.Convert.ascii_to_bin(),
           str_mti |> String.to_charlist() |> Ale8583.Convert.ascii_to_ebcdic(), []}
      end

    #Logger.debug("[#{inspect(str_mti)}|#{inspect(str_bp)}|#{inspect(str_bs)}|#{inspect(value)}]")

    case str_bs do
      "0000000000000000" ->
        str_header_prosa ++ str_mti ++ str_bp ++ value

      _ ->
        str_header_prosa ++ str_mti ++ str_bp ++ str_bs_bs ++ value
    end
  end

  @doc """

  Function for get ISO from list(RAW data without length).

  Returns `iso`



  """
  def list_to_iso({str_bit_map, list, type, str_header_prosa}, iso) do
    list_bit_map = Ale8583.BitMap.get_list_bit_map(str_bit_map)
    #Logger.debug("BitMap: #{str_bit_map}  List:#{inspect list_bit_map}")
    cond do
      type in [:prosa, :mc] ->
        iso =
          if type == :prosa do
            {:iso, list_iso, {bit_map_p, bit_map_s, flag_bm_sec, iso_conf}, status} = iso
            list_iso = List.keyreplace(list_iso, :header_prosa, 0, {:header_prosa, str_header_prosa})
            {:iso, list_iso, {bit_map_p, bit_map_s, flag_bm_sec, iso_conf}, status}
          else
            iso
          end

        case Ale8583.ValidISO.decode_ascci(list_bit_map, list, iso) do
          {:ok, _, new_iso} ->
            new_iso

          {:error, _, iso_error} ->
            iso_error
        end

      type == :master_card ->
        case Ale8583.ValidISO.decode_ebcdic(list_bit_map, list, iso) do
          # { :ok, acc, iso_new }
          {:ok, _, new_iso} ->
            Logger.warn("DECODE EBCDIC #{inspect(new_iso)}")
            new_iso

          {:error, _, iso_error} ->
            iso_error
        end

      true ->
        iso =
          setStatusISO(iso, {:error, "Type is not valid, use :prosa or :master_card or :mc ."})

        iso
    end
  end

  @doc """
  Function for  prints a prety fields ISO.
  ## Examples


  """
  def printAll({atom_iso, list_iso, {_, _, _, list_iso_conf}, _}, extra) do
    case atom_iso do
      :iso ->
        {_, mti} = List.keyfind(list_iso, :mti, 0)
        {_, bp} = List.keyfind(list_iso, :bp, 0)
        {_, bs} = List.keyfind(list_iso, :bs, 0)

        extra =
          extra <> "\n" <> "mti<#{mti}>" <> "\n" <> "bp<#{bp}>" <> "\n" <> "bs<#{bs}>" <> "\n"

        list_iso = List.keydelete(list_iso, :mti, 0)
        list_iso = List.keydelete(list_iso, :bp, 0)
        list_iso = List.keydelete(list_iso, :bs, 0)
        list_iso = List.keydelete(list_iso, :header_prosa, 0)

        do_printAll(
          Enum.sort_by(list_iso, fn {atom, _} ->
            String.to_integer(String.slice(Atom.to_string(atom), 1..5))
          end),
          list_iso_conf,
          extra
        )

      # do_printAll(list_iso |> Enum.sort, list_iso_conf, extra)
      _ ->
        Logger.error("Error in printAll function, atom :iso is not present.")
    end
  end

  def setConf(path) do
    case File.open(path) do
      {:ok, file} ->
        ## |> TermParser.parse
        list = Ale8583.BlockReader.read!(file)
        list

      {:error, reason} ->
        {:error, reason}
    end
  end

  @doc """
  Public function for get list support msgs.

  Returns `@msgs`

  Examples
  iex(3)> Ale8583.msgs
  ["0100", "0190", "0110", "0120", "0130", "0200", "0210", "0220", "0230", "0400",
  "0410", "0420", "0421", "0430", "0800", "0810", "0620", "9100", "9190", "9110",
  "9120", "9130", "9200", "9210", "9220", "9230", "9400", "9410", "9420", "9421",
  "9430", "9800", "9810", "9620"]

  """
  def msgs do
    @msgs
  end

  @doc """
  Private function for create new iso from configuration list.

  Returns `iso`

  """
  defp new(:conf, {mti, list_conf}, headerProsa) do
    case mti in @msgs do
      true ->
        {:iso, [mti: mti, bp: "0000000000000000", bs: "0000000000000000", header_prosa: headerProsa],
         {Ale8583.BitMap.newBitMapP(), Ale8583.BitMap.newBitMapS(), :flag_bm_sec_no, list_conf},
         {:ok, "OK"}}

      false ->
        {:error, [], {}, "Error MTI no valid:  #{mti}, Those mtis ara valid: #{@msgs}."}
    end
  end

  @doc """
  Private function for create new iso from file configuration path.

  Returns `iso`

  """
  defp new(:path, {mti, path}, headerProsa) do
    case setConf(path) do
      {:ok, list_conf} ->
        case mti in @msgs do
          true ->
            {:iso, [mti: mti, bp: "0000000000000000", bs: "0000000000000000", header_prosa: headerProsa],
             {Ale8583.BitMap.newBitMapP(), Ale8583.BitMap.newBitMapS(), :flag_bm_sec_no, list_conf},
             {:ok, "OK"}}

          false ->
            {:error, [], {}, "Error MTI no valid:  #{mti}, Those mtis ara valid: #{@msgs}."}
        end

      {:error, reason} ->
        {:error, [], {}, {:error, "Error when try load file configuration #{reason}."}}
    end
  end

  @doc """
  Private function logic for create print buffer from iso fields.

  Returns `nothing`

  """
  defp do_printAll([head | tail], list_iso_conf, buffer) do
    {key, value} = head
    # Logger.warn "key #{inspect key}, value #{inspect value} isoList #{inspect list_iso_conf}"
    buffer =
      if key in [:mti, :bp, :bs, :header_prosa] do
          buffer
        # buffer = buffer <> "#{key}<#{value}>\n"
      else
        {_, map} = List.keyfind(list_iso_conf, key, 0)
        case map.var_length do
          0 ->
            buffer <> " #{key}<#{value}>\n"
          2 ->
            buffer <> " #{key}<#{String.slice(value, 0, 2)}>\n"
            buffer <> " #{key}<#{String.slice(value, 2..(map.length + 1))}>\n"
          3 ->
            buffer <> " #{key}<#{String.slice(value, 0, 3)}>\n"
            buffer <> " #{key}<#{String.slice(value, 3..(map.length + 1))}>\n"
        end
      end
    do_printAll(tail, list_iso_conf, buffer)
  end

  @doc """
  Private function to catch buffer for  print.

  Returns `iso`

  """
  defp do_printAll([], _, buffer) do
    Logger.error(buffer)
  end

  @doc """
  Private function .

  Returns `tuple`

  """
  defp setStatusISO({:iso, list_iso, conf, _}, {result, message}) do
    {:iso, list_iso, conf, {result, message}}
  end

  @doc """
  Private function .

  Returns `iso`

  """
  defp getAppendISO(list_iso, list_iso_conf) do
    do_getAppendISO(list_iso, list_iso_conf, [])
  end


  @doc """
  Private function  for logic from getAppendISO() funtion .

  Returns `nothing`

  """
  defp do_getAppendISO([head | tail], list_iso_conf, acc) do
    {atom_key, value} = head
    # Logger.debug(" atom_key #{inspect atom_key}")
    if atom_key in [:header_prosa, :bs, :bp, :mti, :c1] do
      do_getAppendISO(tail, list_iso_conf, acc)
    else
      # Logger.debug "Ale8583Worker.append { #{atom_key}::[#{value}] "
      {_atom_key, map} = List.keyfind(list_iso_conf, atom_key, 0)
      # Logger.debug "Ale8583Worker.append { #{atom_key}::[#{value}] #{map.code} "
      value =
        case map.code do
          :exc_mc_48 ->
            value |> String.to_charlist() |> Ale8583.Convert.ascii_to_exc_mc_48()
          :ebcdic ->
            value |> String.to_charlist() |> Ale8583.Convert.ascii_to_ebcdic()
          :ascii ->
            String.to_charlist(value)
          :bin ->
            value |> String.to_charlist() |> Ale8583.Convert.ascii_to_bin()
        end
      do_getAppendISO(tail, list_iso_conf, acc ++ value)
    end
  end


  @doc """
  Private function  to  catch accoumulator from getAppendISO() funtion .

  Returns `acc`

  """
  defp do_getAppendISO([], _, acc) do
    acc
  end


  @doc """
  Private function .

  Returns `iso`

  """
  defp sec_add_field(key, atom_key, value, list_bit_map_p, list_bit_map_s, list_iso, flag_bm_sec, list_iso_conf) do
    case List.keymember?(list_iso, atom_key, 0) do
      true ->
        {:iso, list_iso |> List.keyreplace(atom_key, 0, {atom_key, value}) |> Enum.sort(),
         {list_bit_map_p, list_bit_map_s, flag_bm_sec, list_iso_conf}, {:ok, "OK UPDATE"}}
      false ->
        list_iso = (list_iso ++ ["c#{key}": value]) |> Enum.sort()
        cond do
          key in 1..64 ->
            list_bit_map_p = Ale8583.BitMap.modifyInsert(list_bit_map_p, atom_key)
            list_iso =
              List.keyreplace(
              list_iso,
              :bp,
              0,
              {:bp, Ale8583.BitMap.getBitMapHex(list_bit_map_p)}
            )
            {:iso, list_iso, {list_bit_map_p, list_bit_map_s, flag_bm_sec, list_iso_conf},
            {:ok,
              "OK INSERT AND PRIMARY BITMAP UPDATE,#{atom_key}-#{key}: value #{value}"}}

          key in 65..128 ->
            {list_bit_map_p, flag_bm_sec, list_iso} =
            if flag_bm_sec == :flag_bm_sec_no do
              #Logger.debug("flag_bit_map_sec #{flag_bm_sec} ")
              list_bit_map_p_temp = Ale8583.BitMap.modifyInsert(list_bit_map_p, :c1)
              list_iso_temp = List.keyreplace(
                  list_iso,
                  :bp,
                  0,
                  {:bp, Ale8583.BitMap.getBitMapHex(list_bit_map_p_temp)}
                )
              {list_bit_map_p_temp,
                :flag_bm_sec_yes,
                list_iso_temp}
            else
              {list_bit_map_p, flag_bm_sec, list_iso}
            end

            #Logger.debug("List bit mapP : #{inspect list_bit_map_p}\n Flag bm Sec:  #{flag_bm_sec}, \n #{inspect list_iso}")
            list_bit_map_s = Ale8583.BitMap.modifyInsert(list_bit_map_s, atom_key)
            {:iso,
              List.keyreplace(
                list_iso,
                :bs,
                0,
                {:bs, Ale8583.BitMap.getBitMapHex(list_bit_map_s)}
              ), {list_bit_map_p, list_bit_map_s, flag_bm_sec, list_iso_conf},
              {:ok,
                "OK INSERT AND SECUNDARY BITMAP UPDATE,#{atom_key}-#{key}: value #{value}"}}

          true ->
            {:iso, list_iso, {list_bit_map_p, list_bit_map_s, flag_bm_sec, list_iso_conf},
            {:ok, "FIELD NOT SUPPORTED, FIELD SHOULD BE BETWEEN 2..128."}}
        end
      end
  end
end
