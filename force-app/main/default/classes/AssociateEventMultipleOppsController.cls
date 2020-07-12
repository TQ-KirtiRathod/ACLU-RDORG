/*
*
*Name  :  AssociateEventMultipleOppsController
*Author:  Appirio India (Sai Krishna)
*Date  :  April 12, 2017
*Purpose : Controller for AssociateEventToMultipleProposals page. The page opens from a custom button "Attach to Multiple Proposals" 
*          on Event layout. On click of the button, opens a new Page in the same window which shows the Proposal Records under the account 
*          with a button "Attach to Selected Proposals". The event is attached to all the selected proposal records on click of this button.
*
*/
public class AssociateEventMultipleOppsController {
    public Event parentEventRec {get;set;}
    public List<PledgeOpportunityWrapper> opptyWrapper {get;set;}
    public Boolean isWrappernull {get;set;}
    
    public AssociateEventMultipleOppsController (){
        Id eventId = apexPages.currentPage().getParameters().get('EventId');
        opptyWrapper = new List<PledgeOpportunityWrapper>();
        isWrappernull = false;
        if(!String.isBlank(eventId)){
            parentEventRec = [SELECT DurationInMinutes,ActivityDateTime, subject , accountId, ActivityDate , whatId, WhoId 
                              FROM Event 
                              WHERE Id =:eventId LIMIT 1];
            String event15DigitId = String.ValueOf(parentEventRec.Id).substring(0,15);
            // Populate the Opportunity Wrapper by fetching the proposal Records under the account
            for(Opportunity obj: [SELECT Id, Name,(SELECT Id
                                                   FROM events WHERE Parent_Task_Id__c =:event15DigitId) 
                                  FROM Opportunity 
                                  WHERE accountId =: parentEventRec.accountId 
                                    AND recordType.Name = 'Proposal' 
                                    AND Id !=: parentEventRec.whatId  ]){
                if(obj.events.size()>0 && !obj.events.IsEmpty()){                
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
        List<event> eventToCreate = new List<event>();
        List<eventRelation> createEventRelation = new List<eventRelation>();
        Set<Id> Invitees = new Set<Id>();
        for(PledgeOpportunityWrapper objWrap: opptyWrapper){
            if(objWrap.isSelect){
                Event dupEvent = parentEventRec.Clone(false,true,false,false);
                dupEvent.Parent_Task_Id__c = String.ValueOf(parentEventRec.Id).substring(0,15);
                dupEvent.whatId = objWrap.objOppty.Id;
                eventToCreate.add(dupEvent);
            }
        }
    
        
        if(eventToCreate.IsEmpty()){
            ApexPages.Message myMsg;
            myMsg = new ApexPages.Message(ApexPages.Severity.ERROR,'Select any Opportunity and Click to Associate Tasks');
            ApexPages.addMessage(myMsg);
            return null;
        }
        else{
            eventToCreate.add(new Event(Id= parentEventRec.Id, Is_Parent__c = true));
           try{
              
                Upsert eventToCreate;
                
                // Fetch all Invitees for the Parent Event
                for(eventRelation evR: [SELECT Id, Relation.Name,RelationId FROM eventRelation  
                                        WHERE eventId=:parentEventRec.Id AND isInvitee = true]){
                    Invitees.add(evR.RelationId);
                }

                // create invitees for the duplicate events created
                for(Event ev: eventToCreate){
                    if(ev.Is_Parent__c == false){
                        for(Id userId: Invitees){
                            createEventRelation.add(new eventRelation(EventId = ev.Id, IsInvitee = true, RelationId = userId));
                        }
                    }
                }
                if(!createEventRelation.IsEmpty()){
                    insert createEventRelation;
                }
                
                return new PageReference('/'+parentEventRec.Id);
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
        return new PageReference('/'+parentEventRec.Id);
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