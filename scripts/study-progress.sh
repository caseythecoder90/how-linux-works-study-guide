#!/bin/bash
# Script to track and display study progress

echo "=== HOW LINUX WORKS - STUDY PROGRESS ==="
echo

# Count chapters
TOTAL_CHAPTERS=$(find chapters/ -mindepth 1 -maxdepth 1 -type d | wc -l)
echo "Total Chapters: $TOTAL_CHAPTERS"

# Count completed notes (non-template files with substantial content)
COMPLETED_NOTES=$(find chapters/ -name "notes.md" -exec wc -l {} \; | awk '$1 > 50 {count++} END {print count+0}')
echo "Completed Notes: $COMPLETED_NOTES"

# Count flashcard files with content
COMPLETED_FLASHCARDS=$(find chapters/ -name "flashcards.md" -exec grep -l "### Card" {} \; 2>/dev/null | wc -l)
echo "Chapters with Flashcards: $COMPLETED_FLASHCARDS"

# Count exercise files with content
COMPLETED_EXERCISES=$(find chapters/ -name "lab-exercises.md" -exec wc -l {} \; | awk '$1 > 100 {count++} END {print count+0}')
echo "Completed Lab Exercises: $COMPLETED_EXERCISES"

echo
echo "=== PROGRESS BREAKDOWN ==="

for chapter_dir in chapters/*/; do
    chapter_name=$(basename "$chapter_dir")
    echo -n "$chapter_name: "
    
    # Check each component
    notes_done=false
    flashcards_done=false
    exercises_done=false
    
    if [ -f "$chapter_dir/notes.md" ] && [ $(wc -l < "$chapter_dir/notes.md") -gt 50 ]; then
        notes_done=true
    fi
    
    if [ -f "$chapter_dir/flashcards.md" ] && grep -q "### Card" "$chapter_dir/flashcards.md" 2>/dev/null; then
        flashcards_done=true
    fi
    
    if [ -f "$chapter_dir/exercises/lab-exercises.md" ] && [ $(wc -l < "$chapter_dir/exercises/lab-exercises.md") -gt 100 ]; then
        exercises_done=true
    fi
    
    # Display status
    status=""
    [ "$notes_done" = true ] && status="${status}N"
    [ "$flashcards_done" = true ] && status="${status}F"
    [ "$exercises_done" = true ] && status="${status}E"
    
    if [ -z "$status" ]; then
        echo "Not Started"
    else
        echo "$status (N=Notes, F=Flashcards, E=Exercises)"
    fi
done

echo
echo "=== NEXT STEPS ==="
echo "1. Complete notes for chapters without 'N'"
echo "2. Create flashcards for chapters without 'F'" 
echo "3. Complete lab exercises for chapters without 'E'"

# Calculate completion percentage
if [ $TOTAL_CHAPTERS -gt 0 ]; then
    COMPLETION_PCT=$(echo "scale=1; ($COMPLETED_NOTES * 100) / $TOTAL_CHAPTERS" | bc -l 2>/dev/null || echo "0")
    echo
    echo "Overall Completion: ${COMPLETION_PCT}%"
fi