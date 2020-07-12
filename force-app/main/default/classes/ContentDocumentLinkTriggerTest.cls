/**
 Test Class for ContentDocumentLinkTriggerHandler
 */
@isTest
private class ContentDocumentLinkTriggerTest {
    static list<Opportunity> oppList;
    static list<Campaign> cmpList;
    static list<ContentDocumentLink> contentlinkList;
    static Account acc;
    
    //Verify Document Attached Flag on Opportunity
    @isTest
    static void testContent()
    {   
       User u =TestUtils.createUser('LastNameTest', 'UserName####$@gmail.com',null,false);
        u.Is_Affiliate_User__c=true;
        insert u;
       system.runAs(u) {
            createTestData();
            test.starttest();
            for(Integer i=0; i<5; i++) {
                contentlinkList[i].LinkedEntityId=oppList[i].id;
            }
            insert contentlinkList;
            test.stoptest();
            for(Opportunity op : [SELECT Set_Document_Attached__c FROM Opportunity WHERE Id IN :oppList]) {
                system.assertEquals(true, op.Set_Document_Attached__c);
            }
       }
    }
    
    //Verify Document Attached Flag on Campaign
    @isTest
    static void testContentCampaign()
    {   
        User u =TestUtils.createUser('LastNameTest', 'UserName####$@gmail.com',null,false);
        u.Is_Affiliate_User__c=true;
        insert u;
        system.runAs(u) {
            createTestData();
            test.starttest();
            for(Integer i=0; i<5; i++) {
                contentlinkList[i].LinkedEntityId=cmpList[i].id;
            }
            
            insert contentlinkList;
            test.stoptest();
            for(Campaign c : [SELECT Set_Document_Attached__c FROM Campaign WHERE Id IN :cmpList]) {
                system.assertEquals(true, c.Set_Document_Attached__c);
            }
        }
    }
    
    @isTest
    static void testContentAccount()
    {   
        User u =TestUtils.createUser('LastNameTest', 'UserName####$@gmail.com',null,false);
        u.Is_Affiliate_User__c=true;
        insert u;
        system.runAs(u) {
            createTestData();
            test.starttest();
            contentlinkList[0].LinkedEntityId=acc.id;
            insert contentlinkList[0];
            test.stoptest();
            system.assert(contentlinkList.size() > 0);
        }
    }
    @isTest
    static void testContentContact()
    {   
        User u =TestUtils.createUser('LastNameTest', 'UserName####$@gmail.com',null,false);
        u.Is_Affiliate_User__c=true;
        insert u;
        system.runAs(u) {
            acc = TestUtils.createAccount('Account1',true);
           
            List<Contact> conList = new List<Contact>();
            for(integer i = 0;i<5;i++) {
                Contact conObj = new Contact();
                conObj.LastName = 'test'+i;
                conObj.AccountId = acc.id;
                conList.add(conObj);
            }
            insert conList;
            createContentData();
            for(Integer i=0; i<5; i++) {
                contentlinkList[i].LinkedEntityId=conList[i].id;
            }
            
            test.starttest();            
            insert contentlinkList;
            test.stoptest();
            system.assert(contentlinkList.size() > 0);
        }
    }
    @isTest
    static void testPlannedGivingContent()
    {   
        User u =TestUtils.createUser('LastNameTest', 'UserName####$@gmail.com',null,false);
        u.Is_Affiliate_User__c=true;
        insert u;
        system.runAs(u) {
            acc = TestUtils.createAccount('Account1',true);
            List<rC_Giving__Planned_Giving__c> plannedGivingList = new List<rC_Giving__Planned_Giving__c>();
            for(integer i = 0;i<5;i++) {
                rC_Giving__Planned_Giving__c plannedGivingObj = new rC_Giving__Planned_Giving__c();
                plannedGivingObj.Name = 'test'+i;
                plannedGivingObj.rC_Giving__Account__c = acc.id;
                plannedGivingList.add(plannedGivingObj);
            }
            insert plannedGivingList;
            createContentData();
            for(Integer i=0; i<5; i++) {
                contentlinkList[i].LinkedEntityId=plannedGivingList[i].id;
            }
            
            test.starttest();            
            insert contentlinkList;
            test.stoptest();
            system.assert(contentlinkList.size() > 0);
        }
    }
    @isTest
    static void testProspectReseachContent()
    {   
        User u =TestUtils.createUser('LastNameTest', 'UserName####$@gmail.com',null,false);
        u.Is_Affiliate_User__c=true;
        insert u;
        system.runAs(u) {
            acc = TestUtils.createAccount('Account1',true);
            List<Prospect_Research__c> prospectReseachList = new List<Prospect_Research__c>();
            for(integer i = 0;i<5;i++) {
                Prospect_Research__c prospectResearchObj = new Prospect_Research__c();
                //prospectResearch = 'test'+i;
                prospectResearchObj.Account__c = acc.id;
                prospectReseachList.add(prospectResearchObj);
            }
            insert prospectReseachList;
            createContentData();
            for(Integer i=0; i<5; i++) {
                contentlinkList[i].LinkedEntityId=prospectReseachList[i].id;
            }
            
            test.starttest();            
            insert contentlinkList;
            test.stoptest();
            system.assert(contentlinkList.size() > 0);
        }
    }
    @isTest
    static void testTaskContent()
    {   
        User u =TestUtils.createUser('LastNameTest', 'UserName####$@gmail.com',null,false);
        u.Is_Affiliate_User__c=true;
        insert u;
        system.runAs(u) {
            acc = TestUtils.createAccount('Account1',true);
            List<Task> taskList = new List<Task>();
            for(integer i = 0;i<5;i++) {
                Task taskObj = new Task();
                //prospectResearch = 
                taskObj.Subject = 'test'+i;
                taskObj.priority = 'Normal';
                taskObj.whatId = acc.Id;
                taskList.add(taskObj);
            }
            insert taskList;
            createContentData();
            for(Integer i=0; i<5; i++) {
                contentlinkList[i].LinkedEntityId=taskList[i].id;
            }
            
            test.starttest();            
            insert contentlinkList;
            test.stoptest();
            system.assert(contentlinkList.size() > 0);
        }
    }
    @isTest
    static void testEventContent()
    {   
        User u =TestUtils.createUser('LastNameTest', 'UserName####$@gmail.com',null,false);
        u.Is_Affiliate_User__c=true;
        insert u;
        system.runAs(u) {
            acc = TestUtils.createAccount('Account1',true);
            List<Event> eventList = new List<Event>();
            for(integer i = 0;i<5;i++) {
                Event eventObj = new Event();
                //prospectResearch = 
                eventObj.Subject = 'test'+i;
                eventObj.StartDateTime = System.now();
                eventObj.EndDateTime = System.now();
                eventObj.whatId = acc.Id;
                eventList.add(eventObj);
            }
            insert eventList;
            createContentData();
            for(Integer i=0; i<5; i++) {
                contentlinkList[i].LinkedEntityId=eventList[i].id;
            }
            
            test.starttest();            
            insert contentlinkList;
            test.stoptest();
            system.assert(contentlinkList.size() > 0);
        }
    }
    static void createTestData() {
        acc = TestUtils.createAccount('Account1',true);
        Campaign cmp;
        cmpList = new list<Campaign>();
        for(Integer i=0; i<5; i++) {
            cmp = TestUtils.createCampaign('CampaignTest'+i, false);
            cmp.rC_Giving__Affiliation__c = 'AK - ACLU of Alaska';
            cmp.rC_Giving__Sub_Affiliation__c = '6 - Misc. Giving';
            cmp.rC_Giving__Campaign_Type__c = 'S - Special Appeal/Direct Mail';
            cmpList.add(cmp);
        }
        insert cmpList;
        oppList = new list<Opportunity>();
        Opportunity opp;
        for(Integer i=0; i<5; i++) {
            opp = TestUtils.createOpportunity(acc.Id, 'TestOpp', false);
            opp.CampaignId = cmpList[i].Id;
            oppList.add(opp);
        }
        insert oppList;
        for(Opportunity op : oppList) {
            op.Campaign_Type__c = 'G';
        }
        update oppList;
        
        ContentVersion content=new ContentVersion(); 
        content.Title='Header_Picture1'; 
        content.PathOnClient='/' + content.Title + '.jpg'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob; 
        content.origin = 'H';
        insert content;
        Id cId = [select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlinkList = new list<ContentDocumentLink>();
        ContentDocumentLink contentlink;
        for(Integer i=0; i<5; i++) {
            contentlink=new ContentDocumentLink();
            contentlink.contentdocumentid=cId;
            contentlink.ShareType = 'V';
            contentlinkList.add(contentlink);
        }
        
    }
    static void createContentData() {
        ContentVersion content=new ContentVersion(); 
        content.Title='Header_Picture1'; 
        content.PathOnClient='/' + content.Title + '.jpg'; 
        Blob bodyBlob=Blob.valueOf('Unit Test ContentVersion Body'); 
        content.VersionData=bodyBlob; 
        content.origin = 'H';
        insert content;
        Id cId = [select contentdocumentid from contentversion where id =: content.id].contentdocumentid;
        contentlinkList = new list<ContentDocumentLink>();
        ContentDocumentLink contentlink;
        for(Integer i=0; i<5; i++) {
            contentlink=new ContentDocumentLink();
            contentlink.contentdocumentid=cId;
            contentlink.ShareType = 'V';
            contentlinkList.add(contentlink);
        }
        
    }
    
}