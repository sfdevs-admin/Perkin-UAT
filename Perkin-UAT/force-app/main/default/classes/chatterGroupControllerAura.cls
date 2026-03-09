/**
*   Description     :   Controller to return chatter group for Dealers
*   Created by      :   Amiya Das
*   Created Date    :   11th Nov 2020
*/ 

public with sharing class chatterGroupControllerAura {
   
    /* public chatterGroupControllerAura() {
     } */
     
     // get list of chatter groups
     @AuraEnabled(cacheable=true)
     public static list<CollaborationGroup> getChatterGroups(){
         
        /* list<User> commUserList = [select id, Name, IsPortalEnabled FROM User WHERE 
                                    Profile.UserLicense.Name = 'Partner Community']; */
  
         list<CollaborationGroup> chatterGroups = [select Id, Name from CollaborationGroup where Id in (select 
                                                    CollaborationGroupId from CollaborationGroupMember where 
                                                    MemberId =: UserInfo.getUserId())];
 
         system.debug('groups : ' +chatterGroups);
         return chatterGroups;
     }
 }