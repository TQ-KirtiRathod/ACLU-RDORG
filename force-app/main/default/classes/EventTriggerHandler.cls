/*
*
*Name  :  EventTriggerHandler
*Author:  Appirio India (Sai Krishna)
*Date  :  April 20, 2017
*Purpose : Handler class for EventTrigger. Logic updates/inserts portfolioId
*
*/
public class EventTriggerHandler {
    //private static Id proposalID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
    public static void mainEntry(List<Event> newList, List<Event> oldList, Map<Id,Event> newMap, Map<Id,Event> oldMap,
                               Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, Boolean isBefore, Boolean isAfter) {
    if(TriggerState.isActive('EventTrigger') && !(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) && !(UserInfo.getName() == Label.roundData_Sync && UserInfo.getProfileId() == Label.ACLU_rD_Sync_User_Profile)) { 
        if(isBefore) {
            if(isInsert) {
                beforeInsert(newList);
            }
            else if(isUpdate) {
                beforeUpdate(newList,oldMap);
            }
        }
    }                               
  }
  
  private static void beforeInsert(List<Event> newList) {
      List<Event> updatePortfolioId = new List<Event> ();
      set<Id> opportunityIds = new set<Id>();
        for(Event objEve : newList) {
             // Populates the PortfolioId if the Task is related to Opportunity Object
          if(!String.isBlank(objEve.whatId) && String.valueOf((objEve.whatId).getSObjectType()) == 'Opportunity'){
              updatePortfolioId.add(objEve);
              opportunityIds.add(objEve.whatId);
          }    
        }
        
        // Populates the Portfolio Id if the Task is related to Opportunity 
        if(!opportunityIds.isEmpty()){
            populateportfolioId(updatePortfolioId, opportunityIds);
        }
  }
  
  private static void beforeUpdate(List<Event> newList, Map<Id,Event> oldMap) {
        set<Id> opportunityIds = new set<Id>();
        List<Event> updatePortfolioId = new List<Event> ();
        for(Event objEvent : newList) {
            // Populates the Portfolio Id if the Task is related to Opportunity Object 
            if(!String.isBlank(objEvent.whatId) && oldMap.get(objEvent.Id).whatId != objEvent.whatId && String.valueOf((objEvent.whatId).getSObjectType()) == 'Opportunity'){
              updatePortfolioId.add(objEvent);
              opportunityIds.add(objEvent.whatId);
            }
        }
        // Populates the account Id if the Task is related to Confidential Data
        if(!opportunityIds.isEmpty()){
            populateportfolioId(updatePortfolioId, opportunityIds);
        }
        
      
  }
  
  // Populates the portfolio Id if the Task is related to Opportunity Object
  private static void populateportfolioId(List<Event> eventsToUpdate, set<Id> opportunityIds){
      Map<Id, Opportunity> oppMapRecords = new Map<Id, Opportunity>([SELECT Id,Portfolio__c FROM Opportunity WHERE Id=:opportunityIds AND Portfolio__c != null]);
      for(Event eve: eventsToUpdate){
          if(oppMapRecords.get(eve.whatId) != null){
            eve.Portfolio_Id__c = String.ValueOf(oppMapRecords.get(eve.whatId).Portfolio__c).substring(0,15);
          }
      }
  }
}