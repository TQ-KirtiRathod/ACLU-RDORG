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
* Test class for RecordAccessQueueableClass
*/
@isTest
private class RecordAccessQueueableClassTest {
    
    private static testMethod void RecordAccessQueueableClassTest() {
        
        map<id, string> maptest = new map<Id, string>();
        Account objAccount = TestUtils.createAccount('test Account', true);
        maptest.put(objAccount.Id, 'NN');
        
        AsyncRequest__c ar = new AsyncRequest__c(Params__c = JSON.serialize(maptest));
        insert ar;
        RecordAccessQueueableClass aap = new RecordAccessQueueableClass(ar);
        
        aap.createChildSharing();       
        system.assertEquals(false, [SELECT Id, Error__c FROM AsyncRequest__c].Error__c);
        
        
    }
}