#####################################################################################################
#                           Example of use of the EKARA API                                         #
#####################################################################################################
# Swagger interface : https://api.ekara.ip-label.net/                                               #
# To be personalized in the code before use:                                                        #
#     username / password / client  / RefreshPage / IntervalInventory /  HTMLFile                   #
# Purpose of the script : Dynamic Inventory of scenarios.                                           #
#####################################################################################################
# Author : Guy Sacilotto
# Last Update : 26/12/2023
# Version : 7.1


<#
Authentication :  user / password
Method call : 
    auth/login
    results-api/scenarios/status?clientId={$client}"

Grouping : by scenarios
Restitution : HTML Page with images / Dynamic refresh
#>

Clear-Host

#region VARIABLES
#========================== SETTING THE VARIABLES ===============================
$error.clear() 
[String]$global:Version = "7.1"
$global:API = "https://api.ekara.ip-label.net"                                                # Webservice URL
$global:UserName = ""                                                                         # EKARA Account
$global:PlainPassword = ""                                                                    # EKARA Password
$global:RefreshPage = 65                                                                      # Fréquence de rafraichissement de la page Web en seconde
$global:IntervalInventory = 60                                                                # Fréquence de l'inventaire en seconde
$Global:client = ""


$global:DefaultDebut = ((Get-Date).adddays(-1)).tostring("yyyy-MM-dd") + " 00:00:00"          # Set the start date
$global:DefaultFin = (Get-Date).tostring("yyyy-MM-dd") + " 00:00:00"                          # Set the End Date
$global:CurrentDate = (Get-Date).tostring("yyyy-MM-dd HH:mm:ss")


# Recherche le chemin du script
if ($psISE) {
    [String]$global:Path = Split-Path -Parent $psISE.CurrentFile.FullPath
    Write-Host "Path ISE = $Path"
} else {
    #[String]$global:Path = split-path -parent $MyInvocation.MyCommand.Path
    [String]$global:Path = (Get-Item -Path ".\").FullName
    Write-Host "Path Direct = $Path"
}

[String]$global:HTMLFile = "CONSOLE_EKARA.html"                                               # Nom du fichier HTML généré 
[String]$global:HTMLFullPath = $Path+"\"+$HTMLFile 
[String]$global:HTMLicon= $Path+"\images\Ekara.ico"                                           # Fichier icon
[String]$global:HTMLLogo= $Path+"\images\Ekara.ico"                                           # Fichier Logo
[String]$global:cssFile= $Path+"\css\morning.css"                                             # Fichier CSS
[String]$global:jsFileMorning= $Path+"\js\morning.js"                                         # Fichier JS
[String]$global:jsFileSortable= $Path+"\js\sorttable.js"                                      # Fichier JS
[String]$global:imageFile= $Path+"\images"                                                    # Fichier tendance
[String]$global:audioFile= $Path+"\audio"                                                     # Fichier audio
[String]$global:periode = "[$CurrentDate]"                                                    # Titre du rapport

$global:headers = $null
$global:headers = New-Object "System.Collections.Generic.Dictionary[[String],[String]]"       # Create Header
$headers.Add("Accept","application/json")                                                     # Setting Header
$headers.Add("Content-Type","application/json")                                               # Setting Header

#endregion


#region Functions
function Authentication{
    try{
        # Without asking for an account and password
        if(($UserName -ne $null -and $PlainPassword -ne $null) -and ($UserName -ne '' -and $PlainPassword -ne '')){
            Write-Host "--- Automatic AUTHENTICATION (account) ---------------------------" -BackgroundColor Green
            $uri = "$API/auth/login"                                                                                               # Webservice Methode
            $response = Invoke-RestMethod -Uri $uri -Method POST -Body @{ email = "$UserName"; password = "$PlainPassword"}        # Call WebService method
            $global:Token = $response.token                                                                                        # Register the TOKEN
            $global:headers.Add("authorization","Bearer $Token")                                                                   # Adding the TOKEN into header
        }Else{
            Write-Host "--- Account and Password not set ! ---------------------------" -BackgroundColor Red
            Write-Host "--- To use this connection mode, you must configure the account and password in this script." -ForegroundColor Red
            exit
        }
    }Catch{
        Write-Host "-------------------------------------------------------------" -ForegroundColor red 
        Write-Host "Erreur ...." -BackgroundColor Red
        Write-Host $Error.exception.Message[0]
        Write-Host $Error[0]
        Write-host $error[0].ScriptStackTrace
        Write-Host "-------------------------------------------------------------" -ForegroundColor red
        Break 
    }
}


function Inventory{
    #========================== results/overview =============================
    # Call WS : results-api/scenarios/status
    try{
        $uri ="$API/results-api/scenarios/status?clientId=$client"                                    # Webservice Methode
        $status = Invoke-RestMethod -Uri $uri -Method POST -Headers $headers                           # Call WebService method
        Write-Host "scenarios/status" -BackgroundColor Red                                            # Display information
        $Global:CurrentDate = (Get-Date).tostring("yyyy-MM-dd HH:mm:ss")
        $nbscenario = 0
        $unknown = 0          
        $Success = 0
        $Failure = 0
		$Aborted = 0
        $Noexecution = 0				        
        $Maintenance = 0 
		$Stopped = 0
		$Excluded = 0
		$Degraded = 0
        
		
        $Scenario_list_Failure = ""
        $Scenario_list_unknown = ""
		
		$status = $status | Sort-Object -Property @{Expression = "currentStatus"; Descending = $true}, @{Expression = "startTime"; Descending = $true}
        
        $global:htmlPart2 = "
        
                    <div>
                        <center>
                                    <table class=""sortable"">
                                        <thead>
											<tr>
												<th>Status</th>
												<th>Nom</th>
												<th>Depuis</th>
											</tr>
										</thead>
                                        <tbody>"

        
        
        Foreach ($scenario in $status)
        {
            Write-Host "Monitor Name : "$scenario.scenarioName -BackgroundColor Green 				       # Display information
            Write-Host "Monitor currentStatus : "$scenario.currentStatus                                   # Display information 

            $Global:ScenarioDate = (Get-Date $scenario.startTime -Format "yyyy-MM-dd HH:mm:ss")
            $Difdate=NEW-TIMESPAN –Start $CurrentDate –End $ScenarioDate                                   # Calcul interval entre les 2 dates                    
            $timeElapsed=$Difdate.ToString("dd' jour(s) 'hh' heure(s) 'mm' minute(s) 'ss' seconde(s)'")    # Formate la date
            Write-Host ($timeElapsed)
            $nbscenario=$nbscenario+1                                                                      # Compte le nombre de scénario

            switch ($scenario.currentStatus){
                
                # 0=Unknown / 1=Success / 2=Failure / 3=Aborted / 4=Maintenance / 5=No execution / 6=Stopped / 7=Excluded / 8=Degraded
                0 {$unknown=$unknown+1; 
                    $icon="$imageFile\help.ico";
                    $Formattrend = "<span style='font-family: Calibri; text-align: center!important; display: block; color: rgba(0, 0, 0, 0.0); font-size:15px;'>"+$scenario.currentStatus+"<img src=$icon width=40 height=40 title=Unknown></></span>"
                    }
                1 {$Success=$Success+1; 
                    $icon="$imageFile\green_button.ico";
                    $Formattrend = "<span style='font-family: Calibri; text-align: center!important; display: block; color: rgba(0, 0, 0, 0.0); font-size:15px;'>"+$scenario.currentStatus+"<img src=$icon width=40 height=40 title=Success></></span>"
                    }
                2 {$Failure=$Failure+1; 
                    $icon="$imageFile\red_button.ico";
                    $Formattrend = "<span style='font-family: Calibri; text-align: center!important; display: block; color: rgba(0, 0, 0, 0.0); font-size:15px;'>"+$scenario.currentStatus+"<img src=$icon width=40 height=40 title=Failure></></span>"
                    }
                3 {$Aborted=$Aborted+1;
					$icon="$imageFile\delete.ico"; 
                    $Formattrend = "<span style='font-family: Calibri; text-align: center!important; display: block; color: rgba(0, 0, 0, 0.0); font-size:15px;'>"+$scenario.currentStatus+"<img src=$icon width=40 height=40 title=Aborted></></span>"
                    }
                4 {$Maintenance=$Maintenance+1; 
                    $icon="$imageFile\pause.ico";
                    $Formattrend = "<span style='font-family: Calibri; text-align: center!important; display: block; color: rgba(0, 0, 0, 0.0); font-size:15px;'>"+$scenario.currentStatus+"<img src=$icon width=40 height=40 title=Maintenance></></span>"
                    }
                5 {$Noexecution=$Noexecution+1
                    $icon="$imageFile\blue_button.ico"; 
                    $Formattrend = "<span style='font-family: Calibri; text-align: center!important; display: block; color: rgba(0, 0, 0, 0.0); font-size:15px;'>"+$scenario.currentStatus+"<img src=$icon width=40 height=40 title=""No execution""></></span>"
                    }
                6 {$Stopped=$Stopped+1; 
                    $icon="$imageFile\stop.ico";
                    $Formattrend = "<span style='font-family: Calibri; text-align: center!important; display: block; color: rgba(0, 0, 0, 0.0); font-size:15px;'>"+$scenario.currentStatus+"<img src=$icon width=40 height=40 title=Stopped></></span>"
                    }
                7 {$Excluded=$Excluded+1; 
                    $icon="$imageFile\process.ico";
                    $Formattrend = "<span style='font-family: Calibri; text-align: center!important; display: block; color: rgba(0, 0, 0, 0.0); font-size:15px;'>"+$scenario.currentStatus+"<img src=$icon width=40 height=40 title=Excluded></></span>"
                    }
                8 {$Degraded=$Degraded+1; 
                    $icon="$imageFile\warning.ico";
                    $Formattrend = "<span style='font-family: Calibri; text-align: center!important; display: block; color: rgba(0, 0, 0, 0.0); font-size:15px;'>"+$scenario.currentStatus+"<img src=$icon width=40 height=40 title=Degraded></></span>"
                    }
                default{$icon="$imageFile\info.ico";
                    $Formattrend = "<span style='font-family: Calibri; text-align: center!important; display: block; color: rgba(0, 0, 0, 0.0); font-size:15px;'>"+$scenario.currentStatus+"<img src=$icon width=40 height=40 title=???></></span>"
                    }
            }
                        
            # Generation du contenu de la page WEB
            $global:htmlPart2 += "
                            <tr>
                                <td align=right>"+$Formattrend+"</td>
                                <td title="+$scenario.scenarioId+">"+$scenario.scenarioName+"</td>
                                <td align=center title="""+[string]$ScenarioDate +""">"+$timeElapsed+"</td>
                            </tr>"

        }
        
        # Affiche un message en cas d'erreur
        if($Failure -gt 0){
            jouerAlarme
            info "Error" "$Failure Scénario(s) en erreur !" "Erreur"
            Write-Host "$Failure Scénario(s) en erreur !" -ForegroundColor Red
        }
        
        if($unknown -gt 0){
            info "Warning" "$unknown Scénario(s) en etat unknown !" "Inconnu"
            Write-Host "$unknown Scénario(s) en etat unknown !" -ForegroundColor Yellow
        }

        $global:htmlPart2 += "
                                                     
                                            </tbody>
                                        <tfoot></tfoot>
                                    </table>
                        </center>
                    </div>"


        [String]$global:htmlPart1 = @"
                    <div>
                        <center>
                                            <table >
                                                <tr>
                                                    <td>
                                                        <table>
                                                            <thead>
                                                                <tr><th>   Total   </th></tr>
                                                            </thead>
                                                            <tbody>
                                                                <tr><td style="text-align:center"><b>$nbscenario</b></td></tr>
                                                            </tbody>
                                                        </table>
                                                    </td>
                                                    <td> 
                                                        <table >
                                                            <thead>
                                                                <tr><th>  Succes  </th></tr>
                                                            </thead>
                                                            <tbody>
                                                                <tr><td style="text-align:center; color:green;"><b>$Success</b></td></tr>
                                                            </tbody>
                                                        </table>
                                                    </td>
                                                    <td> 
                                                        <table>
                                                            <thead>
                                                                <tr><th>  Echec  </th></tr>
                                                            </thead>
                                                            <tbody>
                                                                <tr><td style="text-align:center; color:red;"><b>$Failure</b></td></tr>
                                                            </tbody>
                                                        </table>
                                                    </td>
                                                    <td> 
                                                        <table>
                                                            <thead>
                                                                <tr><th>Maintenance</th></tr>
                                                            </thead>
                                                            <tbody>
                                                                <tr><td style="text-align:center; color:blue;"><b>$Maintenance</b></td></tr>
                                                            </tbody>
                                                        </table>
                                                    </td>
                                                    <td> 
                                                        <table>
                                                            <thead>
                                                                <tr><th>Dégradé</th></tr>
                                                            </thead>
                                                            <tbody>
                                                                <tr><td style="text-align:center;"><b>$Degraded</b></td></tr>
                                                            </tbody>
                                                        </table>
                                                    </td>
                                                    <td> 
                                                        <table>
                                                            <thead>
                                                                <tr><th>Interrompu</th></tr>
                                                            </thead>
                                                            <tbody>
                                                                <tr><td style="text-align:center;"><b>$Aborted</b></td></tr>
                                                            </tbody>
                                                        </table>
                                                    </td>
                                                    <td> 
                                                        <table>
                                                            <thead>
                                                                <tr><th>Non Exécuté</th></tr>
                                                            </thead>
                                                            <tbody>
                                                                <tr><td style="text-align:center;"><b>$Noexecution</b></td></tr>
                                                            </tbody>
                                                        </table>
                                                    </td>
                                                    <td> 
                                                        <table>
                                                            <thead>
                                                                <tr><th> Arrêté </th></tr>
                                                            </thead>
                                                            <tbody>
                                                                <tr><td style="text-align:center;"><b>$Stopped</b></td></tr>
                                                            </tbody>
                                                        </table>
                                                    </td>
                                                    <td> 
                                                        <table>
                                                            <thead>
                                                                <tr><th> Exclus </th></tr>
                                                            </thead>
                                                            <tbody>
                                                                <tr><td style="text-align:center;"><b>$Excluded</b></td></tr>
                                                            </tbody>
                                                        </table>
                                                    </td>
                                                    <td> 
                                                        <table>
                                                            <thead>
                                                                <tr><th>Inconnu</th></tr>
                                                            </thead>
                                                            <tbody>
                                                                <tr><td style="text-align:center;"><b>$unknown</b></td></tr>
                                                            </tbody>
                                                        </table>
                                                    </td>
                                                </tr>
                                            </table>
                        </center>
                    </div>
"@

        Write-Host "Dernière execution de l'inventaire ----->[ $CurrentDate ]<-----"
        create_TOP_HTML                                                                # Mise à jour de la page HTML
        create_BOTTOM_HTML
    }
    catch{
        Write-Host "-------------------------------------------------------------" -ForegroundColor red
        Write-Host "Erreur ...." -BackgroundColor Red
        Write-Host $Error.exception.Message[0]
        Write-Host $Error[0]
        Write-host $error[0].ScriptStackTrace
        Write-Host "-------------------------------------------------------------" -ForegroundColor red
    }                                                                      
}


function Create_HTML(){
    # Create WEB page
    Write-Host "Create WEB page" -ForegroundColor blue
    New-Item $HTMLFullPath -Type file -force
    Add-Content -Path $HTMLFullPath -Value $top
    Add-Content -Path $HTMLFullPath -Value $htmlPart1
    Add-Content -Path $HTMLFullPath -Value $htmlPart2
    Add-Content -Path $HTMLFullPath -Value $bottom
}


Function info($TipIcon, $title, $message){
    If (-NOT $global:objNotifyIcon) {		
        [void] [System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
        Write-Host "Charge System.Windows.Forms"
    }
    $global:objNotifyIcon = New-Object System.Windows.Forms.NotifyIcon 		
    $objNotifyIcon.Icon = $HTMLLogo		                                                                # icon affiché dans la barre des tâches(sur la base d'un exe)
    $objNotifyIcon.BalloonTipIcon = [System.Windows.Forms.ToolTipIcon]::$TipIcon 						# icon dans l'info bulle
    $objNotifyIcon.BalloonTipText = $message 															# Message de l'info bulle
    $objNotifyIcon.BalloonTipTitle = $title														        # titre de l'info bulle
    $objNotifyIcon.Visible = $True                                                                      # rend visible l'info bulle
    $objNotifyIcon.ShowBalloonTip(1000)																    # temp d'affichage de l'info bulle
    $objNotifyIcon.Dispose()                                                                            # Efface le message	
}


function jouerAlarme { 
	Add-Type -AssemblyName presentationCore
	$mediaPlayer = New-Object system.windows.media.mediaplayer
	$mediaPlayer.open("$audioFile\IOS-Notification.mp3")
	$mediaPlayer.Play()
}


function Hide-Console{
    # .Net methods Permet de réduire la console PS dans la barre des tâches
    Add-Type -Name Window -Namespace Console -MemberDefinition '
    [DllImport("Kernel32.dll")]
    public static extern IntPtr GetConsoleWindow();

    [DllImport("user32.dll")]
    public static extern bool ShowWindow(IntPtr hWnd, Int32 nCmdShow);
    '
    $consolePtr = [Console.Window]::GetConsoleWindow()
    #0 hide / 1 normal / 2 réduit 
    [Console.Window]::ShowWindow($consolePtr, 2)
}


Function create_TOP_HTML{
    $LastUpdateInventory = (Get-Date).tostring("dd/MM/yyyy HH:mm:ss")                          # Pour afficher la mise à jour de la date d'execution du script
    # Content HTML top
        [String]$global:top = @"
        <!DOCTYPE html PUBLIC '-//W3C//DTD XHTML 1.0 Transitional//EN' 'http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd'>
        <html xmlns='http://www.w3.org/1999/xhtml'>
        <head>
            <title>- CONSOLE EKARA -</title>
            <meta http-equiv='Content-type' content='text/html'>
            <meta http-equiv='refresh' content="$RefreshPage"/>
            <link rel="shortcut icon" href="$HTMLicon">
            <link rel="stylesheet" href="$cssFile">
            <script src="$jsFileMorning"></script>
            <script src="$jsFileSortable"></script>
            <script language="JavaScript">
                function display_ct() {
                    var x = new Date()
                    var txt = "Last page refresh : "
                    var x1=x.toUTCString();// changing the display to UTC string
                    var x2=x.getDate() + "/" + (x.getMonth() +1) + "/" + x.getFullYear();
                    x2 = txt + x2 + " - " +  x.getHours( )+ ":" +  x.getMinutes() + ":" +  x.getSeconds();
                    document.getElementById('RefreshPageDateTime').innerHTML = x2;
                }
"@
        [String]$global:top += "
                function audio_alarme() {
					var audio=document.createElement('audio');
					audio.setAttribute('src','./audio/alarme_chouette.mp3');
					audio.play();
				}
"
        [String]$global:top += @"
            </script>
        </head>
    
        <body onload="display_ct()">
            <span id="col1" onload="audio_alarme()">
                <a href="https://ekara.ip-label.net/" target="_blank" title="Ekara Restituion UI">
                    <img class="logo" src="$HTMLLogo" alt="Logo EKARA"/>
                </a>
            </span>
            <span id="col2">
                <h1>CONSOLE EKARA</h1> 
                <p><span id="RefreshPageDateTime" STYLE="padding:0 0 0 40px;"></span> <span id="InventoryDateTime" STYLE="padding:0 0 0 80px;">Last request update : $LastUpdateInventory</span></p>
            </span>
"@
}


Function create_BOTTOM_HTML{
    # Content HTML bottom
        [String]$global:bottom = @"
            <hr>        
            <center>
                    <h2>Version : $Version</h2>
            </center>
        </body>
"@
}

#endregion


#region Main
    #========================== START SCRIPT ======================================
    info "Info" "EKARA Console" "EKARA request started"               # Lance la fonction pour afficher une POPUP
    Hide-Console                                                     # Lance la fonction pour réduit la console PS dans la barre des taches
    Authentication                                                    # Lance la fonction l'authentification
    Inventory                                                         # Lance la fonction pour effectuer l'inventaire
    Create_HTML | Out-Null                                            # Lance la fonction pour créer la page HTML
    Start-Process $HTMLFullPath                                       # Lance la fonction pour ouvrir la page HTML
    

    # Boucle pour relancer l'inventaire et mettre à jour le contenu du fichier HTML jusqu'à 23:55
    Do {
	    Write-Host "Debut de Boucle : Attente de $IntervalInventory secondes"
        Start-Sleep -Seconds $IntervalInventory
        Inventory
        Create_HTML | Out-Null              # Creating a HNML file for content
    }
    Until("1" -gt "2")
#endregion
