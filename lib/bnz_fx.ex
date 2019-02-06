defmodule BnzFx do
  @moduledoc """
  Documentation for BnzFx.
  """
  require Logger
  @feed "https://www.bnz.co.nz/XMLFeed/portal/fx/xml"
  @cache :bnz_fx

  @doc """
  Hello world.

  ## Examples

      iex> BnzFx.hello()
      :world

  """
  def rates do
    tree =
      get_xml()
      |> Exoml.decode()

    {_, _, r} = tree
    {_, _, r2} = Enum.at(r, 1)
    {_, _, r3} = Enum.at(r2, 1)
    {_updated, rates} = Enum.split(r3, 1)
    Enum.map(rates, fn {_, _, x} -> format(x) end)
  end

  def get(curr) do
    case get_cache(curr) do
      nil -> 
        rates()
        get_cache(curr)
      {:error, :not_found} ->
        rates()
        get_cache(curr)
      rate -> rate
    end
  end

  defp format(rate) do
    rate
    |> Enum.reduce(%{}, fn {x, _, y}, acc -> Map.put(acc, x, List.first(y)) end)
    |> BnzFx.Currency.new()
    |> set_cache()
  end

  defp get_cache(curr) do
    case ConCache.get(@cache, curr) do
      nil -> {:error, :not_found}
      rate -> rate
    end
  end
  defp set_cache(curr) do
    ConCache.put(@cache, curr.currency, curr)  
  end

  defp get_xml() do
    case :httpc.request(String.to_charlist(@feed)) do
      {:ok, {status, _header, body}} ->
        Logger.debug("Fetched FX rates: #{inspect(status)}")
        List.to_string(body)

      error ->
        Logger.warn("Could not fetch feed: #{inspect(error)}")
        error
    end
  end
end
