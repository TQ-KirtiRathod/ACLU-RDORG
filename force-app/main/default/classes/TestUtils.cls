/***********************************************************************************************************
 * Appirio, Inc
 * Name         : TestUtils
 * Created By   : Ashu Gupta
 * Purpose      : Test class utility
 * Created Date : Oct 25,2016
 *
 * Date Modified                Modified By             Description of the update
  ----------------------------------------------------------------------------------------------------------
 * Nov 15,2016                 SaiKrishna               Added the createGroup Method
 * Nov 16,2016                 SaiKrishna               Added the Relationship,ActionPlan,
                                                        PaymentMethod,FSalutation,preferences and Planned Giving Methods
 * Nov 23,2016                 SaiKrishna               Added the Opportunity NGOC objects lookups
 **********************************************************************************************************/

public with sharing class TestUtils {
    // Create multiple accounts
    public static list<Account> createAccounts(Boolean doInsert){
        List<Account> accList = new List<Account>();
        for(integer i=0;i<10;i++)
            { 
             accList.add(TestUtils.createAccount('Test'+i,false));
             accList.get(i).Account_Type__c='Matching Company';
             accList.get(i).accountNumber='123';
             accList.get(i).External_ID__c = '003112'+i;
             accList.get(i).BillingStreet=' street abc'+i;
             accList.get(i).BillingCity='city'+i;
             accList.get(i).BillingState='state'+i;
             accList.get(i).BillingCountry='Ind';
             accList.get(i).BillingpostalCode='302039';
            }
            if(doInsert)
                insert accList;
            return accList;
    }
    // create single account
    public static Account createAccount(String name, Boolean doInsert){
        Account acc = new Account(Name = name);
        if(doInsert)
            insert acc;
        return acc;
    }

    // Create specified number of accounts (DS - May 2019)
    public static list<Account> createAccounts(Integer listSize, Boolean doInsert){
        List<Account> accList = new List<Account>();
        for(integer i=0;i<listSize;i++)
            { 
             accList.add(TestUtils.createAccount('Test'+i,false));
             accList.get(i).Account_Type__c='Matching Company';
             accList.get(i).accountNumber='123';
             accList.get(i).External_ID__c = '003112'+i;
             accList.get(i).BillingStreet=' street abc'+i;
             accList.get(i).BillingCity='city'+i;
             accList.get(i).BillingState='state'+i;
             accList.get(i).BillingCountry='Ind';
             accList.get(i).BillingpostalCode='302039';
            }
            if(doInsert)
                insert accList;
            return accList;
    }
    
    public static Batch_Log__c batchLog(String name, Boolean doInsert){
        Batch_Log__c bL = new Batch_Log__c (Name = name);
        
        if(doInsert)
            insert bL;
            
        return bL;
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
    
     public static Affiliate_Yearly__c createAffiliateYearly(String name,Id accountId, String fiscalYear, Boolean doInsert){
        Affiliate_Yearly__c aff = new Affiliate_Yearly__c(Name = name, Fiscal_Year__c = fiscalYear);
        if(accountId != null)
            
            aff.Account__c = accountId;
        if(doInsert)
            insert aff;
        return aff;
    }
    
     public static National_Fiscal_Year__c createFiscalyearCSData(String name, String fiscalYear,Integer unionCostFactor,
                                                    Integer foundationCostFactor, Integer percentGMIAffiliates, Boolean doInsert){
        National_Fiscal_Year__c NFY = new National_Fiscal_Year__c(Name = name, Fiscal_Year__c = fiscalYear,
                                                    Foundation_Cost_Factor__c = foundationCostFactor,Percent_GMI_Affiliates__c = percentGMIAffiliates,Union_Cost_Factor__c = unionCostFactor);
       
       
        if(doInsert)
            insert NFY;
        return NFY;
    }
     public static Zip_Affiliate__c createZipAffiliate(String name,Boolean doInsert){
        Zip_Affiliate__c ZipAff = new Zip_Affiliate__c(Name = name);
       
       
        if(doInsert)
            insert ZipAff;
        return ZipAff;
    }
    
    public static Email__c createEmail(Id conId,String emailAddr,Boolean doInsert){
     
        Email__c email = new Email__c(Contact__c = conId,Email_address__c = emailAddr);
       
       
        if(doInsert)
            insert email;
            
        Email_Preference__c ep = new Email_Preference__c(Email__c = email.Id, Email_List_Code__c = 'AL');
        
        if(doInsert) {
            insert ep;
        }
        return email;
    }
    
    public static Phone__c createPhone(Id conId,String phoneNumber,Boolean doInsert){
     
        Phone__c phone = new Phone__c(Contact__c = conId,Phone_Number__c = phoneNumber);
       
        if(doInsert)
            insert phone;
        return phone;
    }
    
    public static rC_Connect__Batch_Upload__c createBatchUpload(String name,String acquisitionUploadSource,Id contact1ID,String contact1Email,Boolean doInsert){
        rC_Connect__Batch_Upload__c batchUpload = new rC_Connect__Batch_Upload__c(Name = name,SB_Acquisition_Upload_source__c = acquisitionUploadSource,rC_Connect__Batch_Upload_Contact_1_Matched__c = contact1ID,Cont1_Email__c = contact1Email, Cont1_OptIn__c = true, Additional_Opt_In_Lists__c ='test', rC_Connect__Contact_1_Phone_1__c = '12345');
       
       
        if(doInsert)
            insert batchUpload;
        return batchUpload;
    }
    
    public static Group createGroup(String name,Boolean doInsert){
        Group Grp = new Group(Name = name);
        if(doInsert)
            insert Grp;
        return Grp;
    }
    
    
    public static rC_Bios__Preference__c createPreferences(Id AccountId, Boolean doInsert){
        rC_Bios__Preference__c Prefe = new rC_Bios__Preference__c(rC_Bios__Account__c = AccountId, rC_Bios__Code_Value__c='123', rC_Bios__Category__c = 'Benefits');
        if(doInsert)
            insert Prefe;
        return Prefe;
    }
    
    public static rC_Bios__Preference__c createPreferencesUsingContact(Id ContactId, Boolean doInsert){
        rC_Bios__Preference__c Prefe = new rC_Bios__Preference__c(rC_Bios__Contact__c = ContactId, rC_Bios__Code_Value__c='123', rC_Bios__Category__c = 'Benefits');
        if(doInsert)
            insert Prefe;
        return Prefe;
    }

    public static rC_Bios__Preference__c createPreferences(Id accountId, String codeValue, String category, Date startDate, Date EndDate, Boolean doInsert){
        rC_Bios__Preference__c Pref = new rC_Bios__Preference__c(rC_Bios__Account__c = accountId, rC_Bios__Code_Value__c = codeValue, rC_Bios__Category__c = category, rC_Bios__Start_Date__c = startDate, rC_Bios__End_Date__c = endDate);
        if(doInsert)
            insert Pref;
        return Pref;
    }

    public static void createPreferenceCodes() {
        List<rC_Bios__Preference_Code__c> pcs = new List<rC_Bios__Preference_Code__c>{
            new rC_Bios__Preference_Code__c(rC_Bios__Code_Value__c = 'BLANK1', 
                                            Description__c = 'BLANK1'),
            new rC_Bios__Preference_Code__c(rC_Bios__Code_Value__c = 'BLANK2', 
                                                Description__c = 'BLANK2'),
            new rC_Bios__Preference_Code__c(rC_Bios__Code_Value__c = 'TEST1', 
                                                rC_Bios__Category__c = 'Programmatic', 
                                                rC_Bios__Subcategory__c = 'Major Gifts', 
                                                rC_Bios__Type__c = 'M1', 
                                                rC_Bios__Subtype__c = 'Top Prospects', 
                                                Description__c = 'TEST1'),
            new rC_Bios__Preference_Code__c(rC_Bios__Code_Value__c = 'TEST2', 
                                                rC_Bios__Category__c = 'TESTC', 
                                                Description__c = 'TEST2'),
            new rC_Bios__Preference_Code__c(rC_Bios__Code_Value__c = 'TEST3', 
                                                rC_Bios__Category__c = 'Programmatic', 
                                                rC_Bios__Subcategory__c = 'Major Gifts', 
                                                rC_Bios__Type__c = 'M1', 
                                                rC_Bios__Subtype__c = 'Top Prospects', 
                                                Description__c = 'TEST3'),
            new rC_Bios__Preference_Code__c(rC_Bios__Code_Value__c = 'TEST4', 
                                                rC_Bios__Category__c = 'Programmatic', 
                                                rC_Bios__Subcategory__c = 'Major Gifts', 
                                                rC_Bios__Type__c = 'M1', 
                                                rC_Bios__Subtype__c = 'Top Prospects', 
                                                Description__c = 'TEST4'),
            new rC_Bios__Preference_Code__c(rC_Bios__Code_Value__c = ACLUMergeManager.LEGACY_DUPLICATE_PREFCODE, 
                                                rC_Bios__Category__c = 'Programmatic', 
                                                rC_Bios__Subcategory__c = 'Major Gifts', 
                                                rC_Bios__Type__c = 'M1', 
                                                rC_Bios__Subtype__c = 'Top Prospects', 
                                                Description__c = 'DUPLICATE')};
            for (String preservePrefCode : ACLUMergeManager.PRESERVE_ALL_PREFCODES) {
                rC_Bios__Preference_Code__c ppc = new rC_Bios__Preference_Code__c(rC_Bios__Code_Value__c = preservePrefCode, 
                                                    Description__c = 'PRESERVE', 
                                                rC_Bios__Category__c = 'Programmatic', 
                                                rC_Bios__Subcategory__c = 'Major Gifts', 
                                                rC_Bios__Type__c = 'M1', 
                                                rC_Bios__Subtype__c = 'Top Prospects');
                pcs.add(ppc);
            }
            for (String preserveMostRecentPrefCode : ACLUMergeManager.PRESERVE_MOST_RECENT_PREFCODES) {
                rC_Bios__Preference_Code__c ppc = new rC_Bios__Preference_Code__c(rC_Bios__Code_Value__c = preserveMostRecentPrefCode, 
                                                    Description__c = 'PRESERVE MOST RECENT', 
                                                rC_Bios__Category__c = 'Programmatic', 
                                                rC_Bios__Subcategory__c = 'Major Gifts', 
                                                rC_Bios__Type__c = 'M1', 
                                                rC_Bios__Subtype__c = 'Top Prospects' );
                pcs.add(ppc);
            }
            for (rC_Bios__Preference_Code__c pc : pcs) {
            system.debug('PCS: ' + pc.rC_Bios__Code_Value__c);}
        insert pcs;
    }
    
    
    public static rC_Bios__Relationship__c createRelationShip(Id AccountId, Id Account2Id, Boolean doInsert){
        rC_Bios__Relationship__c RS = new rC_Bios__Relationship__c(rC_Bios__Account_1__c = AccountId, rC_Bios__Account_2__c = Account2Id);
        if(doInsert)
            insert RS;
        return RS;
    }
    
    public static rC_Bios__Relationship__c createRelationShipUsingContact(Id contactId, Id contact2Id, Boolean doInsert){
        rC_Bios__Relationship__c RS = new rC_Bios__Relationship__c( rC_Bios__Contact_1__c = contactId,  rC_Bios__Contact_2__c = contact2Id);
        if(doInsert)
            insert RS;
        return RS;
    }
    
    public static rC_Bios__Relationship__c createRelationShipUsingOpportunity(Id accountId, Id OpportunityId, Boolean doInsert){
        rC_Bios__Relationship__c RS = new rC_Bios__Relationship__c( rC_Bios__Account_1__c = accountId, rC_Bios__Opportunity__c = OpportunityId);
        if(doInsert)
            insert RS;
        return RS;
    }
    
    public static rC_Giving__Payment_Method__c createPaymentMethod(Id AccountId, Boolean doInsert){
        rC_Giving__Payment_Method__c PM = new rC_Giving__Payment_Method__c(rC_Giving__Account__c = AccountId,RecordTypeId = Schema.SObjectType.rC_Giving__Payment_Method__c.getRecordTypeInfosByName().get('Cash/Check').getRecordTypeId());
        if(doInsert)
            insert PM;
        return PM;
    }
    
    
    public static rC_Bios__Salutation__c createSalutation(Id AccountId, Boolean doInsert){
        rC_Bios__Salutation__c Sl = new rC_Bios__Salutation__c(rC_Bios__Account__c = AccountId);
        if(doInsert)
            insert Sl;
        return Sl;
    }
    
    public static rC_Bios__Salutation__c createSalutationUsingContact(Id contactId, Boolean doInsert){
        rC_Bios__Salutation__c Sl = new rC_Bios__Salutation__c(rC_Bios__Contact__c = contactId);
        if(doInsert)
            insert Sl;
        return Sl;
    }
    
    public static rC_Giving__Planned_Giving__c createPlannedGiving(Id AccountId, Id Account2Id, Boolean doInsert){
        rC_Giving__Planned_Giving__c Pg = new rC_Giving__Planned_Giving__c(rC_Giving__Account__c = AccountId, rC_Giving__Fund__c = Account2Id);
        if(doInsert)
            insert Pg;
        return Pg;
    }
    
    public static rC_Bios__Action_Plan__c createActionPlan(Id AccountId, Boolean doInsert){
        rC_Bios__Action_Plan__c Ap = new rC_Bios__Action_Plan__c(rC_Bios__WhatId__c = AccountId);
        if(doInsert)
            insert Ap;
        return Ap;
    }
    public static rC_Bios__Action_Plan__c createBiosActionPlan(Id AccountId, Boolean doInsert){
        rC_Bios__Action_Plan__c Ap = new rC_Bios__Action_Plan__c(rC_Bios__Account__c = AccountId);
        if(doInsert)
            insert Ap;
        return Ap;
    }
    public static rC_Bios__Action_Plan__c createActionPlanUsingContact(Id contactId, Boolean doInsert){
        rC_Bios__Action_Plan__c Ap = new rC_Bios__Action_Plan__c(rC_Bios__WhatId__c = contactId);
        if(doInsert)
            insert Ap;
        return Ap;
    }
    
    public static Prospect_Research__c createProspectResearch(Id contactId, Boolean doInsert){
        Prospect_Research__c pr = new Prospect_Research__c(Contact__c= contactId);
        if(doInsert)
            insert pr;
        return pr;
    }
    
    public static rC_Bios__Address__c createAddress(String addName, Boolean doInsert){
        rC_Bios__Address__c address = new rC_Bios__Address__c(name = addName);
        if(doInsert)
            insert address;
        return address;
    }
    
    public static rC_Bios__Account_Address__c createAccountAddress(Id addressId, Id accountId, Boolean doInsert){
        rC_Bios__Account_Address__c accAddress = new rC_Bios__Account_Address__c(rC_Bios__Address__c = addressId, rC_Bios__Account__c = accountId);
        if(doInsert)
            insert accAddress;
        return accAddress;
    }

     public static rC_Bios__Contact_Address__c createContactAddress(Id addressId, Id contactId, Boolean doInsert){
        rC_Bios__Contact_Address__c conAddress = new rC_Bios__Contact_Address__c(rC_Bios__Address__c = addressId, rC_Bios__Contact__c = contactId);
        if(doInsert)
            insert conAddress;
        return conAddress;
    }
    
    public static Confidential_Data__c createConfidentialData(Id accountId,Id contactId,Id oppId, Boolean doInsert){
        Confidential_Data__c cdata = new Confidential_Data__c(Account__c = accountId, Contact__c = contactId,Opportunity__c = oppId);
        if(doInsert)
            insert cdata;
        return cdata;
    }

    
    public static Attachment createAttachment(String bodyText, Id parentId, String names, Boolean doInsert){
        Blob b = Blob.valueOf(bodyText);
        
        Attachment attach = new Attachment();
        attach.ParentId = parentId;
        attach.Name = names;
        attach.Body = b;
        
         if(doInsert)
            insert attach;
        return attach;
    }
    
    public static Opportunity createOpportunity(Id AccountId, String Name, Boolean doInsert){
      /*  Schema.DescribeFieldResult fieldResult = Opportunity.Restriction__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        String defaultRestriction = String.valueof(ple.get(10));
        System.debug('first value in list'+ple.get(10));
*/        
        Opportunity opp = new Opportunity(rC_Giving__Affiliation__c = 'NGO', rC_Giving__Giving_Amount__c = 20,
                                          AccountId = AccountId ,Name = Name, CloseDate = Date.Today(),StageName = 'Prospecting');
        if(doInsert)
            insert opp;
        return opp;
    }
    public static Product2 createProduct(String Name,Boolean isActive,Boolean doInsert){
        Product2 p2 = new Product2(Name= Name,isActive=isActive);
        if(doInsert)
            insert p2;
        return p2;
    }
    
    public static Pricebook2 createPriceBook(String name,Boolean doInsert) {
    Pricebook2 testPriceBooks = new Pricebook2(Name = name,
                                               isActive = true);    
     
    
    if(doInsert) {
      insert testPriceBooks;
    }
    return testPriceBooks;
  }
      public static PricebookEntry createPriceBookEntry(Id productId, Boolean doInsert) {
            Id pricebookId = Test.getStandardPricebookId();
            Pricebook2 obj = new Pricebook2();
            obj.Id=pricebookId;
            obj.Name='Standard Price Book';
            update obj;
            PricebookEntry testPriceBookEntry = new PricebookEntry( Pricebook2Id = priceBookId,
                                                            UnitPrice = 12000, IsActive = true,                                                           
                                                            UseStandardPrice=false,
                                                            Product2Id = productId);
   
     
    if(doInsert) {
      insert testPriceBookEntry;
    }
    return testPriceBookEntry;
  }
  

    
    public static OpportunityLineItem createOpportunityLineItem(Id OppId,Id priceBookEntryId,Boolean doInsert){
        OpportunityLineItem oppLineItem = new OpportunityLineItem(OpportunityId=OppId,PriceBookEntryId=priceBookEntryId,Quantity=4,totalprice=200);
         if(doInsert) {
        insert oppLineItem;
    }
    return oppLineItem;
    }
    
    public static campaign createCampaign(String Name, Boolean doInsert){
        campaign camp = new campaign(Name = Name);
        if(doInsert)
            insert camp;
        return camp;
    }
    

    public static CampaignMember createCampaignMember(Id campaignId,Id leadId, Boolean doInsert){
        CampaignMember cm = new CampaignMember(CampaignId=campaignId,LeadId = leadId); 
        if(doInsert)
            insert cm;
        return cm;
    }
    public static Lead createLead(String name,String company, String status,Boolean doInsert){
        Lead ld = new Lead(LastName = name, Company=company,Status=status);
        if(doInsert)
            insert ld;
        return ld;
    }
    
    public static User createUser(string LastName,string UserName, Id RoleId, Boolean doInsert) {
        
        User objUser = new User(ProfileId = userinfo.getProfileId(),
                        LastName = LastName,
                        Email = 'puser000@aclu.org',
                        Username = UserName,
                        CompanyName = 'TEST',
                        Title = 'title',
                        Alias = 'alias',
                        TimeZoneSidKey = 'America/Los_Angeles',
                        EmailEncodingKey = 'UTF-8',
                        LanguageLocaleKey = 'en_US',
                        LocaleSidKey = 'en_US',
                        UserRoleId = RoleId);
        if(doInsert)
            insert objUser;
            
        return objUser;
    }
    
    // Creating System Admin user
    public static User createSysAdminUser(String profileName){
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
        return testUser;
        /*if(doInsert){
insert testUser;
}*/
    }
    
    
    public static Groupmember createGroupmember(Id userId, Id gpId, Boolean doInsert){
        GroupMember Grp = new GroupMember(UserOrGroupId = userId, GroupId = gpId);
        if(doInsert)
            insert Grp;
        return Grp;
    }
    
       public static AccountTeamMember createAccountTeamMember(Id userId, Id accountId, Boolean doInsert){
        AccountTeamMember atm = new AccountTeamMember(UserId = userId, AccountId = accountId);
        if(doInsert)
            insert atm;
        return atm;
    }
    
      public static OpportunityTeamMember createOpportunityTeamMember(Id userId, Id oppId, Boolean doInsert){
        OpportunityTeamMember otm = new OpportunityTeamMember(UserId = userId, OpportunityId = oppId);
        if(doInsert)
            insert otm;
        return otm;
    }
    
    public static TriggerSettings__c createTriggerSettings(String triggerName, Boolean doInsert){
        TriggerSettings__c triggerSettings = new TriggerSettings__c(Name = triggerName, isActive__c = true, isTestMode__c = false);
        
        if(doInsert)        
            insert triggerSettings;
        return triggerSettings;
    }
    
    public static rC_Giving__Opportunity_Credit__c createOpportunityCredits(Id oppId, String givingType, Integer distribution, String sharingcode, Boolean doInsert){
        rC_Giving__Opportunity_Credit__c oppCredit = new rC_Giving__Opportunity_Credit__c (rC_Giving__Opportunity__c = oppId, rC_Giving__Type__c = givingType, rC_Giving__Distribution__c = distribution, Sharing_Code__c = sharingcode);
       
        if(doInsert)
            insert oppCredit;
        return oppCredit;
    }
    
    public static Income_Type_Distribution__c createIncomeTypeDistribution(Id affId, String IncomeType, Decimal amount, Boolean doInsert){
        Income_Type_Distribution__c incomeTDistri = new Income_Type_Distribution__c (Affiliate_Yearly__c = affId, Income_Type__c = IncomeType, Amount__c = amount);
       
        if(doInsert)
            insert incomeTDistri;
        return incomeTDistri;
    }
    
    public static Email_Preference__c createEmailPreference(Id emailId, String emailCode, Boolean opt, Boolean doInsert) {
        
        Email_Preference__c ep = new Email_Preference__c(Email__c = emailId, Email_List_Code__c = emailCode, opt_In__c = opt);
        
        if(doInsert) {
            insert ep;
        }
        return ep;
    }
    
    public static Email_Preference_List__c createEmailPrefList(String name, String afl, Boolean exl, Boolean homeAfl, String lc, String lstLbl, Boolean doInsert) {
        Email_Preference_List__c epList = new Email_Preference_List__c(Name = name, Affiliation__c = afl, Exclude_from_Preference_Center__c = exl,
                                                                        Is_Home_Affiliate_List__c = homeAfl, List_Code__c = lc,
                                                                        List_Label__c = lstLbl);
        
        if(doInsert) {
            insert epList;
        }
        return epList;
    }
    public static Batch_Log__c createBatchLog(String bname, Boolean doInsert){
        Batch_Log__c bl = new Batch_Log__c(Name = bname, Batch_Date__c=Date.Today());
        if(doInsert){
            insert bl;
        }
        return bl;
    }
    public static Batch_Log_Summary__c createBatchLogSummary(String blsname, Boolean doInsert){
        Batch_Log_Summary__c bls = new Batch_Log_Summary__c (Name = blsname);
        if(doInsert){
            insert bls;
        }
        return bls;
    }
    
    /*
    Method Name:        createListNationalBudget
    Input Parameter:    Integer count
    Output Parameter:   List<createListNationalBudget>
    Description:        This method takes one argument as a integer and return the list of NationBudget.
    */
    public static List<National_Budget__c> createListNationalBudget(Integer count){
        List<National_Budget__c> lstNationalBudget = new List<National_Budget__c>();
        for(integer i=0;i<count;i++){
            lstNationalBudget.add(new National_Budget__c(Name='test'+i, Budget_Category__c='Unbudgeted - null - Union Recognized Foundation/Grant',Budget_Grouping__c='test'));
        }
        return lstNationalBudget;
    }
    public static List<Group> createGroupList(Integer count){
        List<Group> lstGroup = new List<Group>();
        for(integer i=0;i<count;i++){
            lstGroup.add(new Group(name='National'));
        }
        return lstGroup;
    }
    public static List<Prospect_Research__c> createProspectResearchList(integer count){
        List<Prospect_Research__c> lstProspectRes = new List<Prospect_Research__c>();
        for(integer i=0;i<count;i++){
            lstProspectRes.add(new Prospect_Research__c());
        }
        return lstProspectRes;
    } 
    
   public static Opportunity createOpportunityWithRecType(Id recTypeId, Id accId, String oppName, String ackCode, String ackStatus,
                                                                String stg, Id cId, Double amt, Date cDate, Boolean isInsert) {
       Opportunity op = new Opportunity(RecordTypeId = recTypeId, AccountId = accId, Name = oppName, Acknowledgment_Code__c = ackCode, CloseDate = cDate,
                                            Acknowledgment_Status__c = ackStatus, StageName = stg, CampaignId = cId, rC_Giving__Giving_Amount__c = amt );
       if(isInsert) {
           insert op;
       }
       return op;
   }
   
   public static CampaignShare createCampaignShare(Id cId, Id uId, String level, Boolean isInsert) {
       CampaignShare cs = new CampaignShare(CampaignId = cId, UserOrGroupId = uId, CampaignAccessLevel = level);
       if(isInsert) {
           insert cs;
       }
       return cs;
   }
   
   public static Batch_Upload_Source_File__c createBatchUploadSourceFileSetting(String settingName, String batchType, Boolean isInsert) {
       Batch_Upload_Source_File__c cs = new Batch_Upload_Source_File__c(Name = settingName, Batch_Name_Type__c = batchType);
       if(isInsert) {
           insert cs;
       }
       return cs;
   }
   
   //Create Async request record
   public static AsyncRequest__c createAsyncRequest(String objectApiName, String asyncType, string parms, Boolean isInsert){
       AsyncRequest__c asyncRequest = new AsyncRequest__c(Error__c = false, Object_API_Name__c = objectApiName, AsyncType__c = asyncType,
                                                           Params__c = parms);
       if(isInsert){
           insert asyncRequest;
       }
       return asyncRequest;
   }
   
   //create Portfolio record
   public static Portfolio__c createPortfolio(String pName, Boolean isInsert) {
       Portfolio__c p = new Portfolio__c(Name = pName);
       if(isInsert) {
           insert p;
       }
       return p;
   }
   
   // Create Last_Run_Time_Of_Batch__c record
   public static Last_Run_Time_Of_Batch__c createLastRunSetting(String lName, Date dt, Boolean isInsert) {
       Last_Run_Time_Of_Batch__c lstRT = new Last_Run_Time_Of_Batch__c(Name = lName, Last_Run_Time__c = dt);
       if(isInsert){
           insert lstRT;
       }
       return lstRT;
   }
   
   //Create Event Record
   public static event createEvent(String strSubject, Id whatRec, Id whoRec, Date actDate, DateTime actDateTime, Boolean isInsert){
       event eventRecord = new event(subject = strSubject, whoId = whoRec, whatId = whatRec, ActivityDate = actDate,
                                     ActivityDateTime = actDateTime);
       
       if(isInsert){
           insert eventRecord;
       }
       return eventRecord;
   }
   
   
   //create Opportunity_Start_End_Date_To_Process__c record
   public static Opportunity_Start_End_Date_To_Process__c createOpptyStartEndProcess(String recName, Date startDate, 
   																Date endDate, Boolean isInsert) {
   		Opportunity_Start_End_Date_To_Process__c opp = new Opportunity_Start_End_Date_To_Process__c(Name = recName, Start_Date__c = startDate, 
   																										End_Date__c = endDate);
   		if(isInsert) {
   			insert opp;
   		}
   		return opp;
   }
   
   //create Campaign_Roll_Up__c record
   public static Campaign_Roll_Up__c createCampaignRollUp(String nm, String fiscalYear, Boolean isInsert) {
   		Campaign_Roll_Up__c camp = new Campaign_Roll_Up__c(Name = nm, Fiscal_Year__c = fiscalYear);
   		if(isInsert) {
   			insert camp;
   		}
   		return camp;
   }
   
   //create Monthly_Cash_Receipts_Controls__c record
   public static Monthly_Cash_Receipts_Controls__c createCashReceiptsControls(String name, String ownerEmail, String senderEmail,
                                                                              String batchSummaryId, String creditCardBatchId,
                                                                              String salesforceUrl, Boolean isInsert  ){
        Monthly_Cash_Receipts_Controls__c mcrs = new Monthly_Cash_Receipts_Controls__c(name = name, Report_Request_Owner_Email__c = ownerEmail,
                                                                                       Batch_Summary_Report_Id__c = batchSummaryId,
                                                                                       Salesforce_Base_URL__c = salesforceUrl,
                                                                                       Report_Request_Sender_Email__c = senderEmail,
                                                                                       Credit_Card_Batches_Report_Id__c = creditCardBatchId); 
        
        if(isInsert) {
            insert mcrs;
        }
        return mcrs;
   }
   
   //Create Task Record
   public static Task createTask(String subj, String status, Boolean isInsert) {
   		Task t = new Task(Subject = subj, Status = status);
   		if(isInsert) {
   			insert t;
   		}
   		return t;
   }
   
   //Create Queueable_Control__c record
    public static Queueable_Control__c createQueueableControl(String lName, Integer BatchSizeEmail, Integer BatchSizeAccount, Boolean isInsert) {
        Queueable_Control__c QCntrl = new Queueable_Control__c(Name = lName, Batch_Size_Email__c = BatchSizeEmail,Batch_Size_Account__c = BatchSizeAccount, Batch_Size_Account_Address__c= 0123);
          if(isInsert){
              insert QCntrl;
          }
          return QCntrl;
    }
    
    // Create sb_action__c record
    public static sb_action__c createAction(String lName, Decimal SpringboardID, boolean isInsert) {
        sb_action__c  action = new sb_action__c(Name = lName, Springboard_ID__c=SpringboardID);
        if(isInsert){
            insert action;
        }
        return action;
    }
    
    //create Sharing_Codes_For_Membership_Campaign__c record
    public static Sharing_Codes_For_Membership_Campaign__c createSharingCodes(String sName, String codeVal, Boolean isInsert) {
        Sharing_Codes_For_Membership_Campaign__c sh = new Sharing_Codes_For_Membership_Campaign__c(Name = sName, 
                                                            Code_Value__c = codeVal);
        if(isInsert) {
            insert sh;
        }
        return sh;
    } 
        
    //create Account_Team__c record
    public static Account_Team__c createAccountTeam( Id accId, Id conId, Id userId, String teamrole, Boolean isInsert ){
        Account_Team__c at = new Account_Team__c();
        at.Account__c = accId;
        at.Contact__c = conid;
        at.Team_Member__c = userid;
        at.Team_Role__c = teamrole;
        if(isInsert) {
            insert at;
        }
        return at;
    }
    
    //create Case record
    public static Case createCase( Id accId, Boolean isInsert ){
        Case cs = new Case();
        cs.AccountId = accId;
        cs.Origin = 'Email';
        cs.Status = 'New';
        if(isInsert) {
            insert cs;
        }
        return cs;
    }
}