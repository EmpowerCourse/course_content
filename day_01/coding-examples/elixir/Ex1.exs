defmodule Ex1 do
  def run do
    add2(2, 4)
    |> show_result
  end

  defp add2(n1, n2) do
    n1 + n2
  end
  # or, this can be written more simply:
  # defp add2(n1, n2), do: n1 + n2  

  defp show_result(result) do
    IO.puts result
  end
  # or, again, this can be written more simply:
  # defp show_result(result), do: IO.puts result  
end