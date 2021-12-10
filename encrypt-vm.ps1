#encrypt vms
#input can be csv with vm names or csv with esxi names - use either 'vms' or 'hosts' header in csv to declare that.
#script will loop through the csv file and shutdown vm, encrypt and power on.
#note that it takes significant amount of time to encrypt large disks and downtime should be arranged with app manager prior.
#Contact: Michal Czechowski
#Date: 10.1.2021

[CmdletBinding()]
Param(
  [Parameter(Mandatory=$True)]
   [string]$path_to_csv,
   [Parameter(Mandatory=$True)]
   [string]$vcenter
)


Import-Module -Name .\vmware.vmencryption.psd1


function Wait-VMPowerState {
[CmdletBinding()]
Param(
        # The name of a VM
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        $VMName,
        # The operation (up or down)
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
                   [ValidateSet("Up","Down")]
        $Operation
    )
begin{
    $vm = get-vm -Name $vmname
    }
process{
    switch ($operation) {
        down {
                if ($vm.PowerState -eq "PoweredOn") {
                    Write-Verbose "Shutting Down $vmname"
                    Shutdown-VMGuest $vm -Confirm:$false
                    #Wait for Shutdown to complete
                    do {
                       #Wait 5 seconds
                       Start-Sleep -s 5
                       write-host -ForegroundColor Yellow "Waiting for $vmname to shutdown..."
                       #Check the power status
                       $vm = Get-VM -Name $vmname
                       $status = $vm.PowerState
                    }until($status -eq "PoweredOff")
                } 
                 elseif ($vm.PowerState -eq "PoweredOff") {
                    Write-Verbose "$vmname is powered down"
                }
            }
         up {
                if ($vm.PowerState -eq "PoweredOff") {
                    Write-Verbose "Starting VM $vmname"
                    $vm | Start-VM -Confirm:$false
                    $question = $vm | get-vmquestion -QuestionText "*virtualized AMD-V/RVI*"
	                if ($question) {
			            $vm | get-vmquestion | set-vmquestion -option "Yes" -confirm:$false | start-vm -erroraction silentlycontinue -confirm:$false
			            }
                    #Wait for startup to complete
                    do {
                       #Wait 5 seconds
                       Start-Sleep -s 5
                       write-host -ForegroundColor Yellow "Waiting for $vmname to powerup..."
                       #Check the power status
                       $vm = Get-VM -Name $vmname
                       $status = $vm.PowerState
                    }until($status -eq "PoweredOn")
                }
                 elseif ($vm.PowerState -eq "PoweredOn") {
                    Write-Verbose "$vmname is powered up"
                }
            }
        }
    }
end{
    $vm = Get-VM -Name $vmname 
    $vm 
    }
}


$date = get-date -Format MM/dd/yyyy
$datefile = get-date -format MM.dd.yyyy-HH.mm.ss

disconnect-viserver * -force -confirm:$false -erroraction SilentlyContinue
try{
    connect-viserver $vcenter
    }
catch {
    write-host "Check if '$vcenter' parameter was input correctly."
    }

$EncryptionPolicy = Get-SpbmStoragePolicy -name "VM Encryption Policy"

$inputz = import-csv $path_to_csv

if ($inputz.vms -ne $null) {
    write-host -ForegroundColor Cyan "Found csv file with list of VMs. Processing all vm's in a csv."
    foreach ($v in $inputz.vms) {
            Wait-VMPowerState -VMName $v -Operation Down
            Get-VM $v | Enable-VMEncryption -policy $EncryptionPolicy -KMSClusterId "vault-prod"
            get-vm $v | start-vm -Confirm:$false
            }
    }
elseif ($inputz.hosts -ne $null) {
    write-host -ForegroundColor Cyan "Found csv file with list of ESXi hosts. Processing all vm's running on ESXi hosts in CSV."
    foreach ($h in $inputz.hosts) {
        $vms = get-vmhost $h | get-vm | where name -notlike "*vcls*" | where encrypted -like "*false*"
        foreach ($v in $vms) {
            Wait-VMPowerState -VMName $v -Operation Down
            Get-VM $v | Enable-VMEncryption -policy $EncryptionPolicy -KMSClusterId "vault-prod"
            get-vm $v | start-vm -Confirm:$false
            }
        }
    }
else {
    write-host -ForegroundColor Cyan "Incorrect header in CSV. Use only one of the following headers: 'vms' or 'hosts'"
    }


disconnect-viserver * -force -confirm:$false -erroraction SilentlyContinue
