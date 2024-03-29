defmodule Eibicrawler do
  defstruct [:machine_name_for_period, :filename, :current_file_link, :last_update]

  @eibi_web "http://www.eibispace.de/"

  def get_current_file_metadata do
    %HTTPoison.Response{body: body} = HTTPoison.get!(@eibi_web)
    {:ok, document} = Floki.parse_document(body)

    current_file_relative_link = document
      |> Floki.find("a:fl-contains('CSV database')")
      |> Floki.attribute("href")
      |> List.first()

    %{"current_file_name" => current_file_name} = Regex.named_captures(
      ~r/^dx\/(?<current_file_name>.+)$/,
      current_file_relative_link
    )

    period_full_string = document
      |> Floki.find("span:fl-contains('The current EiBi shortwave schedules')")
      |> Floki.text()

    %{"period" => period} = Regex.named_captures(
      ~r/^The current EiBi shortwave schedules \((?<period>.+)\)$/,
      period_full_string
    )

    machine_name_for_period = period
      |> String.replace(" ", "_")
      |> String.downcase

    last_update = document
      |> Floki.find("center:nth-of-type(2) > table:first-of-type > tr:first-of-type > td:last-of-type > span")
      |> Floki.text()
      |> (&(Regex.run(
        ~r/(?<date>\d{1,2} [A-Za-z]{3} 20\d{2})(.+)?/,
        &1,
        [capture: ["date"]]
      ))).()
      |> List.first()

    %Eibicrawler{
      machine_name_for_period: machine_name_for_period,
      filename: current_file_name,
      current_file_link: @eibi_web <> current_file_relative_link,
      last_update: last_update
    }
  end
end
