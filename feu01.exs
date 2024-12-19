defmodule Lexer do
  @type token() ::
          {:INTEGER, integer()}
          | :PLUS
          | :MINUS
          | :MOD
          | :DIV
          | :MUL
          | :ILLEGAL
          | :LPAREN
          | :RPAREN

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

  # Parenthesis:
  def next_token(<<"(", remaining::binary>>), do: {:LPAREN, remaining}
  def next_token(<<")", remaining::binary>>), do: {:RPAREN, remaining}

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
  def next_token(_binary) do
    {:ILLEGAL, nil}
  end

  defp integer(binary), do: integer(binary, 0)

  defp integer(<<ch, remaining::binary>>, acc) when is_numeric(ch) do
    new_acc = acc * 10 + (ch - ?0)
    integer(remaining, new_acc)
  end

  defp integer(remaining, acc), do: {acc, remaining}
end

defmodule Parser do
  def parse(fun, raw) when is_function(fun, 1) do
    {token, remaining} = Lexer.next_token(raw)
    {fun.(token), remaining}
  end

  def parse({prior_fun, :or, other_fun}, raw) do
    case parse(prior_fun, raw) do
      :error ->
        parse(other_fun, raw)

      ok ->
        ok
    end
  end

  def int({:INTEGER, int}), do: int
  def int(_token), do: error()

  def error(), do: :error
end

defmodule Interpreter do
  def interpert() do
  end

  alias Parser, as: P

  def factor(raw) do
    P.parse(&P.int/1, raw)
  end
end

Interpreter.factor("+") |> IO.inspect()
