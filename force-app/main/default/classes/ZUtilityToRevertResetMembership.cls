/*
*
*Name  :  ZUtilityToRevertResetMembership
*Author:  Appirio India (Bhavesh Malviya)
*Date  :  May 5, 2018
*Purpose : Batch script utility ("zUtilityToRevertResetMembership") to correct historical data. One time run
*
*/
Global class ZUtilityToRevertResetMembership implements Database.Batchable<sObject>, Database.Stateful {
    global String queryCondtion;
    global Set<Id> accIds;
    global List<Opportunity> oppListToUpdate;
    
    global ZUtilityToRevertResetMembership ( String queryFilter ){
        this.queryCondtion = queryFilter;
        accIds = new Set<Id>();
        oppListToUpdate = new List<Opportunity>();
    }
    global Database.QueryLocator start( Database.BatchableContext bc ){
        if( String.isBlank(queryCondtion) ){
            System.assert(false, 'Please add string parameter with condition like - CloseDate = LAST_FISCAL_YEAR AND rC_Giving__External_Id__c = \'Flagged for MembershipShareCode Reset\' ' );
        }
        String query = 'SELECT Id ,AccountId , Sharing_Code__c, rC_Giving__External_ID__c,New_Membership_Set_To_Date__c,';
        query += 'Batch_Log__r.Name, Account.Original_Join_Date__c, Account.Last_Membership_Gift__c, ';
        query += 'Account.Last_Membership_Gift__r.CloseDate FROM Opportunity WHERE '+queryCondtion;
        return Database.getQueryLocator( query );
    }
    
    global void execute( Database.BatchableContext bc, List<Opportunity> oppList ){
        oppListToUpdate.clear();
        BatchLogManager blm = new BatchLogManager();
        List<Opportunity> oppListToUpdate = new List<Opportunity>();
        for( Opportunity opp : oppList ){
            if( accIds.contains(opp.AccountId) ){
                accIds.add( blm.BatchResetMembershipMethod( opp, false ));
            } else {
                accIds.add( blm.BatchResetMembershipMethod( opp, true));
            }
            opp.Stagename = 'Completed';
            oppListToUpdate.add( opp );
        }
        if( oppListToUpdate.size() > 0 ){
            update oppListToUpdate;
        }
    }
    global void finish( Database.BatchableContext bc){
        
    }
    
}