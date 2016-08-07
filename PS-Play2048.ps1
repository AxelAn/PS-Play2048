##############################################################################################################################
# Name			: 	Invoke-2048.ps1
# Description	: 	Play the game 2048 everywhere you find the "POWERshell"
# Author		: 	This one is by Axel Pokrandt (APo)
#				:	Base Powershell version created by: Micky Balladelli (https://balladelli.com/2048-powershell)
# 				:	Original code in JavaScript by: Gabriele Cirulli (https://github.com/gabrielecirulli/2048)
#				:	Story see 	http://de.wikipedia.org/wiki/2048_(Computerspiel)
#				:				http://en.wikipedia.org/wiki/2048_(video_game)
# License		:	
# Date			: 	10.11.2014 created based from code by Micky Balladelli
#				:   11.11.2014 Source Cleanup
#				:			   Check Win/Loose, New-Game
$Version		= "1.0.0 November 2014"
#				:   14.11.2014 	Better Form
#				:				Game Settings : change board size, winning game
#				:				ComputeFontSize rewritten, create new fonts only once
#				:				
$Version		= "1.1.0 November 2014"
#				:   15.11.2014 	Win/Lost Status
$Version		= "1.2.0 November 2014"
#				:				
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
#
#Requires –Version 2 
Set-StrictMode -Version Latest	

#region Import the Assemblies
[reflection.assembly]::loadwithpartialname("System.Windows.Forms") | Out-Null
[reflection.assembly]::loadwithpartialname("System.Drawing") | Out-Null
Add-Type -AssemblyName presentationCore 
#endregion

# constant declaration 

$script:boardSizes				= @(4,5,6,8,10)
$script:boardSizesMax			= 5
$script:boardSizeIndex			= 0

$script:gridSize 		= 4
$script:score 			= 0

$script:playStatePlay	= 0
$script:playStateLost	= 1
$script:playStateWin	= 2

$script:currentPlayState	= $script:playStatePlay

$script:winningGames		= @(1024,2048,4096,8192,16384,32768,65536)
$script:winningGamesMax		= 7
$script:winningGamesIndex   = 1
$script:winningTile			= 2048

$script:directionUp		= 3
$script:directionLeft	= 0
$script:directionDown	= 1
$script:directionRight	= 2

$script:vectorMap =	@(	@{ "row" = 0; "col"= -1 }; 	# 0  Left
						@{ "row" = 1; "col" = 0 };  # 1  Down
						@{ "row" = 0; "col" = 1 };  # 2  Right
						@{ "row"= -1; "col" = 0 })  # 3  Up
#	
$form = New-Object System.Windows.Forms.Form

$script:Font_1 	= New-Object System.Drawing.Font ($Form.Font.FontFamily, $Form.Font.Size, $Form.Font.Style)
$script:Font_2 	= New-Object System.Drawing.Font ($Form.Font.FontFamily, $Form.Font.Size, $Form.Font.Style)
$script:Font_3 	= New-Object System.Drawing.Font ($Form.Font.FontFamily, $Form.Font.Size, $Form.Font.Style)
$script:Font_4 	= New-Object System.Drawing.Font ($Form.Font.FontFamily, $Form.Font.Size, $Form.Font.Style)
$script:Font_5 	= New-Object System.Drawing.Font ($Form.Font.FontFamily, $Form.Font.Size, $Form.Font.Style)

<# REGION SOUND
$script:playermove = new-object system.windows.media.mediaplayer
$script:playerMove.open([uri]$((Resolve-Path ".\plop-click.mp3").Path))
# ENDREGION SOUND
#>
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
function GetVector {
	param ([Parameter(Mandatory=$true)][int]$direction)
 
	return $script:vectorMap[$direction]
}
#					
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
function WithinBounds {
	param ([Parameter(Mandatory=$true)][int]$row,
		   [Parameter(Mandatory=$true)][int]$col)

	return (($row -ge 0 -and $row -lt $script:gridSize) -and ($col -ge 0 -and $col -lt $script:gridSize))
}
#					
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
function ColorSingleTile {
	param ([Parameter(Mandatory=$true)][PsCustomObject]$cell)

	switch ($cell.label.text) {
		default
		{
			$cell.label.ForeColor = "#776e65"
			$cell.label.BackColor = [System.Drawing.Color]::Silver
		}
		"2"
		{
			$cell.label.BackColor = "#eee4da"
			$cell.label.ForeColor = [System.Drawing.Color]::DimGray
		}
		"4"
		{
			$cell.label.BackColor = "#ede0c8"
			$cell.label.ForeColor = [System.Drawing.Color]::DimGray
		}
		"8"
		{
			$cell.label.ForeColor = "#f9f6f2"
			$cell.label.BackColor = "#f2b179"
		}
		"16"
		{
			$cell.label.ForeColor = "#f9f6f2"
			$cell.label.BackColor = "#f59563"
		}
		"32"
		{
			$cell.label.ForeColor = "#f9f6f2"
			$cell.label.BackColor = "#f67c5f"
		}
		"64"
		{
			$cell.label.ForeColor = "#f9f6f2"
			$cell.label.BackColor = "#f65e3b"
		}
		"128"
		{
			$cell.label.ForeColor = "#f9f6f2"
			$cell.label.BackColor = "#edcf72"
		}
		"256"
		{
			$cell.label.ForeColor = "#f9f6f2"
			$cell.label.BackColor = "#edcc61"
		}
		"512"
		{
			$cell.label.ForeColor = "#f9f6f2"
			$cell.label.BackColor = "#edc850"
		}
		"1024"
		{
			$cell.label.ForeColor = "#f9f6f2"
			$cell.label.BackColor = "#edc53f"
		}
		"2048"
		{
			$cell.label.ForeColor = "#f9f6f2"
			$cell.label.BackColor = "#edc22e"
		}
		"4096"
		{
			$cell.label.ForeColor = "#f9f6f2"
			$cell.label.BackColor = "#ebb914"
		}
		"8192"
		{
			$cell.label.ForeColor = "#f9f6f2"
			$cell.label.BackColor = "#d3a612"
		}
		"16384"
		{
			$cell.label.ForeColor = "#f9f6f2"
			$cell.label.BackColor = "#bc9410"
		}
		"32768"
		{
			$cell.label.ForeColor = "#f9f6f2"
			$cell.label.BackColor = "#bc9410"
		}			
		"65536"
		{
			$cell.label.ForeColor = "#f9f6f2"
			$cell.label.BackColor = "#bc9410"
		}			
	}
	
}
#					
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
function ColorTiles {
	param ([PsCustomObject[][]]$grid)
 
	foreach ($row in $grid)	{
		foreach ($cell in $row)	{
			ColorSingleTile $cell
		}
	}
}
#					
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
function FindFarthestPosition {
	param ( [Parameter(Mandatory=$true)][PsCustomObject[][]]$grid, 
			[Parameter(Mandatory=$true)][PsCustomObject]$cell,
			[Parameter(Mandatory=$true)][System.Collections.Hashtable]$vector,
			[Parameter(Mandatory=$true)][int]$gridSize) 
 
	# Progress towards the vector direction until an obstacle is found
 
	do	{
		$previous = $cell;
		$row = $previous.row + $vector.row 
		$col = $previous.col + $vector.col
	} while ((WithinBounds $row $col) -and ($cell = $grid[$row][$col]) -and  $cell.empty)
 
	return @{ "farthest" = $previous;
		      "next"	 = $cell 		# Used to check if a merge is required
		    }
}
#					
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
function CheckAndMove {
	param ( [Parameter(Mandatory=$true)][PsCustomObject]$cell,
			[Parameter(Mandatory=$true)][PsCustomObject[][]]$grid, 
			[Parameter(Mandatory=$true)][int]$direction,
			[Parameter(Mandatory=$true)][switch]$checkOnly)
 
	$moved = $false
 
	if ($cell.empty -eq $false -and $cell.moving -eq $false) {
		$new = FindFarthestPosition $grid $cell (GetVector $direction) $script:gridSize 
 
		# Check if merge is possible
		if ( ($cell.label.text -eq $new.next.label.text) -and 
		     (($cell.row -ne $new.next.row) -or ($cell.col -ne $new.next.col)) -and 
			 ($new.next.merged -eq $false))	{

			if (!$CheckOnly) {
				$moved = MoveTile $cell $new.next 
				if ($moved) {
					ColorSingleTile $cell
					ColorSingleTile $new.next
				}
			} else {
				$moved = $True
			}
		}
		elseif (($cell.row -ne $new.farthest.row) -or ($cell.col -ne $new.farthest.col)) {

			if (!$CheckOnly) {
				$moved = MoveTile $cell $new.farthest 
				if ($moved) {
					ColorSingleTile $cell
					ColorSingleTile $new.farthest
				}
			} else {
				$moved = $True
			}
		} else {
		}
	}
 
	return $moved
}
#					
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
function MoveTile {
	param ( [Parameter(Mandatory=$true)][PsCustomObject]$from,
			[Parameter(Mandatory=$true)][PsCustomObject]$to)
 
	if ($from.label.text -eq $to.label.text -and $to.merged -eq $false)	{
		# merging tiles is possible
		$newTileValue = [int]$from.label.text * 2
		
		if ($newTileValue -eq $script:winningTile) {
			$script:currentPlayState = $script:playStateWin		
		}
		$to.label.text = $newTileValue.ToString()
		$to.merged = $true
 
		$script:score += [int] $to.label.text
		$labelScore.Text  = ("{0}" -f $script:score)
	} else {
		$to.label.text = $from.label.text
	}
 
	$from.label.text = ""
	$to.empty = $false
	$from.empty = $true
	$to.moving = $true
 
	ComputeFontSize $to.label

	return $true
}
#					
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
function CalculateFont {
	Param(  [Parameter(Mandatory=$true)][System.Drawing.Font]$font,
			[Parameter(Mandatory=$true)][string]$Text,
			[Parameter(Mandatory=$true)][System.Drawing.Size]$Size)
	
	$offset = 10
	
	if ($Text -eq "") {
		$fontWidth = [System.Windows.Forms.TextRenderer]::MeasureText("2", $Font).Width + $offset
	} else {
		$fontWidth = [System.Windows.Forms.TextRenderer]::MeasureText($Text, $Font).Width + $offset
	}
	
	if ($size.Width -lt $fontWidth -and $fontWidth -ne 0) {
		while($size.Width -lt $fontWidth) {
			$Font = New-Object System.Drawing.Font ($Font.FontFamily, ($Font.Size - 1), $Font.Style)
			$fontWidth = [System.Windows.Forms.TextRenderer]::MeasureText($Text, $Font).Width + $offset
		}
	} elseif ($fontWidth -ne 0 -and $size.Width -gt $fontWidth) {
		if ($font.size -ne ($size.Height/2.8)) {
			$Font = New-Object System.Drawing.Font ($Font.FontFamily, ($size.Height/2.8), $Font.Style)
		}
	}
	
	return $font
}
#					
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
function ComputeFontSize {
	param ([Parameter(Mandatory=$true)][System.Windows.Forms.Label]$label)

	if ($label.Text.Length -eq 0) {
		$label.Font = $script:Font_1
	} elseif ($label.Text.Length -eq 1) {
		$label.Font = $script:Font_1
	} elseif ($label.Text.Length -eq 2) {
		$label.Font = $script:Font_2
	} elseif ($label.Text.Length -eq 3) {
		$label.Font = $script:Font_3
	} elseif ($label.Text.Length -eq 4) {
		$label.Font = $script:Font_4
	} elseif ($label.Text.Length -eq 5) {
		$label.Font = $script:Font_5
	} else {
		$label.Font = $script:Font_5
	}
}
#					
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
Function CheckAndMoveTilesWithDirection {
	param ( [Parameter(Mandatory=$true)][PsCustomObject[][]]$grid,
			[Parameter(Mandatory=$true)][int]$direction,
			[Parameter(Mandatory=$true)][switch]$CheckOnly)
	
	$moved = $false
	$SleepTime = 40
	
	switch ($direction)	{
		$script:directionDown	{
					for ($row = $script:gridSize -1; $row -ge 0; $row--) {
						$rowMoved = $false
						for ($col = 0; $col -lt $script:gridSize; $col++) {
							$cell = $grid[$row][$col]
							$ret = CheckAndMove $cell $grid $direction -CheckOnly:$CheckOnly 
		 
							if ($ret -eq $true)	{
								$moved = $true
								$rowMoved = $true
							}
						}
						#if ($rowMoved -and !$CheckOnly) {Start-Sleep -MilliSeconds $SleepTime}
					}
				}
		$script:directionRight	{
					foreach ($row in $grid)	{
						$traversal = $row.Clone()
						[array]::Reverse($traversal)
						$rowMoved = $false
						
						foreach($cell in $traversal) {
							$ret = CheckAndMove $cell $grid $direction -CheckOnly:$CheckOnly 
							if ($ret -eq $true)	{
								$moved = $true
								$rowMoved = $true
							}
						}
						#if ($rowMoved -and !$CheckOnly) {Start-Sleep -MilliSeconds $SleepTime}
						
					}
				}
		{$script:directionLeft, $script:directionUp -contains $_}
				{
					foreach ($row in $grid)	{
					
						$rowMoved = $false
						foreach($cell in $row) {
							$ret = CheckAndMove $cell $grid $direction -CheckOnly:$CheckOnly 
							if ($ret -eq $true)	{
								$moved = $true
								$rowMoved = $true
							}
						}
						#if ($rowMoved -and !$CheckOnly) {Start-Sleep -MilliSeconds $SleepTime}
					}
				}
	}	
	
	return $moved 
}
#					
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
Function Check-LoseGame {
	param ([Parameter(Mandatory=$true)][PsCustomObject[][]]$grid)
	
	$ret = $false
	
	if (!(Check-AvailableCell $grid)) {
		# No more Cells available, Check directions

		if (!(CheckAndMoveTilesWithDirection $grid  $script:directionUp		-CheckOnly:$True  )) {
			if (!(CheckAndMoveTilesWithDirection $grid  $script:directionDown	-CheckOnly:$True  )) {
				if (!(CheckAndMoveTilesWithDirection $grid  $script:directionLeft	-CheckOnly:$True  )) {
					if (!(CheckAndMoveTilesWithDirection $grid  $script:directionRight	-CheckOnly:$True  ) ) {
						"OOOOPS .... you lose the game" | out-host
						$script:currentPlayState = $script:playStateLost
						$ret = $true
					}
				}
			}
		}
	}
	
	return $ret
}
#					
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
function MoveTiles {
	param ([PsCustomObject[][]]$grid,[int]$direction)
 
	$moved = CheckAndMoveTilesWithDirection $grid  $direction -CheckOnly:$False  
	
	# Done moving, reset the moving and merged flags
	foreach ($row in $grid)	{
		foreach($cell in $row) {
			$cell.moving = $false
			$cell.merged = $false
 		}
	}
	<# REGION SOUND
	if ($moved) {
		
        #$songDuration = $script:playerMove.NaturalDuration.TimeSpan.TotalMilliseconds
		#$script:playerMove.Volume = 0.25
		#$script:playerMove.Play()
		#Start-Sleep -Milliseconds $songDuration
		#$script:playerMove.Stop()	
		
		$script:playerMove.Stop()
		$script:playerMove.Volume = 0.25
		$script:playerMove.Play()
		
	}
	# ENDREGION SOUND
	#>
	
	return $moved 
}
#					
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
function GetAvailableCells {
	param ([Parameter(Mandatory=$true)][PsCustomObject[][]]$grid)
 
	$cells = @()
	foreach ($row in $grid)	{
		foreach($cell in $row) {
			if ($cell.empty) {
				$cells += $cell
			}
		}
	}
 
	return $cells
}
#					
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 
function Check-AvailableCell {
	param ([Parameter(Mandatory=$true)][PsCustomObject[][]]$grid)
	
	$avail = $false
 					
	for ($row = 0; ($row -lt $script:gridSize) -and !$avail; $row++) {
		for ($col = 0; ($col -lt $script:gridSize) -and !$avail; $col++) {
			if ($grid[$row][$col].empty) {
				$avail = $True
			}
		}
	}
 
	return $avail
}
#					
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# 
function CreateEmptyGrid {
	param ([Parameter(Mandatory=$true)][int]$gridSize)
	$grid = @()
 
	$grid = ,@(0..($gridSize-1))
	for ($i = 1; $i -lt $gridSize; $i++)
	{
		$grid += ,@(0..($gridSize-1))
	}

	for ($i = 0; $i -lt $gridSize; $i++)
	{
		for ($j = 0; $j -lt $gridSize; $j++)
		{
			$grid[$i][$j] = New-Object -TypeName PSCustomObject -Property @{
			                    empty = $true;
								tile  = 0;
								row	  = $i;
								col	  = $j;
								label = $null;
								moving= $false
								merged= $false
							}
		}
 
	}
 
	return $grid
}
#					
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
function AddRandomTile {
	param ([Parameter(Mandatory=$true)][PsCustomObject[][]]$grid)

	$cells = GetAvailableCells $grid
	if ($cells)	{
		$random = if ((Get-Random -Minimum 1 -Maximum 100) -lt 90) {"2"} else {"4"}
		
		$cell = Get-Random -InputObject $cells
 
		if ($cell) {
			$cell.label.Text = $random
			$cell.empty = $false
			ComputeFontSize $cell.label
			ColorTiles $grid
		}
	}
	return $cell
}
#					
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
Function New-Game {
	param ([Parameter(Mandatory=$true)][PsCustomObject[][]]$grid)
	
	for ($i = 0; $i -lt $script:gridSize; $i++) {
		for ($j = 0; $j -lt $script:gridSize; $j++) {
			$grid[$i][$j].empty = $true;
			$grid[$i][$j].tile  = 0;
			$grid[$i][$j].row	  = $i;
			$grid[$i][$j].col	  = $j;
			$grid[$i][$j].label.Text = ""
			$grid[$i][$j].moving= $false
			$grid[$i][$j].merged= $false
		}
	}
	
	$null = AddRandomTile $grid
	$null = AddRandomTile $grid
	
	ColorTiles $grid
	$script:score 			= 0
	$labelScore.Text = "0"
	
	$labelStatus.ForeColor = [System.Drawing.Color]::FromArgb(255,255,255,255)
	$labelStatus.Text = "Play the Game"		

	
	$script:currentPlayState	= $script:playStatePlay
}
#					
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
function New-WinningGame {
	param ([Parameter(Mandatory=$true)][PsCustomObject[][]]$grid)

	$script:winningGamesIndex = (++$script:winningGamesIndex % $script:winningGamesMax)
	
	$script:winningTile = $script:winningGames[$script:winningGamesIndex]
	$buttonGame.Text = ("Game : {0}" -f $script:winningTile)

	New-Game $grid
	
	$grid
}
#					
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
Function New-Board {
	param ([Parameter(Mandatory=$true)][PsCustomObject[][]]$grid)

	$script:boardSizeIndex = (++$script:boardSizeIndex % $script:boardSizesMax)
	
	$script:gridSize = $script:boardSizes[$script:boardSizeIndex]
	$buttonBoard.Text = ("Board : {0} x {1}" -f $script:gridSize,$script:gridSize)
	
	$grid = CreateEmptyGrid $script:gridSize
	
	New-GridLabel $grid
	Resize $panelBoard $grid	
	New-Game $grid
	
	$grid
}
#					
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
Function New-GridLabel {
	Param([Parameter(Mandatory=$true)][PsCustomObject[][]]$grid)
	
	$panelBoard.Controls.clear()
	
	for ($i = 0; $i -lt $script:gridSize; $i++) {
		for ($j = 0; $j -lt $script:gridSize; $j++) {
			$grid[$i][$j].label = New-Object System.Windows.Forms.Label
			$grid[$i][$j].label.AutoSize = $false
			$grid[$i][$j].label.TextAlign =  [System.Drawing.ContentAlignment]::MiddleCenter
			$panelBoard.Controls.Add($grid[$i][$j].label)
		}
	}
	
}
#					
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#
Function Test-PlayState {

	switch ($script:currentPlayState) {
		($script:playStatePlay) {
									break;
								}
		($script:playStateLost) {
									$labelStatus.ForeColor = [System.Drawing.Color]::FromArgb(255,255,0,0)
									$labelStatus.Text = "You have LOST"
									break;
								}
		($script:playStateWin)	{
									$labelStatus.ForeColor = [System.Drawing.Color]::FromArgb(255,0,255,0)
									$labelStatus.Text = "Yeah, you WIN"		
									break;
								}
	}
}

#					
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
#

$grid = CreateEmptyGrid $script:gridSize
 
function Resize {
	param ( [Parameter(Mandatory=$true)]$element,
			[Parameter(Mandatory=$true)][PsCustomObject[][]]$grid)
 
	$border = 10
	$margin = 7
	
	$y = $border
	$x = $border
 
	$size = New-Object System.Drawing.Size
	$size.Width = (($element.Width - (2*$border) - ($margin*($script:gridSize-1))) / $script:gridSize) 
	$size.Height = (($element.Height - (2*$border) - ($margin*($script:gridSize-1))) / $script:gridSize) 
 
	$script:Font_1 = CalculateFont $script:Font_1 "9" $size
	$script:Font_2 = CalculateFont $script:Font_2 "99" $size
	$script:Font_3 = CalculateFont $script:Font_3 "999" $size
	$script:Font_4 = CalculateFont $script:Font_4 "9999" $size
	$script:Font_5 = CalculateFont $script:Font_5 "99999" $size
 
	for ($i = 0; $i -lt $script:gridSize; $i++)
	{
		for ($j = 0; $j -lt $script:gridSize; $j++)
		{
			$grid[$i][$j].label.Location = New-Object System.Drawing.Point($x, $y)
			$x += ($size.Width) + $margin
			$grid[$i][$j].label.Size = $size
 
			if ($grid[$i][$j].label.Text -ne $null)
			{
				ComputeFontSize $grid[$i][$j].label
			}
		}
 
		$y += ($size.Height) + $margin
		$x = $border
	}
 
}
 
$form_keyDown = {
	$SleepTime = 80
	
	if ($script:currentPlayState -eq $script:playStatePlay) {
		if($_.KeyCode -eq "Down") {
			if ((MoveTiles $grid $script:directionDown ))	{
				#Start-Sleep -MilliSeconds $SleepTime
				AddRandomTile $grid
			}
		} elseif($_.KeyCode -eq "Up")	{
			if ((MoveTiles $grid $script:directionUp )) {
				#Start-Sleep -MilliSeconds $SleepTime
				AddRandomTile $grid
			}
		} elseif($_.KeyCode -eq "Left") {
			if ((MoveTiles $grid $script:directionLeft )) {
				#Start-Sleep -MilliSeconds $SleepTime
				AddRandomTile $grid
			}
		} elseif($_.KeyCode -eq "Right")	{
			if ((MoveTiles $grid $script:directionRight ))	{
				#Start-Sleep -MilliSeconds $SleepTime
				AddRandomTile $grid
			}
		}
		Check-LoseGame $grid 
	} 
	
	Test-PlayState
	
	if($_.KeyCode -eq "N") {
		New-Game $grid 
	}
	if($_.KeyCode -eq "X") {
		$form.close()
	}
	if($_.KeyCode -eq "B") {
		
		$grid = New-Board $grid
	}
	if($_.KeyCode -eq "G") {
		New-WinningGame $grid
	}
}

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
# GUI
#

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
$panelBoard = New-Object System.Windows.Forms.Panel

$panelBoard.DataBindings.DefaultDataSourceUpdateMode = 0
$panelBoard.Name = "PanelBoard"
$panelBoard.Location = New-Object System.Drawing.Point(0,0)
$panelBoard.Size = New-Object System.Drawing.Size(0,0)

$panelBoard.Dock = [System.Windows.Forms.DockStyle]::Fill

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
 
$panelControl = New-Object System.Windows.Forms.Panel

$panelControl.DataBindings.DefaultDataSourceUpdateMode = 0
$panelControl.Name = "PanelControl"
$panelControl.Location = New-Object System.Drawing.Point(0,0)
$panelControl.Size = New-Object System.Drawing.Size(200,0)

$panelControl.Dock = [System.Windows.Forms.DockStyle]::Right

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 

$labelBottom = New-Object System.Windows.Forms.Label
$labelBottom.Name = "labelBottom"
$labelBottom.ForeColor = [System.Drawing.Color]::FromArgb(255,192,192,192)
$labelBottom.TextAlign =  [System.Drawing.ContentAlignment]::BottomRight
$labelBottom.Text = "by Axel Pokrandt"
$labelBottom.Location = New-Object System.Drawing.Point(0,0)
$labelBottom.Size = New-Object System.Drawing.Size(195,10)
$labelBottom.Font = New-Object System.Drawing.Font ($form.Font.FontFamily,6, $form.Font.Style)
$labelBottom.Dock = [System.Windows.Forms.DockStyle]::Bottom

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 

$labelStatus = New-Object System.Windows.Forms.Label
$labelStatus.Name = "labelStatus"
$labelStatus.ForeColor = [System.Drawing.Color]::FromArgb(255,255,255,255)
$labelStatus.TextAlign =  [System.Drawing.ContentAlignment]::MiddleCenter
$labelStatus.Text = "Play the Game"
$labelStatus.AutoSize = $false
$labelStatus.Location = New-Object System.Drawing.Point(5,0)
$labelStatus.Size = New-Object System.Drawing.Size(190,34)
$labelStatus.Font = New-Object System.Drawing.Font ($form.Font.FontFamily, 16, [System.Drawing.FontStyle]::Bold)
$labelStatus.Dock = [System.Windows.Forms.DockStyle]::Bottom
# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 

$labelScore = New-Object System.Windows.Forms.Label
$labelScore.Name = "labelScore"
$labelScore.ForeColor = [System.Drawing.Color]::FromArgb(255,255,255,10)
$labelScore.TextAlign =  [System.Drawing.ContentAlignment]::MiddleCenter
$labelScore.Text = "0"
$labelScore.AutoSize = $false
$labelScore.Location = New-Object System.Drawing.Point(5,0)
$labelScore.Size = New-Object System.Drawing.Size(190,28)
$labelScore.Font = New-Object System.Drawing.Font ($form.Font.FontFamily, 22, $form.Font.Style)
$labelScore.Dock = [System.Windows.Forms.DockStyle]::Bottom

$panelControl.Controls.Add($labelScore)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
$buttonNew = New-Object System.Windows.Forms.Button
$buttonNew.ForeColor = [System.Drawing.Color]::FromArgb(255,255,255,10)
$buttonNew.Name = "buttonNew"
$buttonNew.DataBindings.DefaultDataSourceUpdateMode = 0
$buttonNew.Location = New-Object System.Drawing.Point(5,10)
$buttonNew.Size = New-Object System.Drawing.Size(190,26)
$buttonNew.Text = "New Game"
$buttonNew.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$buttonNew.add_Click({New-Game $grid })
$buttonNew.add_PreviewKeyDown({
	$_.IsInputKey = ( @("Left","Right","Up","Down") -contains $_.KeyCode ) # sent back to form
})

$panelControl.Controls.Add($buttonNew)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 

$buttonBoard = New-Object System.Windows.Forms.Button
$buttonBoard.ForeColor = [System.Drawing.Color]::FromArgb(255,255,255,10)
$buttonBoard.Name = "buttonBoard"
$buttonBoard.DataBindings.DefaultDataSourceUpdateMode = 0
$buttonBoard.Location = New-Object System.Drawing.Point(5,41)
$buttonBoard.Size = New-Object System.Drawing.Size(190,26)
$buttonBoard.Text = ("Board : {0} x {1}" -f $script:gridSize,$script:gridSize)
$buttonBoard.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$buttonBoard.add_Click({$grid = New-Board $grid })
$buttonBoard.add_PreviewKeyDown({
	$_.IsInputKey = ( @("Left","Right","Up","Down") -contains $_.KeyCode ) # sent back to form
})

$panelControl.Controls.Add($buttonBoard)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 

$buttonGame = New-Object System.Windows.Forms.Button
$buttonGame.ForeColor = [System.Drawing.Color]::FromArgb(255,255,255,10)
$buttonGame.Name = "buttonGame"
$buttonGame.DataBindings.DefaultDataSourceUpdateMode = 0
$buttonGame.Location = New-Object System.Drawing.Point(5,72)
$buttonGame.Size = New-Object System.Drawing.Size(190,26)
$buttonGame.Text = ("Game : {0}" -f $script:winningTile)
$buttonGame.FlatStyle = [System.Windows.Forms.FlatStyle]::Flat
$buttonGame.add_Click({$grid = New-Board $grid })
$buttonGame.add_PreviewKeyDown({
	$_.IsInputKey = ( @("Left","Right","Up","Down") -contains $_.KeyCode ) # sent back to form
})

$panelControl.Controls.Add($buttonGame)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
$panelControl.Controls.Add($labelStatus)
$panelControl.Controls.Add($labelScore)
$panelControl.Controls.Add($labelBottom)

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 

#
# Add the output text box
New-GridLabel $grid

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 

$form.Controls.Add($panelBoard)
$form.Controls.Add($panelControl)
 
$null = AddRandomTile $grid
$null = AddRandomTile $grid

# ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~ 
 
# Set initial dialog size and title
$form.Size = New-Object System.Drawing.Size(600,410)
$form.StartPosition = 'CenterParent'
$form.Text = ("2048 in Powershell, {0}" -f $Version)
$form.BackColor = [System.Drawing.Color]::Gray 
$form.KeyPreview = $true 
$form.Add_KeyDown($form_keyDown)
$OnResize = {
	Resize $panelBoard $grid
}
$form.add_Resize($OnResize)
 
$icon = [system.drawing.icon]::ExtractAssociatedIcon($PSHOME + "\powershell.exe")
$Form.icon = $icon
 
#Show the Form
Resize $panelBoard $grid
ColorTiles $grid
$script:currentPlayState = $script:playStatePlay

$form.ShowDialog()| Out-Null
