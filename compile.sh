#!/usr/bin/env bash
# Convert markdown files in blog-md/ to HTML files in blog/
# Also updates the Blog section in index.html

set -e

# Re-exec with nix-shell if pandoc is not available
if ! command -v pandoc &> /dev/null; then
    exec nix-shell -p pandoc --run "$0"
fi

# Create blog directory if it doesn't exist
mkdir -p blog

# HTML template header
header='<!DOCTYPE html>
<html lang="en-US">
<head>
  <title>%s</title>
  <link rel="stylesheet" type="text/css" href="../v1.css" />
  <meta charset="utf-8">
</head>
<body>
  <div class="content" style="padding-top: 20px;">
'

# HTML template footer
footer='
  </div>
</body>
</html>'

# Array to store blog entries for index.html
declare -a blog_entries

# Convert each markdown file
for md_file in blog-md/*.md; do
    filename=$(basename "$md_file" .md)
    html_file="blog/${filename}.html"

    # Extract date from filename (handles YYYY-MM-DD or YYYY_MM_DD)
    date_raw=$(echo "$filename" | grep -oE '^[0-9]{4}[-_][0-9]{2}[-_][0-9]{2}')
    date_formatted=$(echo "$date_raw" | sed 's/_/-/g')

    # Extract title from first line (remove # prefix if present)
    title=$(head -n 1 "$md_file" | sed 's/^#* *//')

    # Convert markdown to HTML body using pandoc
    body=$(pandoc "$md_file" -f markdown -t html)

    # Write the complete HTML file
    printf "$header" "$title" > "$html_file"
    echo "    <p><em>$date_formatted</em></p>" >> "$html_file"
    echo "$body" >> "$html_file"
    echo "$footer" >> "$html_file"

    # Store entry for index.html (date|html_file|title for sorting)
    blog_entries+=("$date_formatted|$html_file|$title")

    echo "Converted: $md_file -> $html_file"
done

# Generate blog section for index.html (sorted by date, newest first)
blog_section='    <h3 class="heading">Blog</h3>
    <ul>'

while IFS='|' read -r date html_file title; do
    blog_section+="
      <li>
        <p>$date: <a href=\"$html_file\">$title</a></p>
      </li>"
done < <(printf '%s\n' "${blog_entries[@]}" | sort -r)

blog_section+='
    </ul>'

# Generate self-hosted section from self-hosted.md
if [[ -f self-hosted.md ]]; then
    selfhosted_section='    <h3 class="heading">Self-Hosted Services</h3>
    <ul>'

    current_title=""
    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" =~ ^#\  ]]; then
            # Title line - extract title (remove "# " prefix)
            current_title="${line#\# }"
        elif [[ -n "$line" && -n "$current_title" ]]; then
            # Description line
            description="$line"

            # Check if title looks like a URL/domain
            if [[ "$current_title" =~ ^https?:// ]]; then
                url="$current_title"
                display="$current_title"
            elif [[ "$current_title" =~ \. ]]; then
                # Looks like a domain
                url="https://$current_title"
                display="$current_title"
            else
                url=""
                display="$current_title"
            fi

            if [[ -n "$url" ]]; then
                selfhosted_section+="
      <li>
        <p><b><a href=\"$url\">$display</a>:</b> $description</p>
      </li>"
            else
                selfhosted_section+="
      <li>
        <p><b>$display:</b> $description</p>
      </li>"
            fi
            current_title=""
        fi
    done < self-hosted.md

    selfhosted_section+='
    </ul>'

    # Update index.html - replace Self-Hosted Services section
    if grep -q '<h3 class="heading">Self-Hosted Services</h3>' index.html; then
        perl -i -0pe "s|    <h3 class=\"heading\">Self-Hosted Services</h3>\n    <ul>.*?</ul>|$selfhosted_section|s" index.html
        echo "Updated Self-Hosted Services section in index.html"
    else
        echo "Warning: Self-Hosted Services section not found in index.html"
    fi
fi

# Update index.html - replace Blog section
if grep -q '<h3 class="heading">Blog</h3>' index.html; then
    # Use perl for multiline replacement
    perl -i -0pe "s|    <h3 class=\"heading\">Blog</h3>\n    <ul>.*?</ul>|$blog_section|s" index.html
    echo "Updated Blog section in index.html"
else
    echo "Warning: Blog section not found in index.html"
fi

echo "Done! HTML files are in the blog/ directory."
