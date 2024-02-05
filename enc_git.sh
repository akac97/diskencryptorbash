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
        # Add all files to Git
        git -C $unmountpoint add .
        # If there are large files, add them to Git LFS
        find $unmountpoint -type f -size +10M -exec git -C $unmountpoint lfs track {} \;
        echo "All files added to Git or Git LFS"
        # Get the current commit number
        commit_number=$(git -C $unmountpoint rev-list --count HEAD)
        # Increment the commit number
        let "commit_number++"
        # Commit changes
        git -C $unmountpoint commit -m "Commit $commit_number"
        echo "Changes committed to Git as Commit $commit_number"
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
        # Initialize a new Git repository
        git init $git_init_mountpoint
        # Initialize Git LFS
        git -C $git_init_mountpoint lfs install
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
                git -C /mnt/mydisk log --oneline --pretty=format:"%h - %s, %cr, size: %f" --stat
                ;;
            2)
                echo "Listing snapshots..."
                git -C /mnt/mydisk log --oneline --pretty=format:"%h - %s, %cr, size: %f" --stat
                echo "Enter the commit hash to revert to:"
                read commit_hash
                git -C /mnt/mydisk checkout $commit_hash
                echo "Reverted to snapshot $commit_hash"
                ;;
            3)
                echo "Listing snapshots..."
                git -C /mnt/mydisk log --oneline --pretty=format:"%h - %s, %cr, size: %f" --stat
                echo "Enter the commit hash to delete:"
                read commit_hash
                git -C /mnt/mydisk branch -D $commit_hash
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
