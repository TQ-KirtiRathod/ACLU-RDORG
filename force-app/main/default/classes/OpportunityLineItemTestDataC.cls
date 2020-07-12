@IsTest
public class OpportunityLineItemTestDataC {
    public static final Map<Id, Schema.RecordTypeInfo> RT_ID_MAP = Schema.SobjectType.Opportunity.getRecordTypeInfosById();
	public static final Map<String, Id> RECORD_TYPE_ID_BY_DEVELOPER_NAME = GetRecordTypeIdsByDeveloperName(Opportunity.SobjectType);
	public static final Map<String, Id> PRODUCT_RECORD_TYPE_ID_BY_DEVELOPER_NAME = GetRecordTypeIdsByDeveloperName(Product2.SobjectType);
	public static final Map<String, Id> PAYMENT_RECORD_TYPE_ID_BY_DEVELOPER_NAME = GetRecordTypeIdsByDeveloperName(rC_Giving__Payment_Method__c.SobjectType);

    public static final String RT_DEVELOPER_NAME_ITEM_PRODUCT = 'Item';
	public static final String RT_DEVELOPER_NAME_PACKAGE_PRODUCT = 'Package';

	public static final Id RT_ITEM_ID_PRODUCT = getProductRecordTypeId(RT_DEVELOPER_NAME_ITEM_PRODUCT);
	public static final Id RT_PACKAGE_ID_PRODUCT = getProductRecordTypeId(RT_DEVELOPER_NAME_PACKAGE_PRODUCT);

    private static String TEST_PACKAGE_NAME = 'package';
    private static Map<Schema.SObjectType,Map<String,Id>> recordTypeCache = new Map<Schema.SObjectType,Map<String,Id>>();

    public static Product2[] itemList;
    public static Product2 itemPackage;
    public static Product2[] subItemList;
    public static rC_Giving__GAU__c[] accountingUnitList;
    public rC_Giving__Giving_Level__c[] givingLevelList;
    public Campaign campaign;
    public Account account;
    public Contact contact;
    public Opportunity opportunity;
    public rC_Giving__Payment_Method__c paymentMethod;
    public static PricebookEntry[] pricebookEntries;
    public static Pricebook2 customPb;

    public void initializeSettings(rC_Giving__Opportunity_Setting__c opportunitySettings) {

        //rC_Giving__Opportunity_Setting__c opportunitySettings = rC_Giving__Opportunity_Setting__c.getINstance();
        opportunitySettings.rC_Giving__Disable_UpdateProducts__c = true;
        opportunitySettings.rC_Giving__Disable_Advanced_Financial_CRM__c = true;
        opportunitySettings.rC_Giving__Disable_CascadeAffiliations__c = true;
        opportunitySettings.rC_Giving__Disable_CascadeAllocations__c  = true;
        opportunitySettings.rC_Giving__Disable_CascadeGivingParent__c = true;
        opportunitySettings.rC_Giving__Disable_CascadeHardCredits__c = true;
        opportunitySettings.rC_Giving__Disable_CascadePaymentMethods__c = true;
        opportunitySettings.rC_Giving__Disable_CascadePlannedGiving__c = true;
        opportunitySettings.rC_Giving__Disable_CascadeSoftCredits__c = true;
        opportunitySettings.rC_Giving__Disable_CascadeSummaries__c = true;
        opportunitySettings.rC_Giving__Disable_ImportCampaign__c = true;
        opportunitySettings.rC_Giving__Disable_ImportCampaignProducts__c = true;
        opportunitySettings.rC_Giving__Disable_InsertAllocations__c = true;
        opportunitySettings.rC_Giving__Disable_InsertMatchingCredit__c = true;
        opportunitySettings.rC_Giving__Disable_RollupAllocations__c = true;
        opportunitySettings.rC_Giving__Disable_RollupGiving__c = true;
        opportunitySettings.rC_Giving__Disable_UpdateCurrency__c = true;
        opportunitySettings.rC_Giving__Disable_UpdateMatching__c = true;
        opportunitySettings.rC_Giving__Disable_UpdateProducts__c = true;

        upsert opportunitySettings;
        rC_Giving__Opportunity_Product_Setting__c Settings = rC_Giving__Opportunity_Product_Setting__c.getInstance();
        Settings.rC_Giving__Disable_ExplodeItems__c = true;
        Settings.rC_Giving__Disable_SetDeliveryMethod__c = true;
		upsert Settings;
        
        rC_Giving__Account_Setting__c accountSetting = rC_Giving__Account_Setting__c.getInstance();
        accountSetting.rC_Giving__Update_Summaries_Batch__c = true;
        accountSetting.rC_Giving__Disable_RollupSummaries__c  = true;
        accountSetting.rC_Giving__Disable_RollupRecognitionCredits__c = true;
        accountSetting.rC_Giving__Disable_UpdateSummaries__c = true;
		upsert accountSetting;
        rC_Giving__Product_Setting__c productSetting = rC_Giving__Product_Setting__c.getInstance();
        productSetting.rC_Giving__Disable_CascadeFMV__c = true;
        productSetting.rC_Giving__Disable_CascadePaymentMethods__c = true;
        productSetting.rC_Giving__Disable_UpdateActive__c = true;
        productSetting.rC_Giving__Disable_UpdateActiveDates__c = true;
        productSetting.rC_Giving__Disable_UpdateGivingLevelItems__c = true;
		upsert productSetting;
    }

	public static Product2[] setupProductHierarchy() {

        Product2[] items = new Product2[]{};
        Product2[] subitems = new Product2[]{};

        Product2 pkg = new Product2();
        pkg.Name = TEST_PACKAGE_NAME;
        pkg.IsActive = true;
        pkg.RecordTypeId = RT_PACKAGE_ID_PRODUCT;

        for(Integer i = 0; i < 2; i++){
            Product2 item = new Product2();
            item.Name = 'item ' + i;
            item.IsActive = true;
            item.RecordTypeId = RT_ITEM_ID_PRODUCT;
            items.add(item);
        }
		    insert items;
        // Combining the pkg and items into one insert 		to save on trigger queries,
        // which are unbelievably inefficient for Products
        Product2[] combinedList = new Product2[]{};
        combinedList.add(pkg);
        //combinedList.addAll(items);
        insert combinedList;

        rC_Giving__Package_Item__c[] packageitems = new rC_Giving__Package_Item__c[]{};

        for (Product2 product : items) {
            packageitems.add(new rC_Giving__Package_Item__c(rC_Giving__Package__c = pkg.id, rC_Giving__Item__c = product.id));
        }

        insert packageitems;

        for(Product2 item : items) {
            for(Integer i = 0; i < 1; i++) {
                Product2 subItem = new Product2();
                subItem.Name = 'sub-item ' + i;
                subItem.IsActive = true;
                subItem.RecordTypeId = RT_ITEM_ID_PRODUCT;
                subItem.rC_Giving__Parent_Item__c = item.Id;
                subItem.rC_Giving__FMV__c = 0.0;
                subitems.add(subItem);
            }
        }

        insert subitems;

        // This collection is intended to be used for setting up test pricebook enties for the hierarchy
        Product2[] allItems = new Product2[]{};
        allItems.add(pkg);
        allItems.addAll(items);
        allItems.addAll(subitems);

        return allItems;
    }

 	static Id getProductRecordTypeId(String name) {
		return PRODUCT_RECORD_TYPE_ID_BY_DEVELOPER_NAME.get(name);
	}

    public static Map<String, Id> getRecordTypeIdsByDeveloperName(Schema.SObjectType sObjectType) {
		if (sObjectType == null) {
			return new Map<String, Id>();
		}
		/*if (!recordTypesArePrefetched) {
			prefetchRecordTypes();
		}*/
        Map<String, Id> recordTypeMap = new Map<String, Id>();
        /*for (RecordType recordType :[SELECT Id, Name FROM RecordType WHERE SobjectType=:String.valueOf(sObjectType)]) {
            recordTypeMap.put(recordType.Name,recordType.Id);
        }*/
		recordTypeCache = recordTypeCache == null ? new Map<Schema.SObjectType,Map<String,Id>>(): recordTypeCache;
		recordTypeMap = recordTypeCache.get(sObjectType);
		// If not, build a map of RecordTypeIds keyed by DeveloperName
		if (recordTypeMap == null) {
			fetchRecordTypes(sObjectType);
			recordTypeMap = recordTypeCache.get(sObjectType);
		}

		return recordTypeMap;
	}

    public void initializePrerequisites() {
        initializeAccountingUnitList();
        initializeGivingLevelList();
        initializeCampaign(true);
        initializeAccount(true);
        initializeContact(true);
        initializePaymentMethod_ChargeCard();
    }

    private static void fetchRecordTypes(Schema.SObjectType sobjectType) {
		fetchRecordTypes(new List<Schema.SObjectType>{sobjectType});
	}

    public static void fetchRecordTypes(List<Schema.SObjectType> sobjectTypes) {
		Map<String, Schema.SObjectType> sobjectTypesByName = new Map<String, Schema.SObjectType>();
		for (Schema.SObjectType soType : sobjectTypes) {
			sobjectTypesByName.put(String.escapeSingleQuotes(soType.getDescribe().getName()), soType);
		}

        List<RecordType> recordTypes = [SELECT Id, Name, DeveloperName, SObjectType FROM RecordType
			WHERE SObjectType IN :sobjectTypesByName.keySet() AND IsActive = TRUE ORDER BY SObjectType ASC];

		String currentSObjectName = '';
		Map<String, Id> currentRecordTypeMap = null;

		// This loop depends upon the recordTypes being ordered by SObjectType
		for (RecordType rt : recordTypes) {
			if (currentSObjectName != rt.SObjectType) {
				currentSObjectName = rt.SObjectType;
				currentRecordTypeMap = new Map<String, Id>();
				recordTypeCache.put(sobjectTypesByName.get(currentSObjectName), currentRecordTypeMap);
			}
			currentRecordTypeMap.put(String.valueOf(rt.get('DeveloperName')), rt.Id);
		}
	}

     public static void initializeProductHierarchy() {
        itemPackage = [
            select Name, IsActive, RecordTypeId
            from Product2
            where Name = 'package'
            and IsActive = true
            and RecordTypeId = :RT_PACKAGE_ID_PRODUCT
            limit 1
        ];

        rC_giving__Package_Item__c[] packageitems = [
            select rC_giving__Package__c, rC_giving__Item__c
            from rC_giving__Package_Item__c
            where rC_giving__Package__c = :itemPackage.Id
        ];

        List<Id> itemIds = new List<Id>();

        for (rC_giving__Package_Item__c pi : packageItems) {
            itemIds.add(pi.rC_giving__Item__c);
        }

         itemList = [
            select Name, IsActive, RecordTypeId, rC_giving__FMV__c
            from Product2
            where Id in :itemIds
            and IsActive = true
            and RecordTypeId = :RT_ITEM_ID_PRODUCT
        ];

        subItemList = [
            select Name, rC_giving__Parent_Item__c, IsActive, RecordTypeId, rC_giving__FMV__c
            from Product2
            where rC_giving__Parent_Item__c in :itemIds
            and IsActive = true
            and RecordTypeId = :RT_ITEM_ID_PRODUCT
        ];

        //if(withPricebookEntries) initializePricebook();
    }

    public static List<rC_Giving__Giving_Level__c> createGivingLevel() {
        List<rC_Giving__Giving_Level__c> theList = new List<rC_Giving__Giving_Level__c>();
		for(Decimal i = 0; i < 3000; i += 1000) {
            rC_Giving__Giving_Level__c givingLevel = new rC_Giving__Giving_Level__c();
            givingLevel.Name = 'RCSBIRD Giving Level ' + i;
            givingLevel.rC_Giving__Activity_Type__c = 'Donation';
            givingLevel.rC_Giving__Affiliation__c = 'RCSBIRD';
            givingLevel.rC_Giving__Min_Amount__c = i;
            givingLevel.rC_Giving__Max_Amount__c = i + 1000 - 0.01;
            givingLevel.rC_Giving__Major_Donor_Level__c = givingLevel.rC_Giving__Min_Amount__c >= 1500;
            givingLevel.rC_Giving__Active_Months__c = '12';
            givingLevel.rC_Giving__Renewal_Months__c = '2';
            givingLevel.rC_Giving__Grace_Months__c = '2';
            //givingLevel.Period_Type__c = OpportunityRecordTypes.RT_MEMBERSHIP.equals(scenario.activityType) ? null : TYPE_CALENDAR_YEAR;
            theList.add(givingLevel);
        }
        insert theList;

        return theList;
    }

    public static void setupPriceBookEntriesforProducts(Product2[] productList) {
        if (productList.isEmpty()) {
            System.debug(LoggingLevel.WARN, 'setupPriceBookEntriesforProducts: productList is empty');
        } else {
            customPb =  new Pricebook2(Name='RCSBIRD', isActive=true);
        	insert customPB;

            setupPriceBookEntriesforProducts(customPb, productList);
        }
    }

    private static void setupPriceBookEntriesforProducts(Pricebook2 customPb, Product2[] productList) {

        // Used for insert
        pricebookEntries = new PricebookEntry[] {};
		System.debug('productList :: ' + productList);
        // Add to the standard pricebook
        for(Product2 product : productList) {
            if (product.Id == null) {
                continue;
            }
            PricebookEntry pricebookEntry = new PricebookEntry();
            pricebookEntry.Pricebook2Id = Test.getStandardPriceBookId();
            pricebookEntry.Product2Id = product.Id;
            pricebookEntry.UnitPrice = 10;
            pricebookEntry.UseStandardPrice = false;
            pricebookEntry.IsActive = true;
            pricebookEntries.add(pricebookEntry);

            PricebookEntry customEntry = new PricebookEntry();
            customEntry.Pricebook2Id = customPb.Id;
            customEntry.Product2Id = String.valueOf(product.Id).substring(0,15);
            customEntry.UnitPrice = 10;
            customEntry.UseStandardPrice = false;
            customEntry.IsActive = true;
            pricebookEntries.add(customEntry);
        }
		System.debug('pricebookEntries****' + pricebookEntries);
        insert pricebookEntries;
    }

    public rC_Giving__GAU__c[] initializeAccountingUnitList() {
        accountingUnitList = new rC_Giving__GAU__c[] {};

        for(Integer i = 0; i < 3; i++) {
            rC_Giving__GAU__c accountingUnit = new rC_Giving__GAU__c();
            accountingUnit.Name = 'RCSBIRD Accounting Unit ' + i;
            accountingUnitList.add(accountingUnit);
        }
		insert accountingUnitList;
        return accountingUnitList;
    }

 	public rC_Giving__Giving_Level__c[] initializeGivingLevelList() {
        givingLevelList = new rC_Giving__Giving_Level__c[] {};

        for(Decimal i = 0; i < 3000; i += 1000) {
            rC_Giving__Giving_Level__c givingLevel = new rC_Giving__Giving_Level__c();
            givingLevel.Name = 'RCSBIRD Giving Level ' + i;
            givingLevel.rC_Giving__Activity_Type__c = 'Donation';
            givingLevel.rC_Giving__Affiliation__c = 'RCSBIRD';
            givingLevel.rC_Giving__Min_Amount__c = i;
            givingLevel.rC_Giving__Max_Amount__c = i + 1000 - 0.01;
            givingLevel.rC_Giving__Major_Donor_Level__c = givingLevel.rC_Giving__Min_Amount__c >= 1500;
            givingLevel.rC_Giving__Active_Months__c = '12';
            givingLevel.rC_Giving__Renewal_Months__c = '2';
            givingLevel.rC_Giving__Grace_Months__c = '2';
            givingLevelList.add(givingLevel);
        }

        // Insert it
        insert givingLevelList;

        return givingLevelList;
    }

 	public Campaign initializeCampaign(Boolean isInsertable) {
        campaign = new Campaign();
        campaign.Name = 'RCSBIRD Campaign Name';
        campaign.IsActive = true;
        campaign.rC_Giving__Source_Code__c = 'RCSBIRD_TEST';
        campaign.rC_Giving__Affiliation__c = 'RCSBIRD';

        if (accountingUnitList != null && accountingUnitList.isEmpty() == false) {
            campaign.rC_giving__GAU__c = accountingUnitList[0].Id;
        }

        if (isInsertable == true) {
            insert campaign;
        }

        return campaign;
    }

    public Account initializeAccount(Boolean isInsert) {
        account = new Account();
        account.Name = 'RCSBIRD Account';
        account.rC_Giving__Track_Affiliations__c = true;
        account.rC_Giving__Track_Hard_Credits__c = true;
        account.rC_Giving__Track_Soft_Credits__c = true;
        account.rC_Giving__Track_Summaries__c = true;

        if (isInsert == true) {
            insert account;
        }

        return account;
    }

    public Contact initializeContact(Boolean isInsert) {

        contact = new Contact();
        contact.FirstName = 'Jason';
        contact.LastName = 'RCSBIRD';
        contact.AccountId = account.Id;
        contact.rC_Giving__Track_Hard_Credits__c = true;
        contact.rC_Giving__Track_Soft_Credits__c = true;

        if (isInsert == true) {
            insert contact;
        }

        return contact;
    }

    public rC_Giving__Payment_Method__c initializePaymentMethod_ChargeCard() {
        System.debug('PAYMENT_RECORD_TYPE_ID_BY_DEVELOPER_NAME :: ' + PAYMENT_RECORD_TYPE_ID_BY_DEVELOPER_NAME);
        paymentMethod = new rC_Giving__Payment_Method__c();
        paymentMethod.RecordTypeId = PAYMENT_RECORD_TYPE_ID_BY_DEVELOPER_NAME.get('Cash_Check');
        paymentMethod.rC_Giving__Account__c = account.Id;
        paymentMethod.rC_Giving__Contact__c = contact.Id;
        /*paymentMethod.rC_Giving__Billing_Street__c = '123 Main St #1001';
        paymentMethod.rC_Giving__Billing_City__c = 'Lone Tree';
        paymentMethod.rC_Giving__Billing_State__c = 'CO';
        paymentMethod.rC_Giving__Billing_Postal_Code__c = '80124';
        paymentMethod.rC_Giving__Billing_Country__c = 'US';
        paymentMethod.rC_Giving__Card_Holder_Name__c = 'RCSBIRD';
        paymentMethod.rC_Giving__Card_Number__c = '4111111111111111';
        paymentMethod.rC_Giving__Card_Expiration_Month__c = '01';*/
        paymentMethod.rC_Giving__Card_Expiration_Year__c = '20';
        paymentMethod.rC_Giving__Is_Active__c = true;
        paymentMethod.rC_Giving__Is_Default__c = false;
        paymentMethod.rC_Giving__Payment_Type__c = 'Charge Card';

        insert paymentMethod;
        return paymentMethod;
    }
    public void initializeOpportunity_MembershipAnnually(Boolean isInsertable) {
        initializeOpportunity(isInsertable, RECORD_TYPE_ID_BY_DEVELOPER_NAME.get('Donation'), 'Annually', 'Annually');
    }
    //
    public Opportunity initializeOpportunity(Boolean isInsertable, Id recordTypeId, String givingFrequency, String paymentFrequency) {
        Opportunity opportunity = initializeOpportunity(false);
        opportunity.RecordTypeId = recordTypeId;
        opportunity.rC_giving__Giving_Frequency__c = givingFrequency;
        opportunity.rC_giving__Payment_Frequency__c = paymentFrequency;

        if (isInsertable == true) {
            insert opportunity;
        }

        return opportunity;
    }

    public Opportunity initializeOpportunity(Boolean isInsertable) {

        opportunity = new Opportunity();
        opportunity.rC_Giving__Affiliation__c = 'RCSBIRD';
        opportunity.AccountId = account.Id;
        opportunity.Amount = 0;
        opportunity.CampaignId = campaign.Id;
        opportunity.CloseDate = Date.today();
        opportunity.rC_Giving__Giving_Amount__c = 950;
        opportunity.rC_Giving__Giving_Frequency__c = 'One Payment';
        opportunity.rC_Giving__Giving_Years__c = 1;
        opportunity.rC_Giving__Giving_Type_Engine__c = 'Standard';
        //opportunity.rC_Giving__Matching_Account__c = accountEmployer != null ? accountEmployer.Id : null;
        opportunity.rC_Giving__Payment_Frequency__c = 'One Payment';
        opportunity.rC_Giving__Payment_Method_Selected__c = paymentMethod.Id;
        opportunity.rC_Giving__Payment_Method__c = paymentMethod.rC_Giving__Payment_Type__c;
        opportunity.RecordTypeId = RECORD_TYPE_ID_BY_DEVELOPER_NAME.get('DONATION');
        opportunity.StageName = 'Open';
        opportunity.name = 'donation';

        if (isInsertable == true) {
            insert opportunity;
        }

        return opportunity;
    }
}