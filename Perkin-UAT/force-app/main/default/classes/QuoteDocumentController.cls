/**
 * Created by mgaska001 on 20.11.2025.
 */

public with sharing class QuoteDocumentController {

    private static final String SECTION_HEADER = 'Header';
    private static final String SECTION_EXECUTIVE_SUMMARY = 'Executive_Summary';
    private static final String SECTION_QUOTE = 'Quote';
    private static final String SECTION_QUOTE_HIGHLIGHTS = 'Quote_Highlights';
    private static final String SECTION_MARKETING_COLLATERAL = 'Marketing_Collateral';
    private static final String SECTION_INCLUDED_PARTS = 'Included_Parts';
    private static final String SECTION_FINANCING_LEASING = 'Financing_Leasing';

    private static final String TEMPLATE_HEADER = 'Quote - Header';
    private static final String TEMPLATE_EXECUTIVE_SUMMARY = 'Quote - Executive Summary';
    private static final String TEMPLATE_QUOTE_MAIN = 'Quote - Main';
    private static final String TEMPLATE_PRODUCT_DETAILS = 'Quote - Product Details';
    private static final String TEMPLATE_PRODUCT_LITERATURE = 'Quote - Product Literature';
    private static final String TEMPLATE_INCLUDED_PARTS = 'Quote - Included Parts';
    private static final String TEMPLATE_FINANCING_OPTIONS = 'Quote - Financing Options';

    // The main Quote section is the first on the list.
    // It will be the one that we will link generated document to, so the lowest SBQQ__QuoteDocument__c.SBQQ__Version__c will be used then without gaps
    private static final Map<String, String> sectionTemplates = new Map<String, String>{
        SECTION_QUOTE => TEMPLATE_QUOTE_MAIN,
        SECTION_HEADER => TEMPLATE_HEADER,
        SECTION_EXECUTIVE_SUMMARY => TEMPLATE_EXECUTIVE_SUMMARY,
        SECTION_QUOTE_HIGHLIGHTS => TEMPLATE_PRODUCT_DETAILS,
        SECTION_MARKETING_COLLATERAL => TEMPLATE_PRODUCT_LITERATURE,
        SECTION_INCLUDED_PARTS => TEMPLATE_INCLUDED_PARTS,
        SECTION_FINANCING_LEASING => TEMPLATE_FINANCING_OPTIONS
    };

    private static final Map<String, String> sectionFields = new Map<String, String>{
        SECTION_QUOTE => 'Quote_Page__c',
        SECTION_HEADER => 'Header_Page__c',
        SECTION_EXECUTIVE_SUMMARY => 'Executive_Summary_Page__c',
        SECTION_QUOTE_HIGHLIGHTS => 'Quote_Highlights_Page__c',
        SECTION_MARKETING_COLLATERAL => 'Marketing_Collateral_Page__c',
        SECTION_INCLUDED_PARTS => 'Included_Parts_Page__c',
        SECTION_FINANCING_LEASING => 'Financing_Leasing_Page__c'
    };

    private static final Map<String, String> sectionSuffix = new Map<String, String>{
        SECTION_QUOTE => '-03',
        SECTION_HEADER => '-01',
        SECTION_EXECUTIVE_SUMMARY => '-02',
        SECTION_QUOTE_HIGHLIGHTS => '-04',
        SECTION_MARKETING_COLLATERAL => '-05',
        SECTION_INCLUDED_PARTS => '-06',
        SECTION_FINANCING_LEASING => '-07'
    };

    private static final Map<String, String> languageSuffix = new Map<String, String>{
        'ja' => ' - JP',
        'ko' => ' - KR',
        'th' => ' - TH',
        'zh_CN' => ' - CN',
        'zh_TW' => ' - ZW'
    };

    /**
     * @description SC-459 Method to get SBQQ__Quote__c record language and sections selected
     * and return list of section parameters to generate sections as separate SBQQ__QuoteDocument__c and Document records
     * @param quoteId : Salesforce SBQQ__Quote__c.Id
     * @param documentName : Unique merged document name. This is a common prefix to gather all generated document sections.
     * return : List of QuoteDocumentParams - first should be main Quote section to be generated first
     */
    @AuraEnabled
    public static String prepareSections(Id quoteId, String documentName) {
        List<QuoteDocumentParams> sectionParams = new List<QuoteDocumentParams>();
        Map<String, String> templates = fetchTemplates();

        // query selected pages to generated Quote Document
        SBQQ__Quote__c quote = fetchQuote(quoteId);

        for (String section : sectionTemplates.keySet()) {
            String fieldName = sectionFields.get(section);
            Boolean checkSelected = (Boolean)quote.get(fieldName);
            if (!checkSelected) {
                continue;
            }
            String fileName = documentName + sectionSuffix.get(section) + '.pdf';
            String language = quote.BD_Quote_Language__c;
            String templateName = sectionTemplates.get(section);
            String suffix = languageSuffix.get(language);
            if (String.isNotBlank(suffix)) {
                templateName += suffix;
            } else if (quote.Is_Brazil_Entity__c) {
                templateName += ' - BR';
            }
            String templateId = templates.get(templateName);
            QuoteDocumentParams params = new QuoteDocumentParams();
            params.quoteId = quoteId;
            params.templateId = templateId;
            params.fileName = fileName;
            params.language = language;
            sectionParams.add(params);
        }

        return JSON.serialize(sectionParams);
    }

    /**
     * @description SC-459 Method to check status of job generating Quote document, the status has to be pooled
     * because there is not notification about Quote document generation status in CPQ.
     * @param jobId : Job Id
     * return : Status of queried AsyncApexJob record
     */
    @AuraEnabled
    public static String checkJobStatus(String jobId) {
        return fetchJobStatus(jobId);
    }

    /**
     * @description SC-459 Method to generate Quote document.
     * @param quoteId : Salesforce SBQQ__Quote__c.Id
     * @param templateId : Salesforce SBQQ__QuoteTemplate__c.Id
     * @param fileName : Unique file name for Quote document
     * @param language : Language code
     * return : AsyncApexJob.Id - be aware that jobId returned from SBQQ.ServiceRouter is an Id enclosed with quotation, get rid of it !!
     */
    @AuraEnabled
    public static String saveSection(String quoteId, String templateId, String fileName, String language) {
        // QuoteProposalModel is not installed with CPQ ?!
        JSONGenerator gen = JSON.createGenerator(true);
        gen.writeStartObject();
        gen.writeStringField('quoteId', quoteId);
        gen.writeStringField('templateId', templateId);
        gen.writeStringField('name', fileName);
        gen.writeStringField('language', language);
        gen.writeEndObject();
        String pretty = gen.getAsString();

        if (Test.isRunningTest())
        {
            AsyncApexJob job = [SELECT Id, Status FROM AsyncApexJob WHERE Status = 'Completed' LIMIT 1];
            return job.Id;
        } else {
            String jobId = SBQQ.ServiceRouter.save('SBQQ.QuoteDocumentAPI.Save', pretty);
            // jobId returned from SBQQ.ServiceRouter is an Id enclosed with quotation, get rid of it !!
            return jobId.replace('"', '');
        }
    }

    /**
     * @description SC-459 Method to get list of SBQQ__QuoteDocument__c.SBQQ__DocumentId__c for Quoet document records.
     * These are documents generated by CPQ SBQQ.ServiceRouter
     * @param quoteId : Salesforce SBQQ__Quote__c.Id
     * @param documentName : Unique merged document name. This is a common prefix to gather all generated document sections.
     * return : List of SBQQ__QuoteDocument__c.SBQQ__DocumentId__c
     */
    @AuraEnabled
    public static List<String> getSectionIds(Id quoteId, String documentName) {
        List<String> documentIds = new List<String>();
        List<SBQQ__QuoteDocument__c> quoteDocuments = fetchQuoteDocuments(quoteId, documentName);
        for (SBQQ__QuoteDocument__c quoteDocument : quoteDocuments) {
            if (String.isNotBlank(quoteDocument.SBQQ__DocumentId__c)) {
                documentIds.add(quoteDocument.SBQQ__DocumentId__c);
            }
        }
        return documentIds;
    }

    /**
     * @description SC-459 Method to delete all SBQQ__QuoteDocument__c and Document records that are temporarily
     * generated Quote documents. This method is used in Preview mode.
     * @param quoteId : Salesforce SBQQ__Quote__c.Id
     * @param documentName : Unique merged document name. This is a common prefix to gather all generated document sections.
     */
    @AuraEnabled
    public static void deleteSections(Id quoteId, String documentName) {
        // Reuse method for Generate mode. Pass blank final documentId.
        linkMergedAndDeleteSections(quoteId, documentName, null, null);
    }

    /**
     * @description SC-459 Method to delete all SBQQ__QuoteDocument__c and Document records that are temporarily
     * generated Quote documents. Exclude from delete first SBQQ__QuoteDocument__c record, that will be a link
     * to the merged final document. This method is used in Generate mode.
     * @param quoteId : Salesforce SBQQ__Quote__c.Id
     * @param documentName : Unique merged document name. This is a common prefix to gather all generated document sections.
     */
    @AuraEnabled
    public static SBQQ__QuoteDocument__c linkMergedAndDeleteSections(Id quoteId, String documentName, Id documentId, String mergedDocumentName) {
        List<SBQQ__QuoteDocument__c> quoteDocuments = fetchQuoteDocuments(quoteId, documentName);
        if (quoteDocuments.isEmpty()) {
            return null;
        }

        // All temporary generated Document records with section content has to be deleted
        List<Document> documents = new List<Document>();
        for (SBQQ__QuoteDocument__c quoteDocument : quoteDocuments) {
            if (String.isNotBlank(quoteDocument.SBQQ__DocumentId__c)) {
                documents.add(new Document(
                    Id = quoteDocument.SBQQ__DocumentId__c
                ));
            }
        }

        SBQQ__QuoteDocument__c mainDocument = null;
        if (String.isNotBlank(documentId)) {
            // Exclude from delete first SBQQ__QuoteDocument__c record, that will be a link to the merged final document
            mainDocument = quoteDocuments.remove(0);
            mainDocument.Name = mergedDocumentName;
            mainDocument.SBQQ__DocumentId__c = documentId;
            update mainDocument;
        }

        if (!documents.isEmpty()) {
            delete documents;
        }
        if (!quoteDocuments.isEmpty()) {
            delete quoteDocuments;
        }

        return mainDocument;
    }

    private static SBQQ__Quote__c fetchQuote(Id quoteId) {
        List<SBQQ__Quote__c> quotes = [
            SELECT Id, Name, BD_Quote_Language__c, Is_Brazil_Entity__c,
                Header_Page__c, Executive_Summary_Page__c, Quote_Highlights_Page__c,
                Quote_Page__c, Included_Parts_Page__c, Marketing_Collateral_Page__c, Financing_Leasing_Page__c
            FROM SBQQ__Quote__c
            WHERE Id = :quoteId
            LIMIT 1
        ];
        return (quotes.isEmpty()) ? null : quotes[0];
    }

    private static Map<String, String> fetchTemplates() {
        // All new templates have name with 'Quote - ' prefix.
        Map<String, String> templates = new Map<String, String>();
        for (SBQQ__QuoteTemplate__c template : [
            SELECT Id, Name
            FROM SBQQ__QuoteTemplate__c
            WHERE Name LIKE 'Quote - %'
        ]) {
            templates.put(template.Name, template.Id);
        }
        return templates;
    }

    private static List<SBQQ__QuoteDocument__c> fetchQuoteDocuments(Id quoteId, String documentName) {
        // Order documents by automatically incremented SBQQ__Version__c number.
        // The main Quote section have the lowest SBQQ__QuoteDocument__c.SBQQ__Version__c.
        String name = documentName + '%';
        List<SBQQ__QuoteDocument__c> quoteDocuments = [
            SELECT Id, SBQQ__Quote__c, SBQQ__DocumentId__c, SBQQ__Version__c,
                SBQQ__Quote__r.SBQQ__PrimaryContact__c, SBQQ__Opportunity__c
            FROM SBQQ__QuoteDocument__c
            WHERE SBQQ__Quote__c = :quoteId
            AND Name LIKE :name
            ORDER BY SBQQ__Version__c
        ];
        return quoteDocuments;
    }

    private static String fetchJobStatus(String jobId) {
        List<AsyncApexJob> jobs = [
            SELECT Id, Status
            FROM AsyncApexJob
            WHERE Id = :jobId
        ];
        return (jobs.isEmpty()) ? null : jobs[0].Status;
    }

    public class QuoteDocumentParams {
        public String quoteId;
        public String templateId;
        public String fileName;
        public String language;
    }
}