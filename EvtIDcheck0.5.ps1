Param(
[switch] $ErrorIfContains,
[switch] $Unlimited,
[string] $LogName,
[string] $ID,
[string] $Source,
[string] $Level,
[string] $Message,
[int] $display
)

<#
- Prise en charge des noms de log evtx courts à ajouter dans la prochaine version
- Ajouter prise en charge noms de niveaux explicites
#>

$limit = (Get-Date) - (New-TimeSpan -Day 1)
if(-not $display){$display = 10}
if(-not $ID){$ID = "*"}
if(-not $Level){$Level = "*"}
if(-not $Source){$Source = "*"}
if(-not $Message){$Message = "*"}

$sysroot = Get-ChildItem Env:\SystemRoot
$sysroot = $sysroot.value
$logpath = "$sysroot\System32\Winevt\Logs\"
#$Eventlogs = Get-ChildItem "$sysroot\System32\Winevt\Logs\" | where {$_.name -match ".evtx"}
$Eventlogs = Get-ChildItem $logpath | select-object name | where {$_.name -match ".evtx"} | select -ExpandProperty Name


$EvtxList = @()
[System.Collections.ArrayList]$EvtxList

$EmptyList = @()
[System.Collections.ArrayList]$EmptyList


foreach($Eventlog in $Eventlogs){
    $EvtFullPath = $logpath+$Eventlog
    $Populated = Get-ChildItem -path $EvtFullPath |  %{ if($_.Length -gt "69632") {$_.Name}}
    if($Populated){
        $EvtxList += $EvtFullPath
    }else{
        $EmptyList += $EvtFullPath
    }
}

#Si un nom de log est fourni
if($logName){
    #Et si un autre paramètre est fourni pour affiner la recherche
    if($ID -or $Level -or $Message -or $Source){
        #Si le log est dans la liste de logs valides
        if($EvtxList -contains $LogName){
            #On récupère les entrées du log
            $events = Get-WinEvent -path $LogName | Where-Object {$_.ID -like $ID -and $_.Level -like $Level -and $_.ProviderName -like "*$Source*" -and $_.Message -like "*$Message*"}
            if(-not $Unlimited){$events = $events | Where-Object {$_.TimeCreated -ge $limit}}

            #On stocke le nombre de résultats
            $evtcount = $events.count

            #Partie affichant une erreur si evt trouvé
            if($ErrorIfContains){
                #Si pas de résultats contenu dans evtcount, Ok
                if ($events -eq $null){
                    "OK: Event not found"
                    Exit 0
                #Sinon si résultats trouvés, erreur => Affichage des résultats
                } else {
                    "ERROR: Event found"
	                $events | Select-Object -first $display | Format-Table
                    if($evtcount -gt $display){"Total: " + $evtcount + " events"}
	                Exit 1001
                }
            #Partie affichant un retour Ok si evt trouvé
            }else{
                #Si résultats trouvés, Ok => Affichage des résultats
                if ($events){
                    "OK: Event found"
                    $events | Select-Object -first $display | Format-Table
                    if($evtcount -gt $display){"Total: " + $evtcount + " events"}
                    Exit 0
                #Sinon si pas de résultats, erreur
                } else {
                    "ERROR: Event not found"
                    Exit 1001
                }
            }
        #Sinon si le log n'est pas dans la liste de logs existants
        }else{
            #On vérifie si le log est présent dans la liste des log vides
            if($EmptyList -contains $LogName){
                "The log is empty"
                Exit 1001
            #Si pas dans la liste, alors le log n'existe pas
            }else{
                "The log doesn't exist"
                Exit 1001
            }
        }
    }else{
        "Please provide at least one more parameter"
        Exit 1001
    }
}else{
    "Missing parameter: LogName"
    Exit 1001
}
