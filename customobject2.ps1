<#
Permet de récolter une liste d'événements avec correspondance de nom réel, nom de match et paramètre définissant si le log est peuplé ou non
#>


$logpath =  "C:\Windows\System32\winevt\Logs\"

$Names = Get-ChildItem $logpath | select-object name, Length | where {$_.name -match ".evtx"} | select -ExpandProperty Name

$EvtxList = @()
[System.Collections.ArrayList]$EvtxList

$Names | ForEach-Object{
    $path = "$logpath"+"$Name"
    $Name = $_
    if($Name -match "%4"){$MatchName = $Name -replace "%4", " "}else{$MatchName = $Name}
    if($MatchName -match "Microsoft-Windows-"){$MatchName = $MatchName -replace "Microsoft-Windows-", ""}else{$MatchName = $Name}
    Get-ChildItem -path "$path" |  %{ if($_.Length -gt "69632") {$Populated = "True"}else{$Populated = "False"}}
    $Evtlog = New-Object PSObject
    Add-Member -InputObject $Evtlog -MemberType NoteProperty -Name Name -Value "$Name"
    Add-Member -InputObject $Evtlog -MemberType NoteProperty -Name MatchName -Value "$MatchName"
    Add-Member -InputObject $Evtlog -MemberType NoteProperty -Name IsPopulated -Value "$Populated"
    $EvtxList += $Evtlog
    }

    $EvtxList