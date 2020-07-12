/*
*
*Name  :  ContactAddressTriggerHandlerTest
*Author:  Appirio India (Sakshi Arora)
*Date  :  May 23,2017
*Purpose : Reset the shareing for the lookups changes
*
*/
@isTest
public class ContactAddressTriggerHandlerTest {
    private static List<rC_Bios__Contact_Address__c> contactAddressList;
    private static List<Zip_Affiliate__c> zipList;
    
    /*
	*
	* Method  contactAddressBeforeInsertTest
	* Testing contact address before insert Scenarios
	*/
    static testMethod void contactAddressBeforeInsertTest() {
        
        createData();
        
        Test.startTest();
        	insert contactAddressList;
        Test.stopTest();
    	List<rC_Bios__Contact_Address__c> contAddress = [	SELECT rC_Bios__Original_City__c, rC_Bios__Original_State__c
                                           					FROM rC_Bios__Contact_Address__c
                                           					WHERE rC_Bios__Original_Postal_Code__c = '55600'];
        // State & City are getting populated                                     		
        System.assertEquals(zipList[0].city__c, contAddress[0].rC_Bios__Original_City__c);  
        System.assertEquals(zipList[0].State__c, contAddress[0].rC_Bios__Original_State__c);     
    } 
    
    /*
	*
	* Method  contactAddressBeforeUpdateTest
	* Testing contact address before update Scenarios
	*/
    static testMethod void contactAddressBeforeUpdateTest() {
        
        createData();
        insert contactAddressList;
        List<rC_Bios__Contact_Address__c> OrigContAddress = [	SELECT rC_Bios__Original_City__c, rC_Bios__Original_State__c
                                           						FROM rC_Bios__Contact_Address__c
                                           						WHERE Id =: contactAddressList[0].Id];
                                           			
        Test.startTest();                               
        	contactAddressList[0].rC_Bios__Original_Postal_Code__c = '55601';
        	update contactAddressList[0];
        Test.stopTest();
        List<rC_Bios__Contact_Address__c> UpdatedContAddress = [	SELECT rC_Bios__Original_City__c, rC_Bios__Original_State__c
                                           							FROM rC_Bios__Contact_Address__c
                                           							WHERE Id =: contactAddressList[0].Id];
        // State & City remains same as per the code                                   		
        System.assertEquals(OrigContAddress[0].rC_Bios__Original_City__c, UpdatedContAddress[0].rC_Bios__Original_City__c); 
        System.assertEquals(OrigContAddress[0].rC_Bios__Original_State__c, UpdatedContAddress[0].rC_Bios__Original_State__c);  
    }
    
    private static void createData(){
        List<Contact> contactList = new List<Contact>();
        List<rC_Bios__Address__c> addressList = new List<rC_Bios__Address__c>();
        contactAddressList = new List<rC_Bios__Contact_Address__c>();
		zipList = new List<Zip_Affiliate__c>();
		Contact cont;
		Zip_Affiliate__c zip;
		rC_Bios__Address__c address;
		rC_Bios__Contact_Address__c accAddress;
		 
        // Contact Records & Zip Affiliate Records
        for(Integer i=0 ; i<5 ; i++){
            cont = TestUtils.createContact(null,'con'+i,'test'+i, false);
            contactList.add(cont);
            
            zip = TestUtils.createZipAffiliate('5560'+i,false);
            zip.city__c = 'AB'+i;
            zip.State__c = 'ZY'+i;
            zipList.add(zip);
        }
        
        insert contactList;
        insert zipList;
        
        // Respective address records 
        for(Integer i=0 ; i<5 ; i++){
            address = TestUtils.createAddress('address'+i, false);
            address.rC_Bios__Postal_Code__c = '5560'+i;
            addressList.add(address);
        }
        insert addressList;
        
        // ContactAddressList Records
        for(Integer i=0 ; i<5 ; i++){
            accAddress = TestUtils.createContactAddress(addressList[i].Id, contactList[i].Id, false);
            accAddress.rC_Bios__Original_Postal_Code__c = '5560'+i;
            contactAddressList.add(accAddress);        
        }
    }
}