#!/usr/bin/bash

# connect the configuration file
source cfg.config

# checking that cfg.config is filled in correctly
if [[ -z $Your_Dirs || -z $Backup_Dir || -z $Log_File || -z $Retain_Rights || -z $Min_Backups || -z $Max_Backups || -z $Max_Size ]]
then
    echo "Error: configuration file is configured incorrectly."
    exit 1
fi

# checking the availability of the directory where backups will be stored
if [[ ! -d "$Backup_Dir" ]]
then
    mkdir "$Backup_Dir"
fi

# creating a compressed archive
time=$(date +%m-%d-%Y-%H-%M-%S)
backup="${time}.tar.gz"

if [ "$Retain_Rights" = true ]
then
    tar -czpf "$Backup_Dir/$backup" $Your_Dirs
else
    tar -czf "$Backup_Dir/$backup" $Your_Dirs
fi

echo "$time: add backup $backup" >> "$Log_File"

# converting the maximum space value (GB/MB) into bits
delimeter=" "
count=${Max_Size%$delimeter*}
type=${Max_Size##*$delimeter}

if [[ $type = 'GB' ]]
then
    bits_Max_Size=$(( $count * 8000000000 ))
elif [[ $type = 'MB' ]]
then
    bits_Max_Size=$(( $count * 8000000  ))
else
    echo "Error: Max_Size incorrectly stated."
fi

# the cycle deletes the oldest backups if the limit of backups or allocated space is exceeded, in cases where there are more backups than the user-specified value "Min_Backups"
while [[ $(ls $Backup_Dir | wc -l) -gt $Max_Backups ]] || [[ $(du -s $Backup_Dir | awk '{ print $1 }' ) -gt $bits_Max_Size ]] 
do
    if [ $(ls $Backup_Dir | wc -l) -gt $Min_Backups ]
    then
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
