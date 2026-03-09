/**
 * Created by mgaska001 on 16.11.2025.
 */

public with sharing class QuotePrimaryContactService {

    public static Integer FULL_NAME_MAX_LENGTH = 255;

    /**
     * @description SC-XXX Method for trigger handler on SBQQ__Quote__c after update to manage
     * Primary Contact full name on Quote with user readable Salutation
     * SAP salutation codes are stored as Contact.Salutation and Salesforce does not support to label conversion in formula fields
     */
    public static void populateFullName(List<SBQQ__Quote__c> newList, Map<Id, SBQQ__Quote__c> oldMap) {
        Map<Id, SBQQ__Quote__c> processMap = new Map<Id, SBQQ__Quote__c>();
        Set<Id> contactIds = new Set<Id>();

        for (SBQQ__Quote__c newQuote : newList) {
            SBQQ__Quote__c oldQuote = oldMap.get(newQuote.Id);
            if (oldQuote == null || newQuote.SBQQ__PrimaryContact__c != oldQuote.SBQQ__PrimaryContact__c) {
                processMap.put(newQuote.Id, newQuote);
                if (newQuote.SBQQ__PrimaryContact__c != null) {
                    contactIds.add(newQuote.SBQQ__PrimaryContact__c);
                }
            }
        }

        if (processMap.isEmpty()) {
            return;
        }

        Map<Id, Contact> contacts = fetchContacts(contactIds);

        for (SBQQ__Quote__c newQuote : processMap.values()) {
            if (newQuote.SBQQ__PrimaryContact__c != null) {
                Contact contact = contacts.get(newQuote.SBQQ__PrimaryContact__c);
                String fullName = contact.LastName;
                if (String.isNotBlank(contact.FirstName)) {
                    fullName = contact.FirstName + ' ' + fullName;
                }
                if (String.isNotBlank(contact.Salutation)) {
                    String salutation = contact.Salutation;
                    if (fullName.length() + salutation.length() > FULL_NAME_MAX_LENGTH - 1) {
                        salutation = salutation.left(FULL_NAME_MAX_LENGTH - fullName.length() - 2).trim() + '.';
                    }
                    fullName = salutation + ' ' + fullName;
                }
                newQuote.Primary_Contact_Full_Name__c = fullName;
            } else {
                newQuote.Primary_Contact_Full_Name__c = null;
            }
        }
    }

    /**
     * @description Helper method to query Contact records with FirstName, LastName and Salutation label
     */
    public static Map<Id, Contact> fetchContacts(Set<Id> contactIds) {
        if (contactIds.isEmpty()) {
            return new Map<Id, Contact>();
        }
        return new Map<Id, Contact>([
            SELECT Id, FirstName, LastName, toLabel(Salutation)
            FROM Contact
            WHERE Id IN :contactIds
        ]);
    }

}