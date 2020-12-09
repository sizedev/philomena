# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Philomena.Repo.insert!(%Philomena.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Philomena.{Repo, Users.User}
alias Philomena.Images

{:ok, ip} = EctoNetwork.INET.cast({203, 0, 113, 0})
{:ok, _} = Application.ensure_all_started(:plug)

resources =
  "priv/repo/seeds_extra.json"
  |> File.read!()
  |> Jason.decode!()

pleb = Repo.get_by!(User, name: "Pleb")
request_attributes = [
  fingerprint: "c1836832948",
  ip: ip,
  user_agent: "Hopefully not IE",
  referrer: "localhost",
  user_id: pleb.id,
  user: pleb
]

IO.puts "---- Generating images"
for image_def <- resources["remote_images"] do
  file = Briefly.create!()
  now = DateTime.utc_now() |> DateTime.to_unix(:microsecond)

  IO.puts "Fetching #{image_def["url"]} ..."
  {:ok, %{body: body}} = Philomena.Http.get(image_def["url"])

  File.write!(file, body)

  upload = %Plug.Upload{
    path: file,
    content_type: "application/octet-stream",
    filename: "fixtures-#{now}"
  }

  IO.puts "Inserting ..."

  Images.create_image(
    request_attributes,
    Map.merge(image_def, %{"image" => upload})
  )
  |> case do
    {:ok, %{image: image}} ->
      IO.puts "Created image ##{image.id}"

    {:error, :image, changeset, _so_far} ->
      IO.inspect changeset.errors
  end
end

IO.puts "---- Done."
