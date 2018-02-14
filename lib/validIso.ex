defmodule Ale8583.ValidISO do
  require Logger 
  @moduledoc """
  MODULE Ale8583.ValidUSI contains functions for ISO validation/format/decode/code  .
  """

  @doc """
    
  Function for EBCDIC decode .

  """
  def decodeEBCDIC(bitMapList, list, iso) do
    do_decodeEBCDIC(bitMapList,list,iso,[])
  end
  defp do_decodeEBCDIC( [], _ , iso_new, acc) do
    { :ok, acc, iso_new } 
  end
  defp do_decodeEBCDIC([head|tail], list, {:iso ,iso,{bitMapP,bitMapS,flagBMSec,isoConf}, status}, acc)  do
    atomKey="c" <> Integer.to_string(head)
    case List.keyfind(isoConf, String.to_atom(atomKey) ,0) do 
      { _, map} -> 
      case atomKey do 
	"c1" ->
		do_decodeEBCDIC(tail,list,{:iso ,iso,{bitMapP,bitMapS,flagBMSec,isoConf}, status}, acc)
	_ ->  
	 
      case getField_ebcdic_to_string( head, list, map) do 
        { :ok, new_list, value} ->
          case  Ale8583.do_addField({head,value},{:iso ,iso,{bitMapP,bitMapS,flagBMSec,isoConf}, status}) do 
            { :ok , iso_new } ->
		Logger.warn " SAVE VALUE -------------------------------#{value}---------------------------------" 
              do_decodeEBCDIC( tail, new_list, iso_new, acc ++ [  "c#{head}": value ])
            { :error, { _ , _ ,_ , { _ , message}} } ->
              Logger.error " :error, Error to addField:  #{message}." 
              { :error, "",  {:iso ,iso,{bitMapP,bitMapS,flagBMSec,isoConf},{:error,"  Error to addField:  #{message}."} }}
          end
        { :error, message} ->
            { :error, "",  {:iso ,iso,{bitMapP,bitMapS,flagBMSec,isoConf},{:error,"  Error in do_decode_bitmap:  #{message}."} }}
     end  
     end
      _ ->
        { :error, "",  {:iso ,iso,{bitMapP,bitMapS,flagBMSec,isoConf},{:error,"Error field #{head} doesn't exist in configuration file."} }}
    end
  end
  def decodeASCCI(bitMapList, string, iso) do
    do_decodeASCCI(bitMapList,string,iso,[])
  end 
  defp do_decodeASCCI( [], _ , iso_new, acc) do
    { :ok, acc, iso_new } 
  end
  defp do_decodeASCCI([head|tail], list, {:iso ,iso,{bitMapP,bitMapS,flagBMSec,isoConf}, status}, acc)  do
    atomKey="c" <> Integer.to_string(head)
    #Logger.info "INSPECT #{inspect head}"
    case List.keyfind(isoConf, String.to_atom(atomKey) ,0) do 
      { _, map} -> 
        case getField_ebcdic_to_string( head, list, map) do 
          { :ok, new_list, value} ->
            #Logger.info "INSPECT #{inspect head}"
            case  Ale8583.do_addField({head,value},{:iso ,iso,{bitMapP,bitMapS,flagBMSec,isoConf}, status}) do 
              { :ok , iso_new } -> 
                do_decodeASCCI( tail, new_list, iso_new, acc ++ [  "c#{head}": value ])
              { :error, { _ , _ ,_ , { _ , message}} } ->
                Logger.error " :error, Error to addField:  #{message}." 
              { :error, "",  {:iso ,iso,{bitMapP,bitMapS,flagBMSec,isoConf},{:error,"  Error to addField:  #{message}."} }}
            end
        end
      _ ->
        { :error, "",  {:iso ,iso,{bitMapP,bitMapS,flagBMSec,isoConf},{:error,"Error field #{head} doesn't exist in configuration file."} }}
    end
  end 
#  defp getField(key,list,map) do
#    string= List.to_string(list)
#    length=String.length(string)
#    cond do
#      map.var_length == 0 -> 
#        lengthValue = map.length
#      map.var_length== 2 && length>=2  ->
#        strLength=String.slice(string,0,2)
#        case Regex.match?(~r/^[0-9]+$/, strLength) do
#          true ->
#            lengthValue = String.to_integer(strLength)+2   
#          false->
#            lengthValue=-2
#        end
#      map.var_length== 3 && length>=3  -> 
#        strLength=String.slice(string,0,3)
#        case Regex.match?(~r/^[0-9]+$/, strLength) do
#         true ->
#            lengthValue = String.to_integer(strLength)+3   
#          false->
#            lengthValue=-2
#        end
#      true -> 
#        lengthValue=-1; 
#    end
#    cond do
#      lengthValue != -2 && lengthValue != -1 && length >= lengthValue  ->
#        value= String.slice(string, 0, lengthValue )
#        case valid({key, value}, map) do
#          { :ok, _ } -> { :ok, String.slice(string, lengthValue , length ), value}  
#          { :error, msgError } -> { :error , msgError } 
#        end
#      lengthValue == -2 ->
#          { :error, " Error in field #{key} : <field>#{string}</field>  length is not numeric: \"#{strLength}\" Value +15: \"#{String.slice(string,0,15)}\"."}          
#      lengthValue == -1 ->
#        { :error, " Error in field #{key} : <field>#{string}</field>  length should be var_length  #{map.var_length} and length should be <= #{map.length} ."}  
#      true -> { :error , " Error in field #{key} : length field for <field>#{string}</field>   is less to lengthValue #{lengthValue}, check configure var_length:  #{map.var_length} and length should be <= #{map.length} ."}  
#    end
#  end
  defp getField_ebcdic_to_string(key, listData, map) do
    length=Kernel.length(listData)
    lengthValue=
    cond do
      map.var_length == 0 -> 
        map.length
      map.var_length== 2 && length>=2  ->
        #strLength=String.slice(string,0,2)
        [a,b|_]=listData
        strLength=
        case map.code do
          :ascii ->
            List.to_string([a,b])
          :ebcdic ->
            Ale8583.Convert.ebcdic_to_ascii([a,b]) |>  List.to_string
        end
        case Regex.match?(~r/^[0-9]+$/, strLength) do
          true ->
            String.to_integer(strLength)+2   
          false->
            -2
        end
      map.var_length== 3 && length>=3  -> 
        [a,b,c|_]=listData
        strLength=
        case map.code do
          :ascii ->
            List.to_string([a,b,c])
          :ebcdic ->
            Ale8583.Convert.ebcdic_to_ascii([a,b,c]) |> List.to_string
        end
        case Regex.match?(~r/^[0-9]+$/, strLength) do
          true ->
            String.to_integer(strLength)+3   
          false->
            -2
        end
      true -> 
        -1 
    end
    cond do
      lengthValue != -2 && lengthValue != -1 && length >= lengthValue  ->
        listValue=Enum.take(listData, lengthValue ) 
        value=
        case map.code do
          :ascii ->
            List.to_string(listValue)
          :ebcdic ->
            Ale8583.Convert.ebcdic_to_ascii(listValue) |> List.to_string
        end
	      case valid({key, value}, map) do
          { :ok, _ } -> 
            { :ok, Enum.slice( listData, lengthValue, Kernel.length(listData)) , value}
          { :error, msgError } -> 
            { :error , msgError } 
        end
      lengthValue == -2 ->
          { :error, " Error in field #{key} : <field>#{inspect listData}</field>  length is not numeric  ."}  
        
      lengthValue == -1 ->
        { :error, " Error in field #{key} : <field>#{inspect listData}</field>  length should be var_length  #{map.var_length} and length should be <= #{map.length} ."}  
      true -> 
        { :error , " Error in field #{key} : length field for <field>#{inspect listData}</field>   is less to lengthValue #{lengthValue}, check configure var_length:  #{map.var_length} and length should be <= #{map.length} ."}  
    end
  end
  def valid({key,value},map) when key in 1..128 do
    var=
    cond do 
      map.var_length == 0 -> 
        if String.length(value) != map.length  do
          {:error,"#{key} Error in length, should be #{map.length}."} 
        else
          {:ok,"OK"}
        end
      map.var_length == 2 || map.var_length == 3 ->
        if( String.length(value)-map.var_length > map.length) do
          {:error,"#{key} Error in length, should be #{String.length(value)-map.var_length} > #{map.length}, data: #{value} ."} 
        else
          {:ok,"OK"}
        end
      true  ->
        {:error,"#{key} Error var_length in configuration iso file,  should be  0 or 2 or 3."} 
    end
    {status, _ } = var
    var=
    if status == :ok do
     cond do
       map.type == "B" ->
         case Regex.match?(~r/^[0-9A-Fa-f]+$/,value) do
             true ->
               {:ok,"OK"}
             false ->
               {:error,"#{key} Error data type should be [0-9A-Fa-f] value#{value}\"."}
         end
       map.type  == "N" ->
         case Regex.match?(~r/^[0-9]+$/,value) do
             true ->
               {:ok,"OK"}
             false ->
               {:error,"#{key} Error data type should be [0-9] value#{value}\"."}
         end
       map.type == "AN" ->
         case Regex.match?(~r/^[0-9A-Za-z]+$/,value) do
             true ->
               {:ok,"OK"}
             false ->
               {:error,"#{key} Error data type should be [0-9A-Za-z] value#{value}\"."}
         end
       map.type == "ANS" ->
         {:ok,"OK"}
       map.type  ->  
         { :error, "#{key} Error type in configuration iso file,  should be N or AN or ANS."} 
     end
    else
      var 
    end 
    var
  end
  def valid({key,_},_) do
    {:error, "Out range 1..128 #{inspect key}"}
  end
  def headerPROSA(value)  do
    cond do
      String.length(value)!= 12 ->
        {:error,  "ISO PROSA HEADER  length shpuld be 12 but is #{String.length(value)} ."}
      String.slice(value,0,3) != "ISO" ->
        {:error,  "ISO HEAD IS NOT IN :header_prosa."}
      true ->
        { :ok,  "OK INSERT PROSA HEADER."}
    end
  end
end

