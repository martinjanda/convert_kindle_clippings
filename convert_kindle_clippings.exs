#! /usr/bin/env elixir


defmodule KindleClipps do
  @moduledoc """
  `KindleClipps` is a module for parsing Kindle clippings.

  """
  alias SanitizeFilename

  @locationRe ~r/.*Location (\d+)-(\d+).*/i


  @doc """
  Parse a Kindle clipping and create a map with the following keys:
  - `:title` - the title of the book
  - `:location` - the location of the clip
  - `:added` - the date and time the clip was added
  - `:text` - the text of the clip
  """
  def parse_clip(txt) when is_bitstring(txt) do
    txt
    |> String.split("\r\n", [trim: true])
    |> Enum.map(&String.trim/1)
    |> Enum.map(&String.trim_leading(&1, "\uFEFF"))
    |> case do
      [title, loc_and_added, text] ->
        {loc_start, loc_end} = parse_location(loc_and_added)

        %{
          title: parse_title(title),
          autor: parse_autor(title),
          location_start: loc_start,
          location_end: loc_end,
          text: text
        }
      _ ->
        # bookmarks and notes are ignored
        %{}
    end

  end

  # Parse the location from a Kindle clip line
  def parse_location(loc_and_added) do
    case Regex.run(@locationRe, loc_and_added) do
      [_, loc_start, loc_end] ->
        {String.to_integer(loc_start), String.to_integer(loc_end)}
      _ ->
        {nil, nil}
    end

  end


  def parse_title(title) do
    [title | _] = String.split(title, " (")
    title
  end

  def parse_autor(title) do
    values = String.split(title, " (")
    String.trim_trailing(List.last(values, ""), ")")
  end



  @doc """
  Load a file with Kindle clippings and parse each clip.
  Remove invalid clips and duplicates.
  """
  def load_clips(file) do
    File.read!(file)
    |> String.split("==========")
    |> Enum.map(&parse_clip/1)
    |> Enum.reject(fn clip -> Map.get(clip, :text) == nil or Map.get(clip, :location_start) == nil end) # remove invalid clips
    |> Enum.uniq_by(&(&1.location_start ))
  end

  @doc """
  Sort clips by book title and location.
  """
  def sort_clips(clips) do
    Enum.sort(clips, &sort_by_title_and_location/2)
  end

  defp sort_by_title_and_location(clip1, clip2) do
    if clip1.title == clip2.title do
      clip1.location_start < clip2.location_start
    else
      clip1.title < clip2.title
    end
  end

  @doc """
  Write clips to a files per book as markdown
  """
  def write_clips(clips, dir) do
    clips
    |> Enum.group_by(& &1[:title])
    |> Enum.each(fn {title, clips} ->
      File.write!(Path.join([dir, SanitizeFilename.sanitize(title) <> ".md"]), format_md_clips(title, clips))
    end)
  end

  def format_md_clips(title, clips) do
    "# " <> title <> "\n" <> Enum.random(clips).autor <> "\n\n" <> (Enum.map(clips, &format_md_clip/1) |> Enum.join("\n\n"))
  end

  def format_md_clip(clip) do
    """
    > #{clip[:text]}
    > (Location #{clip[:location_start]}-#{clip[:location_end]})

    """
  end
end

defmodule SanitizeFilename do
  @doc """
     Takes a filename and strip and normalizes it with :nfd, keeps number and non accent character.
  """
  def sanitize(string) do
    String.trim(string)
    |> String.normalize(:nfd)
    |> String.replace(~r/[^.0-9A-z\s]/u, "")
    |> String.replace(~r/[[:space:]]+/u, "-")
  end
end


# CLI interface
cli_help = "Usage: convert_kindle_clippings.exs <My Clippings.txt> <export_dir>"
cli_args = System.argv()

case cli_args do
  [input_file, dir] ->
    if !File.dir?(dir) do
      IO.puts("Error: #{dir} is not a directory\n\n#{cli_help}")
      exit(:shutdown)
    end

    if !File.exists?(input_file) do
      IO.puts("Error: #{input_file} does not exist\n\n#{cli_help}")
      exit(:shutdown)
    end

    IO.puts("\nLoading clips from #{input_file} and write files per book to #{dir}\n\n")

    clips = KindleClipps.load_clips(input_file)

    clips
    |> KindleClipps.sort_clips()
    |> KindleClipps.write_clips(dir)

    IO.puts("Done. #{Enum.count(clips)} clips written to #{dir}")
  _ ->
    IO.puts("Error: no input file and output dir\n\n#{cli_help}")
end
