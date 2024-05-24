#!/bin/bash

# Global variables
data_dir="$HOME/ECEP/LinuxSystems/Projects/.TestData"
user_file="$data_dir/user_credentials.csv"
log_file="$data_dir/test_activity.log"
question_bank="${1:-question_bank.txt}"

# Function to log activities
function log_activity() {
    echo "$(date): $1" >> $log_file
}

# Function to setup environment
function setup_environment() {
    mkdir -p $data_dir
    touch $log_file
    touch $user_file
    [[ ! -f $question_bank ]] && { echo "Question bank file not found."; exit 1; }
}

# Function for user sign-up
function sign_up() {
    echo "Sign up:"
    read -p "Enter username (alphanumeric only): " username
    if ! [[ $username =~ ^[a-zA-Z0-9]+$ ]]; then
        echo "Invalid username."
        return
    fi
    read -s -p "Enter password (min 8 chars, at least one number and symbol): " password
    echo
    if ! [[ $password =~ ^(?=.*[a-zA-Z])(?=.*[0-9])(?=.*[^a-zA-Z0-9]).{8,}$ ]]; then
        echo "Password does not meet requirements."
        return
    fi
    read -s -p "Re-enter password: " password2
    echo
    if [ "$password" != "$password2" ]; then
        echo "Passwords do not match."
        return
    fi
    echo "$username,$password" >> $user_file
    log_activity "User $username created."
}

# Function for user sign-in
function sign_in() {
    echo "Sign in:"
    read -p "Username: " username
    read -s -p "Password: " password
    echo
    if grep -q "$username,$password" $user_file; then
        echo "Login successful."
        log_activity "User $username logged in."
    else
        echo "Invalid credentials."
    fi
}

# Function to take test
function take_test() {
    mkdir -p $data_dir
    answer_file="$data_dir/answer_file.csv"
    touch $answer_file
    while IFS= read -r line; do
        IFS='|' read -ra ADDR <<< "$line"
        question="${ADDR[0]}"
        options=("${ADDR[@]:1}")
        echo "$question"
        select opt in "${options[@]}"; do
            echo "You picked $opt ($REPLY)"
            echo "$question, $opt" >> $answer_file
            break
        done
    done < $question_bank
}

# Main menu
function main_menu() {
    PS3='Choose an option: '
    options=("Sign In" "Take Test" "View Test" "Sign Up" "Exit")
    select opt in "${options[@]}"
    do
        case $opt in
            "Sign In")
                sign_in
                ;;
            "Take Test")
                take_test
                ;;
            "View Test")
                view_test
                ;;
            "Sign Up")
                sign_up
                ;;
            "Exit")
                log_activity "Exit selected."
                break
                ;;
            *) echo "Invalid option $REPLY";;
        esac
    done
}

# Start the script
setup_environment
main_menu
