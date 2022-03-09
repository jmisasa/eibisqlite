defmodule Eibisqlite.Import do
  alias Exqlite.Sqlite3, as: Sqlite

  @doc """
  Generates database and run import
  """
  def import() do
    File.mkdir("tmp")
    db_file = "./tmp/eibi.sqlite"
    eibi_file_endpoint = "http://eibispace.de/dx/sked-b21.csv"
    eibi_file_tmp = "./tmp/eibi.csv"

    :ok = File.rm!(db_file)
    {:ok, conn} = Sqlite.open(db_file)

    # create tables
    :ok = Sqlite.execute(conn, "create table country_codes (id integer primary key, itu_code text, country_name text)");
    :ok = Sqlite.execute(conn, """
      create table eibi (
        id integer primary key,
        khz real,
        utc text,
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

    {:ok, statement} = Sqlite.prepare(conn, "insert into country_codes (itu_code, country_name) values (?1, ?2)")

    File.cwd! <> "/eibi-files/country_codes.csv"
      |> Path.expand(__DIR__)
      |> File.stream!
      |> CSV.decode()
      |> Enum.drop(1)
      |> Enum.map(fn {:ok, row} ->
        Sqlite.bind(conn, statement, row)
        Sqlite.step(conn, statement)
      end)

#    %HTTPoison.Response{body: body} = HTTPoison.get!(eibi_file_endpoint)
#    File.write!(eibi_file_tmp, body)

    {:ok, statement} = Sqlite.prepare(conn, """
      insert into eibi (
        khz,
        utc,
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
        ?11
      )
    """)

    eibi_file_tmp
    |> Path.expand(__DIR__)
    |> File.stream!
    |> CSV.decode()
    |> Enum.drop(1)
    |> Enum.map(fn {:ok, row} ->
      Sqlite.bind(conn, statement, row)
      Sqlite.step(conn, statement)
    end)

    # Step is used to run statements
    :done = Sqlite.step(conn, statement)
    :ok = Sqlite.release(conn, statement)
  end
end
