Param(
[long] $jobscount,
[switch] $current,
[switch] $more
)

$yesterday = (get-date (get-date).addDays(-1) -format yyyy-MM-dd)
$currentday = get-date -format yyyy-MM-dd

if(-not($jobscount)){$jobscount = "1"}

if(-not($current)){
    #si on vérifie un backup du même jour que les VSJ
    $date = $yesterday
}else{
    #si on vérifie un backup du jour précédent
    $date = $currentday
}


$file = "log $date.txt"
$filePath = "C:\Program Files (x86)\Cobian Backup 11\Logs\" + $file 
$testpath = Test-Path -PathType leaf $filePath
#Si fichier de logs existe
if($testpath="True"){
    $string = Get-Content -path $filePath 2> $null | Where-Object {$_ -match "Sauvegarde \** fait"}
    #$jobsfound = $string | Measure-Object -Line
    $jobsfound = $string.count
    if($jobscount -gt $jobsfound){
        #Si nombre de jobs attendu plus grand que nombre jobs trouvés, erreur
        "Pas assez de travaux trouvés: $jobsfound/$jobscount"
        Exit 1001
    }else{
        #Sinon, si assez de jobs trouvés
        #Si résultat de backup trouvé
        if($string){
            #On récupère les éventuelles erreurs VSS dans variable vssERR
            $vssERR = Get-Content -path $filePath | Where-Object {$_ -match "ERR" -and $_ -match "Volume Shadow Copy"}
            #si erreurs ne causent pas de fail
            $result = Get-content $filePath | where {$_ -match "Sauvegarde faite."}
            #Et si des erreurs ne sont pas trouvées, on affiche Backup Ok avec erreurs si option activée
            if(-not ($vssERR)){
                #RECUPERER NOMBRE ERREURS RESULTAT BACKUP
                #INSERER IF NOMBRE ERREURS              
                "Backup OK"
                ""
                "============================"
                ""
                $result
                if($more){
                    Get-content $filePath | where {$_ -match "ERR"}
                }
                Exit 0
            }else{
                #Si par contre des erreurs VSS sont trouvées, le Backup échoue avec statut warning
                "WARNING - Erreur Volume Shadow Copy"
                ""
                "Certains fichiers ont pu ne pas être sauvegardés"
                "============================"
                ""
                $vssERR
                Exit 1001
            }              

        }else{
                #sinon, erreur
                "Backup NOK - Results not found"
                Exit 1001
        }
    }
}else{
    #Si le log n'existe pas, erreur
    "Log not found"
    Exit 1001
}

