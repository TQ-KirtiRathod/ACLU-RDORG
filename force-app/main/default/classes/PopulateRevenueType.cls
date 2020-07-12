/*
*
*Name  :  PopulateRevenueType
*Author:  Appirio India (Shikha Gupta)
*Date  :  June 13, 2017
*Purpose : Contains method to populate RPT_Revenue_Type__c on Opportunity. Used in OpportunityTriggerHandler
*
*/
public class PopulateRevenueType {
    
    private static Set<String> setOfShareCodesForPGC = new Set<String>{'Q001','Q002','Q003','Q004','Q005',
                                                            'U001','U002','U003','U004','U005'};
	private static Set<String> setOfShareCodes = new Set<String>{'A001','A002','A003','B003','C005','C008',
                                                       'C009','D009','D010','D011','D012','E013',
                                                       'E015','E016','E017','P001','P002','P003'};
	private static Set<String> setOfRequiredSourcecodes = new Set<String>{'H100','E181','R181'};
	
	public static List<Opportunity> populateRevenueType(List<Opportunity> listOfOppsToProcess) {
		List<Opportunity> opptyToUpdate = new List<Opportunity>();
        
		for(Opportunity opp: listOfOppsToProcess) {
            
			if((opp.Deposit_Site__c == null || (opp.Deposit_Site__c != null && opp.Deposit_Site__c != Label.Cosmetic_Gift_Deposit_Site)) 
            && (opp.Sharing_Code__c == null || (opp.Sharing_Code__c != null && !setOfRequiredSourcecodes.contains(opp.Sharing_Code__c )))) {
        	
		        if(opp.rC_Giving__Source_Code__c != null
					           && ((opp.rC_Giving__Source_Code__c.length() >= 9) && ((opp.rC_Giving__Source_Code__c).subString(7,9) == 'SF'))) {
						    opp.RPT_Revenue_Type__c = 'Short Fall';
						
		        } else if ((opp.RPT_Package_Code__c != null) && (opp.RPT_Package_Code__c.length() >= 7) 
		                  && ((opp.RPT_Package_Code__c).subString(3,7) == 'CPXX')) {
						    opp.RPT_Revenue_Type__c = 'Leading Freedom Forward';
						
		        } else if ((opp.RPT_Package_Code__c != null) && (opp.RPT_Package_Code__c.length() >= 7) 
		                  && ((opp.RPT_Package_Code__c).subString(3,7) == 'CPCC')) {
						    opp.RPT_Revenue_Type__c = 'Transformational';
						
		        } else if (opp.Program_Type__c != null && opp.Sharing_Code__c != null 
		                  && (opp.Program_Type__c == '1' || opp.Program_Type__c == '2' || opp.Program_Type__c == '3') 
		                  && setOfShareCodes.contains(opp.Sharing_Code__c)) {
						   opp.RPT_Revenue_Type__c = 'Membership';
						
		        } else if (opp.Sharing_Code__c != null && setOfShareCodesForPGC.contains(opp.Sharing_Code__c)) {
						    opp.RPT_Revenue_Type__c = 'Planned Giving Cash';
						
		        } else {
						    opp.RPT_Revenue_Type__c = 'Annual Fund';
						}
						//opptyIds.add(opp.Id);
		        opptyToUpdate.add(opp);
		      }
		}
		return opptyToUpdate;
	}
}