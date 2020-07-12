/*
*
*Name  :  SB_P2P_Trigger_PersonalCampaign
*Author:  Joel Rothschild
*Date  :  March 07, 2017
*Purpose : Contains methods related to P2P_Personal_Campaign__c to be used along with SpringboardTriggerHandler 
*
*/
public with sharing class SB_P2P_Trigger_PersonalCampaign extends SpringboardTriggerHandler {

	private boolean IsExecuting = false;

/*  @TODO: DO WE EVEN NEED THIS?
    public SB_P2P_Trigger_PersonalCampaign(boolean isExecuting){
        IsExecuting = isExecuting;
    }
*/

	/**
	 * Logic to run after new personal campaigns are created.
	 */
	public override void onAfterInsert() {
   		// Increment the campaign count on the related contacts.
   		updateCampaignCountOnContact((P2P_Personal_Campaign__c[]) Trigger.new);
    }
    public void onAfterInsert(P2P_Personal_Campaign__c[] triggerNewOverride) {
    	updateCampaignCountOnContact(triggerNewOverride);
    }
    
    /**
     * Increments the number of personal campaigns a contact is assocated with.
     */
    private void updateCampaignCountOnContact(P2P_Personal_Campaign__c[] personalCampaigns) {
    	Map<Id, Decimal> contactCampaignCount = new Map<Id, Decimal>();
		
		for (P2P_Personal_Campaign__c personalCampaign: personalCampaigns) {
			// Campaign count.
			if (contactCampaignCount.containsKey(personalCampaign.P2P_Campaigner__c)) {
				contactCampaignCount.put(personalCampaign.P2P_Campaigner__c, contactCampaignCount.get(personalCampaign.P2P_Campaigner__c) + 1);
			}
			else {
				contactCampaignCount.put(personalCampaign.P2P_Campaigner__c, 1);	
			}
		}
		
		// Get the contacts that need to be updated.
		if (!contactCampaignCount.isEmpty()) {
			
			List<Contact> contacts = [SELECT Id, SB_P2P_Total_Campaigns__c, SB_P2P_Total_Donations__c, SB_P2P_Total_Donation_Amount__c FROM Contact WHERE Id IN : contactCampaignCount.keySet()];
			for (Contact contact : contacts) {
				// Increase campaign count.
				if (contact.SB_P2P_Total_Campaigns__c == NULL) {
					contact.SB_P2P_Total_Campaigns__c = contactCampaignCount.get(contact.Id);
				}
				else {
					contact.SB_P2P_Total_Campaigns__c += contactCampaignCount.get(contact.Id);
				}
			}
		
			update contacts; 
		}
    }
}