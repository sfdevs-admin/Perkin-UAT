public class PKI_QUEUE_ManageGroupController {
    @InvocableMethod(label='Insert Group' description='Inserts the Group specified and returns the IDs of the new Group.' category= 'Group')
    public static List<ID> insertGroups(List<FlowInputs> request) {
       // system.debug('request$$$>'+request);
        Database.SaveResult result = Database.insert(request[0].Groups);
        List<Id> GroupIds = new List<ID>();
        if (result.isSuccess()) {
            GroupIds.add(result.getId());
        }
        List<string> sobjectstrlist;
        // system.debug('request[0].varSobjcttype=='+request[0].varSobjcttype);
        if(request[0].varSobjcttype != null && !String.isBlank(request[0].varSobjcttype)){
            sobjectstrlist =request[0].varSobjcttype.split(';');
        }
        if(sobjectstrlist != null && !sobjectstrlist.isEmpty()){
            list<QueueSobject> objlist= new List<QueueSobject>();
            for(string str:sobjectstrlist){
                QueueSobject obj= new QueueSobject();
                obj.SobjectType=str;
                obj.QueueId=GroupIds[0];
                objlist.add(obj);
            }
            if(!objlist.isEmpty())
                insert objlist;
        }
        
        return GroupIds;
    }
    public class FlowInputs{
        
        @InvocableVariable
        public Group Groups;
        
        @InvocableVariable
        public String varSobjcttype;
        
    }
    
}