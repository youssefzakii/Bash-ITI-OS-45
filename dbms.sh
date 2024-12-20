#!/bin/bash


#############
# main menu #
display_main_menu() {
  echo "Main Menu:"
  echo "1. Create Database"
  echo "2. List Databases"
  echo "3. Connect to Database"
  echo "4. Drop Database"
  echo "5. Exit"
  read -p "Choose an option: " choice
}


##################
# database menu #
display_database_menu() {
  echo "Database Menu:"
  echo "1. Create Table"
  echo "2. List Tables"
  echo "3. Drop Table"
  echo "4. Insert into Table"
  echo "5. Select From Table"
  echo "6. Delete From Table"
  echo "7. Update Table"
  echo "8. Back to Main Menu"
  read -p "Choose an option: " db_choice
}

#############
# create db #
create_database() 
{
  read -p "Enter database name: " db_name
  mkdir -p "$db_name" && echo "Database '$db_name' created."
}

###########
# list db #
list_databases() {
  echo "Databases:"
  ls -d */ 2>/dev/null | sed 's#/##'
}

#############
# delete db #
drop_database() 
{
  read -p "Enter database name to drop: " db_name
  rm -rf "$db_name" && echo "Database '$db_name' dropped."
}

# Function to connect to a database
connect_to_database() {
  read -p "Enter database name to connect: " db_name
  if [ -d "$db_name" ]; then  
  echo "Connected to database '$db_name'." 
  while true; do
  display_database_menu
  case $db_choice in
  1) create_table "$db_name" ;;
  2) list_tables "$db_name" ;;
  3) drop_table "$db_name" ;;
  4) insert_into_table "$db_name" ;;
  5) select_from_table "$db_name" ;;
  6) delete_from_table "$db_name" ;;
  7) update_table "$db_name" ;;
  8) break ;;
  *) echo "Invalid choice." ;;
  esac
  done
  else
  echo "Database '$db_name' does not exist."
  fi
}

##############################
# Function to create a table #
create_table() {
  local db_name=$1
  read -p "Enter table name: " table_name
  read -p "Enter columns (format: col1:type1,col2:type2,...): " columns
  read -p "Enter the unique key column: " unique_key

  if [[ ",$columns," != *",$unique_key:"* ]]; then
    echo "Error: Unique key must be one of the columns."
    return
  fi
  echo "$columns" > "$db_name/$table_name.meta"
  echo "unique_key:$unique_key" >> "$db_name/$table_name.meta"
  touch "$db_name/$table_name"
  echo "Table '$table_name' created."
}


###########################
# Function to list tables #
list_tables() 
{
  local db_name=$1
  echo "Tables in database '$db_name':"
  ls "$db_name" | grep -v ".meta" 2>/dev/null
}

############################
# Function to drop a table #
drop_table() {
  local db_name=$1
  read -p "Enter table name to drop: " table_name
  rm -f "$db_name/$table_name" "$db_name/$table_name.meta" && echo "Table '$table_name' dropped." || echo "Table '$table_name' does not exist."
}




#################################
## insert ##

insert_into_table() {
  local db_name=$1
  read -p "Enter table name: " table_name

  if [ -f "$db_name/$table_name" ]; then
    columns=$(head -1 "$db_name/$table_name.meta")
    unique_key=$(grep "^unique_key:" "$db_name/$table_name.meta" | cut -d: -f2)
    IFS=',' read -r -a col_array <<< "$columns"
    declare -A row

    for col in "${col_array[@]}"; do
      IFS=':' read -r col_name col_type <<< "$col"
      read -p "Enter value for $col_name: " value
      row[$col_name]=$value
    done

    unique_key_value=${row[$unique_key]}
    if [ -n "$unique_key " ] && grep -q "^$unique_key_value " "$db_name/$table_name"; then
      echo "Error: Unique key value '${row[$unique_key]}' already exists."
    else
      # Insert the row
      echo "$(IFS=,; echo "${row[$unique_key]},${row[@]:1}")" >> "$db_name/$table_name"
      echo "Row inserted."
    fi
  else
    echo "Table '$table_name' does not exist."
  fi
}



#####################################
### select ######
select_from_table() 
{
  read -p "Enter table name: " table_name
  if [ -f "$db_name/$table_name" ]; then
    unique_key=$(grep "^unique_key:" "$db_name/$table_name.meta" | cut -d: -f2)
    read -p "Enter $unique_key value to select: " unique_value
   grep "^$unique_value " "$db_name/$table_name"|| echo "No matching record found."
  else
    echo "Table '$table_name' does not exist."
  fi
}


#######################
# delete from a table #
delete_from_table() {
  local db_name=$1
  read -p "Enter table name: " table_name
  if [ -f "$db_name/$table_name" ]; then
    unique_key=$(grep "^unique_key:" "$db_name/$table_name.meta" | cut -d: -f2)
    read -p "Enter $unique_key value to delete: " unique_value
    if grep -q "^$unique_value" "$db_name/$table_name"; then
      sed -i "/^$unique_value/d" "$db_name/$table_name"
      echo "Row with $unique_key=$unique_value deleted."
    else
      echo "No matching record found."
    fi
  else
    echo "Table '$table_name' does not exist."
  fi
}







###########################
### update a table ########
update_table() {
  local db_name=$1
  read -p "Enter table name: " table_name
  if [ -f "$db_name/$table_name" ]; then
    columns=$(head -1 "$db_name/$table_name.meta")
    unique_key=$(grep "^unique_key,:" "$db_name/$table_name.meta" | cut -d: -f1)
    echo "Current data in table '$table_name':"
    cat "$db_name/$table_name"
    read -p "Enter value of row to update: " unique_value

    line_no=$(grep -n "^$unique_value" "$db_name/$table_name" | cut -d: -f1)

    if [ -z "$line_no" ]; then
      echo "Error: Unique key not found."
      return
    fi

    IFS=',' read -r -a col_array <<< "$columns"
    declare -A row

    for col in "${col_array[@]}"; do
      IFS=':' read -r col_name col_type <<< "$col"
      read -p "Enter new value for $col_name ($col_type): " value
      row[$col_name]=$value
    done

    sed -i "${line_no}s/.*/$(IFS=,; echo "${row[@]}")/" "$db_name/$table_name" && echo "Row with $unique_key=$unique_value updated."
  else
    echo "Table '$table_name' does not exist."
  fi
}






#######################################################################################################
# Main program loop
while true; do
  display_main_menu
  case $choice in
    1) create_database ;;
    2) list_databases ;;
    3) connect_to_database ;;
    4) drop_database ;;
    5) echo "Exited"; exit ;;
    *) echo "Invalid choice." ;;
  esac
done
