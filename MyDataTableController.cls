public with sharing class MyDataTableController {
    
    private static string  convertStatus = [SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1]?.MasterLabel == ''? 'Closed - Converted':[SELECT Id, MasterLabel FROM LeadStatus WHERE IsConverted=true LIMIT 1].MasterLabel;
    
    //Retrieve datatable display records
    @AuraEnabled (cacheable=true)
    public static List<returnRecordsWrapper> getRecords(String keyWord){
        List<returnRecordsWrapper> returnRecords = new List<returnRecordsWrapper>();
        List<Lead> leadList;
        List<Opportunity> oppList;
        string searchWord = '%' + String.escapeSingleQuotes(keyWord) + '%';
        if(keyWord != '%%'){
            leadList = [select Id, Account__r.Name, Status, Due_Date__c From Lead where Account__r.Name !=null AND Due_Date__c != null AND Account__r.Name like :searchWord AND Status <>:convertStatus AND  OwnerId = :UserInfo.getUserId()  limit 100];
            oppList = [select Id, Account.Name, StageName, CloseDate From Opportunity where Account.Name like :searchWord AND StageName != 'Closed Won' AND  OwnerId = :UserInfo.getUserId() limit 100];
        } else{
            leadList = [select Id, Account__r.Name, Status, Due_Date__c From Lead where Status <>:convertStatus  AND  OwnerId = :UserInfo.getUserId() limit 100];
            oppList = [select Id, Account.Name, StageName, CloseDate From Opportunity where StageName != 'Closed Won' AND  OwnerId = :UserInfo.getUserId() limit 100];
        }
        Integer m = 0;
        for(Lead l : leadList) {
            returnRecordsWrapper tempWrapper = new returnRecordsWrapper();
            tempWrapper.Index = m+1;
            tempWrapper.id = l.id;
            tempWrapper.BusinessName = l.Account__r.Name;
            tempWrapper.Type = 'Lead';
            tempWrapper.Status = l.Status;
            tempWrapper.DueDate = string.valueof(l.Due_Date__c);
            returnRecords.add(tempWrapper);
            m++;
        }
        for(Opportunity o : oppList) {
            returnRecordsWrapper tempWrapper = new returnRecordsWrapper();
            tempWrapper.Index = m+1;
            tempWrapper.id = o.id;
            tempWrapper.BusinessName = o.Account.Name;
            tempWrapper.Type = 'Opportunity';
            tempWrapper.Status = o.StageName;
            tempWrapper.DueDate = string.valueof(o.CloseDate);
            returnRecords.add(tempWrapper);
            m++;
        }        
        return returnRecords;
   }

   //Delete records
   @AuraEnabled   
   public static List<returnRecordsWrapper> deleteRecords(String deleteRecWrapper){ 
    List<returnRecordsWrapper> jsonData = (List<returnRecordsWrapper>)JSON.deserialize(deleteRecWrapper, List<returnRecordsWrapper>.class);
    Set<Id> leadDeleteIds = new Set<Id>();
    Set<Id> oppDeleteIds = new Set<Id>();
    for(returnRecordsWrapper w : jsonData) {
        if(w.type == 'lead'){
            leadDeleteIds.add(w.id);
        }else{
            oppDeleteIds.add(w.id);
        }
    }
    if(leadDeleteIds.size() > 0){
        List<Lead> leadDeletList = [select Id From Lead where id in: leadDeleteIds];
        delete leadDeletList;
    }
    if(oppDeleteIds.size() > 0){
        List<Opportunity> oppDeletList = [select Id From Opportunity where id in: oppDeleteIds];
        delete oppDeletList;
    } 
    return getRecords('%%');
}

   //Clone records
   @AuraEnabled
   public static List<returnRecordsWrapper> cloneRecords(String cloneRecWrapper){
    List<returnRecordsWrapper> jsonData = (List<returnRecordsWrapper>)JSON.deserialize(cloneRecWrapper, List<returnRecordsWrapper>.class);
    Set<Id> leadCloneIds = new Set<Id>();
    Set<Id> oppCloneIds = new Set<Id>();
    for(returnRecordsWrapper w : jsonData) {
        if(w.type == 'lead'){
            leadCloneIds.add(w.id);
        }else{
            oppCloneIds.add(w.id);
        }
    }
    if(leadCloneIds.size() > 0){
        List<Lead> leadCloneTargetList = new List<Lead>();
        List<Lead> leadCloneSourceList = [select Id, Account__c, Name, LastName, Company, Status, Due_Date__c From Lead where id in: leadCloneIds];
        for(Lead l : leadCloneSourceList)
        {
            Lead leadCopy = l.clone(false,false,false,false);
            if(l.Due_Date__c != null){
                leadCopy.Due_Date__c = l.Due_Date__c.addYears(1);
            }else{
                leadCopy.Due_Date__c = system.today();
            }
            leadCloneTargetList.add(leadCopy);
        }
        insert leadCloneTargetList;
    }
    if(oppCloneIds.size() > 0){
        List<Opportunity> oppCloneTargetList = new List<Opportunity>();
        List<Opportunity> oppCloneSourceList = [select Id, AccountId,Name, CloseDate, StageName From Opportunity where id in: oppCloneIds];
        for(Opportunity o : oppCloneSourceList)
        {
            Opportunity oppCopy = o.clone(false,false,false,false);
            oppCopy.CloseDate = o.CloseDate.addYears(1);
            oppCloneTargetList.add(oppCopy);
        }
        insert oppCloneTargetList;
    }
    return getRecords('%%');
}

  //Convert records
  @AuraEnabled
   public static List<returnRecordsWrapper> convertRecords(String convertRecWrapper){
    List<returnRecordsWrapper> jsonData = (List<returnRecordsWrapper>)JSON.deserialize(convertRecWrapper, List<returnRecordsWrapper>.class);
    if (jsonData[0].type == 'lead'){
        Set<Id> leadConvertIds = new Set<Id>();
        for(returnRecordsWrapper w : jsonData) {
            leadConvertIds.add(w.id);
        }
        List<Lead> leadConvertList = [select Id From Lead where id in: leadConvertIds];
        list<Database.LeadConvert> leadsToConvert = new list<Database.LeadConvert>();
        for(lead l: leadConvertList){
            Database.LeadConvert tempLC = new Database.LeadConvert();
            tempLC.setLeadId(l.id);
            tempLC.setConvertedStatus(convertStatus);
            leadsToConvert.add(tempLC);
        }
        List<Database.LeadConvertResult> lc = Database.convertLead(leadsToConvert);
        // for(Database.LeadConvertResult lctemp: lc){
        //     system.debug('lctemp.getAccountId++++'+lctemp.getAccountId());
        //     system.debug('lctemp.getContact++++'+lctemp.getContactId());
        //     system.debug('lctemp.getOpportunity++++'+lctemp.getOpportunityId());
        // }
    } else{
        String oppId = jsonData[0].id;
        Opportunity oppConvert = [select Id, StageName From Opportunity where id =: oppId limit 1];
        oppConvert.StageName = 'Closed Won';
        upsert oppConvert;
    }
    return getRecords('%%');
   }
   
   //Create wrapper structrue
   public class returnRecordsWrapper{
    @auraEnabled public Integer  Index;
    @auraEnabled public string  BusinessName;
    @auraEnabled public string  Type;
    @auraEnabled public string  Status;
    @auraEnabled public string  DueDate;
    @auraEnabled public string  id;
 }
}