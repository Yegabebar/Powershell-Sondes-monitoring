################################################
# Crée par: Mathieu Barbé-gayet
# Date: 21/12/18

Param(
[switch] $current
)

$yesterday = (get-date (get-date).addDays(-1) -format dd/MM/yyyy)
$currentday = get-date -format dd/MM/yyyy
$regex = '\d{2}/\d{2}/\d{4}\s\d{2}:\d{2}:\d{2};Echec Sauvegarde journali.re;[^;]+'

if(-not($current)){
    #Si on vérifie un backup du même jour que les VSJ
    $date = $yesterday
}else{
    #Si on vérifie un backup du jour précédent
    $date = $currentday
}

$logfile = "C:\ProgramData\Axilog\AxiSoftware\AxiDBSafe\AxiDBSafe_UnifiedLogs.log"
$testpath = Test-Path -PathType leaf $logfile
#Si fichier de logs existe
if($testpath="True"){
    $eventset = Get-Content -path $logfile 2> $null | Where-Object {($_ -match "$date" -or $_ -match "$currentday")}
    #Et si des entrées de log sont trouvées pour la date voulue (Hier ou aujourd'hui)
    if($eventset){
        $failedbackups = $eventset | select-string -pattern $regex | foreach {$_.matches}| select value
        $failedbackups = $failedbackups.value
        #Si pas de backups échoués, OK
        if(-not $failedbackups){
            "Backups OK"
            Exit 0
        #Si backups échoués
        }else{
            "Backups failed:"
            #Affichage liste de backups échoués
            $failedbackups.Replace(";"," ")
            Exit 1001
        }        
    #Sinon si pas d'entrées
    }else{
        "No log entries found"
        Exit 1001
    }
#Si le log n'existe pas, erreur
}else{
    "Log not found"
    Exit 1001
}