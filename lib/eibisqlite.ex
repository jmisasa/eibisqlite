defmodule Eibisqlite do
  @moduledoc """
  Documentation for `Eibisqlite`.
  """

  @doc """
  Run import
  """
  def import do
    Eibisqlite.Import.import()
  end
end
