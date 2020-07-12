/**
 * Test Class for EventRegistratingController
 **/
@isTest(seeAllData = false)
private class EventRegistratingControllerTest {
    private static testMethod void testEventRegistratingController(){
    	
    	Test.startTest();
        User sysAdmin = TestUtils.createUser('Admin', 'testUser@email.com.random1', null, true);
        Account testacc1 = new Account(Name = 'testAcc1');
        insert testacc1;
        List<Opportunity> oppList = new List<Opportunity>();
        String DonationId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Donation').getRecordTypeId();
        for(integer i=0; i<150; i++){
            Opportunity tempOpp = new Opportunity();
            tempOpp.RecordTypeId = DonationId;
            tempOpp.rC_Giving__Affiliation__c = 'NGO';
            tempOpp.rC_Giving__Giving_Amount__c = 20;
            tempOpp.AccountId = testacc1.Id;
            tempOpp.Name = 'testOpp'+i;
            tempOpp.CloseDate = Date.Today();
            tempOpp.StageName = 'Prospecting';
			oppList.add(tempOpp);
        }
        
        System.runAs(sysAdmin){
             if(oppList.size()>0){
            insert oppList;
        }
        Opportunity testOpp1 = oppList.get(0);
        
        Campaign testCampaign1;
        Lead testLead1 = new Lead(LastName = 'testLead1', Company='leadCompany',Status='open');
        insert testLead1;
            
        CampaignMember testCampaignMember1 = new CampaignMember();
        
        Product2 testProd1 = new Product2(Name= 'test product',isActive=true);
        testProd1.family = 'test family';
        testProd1.isAd__c = true;
        testProd1.RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('Item').getRecordTypeId();
        insert testProd1;
        
        PricebookEntry testPB = new PricebookEntry();
        testPB.UseStandardPrice=false;
        testPB.Product2Id = testProd1.Id;
        testPB.UnitPrice = 300;
        testPB.PriceBook2Id = Test.getStandardPricebookId();
        testPB.IsActive = true;
        insert testPB;
        
        OpportunityLineItem testOppLine1 = new OpportunityLineItem();
        testOppLine1.OpportunityId=testOpp1.Id;
        testOppLine1.PriceBookEntryId=testPB.Id;
        testOppLine1.TotalPrice=2000;
        testOppLine1.Quantity = 2;
		insert testOppLine1;
        Test.stopTest();
        testOpp1 = [SELECT Id, Name, Account.Name, RecordType.Name,
  					(SELECT Quantity, UnitPrice, TotalPrice, PricebookEntry.Name, PricebookEntry.Product2.Family,
                     Product2.name,Product2.isAd__c,Product2.isDiscount_Item__c FROM OpportunityLineItems) 
                    FROM Opportunity WHERE name= 'testOpp0'][0];
        
        //Since Campaign and CampaignMember needs special User Permissions to be created, using an Admin so that 
        //no matter which user is logged in, they get created
       
            testCampaign1 = new campaign(Name ='testCampaign1');
            insert testCampaign1;
            testCampaignMember1 = new CampaignMember(CampaignId=testCampaign1.id,LeadId = testLead1.Id);
            testCampaignMember1.Opportunity__c = testOpp1.Id;
            insert testCampaignMember1;
        
        oppList.clear(); //clearing the previously populated oppList List
        for(Opportunity tempOpp: [SELECT id, CampaignId FROM Opportunity WHERE name LIKE 'testOpp%']){
            tempOpp.CampaignId = testCampaign1.Id;
            oppList.add(tempOpp);
        }
        update oppList;        
        
        testOpp1 = [SELECT Id, Name, Account.Name, RecordType.Name,CampaignId,
  					(SELECT Quantity, UnitPrice, TotalPrice, PricebookEntry.Name, PricebookEntry.Product2.Family,
                     Product2.name,Product2.isAd__c,Product2.isDiscount_Item__c FROM OpportunityLineItems) 
                    FROM Opportunity WHERE name= 'testOpp1'][0];
        
        testCampaignMember1 = [SELECT Id, Name, Opportunity__c FROM CampaignMember][0];
        
        //setting the current page reference
        Test.setCurrentPage(Page.Event_Registration_Page);
        //setting the URL parameters of the page
        ApexPages.CurrentPage().getParameters().put('camId', testCampaign1.Id);
        ApexPages.CurrentPage().getParameters().put('selOppId', testOpp1.Id);
        ApexPages.CurrentPage().getParameters().put('selOppRow', '1');
        ApexPages.CurrentPage().getParameters().put('selRec', '1');
        
        //creating the instance of the controller of the VF page
        eventRegistratingController erc = new eventRegistratingController();
        erc.SortingOrder = 'Desc';
        erc.sortName();
        erc.getRegistrations();
        erc.addCampaingMemeber();
        erc.savenewCampaignMember();
        
        boolean isHasNext = erc.hasNext;
        boolean isHasPrevious = erc.hasPrevious;
        System.assertEquals(true,isHasNext);
        System.assertEquals(false,isHasPrevious);	//since it is the first batch of 50 records out of total 100
        											//(Total opp inserted are 150, but in controller, in query, its LIMIT 100)
        															
        erc.deleteCmMember();
        erc.closeSec();
        
        erc.next();
        isHasNext = erc.hasNext;
        isHasPrevious = erc.hasPrevious;
        System.assertEquals(false,isHasNext);		//since all 100 records have been loaded	
        System.assertEquals(true,isHasPrevious);	//since it is the second batch of 50 records out of total 100
        
        erc.manageSeat();
        erc.campaignAttributes();
        erc.newPledge();
        erc.saveCampaignMembers();
        
        //calling the registrationWrapper Wrapper functionalities
        eventRegistratingController.registrationWrapper ercWrap = new eventRegistratingController.registrationWrapper(testOpp1,2,null);
		//calling the campaignMemberWrapper Wrapper functionalities
        eventRegistratingController.campaignMemberWrapper campMembWrap = new eventRegistratingController.campaignMemberWrapper(2,testCampaignMember1);
        erc.SortingOrder = 'ASC';
        erc.sortName();
            
        erc.previous();
        isHasNext = erc.hasNext;
        isHasPrevious = erc.hasPrevious;
        System.assertEquals(true,isHasNext);		//since we are on batch 1 again	
        System.assertEquals(false,isHasPrevious);	
        }
    }
}