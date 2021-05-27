
[CmdletBinding()]
Param(
    [Parameter(Mandatory)]
    [string]$repoUrl,
    [Parameter(Mandatory)]
    [string]$username,
    [Parameter(Mandatory)]
    [string]$password,
    [Parameter(Mandatory)]
    [ValidateSet("r", "p", "t")]
    [string]$certificateAcceptResponse,
    [Parameter(Mandatory=$false)]
    [AllowEmptyString()]
    [string]$destination="",
    [switch]$outputStdout
)

# Shamelessly stolen from https://stackoverflow.com/a/54933303
Function Await-Task {
    param (
        [Parameter(ValueFromPipeline=$true, Mandatory=$true)]
        $task
    )

    process {
        while (-not $task.AsyncWaitHandle.WaitOne(1000)) { }
        $task.GetAwaiter().GetResult()
    }
}

Function Read-Output {
    param (
        [Parameter(ValueFromPipeline=$true, Mandatory=$true)]
        $streamReader
    )
    process {
        $readContent = ""
        $bufferSize = 80
        $buffer = [Char[]]::new($bufferSize)
        do {
            $readCount = $streamReader.ReadAsync($buffer, 0, $bufferSize) | Await-Task
            $readContent += $buffer[0..$readCount] -join ''
        } While($se.Peek() -ne -1)

        return $readContent
    }
}

$gitProgramPath = where.exe git
$gitArguments= "svn clone $repoUrl $destination --username=$username"

$p = New-Object System.Diagnostics.Process;
$p.StartInfo.UseShellExecute = $false;
$p.StartInfo.FileName = $gitProgramPath;
$p.StartInfo.Arguments = $gitArguments
$p.StartInfo.CreateNoWindow = $true
$p.StartInfo.RedirectStandardInput = $true
$p.StartInfo.RedirectStandardOutput = $true
$p.StartInfo.RedirectStandardError = $true

[void]$p.Start()

$sw = $p.StandardInput
$sr = $p.StandardOutput
$se = $p.StandardError


Start-Sleep -Seconds 5

$readText = $se | Read-Output

if($readText.Contains("Couldn't chdir to ")) {
    Write-Error "git svn is still running, please kill perl.exe and relaunch the command"
    exit 1
}
if($readText.Contains("(R)eject, accept (t)emporarily or accept (p)ermanently?")) {
    switch($certificateAcceptResponse) {
        "r" { Write-Host "Rejecting certificate" }
        "t" { Write-Host "Accepting certificate temporarily" }
        "p" { Write-Host "Accepting certificate permanently" }
    }
    $sw.WriteLine($certificateAcceptResponse)
    Start-Sleep -Seconds 5
    $readText = $se | Read-Output
}
if($readText.Contains("Password for ")) {
    Write-Host "Entering password"
    $sw.WriteLine($password)
}

$p.WaitForExit();

if($outputStdout.IsPresent) {
    Write-Host ($p.StandardOutput.ReadToEnd())
}

