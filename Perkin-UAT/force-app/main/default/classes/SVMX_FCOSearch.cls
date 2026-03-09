public class SVMX_FCOSearch {
  public String uid=System.currentPageReference().getParameters().get('uid');
  public FCO__c FCO = new FCO__c();
  public FCO_Search__c FCOSearch = new FCO_Search__c();
  List<FCO_Search__c> FCOSlist = new List<FCO_Search__c>();
  Boolean SearchFlag = false,CreateFlag=false,SrchlistFlg=true,ShowSaveflg=true;
  List<SVMXC__Installed_Product__c> IBlist = new List<SVMXC__Installed_Product__c>();
  List<FCO_Lines__c> FCOLlist = new List<FCO_Lines__c>();
  List<FCO_Lines__c> FCOLCollist = new List<FCO_Lines__c>();
  public SVMX_FCOSearch(){
    SrchlistFlg=true;
    FCO=[select id,Name,FCO_Type__c,PSC_Status__c,Description__c,Business_Unit_FCO__c,Creation_Date__c,Product__c,Compliance_Date__c from FCO__c where id=:uid];
      
      FCOSearch.Target_Product__c=FCO.Product__c;
      
     FCOSlist=[Select CreatedBy.Name,CreatedDate, FCO__c, Id, Target_Product__c, Target_Product_SW_Minor_Start__c, 
     	Target_Serial_Start__c, Target_Serial_End__c,
        Target_Product_SW_Minor_End__c, Target_Product_SW_Major_Start__c, Target_Product_SW_Major_End__c, 
        Target_Product_SW_Build_Start__c, Target_Product_SW_Build_End__c,Target_Product_SW_Revision_End__c, Target_Product_SW_Revision_Start__c,
        Target_Product_Attribute_4__c, Target_Product_Attribute_3__c, Target_Product_Attribute_2__c, Target_Product_Attribute_1__c, 
        SystemModstamp, Serial_6_Start__c, Serial_6_End__c, Serial_5_Start__c, Serial_5_End__c, Serial_4_Start__c, Serial_4_End__c, 
        Serial_3_Start__c, Serial_3_End__c, Serial_2_Start__c, Serial_2_End__c, Serial_1_Start__c, Serial_1_End__c, Select__c, 
        Restricted_to_Same_Product__c,Product_1_SW_Revision_End__c, Product_1_SW_Revision_Start__c, 
        Product_2_SW_Revision_End__c,Product_2_SW_Revision_Start__c, Product_3_SW_Revision_End__c, Product_3_SW_Revision_Start__c, 
        Product_4_SW_Revision_End__c, Product_4_SW_Revision_Start__c, Product_5_SW_Revision_End__c, 
        Product_5_SW_Revision_Start__c, Product_6_SW_Revision_End__c, Product_6_SW_Revision_Start__c,
        Product_6__c, Product_6_SW_Minor_Start__c, Product_6_SW_Minor_End__c, Product_6_SW_Major_Start__c, 
        Product_6_SW_Major_End__c, Product_6_SW_Build_Start__c, Product_6_SW_Build_End__c, Product_6_Attribute_4__c, Product_6_Attribute_3__c, 
        Product_5__c, Product_5_SW_Minor_Start__c, Product_5_SW_Minor_End__c, Product_5_SW_Major_Start__c, Product_5_SW_Major_End__c, 
        Product_5_SW_Build_Start__c, Product_5_SW_Build_End__c, Product_5_Attribute_2__c, Product_5_Attribute_1__c, Product_4__c, 
        Product_4_SW_Minor_Start__c, Product_4_SW_Minor_End__c, Product_4_SW_Major_Start__c, Product_4_SW_Major_End__c, 
        Product_4_SW_Build_Start__c, Product_4_SW_Build_End__c, Product_4_Attribute_4__c, Product_4_Attribute_3__c, Product_3__c, 
        Product_3_SW_Minor_Start__c, Product_3_SW_Minor_End__c, Product_3_SW_Major_Start__c, Product_3_SW_Major_End__c, 
        Product_3_SW_Build_Start__c, Product_3_SW_Build_End__c, Product_3_Attribute_2__c, Product_3_Attribute_1__c, Product_2__c, 
        Product_2_SW_Minor_Start__c, Product_2_SW_Minor_End__c, Product_2_SW_Major_Start__c, Product_2_SW_Major_End__c, 
        Product_2_SW_Build_Start__c, Product_2_SW_Build_End__c, Product_2_Attribute_4__c, Product_2_Attribute_3__c, Product_1__c, 
        Product_1_SW_Minor_Start__c, Product_1_SW_Minor_End__c, Product_1_SW_Major_Start__c, Product_1_SW_Major_End__c, 
        Product_1_SW_Build_Start__c, Product_1_SW_Build_End__c, Product_1_Attribute_2__c, Product_1_Attribute_1__c, Name, Join_6__c, 
        Join_5__c, Join_4__c, Join_3__c, Join_2__c, Join_1__c
      from FCO_Search__c where FCO__c=:uid order by createddate desc limit 10];
  }
  public FCO__c getFCO(){
    return FCO;
  }
  public void setFCO(FCO__c f){
    FCO=f;
  }
  public List<FCO_Search__c> getFCOSearchlist(){
    return FCOSlist;
  }
  public void setFCOSearchlist(List<FCO_Search__c> f){
    FCOSlist=f;
  }
  public FCO_Search__c getFCOSearch(){
    return FCOSearch;
  }
  public void setFCOSearch(FCO_Search__c f){
    FCOSearch=f;
  }
  public List<SVMXC__Installed_Product__c> getIBlist(){
    return IBlist;
  }
  public Boolean getSrchlistFlg(){
    return SrchlistFlg;
  }
  public Boolean getShowSaveflg(){
    return ShowSaveflg;
  }
  public Boolean getSrchFlg(){
    return SearchFlag;
  }
  public Boolean getCreateFlg(){
    return CreateFlag;
  }
  public String getSid(){
    return uid;
  }
  public pagereference fnXSTSearch(){
    if(FCOSlist.size()>0){
        String SelFcoSrch;
        integer cont=0;
        for(FCO_Search__c fcosrch:FCOSlist){
            if(fcosrch.select__c){
                cont++;
                SelFcoSrch=fcosrch.id;
            }
        }
        if(cont==1){
            SrchlistFlg=false;
            ShowSaveflg=false;
            FCOSearch=[Select schedule_time__c,Target_Serial_Start__c, Target_Serial_End__c, Target_Product__c, Target_Product_SW_Minor_Start__c, 
                Target_Product_SW_Minor_End__c, Target_Product_SW_Major_Start__c, Target_Product_SW_Major_End__c, 
                Target_Product_SW_Build_Start__c, Target_Product_SW_Build_End__c,Target_Product_SW_Revision_End__c, Target_Product_SW_Revision_Start__c,
                Target_Product_Attribute_4__c, Target_Product_Attribute_3__c, Target_Product_Attribute_2__c, Target_Product_Attribute_1__c, 
                SystemModstamp, Serial_6_Start__c, Serial_6_End__c, Serial_5_Start__c, Serial_5_End__c, Serial_4_Start__c, Serial_4_End__c, 
                Serial_3_Start__c, Serial_3_End__c, Serial_2_Start__c, Serial_2_End__c, Serial_1_Start__c, Serial_1_End__c, Select__c, 
                Restricted_to_Same_Product__c,Product_1_SW_Revision_End__c, Product_1_SW_Revision_Start__c, 
                Product_2_SW_Revision_End__c,Product_2_SW_Revision_Start__c, Product_3_SW_Revision_End__c, Product_3_SW_Revision_Start__c, 
                Product_4_SW_Revision_End__c, Product_4_SW_Revision_Start__c, Product_5_SW_Revision_End__c, 
                Product_5_SW_Revision_Start__c, Product_6_SW_Revision_End__c, Product_6_SW_Revision_Start__c,
                Product_6__c, Product_6_SW_Minor_Start__c, Product_6_SW_Minor_End__c, Product_6_SW_Major_Start__c, 
                Product_6_SW_Major_End__c, Product_6_SW_Build_Start__c, Product_6_SW_Build_End__c, Product_6_Attribute_4__c, Product_6_Attribute_3__c, 
                Product_5__c, Product_5_SW_Minor_Start__c, Product_5_SW_Minor_End__c, Product_5_SW_Major_Start__c, Product_5_SW_Major_End__c, 
                Product_5_SW_Build_Start__c, Product_5_SW_Build_End__c, Product_5_Attribute_2__c, Product_5_Attribute_1__c, Product_4__c, 
                Product_4_SW_Minor_Start__c, Product_4_SW_Minor_End__c, Product_4_SW_Major_Start__c, Product_4_SW_Major_End__c, 
                Product_4_SW_Build_Start__c, Product_4_SW_Build_End__c, Product_4_Attribute_4__c, Product_4_Attribute_3__c, Product_3__c, 
                Product_3_SW_Minor_Start__c, Product_3_SW_Minor_End__c, Product_3_SW_Major_Start__c, Product_3_SW_Major_End__c, 
                Product_3_SW_Build_Start__c, Product_3_SW_Build_End__c, Product_3_Attribute_2__c, Product_3_Attribute_1__c, Product_2__c, 
                Product_2_SW_Minor_Start__c, Product_2_SW_Minor_End__c, Product_2_SW_Major_Start__c, Product_2_SW_Major_End__c, 
                Product_2_SW_Build_Start__c, Product_2_SW_Build_End__c, Product_2_Attribute_4__c, Product_2_Attribute_3__c, Product_1__c, 
                Product_1_SW_Minor_Start__c, Product_1_SW_Minor_End__c, Product_1_SW_Major_Start__c, Product_1_SW_Major_End__c, 
                Product_1_SW_Build_Start__c, Product_1_SW_Build_End__c, Product_1_Attribute_2__c, Product_1_Attribute_1__c, Name, Join_6__c, 
                Join_5__c, Join_4__c, Join_3__c, Join_2__c, Join_1__c, Id, FCO__c,CreatedDate, CreatedById, Conditional_Search__c 
                from FCO_Search__c where id=:SelFcoSrch];
        }else{
            ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR,'Please select only one record.'));
            return null;
        }
    }   
    return null;
  }
  public pagereference fnNewSearch(){
    ShowSaveflg=true;
    SrchlistFlg=false;
    FCOSearch.FCO__c=uid;
    return null;
  }
  public pagereference fnSearch(){
      IBlist.clear();
      
   List <Set<Id>> matchingIds = new List<Set<Id>>();
    List<SVMXC__Installed_Product__c> TopIBlist = new List<SVMXC__Installed_Product__c>();    
    set<Id> TopIPids = new set<Id>();
    set<Id> locids = new set<Id>();
    String Commids = '';
    Double TrtSRLstart=0, TrtSRLend=0;
    Map<String,String> mapSrchStr1 = new Map<String,String>();
    Map<String,String> mapSrchStr2 = new Map<String,String>();
    if(FCOSearch != Null){
    SearchFlag = true;

    if(FCOSearch.Target_Product__c != Null)
        mapSrchStr1.put('SVMXC__Product__c:and:=: : :T',FCOSearch.Target_Product__c);    
    if(FCOSearch.Target_Product_SW_Minor_Start__c != Null)
        mapSrchStr1.put(' Minor__c:and:>=: : :N',FCOSearch.Target_Product_SW_Minor_Start__c);
    if(FCOSearch.Target_Product_SW_Minor_End__c != Null)
        mapSrchStr1.put('Minor__c:and:<=: : :N',FCOSearch.Target_Product_SW_Minor_End__c);
    if(FCOSearch.Target_Product_SW_Major_Start__c != Null)
        mapSrchStr1.put(' Major__c:and:>=: : :N',FCOSearch.Target_Product_SW_Major_Start__c);
    if(FCOSearch.Target_Product_SW_Major_End__c != Null)
        mapSrchStr1.put('Major__c:and:<=: : :N',FCOSearch.Target_Product_SW_Major_End__c);
    /*
    if(FCOSearch.Target_Product_SW_Build_Start__c != Null)
        mapSrchStr1.put(' Build__c:and:>=: : :N',FCOSearch.Target_Product_SW_Build_Start__c);
    if(FCOSearch.Target_Product_SW_Build_End__c != Null)
        mapSrchStr1.put('Build__c:and:<=: : :N',FCOSearch.Target_Product_SW_Build_End__c);
    */ 
    if(FCOSearch.Target_Product_SW_Revision_Start__c != Null)
        mapSrchStr1.put(' Revision__c:and:>=: : :N',FCOSearch.Target_Product_SW_Revision_Start__c);
    if(FCOSearch.Target_Product_SW_Revision_End__c != Null)
        mapSrchStr1.put('Revision__c:and:<=: : :N',FCOSearch.Target_Product_SW_Revision_End__c);
    
    if(FCOSearch.Target_Serial_Start__c != Null)
        TrtSRLstart=double.valueof(FCOSearch.Target_Serial_Start__c);
       //mapSrchStr1.put(' SVMXC__Serial_Lot_Number__c:and:>: : :N',FCOSearch.Target_Serial_Start__c);
    if(FCOSearch.Target_Serial_End__c != Null)
        TrtSRLend=double.valueof(FCOSearch.Target_Serial_End__c);
        //mapSrchStr1.put('SVMXC__Serial_Lot_Number__c:and:<: : :N',FCOSearch.Target_Serial_End__c);
    system.debug('TrtSRLstart>>'+TrtSRLstart+'---TrtSRLend'+TrtSRLend);
    system.debug('mapSrchStr1>>'+mapSrchStr1);
    if(mapSrchStr1 != null && mapSrchStr1.size()>0){
        String  QryStr1=SearchString(mapSrchStr1,null);     
        String SOQLstr='select id,Name,SVMXC__Serial_Lot_Number__c,SVMXC__Product__c,SVMXC__Top_Level__c,SVMXC__Site__c from SVMXC__Installed_Product__c where ';
        SOQLstr = SOQLstr+''+QryStr1;
        System.debug('SOQLstr:'+SOQLstr);
        try{
          TopIBlist=Database.query(SOQLstr);
        }catch(Exception E){ System.debug(E.getmessage());}
        
        for(SVMXC__Installed_Product__c IB:TopIBlist){
            if(TrtSRLstart != 0 &&  TrtSRLend != 0){
                if(Double.valueof(IB.SVMXC__Serial_Lot_Number__c) >= TrtSRLstart && Double.valueof(IB.SVMXC__Serial_Lot_Number__c) <= TrtSRLend){
                    if(IB.SVMXC__Top_Level__c != null){
                        TopIPids.add(IB.SVMXC__Top_Level__c);
                    }else{
                        TopIPids.add(IB.id);
                    }
                    if(IB.SVMXC__Site__c != null){
                        locids.add(IB.SVMXC__Site__c);
                    }
                }
            }
            else if(TrtSRLstart != 0 &&  TrtSRLend == 0){
                if(Double.valueof(IB.SVMXC__Serial_Lot_Number__c) >= TrtSRLstart){
                    if(IB.SVMXC__Top_Level__c != null){
                        TopIPids.add(IB.SVMXC__Top_Level__c);
                    }else{
                        TopIPids.add(IB.id);
                    }
                    if(IB.SVMXC__Site__c != null){
                        locids.add(IB.SVMXC__Site__c);
                    }
                }
            }
            else if(TrtSRLstart == 0 &&  TrtSRLend != 0){
                if(Double.valueof(IB.SVMXC__Serial_Lot_Number__c) <= TrtSRLend){
                    if(IB.SVMXC__Top_Level__c != null){
                        TopIPids.add(IB.SVMXC__Top_Level__c);
                    }else{
                        TopIPids.add(IB.id);
                    }
                    if(IB.SVMXC__Site__c != null){
                        locids.add(IB.SVMXC__Site__c); 
                    }
                }
            }
            else{
                if(IB.SVMXC__Top_Level__c != null){
                    TopIPids.add(IB.SVMXC__Top_Level__c);
                }else{
                    TopIPids.add(IB.id);
                }
                if(IB.SVMXC__Site__c != null){
                    locids.add(IB.SVMXC__Site__c);
                }
            }
        }
        List<Id> TopIPidList = new List<Id>();
        if(FCOSearch.Restricted_to_Same_Product__c == 'Yes'){
            TopIPidList.addall(TopIPids);           
        }else if(FCOSearch.Restricted_to_Same_Product__c == 'No'){
            TopIPidList.addall(locids);
        }
        for(Integer i=0;i<TopIPidList.size();i++){
            if(TopIPidList.size() == i+1)
                Commids +='\''+TopIPidList.get(i)+'\'';
            else
                Commids +='\''+TopIPidList.get(i)+'\',';
        }
        if(Commids != null){
            String joinval = 'OR';
            for (Integer index = 1; index <= 6; index++) {
                Double SRLstart=0,SRLend=0;
                mapSrchStr2.clear();
                List<SVMXC__Installed_Product__c> ATTIBlist= new List<SVMXC__Installed_Product__c>();
                set<Id> ATTTopIPids = new set<Id>();
                String Prod = (String) FCOSearch.get('Product_'+index+'__c');
                SRLstart = Double.valueof(FCOSearch.get('Serial_'+index+'_Start__c'));
                SRLend = Double.valueof(FCOSearch.get('Serial_'+index+'_End__c'));  
                String minorstart = (String) FCOSearch.get('Product_'+index+'_SW_Minor_Start__c');
                String minorend = (String) FCOSearch.get('Product_'+index+'_SW_Minor_End__c');
                String Majorstart = (String) FCOSearch.get('Product_'+index+'_SW_Major_Start__c');
                String Majorend = (String) FCOSearch.get('Product_'+index+'_SW_Major_End__c');
                String Buildstart = (String) FCOSearch.get('Product_'+index+'_SW_Build_Start__c');
                String Buildend = (String) FCOSearch.get('Product_'+index+'_SW_Build_End__c');
                String Revisionstart = (String) FCOSearch.get('Product_'+index+'_SW_Revision_Start__c');
                String Revisionend = (String) FCOSearch.get('Product_'+index+'_SW_Revision_End__c');
                
                if(Prod != Null)
                    mapSrchStr2.put('SVMXC__Product__c:and:=: : :T',Prod);
                if(minorstart != Null)
                    mapSrchStr2.put(' Minor__c:and:>=: : :N',minorstart);
                if(minorend != Null)
                    mapSrchStr2.put('Minor__c:and:<=: : :N',minorend);
                if(Majorstart != Null)
                    mapSrchStr2.put(' Major__c:and:>=: : :N',Majorstart);
                if(Majorend != Null)
                    mapSrchStr2.put('Major__c:and:<=: : :N',Majorend);
                if(Buildstart != Null)
                    mapSrchStr2.put(' Build__c:and:>=: : :N',Buildstart);
                if(Buildend != Null)
                    mapSrchStr2.put('Build__c:and:<=: : :N',Buildend);
                if(Revisionstart != Null)
                    mapSrchStr2.put(' Revision__c:and:>=: : :N',Revisionstart);
                if(Revisionend != Null)
                    mapSrchStr2.put('Revision__c:and:<=: : :N',Revisionend);                 
                    
                //if(SRLstart != Null)
                    //mapSrchStr2.put(' SVMXC__Serial_Lot_Number__c:and:like: : :N',SRLstart+'%');
                //if(SRLend != Null)
                    //mapSrchStr2.put('SVMXC__Serial_Lot_Number__c:and:like: : :N','%'+SRLend);
                    
                if(mapSrchStr2 != null && mapSrchStr2.size()>0){
                    String QryStr=SearchString(mapSrchStr2,null);
                    String QrySubStr=' (SVMXC__Top_Level__c in ('+Commids+') OR SVMXC__Site__c in('+Commids+')) AND ';
                    String SOQLstr1='select id,SVMXC__Serial_Lot_Number__c,Name,SVMXC__Product__c,SVMXC__Top_Level__c,SVMXC__Site__c from SVMXC__Installed_Product__c where ';
                    SOQLstr1 = SOQLstr1+''+QrySubStr+''+QryStr;
                    System.debug('SOQLstr1:'+SOQLstr1);
                    try{
                      ATTIBlist=Database.query(SOQLstr1);
                    }catch(Exception E){}
                    System.debug('ATTIBlist+++ '+ATTIBlist);
                    System.debug('SRLstart+++ '+SRLstart+'---SRLend'+SRLend);
                    for(SVMXC__Installed_Product__c IB:ATTIBlist){
                        if(SRLstart != null &&  SRLend != null){
                            if(Double.valueof(IB.SVMXC__Serial_Lot_Number__c) >= SRLstart && Double.valueof(IB.SVMXC__Serial_Lot_Number__c) <= SRLend){
                                if(IB.SVMXC__Top_Level__c != null){
                                    ATTTopIPids.add(IB.SVMXC__Top_Level__c);
                                }else{
                                    ATTTopIPids.add(IB.id);
                                } 
                            }
                        }
                        else if(SRLstart != null &&  SRLend == null){
                            if(Double.valueof(IB.SVMXC__Serial_Lot_Number__c) >= SRLstart){
                                if(IB.SVMXC__Top_Level__c != null){
                                    ATTTopIPids.add(IB.SVMXC__Top_Level__c);
                                }else{
                                    ATTTopIPids.add(IB.id);
                                } 
                            }
                        }
                        else if(SRLstart == null &&  SRLend != null){
                            if(Double.valueof(IB.SVMXC__Serial_Lot_Number__c) <= SRLend){
                                if(IB.SVMXC__Top_Level__c != null){
                                    ATTTopIPids.add(IB.SVMXC__Top_Level__c);
                                }else{
                                    ATTTopIPids.add(IB.id);
                                } 
                            }
                        }
                        else{
                            if(IB.SVMXC__Top_Level__c != null){
                                ATTTopIPids.add(IB.SVMXC__Top_Level__c);
                            }else{
                                ATTTopIPids.add(IB.id);
                            } 
                        }
                    
                                          
                    }
                                
                    matchingIds.add(TopIPids.clone());                
                    if (joinval == 'OR') {                  
                        TopIPids = new Set<Id>();
                        TopIPids.addAll(ATTTopIPids);
                    } else { // joinval is AND
                        TopIPids.retainAll(ATTTopIPids);
                    }
                    System.debug('TopIPids+++ '+TopIPids);
                    if(index < 6){
                        joinval = (String) FCOSearch.get('Join_'+index+'__c');
                        if (joinval == null)
                            break;
                    }
                    
                }           
            }
        }
        matchingIds.add(TopIPids.clone());  
        System.debug('matchingIds+++ '+matchingIds);
        
        Set<Id> resultSet = new Set<Id>();
        for (Set<Id> curSet : matchingIds) {
            resultSet.addAll(curSet);
        }
        
        if(resultSet.size() >0){             
            try{
              IBlist=[select id,Name,SVMXC__Serial_Lot_Number__c,SVMXC__Product__c,SVMXC__Product__r.name,Major__c,minor__c,Build__c,Revision__c,SVMXC__Company__c from SVMXC__Installed_Product__c where id in:resultSet];
              
            }catch(Exception E){}
            if(IBlist.size()>0){
              CreateFlag=true;
            }else{
              CreateFlag=false;
              ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR,'No Result Found.'));
            }
          }else{
             CreateFlag=false;
            ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR,'No Result Found.'));
          }     
        }            
    }else{
      SearchFlag = false;  
      ApexPages.addMessage(new Apexpages.Message(ApexPages.Severity.ERROR,'Please Select or Enter any one value in the Product Section'));      
    }  
    return null;
  }
  
  public String SearchString(Map<String,String> map1,String StrExtra)
  {
    String SQLStr='';
    Integer i=0;
    for(String str:map1.keyset()){
        List<String> mStr = str.split(':');
        if(mStr[1] != 'or'){
            if(i != 0) SQLStr += ' AND ';
        }else{
            if(i != 0) SQLStr += ' OR ';
        }
        if(mStr[5]=='N'){           
            SQLStr += mStr[3]+' '+ mStr[0] +' '+ mStr[2]+' '+Integer.valueof(map1.get(str))+' '+mStr[4]+' ';
        }else{
            SQLStr += mStr[3]+' '+ mStr[0] +' '+ mStr[2]+' '+'\''+map1.get(str)+'\''+mStr[4]+' ';
        }
        i=1;
    }
    return SQLStr;
  }
  
  
  
  public pagereference fnCreateFCOL(){
    SearchFlag = true;
    Boolean InsFCOL;
    if(IBlist.size()>0){
    
      try{    
        FCOLlist = [select id,Name,Installed_Product_1__c,Status__c from FCO_Lines__c where FCO__c=:uid];
        for(SVMXC__Installed_Product__c ip:IBlist){
          InsFCOL=true;
          for(FCO_Lines__c Fcoln:FCOLlist){
          	for(FCO_Lines__c g: FCOLCollist){
	            if(Fcoln.Installed_Product_1__c == ip.Id){
	              InsFCOL=false;
	            }
	            if(g.id==Fcoln.id) InsFCOL=false;
          	}
          } 
          if(InsFCOL){
            FCO_Lines__c FCOL = new FCO_Lines__c();
            FCOL.FCO__c=uid;
            FCOL.Installed_Product_1__c=ip.id;
            FCOL.Account__c=ip.SVMXC__Company__c;                        
            FCOL.Status__c='Active';
            FCOLCollist.add(FCOL);
          }
        }
        for(FCO_Lines__c Fcoln:FCOLlist){      
          InsFCOL=true;
          for(SVMXC__Installed_Product__c ip:IBlist){
          	for(FCO_Lines__c g: FCOLCollist){
	            if(Fcoln.Installed_Product_1__c == ip.Id){
	              InsFCOL=false;
	            }
	            if(g.id==Fcoln.id) InsFCOL=false;
          	}
          }
          if(InsFCOL){
            Fcoln.Status__c='Inactive';
            FCOLCollist.add(Fcoln);
          }
        }
      }catch(Exception E){
        for(SVMXC__Installed_Product__c ip:IBlist){
          FCO_Lines__c FCOL = new FCO_Lines__c();
          FCOL.FCO__c=uid;
          FCOL.Installed_Product_1__c=ip.id;
          FCOL.Account__c=ip.SVMXC__Company__c;        
          FCOL.Status__c='Active';
          FCOLCollist.add(FCOL);
        }
      }
      if(FCOLCollist.size()>0){
        system.debug(FCOLCollist);
        upsert FCOLCollist;
      }
        system.debug(FCOSearch);
        upsert FCOSearch;
    }
    return null;
  }
  
  public pagereference fnReset(){    
    pagereference pgref= new pagereference('/apex/SVMX_FCOSearch?uid='+uid);
    pgref.setRedirect(true);
    return pgref;
  }
  public pagereference fnSaveSearch(){   
    ShowSaveflg=false; 
    upsert FCOSearch;
    return null;
  }
  public pagereference fnUpdSearch(){   
    update FCOSearch; 
    return null;
  }
}