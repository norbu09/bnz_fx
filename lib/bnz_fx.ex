defmodule BnzFx do
  @moduledoc """
  This module parses the BNZ currency feed and exposes it as a easy to use data
  structure. It does cache internally by default for an hour but can be
  overwritten by setting the `ttl` config variable.
  
  """
  require Logger
  @feed "https://www.bnz.co.nz/XMLFeed/portal/fx/xml"
  @cache :bnz_fx
  @ttl Application.get_env(:bnz_fx, :ttl, :timer.seconds(3600))

  @doc """
  Get the full BnzFx struct - thius holds all information that we get from the
  BNZ XML feed

  ## Examples

      iex> BnzFx.get("USD")
      {:ok, %BnzFx.Currency{
        chequebuy: "0.6962",
        country: "United States",
        currency: "USD",
        label: "United States dollars",
        notebuy: "0.7154",
        notesell: "0.6656",
        ttbuy: "0.6904",
        ttsell: "0.6656"
      }}
  """
  def get(curr) do
    symbol = String.upcase(curr)
    case get_cache(symbol) do
      nil -> 
        rates()
        get_cache(symbol)
      {:error, :not_found} ->
        rates()
        get_cache(symbol)
      rate -> rate
    end
  end

  @doc """
  With `buy` we can get the current FX rate for buying NZD at BNZ. Use this for
  [USD|EUR|...] -> NZD. It returns the first available rate in decreasing order
  from electronic transfer over cheque to cash. Depending on the currency not
  all types will be available.

  ## Examples

      iex> BnzFx.buy("USD")
      {:ok, 0.6904}
  """
  def buy(curr) do
    case get(curr) do
      {:ok, fx} ->
        {rate, _} = Float.parse(fx.ttbuy || fx.chequebuy || fx.notebuy)
        {:ok, rate}
      error -> 
        error
    end
  end

  @doc """
  With `sell` we can get the current FX rate for selling a NZD at BNZ. Use
  this for NZD -> [USD|EUR|...]. It returns the first available rate in
  decreasing order from electronic transfer to cash. Depending on the currency
  not all types will be available.

  ## Examples

      iex> BnzFx.sell("AUD")
      {:ok, 0.9384}
  """
  def sell(curr) do
    case get(curr) do
      {:ok, fx} ->
        {rate, _} = Float.parse(fx.ttsell || fx.notesell)
        {:ok, rate}
      error -> 
        error
    end
  end

  @doc """
  The convenience function `to_nzd` converts any amount in a foreign currency
  to NZD based on current exchange rate.

  ## Examples

      iex> BnzFx.to_nzd(100, "usd")
      {:ok, %BnzFx.Fx{amount: 144.8435689455388, currency: "USD", rate: 0.6904}}
  """
  def to_nzd(amount, curr) do
    BnzFx.Fx.new(amount, curr, :buy)
  end

  @doc """
  The convenience function `from_nzd` converts any amount in NZD to a foreign
  currency based on current exchange rate.

  ## Examples

      iex> BnzFx.from_nzd(100, "usd")
      {:ok, %BnzFx.Fx{amount: 66.56, currency: "USD", rate: 0.6656}}
  """
  def from_nzd(amount, curr) do
    BnzFx.Fx.new(amount, curr, :sell)
  end


  # internal plumbing
  defp rates do
      get_xml()
      |> Exoml.decode()
      |> parse_xml
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
      rate -> {:ok, rate}
    end
  end
  defp set_cache(curr) do
    ConCache.put(@cache, curr.currency, %ConCache.Item{value: curr, ttl: @ttl})
  end

  defp parse_xml(tree) do
    {_, _, r} = tree
    {_, _, r2} = Enum.at(r, 1)
    {_, _, r3} = Enum.at(r2, 1)
    {_updated, rates} = Enum.split(r3, 1)
    Enum.map(rates, fn {_, _, x} -> format(x) end)
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
