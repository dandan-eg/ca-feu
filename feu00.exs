# Echauffement
defmodule Exercice do
  @corner "o"
  @vertical_border "|"
  @horizontal_border "-"

  def draw_rectangle(width, length) do
    Enum.each(1..length, fn
      i when i == 1 or i == length ->
        draw_line(@corner, @horizontal_border, width)

      _ ->
        draw_line(@vertical_border, " ", width)
    end)
  end

  defp draw_line(edge, middle, width) do
    Enum.each(1..width, fn
      ^width -> IO.puts(edge)
      1 -> IO.write(edge)
      _ -> IO.write(middle)
    end)
  end

  @spec validate_args(list(String.t())) ::
          {:ok, non_neg_integer(), non_neg_integer()}
          | {:error, :bad_args}
          | {:error, {:negative, integer}}
          | {:error, {:nan, String.t()}}

  def validate_args([maybe_width, maybe_length]) do
    with {:ok, width} <- validate_to_numbers(maybe_width),
         {:ok, length} <- validate_to_numbers(maybe_length) do
      {:ok, width, length}
    end
  end

  def validate_args(_args), do: {:error, :bad_args}

  def validate_to_numbers(string) do
    case Integer.parse(string) do
      :error -> {:error, {:nan, string}}
      {num, _rest} when num <= 0 -> {:error, {:negative, num}}
      {num, _rest} -> {:ok, num}
    end
  end

  def run do
    System.argv()
    |> validate_args()
    |> case do
      {:ok, width, length} ->
        draw_rectangle(width, length)

      {:error, {:nan, invalid}} ->
        IO.puts("'#{invalid}' is not a valid number.")

      {:error, {:negative, neg_integer}} ->
        IO.puts("#{neg_integer} is not positive number")

      {:error, :bad_args} ->
        IO.puts("usage elixir feu00.exs <width> <length>")
    end
  end
end

Exercice.run()
