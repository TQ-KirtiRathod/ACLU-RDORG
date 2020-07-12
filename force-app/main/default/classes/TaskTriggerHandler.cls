/*
*
*Name  :  TaskTriggerHandler
*Author:  Appirio India (Shikha Gupta)
*Date  :  Dec 26, 2016
*Purpose : Handler class for Task Trigger. Logic includes but not limited to
*          - Updates to What ID, Action Name, Portfolio ID, Account ID, Opportunity ID
*
*/
public with sharing class TaskTriggerHandler {
    private static Id proposalID = Schema.SObjectType.Opportunity.getRecordTypeInfosByName().get('Proposal').getRecordTypeId();
    public static void mainEntry(List<Task> newList, List<Task> oldList, Map<Id,Task> newMap, Map<Id,Task> oldMap,
                               Boolean isInsert, Boolean isUpdate, Boolean isDelete, Boolean isUndelete, Boolean isBefore, Boolean isAfter) {
    if(TriggerState.isActive('TaskTrigger') && !(UserInfo.getName() == Label.Data_Migration && UserInfo.getProfileId() == Label.SysAdminProfileId) && !(UserInfo.getName() == Label.roundData_Sync && UserInfo.getProfileId() == Label.ACLU_rD_Sync_User_Profile)) { 
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
  
  private static void beforeInsert(List<Task> newList) {
      Map<String, Task>  actPlanTskIdToTaskMap = new Map<String, Task>();
      List<Task> updateAccountId = new List<Task> ();
      List<Task> updatePortfolioId = new List<Task> ();
      set<Id> confIds = new set<Id>();
      set<Id> opportunityIds = new set<Id>();
      
      for(Task objTask : newList) {
          if(objTask.rC_Bios__Action_Plan_Task_ID__c != null) {
              actPlanTskIdToTaskMap.put(objTask.rC_Bios__Action_Plan_Task_ID__c, objTask);
          }
          // Populates the account Id if the Task is related to Confidential Data
          if(!String.isBlank(objTask.whatId) && String.valueOf((objTask.whatId).getSObjectType()) == 'Confidential_Data__c'){
              updateAccountId.add(objTask);
              confIds.add(objTask.whatId);
          }
          
          // Populates the PortfolioId if the Task is related to Opportunity Object
          if(!String.isBlank(objTask.whatId) && String.valueOf((objTask.whatId).getSObjectType()) == 'Opportunity'){
              updatePortfolioId.add(objTask);
              opportunityIds.add(objTask.whatId);
          }
          
          //Populate Completed Date
          //Amended per GH-17
          if(objTask.Status == 'Completed') {
          	if (objTask.Completed_date__c == NULL) {
              objTask.Completed_date__c = system.Today();
          	}
            if (objTask.Completed_By__c == NULL) {
          		objTask.Completed_By__c = objTask.OwnerId;
            } 
          }
      }
      if(actPlanTskIdToTaskMap != null) {
          populateActionNameOnTask(actPlanTskIdToTaskMap);
      }
      // Populates the account Id if the Task is related to Confidential Data
      if(!confIds.isEmpty()){
          populateAccountId(updateAccountId, confIds);
      }
      
      // Populates the Portfolio Id if the Task is related to Opportunity 
      if(!opportunityIds.isEmpty()){
          populateportfolioId(updatePortfolioId, opportunityIds);
      }
      
    updateOpportuntyStageOnTask(newList,null);
  }
  
  
  // Populates the portfolio Id if the Task is related to Opportunity Object 18 char value
  private static void populateportfolioId(List<Task> tasksToUpdate, set<Id> opportunityIds){
      Map<Id, Opportunity> oppMapRecords = new Map<Id, Opportunity>([SELECT Id,Portfolio__c FROM Opportunity WHERE Id=:opportunityIds AND Portfolio__c != null]);
      for(Task tsk: tasksToUpdate){
          if(oppMapRecords.get(tsk.whatId) != null && oppMapRecords.get(tsk.whatId).Portfolio__c != null){
            //tsk.Portfolio_Id__c = String.ValueOf(oppMapRecords.get(tsk.whatId).Portfolio__c).substring(0,15);
            tsk.Portfolio_Id__c = String.ValueOf(oppMapRecords.get(tsk.whatId).Portfolio__c);
          }
      }
  }
  
  // Populates the account Id if the Task is related to Confidential Data
  private static void populateAccountId(List<Task> tasksToUpdate, set<Id> confIds){
      Map<Id, Confidential_Data__c> confMapRecords = new Map<Id, Confidential_Data__c>([SELECT Id, Account__c, Opportunity__c FROM Confidential_Data__c WHERE Id=:confIds AND Opportunity__c != null]);
      for(Task tsk: tasksToUpdate){
          if(confMapRecords.get(tsk.whatId) != null){
            tsk.Account_Id__c = String.ValueOf(confMapRecords.get(tsk.whatId).Account__c).substring(0,15);
            tsk.Opportunity_Id__c = String.ValueOf(confMapRecords.get(tsk.whatId).Opportunity__c).substring(0,15);
          }
      }
  }
    
    private static void beforeUpdate(List<Task> newList, Map<Id,Task> oldMap) {
      Map<String, Task>  actPlanTskIdToTaskMap = new Map<String, Task>();
      List<Task> updateAccountId = new List<Task> ();
      List<Task> updatePortfolioId = new List<Task> ();
      set<Id> confIds = new set<Id>();
      set<Id> opportunityIds = new set<Id>();
      for(Task objTask : newList) {
          if(objTask.rC_Bios__Action_Plan_Task_ID__c != null && oldMap.get(objTask.Id).rC_Bios__Action_Plan_Task_ID__c != objTask.rC_Bios__Action_Plan_Task_ID__c) {
              actPlanTskIdToTaskMap.put(objTask.rC_Bios__Action_Plan_Task_ID__c, objTask);
          }
          // Populates the account Id and Opportunity Id if the Task is related to Confidential Data
          if(!String.isBlank(objTask.whatId) && oldMap.get(objTask.Id).whatId != objTask.whatId && String.valueOf((objTask.whatId).getSObjectType()) == 'Confidential_Data__c'){
              updateAccountId.add(objTask);
              confIds.add(objTask.whatId);
          }
          
          // Populates the Portfolio Id if the Task is related to Opportunity Object 
          if(!String.isBlank(objTask.whatId) && oldMap.get(objTask.Id).whatId != objTask.whatId && String.valueOf((objTask.whatId).getSObjectType()) == 'Opportunity'){
              updatePortfolioId.add(objTask);
              opportunityIds.add(objTask.whatId);
          }
          
          //Populate Completed Date
          //Amended per GH-17
          if(objTask.Status != oldMap.get(objTask.Id).Status && objTask.Status == 'Completed') {
          	if (objTask.Completed_date__c == NULL) {
              	objTask.Completed_date__c = system.Today();
          	}
            if (objTask.Completed_By__c == NULL) {
          		objTask.Completed_By__c = objTask.OwnerId;
            }
          }
      }
      if(actPlanTskIdToTaskMap != null) {
          populateActionNameOnTask(actPlanTskIdToTaskMap);
      }
      // Populates the account Id if the Task is related to Confidential Data
      if(!confIds.isEmpty()){
          populateAccountId(updateAccountId, confIds);
      }
      
      // Populates the account Id if the Task is related to Confidential Data
      if(!opportunityIds.isEmpty()){
          populateportfolioId(updatePortfolioId, opportunityIds);
      }
        updateOpportuntyStageOnTask(newList,oldMap); 
    }
    
    private static void populateActionNameOnTask(Map<String, Task> taskToActionPlanTskMap) {
        for(rC_Bios__Action_Plan_Task__c objPlan : [SELECT Id, Name, rC_Bios__Action_Plan__r.Name FROM rC_Bios__Action_Plan_Task__c WHERE Id IN: taskToActionPlanTskMap.keySet()]) {
            taskToActionPlanTskMap.get(String.valueOf(objPlan.Id)).Action_Plan_Name__c = objPlan.rC_Bios__Action_Plan__r.Name;
        } 
    }
    
    private static void updateOpportuntyStageOnTask(List<Task> newList, Map<Id,Task> oldMap) {
        List<Task> tasksToProcess = new List<Task>();
        map<Id,String> mapOfOpportunityIdAndStage = new map<Id,String>();
        Set<Id> setOfOpportunityIds = new set<Id>();
        if(oldMap == null) {
            for(Task theTask : newList) {
                if(theTask.Status == 'Completed' && theTask.WhatId != null && (((String.valueOf(theTask.WhatId)).subString(0,3))=='006')) {
                    setOfOpportunityIds.add(theTask.WhatId);
                    tasksToProcess.add(theTask);
                }
            }
        }
        else {
            for(Task theTask : newList) {
                if(theTask.Status == 'Completed' && theTask.WhatId != null && (((String.valueOf(theTask.WhatId)).subString(0,3))=='006') && 
                   (oldMap.get(theTask.Id).Status != 'Completed' || oldMap.get(theTask.Id).WhatId != theTask.WhatId)) {
                       setOfOpportunityIds.add(theTask.WhatId);
                       tasksToProcess.add(theTask);
                   }
            }
            system.debug('tasksToProcess '+tasksToProcess);
        }
        system.debug('setOfOpportunityIds '+setOfOpportunityIds);
        for(Opportunity theOpp : [SELECT Id, StageName  FROM Opportunity WHERE Id IN : setOfOpportunityIds AND RecordTypeId = :proposalID]) {
            mapOfOpportunityIdAndStage.put(theOpp.Id,theOpp.StageName);
        }
        for(Task task : tasksToProcess) {
            task.Stage__c = mapOfOpportunityIdAndStage.get(task.WhatId);
        }
    }
}