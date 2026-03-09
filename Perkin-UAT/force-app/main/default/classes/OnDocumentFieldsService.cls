/**
 * Created by mgaska001 on 13.11.2025.
 */

public with sharing class OnDocumentFieldsService {

    private static List<IOnDocumentNode> quoteLineNodes = new List<IOnDocumentNode> {
        new OnDocumentCoverageDates(),
        new OnDocumentMaterial(),
        new OnDocumentIPI()
    };

    private static List<IOnDocumentQuoteNode> quoteNodes = new List<IOnDocumentQuoteNode> {
        new OnDocumentBillingCycle(),
        new OnDocumentPaymentTerms(),
        new OnDocumentQuoteType(),
        new OnDocumentTaxExempt(),
        new OnDocumentFreightTerms(),
        new OnDocumentQuoteDate(),
        new OnDocumentExpirationDate(),
        new OnDocumentContractStartDate(),
        new OnDocumentContractEndDate()
    };

    static Map<String, Map<String, String>> picklistToNameLabels = new Map<String, Map<String, String>>{
        'Billing_Cycle__c' => new Map<String, String> {
            '2 Yearly' => 'Quote_Billing_Cycle_2_Yearly',
            'Bi Annual' => 'Quote_Billing_Cycle_Bi_Annual',
            'Bi Annual First of Month' => 'Quote_Billing_Cycle_Bi_Annual_First',
            'Bi Annual Last of Month' => 'Quote_Billing_Cycle_Bi_Annual_Last',
            'Bi-Monthly' => 'Quote_Billing_Cycle_Bi_Monthly',
            'Every 4 months' => 'Quote_Billing_Cycle_Every_4_Months',
            'Fully upfront' => 'Quote_Billing_Cycle_Fully_Upfront',
            'Monthly' => 'Quote_Billing_Cycle_Monthly',
            'Monthly on First of Month' => 'Quote_Billing_Cycle_Monthly_First',
            'Monthly on Last of Month' => 'Quote_Billing_Cycle_Monthly_Last',
            'Quarterly' => 'Quote_Billing_Cycle_Quarterly',
            'Quarterly First of Month' => 'Quote_Billing_Cycle_Quarterly_First',
            'Quarterly Last of Month' => 'Quote_Billing_Cycle_Quarterly_Last',
            'Yearly' => 'Quote_Billing_Cycle_Yearly'
        },
        'Quote_Type__c' => new Map<String, String> {
            'Draft Quote' => 'Quote_Type_Draft',
            'Final Quote' => 'Quote_Type_Final',
            'Preliminary Quote' => 'Quote_Type_Preliminary'
        },
        'SBQQ__PaymentTerms__c' => new Map<String, String> {
            'Net 30 after Installation' => 'Quote_Payment_Terms_Net_30_After_Installation',
            'Net 30 from Invoice' => 'Quote_Payment_Terms_Net_30_From_Invoice',
            'Net 60 after Installation' => 'Quote_Payment_Terms_Net_60_After_Installation',
            'Net 60 from Invoice' => 'Quote_Payment_Terms_Net_60_From_Invoice',
            'Prepayment Required' => 'Quote_Payment_Terms_Prepayment_Required'
        },
        'Tax_Exempt__c' => new Map<String, String> {
            'Yes' => 'Quote_Tax_Exempt_Yes',
            'No' => 'Quote_Tax_Exempt_No'
        },
        'BD_Freight_Terms__c' => new Map<String, String> {
            '2nd Day' => 'Quote_Freight_Terms_2_Day',
            'Overnight' => 'Quote_Freight_Terms_Overnight',
            'Standard Ground' => 'Quote_Freight_Terms_Standard_Ground'
        }
    };

    /**
     * @description SC-584 Method for trigger handler on SBQQ__Quote__c after after update language to manage
     * on document formatted and translated optional details:
     * On_Document_Coverage_Dates, On_Document_IPI, On_Document_Material
     */
    public static void populateOnDocumentFieldsAfterLanguageChange(List<SBQQ__Quote__c> newList, Map<Id, SBQQ__Quote__c> oldMap) {
        Map<Id, SBQQ__Quote__c> processMap = new Map<Id, SBQQ__Quote__c>();

        for (SBQQ__Quote__c newQuote : newList) {
            SBQQ__Quote__c oldQuote = oldMap.get(newQuote.Id);
            if (newQuote.BD_Quote_Language__c != oldQuote.BD_Quote_Language__c) {
                processMap.put(newQuote.Id, newQuote);
            }
        }

        if (processMap.isEmpty()) {
            return;
        }

        // Query related SBQQ__QuoteLine__c records with fields necessary to format on document optional fields
        List<SBQQ__QuoteLine__c> recordsToUpdate = fetchQuoteLines(processMap.keySet());
        if (!recordsToUpdate.isEmpty()) {
            // Populate formatted fields
            populateOnDocumentFields(recordsToUpdate, processMap);
            update recordsToUpdate;
        }
    }

    /**
     * @description SC-584 Method for trigger handler on SBQQ__QuoteLine__c after insert or after update to manage
     * on document formatted and translated optional details:
     * On_Document_Coverage_Dates, On_Document_IPI, On_Document_Material
     */
    public static void populateOnDocumentFields(List<SBQQ__QuoteLine__c> newList, Map<Id, SBQQ__QuoteLine__c> oldMap) {
        Map<Id, SBQQ__QuoteLine__c> processMap = new Map<Id, SBQQ__QuoteLine__c>();
        Set<Id> quoteIds = new Set<Id>();

        collectProcessData(newList, oldMap, processMap, quoteIds);
        if (processMap.isEmpty()) {
            return;
        }

        // Query related SBQQ__Quote__c records with locale language Code
        Map<Id, SBQQ__Quote__c> quotes = fetchQuotes(quoteIds);

        // Populate formatted fields
        populateOnDocumentFields(processMap.values(), quotes);
    }

    /**
     * @description SC-584 Method to format and populate on document formatted and translated optional details:
     * On_Document_Coverage_Dates, On_Document_IPI, On_Document_Material
     */
    private static void populateOnDocumentFields(List<SBQQ__QuoteLine__c> quoteLines, Map<Id, SBQQ__Quote__c> quotes) {
        for (SBQQ__QuoteLine__c quoteLine : quoteLines) {
            String localeCode = quotes.get(quoteLine.SBQQ__Quote__c)?.BD_Quote_Language__c;
            for (IOnDocumentNode node : quoteLineNodes) {
                node.populate(quoteLine, localeCode);
            }
        }
    }

    /**
     * @description Helper method to:
     * Review SBQQ__QuoteLine__c changes to process only these that have impact on fields for quote templates
     * Collect all related SBQQ__Quote__c.Id and SBQQ__QuoteLine__c records to process
     */
    private static void collectProcessData(
        List<SBQQ__QuoteLine__c> newList,
        Map<Id, SBQQ__QuoteLine__c> oldMap,
        Map<Id, SBQQ__QuoteLine__c> processMap,
        Set<Id> quoteIds
    ) {
        for (SBQQ__QuoteLine__c newQuoteLine : newList) {
            Boolean processOld = false;
            Boolean processNew = false;
            SBQQ__QuoteLine__c oldQuoteLine = oldMap.get(newQuoteLine.Id);
            if (oldQuoteLine != null) {
                if (checkNotBlankFields(oldQuoteLine)) {
                    processOld = true;
                }
            }
            if (checkNotBlankFields(newQuoteLine)) {
                processNew = true;
            }
            if (processOld && processNew) {
                // Check if these are no changes
                if (checkNotChanged(newQuoteLine, oldQuoteLine)) {
                    processOld = processNew = false;
                }
            }
            if (processNew || processOld) {
                processMap.put(newQuoteLine.Id, newQuoteLine);
                if (processNew) {
                    quoteIds.add(newQuoteLine.SBQQ__Quote__c);
                }
            }
        }
    }

    /**
     * @description Helper method to check if fields related to on document data are not blank
     */
    private static Boolean checkNotBlankFields(SBQQ__QuoteLine__c newQuoteLine) {
        for (IOnDocumentNode node : quoteLineNodes) {
            if (!node.checkIsBlank(newQuoteLine)) {
                return true;
            }
        }
        return false;
    }

    /**
     * @description Helper method to check if any changes were done that require on document fields update
     */
    private static Boolean checkNotChanged(SBQQ__QuoteLine__c newQuoteLine, SBQQ__QuoteLine__c oldQuoteLine) {
        for (IOnDocumentNode node : quoteLineNodes) {
            if (node.checkIsChanged(newQuoteLine, oldQuoteLine)) {
                return false;
            }
        }
        return true;
    }

    /**
     * @description SC-709, SC-693, SC-638 Method for trigger handler on SBQQ__Quote__c after insert or after update to manage
     * on document formatted and translated fields:
     * Quote_Document_Billing_Cycle__c, Quote_Document_Payment_Terms__c, Quote_Document_Tax_Exempt__c, Quote_Document_Type__c
     */
    public static void populateOnDocumentQuoteFields(List<SBQQ__Quote__c> newList, Map<Id, SBQQ__Quote__c> oldMap) {
        Map<Id, SBQQ__Quote__c> processMap = new Map<Id, SBQQ__Quote__c>();

        collectQuoteProcessData(newList, oldMap, processMap);
        if (processMap.isEmpty()) {
            return;
        }

        // Populate formatted fields
        populateOnDocumentQuoteFields(processMap.values());
    }

    /**
     * @description SC-SC-709, SC-693, SC-638 Method to format and populate on document formatted and translated fields:
     * Quote_Document_Billing_Cycle__c, Quote_Document_Payment_Terms__c, Quote_Document_Tax_Exempt__c, Quote_Document_Type__c
     */
    private static void populateOnDocumentQuoteFields(List<SBQQ__Quote__c> quotes) {
        for (SBQQ__Quote__c quote : quotes) {
            String localeCode = quote.BD_Quote_Language__c;
            for (IOnDocumentQuoteNode node : quoteNodes) {
                node.populate(quote, localeCode);
            }
        }
    }

    /**
     * @description Helper method to:
     * Review SBQQ__Quote__c changes to process only these that have impact on fields for quote templates
     */
    private static void collectQuoteProcessData(
        List<SBQQ__Quote__c> newList,
        Map<Id, SBQQ__Quote__c> oldMap,
        Map<Id, SBQQ__Quote__c> processMap
    ) {
        for (SBQQ__Quote__c newQuote : newList) {
            Boolean processOld = false;
            Boolean processNew = false;
            SBQQ__Quote__c oldQuote = oldMap.get(newQuote.Id);
            if (oldQuote != null) {
                if (newQuote.BD_Quote_Language__c != oldQuote.BD_Quote_Language__c) {
                    processMap.put(newQuote.Id, newQuote);
                    continue;
                }
                if (checkNotBlankFields(oldQuote)) {
                    processOld = true;
                }
            }
            if (checkNotBlankFields(newQuote)) {
                processNew = true;
            }
            if (processOld && processNew) {
                // Check if these are no changes
                if (checkNotChanged(newQuote, oldQuote)) {
                    processOld = processNew = false;
                }
            }
            if (processNew || processOld) {
                processMap.put(newQuote.Id, newQuote);
            }
        }
    }

    /**
     * @description Helper method to check if fields related to on document data are not blank
     */
    private static Boolean checkNotBlankFields(SBQQ__Quote__c newQuote) {
        for (IOnDocumentQuoteNode node : quoteNodes) {
            if (!node.checkIsBlank(newQuote)) {
                return true;
            }
        }
        return false;
    }

    /**
     * @description Helper method to check if any changes were done that require on document fields update
     */
    private static Boolean checkNotChanged(SBQQ__Quote__c newQuote, SBQQ__Quote__c oldQuote) {
        for (IOnDocumentQuoteNode node : quoteNodes) {
            if (node.checkIsChanged(newQuote, oldQuote)) {
                return false;
            }
        }
        return true;
    }

    /**
     * @description Helper method to query SBQQ__Quote__c with BD_Quote_Language__c
     */
    private static Map<Id, SBQQ__Quote__c> fetchQuotes(Set<Id> quoteIds) {
        if (quoteIds.isEmpty()) {
            return new Map<Id, SBQQ__Quote__c>();
        }
        return new Map<Id, SBQQ__Quote__c>([
            SELECT Id, BD_Quote_Language__c
            FROM SBQQ__Quote__c
            WHERE Id IN :quoteIds
        ]);
    }

    /**
     * @description Helper method to query SBQQ__Quote__c with SalesType__c
     */
    private static List<SBQQ__QuoteLine__c> fetchQuoteLines(Set<Id> quoteIds) {
        if (quoteIds.isEmpty()) {
            return new List<SBQQ__QuoteLine__c>();
        }
        return new List<SBQQ__QuoteLine__c>([
            SELECT Id, SBQQ__Quote__c, SBQQ__Number__c, CurrencyIsoCode, ContractStartDate__c, ContractEndDate__c,
                Contract_Start_Date_Formatted__c, Contract_End_Date_Formatted__c,
                On_Document_Coverage_Dates__c, MaterialSerialNumber__c, On_Document_Material__c,
                Foreign_Import_Control_Code__c, IPI_Amount__c, IPI_Percentage__c, On_Document_IPI__c
            FROM SBQQ__QuoteLine__c
            WHERE SBQQ__Quote__c IN :quoteIds
            ORDER BY SBQQ__Quote__c, SBQQ__Number__c
        ]);
    }

    public virtual interface IOnDocumentNode {
        Boolean checkIsBlank(SBQQ__QuoteLine__c newQuoteLine);
        Boolean checkIsChanged(SBQQ__QuoteLine__c newQuoteLine, SBQQ__QuoteLine__c oldQuoteLine);
        void populate(SBQQ__QuoteLine__c newQuoteLine, String localeCode);
    }

    private class OnDocumentCoverageDates implements IOnDocumentNode {
        public Boolean checkIsBlank(SBQQ__QuoteLine__c newQuoteLine) {
            if (newQuoteLine.ContractStartDate__c == null && newQuoteLine.ContractEndDate__c == null) {
                return true;
            }
            return false;
        }

        public Boolean checkIsChanged(SBQQ__QuoteLine__c newQuoteLine, SBQQ__QuoteLine__c oldQuoteLine) {
            if (ChangeUtil.isDateChanged(oldQuoteLine.ContractStartDate__c, newQuoteLine.ContractStartDate__c)
                || ChangeUtil.isDateChanged(oldQuoteLine.ContractEndDate__c, newQuoteLine.ContractEndDate__c)) {
                return true;
            }
            return false;
        }

        public void populate(SBQQ__QuoteLine__c newQuoteLine, String localeCode) {
            newQuoteLine.Contract_Start_Date_Formatted__c = FormatDateInLanguage.formatDate(newQuoteLine.ContractStartDate__c, localeCode);
            newQuoteLine.Contract_End_Date_Formatted__c = FormatDateInLanguage.formatDate(newQuoteLine.ContractEndDate__c, localeCode);
            String coverage = null;
            if (!checkIsBlank(newQuoteLine)) {
                String label = LocaleLabelUtil.getLabel('On_Document_Coverage_Dates', localeCode);
                if (String.isNotBlank(label)) {
                    String startDate = String.isNotBlank(newQuoteLine.Contract_Start_Date_Formatted__c) ? newQuoteLine.Contract_Start_Date_Formatted__c : '-';
                    String endDate = String.isNotBlank(newQuoteLine.Contract_End_Date_Formatted__c) ? newQuoteLine.Contract_End_Date_Formatted__c : '-';
                    coverage = String.format(label, new List<String>{startDate, endDate});
                }
            }
            newQuoteLine.On_Document_Coverage_Dates__c = coverage;
        }
    }

    private class OnDocumentMaterial implements IOnDocumentNode {
        public Boolean checkIsBlank(SBQQ__QuoteLine__c newQuoteLine) {
            return String.isBlank(newQuoteLine.MaterialSerialNumber__c);
        }

        public Boolean checkIsChanged(SBQQ__QuoteLine__c newQuoteLine, SBQQ__QuoteLine__c oldQuoteLine) {
            return ChangeUtil.isTextChanged(oldQuoteLine.MaterialSerialNumber__c, newQuoteLine.MaterialSerialNumber__c);
        }

        public void populate(SBQQ__QuoteLine__c newQuoteLine, String localeCode) {
            String material = null;
            if (!checkIsBlank(newQuoteLine)) {
                String label = LocaleLabelUtil.getLabel('On_Document_Material', localeCode);
                if (String.isNotBlank(label)) {
                    material = String.format(label, new List<String>{newQuoteLine.MaterialSerialNumber__c});
                }
            }
            newQuoteLine.On_Document_Material__c = material;
        }
    }

    private class OnDocumentIPI implements IOnDocumentNode {
        public Boolean checkIsBlank(SBQQ__QuoteLine__c newQuoteLine) {
            if (String.isBlank(newQuoteLine.Foreign_Import_Control_Code__c)
                && newQuoteLine.IPI_Amount__c == null
                && newQuoteLine.IPI_Percentage__c == null
            ) {
                return true;
            }
            return false;
        }

        public Boolean checkIsChanged(SBQQ__QuoteLine__c newQuoteLine, SBQQ__QuoteLine__c oldQuoteLine) {
            if (ChangeUtil.isTextChanged(oldQuoteLine.Foreign_Import_Control_Code__c, newQuoteLine.Foreign_Import_Control_Code__c)
                || ChangeUtil.isPriceChanged(oldQuoteLine.IPI_Amount__c, newQuoteLine.IPI_Amount__c)
                || ChangeUtil.isPriceChanged(oldQuoteLine.IPI_Percentage__c, newQuoteLine.IPI_Percentage__c)
            ) {
                return true;
            }
            return false;
        }

        public void populate(SBQQ__QuoteLine__c newQuoteLine, String localeCode) {
            String ipi = null;
            if (!checkIsBlank(newQuoteLine)) {
                String label = LocaleLabelUtil.getLabel('On_Document_IPI', localeCode);
                if (String.isNotBlank(label)) {
                    String code = String.isNotBlank(newQuoteLine.Foreign_Import_Control_Code__c) ? newQuoteLine.Foreign_Import_Control_Code__c : '-';
                    String iso = newQuoteLine.CurrencyIsoCode;
                    String amount = (newQuoteLine.IPI_Amount__c != null) ? String.valueOf(newQuoteLine.IPI_Amount__c) : '-';
                    String percent = (newQuoteLine.IPI_Percentage__c != null) ? String.valueOf(newQuoteLine.IPI_Percentage__c) : '-';
                    ipi = String.format(label, new List<String>{code, iso, amount, percent});
                }
            }
            newQuoteLine.On_Document_IPI__c = ipi;
        }
    }

    public virtual interface IOnDocumentQuoteNode {
        Boolean checkIsBlank(SBQQ__Quote__c newQuote);
        Boolean checkIsChanged(SBQQ__Quote__c newQuote, SBQQ__Quote__c oldQuote);
        void populate(SBQQ__Quote__c newQuote, String localeCode);
    }

    private class OnDocumentPaymentTerms implements IOnDocumentQuoteNode {
        public Boolean checkIsBlank(SBQQ__Quote__c newQuote) {
            return (String.isBlank(newQuote.SBQQ__PaymentTerms__c)
                && String.isBlank(newQuote.Customer_Default_Payment_Terms__c)
                && String.isBlank(newQuote.Custom_Payment_Terms__c)
            );
        }

        public Boolean checkIsChanged(SBQQ__Quote__c newQuote, SBQQ__Quote__c oldQuote) {
            return (ChangeUtil.isTextChanged(oldQuote.SBQQ__PaymentTerms__c, newQuote.SBQQ__PaymentTerms__c)
                || ChangeUtil.isTextChanged(oldQuote.Customer_Default_Payment_Terms__c, newQuote.Customer_Default_Payment_Terms__c)
                || ChangeUtil.isTextChanged(oldQuote.Custom_Payment_Terms__c, newQuote.Custom_Payment_Terms__c)
            );
        }

        public void populate(SBQQ__Quote__c newQuote, String localeCode) {
            String paymentTerms = null;
            if (!checkIsBlank(newQuote)) {
                if (newQuote.SBQQ__PaymentTerms__c == 'Use Customer Default') {
                    paymentTerms = newQuote.Customer_Default_Payment_Terms__c;
                } else if (newQuote.SBQQ__PaymentTerms__c == 'Custom Payment Terms') {
                    paymentTerms = newQuote.Custom_Payment_Terms__c;
                } else {
                    paymentTerms = newQuote.SBQQ__PaymentTerms__c;
                    String nameLabel = picklistToNameLabels.get('SBQQ__PaymentTerms__c').get(newQuote.SBQQ__PaymentTerms__c);
                    if (String.isNotBlank(nameLabel)) {
                        String label = LocaleLabelUtil.getLabel(nameLabel, localeCode);
                        if (String.isNotBlank(label)) {
                            paymentTerms = label;
                        }
                    }
                }
            }
            newQuote.Quote_Document_Payment_Terms__c = paymentTerms;
        }
    }

    private class OnDocumentBillingCycle extends OnDocumentSimpleNode {
        public OnDocumentBillingCycle() {
            super('Billing_Cycle__c', 'Quote_Document_Billing_Cycle__c');
        }
    }

    private class OnDocumentQuoteType extends OnDocumentSimpleNode {
        public OnDocumentQuoteType() {
            super('Quote_Type__c', 'Quote_Document_Type__c');
        }
    }

    private class OnDocumentTaxExempt extends OnDocumentSimpleNode {
        public OnDocumentTaxExempt() {
            super('Tax_Exempt__c', 'Quote_Document_Tax_Exempt__c');
        }
    }

    private class OnDocumentFreightTerms extends OnDocumentSimpleNode {
        public OnDocumentFreightTerms() {
            super('BD_Freight_Terms__c', 'Quote_Document_Freight_Terms__c');
        }
    }

    private virtual class OnDocumentSimpleNode implements IOnDocumentQuoteNode {
        String sourceFieldName;
        String targetFieldName;

        public OnDocumentSimpleNode(String source, String target) {
            this.sourceFieldName = source;
            this.targetFieldName = target;
        }

        public Boolean checkIsBlank(SBQQ__Quote__c newQuote) {
            String newValue = (String)newQuote.get(sourceFieldName);
            return String.isBlank(newValue);
        }

        public Boolean checkIsChanged(SBQQ__Quote__c newQuote, SBQQ__Quote__c oldQuote) {
            String newValue = (String)newQuote.get(sourceFieldName);
            String oldValue = (String)oldQuote.get(sourceFieldName);
            return ChangeUtil.isTextChanged(oldValue, newValue);
        }

        public void populate(SBQQ__Quote__c newQuote, String localeCode) {
            String value = null;
            if (!checkIsBlank(newQuote)) {
                value = (String)newQuote.get(sourceFieldName);
                String nameLabel = picklistToNameLabels.get(sourceFieldName).get(value);
                if (String.isNotBlank(nameLabel)) {
                    String label = LocaleLabelUtil.getLabel(nameLabel, localeCode);
                    if (String.isNotBlank(label)) {
                        value = label;
                    }
                }
            }
            newQuote.put(targetFieldName, value);
        }
    }

    private virtual class OnDocumentDateNode implements IOnDocumentQuoteNode {
        String sourceDateFieldName;
        String formattedDateFieldName;

        public OnDocumentDateNode(String source, String formatted) {
            this.sourceDateFieldName = source;
            this.formattedDateFieldName = formatted;
        }

        public Boolean checkIsBlank(SBQQ__Quote__c newQuote) {
            if (sourceDateFieldName == 'CreatedDate') {
                return false;
            }
            Date newValue = (Date)newQuote.get(sourceDateFieldName);
            return (newValue != null);
        }

        public Boolean checkIsChanged(SBQQ__Quote__c newQuote, SBQQ__Quote__c oldQuote) {
            if (sourceDateFieldName == 'CreatedDate') {
                return false;
            }
            Date newValue = (Date)newQuote.get(sourceDateFieldName);
            Date oldValue = (Date)oldQuote.get(sourceDateFieldName);
            return ChangeUtil.isDateChanged(oldValue, newValue);
        }

        public void populate(SBQQ__Quote__c newQuote, String localeCode) {
            Date newValue;
            if (sourceDateFieldName == 'CreatedDate') {
                Datetime newTimeValue = (Datetime)newQuote.get(sourceDateFieldName);
                newValue = newTimeValue.date();
            } else {
                newValue = (Date)newQuote.get(sourceDateFieldName);
            }
            String value = FormatDateInLanguage.formatDate(newValue, localeCode);
            newQuote.put(formattedDateFieldName, value);
        }
    }

    private class OnDocumentQuoteDate extends OnDocumentDateNode {
        public OnDocumentQuoteDate() {
            super('CreatedDate', 'Quote_Date_Formatted__c');
        }
    }

    private class OnDocumentExpirationDate extends OnDocumentDateNode {
        public OnDocumentExpirationDate() {
            super('SBQQ__ExpirationDate__c', 'Expiration_Date_Formatted__c');
        }
    }

    private class OnDocumentContractStartDate extends OnDocumentDateNode {
        public OnDocumentContractStartDate() {
            super('ContractStartDate__c', 'Contract_Start_Date_Formatted__c');
        }
    }

    private class OnDocumentContractEndDate extends OnDocumentDateNode {
        public OnDocumentContractEndDate() {
            super('ContractEndDate__c', 'Contract_End_Date_Formatted__c');
        }
    }

}