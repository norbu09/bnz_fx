defmodule BnzFx.Fx do
  @record [
    :amount,
    :rate,
    :currency
  ]

  defstruct @record

  def new(amount, currency, :buy) do
    case BnzFx.buy(currency) do
      {:ok, rate} ->
        rec = %{
          amount: amount / rate,
          rate: rate,
          currency: "NZD"
        }

        {:ok, struct(%__MODULE__{}, rec)}

      error ->
        error
    end
  end

  def new(amount, currency, :sell) do
    case BnzFx.sell(currency) do
      {:ok, rate} ->
        rec = %{
          amount: amount * rate,
          rate: rate,
          currency: String.upcase(currency)
        }

        {:ok, struct(%__MODULE__{}, rec)}

      error ->
        error
    end
  end

  ### Access implementation ###
  def fetch(struct, key), do: Map.fetch(struct, key)
  def get(struct, key, default \\ nil), do: Map.get(struct, key, default)

  def get_and_update(struct, key, fun) when is_function(fun, 1) do
    current = get(struct, key)

    case fun.(current) do
      {get, update} ->
        {get, Map.put(struct, key, update)}

      :pop ->
        pop(struct, key)

      other ->
        raise "the given function must return a two-element tuple or :pop, got: #{inspect(other)}"
    end
  end

  def pop(struct, key, default \\ nil) do
    case fetch(struct, key) do
      {:ok, old_value} ->
        {old_value, Map.put(struct, key, nil)}

      :error ->
        {default, struct}
    end
  end
end
