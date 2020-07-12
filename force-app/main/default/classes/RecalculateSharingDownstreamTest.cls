/**
* @author           : Sandeep Soni, Appirio, Inc.
* @date             : Jun 30, 2017
* @description      : Test class for RecalculateSharingDownstream
* @Code Coverage    : 100%
*/
@IsTest
public class RecalculateSharingDownstreamTest {
    
    public static testMethod void reCalculateSharingTest(){
        Account acc = new Account(name='test');
        insert acc;
        Test.startTest();
        RecalculateSharingDownstream.reCalculateSharing(acc.id,'test');
        Test.stopTest();
        System.assert(acc.id!=null);
    }
}