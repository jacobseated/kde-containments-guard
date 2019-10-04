#!/bin/sh

# Script to deal with a bug/flaw in KDE causing loss of widget/icon location on resolution change
# Run the script once after rebooting, or before starting a game, or other fullscreen application that changes the resolution.
# This script should work with multiple monitors, but you need to run it once with each setup, since a backup is made for each "resolution"
#
#   @author Jacob Kristensen (JacobSeated)
#

# Just a few
#     variables
#     :-)

# The directory the script
# | sed 's/ /\\ /g'

# The script dir is used when calling the PHP script
script_dir=$(dirname "$(readlink -f "$0")")

# The root directory of the resolution-fixer data. I.e. /home/YourUser/kde-containments-guard
containments_guard_directory="$HOME/kde-containments-guard"

# The directory where the backup should be restored to
plasma_config_directory="$HOME/.config"

# Logfile
log_file="$containments_guard_directory/watch_log.txt"

# Fetch current screen resolution, and store it in a variable
current_resolution="$(xdpyinfo | awk '/dimensions/{print $2}')"

# The filename of the plasma configuration that contains the positions of widgets. Etc.
config_file_name='plasma-org.kde.plasma.desktop-appletsrc'
backup_file_name="containments_"$current_resolution".txt"

config_file_path="$plasma_config_directory/$config_file_name"
backup_file_path="$containments_guard_directory/$backup_file_name"

stored_resolution_file_path="$containments_guard_directory/stored_resolution.txt"

config_full_timestamp=$(date +%m-%d-%Y)
config_full_backup_path="$containments_guard_directory/$config_file_name"'_'"$config_full_timestamp.bak"

# Do not change these variables
resolution_has_changed=false

# Just a few
#     functions
#     :-P

write_log () {
    date_time=$(date +%m-%d-%Y" "%H:%M:%S)
    echo "$date_time: $1"
    # echo "$date_time: $1" >> $log_file
}

prevent_root () {
    i_am=$(whoami)
    if [ $i_am = 'root' ]
    then
        write_log "This script should NOT be run as root. Doing nothing."
        exit 0
    fi
}

make_backup () {
    read_config_file
    # First create the resolution directory if it does not exist, then make a backup of [Containments]
    write_log "Made a backup of the configuration file."
    mkdir -p "$containments_guard_directory" && echo "$config_file_content" > "$backup_file_path"
    exit
}

restore_from_backup () {
    
    config_file_content_full="$(cat "$config_file_path")"
    backup_file_content="$(cat $backup_file_path)"
    
    # Just to be save, store a backup of the full file
    # Note. Quoted are needed to avoid just writing everything to one line. Sigh. The logic of bash scripting!
    echo "$config_file_content_full" > "$config_full_backup_path"
    
    # Since a simple literal string replacement is really hard in bash,
    # I decided to use PHP instead. Feel free to do this in pure bash if you know how!
    echo "$(php "$script_dir"/str_replace.php "$config_file_path" "$backup_file_path")" > "$config_file_path"
    
    # Kill and restart Plasma after updating the config file
    killall plasmashell
    kstart5 plasmashell
    
    write_log "Containments restored from backup."
    exit
}

verrify_containments () {
    
    # Get the current resolution, and store it in a variable "real_resolution"
    get_real_resolution
    # Check if resolution has changed by comparing real_resolution to stored_resolution
    check_resolution
    
    while [ $resolution_has_changed != false ]
    do
        # Get the current resolution, and store it in a variable "real_resolution"
        get_real_resolution
        # Check if resolution has changed by comparing real_resolution to stored_resolution
        check_resolution
        if [ "$real_resolution" = "$stored_resolution" ]
        then
            # If suddenly real_resolution matches stored_resolution,
            # the resolution must have reverted from whatever activity that changed it.
            # At this point we might want to restore from backup by running check_config
            check_config
        fi
        sleep 5s
    done
    
}

get_real_resolution () {
    # I first used the xdpyinfo command,
    # but for whatever reason, this does not seem to pick up resolution changes
    # made by full screen applications. So, using xrandr instead.
    real_resolution=$(xrandr | grep \* | awk '{print $1}')
}
# The below function is currently not used, since we only need to keep the "stored" resolution in a variable (stored_resolution).
# The configuration will not be modified anyway, unless the containments section has changed.
#
# get_stored_resolution () {
#    if test -f "$stored_resolution_file_path"; then
#        stored_resolution=$(cat "$stored_resolution_file_path")
#    else
#        write_log "The stored_resolution file does not exist. Exiting."
#        exit
#    fi
# }

check_resolution () {
    # Function to check if the resolution was changed by something.
    # If it was changed, we should wait for it to change back before restoring from backup.
    # write_log "Checking resolution."
    if [ "$real_resolution" != "$stored_resolution" ]
    then
        resolution_has_changed=true
    else
        resolution_has_changed=false
    fi
    
}
read_config_file () {
    # Fetch the [Containments][1][General] section in the $config_file_name.
    # This avoids overwriting the entire file, since I am not sure if other sections might be modified by KDE-
    # we probably do not want to overwrite those changes!
    config_file_content=$(cat "$config_file_path" | grep -Pzo "\[Containments\]\[1\]\[General\][^\[]+")
}

check_config () {
    # This function compares the [containment] section of the config file with out backup
    read_config_file
    
    if test -f "$backup_file_path"; then
        backup_file_content=$(cat "$backup_file_path")
        if [ "$backup_file_content" != "$config_file_content" ]
        then
            # If the backup is available, restore the containments section in the config file from backup
            restore_from_backup
        else
            # Note. You can uncomment this line to avoid spam in your terminal window
            write_log "Containments intact. Doing nothing."
        fi
    else
        # If the backup file/directory is missing, try to create it.
        make_backup
    fi
}

# Let the fun
#     begin
#     :-D

prevent_root

# Get the real resolution when we first run the script
get_real_resolution

# Run check_config to create directory and backup
check_config

# Store the real_resolution in a text file.
# This can then be compared with the current_resolution
echo $real_resolution > $stored_resolution_file_path

stored_resolution=$real_resolution

while true
do
    # Verrify the containments
    verrify_containments
    sleep 2s
done