# Convert Kindle Clippings

This is a simple script in Elixir lang that converts your highlights from `My Clippings.txt` file to markdown files per book

Input is My Clippings.txt file from Kindle e-ink reader device. Bookmarks and notes are ignored.

Output is markdown file with highlights per book in given directory.


## Usage

```bash
elixir convert_kindle_clippings.exs My\ Clippings.txt export_dir/
```

## Test
No mix project here, only exs file. To run tests:

```bash
elixir -r convert_kindle_clippings.exs convert_kindle_clippings_test.exs 
```

