<#  
.Synopsis  
   Checks the available space on cluster Shared Volumes and sends an alert if free space is below set threshold.  
.DESCRIPTION  
   Riccardo Toni: 2018/06/27
   Edited by: Mathieu Barbe-gayet (removed webhooks/emails, adapted to RMM) 2019/03/01
   Version 1.1  
   Checks free CSV space
#>

param( 
    [int]$threshold
) 

Import-Module -Name FailoverClusters  

if(-not $threshold){$threshold="10"}
$FaultyCSV = @()
$CSVlist = @() 
         	  
$csvs = Get-ClusterSharedVolume | where-Object {$_.state -match "online"}
foreach ( $csv in $csvs )  
{  
	$csvinfos = $csv | where-Object {$_.state -match "online"} | select-object -Property Name -ExpandProperty SharedVolumeInfo
	foreach ( $csvinfo in $csvinfos )  
	{  
	    $obj = New-Object PSObject -Property @{  
	        Name        = $csv.Name  
	        Path        = $csvinfo.FriendlyVolumeName  
	        Size        = $csvinfo.Partition.Size  
	        FreeSpace   = $csvinfo.Partition.FreeSpace  
	        UsedSpace   = $csvinfo.Partition.UsedSpace  
	        PercentFree = $csvinfo.Partition.PercentFree  
	    }      
	
	    if($obj.PercentFree -lt $threshold){
	        $FaultyCSV += $obj
	    }else{
	        $CSVlist += $obj
	    }
	}
}

$CSVlist = $CSVlist | Select-Object -Property Name,PercentFree
if($FaultyCSV){
	"Error - Free space below $threshold %:"
	        
    $FaultyCSV
	
    if($CSVlist.Count -gt 0){
        "Current status of other CSV"
        $CSVlist
    }
	Exit 1001
}else{
	"Ok - Enough free space"
	$CSVlist 
	Exit 0
}
