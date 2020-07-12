/*
*
*Name  :  BatchUploadHandler_RetryAddress
*Author:  Amar (rC)
*Date  :  August 24, 2018
*Purpose : The purpose of the class is to handle Address retry logic based on specific error "Insufficient Privileges".
*    1.Create unique MD5 with Address 1 and 2
*    2.Prepare a map BUId -> MD5
*    3.Query on Address Prepare a map MD5 -> AddressId
*    4.Query all address 1/2 queues realted to batch upload
*    5.Iterate address queues
*    6.Get buid from queues and retrieve md5
*    7.based on md5 get address Id
*    8.Identify the suspended queue and update its related address whether its Address_Process_1 or 2
*    9.Setting up batch upload to ready
*/
public with sharing class BatchUploadHandler_RetryAddress {

    public static void retryAddress(rC_Connect__Batch_Upload__c[] batchUploadAddressValidateList) {
        Map<String, String> batchUploadIdToMD5Map = new Map<String, String>();

        // Generate a unique MD5 if address 1 or 2 present
        prepareBatchUploadUniqueMD5(batchUploadAddressValidateList, batchUploadIdToMD5Map);

        if(batchUploadIdToMD5Map.isEmpty()) { 
            return;
        }

        Map<String, String> uniqueMD5ToAddressIdMap = new Map<String, String>(); 
        Map<String, rc_bup__queue__c[]> batchUploadToAddressQueueMap = new Map<String, rc_bup__queue__c[]>();
        // Get all addresses based on unique MD5
        getUniqueMD5Addresses(batchUploadIdToMD5Map.values(), uniqueMD5ToAddressIdMap);

        // Retrieve all Address 1/2 queues and fill the batchUploadToAddressQueueMap Map to process these queues
        getBatchUploadRelatedAddressQueues(batchUploadAddressValidateList, batchUploadToAddressQueueMap);

        // Prepare a map to identify which address is failed Address 1/2
        Map<String, Map<String, Boolean>> batchUploadToSuspendedQueueMap = getBatchUploadSuspendedQueues(batchUploadAddressValidateList);

        rC_Connect__Batch_Upload__c[] batchUploadUpdateableList = new rC_Connect__Batch_Upload__c[]{};
        rc_bup__queue__c[] queueUpdateableList = new rc_bup__queue__c[]{};
        for(rC_Connect__Batch_Upload__c batchUpload :batchUploadAddressValidateList) {
            if(batchUploadToAddressQueueMap.get(batchUpload.Id) == null) {
                continue;
            }
            //Identify which address process needs to be updated
            Map<String, Boolean> processSuspendedMap = batchUploadToSuspendedQueueMap.get(batchUpload.Id);

            for(rc_bup__queue__c queue :batchUploadToAddressQueueMap.get(batchUpload.Id)) {
                if(String.isBlank(queue.rC_BUP__Retriver_Info__c) ) {
                    continue;
                }

                Map<String, Object> retriverInfoMap = (Map<String, Object>)JSON.deserializeUntyped(queue.rC_BUP__Retriver_Info__c);
                String uniqueMD5 = '';

                if(queue.rC_BUP__Process_Name__c.containsIgnoreCase('Address_1_Process') && processSuspendedMap.get('1_Process') != null && processSuspendedMap.get('1_Process')) {
                    uniqueMD5 = batchUploadIdToMD5Map.get(batchUpload.Id+'-1');
                    
                } else if(queue.rC_BUP__Process_Name__c.containsIgnoreCase('Address_2_Process') && processSuspendedMap.get('2_Process') != null && processSuspendedMap.get('2_Process')) {
                    uniqueMD5 = batchUploadIdToMD5Map.get(batchUpload.Id+'-2');
                } else {
                    continue;
                }

                String addressUniqueId = uniqueMD5ToAddressIdMap.get(uniqueMD5);
                retriverInfoMap.remove('rc_connect__batch_upload_address_matched__c');
                retriverInfoMap.put('rc_connect__batch_upload_address_matched__c', addressUniqueId);
                queue.rC_BUP__Retriver_Info__c = JSON.serialize(retriverInfoMap);
                queueUpdateableList.add(queue);
            }

            rC_Connect__Batch_Upload__c batchUploadToUpdate = new rC_Connect__Batch_Upload__c(Id = batchUpload.Id, rC_Connect__Batch_Upload_Status__c = 'Ready for roundData');
            batchUploadUpdateableList.add(batchUploadToUpdate);
        }

        if(queueUpdateableList.size() > 0) {
            update queueUpdateableList;
        }
        if(batchUploadUpdateableList.size() > 0) {
            update batchUploadUpdateableList;
        }

    }

    // Get address records based on unique MD5
    public static void getUniqueMD5Addresses(String[] uniqueMD5List, Map<String, String> uniqueMD5ToAddressIdMap) {

        for(rc_bios__Address__c address :[
            SELECT Id
                 , rC_Bios__Unique_MD5__c
              FROM rc_bios__Address__c
             WHERE rC_Bios__Unique_MD5__c IN :uniqueMD5List
        ]) {
            uniqueMD5ToAddressIdMap.put(address.rC_Bios__Unique_MD5__c, address.Id);
        }

    }

    // Get address 1/2 queues to update with the actual id
    public static void getBatchUploadRelatedAddressQueues(rC_Connect__Batch_Upload__c[] batchUploadAddressValidateList, Map<String, rc_bup__queue__c[]> batchUploadToAddressQueueMap) {

        for(rc_bup__queue__c queue :[
            SELECT Id
                 , rC_BUP__Event__r.rC_BUP__Batch_Upload__c
                 , rC_BUP__Process_Name__c
                 , rC_BUP__Retriver_Info__c
              FROM rc_bup__queue__c
             WHERE rC_BUP__Event__r.rC_BUP__Batch_Upload__c IN :batchUploadAddressValidateList
               AND rC_BUP__Process_Name__c IN ('Address_1_Process', 'Address_2_Process')
        ]) {
            if(batchUploadToAddressQueueMap.containsKey(queue.rC_BUP__Event__r.rC_BUP__Batch_Upload__c)) {
                batchUploadToAddressQueueMap.get(queue.rC_BUP__Event__r.rC_BUP__Batch_Upload__c).add(queue);
            } else {
                batchUploadToAddressQueueMap.put(queue.rC_BUP__Event__r.rC_BUP__Batch_Upload__c, new List<rc_bup__queue__c> {queue });
            }
        }
 
    }

    // Get suspended queues to identify which address queue match id needs to be updated
    private static Map<String, Map<String, Boolean>> getBatchUploadSuspendedQueues(rC_Connect__Batch_Upload__c[] batchUploadAddressValidateList) {
        Map<String, Map<String, Boolean>> batchUploadToSuspendedQueueMap = new Map<String, Map<String, Boolean>>(); 

        for(rc_bup__queue__c queue :[
            SELECT Id
                 , rC_BUP__Event__r.rC_BUP__Batch_Upload__c
                 , rC_BUP__Process_Name__c
              FROM rc_bup__queue__c
             WHERE rC_BUP__Event__r.rC_BUP__Batch_Upload__c IN :batchUploadAddressValidateList
               AND rC_BUP__Queue_State__c = 'Suspend'
         ]) {
            String whichProcess = queue.rC_BUP__Process_Name__c.containsIgnoreCase('2_Process') ? '2_Process' : '1_Process'; 
            Map<String, Boolean> processSuspendedMap = new Map<String, Boolean>(); 
            processSuspendedMap.put(whichProcess, true);
            batchUploadToSuspendedQueueMap.put(queue.rC_BUP__Event__r.rC_BUP__Batch_Upload__c, processSuspendedMap);
        }

        return batchUploadToSuspendedQueueMap;
    }

    // Prepare Unique MD5 based on address on batch upload
    private static void prepareBatchUploadUniqueMD5(rC_Connect__Batch_Upload__c[] batchUploadAddressValidateList
                                                   , Map<String, String> batchUploadIdToMD5Map) {
        for(rC_Connect__Batch_Upload__c batchUpload :batchUploadAddressValidateList) {
            if(isAddress1Present(batchUpload)) {
                String uniqueMD5 = generateUniqueMD5(batchUpload.rC_Connect__Address_Street_Line_1__c
                                                , batchUpload.rC_Connect__Address_Street_Line_2__c
                                                , batchUpload.rC_Connect__Address_City__c
                                                , batchUpload.rC_Connect__Address_State__c
                                                , batchUpload.rC_Connect__Address_Postal_Code__c
                                                , batchUpload.rC_Connect__Address_Country__c);
                batchUploadIdToMD5Map.put(batchUpload.Id + '-1', uniqueMD5);
            }

             if(isAddress2Present(batchUpload)) {
                String uniqueMD5 = generateUniqueMD5(batchUpload.rC_Connect__Address_2_Street_Line_1__c
                                                , batchUpload.rC_Connect__Address_2_Street_Line_2__c
                                                , batchUpload.rC_Connect__Address_2_City__c
                                                , batchUpload.rC_Connect__Address_2_State__c
                                                , batchUpload.rC_Connect__Address_2_Postal_Code__c
                                                , batchUpload.rC_Connect__Address_2_Country__c);
                batchUploadIdToMD5Map.put(batchUpload.Id + '-2', uniqueMD5);
            }

        }

    }

    // Generate Unique MD5
    public static String generateUniqueMD5(String streetLine1
                                            , String streetLine2
                                            , String city
                                            , String state
                                            , String postalCode
                                            , String country) {
        String base = ':' + streetLine1
                    + ':' + streetLine2
                    + ':' + city
                    + ':' + state
                    + ':' + postalCode
                    + ':' + country;
        return EncodingUtil.convertToHex(Crypto.generateDigest('MD5', Blob.valueOf(base.toLowerCase())));
    }

    // Check Address 1 is blank on Batch Upload
    private static Boolean isAddress1Present(rC_Connect__Batch_Upload__c batchUpload) {
        return String.isNotBlank(batchUpload.rC_Connect__Address_Street_Line_1__c)
            || String.isNotBlank(batchUpload.rC_Connect__Address_Street_Line_2__c)
            || String.isNotBlank(batchUpload.rC_Connect__Address_City__c)
            || String.isNotBlank(batchUpload.rC_Connect__Address_State__c)
            || String.isNotBlank(batchUpload.rC_Connect__Address_Postal_Code__c)
            || String.isNotBlank(batchUpload.rC_Connect__Address_Country__c);
    }

    // Check Address 2 is blank on Batch Upload
    private static Boolean isAddress2Present(rC_Connect__Batch_Upload__c batchUpload) {
        return String.isNotBlank(batchUpload.rC_Connect__Address_2_Street_Line_1__c)
            || String.isNotBlank(batchUpload.rC_Connect__Address_2_Street_Line_2__c)
            || String.isNotBlank(batchUpload.rC_Connect__Address_2_City__c)
            || String.isNotBlank(batchUpload.rC_Connect__Address_2_State__c)
            || String.isNotBlank(batchUpload.rC_Connect__Address_2_Postal_Code__c)
            || String.isNotBlank(batchUpload.rC_Connect__Address_2_Country__c);
    }
}