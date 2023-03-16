$content = Get-Content -Path .\validtemplate.json -raw
New-Item -ItemType Directory ".\GeneratedRules"

for (($i = 0); $i -lt 1000; $i++)
{ 
    $newGuid = [System.Guid]::NewGuid()
    $content.replace("{guid}", $newGuid) | Out-File ".\GeneratedRules\$($newGuid).json" -Encoding utf8
}