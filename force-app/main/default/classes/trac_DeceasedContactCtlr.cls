/**
 *
 *
 * @author  Surya pratap, Traction on Demand
 * @Date    2019-06-18
 */
public class trac_DeceasedContactCtlr {

    @AuraEnabled
    public static Contact getContact(String recordId) {
        if(!String.isEmpty(recordId)) {
            return [SELECT Id, rC_Bios__Deceased__c, rC_Bios__Deceased_Day__c, 
                    rC_Bios__Deceased_Month__c, rC_Bios__Deceased_Year__c,
                    AccountId
            FROM Contact
            WHERE Id =: recordId];
        }
        return null;
    }

    @AuraEnabled
    public static String updateContact(String contactJSON) {
        Map<String, String> response = new Map<String, String>{'status' => 'success', 'message' => 'Record saved successfully'}; 
        Contact contact = (Contact)JSON.deserialize(contactJSON, Contact.class);
        Savepoint sp = Database.setSavepoint();
        try {
            
            if(String.isEmpty(contact.rC_Bios__Deceased_Year__c)) {
                throw new trac_Exception('Deceased Year is Required Field');  
            }
            //added to avoid loop on updating contact itself from Phone trigger.
            contact.HomePhone = null;
            contact.rC_Bios__Preferred_Phone__c = null;
            update contact;
            response.put('message', 'Contact deceased successfully \n' + getRecordSaveStatus());
        } catch(Exception ex) {
            response.put('status', 'error');
            if(ex.getMessage().contains('CAN_NOT_UPDATE_NATIONAL_PLEDGE')) {
                response.put('message', System.Label.Deceased_Contact_Can_Not_Update_National_Pledge);
            } else {
                response.put('message', ex.getMessage());
            }
            DataBase.rollback(sp);
        }
        return JSON.serialize(response);
    }
    
    
    @AuraEnabled
    public static String getDeceasedDateAndHelpTextInfo() {
        Map<String, Object> deceadedDateAndHelpText = new Map<String, Object>();
        deceadedDateAndHelpText.put('DeceasedDate', getDeceasedDayMonthAndYearPickListValue());
        deceadedDateAndHelpText.put('HelpText', getFieldsHelpText());
        
        return JSON.serialize(deceadedDateAndHelpText);
    }
    
    private static Map<String, List<String>> getDeceasedDayMonthAndYearPickListValue() {
        
        Map<String, List<String>> deceasedContactPickList = new Map<String, List<String>>();
        deceasedContactPickList.put('DeceasedDay', Utilities.getPickListOptions('Contact', 'rC_Bios__Deceased_Day__c'));
        deceasedContactPickList.put('DeceasedMonth', Utilities.getPickListOptions('Contact', 'rC_Bios__Deceased_Month__c'));
        deceasedContactPickList.put('DeceasedYear', Utilities.getPickListOptions('Contact', 'rC_Bios__Deceased_Year__c'));
        
        return deceasedContactPickList;
        
    }
   
    private static Map<String, String> getFieldsHelpText() {       
        List<String> fieldToGetHelpText = new List<String>{'rc_bios__deceased_day__c','rc_bios__deceased_month__c','rc_bios__deceased_year__c'};
       	return Utilities.getFieldsHelpText('Contact', fieldToGetHelpText);
    }
    
    private static String getRecordSaveStatus() {
        String message = trac_HandleDeceasedContacts.contactsAccountsUpdated +  '  Account Record Updated \n';
        message += trac_HandleDeceasedContacts.contactsEmailUpdated + ' Email Record Updated \n';
        message += trac_HandleDeceasedContacts.contactsPhoneUpdated + ' Phone Record Updated \n';
        message += trac_HandleDeceasedContacts.contactsOpportunityUpdated + ' Opportunities Record Updated \n';
        message += trac_HandleDeceasedContacts.accountsPreferredCreated + ' Account Preference Record Created ';
        
        return message;
    }
}