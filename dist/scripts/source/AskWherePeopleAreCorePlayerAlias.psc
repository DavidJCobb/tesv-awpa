Scriptname AskWherePeopleAreCorePlayerAlias extends ReferenceAlias Hidden

AskWherePeopleAreCoreService Property AWPACoreSvc Auto

Event OnLocationChange(Location akPrior, Location akAfter)
   AWPACoreSvc.OnPlayerLocationChange(akAfter)
EndEvent

Event OnPlayerLoadGame()
   AWPACoreSvc.OnPlayerLoadGame()
EndEvent
