#$a = (Get-Date).Year + (Get-Date).Month + (Get-Date).Day + (Get-Date).Hour + (Get-Date).Minute
$currentTime = Get-Date -format yyyyMMddHHmm
$filelocation="c:\pwscripts\healthcheck\Healthcheck-" + $a + ".htm"

echo $filelocation