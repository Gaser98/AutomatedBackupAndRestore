#!/bin/bash

# Function to validate backup parameters
validate_backup_params() {
    array_length=${#params[@]}
    echo "Length of the array: $array_length"
    #Array elements is vars so a check on its  length will always give 4 whether variables are present or not
    declare -A param_values
    param_values[source_dirs]="$source_dirs"
    param_values[dest_dir]="$dest_dir"
    param_values[encryption_key]="$encryption_key"
    param_values[n]="$n"

    # Iterate through the array of parameters
    all_empty=true
    for element in "${!param_values[@]}"; do
        # Check if the variable is not empty
        if [ -n "${param_values[$element]}" ]; then
            all_empty=false
            break
        fi
    done

    # Check if all variables are empty and exit if they are
    if [ "$all_empty" = true ]; then
        echo "Usage: $0 backup_source backup_destination encryption_key days"
        echo "Error: Enter necessary parameters."
        exit 1
    fi
    for element in "${!param_values[@]}"; do
    if [ -z "${param_values[$element]}" ]; then
        echo "Error: $element is empty."
        exit 1
    fi
    done
    source_dirs="${params[0]}"
    dest_dir="${params[1]}"
    n="${params[3]}"
    if [ ! -d "$source_dirs" ]; then
        echo "Error: Source directory '$source_dirs' does not exist."
        exit 1
    fi
    
    if [ ! -d "$dest_dir" ]; then
        echo "Error: Destination directory '$dest_dir' does not exist."
        exit 1
    fi
    if ! [[ "$n" =~ ^[0-9]+$ ]]; then
        echo "Error: Enter a valid number of days."
        exit 1
    fi
}   

# Function to perform backup
backup() {    
    #Add parameters to an array and provide them as input to validation function

    params=()

    # Read input parameters

    echo "Please enter backup_source_dirs (separate with spaces):"
    read -p "source_dirs: " source_dirs

    # Split the input into an array based on spaces
    IFS=' ' read -ra source_dirs<<< "$source_dirs" 
    echo "$source_dirs"
    source_dirs_array+=("${source_dirs[@]}")
    params+=("${source_dirs_array[0]}")

    echo "Please enter backup_destination:"
    read -p "dest_dir: " dest_dir
    params+=("$dest_dir")

    echo "Please enter encryption key:"
    read -p "encryption_key: " encryption_key
    params+=("$encryption_key")

    echo "Please enter days:"  #Days represent backup period 
    read -p "n: " n 
    params+=("$n")
    #Array checks
    echo "Input params"
    echo "${params[1]}"
    for param in "${params[@]}"; do
        echo "$param"
    done
    validate_backup_params "${params[@]}"

    # Create date variable snapshot
    date_var=$(date +'%Y_%m_%d' | sed 's/[\s:]/_/g')
    current_unix=$(date +"%s")

    # Create destination directory
    backup_dest="$dest_dir/$date_var"
    sudo mkdir -p "$backup_dest"

    # Loop over directories in source
    # Iterate through each source directory
    for dir in "${source_dirs[@]}"; do
        echo "Looping for: $dir"
        if [ -d "$dir" ]; then
            # Iterate through files in the directory
            find "$dir" -type f -print0 | while IFS= read -r -d '' file; do
                file_basename=$(basename "$file")
                relative_path="${file#$dir/}"  # Get relative path
                
                # Calculate the difference in days between last modification and date_var
                dir_mtime=$(stat -c %Y "$file")
                diff_seconds=$(( $current_unix - $dir_mtime ))
                diff_days=$(($diff_seconds / 86400)) # 86400 seconds in a day
                
                echo "File: $relative_path, Modification time: $dir_mtime, Time difference in days: $diff_days"

                # Compare diff_days with n
                if [[ $diff_days -eq $n ]]; then
                    echo "Moving $relative_path to the combined tar file"
                    
                    # Append the file to the combined tar file
                    sudo tar -uf "$dest_dir/$combined_tar_name" -C "$dir" "$relative_path"
                else
                    echo "File not qualified for moving: $relative_path"
                fi
            done
        else
            echo "Directory not found: $dir"
        fi
    done
    # Create a combined tar file
    combined_tar_name="combined_${date_var}.tar"
    sudo tar -cf "$dest_dir/$combined_tar_name" --files-from /dev/null
    echo "Combined tar file created" #New empty tar file created

    # Iterate through each source directory
    for dir in "${source_dirs[@]}"; do
        echo "Looping for: $dir"
        if [ -d "$dir" ]; then
            dir_name=$(basename "$dir")

            # Iterate through files in the directory
            #'-print0' is used to get the filenames without the full path
            find "$dir" -type f -print0 | while IFS= read -r -d '' file; do
                file_basename=$(basename "$file")
                relative_path="${file#$dir/}" 
                
                echo "Moving $relative_path to the combined tar file"
                
                # Move the file to the combined tar file
                sudo tar --update --file "$dest_dir/$combined_tar_name" -C "$dir" "$relative_path" #Updates archive with new files only if they are not in the archive and are newer than existing files
            done
        else
            echo "Directory not found: $dir"
        fi
    done

    # Compress the combined tar file
    sudo gzip "$dest_dir/$combined_tar_name"
    echo "Combined tar file compressed"

    # Encrypt the compressed tar file
    sudo gpg --batch --yes --passphrase "$encryption_key" -c "$dest_dir/${combined_tar_name}.gz"
    echo "Combined tar file encrypted"

    # Remove the original compressed tar file
    sudo rm "$dest_dir/${combined_tar_name}.gz"
    echo "Original combined tar file removed"
    # Copy backup to remote server using scp #configured ssh on remote server and all done
    scp -r "$dest_dir/combined_${date_var}.tar.gz.gpg" user@host:~/remote_backup_dir
    echo "Backup completed"
}
# Function to validate restore parameters
validate_restore_params() {
    array_length=${#paramsr[@]}
    echo "Length of the array: $array_length"
    #Array elements is vars so a check on its  length will always give 4 whether variables are present or not
    declare -A param_values
    param_values[source_dir]="$source_dir"
    param_values[dest_dir]="$dest_dir"
    param_values[decryption_key]="$decryption_key"

    # Iterate through the array of parameters
    all_empty=true
    for element in "${!param_values[@]}"; do
        # Check if the variable is not empty
        if [ -n "${param_values[$element]}" ]; then
            all_empty=false
            break
        fi
    done

    # Check if all variables are empty and exit if they are
    if [ "$all_empty" = true ]; then
        echo "Usage: $0 restore_source restore_destination decryption_key"
        echo "Error: Enter necessary parameters."
        exit 1
    fi
    for element in "${!param_values[@]}"; do
    if [ -z "${param_values[$element]}" ]; then
        echo "Error: $element is empty."
        exit 1
    fi
    done 
    
    source_dir="${paramsr[0]}"
    dest_dir="${paramsr[1]}"
    
    
    if [ ! -d "$source_dir" ]; then
        echo "Error: Source directory '$source_dir' does not exist."
        exit 1
    fi
    
    if [ ! -d "$dest_dir" ]; then
        echo "Error: Destination directory '$dest_dir' does not exist."
        exit 1
    fi
    
}

# Function to perform restore
restore() {
    #Add parameters to an array and provide them as input to validation function

    paramsr=()

    # Read input parameters

    echo "Please enter restore_source:"
    read -p "source_dir: " source_dir 
    paramsr+=("$source_dir")

    echo "Please enter restore_destination:"
    read -p "dest_dir: " dest_dir
    paramsr+=("$dest_dir")

    echo "Please enter decryption key:"
    read -p "decryption_key: " decryption_key
    paramsr+=("$decryption_key")

    validate_restore_params "${paramsr[@]}"

    # Create temp directory
    sudo  mkdir -p "$dest_dir/$temp_dir"

    # Loop over encrypted files
    for encrypted_file in "$source_dir"/*.gpg; do
        if [ -f "$encrypted_file" ]; then
            decrypted_file="${encrypted_file%.gpg}"
            decrypted_name=$(basename "$decrypted_file")

            # Decrypt the file
            gpg --batch --yes --passphrase "$decryption_key" -o "$temp_dir/$decrypted_name" -d "$encrypted_file"
            echo "Decrypted $decrypted_name"
            
            # Extract files from temp directory
            sudo tar -xzf "$temp_dir/$decrypted_name" -C "$dest_dir"
            echo "Extracted files from $decrypted_name to $dest_dir"
            
            # Clean up decrypted file
            rm "$temp_dir/$decrypted_name"
            echo "Removed decrypted file $decrypted_name"
        fi
    done

}
