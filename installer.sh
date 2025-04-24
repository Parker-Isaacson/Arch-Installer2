#!/bin/sh

user=""
pass=""
swap="False"      # Build without swap partition
no_wm="False"        # Build with window manager 
hostname="default"   # Default hostname
region="America"     # Default time zone being America/New_York
city="New_York"
drive=""             # No default drive — must be provided

# Look through the arguements
while [ "$#" -gt 0 ]; do
    case "$1" in
        --help)
            printf "Program used to automate the install process for Arch Linux.\n"
            printf "\t--help\t\tOpens this menu\n"
            printf "\t--no-swap\tDisables the swap partition (default \"True\")\n"
            printf "\t--no-vm\t\tDisables the wm install and configuration (default \"False\")\n"
            printf "\t--hostname\tSets the hostname of the computer (default \"default\")\n"
            printf "\t--region\tSets the time zone region of the computer (default \"America\")\n"
            printf "\t--city\t\tSets the time zone city of the computer (default \"New_York\")\n"
            printf "\t--drive\t\tSets the drive to be partitioned, formed as /dev/sdX\n"
            printf "\t--user\t\tSets the username of the system\n"
            printf "\t--pass\t\tSets the root and user password to the same thing\n"
            exit 0
            ;;
        --swap)
            swap="True"
            ;;
        --no-vm)
            no_wm="True"
            ;;
        --hostname)
            hostname="$2"
            shift
            ;;
        --region)
            region="$2"
            shift
            ;;
        --city)
            city="$2"
            shift
            ;;
        --drive)
            drive="$2"
            shift
            ;;
        --user)
            user="$2"
            shift
            ;;
        --pass)
            pass="$2"
            shift
            ;;
        *)
            echo "Unknown option: $1"
            ;;
    esac
    shift
done

# Check if required values are empty
while [ -z "$user" ]; do
    read -p "Error: --user is required. Please input a user: " user
done

while [ -z "$pass" ]; do
    stty -echo
    read -p "Error: --pass is required. Please input a password: " pass
    stty echo
    echo
done

while [ -z "$drive" ]; do
    read -p "Error: --drive is required. Please input a drive in format \"/dev/sdX\": " drive
done

# Hide the password for printing
pass_hidden=""
i=0
while [ $i -lt ${#pass} ]; do
    pass_hidden="$pass_hidden*"
    i=$((i+1))
done

# Debug print
echo "user=$user"
echo "pass=$pass_hidden"
echo "swap=$swap"
echo "no_wm=$no_wm"
echo "hostname=$hostname"
echo "region=$region"
echo "city=$city"
echo "drive=$drive"

if [ "$swap" = "True" ]; then
    echo "Swapping"
fi