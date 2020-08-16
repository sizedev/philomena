defmodule PhilomenaWeb.ImageView do
  use PhilomenaWeb, :view

  alias Philomena.Tags.Tag

  def show_vote_counts?(%{hide_vote_counts: true}), do: false
  def show_vote_counts?(_user), do: true

  def title_text(image) do
    tags = truncate(image.tag_list_cache)

    "Size: #{image.image_width}x#{image.image_height} | Tagged: #{tags}"
  end

  def truncate(<<string::binary-size(1024), _rest::binary>>), do: string <> "..."
  def truncate(string), do: string

  def truncate_short(<<string::binary-size(24), _rest::binary>>), do: string <> "..."
  def truncate_short(string), do: string

  def render_intent(_conn, %{thumbnails_generated: false}, _size), do: :not_rendered

  def render_intent(conn, image, size) do
    uris = thumb_urls(image, can?(conn, :show, image))
    vid? = image.image_mime_type == "video/webm"
    gif? = image.image_mime_type == "image/gif"

    hidpi? = conn.cookies["hidpi"] == "true"
    webm? = conn.cookies["webm"] == "true"
    use_gif? = vid? and not webm? and size in ~W(thumb thumb_small thumb_tiny)a
    filter = filter_or_spoiler_value(conn, image)

    cond do
      hidpi? and not (gif? or vid?) ->
        {:hidpi, filter, uris[size], uris[:medium]}

      not vid? or use_gif? ->
        {:image, filter, String.replace(uris[size], ".webm", ".gif")}

      true ->
        {:video, filter, uris[size], String.replace(uris[size], ".webm", ".mp4")}
    end
  end

  def image_link_class(nil) do
    nil
  end

  def image_link_class(_filter) do
    "hidden js-spoiler-target"
  end

  def thumb_urls(image, show_hidden) do
    %{
      thumb_tiny: thumb_url(image, show_hidden, :thumb_tiny),
      thumb_small: thumb_url(image, show_hidden, :thumb_small),
      thumb: thumb_url(image, show_hidden, :thumb),
      small: thumb_url(image, show_hidden, :small),
      medium: thumb_url(image, show_hidden, :medium),
      large: thumb_url(image, show_hidden, :large),
      tall: thumb_url(image, show_hidden, :tall),
      full: pretty_url(image, true, false)
    }
    |> append_full_url(image, show_hidden)
    |> append_gif_urls(image, show_hidden)
  end

  defp append_full_url(urls, %{hidden_from_users: false} = image, _show_hidden),
    do: Map.put(urls, :full, pretty_url(image, true, false))

  defp append_full_url(urls, %{hidden_from_users: true} = image, true),
    do: Map.put(urls, :full, thumb_url(image, true, :full))

  defp append_full_url(urls, _image, _show_hidden),
    do: urls

  defp append_gif_urls(urls, %{image_mime_type: "image/gif"} = image, show_hidden) do
    full_url = thumb_url(image, show_hidden, :full)

    Map.merge(
      urls,
      %{
        webm: String.replace(full_url, ".gif", ".webm"),
        mp4: String.replace(full_url, ".gif", ".mp4")
      }
    )
  end

  defp append_gif_urls(urls, _image, _show_hidden), do: urls

  def thumb_url(image, show_hidden, name) do
    %{year: year, month: month, day: day} = image.created_at
    deleted = image.hidden_from_users
    root = image_url_root()

    format =
      image.image_format
      |> to_string()
      |> String.downcase()
      |> thumb_format(name, false)

    id_fragment =
      if deleted and show_hidden do
        "#{image.id}-#{image.hidden_image_key}"
      else
        "#{image.id}"
      end

    "#{root}/#{year}/#{month}/#{day}/#{id_fragment}/#{name}.#{format}"
  end

  def pretty_url(image, short, download) do
    %{year: year, month: month, day: day} = image.created_at
    root = image_url_root()

    view = if download, do: "download", else: "view"
    filename = if short, do: image.id, else: image.file_name_cache

    format =
      image.image_format
      |> to_string()
      |> String.downcase()
      |> thumb_format(nil, download)

    "#{root}/#{view}/#{year}/#{month}/#{day}/#{filename}.#{format}"
  end

  def image_url_root do
    Application.get_env(:philomena, :image_url_root)
  end

  def image_container(image, link, size, block) do
    hover_text = title_text(image)

    content_tag(:a, block.(), href: link, title: hover_text, class: "image-container #{size}")
  end

  def display_order(tags) do
    Tag.display_order(tags)
  end

  def username(%{name: name}), do: name
  def username(_user), do: nil

  def scope(conn), do: PhilomenaWeb.ImageScope.scope(conn)

  def anonymous_by_default?(conn) do
    conn.assigns.current_user.anonymous_by_default
  end

  def info_row(_conn, []), do: []

  def info_row(conn, [{tag, description, dnp_entries}]) do
    render(PhilomenaWeb.TagView, "_tag_info_row.html",
      conn: conn,
      tag: tag,
      body: description,
      dnp_entries: dnp_entries
    )
  end

  def info_row(conn, tags) do
    render(PhilomenaWeb.TagView, "_tags_row.html", conn: conn, tags: tags)
  end

  def quick_tag(conn) do
    if can?(conn, :batch_update, Tag) do
      render(PhilomenaWeb.ImageView, "_quick_tag.html", conn: conn)
    end
  end

  def deleter(%{deleter: %{name: name}}), do: name
  def deleter(_image), do: "System"

  def scaled_value(%{scale_large_images: false}), do: "false"
  def scaled_value(_user), do: "true"

  def hides_images?(conn), do: can?(conn, :hide, %Philomena.Images.Image{})

  def random_button(conn, params) do
    render(PhilomenaWeb.ImageView, "_random_button.html", conn: conn, params: params)
  end

  def hidden_toggle(%{assigns: %{current_user: nil}}, _route, _params), do: nil

  def hidden_toggle(conn, route, params) do
    render(PhilomenaWeb.ImageView, "_hidden_toggle.html", route: route, params: params, conn: conn)
  end

  def deleted_toggle(conn, route, params) do
    if hides_images?(conn) do
      render(PhilomenaWeb.ImageView, "_deleted_toggle.html",
        route: route,
        params: params,
        conn: conn
      )
    end
  end

  defp thumb_format("svg", _name, false), do: "png"
  defp thumb_format(_, :rendered, _download), do: "png"
  defp thumb_format(format, _name, _download), do: format

  def filter_or_spoiler_value(conn, image) do
    spoilers(conn)[image.id]
  end

  def filter_or_spoiler_hits?(conn, image) do
    Map.has_key?(spoilers(conn), image.id)
  end

  def filter_hits?(conn, image) do
    spoilers(conn)[image.id] == :hidden
  end

  def spoiler_hits?(conn, image) do
    spoilers = spoilers(conn)

    is_list(spoilers[image.id]) or spoilers[image.id] == :complex
  end

  defp spoilers(conn) do
    Map.get(conn.assigns, :spoilers, %{})
  end

  def tag_image(%{image: image}) when not is_nil(image) do
    tag_url_root() <> "/" <> image
  end

  def tag_image(_tag) do
    Routes.static_path(PhilomenaWeb.Endpoint, "/images/tagblocked.svg")
  end

  defp tag_url_root do
    Application.get_env(:philomena, :tag_url_root)
  end
end
