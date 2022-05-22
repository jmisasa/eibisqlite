defmodule Mix.Tasks.CreateVersion do
  defstruct [:updated, :machine_name_for_period, :filename, :last_update]

  use Mix.Task

  def run(_) do
    Application.ensure_all_started(:httpoison)

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
        |> Map.from_struct
        |> Poison.encode!
        |> Mix.shell().info
    else
      %Eibisqlite{
        updated: false
      }
        |> Map.from_struct
        |> Poison.encode!
        |> Mix.shell().info
    end
  end
end