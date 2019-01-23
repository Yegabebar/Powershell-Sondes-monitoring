param(
[float] $quota,
[Parameter(Mandatory=$true)][string] $sender,
[Parameter(Mandatory=$true)][string] $recipient
)
#Renseigner mot de passe entre les guillemets
$passwd = ConvertTo-SecureString "Suckmyd!c4" -AsPlainText -Force
#Renseigner utilisateur entre les guillemets
$mycreds = New-Object System.Management.Automation.PSCredential ("m.barbe@watsoft.net", $passwd)

if(-not ($quota)){"Quota non spécifié"}else{
    $psi = New-object System.Diagnostics.ProcessStartInfo 
    $psi.CreateNoWindow = $true 
    $psi.UseShellExecute = $false 
    $psi.RedirectStandardOutput = $true 
    $psi.RedirectStandardError = $true 
    $psi.FileName = 'c:\Program Files\Backup Manager\ClientTool.exe' 
    $psi.Arguments = @("control.session.list","-no-header") 
    $process = New-Object System.Diagnostics.Process 
    $process.StartInfo = $psi 
    [void]$process.Start()
    $output = $process.StandardOutput.ReadToEnd() 
    $process.WaitForExit() 

    [System.Collections.ArrayList]$selectedsize

    $output | Out-File C:\Windows\Temp\out-temp.txt
    $sources = "Exchange", "FileSystem", "NetworkShares", "Oracle", "SystemState", "VMware", "VssHyperV", "VssMsSql", "VssSharePoint"


    Foreach($source in $sources){
        $find = get-content C:\Windows\Temp\out-temp.txt |  ? { $_ -match "$source" -and "Backup Completed" } | select-object -First 1
        if($find){
            $value = $find.substring(89,4)
            $unit = $find.substring(93,1)
            $value = [float]$value

            if($unit -eq "T"){$value = $value*1024}
                else{if($value -eq "B"){$value = $value/1024/1024/1024}
                    else{if($value -eq "K"){$value = $value/1024/1024}
                        else{if($value -eq "M"){$value = $value/1024}                        }
                        $selectedsize += $value
                    }
                }
        }
    }
    if($selectedsize -gt $quota){
        

        $FullFolderPath = Get-ChildItem 'C:\ProgramData\MXB\Backup Manager\storage\' -Directory | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        $FolderName = (Split-Path $FullFolderPath -Leaf).ToString();
        $UnderscoreIndex = $FolderName.IndexOf('_');
        $unitname = $FolderName.SubString(0,$UnderscoreIndex)

        $exceeds = $selectedsize-$quota
        $quota = [math]::Round($quota,2)
        $selectedsize = [math]::Round($selectedsize,2)
        $exceeds = [math]::Round($exceeds,2)

        $From = "$sender"
        $To = "$recipient"
        $encoding=[System.Text.Encoding]::UTF8

        #Variables à modifier pour personnalisation du mail
        $Subject = "Quota dépassé"
        $Body = "La taille sélectionnée de l'unité $unitname dépasse $quota Go, taille sélectionnée actuellement: $selectedsize Go pour un excédent de $exceeds Go"
        $SMTPServer = "mail.watsoft.net"
        $SMTPPort = "25"
        
        Send-MailMessage -From $From -to $To -Subject $Subject -Body $Body -SmtpServer $SMTPServer -port $SMTPPort -Credential ($mycreds) -Encoding $encoding
    }

}