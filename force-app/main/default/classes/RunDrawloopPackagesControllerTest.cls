/**
 * Test Class for RunDrawloopPackagesController
 */
@isTest(seeAllData=true)
public class RunDrawloopPackagesControllerTest {
    public static List<SelectOption> selectedDDPsOptions;
    public static Map<id, Loop__DDP__c> ddTestMap;
    public static Set<id> oppIdSet;
    public static Account a;
    static User u;
     
    @isTest
    public static void testRunDrawLoop(){
        createAdminUser();
        System.runAs(u) {
            createData();
        }
        RunDrawloopPackagesController r = new RunDrawloopPackagesController();
        setPageParams(false, 'Account Default Formal Salutation', 'Account Default Formal Salutation', 'secondInside', 'secondOutside', 'thirdInside', 'thirdOutside',
                            selectedDDPsOptions, 'mergeNumber', r);
        r.sendRequests();
        RunDrawloopPackagesController.updateMergeNumberOnOpps(r.mergeNumber, oppIdSet, true, 'tAK');
        r.runDDP();
        r.sendRequests();
    }
    
    @isTest
    public static void testRunDrawLoop2(){
        createAdminUser();
        System.runAs(u) {
            createData();
        }
        RunDrawloopPackagesController r = new RunDrawloopPackagesController();
        setPageParams(false, 'Account Default Informal Salutation', 'Account Default Informal Salutation', 'secondInside', 'secondOutside', 'thirdInside', 'thirdOutside',
                            selectedDDPsOptions, 'mergeNumber', r);
        r.sendRequests();
        RunDrawloopPackagesController.updateMergeNumberOnOpps(r.mergeNumber, oppIdSet, true, 'tAK');
        r.runDDP();
        r.sendRequests();
    }
    
    @isTest
    public static void testRunDrawLoop3(){
        createAdminUser();
        System.runAs(u) {
            createData();
        }
        RunDrawloopPackagesController r = new RunDrawloopPackagesController();
        setPageParams(false, 'firstInside', 'firstOutside', 'Account Default Formal Salutation', 'Account Default Formal Salutation', 'thirdInside', 'thirdOutside',
                            selectedDDPsOptions, 'mergeNumber', r);
        r.sendRequests();
        RunDrawloopPackagesController.updateMergeNumberOnOpps(r.mergeNumber, oppIdSet, true, 'tAK');
        r.runDDP();
        r.sendRequests();
    }
    
    @isTest
    public static void  testRunDrawLoop4(){
        createAdminUser();
        System.runAs(u) {
            createData();
        }
        RunDrawloopPackagesController r = new RunDrawloopPackagesController();
        setPageParams(false, 'firstInside', 'firstOutside', 'Account Default Informal Salutation', 'Account Default Informal Salutation', 'thirdInside', 'thirdOutside',
                            selectedDDPsOptions, 'mergeNumber', r);
        r.sendRequests();
        RunDrawloopPackagesController.updateMergeNumberOnOpps(r.mergeNumber, oppIdSet, true, 'tAK');
        r.runDDP();
        r.sendRequests();
    }
    
     @isTest
    public static void testRunDrawLoop5(){
        createAdminUser();
        System.runAs(u) {
            createData();
        }
        RunDrawloopPackagesController r = new RunDrawloopPackagesController();
        setPageParams(false, 'firstInside', 'firstOutside', 'secondInside', 'secondOutside', 'Account Default Formal Salutation', 'Account Default Formal Salutation',
                            selectedDDPsOptions, 'mergeNumber', r);
        r.sendRequests();
        RunDrawloopPackagesController.updateMergeNumberOnOpps(r.mergeNumber, oppIdSet, true, 'tAK');
        r.runDDP();
        r.sendRequests();
    }
    
     @isTest
    public static void testRunDrawLoop6(){
        createAdminUser();
        System.runAs(u) {
            createData();
        }
        RunDrawloopPackagesController r = new RunDrawloopPackagesController();
        setPageParams(false, 'firstInside', 'firstOutside', 'secondInside', 'secondOutside', 'Account Default Informal Salutation', 'Account Default Informal Salutation',
                            selectedDDPsOptions, 'mergeNumber', r);
        r.sendRequests();
        RunDrawloopPackagesController.updateMergeNumberOnOpps(r.mergeNumber, oppIdSet, true, 'tAK');
        r.runDDP();
        r.sendRequests();
    }
    
     @isTest
    public static void testRunDrawLoop7(){
        createAdminUser();
        System.runAs(u) {
            createData();
        }
        RunDrawloopPackagesController r = new RunDrawloopPackagesController();
        setPageParams(false, 'firstInside', 'firstOutside', 'secondInside', 'secondOutside', 'thirdInside', 'thirdOutside',
                            selectedDDPsOptions, 'mergeNumber', r);
        r.sendRequests();
        RunDrawloopPackagesController.updateMergeNumberOnOpps(r.mergeNumber, oppIdSet, true, 'tAK');
        r.runDDP();
        r.sendRequests();
    }
    static void createAdminUser() {
        u = [SELECT Id, Primary_Affiliate__c, Is_Affiliate_User__c FROM User WHERE Id = :userInfo.getUserId()];
        u.Primary_Affiliate__c = 'AK - ACLU of Alaska';
        u.Is_Affiliate_User__c = false;
        update u;
    }
    static void setPageParams(Boolean err, String fI, String fO, String sI, String sO, String tI, String tO, 
                                List<SelectOption> ddpsOptions, String mergeNum, RunDrawloopPackagesController r) {
        r.errors = err;
        //r.bypassSalutation = byPass;
        r.firstInside = fI;
        r.firstOutside = fO;
        r.secondInside = sI;
        r.secondOutside = sO;
        r.thirdInside = tI;
        r.thirdOutside = tO;
        r.selectedDDPs = ddpsOptions;
        r.mergeNumber = mergeNum;
    }
    public static Id getReportId(){
        //Using existing report by setting seeAllData=true
        List <Report> reportList = [SELECT Id,DeveloperName FROM Report WHERE DeveloperName= 'IMO_IHO_Donor_Ack_Report'];
        system.debug('reportList1'  +reportList);
        system.assertEquals(1, reportList.size());
        return reportList.get(0).Id;
    }	
    
    
    public static void createData(){
         ddTestMap = new map<id, Loop__DDP__c>();
         //creating account
     	 Account acc1 = testUtils.createAccount('Test Account1', false);
     	 Account acc2 = testUtils.createAccount('Test Account2', false);
     	 Account acc3 = testUtils.createAccount('Test Account3', false);
     	 list<Account> accList = new list<Account>{acc1, acc2, acc3};
     	 insert accList;
     	 
         Loop__DDP__c rd = new Loop__DDP__c();
         rd.name = 'Test DDP';
         rd.RecordTypeId = Schema.SObjectType.Loop__DDP__c.getRecordTypeInfosByName().get('Opportunity').getRecordTypeId();
	     rd.Primary_Affiliate__c = 'AK - ACLU of Alaska';
         insert rd;
            
         Loop__DDP_Integration_Option__c lc = new Loop__DDP_Integration_Option__c();
         lc.name = 'Document Queue';
         lc.RecordTypeId = Schema.SObjectType.Loop__DDP_Integration_Option__c.getRecordTypeInfosByName().get('Document Queue').getRecordTypeId();
	     lc.Loop__DDP__c = rd.id; 
         insert lc;
        
         Loop__DDP_File__c ldf = new Loop__DDP_File__c();
         ldf.name = 'Test File';
         ldf.Loop__DDP__c = rd.id; 
	     ldf.loop__reportids__c = getReportId();//'00OW0000000PSSaMAO'; // [SELECT  id,name FROM report  WHERE name =: 'Giving with Giving Teams' LIMIT 1].id;
         insert ldf;
                      
		 
         selectedDDPsOptions = new List<SelectOption>();
         selectedDDPsOptions.add(new SelectOption(rd.id,rd.id));

         ddTestMap.put(rd.id, rd);
         map<Id, Opportunity> oppMap = new Map<Id, Opportunity>();
         oppIdSet = new Set<Id>(); 
         Campaign cmp = TestUtils.createCampaign('Test Campaign', true);
         Id donationId = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Donation').getRecordTypeId();
         //Data has to be created according to the report used - IMO_IHO_Donor_Ack_Report
         Opportunity op1 = TestUtils.createOpportunityWithRecType(donationId, acc1.Id, 'Test Opp1', 
	                        'NY Honor', 'N - Not Acknowledged','Open', cmp.Id, 100, system.today(), false);
	     Opportunity op2 = TestUtils.createOpportunityWithRecType(donationId, acc2.Id, 'Test Opp2', 
	                        'NY Honor', 'N - Not Acknowledged','Open', cmp.Id, 100, system.today(), false);
	     Opportunity op3 = TestUtils.createOpportunityWithRecType(donationId, acc3.Id, 'Test Opp3', 
	                        'NY Honor', 'N - Not Acknowledged','Open', cmp.Id, 100, system.today(), false);
	     Opportunity op4 = TestUtils.createOpportunityWithRecType(donationId, acc3.Id, 'Test Opp4', 
	                        'NY Honor', 'N - Not Acknowledged','Completed', cmp.Id, 100, system.today(), false);
	     op4.rC_Giving__Payment_Method__c = 'Cash/Check';             
	     list<Opportunity> oppList = new list<Opportunity>{op1, op2, op3, op4};
	     insert oppList;

	     for(Opportunity opp : oppList) {
            oppIdSet.add(opp.Id);
	     } 
	   
	    //Create Salutation records
	    rC_Bios__Salutation__c sal1 = TestUtils.createSalutation(acc1.Id, false);
	    sal1.rC_Bios__Salutation_Type__c = 'firstInside';
	    rC_Bios__Salutation__c sal2 = TestUtils.createSalutation(acc2.Id, false);
	    sal2.rC_Bios__Salutation_Type__c = 'secondInside';
	    rC_Bios__Salutation__c sal3 = TestUtils.createSalutation(acc3.Id, false);
	    sal3.rC_Bios__Salutation_Type__c = 'thirdInside';
	    list<rC_Bios__Salutation__c> salList = new list<rC_Bios__Salutation__c>{sal1, sal2, sal3};
	    insert salList;
	    
   }
}