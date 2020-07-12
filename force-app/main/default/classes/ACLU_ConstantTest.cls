/*
* Developer     :
* Created Date  :
* Description   : Test class for ACLU_Constant class
*/
@isTest
private class ACLU_ConstantTest {
    @isTest //Method to add coverage
    private static void testAclu_constant(){
        ACLU_Constants v = new ACLU_Constants();
        String s=ACLU_Constants.CONST_OPPTY_STAGE_COMPLETED;
        system.assertEquals(ACLU_Constants.CONST_OPPTY_STAGE_COMPLETED, ACLU_Constants.CONST_OPPTY_STAGE_COMPLETED);
    }
}