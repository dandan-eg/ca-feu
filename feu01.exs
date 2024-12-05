# Evaluter une expression
defmodule Lexer do
  @type tokens :: [:+ | :- | :* | :/ | :% | {:integer, integer}]

  @spec lex(String.t()) :: tokens()
  def lex(expression) do
    tokens = lex(expression, [])
    {:ok, Enum.reverse(tokens)}
  end

  defguard is_whitespace(char) when char in [?\r, ?\s, ?\s]
  defguard is_numeric(char) when char in ?0..?9

  defp lex(<<char, remaining::binary>>, tokens) when is_whitespace(char) do
    lex(remaining, tokens)
  end

  # Nombre Entier: 

  defp lex(<<char, _::binary>> = binary, tokens) when is_numeric(char) do
    {int, remaining} = integer(binary, 0)
    lex(remaining, [{:integer, int} | tokens])
  end

  defp lex(<<"-", char, _::binary>> = binary, tokens) when is_numeric(char) do
    {int, remaining} = integer(binary_slice(binary, 1..byte_size(binary)), 0)
    lex(remaining, [{:integer, -int} | tokens])
  end

  defp lex(<<"+", char, _::binary>> = binary, tokens) when is_numeric(char) do
    {int, remaining} = integer(binary_slice(binary, 1..byte_size(binary)), 0)
    lex(remaining, [{:integer, -int} | tokens])
  end

  # Operations: 
  defp lex(<<"+", remaining::binary>>, tokens), do: lex(remaining, [:+ | tokens])
  defp lex(<<"-", remaining::binary>>, tokens), do: lex(remaining, [:- | tokens])
  defp lex(<<"*", remaining::binary>>, tokens), do: lex(remaining, [:* | tokens])
  defp lex(<<"/", remaining::binary>>, tokens), do: lex(remaining, [:/ | tokens])
  defp lex(<<"%", remaining::binary>>, tokens), do: lex(remaining, [:% | tokens])
  defp lex(<<>>, tokens), do: [:eof | tokens]

  defp integer(<<char, remaining::binary>>, acc) when is_numeric(char) do
    new_acc = acc * 10 + char_to_integer(char)
    integer(remaining, new_acc)
  end

  defp integer(<<_, remaining::binary>>, acc), do: {acc, remaining}
  defp integer(<<>>, acc), do: {acc, <<>>}

  defp char_to_integer(char), do: char - ?0
end

defmodule Interpreter do
  def term!([{:integer, int} | remaining]), do: {int, remaining}

  def term!([lexem | _remaning]),
    do: raise(ArgumentError, message: "invalid lexem #{inspect(lexem)}")

  def eval(raw) do
    case Lexer.lex(raw) do
      {:ok, tokens} ->
        {acc, remaining} = term!(tokens)
        eval_loop(remaining, acc)
    end
  end

  defp eval_loop([:eof], acc), do: acc

  defp eval_loop([operation | tokens], acc) when operation in [:+, :-, :/, :*, :%] do
    {term, remaining} = term!(tokens)
    eval_loop(remaining, calculate(acc, operation, term))
  end

  defp calculate(a, :+, b), do: a + b
  defp calculate(a, :-, b), do: a - b
  defp calculate(a, :*, b), do: a * b
  defp calculate(a, :/, b), do: round(a / b)
  defp calculate(a, :%, b), do: rem(a, b)
end

{:ok, tokens} =
  System.argv()
  |> hd()
  |> Lexer.lex()
  |> IO.inspect()

result = Interpreter.eval(tokens)
IO.puts(result)
