/**
 * This class contains unit tests for validating the behavior of Apex classes
 * and triggers.
 *
 * Unit tests are class methods that verify whether a particular piece
 * of code is working properly. Unit test methods take no arguments,
 * commit no data to the database, and are flagged with the testMethod
 * keyword in the method definition.
 *
 * All test methods in an organization are executed whenever Apex code is deployed
 * to a production organization to confirm correctness, ensure code
 * coverage, and prevent regressions. All Apex classes are
 * required to have at least 75% code coverage in order to be deployed
 * to a production organization. In addition, all triggers must have some code coverage.
 * 
 * The @isTest class annotation indicates this class only contains test
 * methods. Classes defined with the @isTest annotation do not count against
 * the organization size limit for all Apex scripts.
 *
 * See the Apex Language Reference for more information about Testing and Code Coverage.
 */
 
   /*
*
*Name  :  PaymentMethodTriggerHandlerTest
*Author:  Appirio India (Sai Krishna )
*Date  :  NOvember 23, 2016
*Purpose : Reset the shareing for the lookups changes
*
*/
@isTest
private class PaymentMethodTriggerHandlerTest {
    
	public static List<rC_Giving__Payment_Method__c> paymentMethodsList;
	/*
    *
    *Method PaymentMethodAccountLookupSharingTest 
    *Testing if preference record created then share is created based on related affiliate.
    */
    static testMethod void paymentMethodAccountLookupSharingTest() {
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        Map<Id,String> mapPaymentMethodIdToAffilate = new map<Id,String>();
        List<rC_Giving__Payment_Method__share> PaymentMethodSharesToBeInsert = new List<rC_Giving__Payment_Method__share>();
        List<Account> AccountsToBeUpdate = new List<Account>(); 
        List<rC_Giving__Payment_Method__c> paymentMethodsUpdate = new List<rC_Giving__Payment_Method__c> (); 
        setup();
        
        Test.startTest();
        
        if(!paymentMethodsList.isEmpty())
            insert paymentMethodsList;
            
         for(Group gp: [SELECT id, name FROM group ]){
            mapGroupNameToId.put(gp.name,gp.Id);
        }
            
        // Preference Records
        for(rC_Giving__Payment_Method__c paymentMethod : paymentMethodsList){   
            mapPaymentMethodIdToAffilate.put(paymentMethod.Id,paymentMethod.rC_Giving__Account__r.Affiliation__c); 
        } 
        
        Test.stopTest();
        
        //Verifying the Apex Share record got created.
        for(rC_Giving__Payment_Method__share GpShare: [SELECT Id, AccessLevel, UserOrGroupId 
                                                       FROM rC_Giving__Payment_Method__share 
                                                       WHERE ParentId = :paymentMethodsUpdate 
                                                       AND AccessLevel = 'Edit' 
                                                       AND UserOrGroupId =:mapGroupNameToId.get('NN')]){
            system.assertEquals(GpShare.UserOrGroupId,mapGroupNameToId.get('ZF'));
        }  
    }
    
    
    //Test when the Payment method is updated
    private static testMethod void updatePaymentMethod(){
        Map<String,Id> mapGroupNameToId = new map<String,Id>();
        List<rC_Giving__Payment_Method__c> paymentMethodsUpdate = new List<rC_Giving__Payment_Method__c> (); 
        
        setup();
        Test.startTest();
	        if(!paymentMethodsList.isEmpty()){
	            insert paymentMethodsList;
	        }
	            
	        // changing the Payment account lookup .
	        Account acc = TestUtils.createAccount('Account'+1,false);
	        acc.Affiliation__c = 'ZF';
	        insert acc;
	        
	        for(rC_Giving__Payment_Method__c objpayM : paymentMethodsList){
	            paymentMethodsUpdate.add(new rC_Giving__Payment_Method__c(id = objpayM.id, rC_Giving__Account__c = acc.id));
	            
	        }
	        
	        if(!paymentMethodsUpdate.isEmpty()){
	            update paymentMethodsUpdate;
	        }
	        
	        //Verifying the Apex Share record got created.
            for(rC_Giving__Payment_Method__share GpShare: [SELECT Id, AccessLevel, UserOrGroupId 
                                                           FROM rC_Giving__Payment_Method__share 
                                                           WHERE ParentId =:paymentMethodsUpdate 
                                                           AND AccessLevel = 'Edit' 
                                                           AND UserOrGroupId =:mapGroupNameToId.get('ZF')]){
                system.assertEquals(GpShare.UserOrGroupId,mapGroupNameToId.get('NN'));
            }  
    }
    
    
    
    //Test to truncates some fields on Payment Method record
    private static testMethod void testTruncateFieldsTest(){
        setup();
        Test.startTest();
        
	    if(!paymentMethodsList.isEmpty()){ 
	        insert paymentMethodsList;
	    }
	    
	    List<rC_Giving__Payment_Method__c> paymentMethodsAssertList = new List<rC_Giving__Payment_Method__c>();
	    
	    // Test Case 1: Insert | Check truncates Fields
	    paymentMethodsAssertList = [SELECT id,
	                                       rC_Giving__Billing_Street__c,
	                                       rC_Giving__Billing_City__c,
	                                       rC_Giving__Billing_State__c,
	                                       rC_Giving__Billing_Postal_Code__c,
	                                       rC_Giving__Billing_Country__c
	                               FROM rC_Giving__Payment_Method__c
	                               WHERE id IN :paymentMethodsList
	                                    AND rC_Giving__Billing_Street__c != null
	                                    AND rC_Giving__Billing_City__c != null
	                                    AND rC_Giving__Billing_State__c != null
	                                    AND rC_Giving__Billing_Postal_Code__c != null
	                                    AND rC_Giving__Billing_Country__c != null];
	                               
	    System.assertEquals(100, paymentMethodsAssertList.size());
	                               
	    for(rC_Giving__Payment_Method__c paymentFirst : paymentMethodsAssertList){
	        // asserts to check values.
	        System.assertEquals(true, (String.ValueOf(paymentFirst.rC_Giving__Billing_Street__c).length() <= 35));
	        System.assertEquals(true, (String.ValueOf(paymentFirst.rC_Giving__Billing_City__c).length() <= 35));
	        System.assertEquals(true, (String.ValueOf(paymentFirst.rC_Giving__Billing_State__c).length() == 2));
	        System.assertEquals(true, (String.ValueOf(paymentFirst.rC_Giving__Billing_Postal_Code__c).length() <= 20));
	        System.assertEquals(true, (String.ValueOf(paymentFirst.rC_Giving__Billing_Country__c).length() == 2));
	    }
	    
	    // Test Case 2: Update | Check truncates Fields
	    
	     List<rC_Giving__Payment_Method__c> paymentMethodsAssertList_Update = new List<rC_Giving__Payment_Method__c>();
	     Boolean flag = True;
	     if(paymentMethodsAssertList.size() > 0){
	         
            for(rC_Giving__Payment_Method__c paymentMethod_Update : paymentMethodsAssertList) {
                
              if(flag){ 
                paymentMethodsAssertList_Update.add(new rC_Giving__Payment_Method__c(Id = paymentMethod_Update.id, 
                                                                                     rC_Giving__Card_Holder_Name__c = 'CardHolderContactTester ContactContactTester',
                                                                                     rC_Giving__Billing_Contact_Name__c = 'BillingContact ContactContactTester',
                                                                                     rC_Giving__Payment_Type__c = 'Charge Card (No Charge)'));
                   flag = False;                                                                  
                }
               else{
                paymentMethodsAssertList_Update.add(new rC_Giving__Payment_Method__c(Id = paymentMethod_Update.id, 
                                                                                     rC_Giving__Card_Holder_Name__c = 'CardHolderContactContactTester',
                                                                                     rC_Giving__Billing_Contact_Name__c = 'BillingContactContactContactTester',
                                                                                     rC_Giving__Payment_Type__c = 'Charge Card (No Charge)'));
                }                                                                     
                
            }
            if(paymentMethodsAssertList_Update.size() > 0){
                update paymentMethodsAssertList_Update;
            }
         }
            
        for(rC_Giving__Payment_Method__c paymentMethod_UpdateAssert : [SELECT id,rC_Giving__Card_Holder_Name__c,rC_Giving__Billing_Contact_Name__c FROM rC_Giving__Payment_Method__c 
                                                                      WHERE id IN :paymentMethodsAssertList_Update 
                                                                      AND rC_Giving__Card_Holder_Name__c != null
                                                                      AND rC_Giving__Billing_Contact_Name__c != null]){
                                                                          
            if(paymentMethod_UpdateAssert.rC_Giving__Card_Holder_Name__c.contains(' ')) {
                    String[] nameString = paymentMethod_UpdateAssert.rC_Giving__Card_Holder_Name__c.split(' ',2);
                    System.assertEquals(true, (nameString[0].length() <= 25));
                    System.assertEquals(true, (nameString[1].length() <= 25));
                    
            }
            else{
                System.assertEquals(true, (String.ValueOf(paymentMethod_UpdateAssert.rC_Giving__Card_Holder_Name__c).length() <= 25));
            }
            
            if(paymentMethod_UpdateAssert.rC_Giving__Billing_Contact_Name__c.contains(' ')) {
                    String[] nameString = paymentMethod_UpdateAssert.rC_Giving__Billing_Contact_Name__c.split(' ',2);
                    System.assertEquals(true, (nameString[0].length() <= 25));
                    System.assertEquals(true, (nameString[1].length() <= 25));
                    
            }
            else{
                System.assertEquals(true, (String.ValueOf(paymentMethod_UpdateAssert.rC_Giving__Billing_Contact_Name__c).length() <= 25));
            }
        }
	    
    }
    /*
    *
    *Method setup
    *Testing if Affiliation updated then accountShare is re-calculated.
    */
    public static void setup(){
        
        paymentMethodsList = new List<rC_Giving__Payment_Method__c>();
        
        // Creating common Account for rC_Giving__Payment_Method__c object
        Account account_test = TestUtils.createAccount('Account',false);
        account_test.Affiliation__c = 'NN';
        account_test.BillingPostalCode = '00000';
        account_test.BillingCountry = 'Japan';
        insert account_test;
        
        // Inserting bulk Records of rC_Giving__Payment_Method__c
        for(Integer i=0;i<100;i++){   
            rC_Giving__Payment_Method__c paymentMethodTest = TestUtils.CreatePaymentMethod(account_test.Id,false);
            paymentMethodTest.RecordTypeId = Schema.SObjectType.rC_Giving__Payment_Method__c.getRecordTypeInfosByName().get('Paypal').getRecordTypeId();
            paymentMethodTest.rC_Giving__Billing_Street__c = 'TestingStreet ofPAYMENTMETHODTESTINGTILL35';
            paymentMethodTest.rC_Giving__Billing_City__c = 'TestingCity ofPAYMENTMETHODTESTINGTILL35 ';
            paymentMethodTest.rC_Giving__Billing_State__c = 'TestingState ofPAYMENTMETHODTESTINGTILL35';
            paymentMethodTest.rC_Giving__Billing_Postal_Code__c = '223321234567898765432';
            paymentMethodTest.rC_Giving__Billing_Country__c = 'India';
            paymentMethodTest.rC_Giving__Payment_Type__c = 'Paypal';
            paymentMethodTest.rC_Connect__Payment_Processor__c = 'Heartland';
            paymentMethodsList.add(paymentMethodTest);
        }   
    }
}