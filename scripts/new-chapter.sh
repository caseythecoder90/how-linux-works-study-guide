#!/bin/bash
# Script to create a new chapter directory with all required files

if [ $# -ne 2 ]; then
    echo "Usage: $0 <chapter-number> <chapter-title>"
    echo "Example: $0 08 'Processes and Jobs'"
    exit 1
fi

CHAPTER_NUM=$1
CHAPTER_TITLE=$2
CHAPTER_DIR="chapter-$(printf "%02d" $CHAPTER_NUM)-$(echo $CHAPTER_TITLE | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/-$//')"

# Create chapter directory structure
mkdir -p "chapters/$CHAPTER_DIR"/{examples,exercises}

# Create README from template
sed "s/\[X\]/$CHAPTER_NUM/g; s/\[Chapter Title\]/$CHAPTER_TITLE/g" templates/chapter-readme-template.md > "chapters/$CHAPTER_DIR/README.md"

# Create notes from template
sed "s/\[X\]/$CHAPTER_NUM/g; s/\[Chapter Title\]/$CHAPTER_TITLE/g" templates/notes-template.md > "chapters/$CHAPTER_DIR/notes.md"

# Create flashcards from template
sed "s/\[X\]/$CHAPTER_NUM/g; s/\[Chapter Title\]/$CHAPTER_TITLE/g" templates/flashcards-template.md > "chapters/$CHAPTER_DIR/flashcards.md"

# Create exercises from template
sed "s/\[X\]/$CHAPTER_NUM/g; s/\[Chapter Title\]/$CHAPTER_TITLE/g" templates/exercises-template.md > "chapters/$CHAPTER_DIR/exercises/lab-exercises.md"

# Create cheatsheet from template
sed "s/\[X\]/$CHAPTER_NUM/g; s/\[Chapter Title\]/$CHAPTER_TITLE/g" templates/cheatsheet-template.md > "chapters/$CHAPTER_DIR/cheatsheet.md"

echo "Created chapter directory: chapters/$CHAPTER_DIR"
echo "Files created:"
echo "  - README.md"
echo "  - notes.md"
echo "  - flashcards.md"
echo "  - exercises/lab-exercises.md"
echo "  - cheatsheet.md"
echo "  - examples/ (directory)"
echo "  - exercises/ (directory)"