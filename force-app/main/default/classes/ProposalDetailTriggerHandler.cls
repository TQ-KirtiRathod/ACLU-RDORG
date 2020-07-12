/*
*
*Name  :  ProposalDetailTriggerHandler
*Author:  Appirio India (Aashita Sharma)
*Date  :  Jan 30, 2018
*Purpose : Handler class for PropsalDetail_Trigger
*          Proposal Detail is a child objec to Opp Record Type Proposal for donation breakdowns and rollups
*          Logic includes updating Proposal record updates
*
*/
public class ProposalDetailTriggerHandler {

    public static void mainEntry(List<Proposal_Detail__c> newList, List<Proposal_Detail__c> oldList, 
                                Map<Id,Proposal_Detail__c> newMap, Map<Id,Proposal_Detail__c> oldMap, 
                                Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete,
                                Boolean isBefore, Boolean isAfter) {

        //if trigger is active
        if(TriggerState.isActive('ProposalDetail_Trigger') && !(UserInfo.getName() == Label.Data_Migration 
        && UserInfo.getProfileId() == Label.SysAdminProfileId) && !(UserInfo.getName() == Label.roundData_Sync 
        && UserInfo.getProfileId() == Label.ACLU_rD_Sync_User_Profile)) {

            // It is called on before insert
            if(isBefore) {
                if(isInsert) {
                    BeforeInsert(newList);
                }
            }
            // It is called on before update
            if(isBefore) {
                if(isUpdate) {
                    BeforeUpdate(newList, oldMap);
                }
                if(isDelete) {
                    AfterDelete(oldMap);
                }
            }
            if(isAfter) {
                if(isInsert) {
                   AfterInsert(newList);
                }
            }
            if(isAfter) {
                if(isUpdate) {
                    AfterUpdate(newList,oldMap);
                }
            }
        }
    }

    /*
    *
    *Method BeforeUpdate
    *calls onBeforeUpdate
    *
    */
    public static void BeforeUpdate(List<Proposal_Detail__c> newList, Map<Id,Proposal_Detail__c> oldMap){
    
    }

    /*
    *
    *Method BeforeInsert
    *calls BeforeInsert
    *
    */
    public static void BeforeInsert(List<Proposal_Detail__c> newList){
        
    }

    /*
    *
    *Method AfterInsert
    *calls AfterInsert
    *
    */
    public static void AfterInsert(List<Proposal_Detail__c> newList) {
        
        // check for duplicate Emails existing for Contact
        List<Proposal_Detail__c> listOfProposalDetailsToProcess = new List<Proposal_Detail__c>();
        Set<Id> setOppotunityIds = new Set<Id>();
        Map<Id, List<Proposal_Detail__c>> mapOpporutnityToProposaldetails = new Map<Id, List<Proposal_Detail__c>>();
        for(Proposal_Detail__c pd : newList) {
          if(pd.Requested_Amount__c != null || pd.Projected_Amount__c != null) {
              if(!mapOpporutnityToProposaldetails.containsKey(pd.Opportunity__c)) {
                  mapOpporutnityToProposaldetails.put(pd.Opportunity__c, new List<Proposal_Detail__c>());
              }
              mapOpporutnityToProposaldetails.get(pd.Opportunity__c).add(pd);
          }
        }
        if(!mapOpporutnityToProposaldetails.isEmpty()) {
            setUserValidationBypassTrue();
            updateProposalOpportunity(mapOpporutnityToProposaldetails);
        }
    }
    
    /*
    *
    *Method AfterUpdate
    *calls AfterUpdate
    *
    */
    public static void AfterUpdate(List<Proposal_Detail__c> newList, Map<Id,Proposal_Detail__c> oldMap) {
    
        // check for duplicate Emails existing for Contact
        List<Proposal_Detail__c> listOfProposalDetailsToProcess = new List<Proposal_Detail__c>();
        Set<Id> setOppotunityIds = new Set<Id>();
        Map<Id, List<Proposal_Detail__c>> mapOpporutnityToProposaldetails = new Map<Id, List<Proposal_Detail__c>>();
        for(Proposal_Detail__c pd : newList) {
          if(pd.National_c3_Projected_Amount__c  != oldmap.get(pd.Id).National_c3_Projected_Amount__c  
            || pd.National_c4_Projected_Amount__c != oldmap.get(pd.Id).National_c4_Projected_Amount__c  
            || pd.Affiliate_c3_Projected_Amount__c != oldmap.get(pd.Id).Affiliate_c3_Projected_Amount__c 
            || pd.Affiliate_c4_Projected_Amount__c != oldmap.get(pd.Id).Affiliate_c4_Projected_Amount__c  
            || pd.National_c3_Requested_Amount__c != oldmap.get(pd.Id).National_c3_Requested_Amount__c 
            || pd.National_c4_Requested_Amount__c != oldmap.get(pd.Id).National_c4_Requested_Amount__c  
            || pd.Affiliate_c3_Requested_Amount__c != oldmap.get(pd.Id).Affiliate_c3_Requested_Amount__c 
            || pd.Affiliate_c4_Requested_Amount__c != oldmap.get(pd.Id).Affiliate_c4_Requested_Amount__c ) {
              if(!mapOpporutnityToProposaldetails.containsKey(pd.Opportunity__c)) {
                  mapOpporutnityToProposaldetails.put(pd.Opportunity__c, new List<Proposal_Detail__c>());
              }
              mapOpporutnityToProposaldetails.get(pd.Opportunity__c).add(pd);
          }
        }  
        
        if(!mapOpporutnityToProposaldetails.isEmpty()) {
            setUserValidationBypassTrue();
            updateProposalOpportunity(mapOpporutnityToProposaldetails);
        }
    }
    
    public static void afterDelete(Map<Id, Proposal_Detail__c> oldMap) {
        Set<Id> setOpptyId = new Set<Id>();
        Map<Id,Id> mapOfProposalDetailToOppty = new Map<Id,Id>();
        Map<Id, Set<Id>> mapOpptyToPD = new Map<Id, Set<Id>>();
        List<Opportunity> lstOpptyToUpdate = new List<Opportunity>();
        for(Proposal_Detail__c pd : oldMap.values()) {
            if(pd.Opportunity__c != null) {
                setOpptyId.add(pd.Opportunity__c);
                mapOfProposalDetailToOppty.put(pd.Opportunity__c, pd.Id);
            }
        }
        if(!setOpptyId.isEmpty()) {
            
            List<Proposal_Detail__c> listOfProposalDetails = new List<Proposal_Detail__c>([SELECT ID, Opportunity__c 
                                                                                           FROM Proposal_Detail__c
                                                                                           WHERE Opportunity__c IN: setOpptyId
                                                                                           AND Id NOT IN: oldMap.keySet()]);
            
            for(Proposal_Detail__c pd : listOfProposalDetails) {
                if(!mapOpptyToPD.containsKey(pd.Opportunity__c)) {
                    //setOpptyId.add(pd.Opportunity__c);
                    mapOpptyToPD.put(pd.Opportunity__c, new Set<ID>());
                }
                mapOpptyToPD.get(pd.Opportunity__c).add(pd.Id);
            }
            for(Opportunity opp : [SELECT Id, Proposal_Detail_Lock__c FROM Opportunity WHERE Id IN: setOpptyId]) {
                if(!mapOpptyToPD.containsKey(opp.Id)){
                    opp.Proposal_Detail_Lock__c = false;
                    lstOpptyToUpdate.add(opp);
                }
                
            }
        }
        if(!lstOpptyToUpdate.isEmpty()) {
            update lstOpptyToUpdate;
        }
        
    }
    
    public static void updateProposalOpportunity(Map<Id, List<Proposal_Detail__c>> mapOpporutnityToProposaldetails) {
        List<Opportunity> lstOpptyToUpdate = new List<Opportunity>();
        for(Opportunity opp : [SELECT Id, Proposal_Detail_Lock__c, rC_Giving__Requested_Amount__c, rC_Giving__Projected_Amount__c
                               FROM Opportunity
                               WHERE Id IN:  mapOpporutnityToProposaldetails.keySet()]) {

            if(mapOpporutnityToProposaldetails.get(opp.Id)[0].Requested_Amount__c != null) {
               opp.rC_Giving__Requested_Amount__c = mapOpporutnityToProposaldetails.get(opp.Id)[0].Requested_Amount__c;
            }
            if(mapOpporutnityToProposaldetails.get(opp.Id)[0].Projected_Amount__c != null) {
                opp.rC_Giving__Projected_Amount__c = mapOpporutnityToProposaldetails.get(opp.Id)[0].Projected_Amount__c;
            }
            opp.Proposal_Detail_Lock__c = true;
            lstOpptyToUpdate.add(opp);
            
        }
        if(!lstOpptyToUpdate.isEmpty()) {
            update lstOpptyToUpdate;
        }
    }

    public static void setUserValidationBypassTrue(){
        User currentUser = [SELECT Id, Validation_Bypass__c FROM User WHERE ID = :UserInfo.getUserId()];
        currentUser.Validation_Bypass__c = true;
        update currentUser; 
    }

}