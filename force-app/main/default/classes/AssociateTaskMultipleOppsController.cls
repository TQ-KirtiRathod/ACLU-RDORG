/*
*
*Name  :  AssociateTaskMultipleOppsController
*Author:  Appirio India (Sai Krishna)
*Date  :  April 12, 2017
*Purpose : Controller for AssociateTaskMultipleOpps page. The page opens from a custom button "Attach to Multiple Proposals" on Task layout. 
*          On click of the button, opens a new Page in the same window which shows the Proposal Records under the account with a button 
*          "Attach to Selected Proposals". The task is attached to all the selected proposal records on click of this button.
*
*/
public class AssociateTaskMultipleOppsController {
    public Task parentTaskRec {get;set;}
    public List<PledgeOpportunityWrapper> opptyWrapper {get;set;}
    public Boolean isWrappernull {get;set;}
    public AssociateTaskMultipleOppsController (){
        Id taskId = apexPages.currentPage().getParameters().get('TaskId');
        opptyWrapper = new List<PledgeOpportunityWrapper>();
        isWrappernull = false;
        if(!String.isBlank(taskId)){
            parentTaskRec = [SELECT Id, accountId, ActivityDate, Stage__c, WhatId , Meaningful_Contact__c, Action_Type__c, Priority, Status, Subject FROM Task WHERE Id =:taskId LIMIT 1];
            String task15DigitId = String.ValueOf(parentTaskRec.Id).substring(0,15);
            // Populate the Opportunity Wrapper by fetching the proposal Records under the account
            for(Opportunity obj: [SELECT Id, Name,(SELECT Id FROM tasks WHERE Parent_Task_Id__c =:task15DigitId) FROM Opportunity WHERE accountId =: parentTaskRec.accountId AND recordType.Name = 'Proposal' AND Id !=: parentTaskRec.whatId ]){
                if(obj.Tasks.size()>0 && !obj.Tasks.IsEmpty()){                
                    opptyWrapper.add(new PledgeOpportunityWrapper(true,obj));
                }
                else{
                    opptyWrapper.add(new PledgeOpportunityWrapper(false,obj));
                }
            }
            // Disable the save button if the List is Empty
            if(opptyWrapper.IsEmpty()){
                isWrappernull = true;
            }
        }
    }
    
    // Save method 
    public pageReference save(){
        system.debug('EnteredSave>>>:::');
        List<Task> taskToCreate = new List<Task>();
        for(PledgeOpportunityWrapper objWrap: opptyWrapper){
            if(objWrap.isSelect){
                Task dupTask = parentTaskRec.Clone(false,true,false,false);
                dupTask.Parent_Task_Id__c = String.ValueOf(parentTaskRec.Id).substring(0,15);
                dupTask.whatId = objWrap.objOppty.Id;
                taskToCreate.add(dupTask);
            }
        }
        
        if(taskToCreate.IsEmpty()){
            ApexPages.Message myMsg;
            myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Select any Opportunity and Click to Associate Tasks');
            ApexPages.addMessage(myMsg);
            return null;
        }
        else{
            taskToCreate.add(new Task(Id= parentTaskRec.Id, Is_Parent__c = true));
            try{
                Upsert taskToCreate;
                system.debug('taskToCreate>>>:::'+taskToCreate);
                return new PageReference('/'+parentTaskRec.Id);
            }
            catch(exception e){
                ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,e.getMessage());
                ApexPages.addMessage(myMsg);
                return null;
            }
        }
        
    }
    
    // Cancel method 
    public pageReference Cancel(){
        return new PageReference('/'+parentTaskRec.Id);
    }
    
    //Wrapper Class
    public class PledgeOpportunityWrapper {
        public Boolean isSelect {get;set;}
        public Opportunity objOppty {get;set;}
        
        public PledgeOpportunityWrapper (Boolean isSelect, Opportunity Obj){
            this.isSelect = isSelect;
            this.objOppty = Obj;
        }
        
    }

}