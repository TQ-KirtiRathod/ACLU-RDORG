/*
*
*Name  :  AccountLookupPageController
*Author:  Appirio India (Sai)
*Date  :  March 08, 2017
*Purpose : Custom controller for Account_Lookup_Page page. Used in BGE and opened when lookup icon is clicked for the account name. 
*          Popup is opened from openLookupPopup method present in BatchLogDetailPage static resource > BatchLog.js
*
*/
public with sharing class AccountLookupPageController {
    public String query {get; set;}
    public Boolean searchWindow {get;set;}
    public Boolean accountCreated {get;set;}
    public Map<Id,Account> mapAccounts{get; set;}
    public Map<Id, AccountWrapper> accountWrappersById {get;set;}
    public List<AccountWrapper> accountWrappers {
        get {
            return accountWrappersById.values();
        }
    }

    public AccountLookupPageController (){
        searchWindow = true;
        accountCreated = false;
        accountWrappersById = new Map<Id, AccountWrapper> ();
        Set<Id> recentAccounts = new Map<Id, RecentlyViewed>(
            [SELECT Id
             FROM RecentlyViewed
             WHERE Type = 'Account'
             ORDER BY LastViewedDate DESC
             LIMIT 10]).keySet();
        for (Account acc :
            [SELECT Id, Name, Account_Number__c, Affiliation__c, Chapter__c, Most_Recent_Date_All_Time__c, AccountNumber,
                BillingStreet, BillingCity, BillingState, BillingCountry, BillingpostalCode
            FROM Account
            WHERE Id IN :recentAccounts]) {
            accountWrappersById.put(acc.Id, new AccountWrapper(acc));
        }
        findOpenPledges(accountWrappersById);
    }

    public PageReference runQuery()
    {
        Set<String> queryStringWithSpaces = new Set<String>();
        Set<String> queryStringWithoutSpaces = new Set<String>();
        if(searchWindow == false){
            searchWindow = true;
        }
        accountWrappersById = new Map<Id, AccountWrapper> ();
        if(accountCreated == false && query!= null && query.length()>2){
            string dynamicquery ='FIND \''+query+'*\' RETURNING Account(Name,Id,accountNumber, Affiliation__c, Chapter__c, Most_Recent_Date_All_Time__c, Account_Number__c, BillingStreet, BillingCity, BillingState, BillingCountry, BillingpostalCode ) LIMIT 1000';
            List<List<sObject>> accountList = search.query(dynamicquery);
            for(Sobject acc: accountList[0]){
                accountWrappersById.put(acc.Id, new AccountWrapper((account) acc) );
            }
        }
        else if(accountCreated == true){
             for(account acc:[SELECT Id, Name, accountNumber, Affiliation__c, Chapter__c, Most_Recent_Date_All_Time__c, Account_Number__c, BillingStreet, BillingCity, BillingState, BillingCountry, BillingpostalCode
                        FROM Account ORDER BY CreatedDate desc LIMIT 1]){

                    accountWrappersById.put(acc.Id, new AccountWrapper(acc) );
            }
             accountCreated = false;
        }
        else{
            ApexPages.addmessage(new ApexPages.message(ApexPages.severity.WARNING,'Search term must be more than two Characters'));
        }

        findOpenPledges(accountWrappersById);
        return null;
    }

    public PageReference createNew (){
        searchWindow = false;
        accountCreated = true;
        return null;
    }

    public PageReference redirectPage() {
      PageReference pageRef = new PageReference('/setup/ui/recordtypeselect.jsp?ent=Account&retURL=/apex/Account_Lookup_Page&save_new_url=%2F001%2Fe%3FretURL%3D%252F001%252Fo');
      return pageRef;
    }
    
    public static Boolean hide_OpenProsposals() {
        Boolean isAccessToPledges = false;
        //Open Pledges Access
        // TODO: Is this query selective?
        for (User u : [SELECT Id, Denied_Access_to_Open_Givings__c, Profile.Name FROM User WHERE Id = : UserInfo.getuserId()]) {
          if (u.Denied_Access_to_Open_Givings__c == true ) {
            isAccessToPledges = true;
          }
        }
    
        return isAccessToPledges;
    }

    public void findOpenPledges(Map<Id, AccountWrapper> accWrappersById){
        String pledgeParameter = (apexpages.currentpage().getparameters().get('isPledge')!= null)?apexpages.currentpage().getparameters().get('isPledge'):'false';
        Boolean isPledge = Boolean.valueOf(pledgeParameter);
        Boolean userHasPledgeAccess = hide_OpenProsposals();
        for(Opportunity opp: [
            SELECT Id,RecordTypeId,accountId
            FROM Opportunity
            WHERE accountId IN :accWrappersById.keySet()
                AND ( RecordTypeId = : BatchLogDetailPageController.opptyRTMap.get('Grant').getRecordTypeId()
                OR RecordTypeId = : BatchLogDetailPageController.opptyRTMap.get('Proposal').getRecordTypeId()
                OR (
                  RecordTypeId = : BatchLogDetailPageController.opptyRTMap.get('Pledge Payment').getRecordTypeId()
                  AND stageName = 'Open' AND IsCreatedFromBatchLog__c = false))]){
            accWrappersById.get(opp.AccountId).isOpenPledges = false;
            
            if (userHasPledgeAccess) {
                if(!isPledge){
                    accWrappersById.get(opp.AccountId).isOpenPledges = true;
                }
                else if(opp.RecordTypeId != BatchLogDetailPageController.opptyRTMap.get('Pledge Payment').getRecordTypeId()){
                    accWrappersById.get(opp.AccountId).isOpenPledges = true;
                }
            } else if (opp.RecordTypeId == BatchLogDetailPageController.opptyRTMap.get('Pledge Payment').getRecordTypeId() && !isPledge) {
                accWrappersById.get(opp.AccountId).isOpenPledges = true;
            }
        }
    }

    public class AccountWrapper{
        public Account accRec {get;set;}
        public Boolean isOpenPledges {get;set;}

        public AccountWrapper(Account acc){
            this.accRec = acc;
            isOpenPledges = false;
        }
    }
}