defmodule Ale8583 do
  require  Logger
  @msgs ["0100", "0190", "0110", "0120","0130","0200","0210","0220","0230", "0400", "0410","0420","0430", "0800","0810"] 
  @moduledoc """
  Documentation for Ale8583, a formater for ISO - 8583 financial transaction standar .
  """


  @doc """
    
  Function for validate if a field have in ISO.

  Returns `true` or `false` 

  Examples
  iex(15)>  Ale8583.haveInISO?( iso_new, :c3)
true
iex(16)>  Ale8583.haveInISO?( iso_new, :c4)
false
iex(17)>
  """
  def haveInISO?({_,listISO,{_,_,_,_},_} , atomField) do
     List.keymember?(listISO, atomField, 0)
  end
  
  @doc """
    
  Function for validate if a field have in bitmap.

  Returns `true` or `false` 
  #Examples 
  iex(4)> iso_new2= Ale8583.haveBitMapSec?("888812A088888888")
  true
  iex(5)> iso_new2= Ale8583.haveBitMapSec?("688812A088888888")
  false
  iex(6)>
  """
  def haveInBitMap?( strBitMap, intField) do
    listBitMap=Ale8583.BitMap.getListBitMap(strBitMap)
  #  Logger.debug " inspect #{inspect listBitMap}"
    cond do
      intField in listBitMap ->
        true 
      true  ->
        false
    end
  end
  @doc """
    
  Function for get raw data, witout length.

  Returns `raw`
  Examples
  iex(17)>  Ale8583.getTrama iso_new
'08002000000000000000012345'
iex(18)>
  """
  def  getTrama({:iso,listISO,{_,_,_,listISOconf},_}) do
    {_,strMTI} = List.keyfind(listISO,:mti,0)
    {_,strBP} = List.keyfind(listISO,:bp,0)
    {_,strBS} = List.keyfind(listISO,:bs,0)
    {_,strHeaderProsa} = List.keyfind(listISO, :header_prosa,0)
    #value=getAppendISO( listISO, listISOconf)
    list= List.keydelete(listISO, :mti, 0)	 
    list= List.keydelete(list, :bp, 0)	 
    list= List.keydelete(list, :bs, 0)	 
    list= List.keydelete(list, :header_prosa, 0)	 
    value=getAppendISO(Enum.sort_by(list, fn { atom, _  } ->  
			  String.to_integer(String.slice(Atom.to_string(atom), 1..5))
	end ), listISOconf) 
    #Logger.debug "[#{strMTI}|#{strBP}|#{strBS}|#{inspect value}]"
    
    { _ , map } = List.keyfind(listISOconf, :bp, 0 )
    strBP=
    case map.code do 
      :ascii ->
        String.to_charlist(strBP)
      :ebcdic -> 
        String.to_charlist(strBP) |> Ale8583.Convert.ascii_to_ebcdic
      :bin ->
        String.to_charlist(strBP) |> Ale8583.Convert.ascii_to_bin
    end
    strBSBS=
    case map.code do 
      :ascii ->
        String.to_charlist(strBS)
      :ebcdic -> 
        String.to_charlist(strBS) |> Ale8583.Convert.ascii_to_ebcdic
      :bin ->
        String.to_charlist(strBS) |> Ale8583.Convert.ascii_to_bin
      end
      strMTI=
      case map.code do 
        :ascii ->
          String.to_charlist(strMTI)
        :ebcdic -> 
          String.to_charlist(strMTI) |> Ale8583.Convert.ascii_to_ebcdic
        :bin ->
          String.to_charlist(strMTI) |> Ale8583.Convert.ascii_to_ebcdic
        end
        strHeaderProsa = 
        case map.code do 
          :ascii ->
            String.to_charlist(strHeaderProsa)
          _ -> 
            []
          end
      #Logger.debug "[#{inspect strMTI}|#{inspect strBP}|#{inspect strBS}|#{inspect value}]"
   	case strBS do
		"0000000000000000" ->
			strHeaderProsa ++ strMTI ++ strBP ++ value
  		_ ->  
			strHeaderProsa ++ strMTI ++ strBP ++ strBSBS ++ value 
	end
  end 
  @doc """
    
  Function for get field from iso  .

  Returns `value`

  Examples: 

  iex(19)>  Ale8583.getField( :c3 , iso_new)
{:ok, "012345"}


  """
  def getField(field,{:iso,listISO,{_,_,_,_},_}) do
    atomKey=
    case is_atom(field) do
      true ->
        field
      false ->
        String.to_atom("c" <> Integer.to_string(field))
    end
    case List.keymember?(listISO,atomKey,0)  do
      false ->
        {:error, "Field #{atomKey} is'nt present, :getField->keymember"}
      true ->
        case List.keyfind(listISO, atomKey ,0) do 
          { _, value} ->
            {:ok, value}
          _ ->
            {:error, "Field #{atomKey} is'nt present, :getField->keyfind."}
        end
    end
  end
  
  @doc """
    
  Function for validate if bitMap has bitMap secondary .

  Returns `true` or `false`

  Examples:
  iex(4)> iso_new2= Ale8583.haveBitMapSec?("888812A088888888")
true
iex(5)> iso_new2= Ale8583.haveBitMapSec?("688812A088888888")
false

  """
  def haveBitMapSec?(strBitMapP) do
    Ale8583.BitMap.haveBitMapSec?(strBitMapP)
  end
 @doc """

  Function for get ISO from list(RAW data without length).

  Returns `iso`


  
""" 
  def list_to_iso({strBitMap, list, type, str_headerProsa},iso) do
    cond do
      type in [ :prosa, :mc ] ->
        listBitMap = Ale8583.BitMap.getListBitMap(strBitMap)
        Logger.debug "Get BITMAP #{inspect listBitMap} strBitMap#{strBitMap}"
        iso= 
        if type == :prosa do
          {:iso ,listISO,{bitMapP,bitMapS,flagBMSec,isoConf}, status} =  iso
          listISO=List.keyreplace(listISO,:header_prosa,0,{:header_prosa, str_headerProsa})
          {:iso ,listISO,{bitMapP,bitMapS,flagBMSec,isoConf}, status}
        else
          iso
        end
        case Ale8583.ValidISO.decodeASCCI( listBitMap, list,iso ) do 
          { :ok , _ , new_iso } ->
            new_iso 
          { :error , _ , iso_error } -> 
            iso_error
        end
      type == :master_card ->
        listBitMap = Ale8583.BitMap.getListBitMap(strBitMap)
        case Ale8583.ValidISO.decodeEBCDIC( listBitMap, list,iso ) do 
         #{ :ok, acc, iso_new } 
 	        { :ok , _ , new_iso } ->
           	Logger.warn "DECODE EBCDIC #{inspect new_iso}" 
		        new_iso 
          { :error , _ , iso_error } -> 
            iso_error
        end
      true -> 
        iso=setStatusISO(iso,{:error, "Type is not valid, use :prosa or :master_card or :mc ."})
        iso
    end
  end
  @doc """
  Function for add field to ISO. 

  Returns `iso` 
  
  ##Examples
  iex(4)> isoMTI2  = Ale8583.addField({ 3 , "012345"}, isoMTI)

14:38:16.904 [debug] VALUE [ key: 3 atomKey: c3 value: 012345]

14:38:16.907 [debug] OK INSERT AND PRIMARY BITMAP UPDATE, c3-3: value 012345
{:iso,
 [
   bp: "2000000000000000",
   bs: "0000000000000000",
   c3: "012345",
   header_prosa: "",
   mti: "0800"
 ],
 {[
    c1: 0,
    c2: 0,
    c3: 1,
    c4: 0,
    c5: 0,
    c6: 0,
    c7: 0,
    c8: 0,
    c9: 0,
    c10: 0,
    c11: 0,
    c12: 0,
    c13: 0,
    c14: 0,
    c15: 0,
    c16: 0,
    c17: 0,
    c18: 0,
    c19: 0,
    c20: 0,
    c21: 0,
    c22: 0,
    c23: 0,
    c24: 0,
    c25: 0,
    c26: 0,
    c27: 0,
    c28: 0,
    c29: 0,
    c30: 0,
    c31: 0,
    c32: 0,
    c33: 0,
    c34: 0,
    c35: 0,
    c36: 0,
    c37: 0,
    c38: 0,
    c39: 0,
    c40: 0,
    c41: 0,
    c42: 0,
    c43: 0,
    c44: 0,
    c45: 0,
    c46: 0,
    ...
  ],
  [
    c65: 0,
    c66: 0,
    c67: 0,
    c68: 0,
    c69: 0,
    c70: 0,
    c71: 0,
    c72: 0,
    c73: 0,
    c74: 0,
    c75: 0,
    c76: 0,
    c77: 0,
    c78: 0,
    c79: 0,
    c80: 0,
    c81: 0,
    c82: 0,
    c83: 0,
    c84: 0,
    c85: 0,
    c86: 0,
    c87: 0,
    c88: 0,
    c89: 0,
    c90: 0,
    c91: 0,
    c92: 0,
    c93: 0,
    c94: 0,
    c95: 0,
    c96: 0,
    c97: 0,
    c98: 0,
    c99: 0,
    c100: 0,
    c101: 0,
    c102: 0,
    c103: 0,
    c104: 0,
    c105: 0,
    c106: 0,
    c107: 0,
    c108: 0,
    c109: 0,
    ...
  ], :flagBMSec_NO,
  [
    c128: %{code: :ascii, length: 64, type: "B", var_length: 0},
    c127: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c126: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c125: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c124: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c123: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c122: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c121: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c120: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c119: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c118: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c117: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c116: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c115: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c114: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c113: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c112: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c111: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c110: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c109: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c108: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c107: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c106: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c105: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c104: %{code: :ascii, length: 100, type: "ANS", var_length: 3},
    c103: %{code: :ascii, length: 28, type: "ANS", var_length: 2},
    c102: %{code: :ascii, length: 28, type: "ANS", var_length: 2},
    c101: %{code: :ascii, length: 17, type: "ANS", var_length: 2},
    c100: %{code: :ascii, length: 11, type: "N", var_length: 2},
    c99: %{code: :ascii, length: 11, type: "N", var_length: 2},
    c98: %{code: :ascii, length: 25, type: "ANS", var_length: 0},
    c97: %{code: :ascii, length: 16, type: "N", var_length: 0},
    c96: %{code: :ascii, length: 64, type: "B", var_length: 0},
    c95: %{code: :ascii, length: 42, type: "AN", var_length: 0},
    c94: %{code: :ascii, length: 7, type: "AN", var_length: 0},
    c93: %{code: :ascii, length: 5, type: "AN", var_length: 0},
    c92: %{code: :ascii, length: 2, type: "AN", var_length: 0},
    c91: %{code: :ascii, length: 1, type: "AN", var_length: 0},
    c90: %{code: :ascii, length: 42, type: "N", var_length: 0},
    c89: %{code: :ascii, length: 16, type: "N", ...},
    c88: %{code: :ascii, length: 16, ...},
    c87: %{code: :ascii, ...},
    c86: %{...},
    ...
  ]}, {:ok, "OK INSERT AND PRIMARY BITMAP UPDATE,c3-3: value 012345"}}
iex(6)> iso_new= Ale8583.addField({ :c3 , "012345"}, isoMTI)

16:17:47.796 [debug] VALUE [ key: 3 atomKey: c3 value: 012345]

16:17:47.796 [debug] OK INSERT AND PRIMARY BITMAP UPDATE, c3-3: value 012345
{:iso,
 [
   bp: "2000000000000000",
   bs: "0000000000000000",
   c3: "012345",
   header_prosa: "",
   mti: "0800"
 ],
 {[
    c1: 0,
    c2: 0,
    c3: 1,
    c4: 0,
    c5: 0,
    c6: 0,
    c7: 0,
    c8: 0,
    c9: 0,
    c10: 0,
    c11: 0,
    c12: 0,
    c13: 0,
    c14: 0,
    c15: 0,
    c16: 0,
    c17: 0,
    c18: 0,
    c19: 0,
    c20: 0,
    c21: 0,
    c22: 0,
    c23: 0,
    c24: 0,
    c25: 0,
    c26: 0,
    c27: 0,
    c28: 0,
    c29: 0,
    c30: 0,
    c31: 0,
    c32: 0,
    c33: 0,
    c34: 0,
    c35: 0,
    c36: 0,
    c37: 0,
    c38: 0,
    c39: 0,
    c40: 0,
    c41: 0,
    c42: 0,
    c43: 0,
    c44: 0,
    c45: 0,
    c46: 0,
    ...
  ],
  [
    c65: 0,
    c66: 0,
    c67: 0,
    c68: 0,
    c69: 0,
    c70: 0,
    c71: 0,
    c72: 0,
    c73: 0,
    c74: 0,
    c75: 0,
    c76: 0,
    c77: 0,
    c78: 0,
    c79: 0,
    c80: 0,
    c81: 0,
    c82: 0,
    c83: 0,
    c84: 0,
    c85: 0,
    c86: 0,
    c87: 0,
    c88: 0,
    c89: 0,
    c90: 0,
    c91: 0,
    c92: 0,
    c93: 0,
    c94: 0,
    c95: 0,
    c96: 0,
    c97: 0,
    c98: 0,
    c99: 0,
    c100: 0,
    c101: 0,
    c102: 0,
    c103: 0,
    c104: 0,
    c105: 0,
    c106: 0,
    c107: 0,
    c108: 0,
    c109: 0,
    ...
  ], :flagBMSec_NO,
  [
    c128: %{code: :ascii, length: 64, type: "B", var_length: 0},
    c127: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c126: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c125: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c124: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c123: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c122: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c121: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c120: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c119: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c118: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c117: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c116: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c115: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c114: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c113: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c112: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c111: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c110: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c109: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c108: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c107: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c106: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c105: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c104: %{code: :ascii, length: 100, type: "ANS", var_length: 3},
    c103: %{code: :ascii, length: 28, type: "ANS", var_length: 2},
    c102: %{code: :ascii, length: 28, type: "ANS", var_length: 2},
    c101: %{code: :ascii, length: 17, type: "ANS", var_length: 2},
    c100: %{code: :ascii, length: 11, type: "N", var_length: 2},
    c99: %{code: :ascii, length: 11, type: "N", var_length: 2},
    c98: %{code: :ascii, length: 25, type: "ANS", var_length: 0},
    c97: %{code: :ascii, length: 16, type: "N", var_length: 0},
    c96: %{code: :ascii, length: 64, type: "B", var_length: 0},
    c95: %{code: :ascii, length: 42, type: "AN", var_length: 0},
    c94: %{code: :ascii, length: 7, type: "AN", var_length: 0},
    c93: %{code: :ascii, length: 5, type: "AN", var_length: 0},
    c92: %{code: :ascii, length: 2, type: "AN", var_length: 0},
    c91: %{code: :ascii, length: 1, type: "AN", var_length: 0},
    c90: %{code: :ascii, length: 42, type: "N", var_length: 0},
    c89: %{code: :ascii, length: 16, type: "N", ...},
    c88: %{code: :ascii, length: 16, ...},
    c87: %{code: :ascii, ...},
    c86: %{...},
    ...
  ]}, {:ok, "OK INSERT AND PRIMARY BITMAP UPDATE,c3-3: value 012345"}}
iex(7)>  
  """
  def addField({ key, value} , iso) do
    { _ , iso_new } =  do_addField({key,value},iso) 
    iso_new
  end
  
  @doc """
  Function for create new iso .

  Returns `iso` 
 
 """
  def new({mti,listConf}) do
    case mti in @msgs do
      true -> 
        {:iso,
          [ mti: mti, bp: "0000000000000000", bs: "0000000000000000", header_prosa: "" ],
          { Ale8583.BitMap.newBitMapP(), Ale8583.BitMap.newBitMapS(), 
      :flagBMSec_NO,listConf}, { :ok ,"OK"}}
          false -> {:error,[],{},"Error MTI no valid:  #{mti}, Those mtis ara valid: #{@msgs}."}
    end
  end 

  @doc """
  Function for create new iso without configuration file .

  Returns `iso` 
  
  
  ## Examples
iex(1)> isoMTI=Ale8583.new_with_out_conf({"0800","/Users/ale/testPrograms/ale8583/ale8583/ascii.iso.cfg"})
{:iso,
 [mti: "0800", bp: "0000000000000000", bs: "0000000000000000", header_prosa: ""],
 {[
    c1: 0,
    c2: 0,
    c3: 0,
    c4: 0,
    c5: 0,
    c6: 0,
    c7: 0,
    c8: 0,
    c9: 0,
    c10: 0,
    c11: 0,
    c12: 0,
    c13: 0,
    c14: 0,
    c15: 0,
    c16: 0,
    c17: 0,
    c18: 0,
    c19: 0,
    c20: 0,
    c21: 0,
    c22: 0,
    c23: 0,
    c24: 0,
    c25: 0,
    c26: 0,
    c27: 0,
    c28: 0,
    c29: 0,
    c30: 0,
    c31: 0,
    c32: 0,
    c33: 0,
    c34: 0,
    c35: 0,
    c36: 0,
    c37: 0,
    c38: 0,
    c39: 0,
    c40: 0,
    c41: 0,
    c42: 0,
    c43: 0,
    c44: 0,
    c45: 0,
    c46: 0,
    ...
  ],
  [
    c65: 0,
    c66: 0,
    c67: 0,
    c68: 0,
    c69: 0,
    c70: 0,
    c71: 0,
    c72: 0,
    c73: 0,
    c74: 0,
    c75: 0,
    c76: 0,
    c77: 0,
    c78: 0,
    c79: 0,
    c80: 0,
    c81: 0,
    c82: 0,
    c83: 0,
    c84: 0,
    c85: 0,
    c86: 0,
    c87: 0,
    c88: 0,
    c89: 0,
    c90: 0,
    c91: 0,
    c92: 0,
    c93: 0,
    c94: 0,
    c95: 0,
    c96: 0,
    c97: 0,
    c98: 0,
    c99: 0,
    c100: 0,
    c101: 0,
    c102: 0,
    c103: 0,
    c104: 0,
    c105: 0,
    c106: 0,
    c107: 0,
    c108: 0,
    c109: 0,
    ...
  ], :flagBMSec_NO,
  [
    c128: %{code: :ascii, length: 64, type: "B", var_length: 0},
    c127: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c126: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c125: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c124: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c123: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c122: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c121: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c120: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c119: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c118: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c117: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c116: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c115: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c114: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c113: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c112: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c111: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c110: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c109: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c108: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c107: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c106: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c105: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c104: %{code: :ascii, length: 100, type: "ANS", var_length: 3},
    c103: %{code: :ascii, length: 28, type: "ANS", var_length: 2},
    c102: %{code: :ascii, length: 28, type: "ANS", var_length: 2},
    c101: %{code: :ascii, length: 17, type: "ANS", var_length: 2},
    c100: %{code: :ascii, length: 11, type: "N", var_length: 2},
    c99: %{code: :ascii, length: 11, type: "N", var_length: 2},
    c98: %{code: :ascii, length: 25, type: "ANS", var_length: 0},
    c97: %{code: :ascii, length: 16, type: "N", var_length: 0},
    c96: %{code: :ascii, length: 64, type: "B", var_length: 0},
    c95: %{code: :ascii, length: 42, type: "AN", var_length: 0},
    c94: %{code: :ascii, length: 7, type: "AN", var_length: 0},
    c93: %{code: :ascii, length: 5, type: "AN", var_length: 0},
    c92: %{code: :ascii, length: 2, type: "AN", var_length: 0},
    c91: %{code: :ascii, length: 1, type: "AN", var_length: 0},
    c90: %{code: :ascii, length: 42, type: "N", var_length: 0},
    c89: %{code: :ascii, length: 16, type: "N", ...},
    c88: %{code: :ascii, length: 16, ...},
    c87: %{code: :ascii, ...},
    c86: %{...},
    ...
  ]}, {:ok, "OK"}}

 """
  def new_with_out_conf({mti,path}, strHeaderPROSA \\ "") do
    case setConf(path) do
      {:ok, listConf} ->
        case mti in @msgs do
          true ->
            strHeaderPROSA=
            if strHeaderPROSA != "" do
              case Ale8583.ValidISO.headerPROSA(strHeaderPROSA) do 
                {:ok , _ } -> 
                  strHeaderPROSA
                error ->
                  error
                
              end
            else
              ""
            end
            case strHeaderPROSA do 
              {:error, _ } ->
                {:error,[],{},strHeaderPROSA}
              _ ->
              {:iso,
                [ mti: mti, bp: "0000000000000000", bs: "0000000000000000", header_prosa: strHeaderPROSA ],
                { Ale8583.BitMap.newBitMapP(), Ale8583.BitMap.newBitMapS(), 
                  :flagBMSec_NO,listConf}, { :ok ,"OK"}}
            end
          false -> 
              {:error,[],{},{:error,"Error MTI no valid:  #{mti}, Those mtis ara valid: #{@msgs}."}}
        end
      {:error, reason} ->  {:error,[],{},{ :error ,"Error when try load file configuration #{reason}."}}
    end
  end
  
  @doc """
  Function for delete a field in iso .

  Returns `iso` 
  
  
  ## Examples
  iex(3)> iso_new2= Ale8583.deleteField(3, iso_new)
{:iso,
 [bp: "2000000000000000", bs: "0000000000000000", header_prosa: "", mti: "0800"],
 {[
    c1: 0,
    c2: 0,
    c3: 1,
    c4: 0,
    c5: 0,
    c6: 0,
    c7: 0,
    c8: 0,
    c9: 0,
    c10: 0,
    c11: 0,
    c12: 0,
    c13: 0,
    c14: 0,
    c15: 0,
    c16: 0,
    c17: 0,
    c18: 0,
    c19: 0,
    c20: 0,
    c21: 0,
    c22: 0,
    c23: 0,
    c24: 0,
    c25: 0,
    c26: 0,
    c27: 0,
    c28: 0,
    c29: 0,
    c30: 0,
    c31: 0,
    c32: 0,
    c33: 0,
    c34: 0,
    c35: 0,
    c36: 0,
    c37: 0,
    c38: 0,
    c39: 0,
    c40: 0,
    c41: 0,
    c42: 0,
    c43: 0,
    c44: 0,
    c45: 0,
    c46: 0,
    ...
  ],
  [
    c65: 0,
    c66: 0,
    c67: 0,
    c68: 0,
    c69: 0,
    c70: 0,
    c71: 0,
    c72: 0,
    c73: 0,
    c74: 0,
    c75: 0,
    c76: 0,
    c77: 0,
    c78: 0,
    c79: 0,
    c80: 0,
    c81: 0,
    c82: 0,
    c83: 0,
    c84: 0,
    c85: 0,
    c86: 0,
    c87: 0,
    c88: 0,
    c89: 0,
    c90: 0,
    c91: 0,
    c92: 0,
    c93: 0,
    c94: 0,
    c95: 0,
    c96: 0,
    c97: 0,
    c98: 0,
    c99: 0,
    c100: 0,
    c101: 0,
    c102: 0,
    c103: 0,
    c104: 0,
    c105: 0,
    c106: 0,
    c107: 0,
    c108: 0,
    c109: 0,
    ...
  ], :flagBMSec_NO,
  [
    c128: %{code: :ascii, length: 64, type: "B", var_length: 0},
    c127: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c126: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c125: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c124: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c123: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c122: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c121: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c120: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c119: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c118: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c117: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c116: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c115: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c114: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c113: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c112: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c111: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c110: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c109: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c108: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c107: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c106: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c105: %{code: :ascii, length: 999, type: "ANS", var_length: 3},
    c104: %{code: :ascii, length: 100, type: "ANS", var_length: 3},
    c103: %{code: :ascii, length: 28, type: "ANS", var_length: 2},
    c102: %{code: :ascii, length: 28, type: "ANS", var_length: 2},
    c101: %{code: :ascii, length: 17, type: "ANS", var_length: 2},
    c100: %{code: :ascii, length: 11, type: "N", var_length: 2},
    c99: %{code: :ascii, length: 11, type: "N", var_length: 2},
    c98: %{code: :ascii, length: 25, type: "ANS", var_length: 0},
    c97: %{code: :ascii, length: 16, type: "N", var_length: 0},
    c96: %{code: :ascii, length: 64, type: "B", var_length: 0},
    c95: %{code: :ascii, length: 42, type: "AN", var_length: 0},
    c94: %{code: :ascii, length: 7, type: "AN", var_length: 0},
    c93: %{code: :ascii, length: 5, type: "AN", var_length: 0},
    c92: %{code: :ascii, length: 2, type: "AN", var_length: 0},
    c91: %{code: :ascii, length: 1, type: "AN", var_length: 0},
    c90: %{code: :ascii, length: 42, type: "N", var_length: 0},
    c89: %{code: :ascii, length: 16, type: "N", ...},
    c88: %{code: :ascii, length: 16, ...},
    c87: %{code: :ascii, ...},
    c86: %{...},
    ...
  ]}, {:ok, "OK delete"}}

 """
  def deleteField( key,{:iso,listISO,{listBitMapP,listBitMapS,flagBMSec,listISOconf},_}) do 
    ##atomKey="c" <> Integer.to_string(key) |> String.to_atom
    atomKey= String.to_atom("c" <> Integer.to_string(key))

    case List.keymember?(listISO,atomKey, 0)  do
      true ->
        listISO= List.keydelete(listISO,atomKey, 0) |> Enum.sort
        cond do 
          key in 2..64 ->
            listBitMapP=Ale8583.BitMap.modifyDelete(listBitMapP,key)
            listISO=List.keyreplace(listISO,:bp,0,{:bp, Ale8583.BitMap.getBitMapHex( listBitMapP)})
            #       List.keyreplace(listISO,:bp,0,{:bp, Ale8583.BitMap.getListBitMap(listBitMapP)})
            {:iso, listISO ,{listBitMapP,listBitMapS,flagBMSec,listISOconf} , { :ok, "OK delete"} }            
          key in 65..128 ->
            listBitMapS=Ale8583.BitMap.modifyDelete(listBitMapS,key) 
            listISO=List.keyreplace(listISO,:bs,0,{:bs, Ale8583.BitMap.getBitMapHex(listBitMapS  )})
            {:iso, listISO ,{listBitMapP,listBitMapS,flagBMSec,listISOconf} , { :ok, "OK delete"} }
          true -> 
            {:iso, listISO ,{listBitMapP,listBitMapS,flagBMSec,listISOconf} , { :error, "Field is not in 2 - 126"} }
        end
      false ->
        {:iso,
        listISO ,
        {listBitMapP,listBitMapS,flagBMSec,listISOconf},{ :ok , "FIELD #{key} isn't iso member."}} 
    end
  end
  @doc """
  Function for  print a prety fields ISO .
  
  ## Examples
  iex(2)> Ale8583.printAll(isoMTI, "Mensaje ISO: " )

13:24:39.471 [error] Mensaje ISO:
mti<0800>
bp<0000000000000000>
bs<0000000000000000>

:ok
iex(3)>
 """
  def printAll({atomISO ,listISO,{_,_,_,listISOconf},_}, extra) do
    case atomISO do
      :iso ->
       	{_,mti} = List.keyfind(listISO, :mti, 0) 
	      {_,bp} = List.keyfind(listISO, :bp, 0)
	      {_,bs} = List.keyfind(listISO, :bs, 0)
	      extra = extra <> "\n" <> "mti<#{mti}>" <> "\n" <> "bp<#{bp}>" <> "\n" <> "bs<#{bs}>" <> "\n" 
	      listISO= List.keydelete(listISO, :mti, 0)	 
	      listISO= List.keydelete(listISO, :bp, 0)	 
	      listISO= List.keydelete(listISO, :bs, 0)	 
	      listISO= List.keydelete(listISO, :header_prosa, 0)	 
	      do_printAll(  Enum.sort_by(listISO, fn { atom, _  } ->  
			  String.to_integer(String.slice(Atom.to_string(atom), 1..5))
	end ), listISOconf, extra)	
	#do_printAll(listISO |> Enum.sort, listISOconf, extra)  
      _ -> 
        Logger.error "Error in printAll function, atom :iso is not present."
    end
  end

  ## UTILITIES
  ###############################################################3
  
  @doc """
  Secundary Function  for  print a prety fields ISO .
  
  ## Examples
 """
  def do_printAll([head|tail], listISOconf, buffer) do
    {key, value } = head
   	#Logger.warn "key #{inspect key}, value #{inspect value} isoList #{inspect listISOconf}" 
     buffer=
    cond do
	    key in [ :mti, :bp , :bs, :header_prosa ] ->
	        buffer	
		#buffer = buffer <> "#{key}<#{value}>\n"
	    true ->
		    {_, map} = List.keyfind(listISOconf, key , 0)
        case map.var_length do
      		0 ->
        		buffer <> " #{key}<#{value}>\n"
      		2 ->
        		buffer <> " #{key}<#{String.slice(value,0,2)}>\n"
        		buffer <> " #{key}<#{String.slice(value,2..map.length)}>\n"
      		3 ->
        		buffer <> " #{key}<#{String.slice(value,0,3)}>\n"
        		buffer <> " #{key}<#{String.slice(value,3..map.length)}>\n"
    		end
  
	  end
	  do_printAll(tail, listISOconf, buffer)	
  end

  @doc """
  Default Secundary Function  for  print a prety fields ISO .
  
  ## Examples
 """
  def do_printAll([], _, buffer) do
    Logger.error buffer
  end
  
  defp setStatusISO({:iso ,listISO, conf,_ },{ result , message } ) do
    {:iso, listISO, conf,{result, message}}
  end 

  defp getAppendISO(listISO, listISOconf) do
      do_getAppendISO(listISO, listISOconf,[])
  end
  defp do_getAppendISO([ head|tail], listISOconf, acc) do
    { atomKey, value } = head 
    cond do 
      atomKey in [ :header_prosa, :bs, :bp, :mti, :c1 ] ->
        do_getAppendISO(tail, listISOconf, acc)
      true ->
        Logger.debug "Ale8583Worker.append { #{atomKey}::[#{value}] "    
        { atomKey, map } = List.keyfind(listISOconf, atomKey, 0)
        Logger.debug "Ale8583Worker.append { #{atomKey}::[#{value}] #{map.code} "
        value=
        case map.code do 
          :ebcdic ->
            String.to_charlist(value) |> Ale8583.Convert.ascii_to_ebcdic
          :ascii ->
            String.to_charlist(value)
          :bin ->
            String.to_charlist(value) |> Ale8583.Convert.ascii_to_bin
        end 
        do_getAppendISO(tail, listISOconf, acc ++ value )
    end
  end
  defp do_getAppendISO( [], _ , acc) do
    acc
  end
  
  def do_addField({key,value},{:iso ,listISO,{listBitMapP,listBitMapS,flagBMSec,listISOconf},_}) do
    atomKey=
    case is_atom(key) do
      true ->
        key
      false ->
        String.to_atom("c" <> Integer.to_string(key))
    end
    
    key=
    if is_atom(key) do
      String.slice(Atom.to_string(key),1,10) |> String.to_integer
    else 
      key
    end  
    value=
    if is_atom( value ) == true do
      static_field( value) 
    else
      value
    end
    Logger.debug "VALUE [ key: #{key} atomKey: #{atomKey} value: #{value}, list #{inspect listISOconf}]" 
    case List.keyfind(listISOconf, atomKey ,0) do 
      { _, map} -> 
        case  Ale8583.ValidISO.valid({key,value}, map ) do
          {:ok,_} ->
            case List.keymember?(listISO, atomKey, 0)  do
              true -> 
                { :ok, {:iso, List.keyreplace(listISO, atomKey, 0,{atomKey, value}) |> Enum.sort,{listBitMapP,listBitMapS,flagBMSec, listISOconf} ,{ :ok, "OK UPDATE"}}}
              false ->
                listISO = listISO ++ [ "c#{key}": value] |> Enum.sort
                #Logger.debug "Inspect listISO in addfield #{inspect listISO} " 
                cond do 
                  key in 2..64 ->
                    listBitMapP=Ale8583.BitMap.modifyInsert(listBitMapP,atomKey) 
                    Logger.debug "OK INSERT AND PRIMARY BITMAP UPDATE, #{atomKey}-#{key}: value #{value}"
                    listISO = List.keyreplace(listISO,:bp,0,{ :bp, Ale8583.BitMap.getBitMapHex(listBitMapP)})
                    #Logger.debug "Inspect listISO 2 in addfield #{inspect listISO} " 
                    { :ok, { :iso, listISO,
                      {listBitMapP,listBitMapS,flagBMSec,listISOconf},
                      { :ok, "OK INSERT AND PRIMARY BITMAP UPDATE,#{atomKey}-#{key}: value #{value}"}}}
                  key in 65..128 ->
                    listBitMapP = 
                    if flagBMSec == :flagBMSec_NO do 
                      Ale8583.BitMap.modifyInsert(listBitMapP, :c1 )
                    else
                      listBitMapP 
                    end
                    listISO = 
                    if flagBMSec == :flagBMSec_NO do 
                      List.keyreplace(listISO,:bp,0,{:bp, Ale8583.BitMap.getBitMapHex(listBitMapP)})
                    else
                      listISO
                    end
                    flagBMSec = 
                    if flagBMSec == :flagBMSec_NO do 
                      :flagBMSec_YES
                    else
                      flagBMSec
                    end
                    
                    listBitMapS = Ale8583.BitMap.modifyInsert(listBitMapS, atomKey)
                    Logger.debug "OK INSERT AND PRIMARY BITMAP UPDATE, #{atomKey}-#{key}: value #{value}"
                    { :ok, {:iso,
                    List.keyreplace(listISO, :bs,0,{ :bs, Ale8583.BitMap.getBitMapHex(listBitMapS)}),
                      { listBitMapP, listBitMapS, flagBMSec, listISOconf },
                      { :ok , "OK INSERT AND SECUNDARY BITMAP UPDATE,#{atomKey}-#{key}: value #{value}"}} }
                  true ->
                    { :ok, {:iso,listISO,{listBitMapP,listBitMapS,flagBMSec,listISOconf}, { :ok, "FIELD NOT SUPPORTED, FIELD SHOULD BE BETWEEN 2..128."}}}
                end
            end
          {:error,msgError} -> { :error, {:iso,listISO,{listBitMapP,listBitMapS,flagBMSec,listISOconf}, { :error, msgError} }} 
        end
      _ ->
        { :iso ,listISO,{listBitMapP,listBitMapS,flagBMSec,listISOconf}, { :error, "Error field #{key} doesn't exist in configuration file." }}
    end
  end
  defp static_field( staticAtom) do 
    case staticAtom do 
      :MMDDhhmmss ->
        date = DateTime.utc_now
        #Logger.debug "MM:#{date.month}DD:#{date.day}HH:#{date.hour}mm:#{date.minute}ss:#{date.second}"
        "#{formatZero(date.month,2)}#{formatZero(date.day,2)}#{formatZero(date.hour,2)}#{formatZero(date.minute,2)}#{formatZero(date.second,2)}"
      :hhmmss ->  
        date = DateTime.utc_now
        "#{formatZero(date.hour,2)}#{formatZero(date.minute,2)}#{formatZero(date.second,2)}"
      :MMDD -> 
        date = DateTime.utc_now
        "#{formatZero(date.month,2)}#{formatZero(date.day,2)}"
      :YYMM ->
        date = DateTime.utc_now
        yy=date.year - 2000 
        "#{formatZero(yy,2)}#{formatZero(date.month,2)}"
      :auditNumber ->
        "#{formatZero(Enum.random(0..999999),6)}"
      _ ->
        to_string(staticAtom)
    end
  end
  defp formatZero( intValue, intZeros) do
    strValue = Integer.to_string(intValue)
    cond do
      String.length(strValue) == intZeros  ->  strValue
      String.length(strValue) < intZeros  ->  
        intRest= intZeros - String.length(strValue)   
        to_string(for _ <- 1..intRest, do: '0') <> strValue
      true -> 
        Logger.warn "El valor a formatear es mas grande del valor requerido ( #{String.length(strValue)} < #{intZeros}), se procede a regresar el valor sin cumplir con el formato. "
        strValue
    end
  end
  defp setConf(path) do
    case File.open(path) do
      {:ok, file} ->  
        list = Ale8583.BlockReader.read!(file) ##|> TermParser.parse
        list
      {:error, reason}  -> {:error,reason}
    end
  end
end
