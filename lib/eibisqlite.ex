defmodule Eibisqlite do
  defstruct [:updated, :machine_name_for_period, :filename, :last_update]

  @moduledoc """
  Documentation for `Eibisqlite`.
  """

  @doc """
  Run import
  """
  def create_version_if_new_file_available do
    last_update = Application.fetch_env!(:eibisqlite, :last_update)
    latest_file = Application.fetch_env!(:eibisqlite, :latest)

    current_file_metadata = Eibicrawler.get_current_file_metadata()

    %Eibicrawler{
      filename: current_file,
      last_update: current_file_last_update,
      machine_name_for_period: current_file_machine_name_for_period
    } = current_file_metadata

    if (current_file_last_update != last_update || latest_file != current_file) do
      :ok = Import.import(current_file_metadata)

      %Eibisqlite{
        updated: true,
        machine_name_for_period: current_file_machine_name_for_period,
        filename: current_file,
        last_update: current_file_last_update
      }
    else
      %Eibisqlite{
        updated: false
      }
    end
  end
end
