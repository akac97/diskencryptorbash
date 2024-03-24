#!/bin/bash

# List all disk names
echo "Available disks:"
lsblk -dpno NAME

# Select a disk
echo "Enter the disk name (e.g., sda, sdb):"
read disk

# Choose an operation
echo "Choose an option:"
echo "1. Encrypt disk"
echo "2. Decrypt disk"
echo "3. Format disk"
echo "4. Mount disk"
echo "5. Unmount disk"
echo "6. Lock disk"
read option

case $option in
    1)
        echo "Encrypting the disk..."
        cryptsetup -y -v luksFormat --type luks2 --cipher serpent-xts-plain64 --key-size 512 --hash sha512 --iter-time 10000 --use-random --pbkdf argon2id --pbkdf-memory 4194304 /dev/$disk

        ;;
    2)
        echo "Decrypting the disk..."
        cryptsetup luksOpen /dev/$disk encrypted_disk
        ;;
    3)
        echo "Choose a filesystem:"
        echo "1. f2fs"
        echo "2. ext4"
        read fs
        case $fs in
            1)
                echo "Formatting the disk with f2fs..."
                mkfs.f2fs -f /dev/mapper/encrypted_disk
                ;;
            2)
                echo "Formatting the disk with ext4..."
                mkfs.ext4 /dev/mapper/encrypted_disk
                ;;
            *)
                echo "Invalid option."
                ;;
        esac
        ;;
    4)
        echo "Enter the mount point (e.g., /mnt/mydisk):"
        read mountpoint
        mount /dev/mapper/encrypted_disk $mountpoint
        echo "Disk mounted at $mountpoint"
        echo "Choose an option:"
        echo "1. Give access to a normal user"
        echo "2. Keep access restricted to root"
        read access_option
        case $access_option in
            1)
                echo "Enter the username to give access to mountpoint:"
                read username
                chown $username:$username $mountpoint
                echo "Access given to $username"
                ;;
            2)
                echo "Access is kept restricted to root"
                ;;
            *)
                echo "Invalid option."
                ;;
        esac
        ;;
    5)
        echo "Enter the mount point to unmount (e.g., /mnt/mydisk):"
        read unmountpoint
        umount $unmountpoint
        echo "Disk unmounted from $unmountpoint"
        ;;
    6)
        echo "Locking the disk..."
        cryptsetup luksClose /dev/mapper/encrypted_disk
        ;;
    *)
        echo "Invalid option."
        ;;
esac
