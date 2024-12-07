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
  def parse(tokens) do
    case term(tokens) do
      {:ok, base, remaining_tokens} ->
        case do_parse(remaining_tokens, base) do
          {:ok, acc, []} = ok ->
            ok
        end

      {:error, _reason} = error ->
        error
    end
  end

  defp do_parse([:eof], acc), do: {:ok, acc, []}
  defp do_parse([:close_parenthesis | _] = tokens, acc), do: {:ok, acc, tokens}

  defp do_parse([op | tokens], acc) when op in [:plus, :minus] do
    case term(tokens) do
      {:ok, int, remaining_tokens} ->
        result = calculate(acc, op, int)
        do_parse(remaining_tokens, result)

      {:error, _reason} = error ->
        error
    end
  end

  defp term(tokens) do
    case factor(tokens) do
      {:ok, base, remaining_tokens} ->
        do_term(remaining_tokens, base)

      {:error, _reason} = error ->
        error
    end
  end

  defp do_term([op | tokens], acc) when op in [:div, :mod, :mul] do
    case factor(tokens) do
      {:ok, int, remaining_tokens} ->
        result = calculate(acc, op, int)
        do_term(remaining_tokens, result)

      {:error, _reason} = error ->
        error
    end
  end

  defp do_term(tokens, acc), do: {:ok, acc, tokens}

  defp factor([{:integer, int} | remaining_tokens]) do
    {:ok, int, remaining_tokens}
  end

  defp factor([:eof]), do: {:error, :incomplete}

  defp factor([:open_parenthesis | tokens]) do
    case parse(tokens) do
      {:ok, acc, [:close_parenthesis | remaning_tokens]} ->
        {:ok, acc, remaning_tokens}

      {:ok, _acc, _tokens} ->
        {:error, :missing_closing_parenthesis}

      {:error, _tokens} = error ->
        error
    end
  end

  defp factor([token | _]), do: {:error, {:unexpected, token}}

  defp calculate(a, :plus, b), do: a + b
  defp calculate(a, :minus, b), do: a - b
  defp calculate(a, :mul, b), do: a * b
  defp calculate(a, :mod, b), do: rem(a, b)
  defp calculate(a, :div, b), do: round(a / b)
end

case Lexer.lex("(1 + 3 * 2") |> IO.inspect() do
  {:ok, tokens} ->
    parsed = Parser.parse(tokens)
    IO.inspect(parsed)

  {:error, reason} ->
    IO.inspect(reason)
end
