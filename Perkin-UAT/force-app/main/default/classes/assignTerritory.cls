public class assignTerritory{
public void assignTerritoryopp(list<opportunity> oppLI){
set<Id> accountIds=new set<Id>();
set<Id> terIds=new set<Id>();

for(opportunity op: oppLI){accountIds.add(op.AccountId);
}
// Get the active territory model Id
        Id activeModelId = getActiveModelId();
system.debug('---modelId '+activeModelId);
for(ObjectTerritory2Association ota:[Select ObjectId, Territory2Id, Territory2.Territory2Type.Priority from ObjectTerritory2Association where objectId IN :accountIds and Territory2.Territory2ModelId = :activeModelId]){terIds.add(ota.Territory2Id);
}
system.debug('---terIdsAccount '+terIds);
list<UserTerritory2Association> usT2=new list<UserTerritory2Association>([Select ID, UserId,Territory2Id from UserTerritory2Association where UserId=:UserInfo.getUserId() and Territory2Id in: terIds]);system.debug('---ust '+usT2.size()+'--'+usT2);
if(usT2.size()>0){if(usT2.size()==1){for(opportunity op:oppLI ){op.Territory2Id=usT2[0].Territory2Id;
}

}
}

}
private Id getActiveModelId() {
List<Territory2Model> models = [Select Id from Territory2Model where State = 'Active'];
      Id activeModelId;
        if(models.size() == 1){
            activeModelId = models.get(0).Id;
        }
return activeModelId;
    }

}