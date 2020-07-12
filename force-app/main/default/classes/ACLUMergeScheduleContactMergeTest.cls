/*
* Developer     : Dave Seidman
* Created Date  : August 29, 2019
* Description   : Test class for the ACLUMergeScheduleContactMerge class
*/

@isTest
public with sharing class ACLUMergeScheduleContactMergeTest {

    static testMethod void testCreationAndDeletionOfJobs() {
        List<Account> accts = TestUtils.createAccounts(2, TRUE);
        Set<Id> allRecordIds = new Set<Id>{accts[0].Id, accts[1].Id};

        Test.startTest();
        ACLUMergeScheduleContactMerge sch1 = new ACLUMergeScheduleContactMerge(allRecordIds);
        Datetime nowTime = Datetime.now().addSeconds(-5);
        Datetime futureTime = Datetime.now().addSeconds(5);
        String hour = String.valueOf(futureTime.hour());
        String min = String.valueOf(futureTime.minute()); 
        String ss =  String.valueOf(futureTime.second());
        String fireTime = ss + ' ' + min + ' ' + hour + ' * * ?';
        ACLUMergeScheduleContactMerge contactMerge = new ACLUMergeScheduleContactMerge(allRecordIds);
        Id mergeContactsJobId = System.schedule('DC Merge Contacts | ' + accts[0].Id + '|' + accts[1].Id, fireTime, contactMerge);    
        
        Integer cronCount = [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.JobType = '7' and CronJobDetail.Name like 'DC Merge%'
                                AND CreatedDate >= :nowTime ];
        system.assertEquals(1, cronCount);
        Test.stopTest();

        ACLUMergeScheduleContactMerge.deleteJobs();

        cronCount = [SELECT COUNT() FROM CronTrigger WHERE CronJobDetail.JobType = '7' and CronJobDetail.Name like 'DC Merge%'
                                AND CreatedDate >= :nowTime ];
        system.assertEquals(0, cronCount);
    }

}