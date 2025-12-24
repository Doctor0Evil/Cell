function Get-CurveSample {
    param(
        [Parameter(Mandatory)]
        [double]$T,
        [Parameter(Mandatory)]
        [object]$Points
    )
    if ($T -le $Points[0][0]){ return $Points[0][1] }
    for ($i=1;$i -lt $Points.Count;$i++){
        $x0 = $Points[$i-1][0]; $y0 = $Points[$i-1][1]
        $x1 = $Points[$i][0]; $y1 = $Points[$i][1]
        if ($T -le $x1){
            if ($x1 - $x0 -eq 0){ return $y0 }
            $u = ($T - $x0)/($x1 - $x0)
            return $y0 + ($y1 - $y0) * $u
        }
    }
    return $Points[-1][1]
} 

$roar_vol = @( @(0.0,0.0), @(0.5,0.12), @(0.75,0.6), @(0.9,0.85), @(1.0,1.0) )
$roar_pitch = @( @(0.0,0.0), @(0.5,0.48), @(1.0,1.0) )
$creak_vol = @( @(0.0,0.0), @(0.4,0.45), @(0.7,0.75), @(1.0,1.0) )
$creak_pitch = @( @(0.0,0.0), @(0.8,0.03), @(1.0,0.12) )

function Convert-Range {
    param(
        [Parameter(Mandatory)]
        [double]$Value,
        [Parameter(Mandatory)]
        [double]$FromMin,
        [Parameter(Mandatory)]
        [double]$FromMax,
        [Parameter(Mandatory)]
        [double]$ToMin,
        [Parameter(Mandatory)]
        [double]$ToMax
    )
    if ($FromMax -eq $FromMin) { return $ToMin }
    $t = ($Value - $FromMin)/($FromMax - $FromMin)
    return $ToMin + ($ToMax - $ToMin) * $t
} 

Write-Output "Preview tuning sweep (t, roar_db, roar_pitch, creak_db, creak_pitch)"
$steps = 6
for ($i=0;$i -lt $steps;$i++){
    $t = [double]$i / [double]([math]::Max(1,$steps - 1))
    $rv = Get-CurveSample $t $roar_vol
    $rp = Get-CurveSample $t $roar_pitch
    $cv = Get-CurveSample $t $creak_vol
    $cp = Get-CurveSample $t $creak_pitch
    $roar_db = Convert-Range -Value $rv -FromMin 0 -FromMax 1 -ToMin -18.0 -ToMax -6.0
    $roar_pitch = Convert-Range -Value $rp -FromMin 0 -FromMax 1 -ToMin 0.8 -ToMax 1.1
    $creak_db = Convert-Range -Value $cv -FromMin 0 -FromMax 1 -ToMin -20.0 -ToMax -10.0
    $creak_pitch = Convert-Range -Value $cp -FromMin 0 -FromMax 1 -ToMin 0.95 -ToMax 1.05
    Write-Output ("t={0:N2} -> roar_db={1:N2} dB, roar_pitch={2:N3}, creak_db={3:N2} dB, creak_pitch={4:N3}" -f $t,$roar_db,$roar_pitch,$creak_db,$creak_pitch)
} 

# Dump mapping
$mapping = Get-Content 'c:\Users\Hunter\Repos\Cell\tools\audio\autobind_result.json' | ConvertFrom-Json
Write-Output "`nAuto-bind mapping simulation:" 
foreach ($k in $mapping.PSObject.Properties.Name){ Write-Output ("{0} -> {1}" -f $k, (Split-Path $mapping.$k -Leaf)) }