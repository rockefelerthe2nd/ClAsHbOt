Func DonateTroops()
   DebugWrite("DonateTroops()")

   ; Open chat window
   If OpenChatWindow() = False Then Return False

   ; Search for donate button
   Local $donateButtonAbsolute[8]
   If FindDonateButton($donateButtonAbsolute) = False Then Return False

   ; Get the request text
   Local $requestText
   GetRequestText($donateButtonAbsolute, $requestText)

   ; Open donate droops window
   If OpenDonateTroopsWindow($donateButtonAbsolute) = False Then Return False

   ; Loop until donate troops window goes away, no match for request, or loop limit reached
   Local $loopLimit = 5
   While IsColorPresent($WindowChatDimmedColor) And $loopLimit>0
	  DebugWrite("Donate loop " & 6-$loopLimit & " of " & 5)

	  ; Locate troops that are available to donate
	  Local $donateIndexAbsolute[UBound($gDonateSlotBMPs)][4] ; x1, y1, x2, y2
	  FindDonateTroopSlots($donateButtonAbsolute, $donateIndexAbsolute)

	  ; Parse request text, matching with available troops
	  Local $indexOfTroopToDonate
	  If ParseRequestText($requestText, $donateIndexAbsolute, $indexOfTroopToDonate) = False Then ExitLoop
	  If $donateIndexAbsolute[$indexOfTroopToDonate][0] = -1 Then ExitLoop

	  ; Click the correct donate troops button
	  ClickDonateTroops($donateIndexAbsolute, $indexOfTroopToDonate)

	  $loopLimit-=1
   WEnd

   ; Done!
   ResetToCoCMainScreen()
EndFunc

Func OpenChatWindow()
   If IsButtonPresent($MainScreenClosedChatButton) = False And _
	  IsButtonPresent($MainScreenOpenChatButton) = False Then Return False

   RandomWeightedClick($MainScreenClosedChatButton)

   ; Wait for OpenChatButton button
   Local $failCount = 10
   While IsButtonPresent($MainScreenOpenChatButton) = False And $failCount>0
	  Sleep(1000)
	  $failCount -= 1
   WEnd

   If $failCount = 0 Then
	  DebugWrite("Donate Troops failed - timeout waiting for open chat window")
	  ResetToCoCMainScreen()
	  Return False
   EndIf

   Return True
EndFunc

Func FindDonateButton(ByRef $button)
   ; Fills $button with absolute screen coords for Donate button
   GrabFrameToFile("ChatFrame.bmp", 9, 103, 266, 551)

   Local $bestMatch = 99, $bestConfidence = 0, $bestX = 0, $bestY = 0
   ScanFrameForBestBMP("ChatFrame.bmp", $DonateButtonBMPs, 0.95, $bestMatch, $bestConfidence, $bestX, $bestY)

   If $bestMatch = 99 Then
	  DebugWrite("Donate button not found.")
	  ResetToCoCMainScreen()
	  Return False
   EndIf

   $button[0] = $bestX+9
   $button[1] = $bestY+103
   $button[2] = $bestX+9+$ChatWindowDonateButton[2]
   $button[3] = $bestY+103+$ChatWindowDonateButton[3]
   $button[4] = 0
   $button[5] = 0
   $button[6] = 0
   $button[7] = 0

   DebugWrite("Donate button found at absolute: " & $button[0] & ", " & $button[1] & ", " _
	  & $button[2] & ", " & $button[3])

   Return True
EndFunc

Func GetRequestText(Const ByRef $button, ByRef $text)
   ; Grab text of donate request
   Local $textOffset[2] = [-68, -25] ; relative to donate button
   Local $donateTextBox[10] = [$button[0]+$textOffset[0], $button[1]+$textOffset[1], _
							   $button[0]+$textOffset[0]+$ChatTextBox[2], $button[1]+$textOffset[1]+$ChatTextBox[3], _
							   $ChatTextBox[4], $ChatTextBox[5], $ChatTextBox[6], _
							   $ChatTextBox[7], $ChatTextBox[8], $ChatTextBox[9]]

   ;DebugWrite("textbox: " & $donateTextBox[0] & " " & $donateTextBox[1] & " " & $donateTextBox[2] & " " & $donateTextBox[3] & " " & _
	;		  Hex($donateTextBox[4]) & " " & $donateTextBox[5] & " " & $donateTextBox[6] & " " & $donateTextBox[7] & " " & _
	;		  $donateTextBox[8] & " " & $donateTextBox[9] )

   $text = ScrapeExactText($chatCharacterMaps, $donateTextBox, 10)
   DebugWrite("Donate text: '" & $text & "'")
EndFunc

Func OpenDonateTroopsWindow(Const ByRef $button)
   Local $topLeftDonateWindow[2] = [$button[0]+67, $button[1]-109]
   Local $colorRegion[4] = [$topLeftDonateWindow[0]+$WindowDonateTroopsColor[0], _
							$topLeftDonateWindow[1]+$WindowDonateTroopsColor[1], _
							$WindowDonateTroopsColor[2], _
							$WindowDonateTroopsColor[3]]

   RandomWeightedClick($button)

   Local $failCount = 10
   While IsColorPresent($colorRegion) = False And $failCount>0
	  Sleep(200)
	  $failCount -= 1
   WEnd

   If $failCount = 0 Then
	  DebugWrite("Donate Troops failed - timeout waiting for donate troops window")
	  ResetToCoCMainScreen()
	  Return False
   EndIf

   DebugWrite("Donate troops window opened.")
   Return True
EndFunc

Func FindDonateTroopSlots(Const ByRef $button, ByRef $index)
   ; Populates index with the absolute screen coords of all available troop donate buttons

   Local $topLeft[2] = [$button[0]+67, $button[1]-109]
   Local $troopWindowAbsolute[4] = [$topLeft[0], $topLeft[1], $topLeft[0]+492, $topLeft[1]+277]

   ; Grab a frame
   GrabFrameToFile("AvailableDonateFrame.bmp", $troopWindowAbsolute[0], $troopWindowAbsolute[1], _
				   $troopWindowAbsolute[2], $troopWindowAbsolute[3])

   For $i = 0 To UBound($gDonateSlotBMPs)-1
	  Local $res = DllCall("ImageMatch.dll", "str", "FindMatch", "str", "AvailableDonateFrame.bmp", "str", "Images\"&$gDonateSlotBMPs[$i], "int", 3)
	  Local $split = StringSplit($res[0], "|", 2) ; x, y, conf

	  If $split[2] > $gConfidenceDonateTroopSlot Then
		 $index[$i][0] = $button[0]+67  + $split[0]
		 $index[$i][1] = $button[1]-109 + $split[1]
		 $index[$i][2] = $button[0]+67  + $split[0]+25
		 $index[$i][3] = $button[1]-109 + $split[1]+45
		 DebugWrite("Troop " & $gDonateSlotBMPs[$i] & " found at " & $index[$i][0] & ", " & $index[$i][1] & " conf: " & $split[2])
	  Else
		 $index[$i][0] = -1
		 $index[$i][1] = -1
		 $index[$i][2] = -1
		 $index[$i][3] = -1
	  EndIf
   Next
EndFunc

Func ParseRequestText(Const ByRef $text, Const ByRef $avail, ByRef $index)
   $index = -1

   ; Is a negative string present, exit now
   For $i = 1 To $gDonateMatchNegativeStrings[0]
	  If StringInStr($text, $gDonateMatchNegativeStrings[$i]) Then
		 DebugWrite("Negative string match, cannot parse negative requests.")
		 Return False
	  EndIf
   Next

   ; Check the specific troop search strings first
   For $i = $eTroopLavaHound To $eTroopBarbarian Step -1 ; Reverse search to fill more costly troops first
	  Local $searchTerms = StringSplit($gDonateMatchTroopStrings[$i], "|")

	  For $j = 1 To $searchTerms[0]
		 If StringInStr($text, $searchTerms[$j]) Then
			If $avail[$i][0]<>-1 Then
			   DebugWrite("String match for: " & $gTroopNames[$i] & ", troop available")
			   $index = $i
			   ExitLoop 2
			Else
			   DebugWrite("String match for: " & $gTroopNames[$i] & ", troop NOT available")
			EndIf
		 EndIf
	  Next
   Next

   ; Check other match terms
   If $index = -1 Then $index = FindMatchingTroop($text, $gDonateMatchAnyStrings, $gDonateMatchAnyTroops, $avail, "Any")
   If $index = -1 Then $index = FindMatchingTroop($text, $gDonateMatchFarmStrings, $gDonateMatchFarmTroops, $avail, "Farm")
   If $index = -1 Then $index = FindMatchingTroop($text, $gDonateMatchGroundStrings, $gDonateMatchGroundTroops, $avail, "Ground")
   If $index = -1 Then $index = FindMatchingTroop($text, $gDonateMatchAirStrings, $gDonateMatchAirTroops, $avail, "Air")

   If $index = -1 Then
	  DebugWrite("Could not find a fill for request, exiting.")
	  ResetToCoCMainScreen()
	  Return False
   EndIf

   DebugWrite("Filling request with " & $gTroopNames[$index])

   Return True
EndFunc

Func FindMatchingTroop(Const $text, Const ByRef $strings, Const ByRef $troops, Const ByRef $avail, Const $type)
   Local $stringMatch = False
   For $i = 1 To $strings[0]
	  If StringInStr($text, $strings[$i]) Then
		 $stringMatch = True
		 ExitLoop
	  EndIf
   Next

   If $stringMatch = False Then Return -1

   DebugWrite("String match for '" & $type & "'")

   For $i = 1 To $troops[0]
	  Local $troopNum = _ArraySearch($gTroopNames, $troops[$i])
	  If $troopNum <> -1 Then
		 If $avail[$troopNum][0]<>-1 Then Return $troopNum
	  EndIf
   Next

   Return -1
EndFunc

Func ClickDonateTroops(Const ByRef $donateIndexAbsolute, Const $indexOfTroopToDonate)

   Local $DonateMaxClicks[16] = [5, 5, 5, 5,   5, 5, 5, 2,   1, 1, 5, 5,   4, 1, 2, 1]

   Local $button[8] = [$donateIndexAbsolute[$indexOfTroopToDonate][0], _
					   $donateIndexAbsolute[$indexOfTroopToDonate][1], _
					   $donateIndexAbsolute[$indexOfTroopToDonate][2], _
					   $donateIndexAbsolute[$indexOfTroopToDonate][3], _
					   0, 0, 0, 0]

   Local $donateCount=0
   For $i = 1 To $DonateMaxClicks[$indexOfTroopToDonate]
	  If IsColorPresent($WindowChatDimmedColor) Then
		 RandomWeightedClick($button)
		 $donateCount+=1
		 Sleep($gDonateTroopClickDelay)
	  EndIf
   Next

   If $donateCount>0 Then
	  DebugWrite("Donated " & $donateCount & " " & $gTroopNames[$indexOfTroopToDonate])
   EndIf
EndFunc

Func QueueDonatableTroops()
   DebugWrite("QueueDonatableTroops()")

   ; See how many troops are built
   Local $troopCounts[$eTroopCount-2]
   CountAvailableTroops($troopCounts)

   For $i = $eTroopBarbarian To $eTroopLavaHound
	  If $gDonateTroopStock[$i] > 0 Then
		 If $troopCounts[$i] < $gDonateTroopStock[$i] Then
			; queue troops
			DebugWrite($gTroopNames[$i] & " stock LOW - built / needed: " & $troopCounts[$i] & " / " & $gDonateTroopStock[$i])

			; find spell queueing window, or last dark barracks
			OpenTrainTroopsWindow()
			If WhereAmI() <> $eScreenTrainTroops Then
			   ResetToCoCMainScreen()
			   Return
			EndIf

			If FindSpellsQueueingWindow() = False Then
			  DebugWrite("Donate, Queue Troops failed - can't find Spells or Dark window")
			  ResetToCoCMainScreen()
			  Return
			EndIf

			; Count queued troops
			CountQueuedTroops($i)

			; Add to queue - standard or dark?
			If $i >= $eTroopBarbarian And $i <= $eTroopPekka Then
			   ;$gDonateBarracksStandardMaximum
			   ;$gDonateBarracksDarkMaximum
			Else
			EndIf

			CloseTrainTroopsWindow()

		 Else
			DebugWrite($gTroopNames[$i] & " stock FULL - built / needed: " & $troopCounts[$i] & " / " & $gDonateTroopStock[$i])
		 EndIf
	  EndIf
   Next

EndFunc

Func CountAvailableTroops(ByRef $troopCounts)
   ;DebugWrite("CountAvailableTroops()")

   ; Locate Army Camp
   Local $bestMatch = 99, $bestConfidence = 0, $bestX = 0, $bestY = 0
   GrabFrameToFile("ArmyCampSearchFrame.bmp")
   ScanFrameForBestBMP("ArmyCampSearchFrame.bmp", $gArmyCampBMPs, $gConfidenceArmyCamp, $bestMatch, $bestConfidence, $bestX, $bestY)

   If $bestMatch = 99 Then
	  DebugWrite("Unable to locate Army Camp.")
	  Return False
   EndIf

   DebugWrite("Located Level " & $bestMatch+6 & " Army Camp at " & $bestX & ", " & $bestY & " conf: " & $bestConfidence)

   ; Select Army Camp
   Local $campButton[8] = [$bestX-8, $bestY-8, $bestX+40, $bestY+40, 0, 0, 0, 0]
   RandomWeightedClick($campButton)

   ; Wait for Army Camp info button
   Local $failCount=10
   Do
	  Sleep(100)
	  $failCount-=1
   Until IsButtonPresent($rArmyCampInfoButton) Or $failCount<=0

   If $failCount<=0 Then
	  DebugWrite("Error getting Army Camp info button.")
	  Return False
   EndIf

   ; Click Army Camp info button
   RandomWeightedClick($rArmyCampInfoButton)

   ; Wait for Army Camp info screen
   Local $failCount=10
   Do
	  Sleep(100)
	  $failCount-=1
   Until IsButtonPresent($rArmyCampInfoScreenCloseWindowButton) Or $failCount<=0

   If $failCount<=0 Then
	  DebugWrite("Error getting Army Camp info screen.")
	  Return False
   EndIf

   ; Get available troops
   Local $troopIndex[UBound($gTroopSlotBMPs)][4]
   FindArmyCampTroopSlots($gCampTroopSlotBMPs, $troopIndex)

   ; Count troops
   For $i = $eTroopBarbarian To $eTroopLavaHound
	  $troopCounts[$i] = GetArmyCampTroops($i, $troopIndex)
   Next

   ; Close Army Camp info screen
   ResetToCoCMainScreen()

EndFunc

Func CountQueuedTroops(Const $troopIndex)
   DebugWrite("CountQueuedTroops()")

   Local $type, $numBarracks
   If $troopIndex >= $eTroopBarbarian And $troopIndex <= $eTroopPekka Then
	  $type = "Standard"
	  $numBarracks = 4
   Else
	  $type = "Dark"
	  $numBarracks = 2
   EndIf

   ; Loop through barracks and count specified troops, until we get back to the spells screen

#cs
   Local $barracksCount = 1
   Local $failCount = 5

   While $barracksCount <= 4 And $failCount>0

	  ; Click right arrow to get the next standard troops window
	  RandomWeightedClick($TrainTroopsWindowNextButton)
	  Sleep(500)
	  $failCount-=1

	  ; Make sure we are on a standard troops window
	  If IsColorPresent($WindowTrainTroopsStandardColor1) = False And IsColorPresent($WindowTrainTroopsStandardColor2) = False Then
		 ;DebugWrite(" Not on Standard Troops Window: " & Hex($pixelColor1) & "/" & Hex($WindowTrainTroopsStandardColor1[2])& _
			;"  " & Hex($pixelColor2) & "/" & Hex($WindowTrainTroopsStandardColor2[2]))
		 ExitLoop
	  EndIf

	  ; If we have not yet figured out troop costs, then get them now
	  If $gMyTroopCost[$eTroopBarbarian] = 0 Then
		 $gMyTroopCost[$eTroopBarbarian] = ScrapeFuzzyText($smallCharacterMaps, $rTrainTroopsWindowBarbarianCostTextBox)
		 $gMyTroopCost[$eTroopArcher] = ScrapeFuzzyText($smallCharacterMaps, $rTrainTroopsWindowArcherCostTextBox)
		 $gMyTroopCost[$eTroopGoblin]= ScrapeFuzzyText($smallCharacterMaps, $rTrainTroopsWindowGoblinCostTextBox)
		 $gMyTroopCost[$eTroopGiant] = ScrapeFuzzyText($smallCharacterMaps, $rTrainTroopsWindowGiantCostTextBox)
		 $gMyTroopCost[$eTroopWallBreaker] = ScrapeFuzzyText($smallCharacterMaps, $rTrainTroopsWindowWallBreakerCostTextBox)
		 $gMyTroopCost[$eTroopBalloon] = ScrapeFuzzyText($smallCharacterMaps, $rTrainTroopsWindowBalloonCostTextBox)
		 $gMyTroopCost[$eTroopWizard] = ScrapeFuzzyText($smallCharacterMaps, $rTrainTroopsWindowWizardCostTextBox)
		 $gMyTroopCost[$eTroopHealer] = ScrapeFuzzyText($smallCharacterMaps, $rTrainTroopsWindowHealerCostTextBox)
		 $gMyTroopCost[$eTroopDragon] = ScrapeFuzzyText($smallCharacterMaps, $rTrainTroopsWindowDragonCostTextBox)
		 $gMyTroopCost[$eTroopPekka] = ScrapeFuzzyText($smallCharacterMaps, $rTrainTroopsWindowPekkaCostTextBox)
	  EndIf

	  ; If this is an initial fill and we need to queue breakers, then clear all the queued troops in this barracks
	  If $initialFillFlag=True And _GUICtrlButton_GetCheck($GUI_AutoRaidUseBreakers) = $BST_CHECKED Then
		 Local $dequeueTries = 6
		 While IsButtonPresent($TrainTroopsWindowDequeueButton) And $dequeueTries>0 And _GUICtrlButton_GetCheck($GUI_AutoRaidCheckBox)=$BST_CHECKED
			Local $xClick, $yClick
			RandomWeightedCoords($TrainTroopsWindowDequeueButton, $xClick, $yClick)
			_ClickHold($xClick, $yClick, 4000)
			$dequeueTries-=1
			Sleep(500)
		 WEnd
	  EndIf

	  If _GUICtrlButton_GetCheck($GUI_AutoRaidCheckBox)=$BST_UNCHECKED Then Return

	  ; If breakers are included and this is an initial fill then queue up breakercount/4 in each barracks
	  If _GUICtrlButton_GetCheck($GUI_AutoRaidUseBreakers) = $BST_CHECKED And $initialFillFlag Then
		 For $i = 1 To Int(Number(GUICtrlRead($GUI_AutoRaidBreakerCountEdit))/4)
			RandomWeightedClick($TrainTroopsWindowBreakerButton)
			Sleep(500)
		 Next
	  EndIf

	  ; Fill up this barracks
	  Local $fillTries=1
	  Local $troopsToFill
	  Do
		 ; Get number of troops already queued in this barracks
		 Local $queueStatus = ScrapeFuzzyText($largeCharacterMaps, $rTrainTroopsWindowTextBox)

		 If (StringInStr($queueStatus, "Train")=1) Then
			$queueStatus = StringMid($queueStatus, 6)

			Local $queueStatSplit = StringSplit($queueStatus, "/")
			If $queueStatSplit[0] = 2 Then
			   $troopsToFill = Number($queueStatSplit[2]) - Number($queueStatSplit[1])

			   ; How long to click and hold?
			   Local $fillTime
			   If $troopsToFill>60 Then
				  $fillTime = 3500 + Random(-250, 250, 1)
			   ElseIf $troopsToFill>25 Then
				  $fillTime = 2700 + Random(-250, 250, 1)
			   ElseIf $troopsToFill>10 Then
				  $fillTime = 2300 + Random(-250, 250, 1)
			   Else
				  $fillTime = 1800 + Random(-250, 250, 1)
			   EndIf

			   ; Click and hold to fill up queue
			   If $troopsToFill>0 Then
				  Local $xClick, $yClick
				  If $barracksCount/2 = Int($barracksCount/2) Then ; Alternate between archers and barbs
					 RandomWeightedCoords($TrainTroopsWindowBarbarianButton, $xClick, $yClick)
				  Else
					 RandomWeightedCoords($TrainTroopsWindowArcherButton, $xClick, $yClick)
				  EndIf

				  ;DebugWrite("Filling barracks " & $barracksCount & " try " & $fillTries)
				  _ClickHold($xClick, $yClick, $fillTime)
				  Sleep(500)
			   EndIf
			EndIf
		 EndIf

		 $fillTries+=1
	  Until $troopsToFill=0 Or $fillTries>=6 Or _GUICtrlButton_GetCheck($GUI_AutoRaidCheckBox)=$BST_UNCHECKED

	  $barracksCount+=1
   WEnd
#ce
EndFunc

Func FindArmyCampTroopSlots(Const ByRef $bitmaps, ByRef $index)
   ; Populates index with the absolute screen coords of all available troop buttons
   Local $buttonOffset[4] = [0, -0, 51, 69]
   Local $armyCampTroopBox[4] = [291, 287, 753, 331]

   GrabFrameToFile("AvailableRaidTroopsFrame.bmp", $armyCampTroopBox[0], $armyCampTroopBox[1], $armyCampTroopBox[2], $armyCampTroopBox[3])

   For $i = 0 To UBound($bitmaps)-1
	  Local $res = DllCall("ImageMatch.dll", "str", "FindMatch", "str", "AvailableRaidTroopsFrame.bmp", "str", "Images\"&$bitmaps[$i], "int", 3)
	  Local $split = StringSplit($res[0], "|", 2) ; x, y, conf

	  If $split[2] > $gConfidenceArmyCampTroopSlot Then
		 $index[$i][0] = $split[0]+$armyCampTroopBox[0]+$buttonOffset[0]
		 $index[$i][1] = $split[1]+$armyCampTroopBox[1]+$buttonOffset[1]
		 $index[$i][2] = $split[0]+$armyCampTroopBox[0]+$buttonOffset[2]
		 $index[$i][3] = $split[1]+$armyCampTroopBox[1]+$buttonOffset[3]
		 DebugWrite("Troop " & $bitmaps[$i] & " found at " & $index[$i][0] & ", " & $index[$i][1] & " conf: " & $split[2])
	  Else
		 $index[$i][0] = -1
		 $index[$i][1] = -1
		 $index[$i][2] = -1
		 $index[$i][3] = -1
	  EndIf
   Next
EndFunc

Func GetArmyCampTroops(Const $troop, Const ByRef $index)
   If $index[$troop][0] = -1 Then Return -1

   Local $textBox[10] = [$index[$troop][0]+16, $index[$troop][1]+54, $index[$troop][0]+50, $index[$troop][1]+63, _
						 $rTroopSlotCountTextBox[4], $rTroopSlotCountTextBox[5], _
						 0, 0, 0, 0]

   Local $t = ScrapeFuzzyText($gArmyCampCharacterMaps, $textBox)

   Return $t
EndFunc

