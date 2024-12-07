# Evaluter une expression
defmodule Lexer do
  @type token() ::
          :plus
          | :minus
          | :mul
          | :div
          | :mod
          | :open_parenthesis
          | {:integer, integer()}
          | :eof

  @type tokens() :: list(tokens)

  defguard is_whitespace(char) when char in [?\r, ?\n, ?\s]
  defguard is_numeric(char) when char in ?0..?9

  @spec lex(binary()) :: {:ok, tokens()} | {:error, {:invalid, binary()}}
  def lex(binary) when is_binary(binary) do
    case lex(binary, []) do
      {:ok, tokens} ->
        {:ok, Enum.reverse(tokens)}

      {:error, _reason} = err ->
        err
    end
  end

  defp lex(<<char, remaining::binary>>, tokens) when is_whitespace(char) do
    lex(remaining, tokens)
  end

  # Integer:
  defp lex(<<char, _::binary>> = binary, tokens) when is_numeric(char) do
    {int, remaining} = integer(binary, 0)
    lex(remaining, [{:integer, int} | tokens])
  end

  defp lex(<<"+", char, _::binary>> = binary, tokens) when is_numeric(char) do
    {int, remaining} = integer(binary_slice(binary, 1..byte_size(binary)), 0)
    lex(remaining, [{:integer, +int} | tokens])
  end

  defp lex(<<"-", char, _::binary>> = binary, tokens) when is_numeric(char) do
    {int, remaining} = integer(binary_slice(binary, 1..byte_size(binary)), 0)
    lex(remaining, [{:integer, -int} | tokens])
  end

  # Operations:
  defp lex(<<"+", remaining::binary>>, tokens), do: lex(remaining, [:plus | tokens])
  defp lex(<<"-", remaining::binary>>, tokens), do: lex(remaining, [:minus | tokens])
  defp lex(<<"*", remaining::binary>>, tokens), do: lex(remaining, [:mul | tokens])
  defp lex(<<"/", remaining::binary>>, tokens), do: lex(remaining, [:div | tokens])
  defp lex(<<"%", remaining::binary>>, tokens), do: lex(remaining, [:mod | tokens])

  # Parenthesis
  defp lex(<<"(", remaining::binary>>, tokens), do: lex(remaining, [:open_parenthesis | tokens])
  defp lex(<<")", remaining::binary>>, tokens), do: lex(remaining, [:close_parenthesis | tokens])

  defp lex(<<>>, tokens), do: {:ok, [:eof | tokens]}

  defp lex(binary, _tokens) do
    whitespace? = fn char ->
      is_whitespace(char)
    end

    invalid_identifier = read_until(whitespace?, binary, <<>>)
    {:error, {:invalid, invalid_identifier}}
  end

  defp integer(<<char, remaining::binary>>, acc) when is_numeric(char) do
    new_acc = acc * 10 + char_to_integer(char)
    integer(remaining, new_acc)
  end

  defp integer(<<>>, acc), do: {acc, <<>>}
  defp integer(remaining, acc), do: {acc, remaining}

  defp char_to_integer(char), do: char - ?0

  defp read_until(_predicate, <<>>, acc), do: acc

  defp read_until(predicate, <<char, remaining::binary>>, acc) do
    if predicate.(char),
      do: acc,
      else: read_until(predicate, remaining, <<acc::binary, char>>)
  end
end

defmodule Parser do
  def factor([{:integer, int} | tokens]), do: {int, tokens}

  def factor([:open_parenthesis | tokens]) do
    {base, remaining_tokens} = factor(tokens)

    calculate_until(:close_parenthesis, remaining_tokens, base)
  end

  def parse(tokens) do
    {base, remaining_tokens} = factor(tokens)
    do_parse(remaining_tokens, base)
  end

  def do_parse([:eof], acc), do: {:ok, acc}

  def do_parse([operation | tokens], acc) do
    {other, remaining_tokens} = factor(tokens)

    case calculate(acc, operation, other) do
      {:ok, result} ->
        do_parse(remaining_tokens, result)

      {:error, _reason} = error ->
        error
    end
  end

  defp calculate(a, :plus, b), do: {:ok, a + b}
  defp calculate(a, :minus, b), do: {:ok, a - b}
  defp calculate(_a, unknown, _b), do: {:error, {:unknown_op, unknown}}

  def calculate_until(expected_token, [expected_token | tokens], acc),
    do: {acc, tokens} |> IO.inspect()

  def calculate_until(expected_token, [operation | tokens], acc) do
    {other, remaining_tokens} = factor(tokens)

    case calculate(acc, operation, other) do
      {:ok, result} ->
        calculate_until(expected_token, remaining_tokens, result)

      _ ->
        raise "boo"
    end
  end
end

case Lexer.lex("1 + (1 1 - -2)") do
  {:ok, tokens} ->
    parsed = Parser.parse(tokens)
    IO.inspect(parsed)

  {:error, reason} ->
    IO.inspect(reason)
end
