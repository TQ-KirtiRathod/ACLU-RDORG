@isTest
private class Batch_SummaryReportGenerationsTest {
    
    public  static List<Opportunity> listOpportunity;
    public static List<Batch_Log__c> listBatchLog;
    
    private static final String OPPORTUNITY_RT_TRANSACTION_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Transaction').getRecordTypeId();
    private static final String OPPORTUNITY_RT_PLEDGE_PAYMENT_Id = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Pledge Payment').getRecordTypeId();
    @isTest
    private static void TestBatchSummaryReport(){
        Profile objProfile = [Select Id, Name from Profile where Name =: 'System Administrator' limit 1];

		User objeUser = [Select Id, ProfileId from User where Id=: UserInfo.getUserId()];
        System.runAs(objeUser){
            createData();
            //Non Bequest
            for(Integer i=0;i<10;i++){
                listOpportunity.get(i).Sharing_Code__c='A001';
            }
            insert listOpportunity;
	        Date d1=Date.today();
	        Date d2=Date.today().adddays(2);
	        Test.startTest();
	            Database.executebatch(new Batch_SummaryReportGenerations(d1,d2,'batch_Credit_Card_summary'));
	        Test.stopTest();
            system.debug([select COUNT() from Batch_Log_Summary__c]);
	        system.assertNotEquals(0,[select COUNT() from Batch_Log_Summary__c]);
            //system.assertEquals('test',[select name from Batch_Log_Summary__c][0].name);
        }  
    }
    
    @isTest
    private static void TestBatchSummaryReport1(){
        Profile objProfile = [Select Id, Name from Profile where Name =: 'System Administrator' limit 1];

		User objeUser = [Select Id, ProfileId from User where Id=: UserInfo.getUserId()];
        System.runAs(objeUser){
            createData();
            //Bequest record
            for(Integer i=0;i<10;i++){
                listOpportunity.get(i).Sharing_Code__c='Q001';
            }
            insert listOpportunity;  
	        Date d1=Date.today();
	        Date d2=Date.today().adddays(2);
	        Test.startTest();
	           Database.executebatch(new Batch_SummaryReportGenerations(d1,d2,'batch_Credit_Card_summary'));
	        Test.stopTest();
	        system.assertNotEquals(0,[select COUNT() from Batch_Log_Summary__c]);
        }
    }
    
    
    
    //create Test records
    public static void createData(){
        Account ac = Testutils.createAccount('Test',True);
        
        listOpportunity= new List<Opportunity>();
        listBatchLog = new List<Batch_Log__c>();
        //create Campaign
        campaign cm=TestUtils.createCampaign('test',False); 
        cm.rC_Giving__Channel__c='Canvassing';
        cm.rC_Giving__Sub_Affiliation__c='5 - Affiliate Foundation';
        insert cm; 
        
        //Create BatchLogRecords
        for(Integer i=0;i<10;i++){
            Batch_Log__c bLog = new Batch_Log__c();
            bLog.Batch_Log_Status__c='Balanced';
            bLog.Batch_Log_Type__c='Vendor';
            blog.Affiliation__c='NA';
            bLog.Deposit_Site__c='NAB_NatU_Lockbox_chk/cash	';
            bLog.Default_Payment__c = 'Cash/Check';
            bLog.Bank_Date__c=Date.today(); 
            bLog.Payment_Subtype__c='Check';
            bLog.RecordTypeId=Schema.SObjectType.Batch_Log__c.getRecordTypeInfosByName().get('Manual').getRecordTypeId(); 
            bLog.Expected_Amount__c=25;
            bLog.Actual_Amount__c=25;            
            bLog.Expected_Count__c=50;			        
            bLog.Actual_Count__c=50;               
            bLog.Name='NATest';            
            bLog.Batch_Date__c=Date.today();
            listBatchLog.add(bLog);
        }
        insert listBatchLog;
        Opportunity pOp=TestUtils.createOpportunity(ac.id,'Testparent',False);
        pOp.Program_Type__c='te';
        insert pOp;
        for(Integer i=0;i<10;i++){
            Opportunity op = TestUtils.createOpportunity(ac.id,'Test'+i,False);
            op.RecordTypeId=OPPORTUNITY_RT_TRANSACTION_Id;
            op.rC_Giving__Payment_Method__c='Cash/Check';
            op.Name='test'+i;
            op.AccountId=ac.id; 
            op.Amount=1000+i;
            op.High_Amount__c=1000;
            op.Low_Amount__c=999;
            op.Tax_Value__c=1000;
            op.Tax_Date__c=Date.today();
            op.rC_Giving__Source_Code__c='test';
            op.rC_Giving__Parent__c=pOp.Id;
            op.rC_Giving__Ticker_Symbol__c='stock';
            op.Type='Existing Business'; 
            op.Batch_Date__c=Date.today();
            op.rC_Giving__Source_Code__c='test';
            op.Bank_Date__c=Date.today();
            op.Deposit_Site__c='AK_Alaska';
            op.Program_Type__c='te';
            op.CampaignId=cm.Id; 
            op.Batch_Log__c=listBatchLog.get(0).id; 
            op.Batch_Date__c=Date.today();
            op.StageName='Completed';
            op.Payment_Subtype__c='Cash';
            op.Adjustment_Code__c='N';
            listOpportunity.add(op);            
        } 
        
        TestUtils.createCashReceiptsControls('testset', 'test@gmail.com', 'test1@gmail.com', 'test', 'test', 'https://c.cs13.visual.force.com', true );
        
    }
    
}