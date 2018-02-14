defmodule Ale8583.Exclu do
  use Bitwise ##, skip_operators: true
  def char_xor(a, b) do
    char_xor(a, b, "")
  end
  def char_xor("", "", acc), do: acc
  def char_xor(<<a, as::binary>>, <<b, bs::binary>>, acc) do
    char_xor(as, bs, <<acc::binary, bxor(a, b)>>)
  end
  
  def char_and(a, b) do
    char_and(a, b, "")
  end
  def char_and("", "", acc), do: acc
  def char_and(<<a, as::binary>>, <<b, bs::binary>>, acc) do
    char_and(as, bs, <<acc::binary, a &&& b >> )
  end

end
