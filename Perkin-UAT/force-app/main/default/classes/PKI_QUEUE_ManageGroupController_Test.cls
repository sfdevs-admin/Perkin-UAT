@isTest
public class PKI_QUEUE_ManageGroupController_Test {
    @testSetup static void setup() {
      //Creating Group
        Group testGroup = new Group(Name='QUEUE NAME', Type='Queue');
        insert testGroup;
        
        //Creating QUEUE
        System.runAs(new User(Id=UserInfo.getUserId()))
        {
            //Associating queue with group AND to the Case object
            QueuesObject testQueue = new QueueSObject(QueueID = testGroup.id, SObjectType = 'Interaction__c');
            insert testQueue;
        }  
    }
    static testMethod void MethodforQueue(){
        List<PKI_QUEUE_ManageGroupController.FlowInputs> listRequest =new List<PKI_QUEUE_ManageGroupController.FlowInputs>();
        PKI_QUEUE_ManageGroupController.FlowInputs req = new PKI_QUEUE_ManageGroupController.FlowInputs();
        Group testGroup = new Group(Name='QUEUE NAME', Type='Queue');
        req.Groups=testGroup;
        req.varSobjcttype='Interaction__c';
        listRequest.add(req);
        PKI_QUEUE_ManageGroupController.insertGroups(listRequest);
        General_Bypass_Pause_Event.createNewtransaction();
    }
}