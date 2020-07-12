/*
*
*Name  :  AccountFieldPopulate_Batch
*Author:  Appirio India (Bhavesh)
*Date  :  April 10, 2018
*Purpose : Batch class to update Account fields from related Account Team.
*          Batch ran to initialize values, Original I-318842
*
*/
global class AccountFieldPopulate_Batch implements Database.Batchable<sObject>, Database.Stateful{
    global Integer quantity = 0;
    global Integer batchSize = 0;
    global Map<Id,Account> accoundDataMap = new Map<Id, Account>();
    global Set<Id> accIdSet = new Set<Id>();
    
    
    global List<Account_Team__c> start(Database.BatchableContext Bc){
        List<Account_Team__c> accTeamList = new List<Account_Team__c>([SELECT Id, Team_Role__c, Team_Member_Name__c, Account__c FROM Account_Team__c
                                            where Status__c = 'Current'  
                                            AND (Team_Role__c = 'Primary Relationship Manager'   
                                                OR Team_Role__c = 'Major Gifts Affiliate'   
                                                OR Team_Role__c = 'Major Gifts National' 
                                                OR Team_Role__c = 'Leadership Gifts Affiliate'   
                                                OR Team_Role__c = 'Leadership Gifts National') order by Account__c]);  
        quantity = accTeamList.size();
                                            
        return accTeamList;
    }
    
    global void execute(Database.BatchableContext Bc, List<Account_Team__c> accTeamList){
        updateAccountFormulaFields(accTeamList);
    }
    
    
    global void finish(Database.BatchableContext Bc){ 
        
    }
    
    global void updateAccountFormulaFields( List<Account_Team__c> accTeamList ){
        
        Map<Id,Account> accMap = new Map<Id, Account>();
        Account acc;
        for( Account_Team__c at :  accTeamList){
            
            if( accMap.containsKey(at.Account__c) ){
                acc = accMap.get(at.Account__c);
            } else {
                if(accoundDataMap.containsKey(at.Account__c) ){
                   acc = accoundDataMap.get(at.Account__c); 
                } else {
                    acc = new Account( id = at.Account__c, Account_PRM__c = null, Affiliate_LG__c = null, National_LG__c = null, Affiliate_MG__c = null, National_MG__c = null );
                }
                
            }
            
            if( at.Team_Role__c == 'Primary Relationship Manager' ){
                if( acc.Account_PRM__c == NULL ){
                    acc.Account_PRM__c = at.Team_Member_Name__c;
                } else {
                    acc.Account_PRM__c += '; '+at.Team_Member_Name__c;
                }
            } else if( at.Team_Role__c == 'Major Gifts Affiliate' ){
                if( acc.Affiliate_MG__c == NULL ){
                    acc.Affiliate_MG__c = at.Team_Member_Name__c;
                } else {
                    acc.Affiliate_MG__c += '; '+at.Team_Member_Name__c;
                }
            } else if( at.Team_Role__c == 'Major Gifts National' ){
                if( acc.National_MG__c == NULL ){
                    acc.National_MG__c = at.Team_Member_Name__c;
                } else {
                    acc.National_MG__c += '; '+at.Team_Member_Name__c;
                }
            }
            else if( at.Team_Role__c == 'Leadership Gifts Affiliate' ){
                if( acc.Affiliate_LG__c == NULL ){
                    acc.Affiliate_LG__c = at.Team_Member_Name__c;
                } else {
                    acc.Affiliate_LG__c += '; '+at.Team_Member_Name__c;
                }
            }else if( at.Team_Role__c == 'Leadership Gifts National' ){
                if( acc.National_LG__c == NULL ){
                    acc.National_LG__c = at.Team_Member_Name__c;
                } else {
                    acc.National_LG__c += '; '+at.Team_Member_Name__c;
                }
            }
            accMap.put( acc.id,acc );
            accoundDataMap.put(acc.id,acc);
            accIdSet.add(acc.id);
        }
        
        if( accMap.values().size() > 0 ){
            List<Database.SaveResult> batchLogResults = Database.update(accMap.values(), false);
            processResults(batchLogResults, accMap.values(),  'Account formula field update failed: ' );
        }
        
    }
    
    public void processResults(List<Database.SaveResult> results, List<sObject> lstObj, String s ){
        integer i = 0;
        
        set<String> messages; 
        apexLogHandler.apexLog log; 
        for (Database.SaveResult result : results) {
            messages = new set<String>();
            if (!result.isSuccess()){
                for (Database.Error err : result.getErrors()){
                    if(!messages.contains(err.getMessage())) {
                        log = new apexLogHandler.apexLog('AccountFieldPopulate_Batch','execute',
                                                         s+ lstObj[i].id + '\n' + err.getMessage());
                        messages.add(err.getMessage());
                    }
                }
            }
            i++;
        }
        if(log != null) {
            log.saveLogs();
        }
    }

}