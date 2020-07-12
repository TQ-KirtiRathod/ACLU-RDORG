public abstract class OpportunityLineItemTriggerC {

    public static final String PRODUCT2_RECORD_TYPE_NAME_ITEM = 'Item';
    public static final String PRODUCT2_RECORD_TYPE_NAME_PACKAGE = 'Package';
	public static Boolean showErrorMessage = false;
    public static final String PRODUCT2_DELIVERY_METHOD_EMAIL = 'Email';
    public static final String PRODUCT2_DELIVERY_METHOD_BILLING_ADDRESS = 'Billing Address';
    public static final String PRODUCT2_DELIVERY_METHOD_SHIPPING_ADDRESS = 'Shipping Address';
    public static final String PRODUCT2_DELIVERY_METHOD_MAILING_ADDRESS = 'Mailing Address';
    public static final String PRODUCT2_DELIVERY_METHOD_OTHER_ADDRESS = 'Other Address';
    public static final String PRODUCT2_DELIVERY_METHOD_IN_PERSON = 'In Person';

    public static final Map<String, Schema.RecordTypeInfo> PRODUCT2_RECORD_TYPE_INFO_MAP = Schema.SobjectType.Product2.getRecordTypeInfosByName();
    public static final Id PRODUCT2_RECORD_TYPE_ID_ITEM = PRODUCT2_RECORD_TYPE_INFO_MAP.get(PRODUCT2_RECORD_TYPE_NAME_ITEM).getRecordTypeId();
    public static final Id PRODUCT2_RECORD_TYPE_ID_PACKAGE = PRODUCT2_RECORD_TYPE_INFO_MAP.get(PRODUCT2_RECORD_TYPE_NAME_PACKAGE).getRecordTypeId();
    public class UnexpectedNullException extends Exception{}

    //Map of relationships between the Package and its items.
    public Map<Id,List<rC_Giving__Package_Item__c>> packageItemMap;

    //<opportunity.pricebook + product2Id,PricebookEntry> all entries for a particular pricebook (associated with opportunities)
    protected Map<String,PriceBookEntry> pricebookEntryMap;

    //Set<opportunityid+product2Id>
    protected Set<String> opportunitylineitemExistingSet;

    //<opportunityId+product2> we use the composite again to see if a pricebookEntry already exists for a particular opportunity
    protected Set<String> product2PricebookentrySet;

    // MultiCurrency Enabled Fields
    public static final Boolean IS_MULTICURRENCY_ORG = UserInfo.isMultiCurrencyOrganization();
    public static final String DEFAULT_CURRENCY_CODE = Userinfo.getDefaultCurrency();

    public OpportunityLineItemTriggerC() {}

    //public Opportunity_Product_Setting__c setting = Settings.OPPORTUNITY_PRODUCT_SETTING;
    //public Opportunity_Setting__c opportunitySetting = Settings.OPPORTUNITY_SETTING;
    public OpportunityLineItem[] opportunityLineItemOldList;
    public OpportunityLineItem[] opportunityLineItemNewList;

    public Map<Id, OpportunityLineItem> opportunityLineItemOldListMap = new Map<Id, OpportunityLineItem>();
    public Map<Id, OpportunityLineItem> opportunityLineItemNewListMap = new Map<Id, OpportunityLineItem>();

    public OpportunityLineItemTriggerC(OpportunityLineItem[] opportunityLineItemOldList, OpportunityLineItem[] opportunityLineItemNewList) {
        this.opportunityLineItemOldList = opportunityLineItemOldList == null ? new OpportunityLineItem[] {} : opportunityLineItemOldList;
        this.opportunityLineItemNewList = opportunityLineItemNewList == null ? new OpportunityLineItem[] {} : opportunityLineItemNewList;

        // Build the old map
        for(OpportunityLineItem opportunityLineItemOld : this.opportunityLineItemOldList) {
            if (opportunityLineItemOld.Id != null) {
                opportunityLineItemOldListMap.put(opportunityLineItemOld.Id, opportunityLineItemOld);
            }
        }

        // Build the new map
        for(OpportunityLineItem opportunityLineItemNew : this.opportunityLineItemNewList) {
            if (opportunityLineItemNew.Id != null) {
                opportunityLineItemNewListMap.put(opportunityLineItemNew.Id, opportunityLineItemNew);
            }
        }
     }

   /*
        map OpportunityLine item to its opportunity
    */
    protected Map<OpportunityLineItem,Opportunity> getOpportunityMap(List<OpportunityLineItem> opportunityLineItemNewList) {
        Map<OpportunityLineItem,Opportunity> opportunityMap = new Map<OpportunityLineItem,Opportunity>();
        Set<String> opportunityIdList = getFieldStringSet(opportunityLineItemNewList, OpportunityLineItem.OpportunityId);
        opportunityIdList.remove(null);

        List<String> queryFields = new List<String> { 'Pricebook2Id', 'CloseDate' };

        if (IS_MULTICURRENCY_ORG == true) {
            queryFields.add('CurrencyIsoCode');
        }

        String querySOQL = ''
            + 'SELECT ' + String.join(queryFields, ',')
            + '  FROM Opportunity'
            + ' WHERE Id IN :opportunityIdList'
            + ' ORDER BY CloseDate ASC';

        for(Opportunity opportunity : (Opportunity[]) Database.query(querySOQL)) {
            for(OpportunityLineItem opportunityLineItem : opportunityLineItemNewList) {
                if (opportunityLineItem.OpportunityId == opportunity.id) {
                    opportunityMap.put(opportunityLineItem,opportunity);
                }
            }
        }

        return opportunityMap;
    }

    protected Map<Id,List<rC_Giving__Package_Item__c>> getPackageItemMap(Map<OpportunityLineItem,Opportunity> opportunityMap,
        Map<Id,PricebookEntry> pricebookEntryMap,Set<Id> packageItemProductIds) {
        Map<Id, List<rC_Giving__Package_Item__c>> packageItemMap = new Map<Id,List<rC_Giving__Package_Item__c>>();
        Set<Id> opportunityLineItemPackageIds = new Set<Id> {};

        for(OpportunityLineItem opportunityLineItemNew : opportunityMap.keySet()) {

            String opportunityId = opportunityMap.get(opportunityLineItemNew).id;
            String product2Id = pricebookEntryMap.get(opportunityLineItemNew.OpportunityId) != null ? pricebookEntryMap.get(opportunityLineItemNew.OpportunityId).Product2Id : null;

            if (opportunityId == null || product2Id == null) {
                continue;
            }

            opportunityLineItemPackageIds.add(product2Id);
        }

            // Query optimizer
        opportunityLineItemPackageIds.remove(null);
		
        // Fetch Package/Item Relationships
        for(rC_Giving__Package_Item__c packageItem:[
            SELECT rC_Giving__Package__c
                 , rC_Giving__Item__c
                 , rC_Giving__Item__r.Name
              FROM rC_Giving__Package_Item__c
             WHERE rC_Giving__Package__c IN :opportunityLineItemPackageIds
        ]) {
            
            if (packageItem.rC_Giving__Package__c == null) {
                continue;
            }

            if (packageItemMap.containsKey(packageItem.rC_Giving__Package__c)) {
                packageItemMap.get(packageItem.rC_Giving__Package__c).add(packageItem);
            } else{
                packageItemMap.put(packageItem.rC_Giving__Package__c,new rC_Giving__Package_Item__c[]{packageItem});
            }

            if (packageItemProductIds != null) {
                packageItemProductIds.add(packageItem.rC_Giving__Item__c);
            }
            
        }

        return packageItemMap;
    }

    // map
    protected Map<Id,PricebookEntry> getPricebookEntryMap(List<OpportunityLineItem> opportunityLineItemNewList) {
        Map<Id,PricebookEntry> pricebookEntryMap = new Map<Id,PricebookEntry>();
        //Set<String> pricebookEntryIds = sobjectExtension.getFieldStringSet(opportunityLineItemNewList, OpportunityLineItem.PricebookEntryId);
        Map<String, OpportunityLineItem> pricebookEntryToLineItemMap = new Map<String, OpportunityLineItem>();
        for(OpportunityLineItem opportunityLineItem :opportunityLineItemNewList) {
            pricebookEntryToLineItemMap.put(opportunityLineItem.pricebookEntryId, opportunityLineItem);
        }
		
        for(PricebookEntry pbe : [
            SELECT Product2Id
                 , Product2.RecordTypeId
                 , Product2.Name
                 , Product2.rC_Giving__Delivery_Method__c
                 , Product2.rC_Giving__Start_Date__c
                 , Product2.rC_Giving__End_Date__c
                 , Product2.IsActive
                 , Pricebook2Id
                 , UnitPrice
              FROM PricebookEntry
             WHERE Id IN :pricebookEntryToLineItemMap.keySet()
        ]) {
            if (!pricebookEntryToLineItemMap.isEmpty() && pricebookEntryToLineItemMap.containsKey(pbe.Id)) {
                pricebookEntryMap.put(pricebookEntryToLineItemMap.get(pbe.Id).OpportunityId, pbe);
            }
        }
		
        return pricebookEntryMap;
    }

    /*
        gets all available pricebookEntries based upon the pricebooks associated with opportunities
    */
    protected Map<String,PriceBookEntry> getAllPricebookEntriesByPricebook(List<PriceBookEntry> priceBookEntryList,Set<Id> packageItemProductIds) {
        Map<String,PriceBookEntry> pricebookentryMap = new Map<String,PriceBookEntry>();
        //Set<String> pricebook2IdList = SobjectExtension.getFieldStringSet(priceBookEntryList, PriceBookEntry.Pricebook2Id);
        //pricebook2IdList.remove(null);

        Set<String> pricebook2IdList = new Set<String>();
        for (PriceBookEntry priceBookEntry :priceBookEntryList) {
            pricebook2IdList.add(priceBookEntry.Pricebook2Id);
        }
        System.debug('priceBookEntryList :: ' + priceBookEntryList);
        List<String> queryFields = new List<String> {
            'Product2Id',
            'Product2.RecordTypeId',
            'Product2.Name',
            'Product2.' + Product2.rC_Giving__Start_Date__c,
            'Product2.' + Product2.rC_Giving__End_Date__c,
            'Product2.IsActive',
            'Pricebook2Id',
            'UnitPrice'
        };

        if (IS_MULTICURRENCY_ORG == true) {
            queryFields.add('CurrencyIsoCode');
        }
        
        // check if there are items in package. if not then no need to query pricebookentries 
        if (packageItemProductIds == null 
            || (packageItemProductIds != null && packageItemProductIds.isEmpty() == true)) {
            return pricebookentryMap;
        }

        String querySOQL = ''
            + 'SELECT ' + String.join(queryFields, ',')
            + '  FROM PriceBookEntry'
            + ' WHERE Pricebook2Id = :pricebook2IdList'
            + '   AND Product2Id IN :packageItemProductIds';


		for(PriceBookEntry pbe : (PriceBookEntry[]) Database.query(querySOQL)) {
            if (pbe.pricebook2Id == null || pbe.product2Id == null) {
                continue;
            }
		
            String compositeKey = String.valueOf(pbe.pricebook2Id) + String.valueOf(pbe.product2Id);

            if (IS_MULTICURRENCY_ORG == true) {
                compositeKey += String.valueOf(pbe.get('CurrencyIsoCode'));
            }

            pricebookentryMap.put(compositeKey,pbe);
        }

        return pricebookentryMap;
    }

    public abstract Boolean getIsUpdateable(OpportunityLineItem opportunityLineItemOld, OpportunityLineItem opportunityLineItemNew);

    public virtual void execute() {
        
        OpportunityLineItem[] opportunityLineItemUpdateableList = new OpportunityLineItem[] {};

        for(OpportunityLineItem opportunityLineItemNew : opportunityLineItemNewList) {
            OpportunityLineItem opportunityLineItemOld = opportunityLineItemOldListMap.get(opportunityLineItemNew.Id);
            opportunityLineItemOld = opportunityLineItemOld == null ? new OpportunityLineItem() : opportunityLineItemOld;

            if (getIsUpdateable(opportunityLineItemOld, opportunityLineItemNew)) {
                opportunityLineItemUpdateableList.add(opportunityLineItemNew);
            }
        }


        if (opportunityLineItemUpdateableList.size() != 0) {
            execute(opportunityLineItemUpdateableList, trigger.IsAfter);
        }
    }

    public virtual void execute(OpportunityLineItem[] opportunityLineItemList, Boolean forceUpdate) {}
    
    public Set<String> getFieldStringSet(Sobject[] sobjectRefList, String sobjectField) {
		Set<String> fieldSet = new Set<String>();
		if (sobjectRefList != null && sobjectField != null) {
			for (Sobject sobjectRef : sobjectRefList) {
				fieldSet.add((String)sobjectRef.get(sobjectField));
			}
		}
		return fieldSet;
	}
    
    public static Set<String> getFieldStringSet(Sobject[] sobjectRefList, Schema.SobjectField sobjectField) {
		Set<String> fieldSet = new Set<String>();
		if (sobjectRefList != null && sobjectField != null) {
			for (Sobject sobjectRef : sobjectRefList) {
				fieldSet.add((String) sobjectRef.get(sobjectField));
			}
		}
		return fieldSet;
	}
}