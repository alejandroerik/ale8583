

# Ale8583

[![Hex.pm](https://img.shields.io/hexpm/v/plug.svg)](https://hex.pm/packages/ale8583)
[![Twitter URL](https://img.shields.io/twitter/url/http/shields.io.svg?style=social)](https://twitter.com/alejandroErik)


ISO8583(MasterC and PROSA) parser for ELIXIR language.

## Getting Started



### Prerequisites

Elixir 1.5+.



## Installation

If [available in Hex](https://hex.pm/docs/publish), the package can be installed
by adding `ale8583` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [
    {:ale8583, "~> 0.1.0"}
  ]
end
```

## Quickfast introduction



A ISO tuple is the main idea, just like that :

{:iso,listISO,{listBitMapP,listBitMapS,flagBMSec,listISOconf},{status, message}} 

  
Where:

	“:iso”  		:   Atom static. 
	“listISO”  	:  Elixir List for fields [ bp: “..” , c1: “…“,  c2: “…” …]
			Atom Fields: 
				:c2   to   :c128   => ISO FIELDS.
				:bp  =>   Primary bit MAP.
				:bs  = >  Secondary bit MAP.  
		 
	“listBitMapP”  :   Elixir List fields [ c1: 0 , c2: 1 …]
			 Atom fields: 
				:c1 to c64  =>  0  or 1 		
	“listBitMapS” :   Elixir List fields [ c65: 0 , c128: 1 …]
			 Atom fields: 
				:c65 to c128  =>  0  or 1
	“flagBMSec” :   true =>  If secondary bit map is present
			 false  =>  any other else
	 “listISOconf” :  ISO configuration from iso.conf.
	{ status , message  } : It’s the result for a back  step operation.  
			“status” :  :ok  or :error
			“message” :  “Message string detail”



### Test Example : 
```ruby
test "list to iso type :prosa" do
    listRAW='ISO0060000400800822000000000000004000000000000000804180203010449101'
    strHeadProsa=Enum.take(listRAW,12) |> List.to_string #String.slice(data,0,12)
    Logger.debug "Header PROSA : #{strHeadProsa} "
    ## MTI
    strMTI= Enum.slice(listRAW, 12 ,4 ) |> List.to_string
    ## BIT MAP PRIMARY
    strBitMap=Enum.slice(listRAW, 16,16 ) |> List.to_string
    ## BIT MAP IF TRANSACTION HAS BIT MAP SECONDARY
    strBitMap =
    if Ale8583.haveBitMapSec?(strBitMap) == true do
      Enum.slice(listRAW,16,32) |> List.to_string
    else
      strBitMap
    end
    
    ## TAKE FIELDS SINCE FIELD 1.  
    listFields= Enum.take(listRAW, 32 - Kernel.length(listRAW))

    ## ISO MAKES FROM MTI AND CONFIGURATION FILE.
    isoMTI=Ale8583.new_with_out_conf({strMTI,"/Users/ale/testPrograms/ale8583/ale8583/ascii.iso.cfg"})
    {:iso,listISO,{listBitMapP,listBitMapS,flagBMSec,listISOconf},{status, message}} = isoMTI
    Logger.info "Result : #{inspect status} #{inspect message}" 
    assert status == :ok
    #Logger.info "#{inspect isoMTI} "
    Logger.info "#{inspect strBitMap}, #{inspect listFields}, #{inspect strHeadProsa} "
    isoMTI= Ale8583.list_to_iso({strBitMap,listFields, :prosa ,strHeadProsa}, isoMTI)
    {:iso,listISO,{listBitMapP,listBitMapS,flagBMSec,listISOconf},{status, message}} = isoMTI
    ## INSPECT RESULT :ok or :error
    Logger.info "Result : #{inspect status} #{inspect message}" 
    assert status == :ok

    Ale8583.printAll(isoMTI, "Print fields ISO type #{strMTI}:")
    
    # VALIDATE FIELDS CONTENT 
    assert List.keymember?(listISO, :c1, 0) == true
    assert List.keymember?(listISO, :c7, 0) == true
    assert List.keymember?(listISO, :c11, 0) == true
    assert List.keymember?(listISO, :c70, 0) == true
    #{ _ , strC3 } = List.keyfind( listISO , :c3 ,0)
    #assert "111000" == strC3
    { _ , strBMP } = List.keyfind( listISO , :bp ,0)
    assert "8220000000000000" == strBMP
    Logger.info "Result : #{inspect status} #{inspect message}"
    assert status == :ok
  end
```
Output: 
```
Finished in 0.1 seconds
3 doctests, 4 tests, 0 failures
```

## Donations:

ETH : 0xc1b633a45c45d1d34cdda66459ff681f9c2b42a0
BTC : 

