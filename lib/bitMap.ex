defmodule Ale8583.BitMap do
   @moduledoc """
  MODULE Ale8583.BitMap contains functions for bitmap validation/format  .
  """


  @doc """
    
  Function for make a new bitMap Primary.

  """
  def newBitMapP() do 
    numbers=Enum.to_list(1..64)
    Enum.map( numbers, fn x -> [ "c#{x}": 0 ]  end ) |> List.flatten
  end

  @doc """
    
  Function for make a new bitMap Secondary.

  """ 
  def newBitMapS() do 
    numbers=Enum.to_list(65..128)
    Enum.map( numbers, fn x -> [ "c#{x}": 0 ]  end ) |> List.flatten
  end

  def getListBitMap( strBitMap ) do 
    cond  do 
      String.length(strBitMap)==16 ||  String.length(strBitMap)==32  ->
        case Regex.match?(~r/^[0-9A-Fa-f]+$/, strBitMap) do
          true ->
            do_getListBitMapp(strBitMap) 
          false -> { :error, "#{strBitMap} Error data type should be [0-9A-Fa-f]."}
        end
      true -> { :error, "Length bitmap error , should be 16 or 32, I received #{String.length(strBitMap)}."}
    end
  end
  def haveBitMapSec?(strBitMap) do
    chrBit=String.slice(strBitMap,0,1)
    cond do
      chrBit in [ "F","E","D","C","B","A","9","8"] ->
        true
      true ->
       false 
    end
  end

  defp do_getListBitMapp( strBitMap )  do
    bitMapIndex=strBitMap |> String.graphemes |> Enum.with_index  
    Enum.reduce( bitMapIndex , [],  fn( { bit, index} , acc) ->
      fac = index * 4;
      #IO.puts(" bit:#{bit}:index:#{index}:fac:#{fac}")
      case bit do
        "F" -> acc ++ [ 1 + fac, 2 + fac, 3 + fac, 4 + fac]
        "E" -> acc ++ [ 1 + fac, 2 + fac, 3 + fac         ]
        "D" -> acc ++ [ 1 + fac, 2 + fac,          4 + fac]
        "C" -> acc ++ [ 1 + fac, 2 + fac                  ]
        "B" -> acc ++ [ 1 + fac,          3 + fac, 4 + fac]  
        "A" -> acc ++ [ 1 + fac,          3 + fac         ]
        "9" -> acc ++ [ 1 + fac,                   4 + fac]
        "8" -> acc ++ [ 1 + fac                           ]
        "7" -> acc ++ [          2 + fac, 3 + fac, 4 + fac]
        "6" -> acc ++ [          2 + fac, 3 + fac         ]
        "5" -> acc ++ [          2 + fac,          4 + fac]
        "4" -> acc ++ [          2 + fac                  ]
        "3" -> acc ++ [                   3 + fac, 4 + fac]
        "2" -> acc ++ [                   3 + fac         ]
        "1" -> acc ++ [                            4 + fac]
        _   -> acc ++ [                                   ]
      end #case 
    end ) # reduce 
  end
  def modifyInsert(listBitMap, atomKey)  do 
    List.keyreplace(listBitMap, atomKey, 0, { atomKey, 1 })
  end
  def modifyDelete(listBitMap, atomKey)  do 
    List.keyreplace(listBitMap, atomKey, 0, { atomKey, 0 })
  end
  def getBitMapHex(listBitMap) do
    do_getBitMapHex(listBitMap, "")
  end
  defp do_getBitMapHex([{_,h1},{_,h2},{_,h3},{_,h4}|tail], acc) do
    byte=Integer.to_string(h1) <> Integer.to_string(h2) <> Integer.to_string(h3) <> Integer.to_string(h4)  
    acc=
    case byte do 
      "0000" ->  acc <> "0"
      "0001" ->  acc <> "1"
      "0010" ->  acc <> "2"
      "0011" ->  acc <> "3"
      "0100" ->  acc <> "4"
      "0101" ->  acc <> "5"
      "0110" ->  acc <> "6"
      "0111" ->  acc <> "7"
      "1000" ->  acc <> "8"
      "1001" ->  acc <> "9"
      "1010" ->  acc <> "A"
      "1011" ->  acc <> "B"
      "1100" ->  acc <> "C"
      "1101" ->  acc <> "D"
      "1110" ->  acc <> "E"
      "1111" ->  acc <> "F"
    end
    do_getBitMapHex(tail,acc)
  end
  defp do_getBitMapHex([],acc) do
    acc
  end 
end
