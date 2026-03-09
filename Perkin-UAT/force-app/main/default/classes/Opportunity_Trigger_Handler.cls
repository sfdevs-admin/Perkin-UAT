public class Opportunity_Trigger_Handler {
    public static boolean isRun = true;
    public static Id opportunity_Informatics = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Informatics').getRecordTypeId();
    public static Set<String> setofProductName = new Set<String> {'Subscription','Term','Maintenance','Perpetual Maintenance','SaaS','PaaS','Term Maintenance'}; 
    public static String [] Stages = new List <String>{'Zero Stage','Stage 1 - Create/Plan','Stage 2 - Qualify','Stage 3 - Develop','Stage 4 - Prove','Stage 5 - Negotiation','Abandoned','Closed Lost','Closed Won'};
        
    public static void beforeTriggerMethod(List<Opportunity> listofnewOpp, Map<Id, Opportunity> mapofOldOpp, Boolean isInsert, Boolean isUpdate){
        Set<Id> setofOppId = new Set<Id>();
        Set<Id> setofInfaOppId = new Set<Id>();
        Set<Id> setofAccId = new Set<Id>();
        List<Contact> listofContactUpdate = new List<Contact>();
        List<Contact> listofContactOwnerUpdate = new List<Contact>(); 
        List<Contact> listofContactSAI = new List<Contact>();
        List<OpportunityLineItem> listOppLine = new List<OpportunityLineItem>();
        Map<Id, String> mapofContactToOwner = new Map<Id,String>();
        Map<Id, String> mapofContactToOwnerManager = new Map<Id,String>();
        Map<Id, String> mapofContactRolesToSAI = new Map<Id,String>();
        Map<Id, Account> mapofOppAccount;
        Map<Id, Pricebook2> mapofPricebook;
        Map<Id, Opportunity> mapofStageOpp = new Map<Id, Opportunity>();
        Map<Id, OpportunityContactRole> mapofContactRoles = new Map<Id,OpportunityContactRole>();
        
        if(isUpdate)
            mapofPricebook = new Map<Id, Pricebook2>([SELECT Id, Name FROM Pricebook2 WHERE Name like '%Informatics%']);
        
        for(Opportunity iterOpp : listofnewOpp){
            setofOppId.add(iterOpp.Id);
            if(iterOpp.RecordTypeId == opportunity_Informatics){
                setofInfaOppId.add(iterOpp.Id);   
                
                if(iterOpp.Type != 'Renewal'){
                    setofAccId.add(iterOpp.AccountId);
                }
                
                if(mapofPricebook!= null && !mapofPricebook.isEmpty() && mapofPricebook.get(iterOpp.Pricebook2Id) != null){
                    if(mapofPricebook.get(iterOpp.Pricebook2Id).Name == 'Informatics Government'){
                        iterOpp.Account_Type_INF__c = 'Government';
                    } else if(mapofPricebook.get(iterOpp.Pricebook2Id).Name == 'Informatics Academic'){
                        iterOpp.Account_Type_INF__c = 'Academic';
                    } else{
                        iterOpp.Account_Type_INF__c = 'Commercial';
                    }
                }
            }
            
            if(Stages.contains(iterOpp.StageName)){
               mapofStageOpp.put(iterOpp.Id, iterOpp);
            }
        }   
        
        if(isInsert && setofAccId.size() > 0){
            mapofOppAccount = new Map<Id, Account>([SELECT Id, Name FROM Account WHERE Id IN: setofAccId]);
        }
        
        if(setofOppId.size() > 0){
            Map<Id, Opportunity> mapofOpportunity = new Map<Id, Opportunity>([SELECT Id, Name, RecordTypeId, CloseDate, AccountId, Account.Name, Type, ContactId, Owner.Name, First_Owner_Changed__c, StageName, Owner.ManagerId, Owner.Manager.Email,
                                                   (Select Type_INF__c, PricebookEntry.Product2.License_Type_INF__c, PricebookEntry.Product2.Product_Type_INF__c, PricebookEntry.Product2.Name, PricebookEntry.Product2.Product_Line__c, Start_Date_INF__c, Product_Status__c, Product_Line__c,Quantity,
                                                   Product_Family__c, OpportunityId, Id, End_Date_INF__c,PricebookEntryId,UnitPrice,Product_Name_INF__c From OpportunityLineItems),
                                                   (Select ContactId, CreatedDate, OpportunityId, Opportunity.Solution_Area_of_Interest__c From OpportunityContactRoles where OpportunityId IN:mapofStageOpp.keySet() AND Opportunity.Solution_Area_of_Interest__c != null)
                                                   FROM Opportunity WHERE Id IN: setofOppId]);
            
            for(Opportunity iterOpp : listofnewOpp){
                if(isInsert && mapofOppAccount != null && !mapofOppAccount.isEmpty()){
                    iterOpp.Opportunity_Alias_INF__c = 'INF_'+mapofOppAccount.get(iterOpp.AccountId).Name + '_' +iterOpp.CloseDate.month()+'/'+iterOpp.CloseDate.year();
                }
                //LDR_Owner_Change
                if(isUpdate && !mapofOpportunity.isEmpty() && iterOpp.StageName == 'Zero Stage' && iterOpp.OwnerId != mapofOldOpp.get(iterOpp.Id).OwnerId && iterOpp.ContactId != null){ 
                    iterOpp.First_Owner_Changed__c = true;
                    mapofContactToOwner.put(mapofOpportunity.get(iterOpp.Id).ContactId, mapofOpportunity.get(iterOpp.Id).Owner.Name);
                }
                //LDR_Owner_Converison
                if(!mapofOpportunity.isEmpty() && iterOpp.StageName == 'Zero Stage'){
                    if(mapofOpportunity.get(iterOpp.Id).Owner.managerId != null)
                        iterOpp.OwnerManager__c = mapofOpportunity.get(iterOpp.Id).Owner.manager.Email;
                    else
                        iterOpp.OwnerManager__c = 'Toby.OConnor@PERKINELMER.COM';
                    mapofContactToOwnerManager.put(mapofOpportunity.get(iterOpp.Id).ContactId, mapofOpportunity.get(iterOpp.Id).Owner.Name);
                }
                
                if(isUpdate && !mapofOpportunity.isEmpty() && iterOpp.RecordTypeId == opportunity_Informatics && mapofOpportunity.get(iterOpp.Id).OpportunityLineItems != null && mapofOpportunity.get(iterOpp.Id).OpportunityLineItems.size() > 0 && iterOpp.StageName == 'Stage 6 - Implement (Closed)' && (iterOpp.StageName!=mapofOldOpp.get(iterOpp.Id).StageName)){
                    for(OpportunityLineItem oppLitem:mapofOpportunity.get(iterOpp.Id).OpportunityLineItems){ 
                        if((oppLitem.PricebookEntry.Product2.License_Type_INF__c.contains('Subscription') ||oppLitem.PricebookEntry.Product2.License_Type_INF__c.contains('Maintenance')||oppLitem.PricebookEntry.Product2.License_Type_INF__c.contains('Term')) && (oppLitem.End_Date_INF__c == NULL ||oppLitem.Start_Date_INF__c == NULL)){
                            iterOpp.addError('Enter the START DATE and END DATE for SUBSCRIPTION, MAINTENANCE and TERM products to submit order');
                        }
                        //Order Processing Status
                        if(oppLitem.PricebookEntry.Product2.License_Type_INF__c == 'Services' || oppLitem.PricebookEntry.Product2.Product_Type_INF__c == 'Services'){
                            iterOpp.Order_Processing_Status_INF__c = 'Revenue Review Required';
                        }
                        //Order Processing Status
                        if(oppLitem.PricebookEntry.Product2.Name == 'OneSource LABIT' || oppLitem.PricebookEntry.Product2.Product_Line__c == 'OMV'){
                            iterOpp.Order_Processing_Status_INF__c = 'Submitted';
                            iterOpp.GP_OrderNum_INF__c = '#';
                        }
                    }
                }
                if(isUpdate && !mapofOpportunity.isEmpty() && iterOpp.RecordTypeId == opportunity_Informatics && iterOpp.StageName == 'Closed Won'){
                    if(mapofOpportunity.get(iterOpp.Id).OpportunityLineItems != null && mapofOpportunity.get(iterOpp.Id).OpportunityLineItems.size() > 0){ 
                        for(OpportunityLineItem ioppLine : mapofOpportunity.get(iterOpp.Id).OpportunityLineItems){
                            if(ioppLine.PricebookEntry.Product2.License_Type_INF__c == 'Perpetual'){
                                ioppLine.Start_Date_INF__c=Date.today();
                                ioppLine.End_Date_INF__c = null;
                                listOppLine.add(ioppLine);
                            }
                        }
                    }
                }
                //CheckContactRoleAndSAI
                if(!mapofOpportunity.isEmpty() && mapofOpportunity.get(iterOpp.Id).OpportunityContactRoles != null && mapofOpportunity.get(iterOpp.Id).OpportunityContactRoles.size() > 0){
                    for(OpportunityContactRole iContactRoles : mapofOpportunity.get(iterOpp.Id).OpportunityContactRoles){
                        if((isInsert || iContactRoles.CreatedDate == Date.Today()) || (isUpdate || iContactRoles.Opportunity.Solution_Area_of_Interest__c != mapofOldOpp.get(iterOpp.Id).Solution_Area_of_Interest__c)){
                            mapofContactRolesToSAI.put(iContactRoles.Id, iContactRoles.Opportunity.Solution_Area_of_Interest__c);
                            mapofContactRoles.put(iContactRoles.Id, iContactRoles);
                        }
                    }                    
                }
            }
            if(!mapofContactToOwner.isEmpty()){                
                for(Contact iterContact : [SELECT Id, Name, Lead_Owner_Sales__c FROM Contact WHERE Id IN: mapofContactToOwner.keySet()]){
                    iterContact.Lead_Owner_Sales__c = mapofContactToOwner.get(iterContact.Id);
                    listofContactUpdate.add(iterContact);
                }
                if(listofContactUpdate.size() > 0){
                    update listofContactUpdate;
                }
            }
            if(!mapofContactToOwnerManager.isEmpty()){                
                for(Contact iterContact : [SELECT Id, Name, Lead_Owner_Sales__c FROM Contact WHERE Id IN: mapofContactToOwnerManager.keySet() and Lead_Owner_LDR_Conversion__c = null]){
                    iterContact.Lead_Owner_LDR_Conversion__c = mapofContactToOwnerManager.get(iterContact.Id);
                    listofContactOwnerUpdate.add(iterContact);
                }
                if(listofContactOwnerUpdate.size() > 0){
                    update listofContactOwnerUpdate;
                }
            }
            if(listOppLine.size() > 0){
                update listOppLine;
            }
        }
        //CheckContactRoleAndSAI
        if(!mapofContactRolesToSAI.isEmpty() && !mapofContactRoles.isEmpty()){
            List<Opportunity_SAI_Mapping__mdt> listOppCustMdt = [SELECT Id, Opportunity_SAI_Value__c,Contact_SAI_Status_API_Name__c FROM Opportunity_SAI_Mapping__mdt WHERE Opportunity_SAI_Value__c IN :mapofContactRolesToSAI.Values()]; 
            if(listOppCustMdt != null && listOppCustMdt.size() > 0){
                for(OpportunityContactRole a : mapofContactRoles.values()){
                    for(Opportunity_SAI_Mapping__mdt imdt : listOppCustMdt){
                        if(a.Opportunity.Solution_Area_of_Interest__c == imdt.Opportunity_SAI_Value__c){
                            Contact conObj = new Contact();
                            conObj.id = a.ContactId;
                            conObj.Has_Opportunity__c = true;
                            conObj.put(imdt.Contact_SAI_Status_API_Name__c , 'Converted to Opportunity'); 
                            listofContactSAI.add(conObj);
                        }
                    }
                }
            }
        }
        if(listofContactSAI.size() > 0){
            Map<Id,Contact> contactMaptoUpdate = new Map<Id,Contact>();
            contactMaptoUpdate.putall(listofContactSAI);
            if(contactMaptoUpdate.size() > 0)                        
                update contactMaptoUpdate.values();  
        }
    }
    public static void afterTriggerMethod(List<Opportunity> listofnewOpp, Map<Id, Opportunity> mapofOldOpp, Boolean isInsert, Boolean isUpdate){
        Set<Id> setofInfaOppId = new Set<Id>();
        List<Asset> listAssetNonrenew = new List<Asset>();
        List<Asset> listAssetInsert = new List<Asset>();
        List<Asset> listAssetRenew = new List<Asset>();
        List<opportunity> listOfoppInsert = new List<Opportunity>();
        List<Task> renewaltasks = new List<Task>();
        List<OpportunityLineItem> listOppLineInsert = new List<OpportunityLineItem>();
        List<OpportunityContactRole> listOppContactRole = new List<OpportunityContactRole>();
        Map<Id, Opportunity> mapofOpportunity;
        Map<Id,List<OpportunityContactRole>> mapOfOppToOppContactRoles = new Map<Id,List<OpportunityContactRole>>();
        Map<Id,List<OpportunityLineItem>> mapOfOppToOppLineItems = new Map<Id,List<OpportunityLineItem>>();
        
        for(Opportunity iterOpp : listofnewOpp){
            if(iterOpp.RecordTypeId == opportunity_Informatics){
                setofInfaOppId.add(iterOpp.Id); 
            }
        }
        
        if(setofInfaOppId.size() > 0){
            if(isUpdate){
                mapofOpportunity = new Map<Id, Opportunity>([SELECT Id, Name, RecordTypeId, CloseDate, AccountId, Account.Name, Renewal_Required_INF__c, Run_Rate_Opp_INF__c, Account_Type_INF__c, Booked_Date_INF__c,
                                                   Quote_Created_Date__c, Quote_Number__c, GP_OrderNum_INF__c, StageName, 
                                                   (Select Type_INF__c, PricebookEntry.Product2Id, PricebookEntry.Product2.License_Type_INF__c,Start_Date_INF__c, Product_Status__c, Product_Line__c,Quantity, PricebookEntry.Product2.Name,
                                                   TotalPrice, Description, Product_Family__c, OpportunityId, Id, End_Date_INF__c,PricebookEntryId,UnitPrice,Product_Name_INF__c From OpportunityLineItems
                                                   where PricebookEntry.Product2.License_Type_INF__c IN :setofProductName), (Select Id, OpportunityId, ContactId, Role, IsPrimary From OpportunityContactRoles)
                                                   FROM Opportunity WHERE Id IN: setofInfaOppId]);
            }
            
            for(Opportunity iterOpp : listofnewOpp){
                if(mapofOpportunity != null && !mapofOpportunity.isEmpty() && mapofOpportunity.get(iterOpp.Id) != null && mapofOpportunity.get(iterOpp.Id).OpportunityLineItems != null && mapofOpportunity.get(iterOpp.Id).OpportunityLineItems.size() > 0){
                    for(OpportunityLineItem iterOppLine : mapofOpportunity.get(iterOpp.Id).OpportunityLineItems){
                        if(isUpdate && iterOpp.StageName == 'Closed Won' && iterOpp.Renewal_Required_INF__c == 'No'&& iterOpp.Run_Rate_Opp_INF__c != true){
                            Asset assetNonRenew = new Asset();
                            assetNonRenew.AccountId = iterOpp.AccountId;
                            assetNonRenew.Product2Id = iterOppLine.PricebookEntry.Product2Id;
                            assetNonRenew.Price= iterOppLine.TotalPrice;
                            assetNonRenew.Account_Type__c = iterOpp.Account_Type_INF__c;
                            assetNonRenew.Booked_Date__c = iterOpp.Booked_Date_INF__c;
                            assetNonRenew.Quote_Date__c =  iterOpp.Quote_Created_Date__c;
                            assetNonRenew.Quote_Number__c = iterOpp.Quote_Number__c;
                            assetNonRenew.Sales_Order_Number__c = iterOpp.GP_OrderNum_INF__c;
                            assetNonRenew.Quantity = iterOppLine.Quantity;
                            assetNonRenew.Unit_Price_LC__c =  iterOppLine.UnitPrice;
                            assetNonRenew.PurchaseDate = iterOpp.CloseDate;
                            assetNonRenew.Status = 'Purchased';                            
                            assetNonRenew.Description = iterOppLine.Description;
                            if(iterOpp.Name.length() > 10){
                                assetNonRenew.Name = iterOpp.Name.substring(0,10)+ '-'  + iterOppLine.PricebookEntry.Product2.Name.substring(0,5) + '-' + '_INF';
                            }else{
                                assetNonRenew.Name = iterOpp.Name + '-'  + iterOppLine.PricebookEntry.Product2.Name.substring(0,5) + '-' + '_INF';
                            }
                            assetNonRenew.Opportunity__c = iterOpp.Id;
                            assetNonRenew.Is_Informatics__c =true;
                            listAssetNonrenew.add(assetNonRenew);
                        }
                    }
                }
                
                if(iterOpp.StageName == 'Closed Won'&& mapofOldOpp != null && !mapofOldOpp.isEmpty() && mapofOldOpp.get(iterOpp.Id) != null &&((mapofOldOpp.get(iterOpp.Id).StageName!=iterOpp.StageName) || (mapofOldOpp.get(iterOpp.Id).Renewal_Required_INF__c!= iterOpp.Renewal_Required_INF__c) || (mapofOldOpp.get(iterOpp.Id).Run_Rate_Opp_INF__c!= iterOpp.Run_Rate_Opp_INF__c)) 
                   && iterOpp.Renewal_Required_INF__c == 'Yes' && iterOpp.Run_Rate_Opp_INF__c != true /*&& iterOpp.SBQQ__PrimaryQuote__c == null*/){
                       mapOfOppToOppContactRoles.put(iterOpp.id, iterOpp.OpportunityContactRoles);
                       if(mapofOpportunity != null && !mapofOpportunity.isEmpty() && mapofOpportunity.get(iterOpp.Id).OpportunityLineItems != null && mapofOpportunity.get(iterOpp.Id).OpportunityLineItems.size() > 0){
                           for(OpportunityLineItem iterOppLine:mapofOpportunity.get(iterOpp.Id).OpportunityLineItems){
                               mapOfOppToOppLineItems.put(iterOpp.id, new List<OpportunityLineItem>{iterOppLine});
                               if(iterOppLine.End_Date_INF__c != null){
                                   OppResetControl.DoNotReset = true;
                                   Opportunity oppnew = iterOpp.clone(false,true);
                                   oppnew.AccountId = iterOpp.AccountId;
                                   oppnew.CloseDate = iterOppLine.End_Date_INF__c; 
                                   oppnew.RecordTypeId = iterOpp.RecordTypeId; 
                                   oppnew.Type='Renewal'; 
                                   oppnew.Application__c = iterOpp.Application__c; 
                                   oppnew.Application_Segment__c = iterOpp.Application_Segment__c; 
                                   oppnew.Application_Market__c = iterOpp.Application_Market__c; 
                                   oppnew.Name='INF_'+mapofOpportunity.get(iterOpp.Id).Account.Name+'_REN_'+iterOppLine.End_Date_INF__c.month()+'/'+iterOppLine.End_Date_INF__c.year(); 
                                   oppnew.Opportunity_Alias_INF__c = 'INF_'+mapofOpportunity.get(iterOpp.Id).Account.Name+'_REN_'+iterOppLine.End_Date_INF__c.month()+'/'+iterOppLine.End_Date_INF__c.year(); 
                                   oppnew.Amount = 0; 
                                   oppnew.Territory2Id = iterOpp.Territory2Id;
                                   oppnew.Probability=90; 
                                   oppnew.StageName='Stage 5 - Negotiation'; 
                                   oppnew.Message_Stage_Progression__c = 'Verbal commitment to buy from PKI'; 
                                   oppnew.Commit_INF__c = 'Yes'; 
                                   oppnew.Booked_Date_INF__c=null; 
                                   oppnew.Quote_Created_Date__c = null;
                                   oppnew.GP_OrderNum_INF__c = null;
                                   oppnew.Originating_Opportunity_INF__c = iterOpp.Id; 
                                   if(iterOpp.GP_OrderNum_INF__c!=null)
                                       oppnew.PY_Order_Number__c = iterOpp.GP_OrderNum_INF__c;
                                   listOfoppInsert.add(oppnew);
                               }
                               if(iterOppLine.PricebookEntry.Product2.License_Type_INF__c != 'Term' && iterOppLine.PricebookEntry.Product2.License_Type_INF__c != 'Subscription' && iterOppLine.PricebookEntry.Product2.License_Type_INF__c != 'Maintenance'){
                                   Asset a = new Asset();
                                   a.AccountId = iterOpp.AccountId;
                                   a.Product2Id = iterOppLine.PricebookEntry.Product2Id;
                                   a.Quantity = iterOppLine.Quantity;
                                   a.Price= iterOppLine.TotalPrice;
                                   a.Account_Type__c = iterOpp.Account_Type_INF__c;
                                   a.Booked_Date__c = iterOpp.Booked_Date_INF__c;
                                   a.Quote_Date__c =  iterOpp.Quote_Created_Date__c;
                                   a.Quote_Number__c = iterOpp.Quote_Number__c;
                                   a.Sales_Order_Number__c = iterOpp.GP_OrderNum_INF__c;
                                   a.Unit_Price_LC__c =  iterOppLine.UnitPrice;
                                   a.PurchaseDate = iterOpp.CloseDate;
                                   a.Status = 'Purchased';
                                   a.Description = iterOppLine.Description;
                                   if(iterOpp.Name.length() > 10){
                                       a.Name = iterOpp.Name.substring(0,10)+ '-'  + iterOppLine.PricebookEntry.Product2.Name.substring(0,5) + '-' + '_INF';
                                   }
                                   else{
                                       a.Name = iterOpp.Name + '-'  + iterOppLine.PricebookEntry.Product2.Name.substring(0,5) + '-' + '_INF';
                                   }
                                   a.Opportunity__c = iterOpp.Id;
                                   a.Is_Informatics__c =true;                                  
                                   listAssetRenew.add(a);
                               }
                           }
                       }
                }
            }
            if(listAssetNonrenew.size() > 0){
                insert listAssetNonrenew;
            }
            if(listOfoppInsert.size() > 0){
                insert listOfoppInsert;                
                
                for(Opportunity opprenew : listOfoppInsert){
                    Task taskObj = new Task(whatID = opprenew.Id, Ownerid = opprenew.OwnerId, Subject=opprenew.Name+'-Renewal Reminder', ActivityDate=opprenew.CloseDate-90);
                    renewaltasks.add(taskObj);
                    
                    if(mapofOpportunity != null && !mapOfOppToOppLineItems.isEmpty() && mapOfOppToOppLineItems.containsKey(opprenew.Originating_Opportunity_INF__c) && mapOfOppToOppLineItems.get(opprenew.Originating_Opportunity_INF__c).size() > 0){
                        for(OpportunityLineItem oppli:mapOfOppToOppLineItems.get(opprenew.Originating_Opportunity_INF__c)){
                            if(oppli.End_Date_INF__c == opprenew.CloseDate){
                                OpportunityLineItem oppLiTemp = oppli.clone(false,true);
                                oppLiTemp.TotalPrice = null;
                                oppLiTemp.OpportunityId = opprenew.Id;
                                oppLiTemp.Start_Date_INF__c = oppLiTemp.End_Date_INF__c.addDays(1);
                                oppLiTemp.End_Date_INF__c = oppLiTemp.End_Date_INF__c.addYears(1);
                                listOppLineInsert.add(oppLiTemp);
                            }
                            Asset asst = new Asset();
                            asst.AccountId = opprenew.AccountId;
                            asst.Product2Id = oppli.PricebookEntry.Product2Id;
                            asst.Quantity = oppli.Quantity;
                            asst.Price= (oppli.Quantity * oppli.UnitPrice);
                            asst.Account_Type__c = opprenew.Account_Type_INF__c;
                            asst.Booked_Date__c = opprenew.Booked_Date_INF__c;
                            asst.Quote_Date__c =  opprenew.Quote_Created_Date__c;
                            asst.Quote_Number__c = opprenew.Quote_Number__c;
                            asst.Sales_Order_Number__c = opprenew.GP_OrderNum_INF__c;
                            asst.Unit_Price_LC__c =  oppli.UnitPrice;
                            asst.PurchaseDate = opprenew.CloseDate;
                            asst.Status = 'Purchased';
                            asst.Description = oppli.Description;
                            if(opprenew.Name.length() > 10){
                                asst.Name = opprenew.Name.substring(0,10)+ '-'  + oppli.PricebookEntry.Product2.Name.substring(0,5) + '-' +oppli.End_Date_INF__c.addYears(1).month()+'/'+oppli.End_Date_INF__c.addYears(1).day()+'/'+oppli.End_Date_INF__c.addYears(1).year() + '_INF';
                            }
                            else{
                                asst.Name = opprenew.Name + '-'  + oppli.PricebookEntry.Product2.Name.substring(0,5) + '-' +oppli.End_Date_INF__c.addYears(1).month()+'/'+oppli.End_Date_INF__c.addYears(1).day()+'/'+oppli.End_Date_INF__c.addYears(1).year() + '_INF';
                            }
                            asst.End_Date__c = oppli.End_Date_INF__c.addYears(1);
                            asst.Start_Date__c = oppli.End_Date_INF__c.addDays(1);
                            asst.Renewal_Opportunity__c= opprenew.Id;
                            asst.Opportunity__c = opprenew.Originating_Opportunity_INF__c;
                            asst.Is_Informatics__c =true;
                            listAssetInsert.add(asst);
                        }
                    }
                    if(!mapOfOppToOppContactRoles.isEmpty() && mapOfOppToOppContactRoles.containsKey(opprenew.Originating_Opportunity_INF__c) && (mapOfOppToOppContactRoles.get(opprenew.Originating_Opportunity_INF__c).size()>0)){   
                        for(OpportunityContactRole oppCR:mapOfOppToOppContactRoles.get(opprenew.Originating_Opportunity_INF__c)){
                            OpportunityContactRole oppCRTemp = oppCR.clone(false,true);
                            oppCRTemp.OpportunityId = opprenew.Id;
                            listOppContactRole.add(oppCRTemp);
                        }
                    }
                }
                insert renewaltasks;
                
                if(listOppLineInsert.size() > 0){
                    insert listOppLineInsert;
                }
                if(listAssetInsert.size() > 0){
                    insert listAssetInsert;
                }
                if(listOppContactRole.size() > 0){
                    insert listOppContactRole;
                }
            }
        }
    }
}