#!/usr/bin/bash

# connect the configuration file
source cfg.config

# checking: whether the user has specified the directory(-ies) for which a backup should be made.
if [[ -n $Your_Dirs ]]; then
    if [[ $Your_Dirs == *" "* ]]; then
        Your_Dirs=($(echo $Your_Dirs | tr " " "\n"))
    else
        Your_Dirs=($Your_Dirs)
    fi
else
    echo "Error:"
    echo "Specify the directory(-ies) you want to backup in the configuration file!"
fi

# checking the availability and accessibility of the directory in which the backups will be stored.
if [[ -n $Backup_Dir ]]; then
    if [[ ! -d "$Backup_Dir" ]]; then
        mkdir -p "$Backup_Dir"
        if [[ $? -eq 1 ]]; then
            echo "An error occurred while creating the backup directory."
            echo "Check the correctness of the path, permissions to create and the amount of remaining memory, or specify a different directory"
            exit 1
        fi
    fi
else
    echo "Error:"
    echo "Specify the directory where you want to backup in the configuration file!"
    exit 1
fi

# checking whether the user has specified a log file
if [[ -z $Log_File ]]; then
    touch log.txt
    echo "Logs are stored in a file ${pwd}/log.txt"
fi

# If it is not specified whether to save rights, it automatically sets the value to true.
if [[ $Retain_Rights != true ]] && [[ $Retain_Rights != false ]]; then
    Retain_Rights=true
fi

# Sets the default value if not specified by the user
if [[ -z $Min_Backups  ]]; then
    Min_Backups=2
fi

# Sets the default value if not specified by the user
if [[ -z $Max_Backups  ]]; then
    Max_Backups=5
fi

# Sets the default value if not specified by the user
if [[ -z $Max_Size  ]]; then
    Max_Size="5 GB"
fi

# creating a compressed archive
count=1

for dir in ${Your_Dirs[@]}; do

    if [[ ! -d $dir ]]; then
        echo "$dir does not exist therefore it is impossible to create a backup of this directory."
        continue
    fi

    time=$(date +%m-%d-%Y-%H-%M-%S)
    backup="${time}_$count.tar.gz"

    if [ "$Retain_Rights" = true ]; then
        tar -czpf "$Backup_Dir/$backup" $dir
    else
        tar -czf "$Backup_Dir/$backup" $dir
    fi

    if [[ $? -eq 1 ]]; then
        echo "Error:"
        echo "Check the permissions to create and the amount of remaining memory."
    else
        echo "$time: add backup $backup" >> "$Log_File"
    fi

    count=$(( $count + 1 ))
done

# converting the maximum space value (GB/MB) into bits
delimeter=" "
count=${Max_Size%$delimeter*}
type=${Max_Size##*$delimeter}

if [[ $type = 'GB' ]]; then
    bits_Max_Size=$(( $count * 8000000000 ))
elif [[ $type = 'MB' ]]; then
    bits_Max_Size=$(( $count * 8000000  ))
else
    echo "Error: Max_Size incorrectly stated."
fi

# the cycle deletes the oldest backups if the limit of backups or allocated space is exceeded, in cases where there are more backups than the user-specified value "Min_Backups"
while [[ $(ls $Backup_Dir | wc -l) -gt $Max_Backups ]] || [[ $(du -s $Backup_Dir | awk '{ print $1 }' ) -gt $bits_Max_Size ]]; do
    if [ $(ls $Backup_Dir | wc -l) -gt $Min_Backups ]; then
        outdated=$(ls -t "$Backup_Dir" | tail -n1)
        rm "$Backup_Dir/$outdated"

        time=$(date +%m-%d-%Y-%H-%M-%S)
        echo "$time: removed backup $outdated" >> "$Log_File"
    else
        echo "Backups were not deleted because their number is equal to the minimum number that you specified"
        break
    fi
done

exit 0
