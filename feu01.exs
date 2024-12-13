defmodule Lexer do
  @type token() :: {:INTEGER, integer()} | :PLUS | :MINUS | :MOD | :DIV | :MUL | :ILLEGAL

  defguardp is_whitespace(ch) when ch in [?\r, ?\n, ?\s]
  defguardp is_numeric(ch) when ch in ?0..?9

  @spec next_token(binary()) :: {token(), binary()} | :error

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

  # End of file:
  def next_token(<<>>), do: {:EOF, nil}
  def next_token(nil), do: nil

  # Error:
  def next_token(binary) do
    whitespace? = fn ch -> is_whitespace(ch) end

    invalid_indentifier = read_until(whitespace?, binary)
    {{:ILLEGAL, invalid_indentifier}, nil}
  end

  defp read_until(predicate, binary), do: read_until(predicate, binary, <<>>)
  defp read_until(_predicate, <<>>, acc), do: acc

  defp read_until(predicate, <<ch, remaining::binary>>, acc) do
    if predicate.(ch),
      do: acc,
      else: read_until(predicate, remaining, <<acc::binary, ch>>)
  end

  defp integer(binary), do: integer(binary, 0)

  defp integer(<<ch, remaining::binary>>, acc) when is_numeric(ch) do
    new_acc = acc * 10 + (ch - ?0)
    integer(remaining, new_acc)
  end

  defp integer(remaining, acc), do: {acc, remaining}

  def stream(binary) do
    Stream.unfold(binary, &next_token/1)
  end
end

Lexer.stream("1 + 2 + 3")
|> Interpreter.interpret()
