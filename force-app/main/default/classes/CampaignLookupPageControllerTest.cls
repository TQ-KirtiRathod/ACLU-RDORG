@isTest
private class CampaignLookupPageControllerTest {
    public static Account ac;
    public static Contact con;
    public static Lead la;
    public static List<CampaignMember> listCampaignMember;
    public static List<Campaign> listCampaign;
    public static RecentlyViewed rec;
    public static Opportunity objOpportunity;
    public static OpportunityLineItem objOpportunityLineItem;
    public static Product2 objProduct;
    public static Pricebook2 objPricebook2;
    public static PricebookEntry objPricebookEntry;
    public static List<rC_Connect__Campaign_Product__c> listRcConnectCampaignProduct;
    public static User u1;
    
    static {
    	// User record
    	u1 = createUser('System Administrator');
    }
    
    @isTest
    Private static void TestCampaignLookupPageControllerTest(){
    	createData();
        Test.startTest();
        //User u1= new User(Id=Userinfo.getUserId(),Is_Affiliate_User__c=true);
        
        System.runAs(u1){  
            
            
            
            PageReference pageRef = Page.Campaign_Lookup_Page;  
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('accId',ac.id);
            ApexPages.currentPage().getParameters().put('deposit','NAtest1');   
            ApexPages.currentPage().getParameters().put('campaignId',listCampaign.get(0).id);
            ApexPages.currentPage().getParameters().put('oppId',objOpportunity.id);     
            CampaignLookupPageController cmp = new CampaignLookupPageController();  
            cmp.runQuery();
            cmp.retrieveCampaignProducts();
            cmp.createOpptyProducts();
            system.assertEquals(true, cmp.showProducts);
         }
        /*ApexPages.currentPage().getParameters().put('accId','test');
ApexPages.currentPage().getParameters().put('deposit','test1'); */  
        Test.stopTest();
    }
    
    @isTest
    Private static void TestCampaignLookupPageControllerTest1(){
    	createData();
        Test.startTest(); 
        //User u1= new User(Id=Userinfo.getUserId(),Is_Affiliate_User__c=False);
        
        System.runAs(u1){  
            
            
            
            PageReference pageRef = Page.Campaign_Lookup_Page;  
            Test.setCurrentPage(pageRef);
            ApexPages.currentPage().getParameters().put('accId','');
            ApexPages.currentPage().getParameters().put('deposit','NAtest1');   
            ApexPages.currentPage().getParameters().put('campaignId',listCampaign.get(0).id);
            ApexPages.currentPage().getParameters().put('oppId',objOpportunity.id);     
            CampaignLookupPageController cmp = new CampaignLookupPageController();  
            cmp.runQuery();
            cmp.retrieveCampaignProducts();
            cmp.createOpptyProducts();
            List<CampaignLookupPageController.campaignWrapper> lstcampaignWrapper = new List<CampaignLookupPageController.campaignWrapper>();
            CampaignLookupPageController.campaignWrapper cw = new CampaignLookupPageController.campaignWrapper(true , null);
            lstcampaignWrapper.add(cw);
            cmp.campaignProductsWrapper = lstcampaignWrapper;
            cmp.createOpptyProducts();
            system.assert(lstcampaignWrapper.size() > 0);
        }
        /*ApexPages.currentPage().getParameters().put('accId','test');
ApexPages.currentPage().getParameters().put('deposit','test1'); */  
        Test.stopTest();
    }
    @IsTest
    public static void validateExceptionBlock(){
    	createData();
         Test.startTest(); 
        //User u1= new User(Id=Userinfo.getUserId(),Is_Affiliate_User__c=False);
        
        System.runAs(u1){
            PageReference pageRef = Page.Campaign_Lookup_Page;  
            Test.setCurrentPage(pageRef);
            // Hard Coded Ids are used for handling exception blocks 
            ApexPages.currentPage().getParameters().put('accId','001W000000P2wBQ');
            ApexPages.currentPage().getParameters().put('deposit','001W000000P2wBQ');   
            ApexPages.currentPage().getParameters().put('campaignId','001W000000P2wBQ');
            ApexPages.currentPage().getParameters().put('oppId','001W000000P2wBQ');     
            CampaignLookupPageController cmp = new CampaignLookupPageController();  
            cmp.runQuery();
            cmp.retrieveCampaignProducts();
            cmp.createOpptyProducts();
            CampaignLookupPageController.campaignWrapper cw = new CampaignLookupPageController.campaignWrapper(true , null);
            system.assertEquals(true, cmp.showProducts);
        }
        /*ApexPages.currentPage().getParameters().put('accId','test');
ApexPages.currentPage().getParameters().put('deposit','test1'); */  
        Test.stopTest();
    }
    public static void createData(){
        objProduct = createProduct('Test',True,False);      
        insert  objProduct; 
        listCampaignMember = new List<CampaignMember>(); 
        listCampaign = new List<Campaign>();
        
        listRcConnectCampaignProduct= new List<rC_Connect__Campaign_Product__c>(); 
        ac = createAccount('Test',True);
        
        
        Contact con = createContact(ac,'TestFirst','TestLast',False);
        con.rC_Bios__Preferred_Contact__c=true; 
        insert con;
        
        for(Integer i=0;i<10;i++){
            Campaign cmp=createCampaign('TestCamp'+i,False);
            cmp.rC_Giving__Source_Code__c='test';
            cmp.rC_Giving__Sub_Affiliation__c='5 - Affiliate Foundation'; 
            listCampaign.add(cmp);   
        } 
        insert listCampaign; 
        
        
        Lead la= createLead('test','Test','Test',false);
        la.SB_Campaign_Id__c = '701W000000043A3';
        insert la;
        
        
        
        for(Integer i=0;i<10;i++){
            CampaignMember cm = createCampaignMember(listCampaign.get(i).id, la.id, False);
            listCampaignMember.add(cm);
            
        } 
        Insert  listCampaignMember;
        
        objOpportunity =  createOpportunity(ac.id,'Test',true);
        // objPricebook2= TestUtils.createPriceBook('test',True);
        objPricebookEntry=createPriceBookEntry(objProduct.Id,True);
        
        objOpportunityLineItem=createOpportunityLineItem(objOpportunity.Id,objPricebookEntry.Id,True);
        
        
        
        for(Integer i=0;i<10;i++){
            rC_Connect__Campaign_Product__c c= new rC_Connect__Campaign_Product__c();
            //  c.Name='test'+i;
            // c.rC_Connect__Product__c=objProduct.Id;
            //System.debug(';;;;'+objProduct.Id);
            // c.rC_Connect__Product__c=objProduct.Id;
            c.rC_Connect__Campaign__c=listCampaign.get(i).id;
            listRcConnectCampaignProduct.add(c);
        } 
        insert listRcConnectCampaignProduct;
        /* rec = new RecentlyViewed();
//rec.Name='test';
rec.Type='Campaign';
rec.LastViewedDate=Date.today();
insert rec; */
    }
    
    private static User createUser(String profileName){
        User testUser = new User();
        Profile p = [SELECT Id FROM Profile WHERE Name = :profileName][0];
        testUser.ProfileId = p.id;
        testUser.FirstName = 'testUser';
        testUser.LastName = profileName;
        testUser.Username = 'testUser' + '@email.com'+'.random1';
        testUser.Email = 'puser000@aclu.org';
        testUser.Alias = 'testUser';
        testUser.CommunityNickname = 'testUser';
        testUser.LanguageLocaleKey = 'en_US';
        testUser.LocaleSidKey = 'en_US';
        testUser.EmailEncodingKey = 'UTF-8';
        testUser.TimeZoneSidKey = 'America/Los_Angeles';
        //testUser.IsActive = true;
        testUser.Department = 'Executive/Admin';
        testUser.Is_Affiliate_User__c=true;
        return testUser;
    }
    
    public static campaign createCampaign(String Name, Boolean doInsert){
        campaign camp = new campaign(Name = Name);
        if(doInsert)
            insert camp;
        return camp;
    }
    
    public static Lead createLead(String name,String company, String status,Boolean doInsert){
        Lead ld = new Lead(LastName = name, Company=company,Status=status);
        if(doInsert)
            insert ld;
        return ld;
    }
    
    public static Contact createContact(Account acc, String firstName, String lastName, Boolean doInsert){
        Contact contact = new Contact(FirstName = firstName, LastName = lastName , 
                                      rC_Bios__Birth_Day__c = '02', rC_Bios__Birth_Month__c = '04',
                                      rC_Bios__Birth_Year__c='2002');
        if(acc != null)
            contact.AccountId = acc.id;
       
        if(doInsert)
            insert contact;
            
        return contact;
    }
    
    
    public static Product2 createProduct(String Name,Boolean isActive,Boolean doInsert){
        Product2 p2 = new Product2(Name= Name,isActive=isActive);
        if(doInsert)
            insert p2;
        return p2;
    }
    
    public static Account createAccount(String name, Boolean doInsert){
        Account acc = new Account(Name = name);
        if(doInsert)
            insert acc;
        return acc;
    }
    
    public static CampaignMember createCampaignMember(Id campaignId,Id leadId, Boolean doInsert){
        CampaignMember cm = new CampaignMember(CampaignId=campaignId,LeadId = leadId); 
        if(doInsert)
            insert cm;
        return cm;
    }
    
    public static Opportunity createOpportunity(Id AccountId, String Name, Boolean doInsert){
        
    	Opportunity opp = new Opportunity(rC_Giving__Affiliation__c = 'NGO', rC_Giving__Giving_Amount__c = 20,
                                          AccountId = AccountId ,Name = Name, CloseDate = Date.Today(),StageName = 'Prospecting');
        if(doInsert)
            insert opp;
        return opp;
    }
    
    public static OpportunityLineItem createOpportunityLineItem(Id OppId,Id priceBookEntryId,Boolean doInsert){
        OpportunityLineItem oppLineItem = new OpportunityLineItem(OpportunityId=OppId,PriceBookEntryId=priceBookEntryId,Quantity=4,totalprice=200);
        if(doInsert) {
        	insert oppLineItem;
    	}
    	return oppLineItem;
    }
    
    public static PricebookEntry createPriceBookEntry(Id productId, Boolean doInsert) {
        Id pricebookId = Test.getStandardPricebookId();
        
        PricebookEntry testPriceBookEntry = new PricebookEntry( Pricebook2Id = priceBookId,
                                                            UnitPrice = 12000, IsActive = true,                                                           
                                                            UseStandardPrice=false,
                                                            Product2Id = productId);
   
     
    	if(doInsert) {
      		insert testPriceBookEntry;
    	}
    	return testPriceBookEntry;
  }
}