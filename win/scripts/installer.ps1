function Write-ErrorMessage {
    [CmdletBinding(DefaultParameterSetName = 'ErrorMessage')]
    param(
        [Parameter(Position = 0, ParameterSetName = 'ErrorMessage', ValueFromPipeline, Mandatory)][string]$errorMessage,
        [Parameter(ParameterSetName = 'ErrorRecord', ValueFromPipeline)][System.Management.Automation.ErrorRecord]$errorRecord, 
        [Parameter(ParameterSetName = 'Exception', ValueFromPipeline)][Exception]$exception
    )

    switch ($PsCmdlet.ParameterSetName) {
        'ErrorMessage' {
            $err = $errorMessage
        }
        'ErrorRecord' {
            $errorMessage = @($error)[0]
            $err = $errorRecord
        }
        'Exception' {
            $errorMessage = $exception.Message
            $err = $exception
        }
    }

    Write-Error -Message $err -ErrorAction SilentlyContinue
    $Host.UI.WriteErrorLine($errorMessage)
}

$currentPrincipal = New-Object Security.Principal.WindowsPrincipal(
    [Security.Principal.WindowsIdentity]::GetCurrent()
)
if (!($currentPrincipal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator))) {
    Write-ErrorMessage "[Error] You are not running this with Administrator permissions."
    exit 1
}

if (!(Get-Command 'choco' -erroraction 'silentlycontinue')) {
    [System.Net.ServicePointManager]::SecurityProtocol = 3072
    iex ((New-Object System.Net.WebClient).DownloadString('https://chocolatey.org/install.ps1'))
    $env:PATH = "$env:PATH;$env.ALLUSERSPROFILE\chocolatey\bin"
}

if (!(Get-Command 'git' -erroraction 'silentlycontinue')) {
    choco install git.install -y --params '/GitAndUnixToolsOnPath /WindowsTerminal'
}

if (!(Get-Command 'python' -erroraction 'silentlycontinue')) {
    choco install python -y --version 3.9.0
}

$env:PIPELINE_ROOT = "$env:USERPROFILE\AppData\Local\Programs\bd-pipeline"

if (Test-Path -path "$env:PIPELINE_ROOT") {
    Write-ErrorMessage "[Error] Pipeline is already installed into `"$env:PIPELINE_ROOT`" directory."
    exit 1
}

$ssh_key = [RegEx]::Escape("$env:USERPROFILE\.ssh\bd-ppl_rsa")

if (!(Test-Path -path $ssh_key)) {
    ssh-keygen -t ed25519 -f $ssh_key -q -N '""'
}

$public_ssh_key_content = $(Get-Content "$ssh_key.pub")

Write-Output ""

[Console]::ForegroundColor = 'red'
[Console]::WriteLine($public_ssh_key_content)
[Console]::ResetColor()

$public_ssh_key_content | Set-Clipboard

Write-Output ""

[Console]::ForegroundColor = 'green'
[Console]::WriteLine("Your Public SSH key was printed above and also copied into your Clipboard.")
[Console]::WriteLine("Please send it to your Administrator and wait for the APPROVAL to proceed.")
[Console]::ResetColor()

Write-Output ""

$reply = Read-Host -Prompt "Have you received the Approval to proceed? [yes/no]"

if ($reply.ToLower() -ne "yes") {
    exit 1
}

Write-Output ""

$env:GIT_SSH_COMMAND = "ssh -i $ssh_key -o IdentitiesOnly=yes"
git clone --depth 1 git@github.com:brudanstudios-rnd/bd-pipeline.git $env:PIPELINE_ROOT

if ($LastExitCode -ne 0) {
    exit $LastExitCode
}

[Environment]::SetEnvironmentVariable("BD_PIPELINE_ROOT", $env:PIPELINE_ROOT, "User")

$icons_dir = "$env:PIPELINE_ROOT\icons"
$icon_path = "$icons_dir\main.ico"

New-item -Path $icons_dir -ItemType Directory
Copy-Item "$PSScriptRoot\..\icons\main.ico" -Destination "$icons_dir\main.ico"

$wscript_obj = New-Object -ComObject ("WScript.Shell")
$shortcut = $wscript_obj.CreateShortcut("$env:USERPROFILE\Desktop\bd-activate.lnk")
$shortcut.TargetPath = "$env:PIPELINE_ROOT\activate.bat"
$shortcut.WorkingDirectory = $env:PIPELINE_ROOT
$shortcut.IconLocation = $icon_path
$shortcut.Save() | Out-Null

[Console]::ForegroundColor = 'green'
[Console]::WriteLine("Successfuly installed BD Remote Pipeline.")
[Console]::ResetColor()
