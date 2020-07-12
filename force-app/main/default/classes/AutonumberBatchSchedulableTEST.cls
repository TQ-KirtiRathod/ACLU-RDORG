/*
*
*Name  :  AutonumberBatchSchedulableTEST
*Author:  Appirio India 
*Date  :  October 10,2017
*Purpose : To Test AutonumberBatchSchedulable Class functionality
*
*/
@isTest
private class AutonumberBatchSchedulableTEST {
    
    //Test method to test scheduling behaviour
    @isTest static void testContactSchedulable() {
        new AutonumberBatchContactSchedulable().execute(null);
        
        //Verify the scheduled AutonumberBatch classes are scheduled
        System.assertEquals(1, [SELECT count() FROM AsyncApexJob 
                                WHERE AsyncApexJob.ApexClass.Name = 'AutonumberBatch']);
    }   

    //Test method to test scheduling behaviour
    @isTest static void testOppSchedulable() {
        new AutonumberBatchOppSchedulable().execute(null);
        
        //Verify the scheduled AutonumberBatch classes are scheduled
        System.assertEquals(1, [SELECT count() FROM AsyncApexJob 
                                WHERE AsyncApexJob.ApexClass.Name = 'AutonumberBatch']);
    } 


}