trigger OpportunityLineItemC_BeforeInsert on OpportunityLineItem (before insert) {
	new OpportunityLineItemC_ExplodeItem(trigger.old, trigger.new).execute();
}