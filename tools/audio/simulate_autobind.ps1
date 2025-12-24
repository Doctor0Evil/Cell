$files = Get-ChildItem -Path 'C:\Users\Hunter\Repos\Cell\audio\stingers' -File | Select-Object -ExpandProperty FullName
function Find-Match($player, $files){
    $lname = $player.ToLower()
    foreach($f in $files){
        if ($f.Split('\\')[-1].ToLower().Contains($lname)){
            return $f
        }
    }
    $tokens = @('base','mid','event','collapse','roar','stinger','petrified','promenade','heat','whisper','ghost','moan')
    foreach($t in $tokens){
        foreach($f in $files){
            if ($f.Split('\\')[-1].ToLower().Contains($t)){
                return $f
            }
        }
    }
    return $files[0]
}
$players = @('BasePlayer','MidPlayer1','MidPlayer2','EventPlayer1','CollapsePlayer1')
$map = @{}
foreach($p in $players){
    $pth = Find-Match $p $files
    $map[$p] = $pth
    # Remove selected file from available pool if present
    $files = $files | Where-Object { $_ -ne $pth }
}
$map | ConvertTo-Json | Out-File -FilePath 'C:\Users\Hunter\Repos\Cell\tools\audio\autobind_result.json' -Encoding utf8
Write-Output "WROTE autobind_result.json"