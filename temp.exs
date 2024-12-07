defmodule Example do
  defguardp is_numeric(char) when char in ?0..?9

  def lex(<<sign, char, _::binary>>)
      when is_numeric(char) and sign in [?-, ?+] do
    IO.puts(sign)
    IO.puts(char)
  end
end

Example.lex("+1")
