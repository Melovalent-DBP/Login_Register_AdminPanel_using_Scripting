#!/bin/bash

# config constants
USER_FILE="users.csv"           # file to store users

# global variables
users=()                        
# array of users , load every data from csv to array for fast lookup and access

current_user=""                 # current logged in user
current_role=""                 # current role of the user

function sleep_with_dots() {
  local count=$1  # Number of dots to print
  local interval=$2  # Interval between dots in seconds

  for ((i=0; i<count; i++)); do 
    echo -n "."
    sleep $interval #. + interval , then . + interval
  done
  echo  # Move to a new line after the last dot
}


# load users 
# it is used to load every data from users.csv to users array 
# so that every time we don't have to use users.csv 

function load_users() {     # load user data from user.csv and fill users array
  users=()                  # users.clear()  # clear the array 
                            # so that old/duplicate data does not create redundency.
                            # it just clears the data from the memory , not the actual users.csv
  
  if [ ! -f "$USER_FILE" ]; then  
    touch "$USER_FILE"  #if user_file doesn't exist , create file using "touch"
    echo "username,password,email,phone,role,placeholder" > "$USER_FILE"    
    # write the header  
    return
  fi
  {
    read                    # cin >> _   # skip the first line
    while read -r user      # while(cin >> user) 
    do
      users+=("$user")      # users.push_back(user)
    done 
  } < "$USER_FILE"          # read from users.csv instead of stdin
}

# Write current users array info to users.csv (write = save)
function save_users() {
  {
  echo "username,password,email,phone,role,placeholder"
  for user in "${users[@]}"; do   # for (user in users)
    echo "$user"                  #   cout << user << endl 
  done
  } > "$USER_FILE"
}


# Helps to extract values from users.csv to string format to manipulate
# The main use is to get values line by line from users.csv
# It is the structure , as like input string structure

function csv_get() {   # csv_get("username,password,email,phone,role", 0) => "username"
  local csv="$1"  #here csv = "username,password,email,phone,role" , basically as a 2D array, it is the row index
  local idx="$2"  #here idx = 1 , basically as 2D array, it is the column index
  
  #[username , password , email ,....][idx=1 means 1st user]
  #[username , password , email ,....][idx=2 means 2nd user]
  
  local IFS=, 
  # IFS[Internal Field Seperator] = "," {username , password , ....}
  
  local -a array=($csv) 
  # array = csv.split(",") 
  
  echo "${array[$idx]}"  
  #array[0] = username
  #array[1] = password ... 
 
 }

function csv_set() {  
#csv_set("username,password,email,phone,role", 0, "new_username") => "new_username,password,email,phone,role"
  local csv="$1" # username,password,email,phone,role
  local idx="$2" # idx
  local value="$3" # "new_username"
  local IFS=,
  local -a array=($csv)   # array = csv.split(",")
  array[$idx]="$value" 
  local res=""
  for item in "${array[@]}"; do
    if [ -z "$res" ]; then  # -z means empty / not
      res="$item"           #sets the array value first time
    else
      res="$res,$item"      # previous value , new value
    fi
  done
  echo "$res," 
}

# user related functions

#Admin Functionality: Remove User
function remove_user() {
  local username="$1"
  local new_users=()                                  # new_users = []
  for user in "${users[@]}"; do      #as 
    if [ $(csv_get "$user" 0) == "$username" ]; then  # if (users[i][0] == username): continue
      continue;                                       #skipping the user that matches the username
    fi
    new_users+=("$user")  
    #new_users.push_back(user)
    #if the username match , then skips the user and add the remaining users in the new_users array 
  done
  users=("${new_users[@]}")                           # users = new_users
  save_users
  echo 
}

#User list show
function list_users() {
  echo "List of users:"
  if [ $current_role != "admin" ]; then
    printf "%3s\t %15s\n" "ID" "Username"             #Admin Header
    # printf("%3s\t %15s\n", "ID", "Username")        
    # 3 charcter for ID , 15 charcter for Username        
  else                                                #User Header
    printf "%3s\t %15s\t %20s\t %12s\t %6s\n" "ID" "Username" "Email" "Phone" "Role"
  fi
  idx=1  #For showing the Sequence of User
  for user in "${users[@]}"; do             # for (user in users)
    local username=$(csv_get "$user" 0)     #     username = users[i][0] 
    local password=$(csv_get "$user" 1)     #     user[1]
    local email=$(csv_get "$user" 2)
    local phone=$(csv_get "$user" 3)
    local role=$(csv_get "$user" 4) 
    if [ $current_role != "admin" ];then 
      printf "%03d\t %15s\n" $idx $username
    else
      printf  "%03d\t %15s\t %20s\t %12s\t %6s\n" $idx $username $email $phone $role
    fi
    idx=$((idx + 1))
  done
}

function add_file_with_owner() {
  echo "Enter the name of the file to add:"
  read file_name     #Name of New FIle name
  sleep_with_dots 3 0.5
  touch "$file_name"


  local ownership_file="file_ownership.txt" 
  #A list of created_file with OWner
  #Two Part", Owner name : File Name

  local temp_file="temp_$ownership_file"   #It contain Updated_Owner with FileName
  local found=0 #a variable to check the file in txt/not

  # Check the created file exists in the txt /not 
  # , otherwise add a new entry
  while IFS=: read -r existing_file owner; do   # while(file_name , owner_name) in ownership_file
   
    if [ "$existing_file" == "$file_name" ]; then  
    # this logic is to check if the file is already present in the file_ownership.txt file 
      
      echo "Error: A file with the name '$file_name' already exists. Please choose Another FileName"
      return
    fi
    echo "$existing_file:$owner" >> "$temp_file"
  done < "$ownership_file"

  # If the file was not found in the list, add it as a new owner
  echo "$file_name:$current_user" >> "$temp_file"
  echo "$file_name added successfully."
  sleep_with_dots 3 0.5
  
  # Replace the original ownership file with the updated temp file
  mv "$temp_file" "$ownership_file"
}
#DBP_HIGHLIGHTES

function remove_file_if_owner() {
  echo "Enter the name of the file to remove:"
  read file_name  
  sleep_with_dots 3 0.5
  if [ -f "$file_name" ]; then
    local owner=$(grep "^$file_name:" file_ownership.txt | cut -d':' -f2) 
    #grep - finds out the file_name from file_ownership.txt
    #cut means cut the file_ownership.txt file with delimiter ":" and print the second field
    #cut actually finds out the owner
    
    if [ "$owner" == "$current_user" ]; then
      rm "$file_name"
      echo "$file_name removed successfully."
      
      # Also remove the entry from the tracking file "temp.txt"
      
      # -v "^$file_name:" part filters out all lines 
      # file_name-এর সাথে মিলে যাওয়া লাইন বাদ দিয়ে বাকি সব লাইন থাকবে।

      grep -v "^$file_name:" file_ownership.txt > temp.txt && mv temp.txt file_ownership.txt
    else
      echo "Only the owner ($owner) can remove this file."
      sleep_with_dots 3 0.5
    fi
  else
    echo "File does not exist."
    sleep_with_dots 3 0.5
  fi
}
#DBP_NOTES

function remove_file_admin() {
  echo "Enter the name of the file to remove:"
  read file_name
  if [ -f "$file_name" ]; then
    # No longer checks if the current user is the owner
    rm "$file_name"
    echo "$file_name removed successfully."
    sleep_with_dots 3 0.5
    # Also remove the entry from the tracking file
    grep -v "^$file_name:" file_ownership.txt > temp.txt && mv temp.txt file_ownership.txt #here grep -v is used to remove the line that matches the pattern "^$file_name:" from the file_ownership.txt file and then the output is redirected to temp.txt file and then the temp.txt file is renamed to file_ownership.txt
  else 
    echo "File does not exist."
    sleep_with_dots 3 0.5
  fi
}

function show_all_files() {
  local ownership_file="file_ownership.txt"
  if [ ! -f "$ownership_file" ]; then  # -f , file or not
    echo "No files have been added yet."
    sleep_with_dots 3 0.5
    return
  fi

  echo "All added files and their owners:"
  sleep_with_dots 3 0.5
    while IFS=: read -r filename owner; 
    do
    echo "$filename - owned by $owner"
  done < "$ownership_file"
}



function finduser() {  # finduser("username") => user_id
  local username=$1
  local user_id=0;
  for user in "${users[@]}"; do
    if [ $(csv_get "$user" 0) == "$username" ]; then    # if (users[user_id][0] == username) return user_id
      echo "$user_id"
      return 0
    fi
    user_id=$((user_id + 1))
  done
  echo "-1"
}

function modify_user() {
  list_users
  local options=("Modify Username" "Modify Password" "Modify Email" "Modify Phone" "Modify Role" "Done" "Cancel")
  read -p "Enter username: " username
  local idx=$(finduser $username)
  if (( idx == -1 )); then
    echo "Invalid username: $username"
    return 1
  else 
    local user=${users[idx]}      # user = users[idx]
    while [ 1 ];do
      choice "" "${options[@]}"
      case $? in
        0)
          read -p "Enter new username: " new_username
          users[idx]=$(csv_set "$user" 0 "$new_username")     # users[idx][0] = new_username
          ;;
        1)
          read -p "Enter password: " new_password
          users[idx]=$(csv_set "$user" 1 "$new_password")
          ;;
        2)
          read -p "Enter new email: " new_email
          users[idx]=$(csv_set "$user" 2 "$new_email")
          ;;
        3)
          read -p "Enter new phone: " new_phone
          users[idx]=$(csv_set "$user" 3 "$new_phone")
          ;;
        4)
          read -p "Enter new role: " new_role
          users[idx]=$(csv_set "$user" 4 "$new_role")
          ;;
        5)
          save_users
          return 0
          ;;
        6)
          load_users
          return 0
          ;;
        *)
          echo "Invalid choice"
          ;;
      esac
    done
  fi

}

# user authentication functions
function login() {
  read -p "Enter username: " username               # cin >> username
  read -p "Enter password: " password      # cin >> password
  for user in "${users[@]}"; do                     # for (i=0; i < users.length; i++)
    local user_username=$(csv_get "$user" 0)        #    user_username = users[i][0] 
    local user_password=$(csv_get "$user" 1)        #    user_password = users[i][1]
    if [ "$username" == "$user_username" ] && [ "$password" == "$user_password" ]; then
      current_user="$username"                      #    current_user = username
      current_role=$(csv_get "$user" 4)             #    current_role = user[i][4]
      clear
      echo "Login successful"
      sleep_with_dots 3 0.5  # This will print 5 dots, with a 0.5-second interval between each dot.
      return 0
    fi
  done
  echo "Login failed"
  sleep_with_dots 3 0.5  # This will print 5 dots, with a 0.5-second interval between each dot.
  return 1
}

function logout() {
  current_user=""
  current_role=""
  echo "Goodbye"
  sleep_with_dots 5 0.5  # This will print 5 dots, with a 0.5-second interval between each dot.
}


function signup() {
  echo "Signup"
  read -p "Enter username: " username
  read -p "Enter password: " password
  read -p "Enter email: " email
  read -p "Enter phone: " phone
  users+=("$username,$password,$email,$phone,user,")
  save_users
  echo "Signup successful"
  sleep_with_dots 3 0.5  # This will print 5 dots, with a 0.5-second interval between each dot.
}

# helper function to display a menu
function choice() {      # choice("intro message", "option1", "option2", ...)
  local intro="$1"   #intro message  
  local opts=("$@")  
  local res=""

  # Print the intro message with animation
  IFS=' ' read -r -a words <<< "$intro" #Seperates each word from Intro Message
                                        # -r -> reads special symbol as text
                                        # -a -> convert the 
  for word in "${words[@]}"; do       
      echo -n "$word "
      sleep 0.5 # Adjust sleep as needed for desired speed
  done
  echo # Move to a new line

  
  for (( i=1; i<${#opts[@]}; i++ )); do   # for (i=1; i<opts.length; i++)
    echo "$i) ${opts[$i]}"                # cout << i << ") " << opts[i] << endl
  done
  read -p "Enter your choice: " res       # cin >> res
  return $((res - 1))                     # return res-1
} 


# when normal user is logged in
function user_menu() {
  local options=("List Users" "Show All File" "Add File" "Remove File" "Logout" "Quit")
  choice "Welcome To The User Menu" "${options[@]}"
  case "$?" in
    0)
      clear
      list_users
      ;;
    
    1)
      clear
      show_all_files
      ;;
    
    2)
      clear
      add_file_with_owner
      ;;

    3)
      clear
      remove_file_if_owner
      ;;

    4)
      clear
      logout
      ;;
    5)
      clear
      echo "Goodbye"
      sleep_with_dots 5 0.5
      exit 0
      ;;
    *)
      echo "Invalid choice"
      ;;
  esac
}

# when admin user is logged in
function admin_menu() {
  local options=("Add User" "Remove User" "Modify Users" "List Users" "Show All File" "Remove File" "Logout" "Quit")
  choice "Welcome to Admin Portal" "${options[@]}"
  case "$?" in
    0)
      clear
      echo "Add User"
      read -p "Enter username: " username
      read -p "Enter password: " password
      read -p "Enter email: " email
      read -p "Enter phone: " phone
      read -p "Enter role: " role
      users+=("$username,$password,$email,$phone,$role,")
      save_users
      ;;
    1)
      clear
      echo "Remove User"
      list_users
      read -p "Enter username: " username
      remove_user "$username"
      ;;
    2)
      clear
      modify_user
      [ $? -eq 0 ] && echo "User modified successfully"     # if (modify_user() == 0) { cout << "User modified successfully" }
      [ $? -eq 1 ] && read -p "Press Enter to continue..."  # if (modify_user() == 1) { cout << "Press Enter to continue..."}
      ;;
    3)
      clear
      list_users
      read -p "Press Enter to continue..."
      ;;

    4)
      clear
      show_all_files
      ;;

    
    5)
      clear
      remove_file_admin
      ;;

    6)
      clear
      logout
      ;;


    7)
      clear
      echo "Goodbye"
      sleep_with_dots 5 0.5
      exit 0
      ;;
    *)
      echo "Invalid choice"
      ;;
  esac
}

# when user hasn't logged in
function nologin_menu() {
  welcome_message="Welcome To The User Management System"
  local options=("Login" "Signup" "Quit")
  choice "$welcome_message" "${options[@]}"
  case "$?" in        # switch(choice return value)
    0)
      clear             # clear the screen
      login             # call login function
      ;;
    1)
      clear
      signup
      ;;

      
    2)
      clear
      echo "Goodbye"
      sleep_with_dots 5 0.5
      exit 0
      ;;
    *)
      echo "Invalid choice"
      ;;
  esac
}

# main function
function main() {
  clear                       # clear the screen
  load_users                  # load users from users.csv
  while [ 1 ]; do             # infinite loop
    case "$current_role" in   #   switch(current_role)
      "user")                 #     case "user":
        user_menu             #      show user menu
        ;;                    #      end_case
      "admin")
        admin_menu
        ;;
      *)
        nologin_menu
        ;;
    esac
  done
}

main                         # call the main function 