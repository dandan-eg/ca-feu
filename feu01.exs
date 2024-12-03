# Evaluter une expression
defmodule Lexer do
  def lex(expression) do
    lex(expression, [])
  end

  defguard is_whitespace(char) when char in [?\r, ?\s, ?\s]
  defguard is_numeric(char) when char in ?0..?9

  defp lex(<<char, remaining::binary>>, tokens) when is_whitespace(char) do
    lex(remaining, tokens)
  end

  defp lex(<<char, _::binary>> = binary, tokens) when is_numeric(char) do
    {int, remaining} = integer(binary, 0)
    lex(remaining, [{:integer, int} | tokens])
  end

  defp lex(<<"+", remaining::binary>>, tokens), do: lex(remaining, [:+ | tokens])
  defp lex(<<"-", remaining::binary>>, tokens), do: lex(remaining, [:- | tokens])
  defp lex(<<>>, tokens), do: {:ok, Enum.reverse([:eof | tokens])}

  defp integer(<<char, remaining::binary>>, acc) when is_numeric(char) do
    new_acc = acc * 10 + char_to_integer(char)
    integer(remaining, new_acc)
  end

  defp integer(<<_, remaining::binary>>, acc), do: {acc, remaining}
  defp integer(<<>>, acc), do: {acc, <<>>}

  defp char_to_integer(char), do: char - ?0
end

defmodule Interpreter do
  def eval(tokens) do
    Enum.reduce(tokens, nil, fn
      token, nil ->
        token

      operation, {:integer, left} ->
        {operation, [left, nil]} |> IO.inspect()

      {:integer, rigth}, {operation, [left, nil]} ->
        {operation, [left, rigth]} |> IO.inspect()

      :eof, {:+, [left, right]} ->
        left + right

      :eof, {:-, [left, right]} ->
        left - right
    end)
  end
end

{:ok, tokens} = Lexer.lex("100   + 23")
result = Interpreter.eval(tokens)
IO.puts(result)
