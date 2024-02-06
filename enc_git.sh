#!/bin/bash

# Set default Git user information globally (change as needed)
git config --global user.email "you@example.com"
git config --global user.name "Your Name"

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
echo "7. Git Init"
echo "8. Manage snapshots"
read option

case $option in
    1)
        echo "Encrypting the disk..."
        cryptsetup -y -v luksFormat --type luks2 --cipher aes-xts-plain64 --key-size 512 --hash sha512 --iter-time 10000 --use-random /dev/$disk
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
        
        # Git Init and Git LFS
        git -C $mountpoint init
        git -C $mountpoint lfs install --skip-repo

        # Configure local Git LFS tracking for all files
        git -C $mountpoint lfs track "*"
        git -C $mountpoint lfs track ".*"

        ;;
    5)
        echo "Enter the mount point to unmount (e.g., /mnt/mydisk):"
        read unmountpoint
        
        # Git add, commit, and push
        git -C $unmountpoint add --all
        git -C $unmountpoint commit -m "Automatic commit"
        git -C $unmountpoint push origin master
        
        umount $unmountpoint
        echo "Disk unmounted from $unmountpoint"
        ;;
    6)
        echo "Locking the disk..."
        cryptsetup luksClose /dev/mapper/encrypted_disk
        ;;
    7)
        echo "Enter the mount point for Git Init (e.g., /mnt/mydisk):"
        read git_init_mountpoint

        # Git Init and Git LFS
        git -C $git_init_mountpoint init
        git -C $git_init_mountpoint lfs install --skip-repo

        # Configure local Git LFS tracking for all files
        git -C $git_init_mountpoint lfs track "*"
        git -C $git_init_mountpoint lfs track ".*"

        echo "Git repository and Git LFS initialized at $git_init_mountpoint"
        ;;
    8)
        echo "Choose an option:"
        echo "1. List snapshots"
        echo "2. Revert to a snapshot"
        echo "3. Delete a snapshot"
        read snapshot_option
        case $snapshot_option in
            1)
                echo "Listing snapshots..."
                git -C $mountpoint log --oneline --pretty=format:"%h - %s, %cr, size: %f" --stat
                ;;
            2)
                echo "Listing snapshots..."
                git -C $mountpoint log --oneline --pretty=format:"%h - %s, %cr, size: %f" --stat
                echo "Enter the commit hash to revert to:"
                read commit_hash
                git -C $mountpoint checkout $commit_hash
                echo "Reverted to snapshot $commit_hash"
                ;;
            3)
                echo "Listing snapshots..."
                git -C $mountpoint log --oneline --pretty=format:"%h - %s, %cr, size: %f" --stat
                echo "Enter the commit hash to delete:"
                read commit_hash
                git -C $mountpoint branch -D $commit_hash
                echo "Deleted snapshot $commit_hash"
                ;;
            *)
                echo "Invalid option."
                ;;
        esac
        ;;
    *)
        echo "Invalid option."
        ;;
esac
