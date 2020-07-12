@isTest
private class BUP_InitiatorTEST {
    @isTest
    static void testschedule()
    {
        test.startTest();
        BUP_Initiator BI= new BUP_Initiator();
        String jobID = system.schedule('Test','0 0 * * * ?', BI);
        test.stopTest();
        system.assert(jobId != null);
    }

}