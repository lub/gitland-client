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
$map = Get-Content -Path '../gitland/map' `
| ForEach-Object {
    $x = 0
    $_ -split ',' | ForEach-Object {
        @{
            Color = $_
            X = $x++
            Y = $y
        }
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
$currentPosition = @{
    Color = $map `
    | Where-Object X -eq $currentPlayer.X `
    | Where-Object Y -eq $currentPlayer.Y `
    | Select-Object -ExpandProperty Color
    X = $currentPlayer.X
    Y = $currentPlayer.Y
}

$moveList = $directionList | ForEach-Object {
    $move = $currentPosition.Clone()
    [int]$move.($_.Axis) += $_.Modifier

    $move.Color = $map `
    | Where-Object X -eq $move.X `
    | Where-Object Y -eq $move.Y `
    | Select-Object -ExpandProperty Color

    $move.Direction = $_.Name

    if($move.Color.Substring(1) -notin ($currentPlayer.Team.Substring(1), $null)) {
        $move
    }
}

$action = $moveList | Get-Random
$action
$action.Direction | Out-File -FilePath act

$env:GIT_SSH_COMMAND = 'ssh -i ./ssh'
git add act
git commit -m 'act'
git push