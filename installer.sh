#!/bin/sh

user=""
pass=""
swap="False"         # Build without swap partition
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

# Start the install process:
stty -echo

# Starting things for the time and drives
timedatectl
wipefs --all "$drive"

# Partition the drive with swap
if [ "$swap" = "True" ]; then
    echo -e "g\nn\n\n\n+1G\ny\nn\n\n\n+4G\ny\nn\n\n\n\ny\nw\nq" | fdisk "$drive"
    mkfs.fat -F 32 "$drive"1
    mkswap "$drive"2
    mkfs.ext4 -F "$drive"3
    mount "$drive"3 /mnt
    swapon "$drive"2
fi

# Partition the drive without swap
if [ "$swap" = "False" ]; then
    echo -e "g\nn\n\n\n+1G\ny\nn\n\n\n\ny\nw\nq" | fdisk "$drive"
    mkfs.fat -F 32 "$drive"1
    mkfs.ext4 -F "$drive"2
    mount "$drive"2 /mnt
fi

# Create the package list
packages=""

if [ "$no_wm" = "False" ]; then # If we are using a wm
    packages="gcc gdb pipewire pipewire-pulse xorg xorg-xinit i3-gaps alacritty i3status dmenu vim"
fi

if [ "$no_wm" = "True" ]; then # If we are not using a wm
    packages="gcc gdb vim"
fi

# Configure the system
pacstrap /mnt base linux linux-firmware
genfstab -U /mnt >> /mnt/etc/fstab
arch-chroot /mnt /bin/bash << EOF
ln -sf /usr/share/zoneinfo/$region/$city /etc/localtime
hwclock --systohc

echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen
locale-gen
echo "LANG=en_US.UTF-8" > /etc/locale.conf

echo "$hostname" > /etc/hostname
echo -e "127.0.0.1\tlocalhost\n::1\tlocalhost\n127.0.1.1\t$hostname.localdomain\t$hostname" > /etc/hosts

echo -e "$pass\n$pass" | passwd

pacman -Sy
pacman -S --noconfirm grub efibootmgr sudo networkmanager

systemctl enable NetworkManager
systemctl start NetworkManager

mkdir /boot/EFI
mount ${drive}1 /boot/EFI

grub-install --target=x86_64-efi --efi-directory=/boot/EFI --bootloader-id=GRUB
grub-mkconfig -o /boot/grub/grub.cfg

useradd -m -G wheel $user
echo -e "$pass\n$pass" | passwd $user
echo "%wheel ALL=(ALL:ALL) ALL" >> /etc/sudoers

pacman -S --noconfirm $packages
echo "exec i3" > /home/$user/.xinitrc

exit
EOF

umount -R /mnt

stty echo

echo "System Is Setup, please reboot"