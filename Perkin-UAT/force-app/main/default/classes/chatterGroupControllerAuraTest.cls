/**
*   Description     :   Test class for 'chatterGroupControllerAura'
*   Created by      :   Amiya Das
*   Created Date    :   23rd Nov 2020
*/ 
@isTest
public with sharing class chatterGroupControllerAuraTest {

    public static testmethod void testgetChatterGroups(){

        CollaborationGroup objCollaborationGroup1 = new CollaborationGroup();

        objCollaborationGroup1.Name = 'My Chatter Groups';
        objCollaborationGroup1.CollaborationType = 'Public';

        insert objCollaborationGroup1;
        system.assert(objCollaborationGroup1.Id != null);

        test.startTest();
        chatterGroupControllerAura.getChatterGroups();
        test.stopTest();
    }
    
}