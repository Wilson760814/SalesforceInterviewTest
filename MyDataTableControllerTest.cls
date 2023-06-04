@IsTest
public class MyDataTableControllerTest {
    @TestSetup
    static void makeData(){
        Account accRef = new Account();
        accRef.Name = 'accTest';
        insert accRef;
        List<Lead> leadList = new List<Lead>();
        List<Opportunity> oppList = new List<Opportunity>();
        for(Integer i=1; i<=2; i++){            
            Lead leadRec = new Lead();
            leadRec.Account__c = accRef.id;
            leadRec.Due_Date__c = Date.valueof('2024-06-02');
            leadRec.LastName = 'leadtest' + i;
            leadRec.OwnerId = UserInfo.getUserId();
            leadRec.Status = 'Open - Not Contacted';
            leadRec.Company = 'Company Name';
            leadList.add(leadRec);
        }
        for(Integer i=1; i<=1; i++){
            Opportunity oppRec = new Opportunity();            
            oppRec.AccountId = accRef.id;
            oppRec.CloseDate = Date.valueof('2024-06-02');
            oppRec.Name = 'opptest'+i;
            oppRec.OwnerId = UserInfo.getUserId();
            oppRec.StageName = 'Qualification';
            oppList.add(oppRec);
        }
        insert leadList;
        insert oppList;
    }

    @IsTest
    public static void getRecordsTest() {
       
        Test.startTest();
        MyDataTableController.getRecords('%%');
        MyDataTableController.getRecords('test');
        Test.stopTest();
        System.assertEquals('accTest', MyDataTableController.getRecords('%%')[0].BusinessName);
        System.assertEquals('accTest', MyDataTableController.getRecords('test')[0].BusinessName);
    }

    @IsTest
    public static void deleteRecordsTest() {        
        Lead leadTest = [select Id, Account__r.Name, Status, Due_Date__c, IsDeleted From Lead where LastName = 'leadtest1' limit 1];
        System.debug('leadTest+++'+leadTest);
        Opportunity oppTest = [select Id, Account.Name, StageName, CloseDate, IsDeleted From Opportunity where Name = 'opptest1' limit 1];
        String leadTestString = '[{"BusinessName":"'+leadTest.Account__r.Name+'","DueDate":"'+leadTest.Due_Date__c+'","id":"'+leadTest.Id+'","Index":3,"Status":"'+leadTest.Status+'","Type":"Lead"}]';
        String oppTestString = '[{"BusinessName":"'+oppTest.Account.Name+'","DueDate":"'+oppTest.CloseDate+'","id":"'+oppTest.Id+'","Index":2,"Status":"'+oppTest.StageName+'","Type":"Opportunity"}]';
       
        Test.startTest();
        MyDataTableController.deleteRecords(leadTestString);
        MyDataTableController.deleteRecords(oppTestString);
        Test.stopTest();
        List<Lead> leadListTest = [select Id, Account__r.Name, Status, Due_Date__c From Lead where LastName = 'leadtest1' limit 1];
        List<Opportunity> oppListTest = [select Id, Account.Name, StageName, CloseDate, IsDeleted From Opportunity where Name = 'opptest1' limit 1];        
        System.assertEquals(0, leadlisttest.size());
        System.assertEquals(0, opplisttest.size());
    }
    
    @IsTest
    public static void cloneRecordsTest() {        
        Lead leadTest = [select Id, Account__r.Name, Status, Due_Date__c From Lead where LastName = 'leadtest1' limit 1];
        Lead leadTestNoDuedate = [select Id, Account__r.Name, Status, Due_Date__c From Lead where LastName = 'leadtest2' limit 1];
        leadTestNoDuedate.Due_Date__c = null;
        update leadTestNoDuedate;
        Opportunity oppTest = [select Id, Account.Name, StageName, CloseDate From Opportunity where Name = 'opptest1' limit 1];
        String leadTestString = '[{"BusinessName":"'+leadTest.Account__r.Name+'","DueDate":"'+leadTest.Due_Date__c+'","id":"'+leadTest.Id+'","Index":1,"Status":"'+leadTest.Status+'","Type":"Lead"}]';
        String leadTestNoDuedateString = '[{"BusinessName":"'+leadTestNoDuedate.Account__r.Name+'","DueDate":"'+leadTestNoDuedate.Due_Date__c+'","id":"'+leadTestNoDuedate.Id+'","Index":2,"Status":"'+leadTestNoDuedate.Status+'","Type":"Lead"}]';
        String oppTestString = '[{"BusinessName":"'+oppTest.Account.Name+'","DueDate":"'+oppTest.CloseDate+'","id":"'+oppTest.Id+'","Index":3,"Status":"'+oppTest.StageName+'","Type":"Opportunity"}]';
       
        Test.startTest();
        MyDataTableController.cloneRecords(leadTestString);
        MyDataTableController.cloneRecords(leadTestNoDuedateString);
        MyDataTableController.cloneRecords(oppTestString);
        Test.stopTest(); 
        Date dateTest = Date.valueof('2025-06-02');
        System.assertNotEquals(null, [select Id, Due_Date__c From Lead where Due_Date__c =: dateTest limit 1]);
        System.assertNotEquals(null, [select Id, Due_Date__c From Lead where Due_Date__c = null limit 1]);
        System.assertNotEquals(null, [select Id, CloseDate From Opportunity where CloseDate =: dateTest limit 1]);
    }
    
    @IsTest
    public static void convertRecordsTest() {        
        Lead leadTest = [select Id, Account__r.Name, Status, Due_Date__c, IsConverted  From Lead where LastName = 'leadtest1' limit 1];
        Opportunity oppTest = [select Id, Account.Name, StageName, CloseDate From Opportunity where Name = 'opptest1' limit 1];
        String leadTestString = '[{"BusinessName":"'+leadTest.Account__r.Name+'","DueDate":"'+leadTest.Due_Date__c+'","id":"'+leadTest.Id+'","Index":3,"Status":"'+leadTest.Status+'","Type":"Lead"}]';
        String oppTestString = '[{"BusinessName":"'+oppTest.Account.Name+'","DueDate":"'+oppTest.CloseDate+'","id":"'+oppTest.Id+'","Index":2,"Status":"'+oppTest.StageName+'","Type":"Opportunity"}]';
       
        Test.startTest();
        MyDataTableController.convertRecords(leadTestString);
        MyDataTableController.convertRecords(oppTestString);
        Test.stopTest(); 
        System.assertNotEquals(null, [select Id, IsConverted  From Lead where IsConverted  = true limit 1]);
        System.assertNotEquals(null, [select Id, StageName From Opportunity where StageName = 'Closed Won' limit 1]);
    }
}