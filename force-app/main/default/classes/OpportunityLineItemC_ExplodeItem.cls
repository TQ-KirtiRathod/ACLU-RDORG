public without sharing class OpportunityLineItemC_ExplodeItem extends OpportunityLineItemTriggerC {

    public OpportunityLineItemC_ExplodeItem(OpportunityLineItem[] opportunityLineItemOldList, OpportunityLineItem[] opportunityLineItemNewList) {
        super(opportunityLineItemOldList, opportunityLineItemNewList);
    }

    public override Boolean getIsUpdateable(OpportunityLineItem opportunityLineItemOld, OpportunityLineItem opportunityLineItemNew) {
		/*if (setting.Disable_ExplodeItems__c == true) {
            return false;
        }*/
        
        if (opportunityLineItemNew.PriceBookEntryId == null) {
            return false;
        }

        return true;
    }

    public override void execute(OpportunityLineItem[] opportunityLineItemList, Boolean forceUpdate) {

        //opportunityLineItemId => PricebookEntry
        Map<Id,PricebookEntry> pricebookEntryMap = getPricebookEntryMap(opportunityLineItemList);

        //get eligible opportunityLineItems
        OpportunityLineItem[] opportunityEligibleList = new OpportunityLineItem[]{};

        for (OpportunityLineItem opportunityLineItem : opportunityLineItemList) {
            PricebookEntry relatedPricebookEntry = (pricebookEntryMap.containsKey(opportunityLineItem.OpportunityId))?pricebookEntryMap.get(opportunityLineItem.OpportunityId):null;

            if (relatedPricebookEntry != null && relatedPricebookEntry.Product2 != null && relatedPricebookEntry.Product2.RecordTypeId == PRODUCT2_RECORD_TYPE_ID_PACKAGE) {
                opportunityEligibleList.add(opportunityLineItem);
            }
        }

        //check if there are any eligible opportunityLineItem related to package
        if (opportunityEligibleList.size() == 0) {
            return;
        }

        //OpportunityLineItemId => Opportunity
        Map<OpportunityLineItem,Opportunity> opportunityMap = getOpportunityMap(opportunityEligibleList);

        //get list of all product assignments for this package from custom M2M object Package_Item__c
        //Package Product2Id => Package_Item__c
        Set<Id> packageItemProductIds = new Set<Id>();
        Map<Id,List<rC_Giving__Package_Item__c>> packageItemMap = getPackageItemMap(opportunityMap,pricebookEntryMap,packageItemProductIds);

        //Check if there are packged item present related to package
        if (packageItemProductIds.size() == 0) {
            return;
        }

        //All PBE by pricebook, pricebook2Id+product2Id => PriceBookEntry
        Map<String,PriceBookEntry> compositePricebookEntryMap = getAllPricebookEntriesByPricebook(pricebookEntryMap.values(),packageItemProductIds);

        //Set up for Discount Product
        Map<ID,PricebookEntry [] > productIdPricebookEntryListMap = getDiscountProductPriceBookEntriesMap();
        Set<String> priceBookIds;
        Map<ID,PricebookEntry[] > priceBookIdPricebookEntryMap = new Map<ID,PricebookEntry[]>();

        if (productIdPricebookEntryListMap.size() == 1) {
           for (ID productId : productIdPricebookEntryListMap.keySet()) {
               PricebookEntry [] priceBookEntryList = productIdPricebookEntryListMap.get(productId);
               priceBookIds = getFieldStringSet(priceBookEntryList, PriceBookEntry.Pricebook2Id);

               for(PricebookEntry priceBookEntry : priceBookEntryList) {
                   if (priceBookIdPricebookEntryMap.containskey(priceBookEntry.PriceBook2Id) == false)
                       priceBookIdPricebookEntryMap.put(priceBookEntry.PriceBook2Id,new PricebookEntry[]{priceBookEntry});
                   else
                       priceBookIdPricebookEntryMap.get(priceBookEntry.PriceBook2Id).add(priceBookEntry);
               }
           }
        }

        //items to insert
        List<OpportunityLineItem> newOpportunityListItems = new List<OpportunityLineItem>();

        for(OpportunityLineItem opportunityLineItem:opportunityEligibleList) {
            Opportunity relatedOpportunity = (opportunityMap.containsKey(opportunityLineItem))?opportunityMap.get(opportunityLineItem):null;
            PricebookEntry relatedPricebookEntry = (pricebookEntryMap.containsKey(opportunityLineItem.OpportunityId))?pricebookEntryMap.get(opportunityLineItem.OpportunityId):null;

            if (relatedOpportunity == null) {
                continue;
            }

            if (relatedPricebookEntry == null) {
                continue;
            }

            if (relatedOpportunity.CloseDate != null
            && ((relatedPricebookEntry.Product2.rC_Giving__Start_Date__c != null && relatedPricebookEntry.Product2.rC_Giving__Start_Date__c > relatedOpportunity.CloseDate)
            || (relatedPricebookEntry.Product2.rC_Giving__End_Date__c != null && relatedPricebookEntry.Product2.rC_Giving__End_Date__c < relatedOpportunity.CloseDate))) {
                continue;
            }

            //there must be items related to the provided package
            if (packageItemMap.containsKey(relatedPricebookEntry.Product2Id) == false) {
                opportunityLineItem.addError('Package has no mapped items');
                continue;
            }

            List<rC_Giving__Package_Item__c> relatedItems = packageItemMap.get(relatedPricebookEntry.Product2Id);
            Decimal discountUnitPrice = relatedPricebookEntry.UnitPrice;

            for(Integer i=0;i<relatedItems.size();++i) {
                rC_Giving__Package_Item__c item = relatedItems.get(i);
                String pricebookCompositeKey = String.valueOf(relatedPricebookEntry.Pricebook2Id)
                                + String.valueOf(item.rC_Giving__Item__c);
                
                if (IS_MULTICURRENCY_ORG == true) {
                    pricebookCompositeKey += String.valueOf(relatedOpportunity.get('CurrencyIsoCode'));
                }
                
                //confirm pricing is availalble for item
                if (compositePricebookEntryMap.containsKey(pricebookCompositeKey) == false) {
                   continue;
                }

                PriceBookEntry itemPricebookEntry = compositePricebookEntryMap.get(pricebookCompositeKey);
                Decimal totalPrice = itemPricebookEntry.UnitPrice * opportunityLineItem.Quantity;
                discountUnitPrice = discountUnitPrice - itemPricebookEntry.UnitPrice;

                if (relatedOpportunity.CloseDate != null
	                && ((itemPricebookEntry.Product2.rC_Giving__Start_Date__c != null && itemPricebookEntry.Product2.rC_Giving__Start_Date__c > relatedOpportunity.CloseDate)
    	            || (itemPricebookEntry.Product2.rC_Giving__End_Date__c != null && itemPricebookEntry.Product2.rC_Giving__End_Date__c < relatedOpportunity.CloseDate))) {
                    opportunityLineItem.addError('Close Date should be between Start and End Date');
                    return;
                }

                if (itemPricebookEntry.Product2.IsActive == false) {
                    opportunityLineItem.addError('Cannot add Item or Package because it is not Active.');
                    return;
                }

                if (i == 0) {
                    opportunityLineItem.rC_Giving__Package_Name__c = relatedPriceBookEntry.Product2.Name;
                    opportunityLineItem.priceBookEntryId = itemPricebookEntry.id;
                    opportunityLineItem.OpportunityId = relatedOpportunity.id;
                    opportunityLineItem.Quantity = opportunityLineItem.Quantity;
                    opportunityLineItem.UnitPrice = itemPricebookEntry.UnitPrice;
                } else {
                    OpportunityLineItem subItem = new OpportunityLineItem(
                        rC_Giving__Package_Name__c = relatedPriceBookEntry.Product2.Name,
                        priceBookEntryId = itemPricebookEntry.id,
                        OpportunityId = relatedOpportunity.id,
                        Quantity = opportunityLineItem.Quantity,
                        TotalPrice = totalPrice,
                        rC_Giving__Package__c = relatedPriceBookEntry.Product2Id);
                        subItem.rC_Giving__Delivery_Status__c = opportunityLineItem.rC_Giving__Delivery_Status__c;
                        subItem.rC_Giving__Delivery_Method__c = opportunityLineItem.rC_Giving__Delivery_Method__c;
                        subItem.rC_Giving__Beneficiary__c = opportunityLineItem.rC_Giving__Beneficiary__c;
                    newOpportunityListItems.add(subItem);
                }

            }
			rC_Giving__Opportunity_Setting__c opportunitySetting = rC_Giving__Opportunity_Setting__c.getInstance();
            if (discountUnitPrice < 0) {
                //Boolean showErrorMessage = false;
                if (showErrorMessage == false  && opportunitySetting.rC_Giving__Package_Discount_Item__c  == null || opportunitySetting.rC_Giving__Package_Discount_Item__c == '') {
                    showErrorMessage = true;
                }

                if (showErrorMessage == false && productIdPricebookEntryListMap.isEmpty() == true) {
                    showErrorMessage = true;
                }

                if (showErrorMessage == false && productIdPricebookEntryListMap.keySet().size() > 1 ) {
                    showErrorMessage = true;
                }

                if (showErrorMessage == false && priceBookIds != null && priceBookIds.contains(relatedPricebookEntry.PriceBook2Id) == false) {
                   showErrorMessage = true;
                }

                if (showErrorMessage == false ) {
                    PricebookEntry[] priceBookEntryList = priceBookIdPricebookEntryMap.get(relatedPricebookEntry.PriceBook2Id);
                    PricebookEntry priceBookEntry = priceBookEntryList.isEmpty() == false ? priceBookEntryList[0]: null;

                    OpportunityLineItem discountItem = new OpportunityLineItem();
                    discountItem.rC_Giving__Package_Name__c = relatedPriceBookEntry.Product2.Name;
                    discountItem.priceBookEntryId = priceBookEntry.id;
                    discountItem.OpportunityId = relatedOpportunity.id;
                    discountItem.Quantity = opportunityLineItem.Quantity;
                    discountItem.UnitPrice = discountUnitPrice;
                    discountItem.rC_Giving__Package__c = relatedPriceBookEntry.Product2Id;
                    newOpportunityListItems.add(discountItem);
                }
            }
        }

        if (newOpportunityListItems.size() != 0) {
			insert newOpportunityListItems;
        }
    }

    public Map<ID, PricebookEntry []> getDiscountProductPriceBookEntriesMap() {
        Map<ID,PricebookEntry [] > productIdPricebookEntryListMap = new Map<ID,PricebookEntry [] >();
		rC_Giving__Opportunity_Setting__c opportunitySetting = rC_Giving__Opportunity_Setting__c.getInstance();
        
        if (opportunitySetting.rC_Giving__Package_Discount_Item__c != null && opportunitySetting.rC_Giving__Package_Discount_Item__c !='') {
            String discountItem = opportunitySetting.rC_Giving__Package_Discount_Item__c;
            String pricebookEntryQuery = ''
                + 'SELECT UnitPrice'
                + '     , Product2Id'
                + '     , Pricebook2Id';

                if (IS_MULTICURRENCY_ORG == true) {
                    pricebookEntryQuery += '     , CurrencyIsoCode';
                }

                pricebookEntryQuery += '  FROM PricebookEntry'
                					+ ' WHERE Product2Id IN (SELECT Id FROM Product2 WHERE Name =:discountItem) ';

            for (PricebookEntry priceBookEntry : (PricebookEntry[]) Database.query(pricebookEntryQuery)) {
                if (productIdPricebookEntryListMap.get(priceBookEntry.Product2Id) == null) {
                    productIdPricebookEntryListMap.put(priceBookEntry.Product2Id,new PricebookEntry[]{});
                }

                productIdPricebookEntryListMap.get(priceBookEntry.Product2Id).add(priceBookEntry);
            }
        }

        return productIdPricebookEntryListMap;
    }

	
}