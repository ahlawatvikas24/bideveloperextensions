param(
    [string]$ReleaseVersion = ""
)

#Figure out the directory in which the script resides.
function Get-ScriptDirectory
{
$Invocation = (Get-Variable MyInvocation -Scope 1).Value
Split-Path $Invocation.MyCommand.Path
}

#IntPtr in 64bit is 8 bytes
function is64bit() {    if ([IntPtr].Size -eq 4) { return $false }    else { return $true }}

#$framework_dir_2 = "$env:systemroot\microsoft.net\framework\v2.0.50727"
$framework_dir_3_5 = "$env:systemroot\microsoft.net\framework\v3.5"
$base_dir = (get-item (Get-ScriptDirectory)).parent.FullName
$build_dir = "$base_dir\build"
$sln_file_2005 = "$base_dir\SQL2005_bidshelper.sln"

#utility locations
$msbuild = "$framework_dir_3_5\msbuild.exe"  
$tf = "$env:ProgramFiles\Microsoft Visual Studio 9.0\Common7\IDE\tf.exe"
$nsisPath = "${Env:ProgramFiles(x86)}\NSIS\makensis.exe"

if(is64bit -eq $true) 
{
$tf = "$env:ProgramFiles (x86)\Microsoft Visual Studio 9.0\Common7\IDE\tf.exe"
$nsisPath = "${Env:ProgramFiles(x86)}\NSIS\makensis.exe"
}

#version files
$versionFiles = @("$base_dir\Properties\AssemblyInfo.cs", "ascii"),
        @("$base_dir\setupScript\BIDSHelperSetup.nsi", "ascii"),
        @("$base_dir\setupScript\BIDSHelperSetup2008.nsi", "ascii"),
        @("$base_dir\setupScript\BIDSHelperSetup2012.nsi", "ascii"),
        @("$base_dir\setupScript\SQL2005CurrentReleaseVersion.xml", "UTF8"),
        @("$base_dir\setupScript\SQL2008CurrentReleaseVersion.xml", "UTF8"),
        @("$base_dir\setupScript\SQL2012CurrentReleaseVersion.xml", "UTF8"),
        @("$base_dir\BIDSHelper.Addin", "unicode"),
        @("$base_dir\BIDSHelper2008.Addin", "unicode")
        @("$base_dir\BIDSHelper2012.Addin", "unicode")
$lastReleaseFile = "$base_dir\setupScript\SQL2005CurrentReleaseVersion.xml"

#Clean 

#checkVersion 
    if($ReleaseVersion.Length -eq 0)
    {
        # if we have not been given an explicit build, then we increment the build number
        # of the current release by 1.
        [string]$(get-Content "$($lastReleaseFile)") -cmatch '\d+\.\d+\.\d+\.\d+'
        $ver = $matches[0]
        
   		# HACK: having this regex match appears to make the replace statement work
		# removing it makes the following replace line fail for some reason.
        $null = $ver -cmatch "(?'main'\d+\.\d+\.\d+\.)(?'build'\d+)"
        
        $ReleaseVersion = $ver -replace "(?'main'\d+\.\d+\.\d+\.)(?'build'\d+)", "$($matches['main'])$([int]$matches['build']+1)"
    }
    


#Compile
    write-Host "Path: $msbuild"
    &($msbuild) $sln_file_2005 /t:Rebuild /p:Configuration=Release /v:q
    Write-Host "Executed Compile!"

#BuildSetup 
    write-Host "Starting NSIS"
    &($nsisPath) "$base_dir\SetupScript\BIDSHelperSetup.nsi"
    write-Host "Completed NSIS"