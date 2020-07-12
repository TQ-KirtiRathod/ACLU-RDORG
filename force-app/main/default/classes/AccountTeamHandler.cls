/*
*
*Name  :  AccountTeamHandler
*Author:  Appirio India (Harshita Khandelwal)
*Date  :  October 31, 2017
*Purpose : Handler Class for AccountTeamHandler Trigger Logic includes - Sets Custom Apex Sharing (T-639732)
** Modified by :: roundCorner Inc. :: 27-March-2019 :: Zendesk: #64227
*/
public class AccountTeamHandler {
	public static double accountTeamAsyncBatchMax;
    
    static {
        Queueable_Control__c q = Queueable_Control__c.getInstance('MainQueueable');
        if (q != null) {
            accountTeamAsyncBatchMax = q.Batch_Size_Account_Team__c;
        } else {
            accountTeamAsyncBatchMax = 100;
        }
    }
    
	/*
	*
	*Method mainEntry
	*@description : defining all trigger events
	*
	*/
    public static void mainEntry(List<Account_Team__c> newList, List<Account_Team__c> oldList, Map<Id, Account_Team__c> newMap, Map<Id, Account_Team__c> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, Boolean isBefore, Boolean isAfter) {
        //if trigger is active
        if(TriggerState.isActive('AccountTeam_Trigger') && !(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) && !(UserInfo.getName() == Label.roundData_Sync && UserInfo.getProfileId() == Label.ACLU_rD_Sync_User_Profile)) {           
            //is called  After insert/Update
            if(isAfter){
                if(isInsert || isUpdate){
                    afterInsertUpdate(newList, newMap, oldMap);
                }
                
                if(isDelete) {
                    afterDelete(oldMap);
                }
            }
        }
    }
    
    /*
    * Method afterInsert
    * @description : calls on afterInsert
    */
    private static void afterInsertUpdate(List<Account_Team__c> newList, Map<Id, Account_Team__c> newMap, Map<Id,Account_Team__c> oldMap) {
    	Boolean isInsert = oldMap == null? true: false;
    	Map<Id, Set<Id>> userToAccount_RWAccess = new Map<Id, Set<Id>>();
    	Set<Id> account_RWAccessSet = new Set<Id>();
    	Map<Id, Set<Id>> userToAccount_RAccess = new Map<Id, Set<Id>>();
    	Set<Id> account_RAccessSet = new Set<Id>();
    	Set<Id> accIdList = new Set<Id>();
    	Set<String> accTeamRoles = new Set<String>{'Primary Relationship Manager', 'Major Gifts Affiliate', 'Major Gifts National','Leadership Gifts Affiliate', 'Leadership Gifts National','Planned Giving National'};
    	
        for(Account_Team__c objAccountTeam : newList) {
            if( accTeamRoles.contains(objAccountTeam.Team_Role__c) && objAccountTeam.Status__c == 'Current'){
                accIdList.add(objAccountTeam.Account__c);
            }
            
            if( !isInsert && ( (objAccountTeam.Status__c != oldMap.get(objAccountTeam.id).Status__c) || (oldMap.get(objAccountTeam.id).Team_Role__c != objAccountTeam.Team_Role__c
                && (accTeamRoles.contains(objAccountTeam.Team_Role__c) || accTeamRoles.contains(oldMap.get(objAccountTeam.id).Team_Role__c) )))){
                accIdList.add(objAccountTeam.Account__c);
            }
        	if(isInsert || (!isInsert && objAccountTeam.Grant_Edit_Access__c != oldMap.get(objAccountTeam.Id).Grant_Edit_Access__c)) {
        	    
        		if(objAccountTeam.Grant_Edit_Access__c) {
        			if(!userToAccount_RWAccess.containsKey(objAccountTeam.Team_Member__c)) {
        				userToAccount_RWAccess.put(objAccountTeam.Team_Member__c, new Set<Id>());
        			}
        			userToAccount_RWAccess.get(objAccountTeam.Team_Member__c).add(objAccountTeam.Account__c);
        			account_RWAccessSet.add(objAccountTeam.Account__c);
        		} else {
        			if(!userToAccount_RAccess.containsKey(objAccountTeam.Team_Member__c)) {
        				userToAccount_RAccess.put(objAccountTeam.Team_Member__c, new Set<Id>());
        			}
        			userToAccount_RAccess.get(objAccountTeam.Team_Member__c).add(objAccountTeam.Account__c);
        			account_RAccessSet.add(objAccountTeam.Account__c);
        		}
        	}  
        	
        	if(userToAccount_RWAccess.size() == accountTeamAsyncBatchMax) {
        	    AccountTeamRecordAccessUtility.grantReadORWriteAccessToRelatedObjects(userToAccount_RWAccess, account_RWAccessSet, true);
        	    account_RWAccessSet.clear();
        	    userToAccount_RWAccess.clear();
        	}
        	
        	if(userToAccount_RAccess.size() == accountTeamAsyncBatchMax) {
        	    AccountTeamRecordAccessUtility.grantReadORWriteAccessToRelatedObjects(userToAccount_RAccess, account_RAccessSet, false);
        	    account_RAccessSet.clear();
        	    userToAccount_RAccess.clear();
        	}
        }
        
        if(!userToAccount_RWAccess.isEmpty()) {
        	AccountTeamRecordAccessUtility.grantReadORWriteAccessToRelatedObjects(userToAccount_RWAccess, account_RWAccessSet, true);
        }
        
        if(!userToAccount_RAccess.isEmpty()) {
        	AccountTeamRecordAccessUtility.grantReadORWriteAccessToRelatedObjects(userToAccount_RAccess, account_RAccessSet, false);
        }
        
        if( accIdList.size() > 0 ){
            updateAccountFormulaFields( accIdList );
        }
        
        
    }
    
    
    public static void updateAccountFormulaFields( Set<id> accIdList ){
        Map<Id,Account> accMap = new Map<Id, Account>();
        Account acc;
        for( Account_Team__c at : [Select Id, Team_Role__c, Team_Member_Name__c, Account__c
                                    FROM Account_team__c 
                                    where Account__c in: accIdList
                                        AND Team_Role__c IN (:'Primary Relationship Manager', :'Major Gifts Affiliate', :'Major Gifts National',:'Leadership Gifts Affiliate', :'Leadership Gifts National',:'Planned Giving National' )
                                        AND  Status__c = 'Current'] ){
                                            System.debug(at);
            
            if( accMap.containsKey(at.Account__c) ){
                acc = accMap.get(at.Account__c);
            } else {
                /*/ Zendesk: #62462 Added National_PG__c as Parameter*/
                acc = new Account( id = at.Account__c, Account_PRM__c = null, Affiliate_LG__c = null, National_LG__c = null,National_PG__c = null  );
            	/*Zendesk: End #62462 */
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
            }else if( at.Team_Role__c == 'Major Gifts National' ){
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
               /*/ Zendesk: #62462*/ 
            }else if(at.Team_Role__c.EqualsIgnoreCase('Planned Giving National')){
                if( acc.National_PG__c == NULL ){
                    acc.National_PG__c = at.Team_Member_Name__c;
                } else {
                    acc.National_PG__c += '; '+at.Team_Member_Name__c;
                }
            }
			/*/ END - Zendesk: #62462*/
            accMap.put( acc.id,acc );
        }
        for(Id accId : accIdList){
            if( !accMap.containsKey(accId)){
                Account ac = new Account(Id=accId);
                ac.Account_PRM__c = null;
                ac.Affiliate_LG__c = null;
                ac.National_LG__c = null;
                ac.Affiliate_MG__c = null;
                ac.National_MG__c = null;
                /*/ Zendesk: #62462*/
                ac.National_PG__c = null;
                accMap.put(accId,ac);
            }
        }
        
        if( accMap.values().size() > 0 ){
            update accMap.values();
        }
        
    }
    
    
    /*
    *Method afterDelete
    *@description : calls on afterDelete
    */
    public static void afterDelete(Map<Id, Account_Team__c> oldMap) {
        Map<Id, Set<Id>> userToAccountMap = new Map<Id, Set<Id>>();
        Set<Id> accountIds = new Set<Id>();
        Set<Id> accIdSet = new Set<Id>();
         /*/ Zendesk: #62462 - Added the value in picklist*/ 
        Set<String> teamRoleValues = new Set<String>{'Primary Relationship Manager', 'Major Gifts Affiliate', 'Major Gifts National',  'Leadership Gifts Affiliate', 'Leadership Gifts National','Planned Giving National'};
        for(Account_Team__c objAccountTeam : oldMap.values()) {
            System.debug(objAccountTeam);
            if(teamRoleValues.contains( objAccountTeam.Team_Role__c ) && objAccountTeam.Status__c == 'Current'){
                accIdSet.add( objAccountTeam.Account__c );
            }
            if(!userToAccountMap.containsKey(objAccountTeam.Team_Member__c)) {
				userToAccountMap.put(objAccountTeam.Team_Member__c, new Set<Id>());
			}
		    userToAccountMap.get(objAccountTeam.Team_Member__c).add(objAccountTeam.Account__c);
			accountIds.add(objAccountTeam.Account__c);
			System.debug(accIdSet);
			if(userToAccountMap.size() == accountTeamAsyncBatchMax) {
        	    AccountTeamRecordAccessUtility.deleteRelatedSharingRecords(userToAccountMap, accountIds);
        	    userToAccountMap.clear();
        	    accountIds.clear();
                System.debug(accIdSet);
        	}
        }
        
        if(!userToAccountMap.isEmpty()) {
            AccountTeamRecordAccessUtility.deleteRelatedSharingRecords(userToAccountMap, accountIds);
        }
        System.debug(accIdSet);
        if( accIdSet.size() > 0 ){
            updateAccountFormulaFields( accIdSet );
        }
    }
}