/*
*Name  :  CancelSustainerPledge
*Author:  Appirio India (Harshita Khandelwal)
*Date  :  Oct 25, 2017
*Purpose : Contains webservice methods to be called from Cancel_Sustainer_Pledge button on Opportunity
*
*/
global class CancelSustainerPledge {
    webservice static String getCancellationValues() {
    	String cancellationValues = '{';
    	
        for(Schema.PicklistEntry value : Opportunity.Cancellation_Reason__c.getDescribe().getPicklistValues()) {
        	cancellationValues += '"'+value.getLabel()+'":"'+value.getValue()+'",';
        }
        cancellationValues = cancellationValues.removeEnd(',');
        cancellationValues += '}';
        return cancellationValues;
    }
    
    webservice static void forceCancelPledge(String reasonVal, Id opptyId) {
        List<Opportunity> opptyToUpdate = new List<Opportunity>();
        
        for(Opportunity objOppty : [SELECT Id, Cancellation_Reason__c, rC_Giving__Is_Canceled__c, rC_Giving__Payment_End_Date__c FROM Opportunity WHERE Id =: opptyId]) {
            //objOppty.Cancellation_Reason__c = reasonVal;
            //objOppty.rC_Giving__Is_Canceled__c = true;
            objOppty.rC_Giving__Payment_End_Date__c = Date.today();
            opptyToUpdate.add(objOppty);
        } 
        
        if(!opptyToUpdate.isEmpty()) {
            update opptyToUpdate;
            updateCancelFieldsOnOpp(reasonVal, opptyId);
            //update new Opportunity(Id = opptyId, StageName = 'Canceled');
        }
    }
    
    @future
    public static void updateCancelFieldsOnOpp(String reasonVal, Id opptyId) {
        List<Opportunity> opptyToUpdate = new List<Opportunity>();
        
        for(Opportunity objOppty : [SELECT Id, Cancellation_Reason__c, rC_Giving__Is_Canceled__c FROM Opportunity WHERE Id =: opptyId]) {
            objOppty.Cancellation_Reason__c = reasonVal;
            objOppty.rC_Giving__Is_Canceled__c = true;
            objOppty.StageName = 'Canceled';
            opptyToUpdate.add(objOppty);
        } 
        
        if(!opptyToUpdate.isEmpty()) {
            update opptyToUpdate;
        }
    }
}