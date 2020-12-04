function export-nsx-dlr {
Write-Host -foregroundcolor "Green" "Script for _Export ESG & DLR configurations_ started..."
 
#If (-Not (Test-Path -LiteralPath ("DLRs-Config-Export-" + $currentDate ))){ $outputFileFolder = New-Item ("C:\Backups\NSX_DLR\backup_"+$date) -itemtype directory}
 
Write-Host "Collecting information for DLRs"
$allDLRs = Get-NsxLogicalRouter
Write-Host "Found" $allDLRs.count "DLRs"
 
Write-Host "Collecting the rest NSX objects"
$allLSs = Get-NsxLogicalSwitch
$VDSwitches = Get-VDSwitch
$VDPorts = $VDSwitches | Get-VDPortgroup
 
# Collecting information for DLRs
If ($allDLRs.count -gt 0) {
Foreach ($DLR in $allDLRs)
{
$DLRExport = ""
Write-Host "Collecting info for " -NoNewLine
Write-Host -foregroundcolor "Yellow" $DLR.name
$DLRExport += "Name = " + $DLR.name + "`n"
$DLRExport += "Hostname = " + $DLR.fqdn + "`n"
$DLRExport += "Description = " + $DLR.description + "`n"
$DLRExport += "Router ID = " + $DLR.id + "`n"
$DLRExport += "Type = " + $DLR.type
if ($DLR.type -eq "distributedRouter"){$DLRExport += " (Logical Router)"}
$DLRExport += "`n"
$DLRExport += "Enable High Availability = " + $DLR.features.highAvailability.enabled + "`n"
$DLRExport += "CLI credentials (User Name) = " + $DLR.cliSettings.userName + "`n"
$DLRExport += "Enable SSH access = " + $DLR.cliSettings.remoteAccess + "`n"
$DLRExport += "Enable FIPS mode = " + $DLR.enableFips + "`n"
$DLRExport += "Edge Control Level Logging = " + $DLR.vseLogLevel + "`n"
$DLRExport += "Datacenter = " + $DLR.datacenterName + "`n"
$DLRExport += "Appliance Size = " + $DLR.appliances.applianceSize + "`n"
$DLRExport += "`n"
 
$DLRExport += "NSX Edge Appliances: " + "`n"
Foreach($DLRappliance in $DLR.appliances.appliance){
$DLRExport += " Index: " + $DLRappliance.highAvailabilityIndex + "`n"
$DLRExport += " Name: " + $DLRappliance.vmName + "`n"
$DLRExport += " Cluster/Resource Pool: " + $DLRappliance.resourcePoolName + "`n"
$DLRExport += " Datastore: " + $DLRappliance.datastoreName + "`n"
$DLRExport += " Folder: " + $DLRappliance.vmFolderName + "`n"
$DLRExport += " Resource Reservation: "
$DLRExport += " CPU = " + $DLRappliance.cpuReservation.reservation
$DLRExport += ", Memory = " + $DLRappliance.memoryReservation.reservation + "`n"
}
$DLRExport += "Configure interfaces" + "`n"
 
$DLRExport += " HA Interface Configuration`n"
$DLRExport += " Connected To: " + $DLR.mgmtInterface.connectedToName + "`n"
$DLRExport += " Interfaces" + "`n"
Foreach($DLRvnic in $DLR.interfaces.interface){
$DLRExport += " Index: " + $DLRvnic.index
If ($DLRvnic.connectedToId){
$DLRExport += "`n Name: " + $DLRvnic.name + "`n"
$DLRExport += " Type: " + $DLRvnic.type + "`n"
$DLRExport += " Connectivity Status: "
If ($DLRvnic.isConnected -eq "true") {$DLRExport += "Connected`n"}
Else {$DLRExport += "Disonnected`n"}
$DLRExport += " Connected to: "
If (($DLRvnic.connectedToId -like "universalwire-*") -or ($DLRvnic.connectedToId -like "virtualwire-*")) { # Find LogicalSwitch name
$LS = $allLSs | Where-Object {$_.objectId -eq $DLRvnic.connectedToId}
$DLRExport += "Logical Switch -> " + $LS.name + "`n"
}
ElseIf ($DLRvnic.connectedToId -like "dvportgroup-*"){ # Find Distributed Virtual Portgroup name
$VDPort = $VDPorts | Where-Object {$_.Key -eq $DLRvnic.connectedToId}
$DLRExport += "DistributedVirtualPortgroup -> " + $VDPort.name + "`n"
}
Else { $DLRExport += "unknown type -> " + $DLRvnic.connectedToId + "`n" }
$DLRExport += " Primary IP Address: " + $DLRvnic.addressGroups.addressGroup.primaryAddress + "`n"
$DLRExport += " Subnet Prefix Length: " + $DLRvnic.addressGroups.addressGroup.subnetPrefixLength + "`n"
$DLRExport += " MTU: " + $DLRvnic.mtu + "`n"
}
Else { $DLRExport += " (Not configured)`n" } # Nothing configured for this NIC
}
 
$DLRRouting = $DLR | Get-NsxLogicalRouterRouting
If ($DLRRouting.staticRouting.defaultRoute) {
$DLRExport += "Configure default gateway: true`n"
$DLRExport += " Gateway IP: " + $DLRRouting.staticRouting.defaultRoute.gatewayAddress + "`n"
$DLRExport += " Admin distance: " + $DLRRouting.staticRouting.defaultRoute.adminDistance + "`n"
}
Else {$DLRExport += "Configure default gateway: false`n"}
 
### After deployment tasks
$DLRExport += "`nAfter deployment tasks`n`n"
 
# Configuration
$DLRExport += "Configuration`n"
 
# Syslog configuration
$DLRExport += " Syslog`n"
$DLRExport += " Syslog Enabled: " + $DLR.features.syslog.enabled + "`n"
Foreach ($DLRsyslogServer in $DLR.features.syslog.serverAddresses.ipAddress) {
$DLRExport += " Syslog Server: " + $DLRsyslogServer + "`n"
}
$DLRExport += " Protocol: " + $DLR.features.syslog.protocol + "`n"
 
# Configure HA parameters
$DLRDefaultHA = $DLR.features.highAvailability
$DLRExport += " HA Configuration`n"
$DLRExport += " HA Status: " + $DLRDefaultHA.enabled + "`n"
If ($DLRDefaultHA.enabled -eq "true") {
$DLRExport += " Declare Dead Time: " + $DLRDefaultHA.declareDeadTime + "`n"
$DLRExport += " Enable logging: " + $DLRDefaultHA.logging.enable + "`n"
$DLRExport += " Log level: " + $DLRDefaultHA.logging.loglevel + "`n"
}
 
#Configure Firewall default policy
$DLRDefaultFirewall = $DLR.features.firewall
$DLRExport += "Firewall status: " + $DLRDefaultFirewall.enabled + "`n"
If ($DLRDefaultFirewall.enabled -eq "true") {
$DLRExport += " Firewall default action: " + $DLRDefaultFirewall.defaultPolicy.action + "`n"
$DLRExport += " Firewall default logging: " + $DLRDefaultFirewall.defaultPolicy.loggingEnabled + "`n"
}
 
# Global Configuration
$DLRExport += "Global Configuration`n"
$DLRExport += " ECMP: " + $DLRRouting.routingGlobalConfig.ecmp + "`n"
# Default Gateway
If ($DLRRouting.staticRouting.defaultRoute) {
$DLRExport += " Default Gateway`n"
$DLRExport += " Gateway IP: " + $DLRRouting.staticRouting.defaultRoute.gatewayAddress + "`n"
$DLRExport += " Admin distance: " + $DLRRouting.staticRouting.defaultRoute.adminDistance + "`n"
$DLRExport += " Description: " + $DLRRouting.staticRouting.defaultRoute.description + "`n"
}
Else {$DLRExport += " Default Gateway: none`n"}
 
$DLRExport += " Dynamic Routing Configuration`n"
# Dynamic Routing Configuration
$DLRExport += " Router ID: " + $DLRRouting.routingGlobalConfig.routerId + "`n"
 
# Static Routes
If ($DLRRouting.staticRouting.staticRoutes.route) {
$DLRExport += " Static Routes`n"
Foreach ($DLRRoutingStaticRoute in $DLRRouting.staticRouting.staticRoutes.route) {
$DLRExport += " Network: " + $DLRRoutingStaticRoute.network
$DLRExport += ", Next Hop: " + $DLRRoutingStaticRoute.nextHop
If ($DLRRoutingStaticRoute.vnic) {
$DLRstaticRoutevNicName = ($DLR.interfaces.interface | Where-Object {$_.index -eq $DLRRoutingStaticRoute.vnic}).name
}
Else {$DLRstaticRoutevNicName = "none"}
$DLRExport += ", Interface: " + $DLRstaticRoutevNicName
$DLRExport += ", Admin Distance: " + $DLRRoutingStaticRoute.adminDistance
$DLRExport += ", Description: " + $DLRRoutingStaticRoute.description
$DLRExport += "`n"
}
}
Else {$DLRExport += " Static Routes: none`n"}
 
# BGP
If ($DLRRouting.bgp.enabled -eq "true") {
$DLRExport += " BGP Configuration`n"
$DLRExport += " Enable BGP: " + $DLRRouting.bgp.enabled + "`n"
$DLRExport += " Enable Graceful Restart: " + $DLRRouting.bgp.gracefulRestart + "`n"
$DLRExport += " Local AS: " + $DLRRouting.bgp.localASNumber + "`n"
$DLRExport += " BGP Neighbours" + "`n"
Foreach ($DLRRoutingBgpNeighbour in $DLRRouting.bgp.bgpNeighbours.bgpNeighbour) {
$DLRExport += " IP Address: " + $DLRRoutingBgpNeighbour.ipAddress + "`n"
$DLRExport += " Forwarding Address: " + $DLRRoutingBgpNeighbour.forwardingAddress + "`n"
$DLRExport += " Protocol Address: " + $DLRRoutingBgpNeighbour.protocolAddress + "`n"
$DLRExport += " Remote AS: " + $DLRRoutingBgpNeighbour.remoteASNumber + "`n"
$DLRExport += " Weight: " + $DLRRoutingBgpNeighbour.weight + "`n"
$DLRExport += " Keep Alive Time: " + $DLRRoutingBgpNeighbour.keepAliveTimer + "`n"
$DLRExport += " Hold Down Time: " + $DLRRoutingBgpNeighbour.holdDownTimer + "`n"
If ($DLRRoutingBgpNeighbour.password) {
$DLRExport += " Password exists: true`n" }
Else {$DLRExport += " Password exists: false`n"}
# collect BGP Filters
If ($DLRRoutingBgpNeighbour.bgpFilters.bgpFilter) {
$DLRExport += " BGP Filters`n"
Foreach ($DLRRoutingBgpNeighbourbgpFilter in $DLRRoutingBgpNeighbour.bgpFilters.bgpFilter) {
$DLRExport += " Direction: " + $DLRRoutingBgpNeighbourbgpFilter.direction + "`n"
$DLRExport += " Action: " + $DLRRoutingBgpNeighbourbgpFilter.action + "`n"
$DLRExport += " Network: " + $DLRRoutingBgpNeighbourbgpFilter.network + "`n"
$DLRExport += " IP Prefix GE: " + $DLRRoutingBgpNeighbourbgpFilter.ipPrefixGe + "`n"
$DLRExport += " IP Prefix LE: " + $DLRRoutingBgpNeighbourbgpFilter.ipPrefixLe + "`n"
}
}
Else {$DLRExport += " BGP Filters: none`n"}
}
}
Else {$DLRExport += " BGP Configuration: none`n"}
# collect Route Redistribution
$DLRExport += " Route Redistribution OSPF: " + $DLRRouting.ospf.redistribution.enabled + "`n"
If ($DLRRouting.bgp.redistribution.enabled -eq "true") {
$DLRExport += " Route Redistribution BGP: " + $DLRRouting.bgp.redistribution.enabled + "`n"
# collect IP Prefixes
$DLRExport += " IP Prefixes`n"
Foreach ($DLRroutingGlobalConfigIpPrefix in $DLRRouting.routingGlobalConfig.ipPrefixes.ipPrefix) {
$DLRExport += " Name: " + $DLRroutingGlobalConfigIpPrefix.name + "`n"
$DLRExport += " IP/Network: " + $DLRroutingGlobalConfigIpPrefix.ipAddress + "`n"
$DLRExport += " IP Prefix GE: " + $DLRroutingGlobalConfigIpPrefix.ge + "`n"
$DLRExport += " IP Prefix LE: " + $DLRroutingGlobalConfigIpPrefix.le + "`n"
}
}
Else {$DLRExport += " Route Redistribution BGP: none`n"}
# Route Redistribution Table
If ($DLRRouting.bgp.redistribution.rules.rule) {
$DLRExport += " Route Redistribution Table" + "`n"
Foreach ($DLRRoutingBgpRedistributionRule in $DLRRouting.bgp.redistribution.rules.rule) {
$DLRExport += " ID: " + $DLRRoutingBgpRedistributionRule.id + ","
$DLRExport += " Learner: BGP,"
$DLRExport += " From: "
If ($DLRRoutingBgpRedistributionRule.from.ospf -eq "true") {$DLRExport += "OSPF,"}
If ($DLRRoutingBgpRedistributionRule.from.bgp -eq "true") {$DLRExport += "BGP,"}
If ($DLRRoutingBgpRedistributionRule.from.static -eq "true") {$DLRExport += "Static Routes,"}
If ($DLRRoutingBgpRedistributionRule.from.connected -eq "true") {$DLRExport += "Connected,"}
If ($DLRRoutingBgpRedistributionRule.prefixName) {$DLRExport += " Prefix: " + $DLRRoutingBgpRedistributionRule.prefixName + ","}
Else {$DLRExport += " Prefix: Any,"}
$DLRExport += " Action: " + $DLRRoutingBgpRedistributionRule.action
$DLRExport += "`n"
}
}
 
$DLRExport += "`n"
 
$outputFileName = "Config-for-DLR_" + $DLR.name + ".txt"
$DLRExport | Out-File -filePath ("C:\Backups\NSX_DLR\backup_"+$date+ "\" + $FolderName + "\" + $outputFileFolder.Name + "\" + $outputFileName)
}
}
 
#Disconnect-NsxServer -vCenterServer $vCenterServerName
#Disconnect-VIServer -Server $vCenterServerName -Confirm:$False
 
Write-Host -foregroundcolor "Green" "`nScript completed!"
}
 
$date = $((Get-Date).ToString('yyyy-MM-dd'))
 
#If (-Not (Test-Path -LiteralPath ("DLRs-Config-Export-" + $currentDate ))){ $outputFileFolder = New-Item ("C:\Backups\NSX_DLR\backup_"+$date+"\AMS") -itemtype directory}
#If (-Not (Test-Path -LiteralPath ("DLRs-Config-Export-" + $currentDate ))){ $outputFileFolder = New-Item ("C:\Backups\NSX_DLR\backup_"+$date+"\BRU") -itemtype directory}
 
#Connect to the first vCenter
$VIServer1 = "vcenter_FQDN"
$VIUser1 = "administrator@vsphere.local"
$VIPass1 = "*******"
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
Disconnect-VIServer -Server * -Force -Confirm:$false
Disconnect-NsxServer -vCenterServer *
Connect-NsxServer -vCenterServer $VIServer1 -user $VIUser1 -pass $VIPass1
If (-Not (Test-Path -LiteralPath ("DLRs-Config-Export-" + $currentDate ))){ $outputFileFolder = New-Item ("C:\Backups\NSX_DLR\backup_"+$date+"\AMS") -itemtype directory}
#call function
export-nsx-dlr
 
#Connect to the second vCenter
$VIServer2 = "vcenter_FQDN"
$VIUser2 = "administrator@vsphere.local"
$VIPass2 = "*******"
Set-PowerCLIConfiguration -InvalidCertificateAction Ignore -Confirm:$false
Disconnect-VIServer -Server * -Force -Confirm:$false
Disconnect-NsxServer -vCenterServer *
Connect-NsxServer -vCenterServer $VIServer2 -user $VIUser2 -pass $VIPass2
If (-Not (Test-Path -LiteralPath ("DLRs-Config-Export-" + $currentDate ))){ $outputFileFolder = New-Item ("C:\Backups\NSX_DLR\backup_"+$date+"\BRU") -itemtype directory}
#call function
export-nsx-dlr
