@isTest
Private class BUP_Initiator_ScheduleTEST {

    @isTest
    static void testSchedule()
    {
        Test.startTest();
        String sch = '0 0 * * * ?';
        String jobID = system.schedule('Test', sch,  new BUP_Initiator_Schedule());
        CronTrigger ct = [SELECT ID, CronExpression
         				    FROM CronTrigger 
                            WHERE id = :jobID];
        //verify class is scheduled for correct time.
        system.assertEquals(sch, ct.CronExpression);
        Test.stopTest();
    }
}