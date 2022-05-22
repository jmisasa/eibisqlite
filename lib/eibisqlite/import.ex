defmodule Import do
  alias Exqlite.Sqlite3, as: Sqlite

  @db_file File.cwd! <> "/tmp/eibi.sqlite"

  @eibi_country_codes_file File.cwd! <> "/eibi-files/country_codes.csv"
  @eibi_language_codes_file File.cwd! <> "/eibi-files/language_codes.csv"
  @eibi_file_tmp File.cwd! <> "/tmp/eibi.csv"

  @csv_header_khz "kHz:75"
  @csv_header_utc "Time(UTC):93"
  @csv_header_days "Days:59"
  @csv_header_itu_code "ITU:49"
  @csv_header_station "Station:201"
  @csv_header_language "Lng:49"
  @csv_header_target_area_code "Target:62"
  @csv_header_remarks "Remarks:135"
  @csv_header_persistence_code "P:35"
  @csv_header_start_date "Start:60"
  @csv_header_end_date "Stop:60"

  @doc """
  Generates database and run import
  """
  @spec import(%Eibicrawler{}) :: String.t()
  def import(current_file_info) do
    File.mkdir("tmp")

    if File.exists?(@db_file) do
      :ok = File.rm!(@db_file)
    end

    {:ok, conn} = Sqlite.open(@db_file)

    # create tables
    :ok = Sqlite.execute(conn, "create table country_codes (id integer primary key, itu_code text, country_name text)");
    :ok = Sqlite.execute(conn, """
      create table eibi (
        id integer primary key,
        khz real,
        utc_start text,
        utc_end text,
        days text,
        itu_code text,
        station text,
        language text,
        target_area_code text,
        remarks text,
        persistence_code integer,
        start_date text,
        end_date text
      )
      """);
    :ok = Sqlite.execute(conn, "create table language_codes (language_code text primary key, description text, iso639_3 text)")

    {:ok, statement} = Sqlite.prepare(conn, "insert into country_codes (itu_code, country_name) values (?1, ?2)")

    @eibi_country_codes_file
      |> Path.expand(__DIR__)
      |> File.stream!
      |> CSV.decode()
      |> Enum.drop(1)
      |> Enum.map(fn {:ok, row} ->
        Sqlite.bind(conn, statement, row)
        Sqlite.step(conn, statement)
      end)

    {:ok, statement} = Sqlite.prepare(conn, "insert into language_codes (language_code, description, iso639_3) values (?1, ?2, ?3)")

    @eibi_language_codes_file
    |> Path.expand(__DIR__)
    |> File.stream!
    |> CSV.decode()
    |> Enum.drop(1)
    |> Enum.map(fn {:ok, row} ->
      Sqlite.bind(conn, statement, row)
      Sqlite.step(conn, statement)
    end)

    %Eibicrawler{current_file_link: current_file_link} = current_file_info
    %HTTPoison.Response{body: body} = HTTPoison.get!(current_file_link)
    {:ok, utf8_body} = Codepagex.to_string(body, :iso_8859_1)
    File.write!(@eibi_file_tmp, utf8_body)

    {:ok, statement} = Sqlite.prepare(conn, """
      insert into eibi (
        khz,
        utc_start,
        utc_end,
        days,
        itu_code,
        station,
        language,
        target_area_code,
        remarks,
        persistence_code,
        start_date,
        end_date
      ) values (
        ?1,
        ?2,
        ?3,
        ?4,
        ?5,
        ?6,
        ?7,
        ?8,
        ?9,
        ?10,
        ?11,
        ?12
      )
    """)

    @eibi_file_tmp
    |> Path.expand(__DIR__)
    |> File.stream!
    |> CSV.decode(separator: ?;, validate_row_length: false, headers: true)
    |> Enum.drop(1)
    |> Enum.map(fn {:ok, row} ->
      %{
        @csv_header_khz => khz,
        @csv_header_utc => utc,
        @csv_header_days => days,
        @csv_header_itu_code => itu_code,
        @csv_header_station => station,
        @csv_header_language => language,
        @csv_header_target_area_code => target_area_code,
        @csv_header_remarks => remarks,
        @csv_header_persistence_code => persistence_code,
        @csv_header_start_date => start_date,
        @csv_header_end_date => end_date
      } = row

      %{
        "utc_start" => utc_start,
        "utc_end" => utc_end
      } = Regex.named_captures(~r/^(?<utc_start>\d{4})-(?<utc_end>\d{4})$/, utc)

      Sqlite.bind(conn, statement, [
          khz,
          utc_start,
          utc_end,
          days,
          itu_code,
          station,
          language,
          target_area_code,
          remarks,
          persistence_code,
          start_date,
          end_date
      ])

      Sqlite.step(conn, statement)
    end)

    # Step is used to run statements
    :done = Sqlite.step(conn, statement)
    :ok = Sqlite.release(conn, statement)

    :ok
  end
end
