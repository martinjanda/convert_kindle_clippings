ExUnit.start

defmodule KindleClippsTest do
  use ExUnit.Case
  # doctest KindleClipps

  test "parse one clip" do
    txt = """
    Managing Humans: Biting and Humorous Tales of a Software Engineering Manager (Michael Lopp)\r
    - Your Highlight on Location 964-965 | Added on Sunday, March 5, 2017 10:47:39 PM\r
    \r
    A one-on-one is your chance to perform weekly preventive maintenance while also understanding the health of your team.\r
    """

    assert KindleClipps.parse_clip(txt) == %{
      title: "Managing Humans: Biting and Humorous Tales of a Software Engineering Manager",
      autor: "Michael Lopp",
      location_start: 964,
      location_end: 965,
      text: "A one-on-one is your chance to perform weekly preventive maintenance while also understanding the health of your team."
    }

  end

  test "parse location and added line" do
    loc_and_added = "- Your Highlight on Location 964-965 | Added on Sunday, March 5, 2017 10:47:39 PM"
    assert KindleClipps.parse_location(loc_and_added) == {964, 965}
  end

  test "sanitize symbols with accents" do
    string = "Ďábelsky žľútoučký kůň"
    assert SanitizeFilename.sanitize(string) == "Dabelsky-zlutoucky-kun"
  end

  test "sanitize removes leading and trailing whitespace, newline, and carriage return characters" do
    string = "  hello\n\rworld  "
    assert SanitizeFilename.sanitize(string) == "hello-world"
  end
end
