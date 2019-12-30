defmodule Philomena.Galleries.Query do
  alias Search.Parser

  defp fields do
    [
      int_fields: ~W(id image_count watcher_count),
      literal_fields: ~W(title user image_ids watcher_ids),
      date_fields: ~W(created_at updated_at),
      ngram_fields: ~W(description),
      default_field: {"title", :term},
      aliases: %{
        "user" => "creator"
      }
    ]
  end

  def compile(query_string) do
    query_string = query_string || ""

    fields()
    |> Parser.parser()
    |> Parser.parse(query_string)
  end
end
