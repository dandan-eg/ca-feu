defmodule Lexer do
  defguardp is_whitespace(ch) when ch in [?\r, ?\n, ?\s]
  defguardp is_numeric(ch) when ch in ?0..?9

  def next_token(<<ch, remaning::binary>>) when is_whitespace(ch) do
    next_token(remaning)
  end

  def next_token(<<"-", ch, _::binary>> = binary) when is_numeric(ch) do
    {int, remaning} = integer(binary_slice(binary, 1..byte_size(binary)))
    {{:integer, -int}, remaning}
  end

  def next_token(<<ch, _::binary>> = binary) when is_numeric(ch) do
    {int, remaning} = integer(binary)
    {{:integer, int}, remaning}
  end

  def next_token(<<"+", remaning::binary>>), do: {{:op, :plus}, remaning}
  def next_token(<<"-", remaning::binary>>), do: {{:op, :minus}, remaning}
  def next_token(<<"*", remaning::binary>>), do: {{:op, :mul}, remaning}
  def next_token(<<"/", remaning::binary>>), do: {{:op, :div}, remaning}
  def next_token(<<"%", remaning::binary>>), do: {{:op, :mod}, remaning}
  def next_token(<<>>), do: {:eof, <<>>}

  defp integer(binary), do: integer(binary, 0)

  defp integer(<<ch, remaining::binary>>, acc) when is_numeric(ch) do
    new_acc = acc + (ch - ?0)
    integer(remaining, new_acc)
  end

  defp integer(remaining, acc), do: {acc, remaining}
end
