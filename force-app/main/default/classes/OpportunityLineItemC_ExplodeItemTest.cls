@IsTest
private class OpportunityLineItemC_ExplodeItemTest {

    @IsTest
    public static void opportunityLineItemExplodeItemTest() {
        OpportunityLineItemTestDataC rc = new OpportunityLineItemTestDataC();
        rc.initializePrerequisites();
		/*TriggerSettings__c triggerSettings = new TriggerSettings__c();
        triggerSettings.Name = 'OpportunityTrigger';
        triggerSettings.isActive__c = false;
        triggerSettings.isTestMode__c = false;
        //triggerSettings.User_Ids_To_Bypass__c = '';

        upsert triggerSettings;*/
        
        rC_Giving__Product_Setting__c productSetting = rC_Giving__Product_Setting__c.getInstance();
        rC_Giving__Opportunity_Setting__c opportunitySettings = rC_Giving__Opportunity_Setting__c.getINstance();
        rC_Giving__Opportunity_Product_Setting__c Settings = rC_Giving__Opportunity_Product_Setting__c.getInstance();
        rC_Giving__Account_Setting__c accountSetting = rC_Giving__Account_Setting__c.getInstance();
        
        rc.initializeSettings(opportunitySettings);
        Product2 otherProduct = new Product2();
        otherProduct.Name = 'RCSBIRD Product Example';
        otherProduct.RecordTypeId = OpportunityLineItemTriggerC.PRODUCT2_RECORD_TYPE_ID_ITEM;
        otherProduct.Family = null;
        otherProduct.IsActive = true;
        insert otherProduct;

        Product2 otherProduct2 = new Product2();
        otherProduct2.Name = 'RCSBIRD Product Example2';
        otherProduct2.RecordTypeId = OpportunityLineItemTriggerC.PRODUCT2_RECORD_TYPE_ID_PACKAGE;
        otherProduct2.Family = null;
        otherProduct2.IsActive = true;
        insert otherProduct2;

        Product2 otherProduct3 = new Product2();
        otherProduct3.Name = 'RCSBIRD Product Example3';
        otherProduct3.RecordTypeId = OpportunityLineItemTriggerC.PRODUCT2_RECORD_TYPE_ID_ITEM;
        otherProduct3.Family = null;
        otherProduct3.IsActive = true;
        insert otherProduct3;
		
        rC_Giving__Package_Item__c packageItem1 = new rC_Giving__Package_Item__c();
        packageItem1.rC_Giving__Package__c = otherProduct2.Id;
        packageItem1.rC_Giving__Item__c = otherProduct.Id;
        insert packageItem1;

        rC_Giving__Package_Item__c packageItem2 = new rC_Giving__Package_Item__c();
        packageItem2.rC_Giving__Package__c = otherProduct2.Id;
        packageItem2.rC_Giving__Item__c = otherProduct3.Id;
        insert packageItem2;

        opportunitySettings.rC_Giving__Package_Discount_Item__c = otherProduct2.name;
        update opportunitySettings;

        Pricebook2 customPb =  new Pricebook2(Name='RCSBIRD', isActive=true);
        insert customPB;

        PricebookEntry pricebookEntry = new PricebookEntry();
        pricebookEntry.Pricebook2Id = Test.getStandardPriceBookId();
        pricebookEntry.Product2Id = otherProduct2.Id;
        pricebookEntry.UnitPrice = 10;
        pricebookEntry.UseStandardPrice = false;
        pricebookEntry.IsActive = true;
        insert pricebookEntry;

        PricebookEntry customEntry = new PricebookEntry();
        customEntry.Pricebook2Id = customPb.Id;
        customEntry.Product2Id = otherProduct2.Id;
        customEntry.UnitPrice = 20;
        customEntry.UseStandardPrice = false;
        customEntry.IsActive = true;
        insert customEntry;
        
        PricebookEntry pricebookEntry2 = new PricebookEntry();
        pricebookEntry2.Pricebook2Id = Test.getStandardPriceBookId();
        pricebookEntry2.Product2Id = otherProduct3.Id;
        pricebookEntry2.UnitPrice = 5;
        pricebookEntry2.UseStandardPrice = false;
        pricebookEntry2.IsActive = true;
        insert pricebookEntry2;

        PricebookEntry customEntry2 = new PricebookEntry();
        customEntry2.Pricebook2Id = customPb.Id;
        customEntry2.Product2Id = otherProduct3.Id;
        customEntry2.UnitPrice = 22;
        customEntry2.UseStandardPrice = false;
        customEntry2.IsActive = true;
        insert customEntry2;

		Test.startTest();

        rc.campaign.rC_giving__Affiliation__c = 'Group 1';
        //upsert rc.campaign;

        // Enable feature
        opportunitySettings.rC_Giving__Disable_UpdateProducts__c = true;

        // New opp
        rc.initializeOpportunity_MembershipAnnually(false);
        rc.opportunity.rC_Giving__Giving_Amount__c = 3000;
        rc.opportunity.rC_Giving__Giving_Type_Engine__c = 'Standard';
        rc.opportunity.Pricebook2Id = customPb.Id;
        //AK:: 09Apr18 - INVALID_OR_NULL_FOR_RESTRICTED_PICKLIST
        //rc.opportunity.Review_Status__c = null;
        insert rc.opportunity;
        
		OpportunityLineItemTriggerC.showErrorMessage = false;
        
        OpportunityLineItem opportunityLineItem = new OpportunityLineItem();
        opportunityLineItem.Product2Id = otherProduct.Id;
        opportunityLineItem.OpportunityId = rc.opportunity.Id;
        opportunityLineItem.rC_Giving__Delivery_Method__c = 'Email';
        opportunityLineItem.Quantity = 1;
        opportunityLineItem.TotalPrice = 10;
        opportunityLineItem.PricebookEntryId = customEntry.Id;
        insert opportunityLineItem;

        test.stopTest();

        Map<String,Integer> deliveryMethodCountMap = new Map<String,Integer>();
        List<AggregateResult> results = [
            SELECT count(Id) c
                 , rC_Giving__Delivery_Method__c deliveryMethod
              FROM OpportunityLineItem
             WHERE OpportunityId = :rc.opportunity.Id
             GROUP BY rC_Giving__Delivery_Method__c
        ];

        Integer totalCount = 0;
        for(AggregateResult ar : results) {
            deliveryMethodCountMap.put(String.valueOf(ar.get('deliveryMethod')),
                Integer.valueOf(ar.get('c')));
            totalCount += Integer.valueOf(ar.get('c'));
        }

        system.assertEquals(3,totalCount,'OpportunityLineItem_ExplodeItemTest.Test: Package explosion failed');
        system.assertEquals(2,deliveryMethodCountMap.get('Email'));

    }
}