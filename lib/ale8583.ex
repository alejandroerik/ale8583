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


  """
  def haveInISO?({_,listISO,{_,_,_,_},_} , atomField) do
     List.keymember?(listISO, atomField, 0)
  end
  
  @doc """
    
  Function for validate if a field have in bitmap.
  
  Returns `true` or `false` 
  #Examples 
 
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
  iex(15)>iso_new=Ale8583.new_with_out_conf({"0800","/Users/ale/testPrograms/ale8583/ale8583/ascii.iso.cfg"})
  iex(16)> iso_new  = Ale8583.addField({ 3 , "012345"}, iso_new)
  iex(17)>  Ale8583.getTrama iso_new
'08002000000000000000012345'
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
  iex(17)>iso_new=Ale8583.new_with_out_conf({"0800","/Users/ale/testPrograms/ale8583/ale8583/ascii.iso.cfg"})
  iex(18)> iso_new  = Ale8583.addField({ 3 , "012345"}, iso_new)
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
  iex(4)> Ale8583.haveBitMapSec?("888812A088888888")
true
iex(5)> Ale8583.haveBitMapSec?("688812A088888888")
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
  Function for  print a prety fields ISO.
  ## Examples


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
