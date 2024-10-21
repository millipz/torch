#!/bin/bash

# Add this variable at the top of your script
SHOULD_EXIT=false

if [[ -z "$EDITOR" ]]; then
    EDITOR="vi"  # or any default editor you prefer
fi

script_exit() {
    SHOULD_EXIT=true
    if [[ "${BASH_SOURCE[0]}" != "${0}" ]]; then
        return $1
    else
        exit $1
    fi
}

search_files() {
    while true; do
        local selected
        selected=$(fd --type f --hidden --follow --exclude .git | fzf --preview 'bat --style=numbers --color=always --line-range :500 {}')
        if [[ -n "$selected" ]]; then
            file_options "$selected"
            local ret=$?
            if [[ $ret -eq 2 ]]; then
                return 2
            elif [[ $ret -eq 3 ]]; then
                return 3
            fi
        else
            return 2
        fi
    done
}

search_dirs() {
    while true; do
        local selected
        selected=$(fd --type d --hidden --follow --exclude .git | fzf --preview 'tree -C {} | head -200')
        if [[ -n "$selected" ]]; then
            dir_options "$selected"
            local ret=$?
            if [[ $ret -eq 2 ]]; then
                return 2
            elif [[ $ret -eq 3 ]]; then
                return 3
            fi
        else
            return 2
        fi
    done
}

file_options() {
    local file="$1"
    while true; do
        local options="Open file in $EDITOR
Open containing directory
Copy path to clipboard
Open in Finder
Back to search
Back to main menu
Exit to shell"
        local choice=$(echo "$options" | fzf --prompt="Action for $file > ")
        case "$choice" in
            "Open file in $EDITOR")
                "$EDITOR" "$file"
                return 3
                ;;
            "Open containing directory")
                cd "$(dirname "$file")"
                echo "Changed to $(pwd)."
                return 3
                ;;
            "Copy path to clipboard")
                echo "$file" | clipcopy
                echo "Path copied to clipboard."
                ;;
            "Open in Finder")
                open "$(dirname "$file")"
                echo "Opened in Finder"
                return 3
                ;;
            "Back to search")
                return
                ;;
            "Back to main menu")
                return 2
                ;;
            "Exit to shell")
                return 3
                ;;
            *)
                echo "Invalid option. Please try again."
                ;;
        esac
        echo "Press Enter to continue..."
        read -r
    done
}

dir_options() {
    local dir="$1"
    while true; do
        local options="Change to directory\nOpen in file manager\nCopy path to clipboard\nBack to search\nBack to main menu\nExit to shell"
        local choice=$(echo -e "$options" | fzf --prompt="Action for $dir > ")
        case "$choice" in
            "Change to directory")
                cd "$dir"
                echo "Changed to $(pwd)."
                return 3
                ;;
            "Open in file manager")
                open "$dir"
                echo "Opened in file manager."
                return 3
                ;;
            "Copy path to clipboard")
                echo "$dir" | clipcopy
                echo "Path copied to clipboard."
                return 3
                ;;
            "Back to search")
                return
                ;;
            "Back to main menu")
                return 2
                ;;
            "Exit to shell")
                return 3
                ;;
        esac
    done
}

# Function to search and launch applications (macOS specific)
search_apps() {
    local selected
    selected=$(find /Applications -name "*.app" -maxdepth 3 | sed 's/.*\///; s/\.app$//' | sort -uf | fzf)
    if [[ -n "$selected" ]]; then
        open -a "${selected}.app"
        echo "Launched $selected"
        read -p "Press Enter to continue..."
    fi
}

# Function to search command history
search_history() {
    local selected
    selected=$(history | fzf --tac | sed 's/^ *[0-9]* *//')
    if [[ -n "$selected" ]]; then
        echo "Executing: $selected"
        eval "$selected"
        read -p "Press Enter to continue..."
    fi
}

# Function to search man pages
search_man() {
    local selected
    selected=$(man -k . | fzf --prompt='Man> ' | awk '{print $1}')
    if [[ -n "$selected" ]]; then
        man "$selected"
    fi
}

# Main menu
main_menu() {
    local options="Search Files\nSearch Directories\nLaunch Applications\nSearch History\nSearch Man Pages\nQuit"
    local selected=$(echo -e "$options" | fzf --prompt="Spotlight-CLI > ")
    case $selected in
        "Search Files") search_files; return $? ;;
        "Search Directories") search_dirs; return $? ;;
        "Launch Applications") search_apps; return 0 ;;
        "Search History") search_history; return 0 ;;
        "Search Man Pages") search_man; return 0 ;;
        "Quit") return 1 ;;
        *) return 0 ;;
    esac
}

main_loop() {
    while true; do
        if $SHOULD_EXIT; then
            return 0
        fi
        main_menu
        ret=$?
        if [[ $ret -eq 1 || $ret -eq 3 ]]; then
            script_exit 0
        fi
    done
}

# Run the main loop
main_loop
if $SHOULD_EXIT; then
    return 0 2>/dev/null || exit 0
fi