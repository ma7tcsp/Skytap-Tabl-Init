#Banner Stuff
function Write-HostColored2(){[CmdletBinding()]param([parameter(Position=0, ValueFromPipeline=$true)] [string[]] $t,[switch] $x,[ConsoleColor] $bc = $host.UI.RawUI.BackgroundColor,[ConsoleColor] $fc = $host.UI.RawUI.ForegroundColor);begin{if ($t -ne $null){$t = "$t"}};process {if ($t) {$cfc = $fc;$cbc = $bc;$ks = $t.split("#");$p = $false;foreach($k in $ks) {if (-not $p -and $k -match '^([a-z]*)(:([a-z]+))?$') {try {$cfc = [ConsoleColor] $matches[1];$p = $true} catch {}if ($matches[3]) {try {$cbc = [ConsoleColor] $matches[3];$p = $true} catch {}}if ($p) {continue}};$p = $false;if ($k) {$argsHash = @{};if ([int] $cfc -ne -1) { $argsHash += @{ 'ForegroundColor' = $cfc } };if ([int] $cbc -ne -1) { $argsHash += @{ 'BackgroundColor' = $cbc } };Write-Host -NoNewline @argsHash $k} $cfc = $fc;$cbc = $bc}} if (-not $x) { write-host }}}
$banner = ("             #darkcyan#▄▄#             
       #yellow#▄▄#  #darkcyan#▄▄██▄▄#  #darkcyan#▄▄#       
       #yellow#██#  #darkcyan#▀▀██▀▀#  #darkcyan#██#       
    #yellow#████████# #darkcyan#▀▀# #darkcyan#████████#    
       #yellow#██#    #red#██#    #darkcyan#██#       ████████╗ █████╗ ██████╗ ██╗     ███████╗ █████╗ ██╗   ██╗
    #darkcyan#██# #yellow#▀▀#    #red#██#    #darkcyan#▀▀# #magenta#██#    ╚══██╔══╝██╔══██╗██╔══██╗██║     ██╔════╝██╔══██╗██║   ██║
  #darkcyan#██████# #red#██████████# #magenta#██████#     ██║   ███████║██████╔╝██║     █████╗  ███████║██║   ██║
    #darkcyan#██# #darkred#▄▄#    #red#██#    #blue#▄▄# #magenta#██#       ██║   ██╔══██║██╔══██╗██║     ██╔══╝  ██╔══██║██║   ██║
       #darkred#██#    #red#██#    #blue#██#          ██║   ██║  ██║██████╔╝███████╗███████╗██║  ██║╚██████╔╝
    #darkred#████████# #magenta#▄▄# #blue#████████#       ╚═╝   ╚═╝  ╚═╝╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝ ╚═════╝ 
       #darkred#██#  #magenta#▄▄██▄▄#  #blue#██#                  HANDS ON TRAINING INITALIZATION...
       #darkred#▀▀#  #magenta#▀▀██▀▀#  #blue#▀▀#       
             #magenta#▀▀#              ")
Write-HostColored2 $banner
#Tableu Initaliser
write-host("")
write-host("          ======================================================================")
write-host("          Please wait while Tableau configures                                  ")
write-host("          This may take several minutes                                         ")
write-host("          When complete, TSM will load in the browser and this window will close")
write-host("          Sit back and make yourself a cuppa in the meantime                    ")
write-host("          ======================================================================")
write-host("")
#Pause for 60 seconds to allow services to run from resume state
Start-Sleep -Seconds 60
#Wait for time synchronization
write-host("Waiting for Date and Time Sync")
$s2 = Get-Service 'Windows Time'
$s2.WaitForStatus('Running')
w32tm /resync /force
#Wait for windows TSM service to start running
write-host("Waiting for TSM service to run")
$s1 = Get-Service 'Tableau Server Service Manager'
$s1.WaitForStatus('Running')
#Set Tls
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Ssl3, [Net.SecurityProtocolType]::Tls, [Net.SecurityProtocolType]::Tls11, [Net.SecurityProtocolType]::Tls12
#Login to TSM and set sesion cookie
$l = Invoke-WebRequest -Uri https://tab-emb-lab:8850/api/0.5/login -Method Post -SessionVariable s -ContentType 'application/json' -Body '{"authentication":{"name":"Administrator","password":"Password1!"}}'
if($l.StatusCode -eq 204){
	#Logged in OK
	write-host("Logged into TSM")
	#Get Licenses
	$r = Invoke-RestMethod -Uri https://tab-emb-lab:8850/api/0.5/licensing/productKeys -Method Get -WebSession $s
	#Check if trial already active
	if($r.ProductKeys.items.serial -eq "trial" -And $r.ProductKeys.items.isActive -eq "True"){
		write-host("Trial already activated")
	}else{
		write-host("No trial license, activate")
		tsm licenses activate -t
		#tsm licenses activate -k 'REPLACE WITH REAL LIC'
		write-host("Updating nodes with new license")
		Start-Sleep -Seconds 60		
	}
	#register Tableau 
	#tsm register --file C:\Users\Administrator\reg.json
	$l = ""
	$b = Get-Content C:\Users\Administrator\reg.json -raw
	$l = Invoke-WebRequest -Uri https://tab-emb-lab:8850/api/0.5/licensing/registration -Method Post -ContentType 'application/json' -WebSession $s -Body $b
	if($l.StatusCode -eq 204){
		#Registration OK
		write-host("Tableau Server Registered")		
	}else{
		#Registraion failed
		write-host("Failed to register automatically")
		write-host("Don't panic! Just click register when prompted in the browser :)")
	}
	#Start Tableau Server
	write-host("Starting Tableau Server")
	#Use TSM command directly to return progress
	tsm start
	#Launch browser to TSM
	start-process "https://tab-emb-lab:8850/#/status"
	#pause
	#Exit
	exit
}else {
	#failed to log in
	write-host("Failed to login")
	pause
}
write-host("Generic Error")
pause
