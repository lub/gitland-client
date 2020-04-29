git -C '../gitland' pull

$players = Get-ChildItem -Path '../gitland/players/' -Exclude 'placeholder99999999999999999999999999999' `
| ForEach-Object {
    @{
        Player = $_.Name
        Team = Get-Content ($_.FullName+'/team')
        X = Get-Content ($_.FullName+'/x')
        Y = Get-Content ($_.FullName+'/y')
    }
}

$y = 0
$decay = Get-Content -Path '../gitland/decay' `
| ForEach-Object {
    $x = 0
    $_ -split ',' | ForEach-Object {
        @{
            Decay = $_
            X = $x++
            Y = $y
        }
    }
    $y++
}

$y = 0
$map = Get-Content -Path '../gitland/map' `
| ForEach-Object {
    $x = 0
    $_ -split ',' | ForEach-Object {
        @{
            Color = $_
            Decay = $decay `
            | Where-Object X -eq $x `
            | Where-Object Y -eq $y `
            | Select-Object -ExpandProperty Decay
            X = $x
            Y = $y
        }
        $x++
    }
    $y++
}

$directionList = @(
    @{
        Name = 'up'
        Axis = 'Y'
        Modifier = -1
    }
    @{
        Name = 'down'
        Axis = 'Y'
        Modifier = 1
    }
    @{
        Name = 'left'
        Axis = 'X'
        Modifier = -1
    }
    @{
        Name = 'right'
        Axis = 'X'
        Modifier = 1
    }
)


$currentPlayer = $players | Where-Object Player -eq 'lub'
$currentPosition = $map `
| Where-Object X -eq $currentPlayer.X `
| Where-Object Y -eq $currentPlayer.Y

$moveList = $directionList | ForEach-Object {
    $preMove = $currentPosition.Clone()
    [int]$preMove.($_.Axis) += $_.Modifier

    $position = $map `
    | Where-Object X -eq $preMove.X `
    | Where-Object Y -eq $preMove.Y

    # check for $null, because that's out of bounds
    if($position -ne $null) {
        $move = $position.Clone()
        $move.Direction = $_.Name

        # check if player is currently empty
        # TODO: spy on move of player on that field
        if($move.Color[0] -eq 'u') {
            [pscustomobject]$move
        }
    }
} `
| Sort-Object {$_.Color[1] -eq $currentPlayer.Team[1]},{$_.Color -eq 'ux'},Decay

'possible moves:'
$moveList | Format-Table

if($moveList) {
    $action = $moveList | Select-Object -First 1
    'choosen action:'
    $action | Format-Table
    $direction = $action.Direction
} else {
    $direction = $directionList.Name | Get-Random
    'no suitable move found; moving random: '+$direction
}
$direction | Out-File -FilePath act

$env:GIT_SSH_COMMAND = 'ssh -i ./ssh'
git add act
git commit -m 'act'
git push