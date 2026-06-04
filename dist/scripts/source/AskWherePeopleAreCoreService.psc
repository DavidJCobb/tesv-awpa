Scriptname AskWherePeopleAreCoreService extends Quest Hidden

FormList Property AskWherePeopleAreContentQuests Auto
Actor Property PlayerRef Auto

AskWherePeopleAreContentQuestBase _current_location_quest

Bool _do_init_on_update        = False
Bool _do_loc_refresh_on_update = False

; Per-session state:
Bool _has_warned_about_form_list_size = False

Event OnInit()
   _do_init_on_update = True
   RegisterForSingleUpdate(3.0)
EndEvent

Event OnUpdate()
   Bool bRefreshPlayerLoc = False
   
   If _do_init_on_update
      _do_init_on_update = False
      ;/
         OnInit, we want to start the quest for whatever location the player is 
         in, so that if the user installs the mod mid-playthrough or COCs from 
         the main menu to a relevant location, they can immediately ask where 
         people are. However, doing this in OnInit doesn't work for COCing from 
         the main menu. I don't know why offhand; maybe the per-location quests 
         aren't initialized yet, or maybe the player's current Location isn't 
         being tracked yet.
         
         In any case, using OnUpdate to carry out a brief delay, and doing this 
         post-init, should work.
      /;
      bRefreshPlayerLoc = True
   EndIf
   If _do_loc_refresh_on_update
      _do_loc_refresh_on_update = False
      bRefreshPlayerLoc         = True
   EndIf
   
   If bRefreshPlayerLoc
      Self.OnPlayerLocationChange(PlayerRef.GetCurrentLocation())
   EndIf
EndEvent

AskWherePeopleAreContentQuestBase[] Function _ContentQuestsAsArray()
   AskWherePeopleAreContentQuestBase[] kArray
   
   Int iSize = AskWherePeopleAreContentQuests.GetSize()
   If iSize <= 16
      kArray = new AskWherePeopleAreContentQuestBase[16]
   ElseIf iSize <= 20
      kArray = new AskWherePeopleAreContentQuestBase[20]
   ElseIf iSize <= 24
      kArray = new AskWherePeopleAreContentQuestBase[24]
   ElseIf iSize <= 32
      kArray = new AskWherePeopleAreContentQuestBase[32]
   ElseIf iSize <= 64
      kArray = new AskWherePeopleAreContentQuestBase[64]
   Else
      kArray = new AskWherePeopleAreContentQuestBase[128]
      If !_has_warned_about_form_list_size && iSize > 128
         _has_warned_about_form_list_size = True
         Debug.Trace("[Ask Where People Are] FormList `AskWherePeopleAreContentQuests` has more than 128 elements; we will only iterate the first 128. (Who filled the list with that much junk?)", 1)
      EndIf
   EndIf
   
   Int iSrc = 0
   Int iDst = 0
   While iSrc < iSize
      AskWherePeopleAreContentQuestBase kCurrent = AskWherePeopleAreContentQuests.GetAt(iSrc) as AskWherePeopleAreContentQuestBase
      If kCurrent
         kArray[iDst] = kCurrent
         iDst = iDst + 1
      EndIf
      iSrc = iSrc + 1
   EndWhile
   
   Return kArray
EndFunction

; Prevent/manage concurrent execution of `OnPlayerLocationChange`.
;
; These vars are checked and set at the start of the function. They get reset by 
; the `_OnPlayerLocationChange_Epilogue` function (which is called whenever the 
; `OnPlayerLocationChange` function exits).
Bool _processing_loc_change = False ; lock
Bool _loc_changes_stacked   = False ; queue a re-do if we're called again while locked

; Called by our player alias.
Function OnPlayerLocationChange(Location akCurrentLocation)
   If _processing_loc_change
      _loc_changes_stacked = True
      Return
   EndIf
   _processing_loc_change = True
   
   Int iCurrent = 0
   If !akCurrentLocation
      ;
      ; Fast path for if the player is no longer in any Location: halt all 
      ; content quests.
      ;
      ; (Further below is an optimization that entails unpacking this 
      ; FormList to an array. We forego that optimization here because we 
      ; will be iterating the list contents exactly once; the optimization 
      ; only helps us if we're iterating the list multiple times.)
      ;
      Int iSize = AskWherePeopleAreContentQuests.GetSize()
      While iCurrent < iSize
         Quest kCurrent = AskWherePeopleAreContentQuests.GetAt(iCurrent) as Quest
         If kCurrent
            kCurrent.Stop()
         EndIf
         iCurrent = iCurrent + 1
      EndWhile
      _current_location_quest = None
      
      _OnPlayerLocationChange_Epilogue()
      Return
   EndIf
   
   ;
   ; This may be premature optimization. We'll see, I suppose.
   ;
   ; Accessing FormList elements requires a function call per element access, 
   ; and the functions in question are standard (as opposed to non-delayed) 
   ; native functions; ergo they synch with the frame rate, and will thus 
   ; always take at least one frame to run.
   ;
   ; See remarks by Bethesda Game Studios developers:
   ; <https://web.archive.org/web/20200217020409/http://forums.bethsoft.com/topic/1373784-papyrus-threading-alternative-techniques/#entry21629276>
   ; <https://ck.uesp.net/w/index.php?title=Category:Non-delayed_Native_Function&oldid=5209>
   ;
   ; We want to be able to loop over the FormList multiple times, so let's 
   ; unpack the FormList into a Papyrus array. We'll incur the overhead of 
   ; those function calls up-front, but only once per list item; subsequent 
   ; accesses will go through the array and thus be "free."
   ;
   AskWherePeopleAreContentQuestBase[] kContentQuests = _ContentQuestsAsArray()
   Int iSize = kContentQuests.RFind(None)
   If iSize < 0
      iSize = kContentQuests.Length
   EndIf
   ;
   ; With that prep done, now we need to find the quest to start (if any) 
   ; and shut down any other AWPA content quests that are running.
   ;
   AskWherePeopleAreContentQuestBase kQuestToStart
   ;
   ; First, try a shortcut: see if any content quest pertains to the exact 
   ; Location that the player has entered. This loop avoids calls to any 
   ; external non-delayed functions; if you're in an outdoor Location for 
   ; a city, e.g. RiftenLocation, this will find the relevant quest as 
   ; fast as possible.
   ;
   ; In the same spirit as the optimization above, we avoid function calls 
   ; (`Array::Find` and `Array::RFind` use call syntax but are compiled to 
   ; single opcodes).
   ;
   While iCurrent < iSize
      AskWherePeopleAreContentQuestBase kCurrent = kContentQuests[iCurrent]
      If kCurrent.pkLocations.Find(akCurrentLocation) >= 0
         kQuestToStart = kCurrent
         iCurrent = iSize
      EndIf
      iCurrent = iCurrent + 1
   EndWhile
   If !kQuestToStart
      ;
      ; The shortcut didn't turn anything up, so now try the more intensive 
      ; check to see if any content quest pertains to an ancestor Location 
      ; of the Location the player has entered. This means we'll be making 
      ; a lot of calls to `Location::IsChild`, a native function that IS 
      ; NOT flagged as "non-delayed."
      ;
      ; (Strange that it isn't, really. The location hierarchy should never 
      ; change during play, so threading and frame sync shouldn't have been 
      ; relevant concerns. Maybe Bethesda just chose to be conservative 
      ; about where they used that flag.)
      ;
      iCurrent = 0
      While iCurrent < iSize
         AskWherePeopleAreContentQuestBase kCurrent = kContentQuests[iCurrent]
         
         Location[] kLocList  = kCurrent.pkLocations
         Int        iLocation = 0
         Int        iLocCount = kLocList.Length
         While iLocation < iLocCount
            If akCurrentLocation.IsChild(kLocList[iLocation])
               kQuestToStart = kCurrent
               iLocation     = iLocCount
               iCurrent      = iSize
            EndIf
            iLocation = iLocation + 1
         EndWhile
         
         iCurrent = iCurrent + 1
      EndWhile
   EndIf
   If kQuestToStart != _current_location_quest
      ;
      ; We've determined what content quest, if any, pertains to the player's 
      ; current Location, so now let's switch to it.
      ;
      iCurrent = 0
      If !kQuestToStart
         While iCurrent < iSize
            kContentQuests[iCurrent].Stop()
            iCurrent = iCurrent + 1
         EndWhile
         _current_location_quest = None
      Else
         While iCurrent < iSize
            AskWherePeopleAreContentQuestBase kCurrent = kContentQuests[iCurrent]
            If kCurrent != kQuestToStart
               kCurrent.Stop()
            EndIf
            iCurrent = iCurrent + 1
         EndWhile
         _current_location_quest = kQuestToStart
         kQuestToStart.Start()
      EndIf
   EndIf
   
   _OnPlayerLocationChange_Epilogue()
EndFunction
Function _OnPlayerLocationChange_Epilogue()
   _processing_loc_change = False
   If _loc_changes_stacked
      _loc_changes_stacked = False
      If !_do_loc_refresh_on_update
         _do_loc_refresh_on_update = True
         Self.RegisterForSingleUpdate(1.0)
      EndIf
   EndIf
EndFunction

Function OnPlayerLoadGame()
   ; Reset per-session state:
   _has_warned_about_form_list_size = False

   If _do_init_on_update
      Return
   EndIf
   Self.OnPlayerLocationChange(PlayerRef.GetCurrentLocation())
EndFunction
