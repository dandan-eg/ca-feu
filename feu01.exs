defmodule Lexer do
  @type token() :: {:INTEGER, integer()} | :PLUS | :MINUS | :MO | :DIV | :MUL

  defguardp is_whitespace(ch) when ch in [?\r, ?\n, ?\s]
  defguardp is_numeric(ch) when ch in ?0..?9

  @spec next_token(binary()) :: {token(), binary()} | :error

  def peek(binary) when is_binary(binary) do
    case next_token(binary) do
      {token, _remaining} ->
        token

      :error ->
        :error
    end
  end

  def next_token(<<ch, remaning::binary>>) when is_whitespace(ch) do
    next_token(remaning)
  end

  # Integer:
  def next_token(<<"+", ch, _::binary>> = binary) when is_numeric(ch) do
    {int, remaining} = integer(binary_slice(binary, 1..byte_size(binary)))
    {{:INTEGER, +int}, remaining}
  end

  def next_token(<<"-", ch, _::binary>> = binary) when is_numeric(ch) do
    {int, remaining} = integer(binary_slice(binary, 1..byte_size(binary)))
    {{:INTEGER, -int}, remaining}
  end

  def next_token(<<ch, _::binary>> = binary) when is_numeric(ch) do
    {int, remaining} = integer(binary)
    {{:INTEGER, int}, remaining}
  end

  # Operations:
  def next_token(<<"+", remaining::binary>>), do: {:PLUS, remaining}
  def next_token(<<"-", remaining::binary>>), do: {:MINUS, remaining}
  def next_token(<<"*", remaining::binary>>), do: {:MUL, remaining}
  def next_token(<<"/", remaining::binary>>), do: {:DIV, remaining}
  def next_token(<<"%", remaining::binary>>), do: {:MOD, remaining}

  def next_token(<<>>), do: {:eof, <<>>}

  def next_token(_invalid), do: :error

  defp integer(binary), do: integer(binary, 0)

  defp integer(<<ch, remaining::binary>>, acc) when is_numeric(ch) do
    new_acc = acc * 10 + (ch - ?0)
    integer(remaining, new_acc)
  end

  defp integer(remaining, acc), do: {acc, remaining}
end

defmodule Interpreter do
  def expr(raw) do
    {:ok, remaining, base} = term(raw)
  end

  def term(raw) do
    case Lexer.next_token(raw) do
      {{:INTEGER, base}, remaining} ->
        calculate_op(remaining, [:MUL, :DIV, :MOD], base)

      _ ->
        :error
    end
  end

  def calculate_op(raw, operations, acc) do
    tokens = consume_n_tokens(raw, 2)

    case tokens do
      [
        {op, _},
        {{:INTEGER, int}, remaining}
      ] ->
        if op in operations do
          calculate_op(remaining, operations, calc(acc, op, int))
        else
          {:ok, acc, raw}
        end

      _ ->
        {:ok, acc, raw}
    end
  end

  defp calc(a, :PLUS, b), do: a + b
  defp calc(a, :MINUS, b), do: a - b
  defp calc(a, :MOD, b), do: rem(a, b)
  defp calc(a, :MUL, b), do: a * b
  defp calc(a, :DIV, b), do: round(a / b)

  def consume_n_tokens(raw, n) when n > 0 do
    consume_n_tokens(raw, n, 0, [])
  end

  defp consume_n_tokens(raw, n, n, tokens), do: Enum.reverse(tokens)

  defp consume_n_tokens(raw, n, i, tokens) do
    {token, remaining} = Lexer.next_token(raw)
    consume_n_tokens(remaining, n, i + 1, [{token, remaining} | tokens])
  end
end

Interpreter.term("10 * 5 + 1") |> IO.inspect()
