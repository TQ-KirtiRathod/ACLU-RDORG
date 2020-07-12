/*
*
*Name  :  PaymentMethodTriggerHandler
*Author:  Appirio India (Sai Krishna)
*Date  :  November 17, 2016
*Purpose :  Handler Class for PaymentMethod Trigger
            Logic includes
            - Truncates Address Length for CC processing
            - Apex Sharing
            - Limits Create access based on custom logic
            (T-555635)
*
*/
public with sharing class PaymentMethodTriggerHandler {

    Public static final String ALLACLU = Label.All_ACLU;
    public static final String NATIONAL = Label.National;
    public static double accountAsyncBatchMax;
    public static Map<String, Boolean> userAccessMap;
    
    static {
        Queueable_Control__c q = Queueable_Control__c.getInstance('MainQueueable');
        if (q != null) {
            accountAsyncBatchMax = q.Batch_Size_Account__c;
        } else {
            accountAsyncBatchMax = 100;
        }
        userAccessMap = new Map<String, Boolean>();
    }
    
    /*
    *
    *Method mainEntry
    *@description : defining all trigger events
    *
    */
    public static void mainEntry(List<rC_Giving__Payment_Method__c > newList, List<rC_Giving__Payment_Method__c> oldList, Map<Id, rC_Giving__Payment_Method__c> newMap, Map<Id, rC_Giving__Payment_Method__c> oldMap, Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, Boolean isBefore, Boolean isAfter) {

        //if Trigger is Active
        if(TriggerState.isActive('PaymentMethod_Trigger') && !(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) && !(UserInfo.getName() == Label.roundData_Sync && UserInfo.getProfileId() == Label.ACLU_rD_Sync_User_Profile)) {

            // It is called on before Insert/Delete Event
            if(isBefore){
                if(isInsert){
                    onBeforeInsert(newList);
                }
                if(isUpdate) {
                    onBeforeUpdate(newList, oldMap);
                }
                if(isDelete){
                    onBeforeDelete(oldList);
                }
            }

            // It is called on After Insert/Update Event
            if(isAfter){
                if(isInsert){
                    onAfterInsert(newList);
                }

                if(isUpdate){
                    onAfterUpdate(newMap, oldMap);
                }
            }
        }

    }

    /*
    *
    *Method onBeforeInsert
    *@param : newList
    *
    */
    public static void onBeforeInsert(List<rC_Giving__Payment_Method__c> newList) {
        Set<Id> accountIds = new Set<Id>();
        list<rC_Giving__Payment_Method__c> paymentMethodsToTruncate = new list<rC_Giving__Payment_Method__c>();
        for(rC_Giving__Payment_Method__c obj: newList){
            if(obj.rC_Giving__Payment_Type__c == 'Charge Card' || obj.rC_Giving__Payment_Type__c == 'EFT') {
                obj.rC_Giving__Is_Default__c = false;
            }
            if(obj.rC_Giving__Account__c != null){
                accountIds.add(obj.rC_Giving__Account__c);
            }
            paymentMethodsToTruncate.add(obj);
            //system.debug('BeforeInsert : ' + obj.rC_Connect__Merchant_Name__c);
        }

        if(accountIds.size() > 0) {
            hasPermission(accountIds, newList);
        }
        if(paymentMethodsToTruncate.size() > 0) {
            truncateFields(paymentMethodsToTruncate, null);
        }
    }
    
    /*
    *
    *Method onBeforeUpdate
    *@param : newMap
    *@param : OldMap
    *
    */
    public static void onBeforeUpdate(list<rC_Giving__Payment_Method__c> newList, Map<Id,rC_Giving__Payment_Method__c> OldMap){
        list<rC_Giving__Payment_Method__c> paymentMethodsToTruncate = new list<rC_Giving__Payment_Method__c>();
        for(rC_Giving__Payment_Method__c obj: newList){
            if(obj.rC_Giving__Billing_Street__c != oldMap.get(obj.Id).rC_Giving__Billing_Street__c
             || obj.rC_Giving__Billing_City__c != oldMap.get(obj.Id).rC_Giving__Billing_City__c
             || obj.rC_Giving__Billing_State__c != oldMap.get(obj.Id).rC_Giving__Billing_State__c
             || obj.rC_Giving__Billing_Postal_Code__c != oldMap.get(obj.Id).rC_Giving__Billing_Postal_Code__c
             || obj.rC_Giving__Billing_Country__c != oldMap.get(obj.Id).rC_Giving__Billing_Country__c
             || obj.rC_Giving__Billing_Contact_Name__c != oldMap.get(obj.Id).rC_Giving__Billing_Contact_Name__c
             || obj.rC_Giving__Card_Holder_Name__c != oldMap.get(obj.Id).rC_Giving__Card_Holder_Name__c) {
               
               paymentMethodsToTruncate.add(obj);  
            }
        }
        if(paymentMethodsToTruncate.size() > 0) {
            truncateFields(paymentMethodsToTruncate, oldMap);
        }
    }
    
    /*
    *
    *Method onBeforeDelete
    *@param : oldList
    *
    */
    public static void onBeforeDelete(List<rC_Giving__Payment_Method__c> oldList) {
        Set<Id> accountIds = new Set<Id>();
        for(rC_Giving__Payment_Method__c obj: oldList){
            if(obj.rC_Giving__Account__c != null){
                accountIds.add(obj.rC_Giving__Account__c);
            }
        }

        if(accountIds.size() > 0) {
            hasPermission(accountIds, oldList);
        }
    }

    /*
    *
    *Method onAfterInsert
    *@param : newList
    *
    */
    public static void onAfterInsert(List<rC_Giving__Payment_Method__c> newList) {
        Set<Id> paymentMethodIds = new Set<Id>();
        Map<Id, Set<Id>> paymntMethodAccountMap = new Map<Id, Set<Id>>();
        
        for(rC_Giving__Payment_Method__c pm: newList){
            paymentMethodIds.add(pm.Id);
            if(!paymntMethodAccountMap.containsKey(pm.rC_Giving__Account__c)) {
                paymntMethodAccountMap.put(pm.rC_Giving__Account__c, new Set<Id>());
            }
            paymntMethodAccountMap.get(pm.rC_Giving__Account__c).add(pm.Id);
        }
        if(!paymentMethodIds.isEmpty() && Utilities.CanUseFutureContext())
            setPaymentMethodShareRecords(paymentMethodIds);
            
        if(!paymntMethodAccountMap.isEmpty()) {
            PaymentMethodTriggerHandler.sharePaymtMethodWithAccountTeam(paymntMethodAccountMap);
        } 
    }
    
    /*
    *
    *Method onAfterUpdate
    *@param : newMap
    *@param : OldMap
    *It checks whether the Account/Contact Lookup changed.
    *
    */
    public static void onAfterUpdate(Map<Id,rC_Giving__Payment_Method__c> newMap, Map<Id,rC_Giving__Payment_Method__c> OldMap){
        Set<Id> accountIds = new Set<Id>();
        Set<Id> paymentMethodIds = new Set<Id>();
        List<String> OldAffiliations = new List<String>();

        for(rC_Giving__Payment_Method__c pm: newMap.Values()){
            if(OldMap.get(pm.Id).rC_Giving__Account__c != pm.rC_Giving__Account__c){
                accountIds.add(OldMap.get(pm.Id).rC_Giving__Account__c);
                paymentMethodIds.add(pm.Id);
            }
            //system.debug('AfterUpdate : ' + pm.rC_Connect__Merchant_Name__c);
        }

        for(Account acc: [SELECT id,Affiliation__c FROM Account WHERE Id =: accountIds]){
            if(acc.Affiliation__c != null)
                OldAffiliations.add(acc.Affiliation__c);
        }
        if(!OldAffiliations.IsEmpty() && Utilities.CanUseFutureContext()){
            resetPaymentMethodShareRecords(paymentMethodIds,OldAffiliations);
        }
    }

    /*
    *
    *Method hasPermission
    *@param : newList
    *It checks the createPermissions.
    *
    */
    public static void hasPermission(Set<Id> accountIds, List<rC_Giving__Payment_Method__c> newList){
        Map<ID, Account> accountMap = new Map<ID, Account>();
        Map<ID, String> mapAccountIdToAffiliation = new Map<ID, String>();
        map<String, Boolean> mapRecordToPermissions= new map<String, Boolean>();

        for(Account acc: [SELECT id,Affiliation__C FROM Account WHERE Id =: accountIds]){
            mapAccountIdToAffiliation.put(acc.Id,acc.Affiliation__c);
        }
        if(!accountIds.isEmpty()) {
            for(Account_Team__c objTeam : [ SELECT Id, Grant_Edit_Access__c, Team_Member__c, Account__c 
                                            FROM Account_Team__c 
                                            WHERE Account__c IN: accountIds]) {
                userAccessMap.put(objTeam.Account__c+'-'+objTeam.Team_Member__c, objTeam.Grant_Edit_Access__c);
            }
        }
        mapRecordToPermissions = RecordAccessUtility.hasCreatePermission(mapAccountIdToAffiliation.Values());

        for(rC_Giving__Payment_Method__c obj: newList){
            if(userAccessMap.containsKey(obj.rC_Giving__Account__c+'-'+UserInfo.getUserId()) && !userAccessMap.get(obj.rC_Giving__Account__c+'-'+UserInfo.getUserId())) {
                if(obj.rC_Giving__Account__c != null){
                    system.debug('All_Affiliate_Edit_Access__c<<<<<'+obj.All_Affiliate_Edit_Access__c);
                    if(obj.All_Affiliate_Edit_Access__c == false && mapRecordToPermissions.get(mapAccountIdToAffiliation.get(obj.rC_Giving__Account__c)) != null && !mapRecordToPermissions.get(mapAccountIdToAffiliation.get(obj.rC_Giving__Account__c))){
                        obj.addError('Sorry, you do not have access to create records related to this Account. The Account belongs to a different Affiliate');
                    }
                }
            }
            
        }
    }


    /*    
    *
    *Method sharePaymtMethodWithAccountTeam
    *@param : Map<Id, Set<ID>>
    *It share records for account teams
    */
    private static void sharePaymtMethodWithAccountTeam(Map<Id, Set<Id>> paymntMethodAccountMap) {
        List<AsyncRequest__c> newAsyncRequests = new List<AsyncRequest__c>();
        while (paymntMethodAccountMap.size() > 0) {
            Map<Id, Set<Id>> newPMAccountMap = new Map<Id, Set<Id>>();

            for (Id key : paymntMethodAccountMap.KeySet()) {
                if (newPMAccountMap.size() < accountAsyncBatchMax) {
                    newPMAccountMap.put(key, paymntMethodAccountMap.get(key));
                    paymntMethodAccountMap.remove(key);
                } else {
                    break;
                }
            }
            
            newAsyncRequests.add(new AsyncRequest__c(AsyncType__c ='share_WithAccountTeam', 
                                   Object_API_Name__c = 'rC_Giving__Payment_Method__c',
                                   Params__c = JSON.serialize(newPMAccountMap)));
        }
        
        try {
            insert newAsyncRequests;        
        } catch(Exception e) {
            apexLogHandler.apexLog log = new apexLogHandler.apexLog('PaymentMethodTriggerHandler','sharePaymtMethodWithAccountTeam', e.getMessage());
            log.logException(e);
            log.saveLogs();
        }
    }
    
    /*
    *
    *Method setPaymentMethodShareRecords
    *@param : newMap
    *It creates the share records based on the their accountAffiliation.
    *
    */
    //@future
    public static void setPaymentMethodShareRecords(Set<Id> PaymentMethodsIds){
        // Method Variables
        Map<Id,String> mapPaymentMethodIdToAffiliate = new Map<Id,String>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        map<Id,Boolean> mapPaymentMethodIdToRestricted = new map<Id,Boolean> ();

         // Collect the PaymentMethodIdToAffiliation
        for(rC_Giving__Payment_Method__c mapPm: [SELECT Id, rC_Giving__Account__r.Restricted_Account__c, rC_Giving__Account__c, rC_Giving__Account__r.Affiliation__c FROM rC_Giving__Payment_Method__c WHERE Id =: PaymentMethodsIds]){
            if(mapPm.rC_Giving__Account__c != null && mapPm.rC_Giving__Account__r.Affiliation__c != null){
                mapPaymentMethodIdToAffiliate.put(mapPm.Id,mapPm.rC_Giving__Account__r.Affiliation__c);
                mapPaymentMethodIdToRestricted.put(mapPm.Id,mapPm.rC_Giving__Account__r.Restricted_Account__c);
            }
        }
        //Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapPaymentMethodIdToAffiliate.Values() OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }

        // Insert the new Affiliations records.
        RecordAccessUtility.InsertPaymentMethodSharingRecords (mapPaymentMethodIdToAffiliate, mapGroupNameToId, mapPaymentMethodIdToRestricted);
    }

    /*
    *
    *Method resetPaymentMethodShareRecords
    *@param : Set<Id> (paymentMethodIds)
    *@param : List<String> OldAffiliations
    *It resets the share records based on the their account Affiliation.
    *
    */
    //@future
    public static void resetPaymentMethodShareRecords(Set<Id> paymentMethodIds, List<String> OldAffiliations){
        // Method Variables
        Map<Id,String> mapPaymentMethodIdToAffiliate = new Map<Id,String>();
        Map<String,Id> mapGroupNameToId = new Map<String,Id>();
        map<Id,Boolean> mapPaymentMethodIdToRestricted = new map<Id,Boolean> ();

         // Collect the PaymentMethodIdToAffiliation
        for(rC_Giving__Payment_Method__c mapPm: [SELECT Id, rC_Giving__Account__r.Restricted_Account__c, rC_Giving__Account__c, rC_Giving__Account__r.Affiliation__c FROM rC_Giving__Payment_Method__c WHERE Id =: paymentMethodIds]){
            if(mapPm.rC_Giving__Account__c != null && mapPm.rC_Giving__Account__r.Affiliation__c != null){
                mapPaymentMethodIdToAffiliate.put(mapPm.Id,mapPm.rC_Giving__Account__r.Affiliation__c);
                mapPaymentMethodIdToRestricted.put(mapPm.Id,mapPm.rC_Giving__Account__r.Restricted_Account__c);
            }
        }

        //Collect all the Groups in a map
        for(Group grp: [SELECT Id, Name FROM Group WHERE Name =: mapPaymentMethodIdToAffiliate.Values() OR Name=: OldAffiliations OR Name =: ALLACLU OR Name =: NATIONAL]){
            mapGroupNameToId.put(grp.Name,grp.Id);
        }

        //Delete the Old affiliations records.
        RecordAccessUtility.deletePaymentMethodSharingRecords (mapPaymentMethodIdToAffiliate.KeySet(), OldAffiliations, mapGroupNameToId, mapPaymentMethodIdToRestricted);
        // Insert the new Affiliations records.
        RecordAccessUtility.InsertPaymentMethodSharingRecords (mapPaymentMethodIdToAffiliate, mapGroupNameToId, mapPaymentMethodIdToRestricted);
    }
    
    /*
    *
    *Method truncateFields
    *@param : list<rC_Giving__Payment_Method__c>
    *@param : Map<Id,rC_Giving__Payment_Method__c>
    *Truncates some fields on Payment Method record
    *T-654725
    *
    */
    public static void truncateFields(list<rC_Giving__Payment_Method__c> paymentMethodsToTruncate, Map<Id,rC_Giving__Payment_Method__c> OldMap){
        for(rC_Giving__Payment_Method__c payment : paymentMethodsToTruncate) {
            if(payment.rC_Giving__Billing_Street__c != null && payment.rC_Giving__Billing_Street__c.length() > 35)
                payment.rC_Giving__Billing_Street__c = payment.rC_Giving__Billing_Street__c.subString(0, 35);
            
            if(payment.rC_Giving__Billing_City__c != null && payment.rC_Giving__Billing_City__c.length() > 35)
                payment.rC_Giving__Billing_City__c = payment.rC_Giving__Billing_City__c.subString(0, 35);

            if(payment.rC_Giving__Billing_State__c != null && payment.rC_Giving__Billing_State__c.length() > 2)
                payment.rC_Giving__Billing_State__c = payment.rC_Giving__Billing_State__c.subString(0, 2);

            if(payment.rC_Giving__Billing_Postal_Code__c != null && payment.rC_Giving__Billing_Postal_Code__c.length() > 20)
                payment.rC_Giving__Billing_Postal_Code__c = payment.rC_Giving__Billing_Postal_Code__c.subString(0, 20);

            if(payment.rC_Giving__Billing_Country__c != null && payment.rC_Giving__Billing_Country__c != 'USA' && payment.rC_Giving__Billing_Country__c.length() > 2)
                payment.rC_Giving__Billing_Country__c = payment.rC_Giving__Billing_Country__c.subString(0, 2);

            if(payment.rC_Giving__Billing_Contact_Name__c != null) {
                if(payment.rC_Giving__Billing_Contact_Name__c.contains(' ')) {
                    String[] nameString = payment.rC_Giving__Billing_Contact_Name__c.split(' ',2);
                    String name1 = nameString[0].length() > 25 ? nameString[0].subString(0,25) : nameString[0];
                    String name2 = nameString[1].length() > 25 ? nameString[1].subString(0,25) : nameString[1];
                    payment.rC_Giving__Billing_Contact_Name__c = name1 + ' ' + name2;
                } else {
                    if(payment.rC_Giving__Billing_Contact_Name__c.length() > 25) {
                        payment.rC_Giving__Billing_Contact_Name__c = payment.rC_Giving__Billing_Contact_Name__c.subString(25);
                    }
                }
            }

            if(payment.rC_Giving__Card_Holder_Name__c != null) {
                if(payment.rC_Giving__Card_Holder_Name__c.contains(' ')) {
                    String[] nameString = payment.rC_Giving__Card_Holder_Name__c.split(' ',2);
                    String name1 = nameString[0].length() > 25 ? nameString[0].subString(0,25) : nameString[0];
                    String name2 = nameString[1].length() > 25 ? nameString[1].subString(0,25) : nameString[1];
                    payment.rC_Giving__Card_Holder_Name__c = name1 + ' ' + name2;
                } else {
                    if(payment.rC_Giving__Card_Holder_Name__c.length() > 25) {
                        payment.rC_Giving__Card_Holder_Name__c = payment.rC_Giving__Card_Holder_Name__c.subString(25);
                    }
                }
            }

        }
    }
}