# A script to export all DLR configuration for multiple vCenters

description: This script exports all the DLR configurations and place the backup on a local location

Backup location: C:\Backups\NSX_DLR\backup_date

Script location: C:\Script\Export_NSX_DLR_configuration.ps1

Windows Task:
name: dlr-backup
action: powershell -ExecutionPolicy Unrestricted -File C:\Script\Export_NSX_DLR_configuration.ps1
frequency: each Saturday on 21:15
