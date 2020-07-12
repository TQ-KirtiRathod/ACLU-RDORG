@isTest
private class CreateInlineOpportunityItemsTest {
    
    @isTest //Method to test the controller
    private static void TestCreateInlineOpportunity() {
        Batch_Log__c bacObj = [SELECT Name, Batch_Type__c, Bank_Date__c, Default_Campaign__c, Deposit_Site__c
                               FROM Batch_Log__c];
        List<Opportunity> listOpportunity = [SELECT Name, Batch_Log__c, RecordTypeId
                                             FROM Opportunity];
        
        PageReference pageRef = Page.createInlineOpportunityItems;	
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('rowIndex','1');
        ApexPages.StandardController sm = new ApexPages.StandardController(bacObj);
        
        Test.startTest();
        createInlineOpportunityItemsCtrl pm = new createInlineOpportunityItemsCtrl(sm);
        pm.getRecTypeValues();
        pm.addRows();
        System.assertEquals(11,pm.opportunityWrapperLst.size());
        pm.saveRows();
        pm.deleteRow();
        pm.None();
        pm.restrictCC();
        Test.stopTest();
    }
    
    @testSetup //Method to create test data
    public static void createData(){
        Account ac = TestUtils.createAccount('Test',true);
        campaign cm = testUtils.createCampaign('Test',false);
        cm.rC_Giving__Sub_Affiliation__c='5 - Affiliate Foundation';
        insert cm;
        
        Batch_Log__c bacObj = new Batch_Log__c();
        bacObj.Batch_Type__c='Adjustment';
        bacObj.Bank_Date__c=Date.today();
        bacObj.Default_Campaign__c=cm.id;
        bacObj.Deposit_Site__c='AK_Alaska';
        insert bacObj;
        
        Batch_Type_To_Oppty_Field_Set_Mapping__c objSetting= new  Batch_Type_To_Oppty_Field_Set_Mapping__c();
        objSetting.Name='Mapping1'; 
        objSetting.Batch_Type__c='Adjustment'; 
        objSetting.Field_Set_Name__c='Oppty_Fields_For_Standard_Batch_Type';
        insert objSetting;
        
        List<Opportunity> listOpportunity = new List<Opportunity>();
        for(Integer i=0;i<10;i++){
            Opportunity op = TestUtils.createOpportunity(ac.id,'Test'+i,False);
            op.Batch_Log__c=bacObj.id;
            op.RecordTypeId=Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
            listOpportunity.add(op);
        } 
        insert listOpportunity;
    }
}