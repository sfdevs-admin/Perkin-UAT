/**
 * Created by frankvanloon on 5/20/20.
 */

public with sharing class BD_CustomLookupService {
	private final static Integer MAX_RESULTS = 10;

	/**
	 * Class used to serialize a single Lookup search result item
	 * The Lookup controller returns a List<LookupSearchResult> when sending search result back to Lightning
	 */
	public class LookupSearchResult implements Comparable {
		@AuraEnabled public String id { get; set; }
		@AuraEnabled public String sObjectType { get; set; }
		@AuraEnabled public String icon { get; set; }
		@AuraEnabled public String title { get; set; }
		@AuraEnabled public String subtitle { get; set; }

		public LookupSearchResult() {}
		
		public LookupSearchResult(String id, String sObjectType, String icon, String title, String subtitle) {
			this.id = id;
			this.sObjectType = sObjectType;
			this.icon = icon;
			this.title = title;
			this.subtitle = subtitle;
		}

		/*
		 * Allow to sort search results based on title
		 */
		public Integer compareTo(Object compareTo) {
			LookupSearchResult other = (LookupSearchResult) compareTo;
			if (this.title == null) {
				return (other.title == null) ? 0 : 1;
			}
			if (other.title == null) {
				return -1;
			}
			return this.title.compareTo(other.title);
		}
	}

	@AuraEnabled(Cacheable=true)
	public static List<LookupSearchResult> searchTechnicians(String searchTerm, List<String> selectedIds)
	{
		// Prepare query paramters
		searchTerm += '*';

		// Execute SOSL search query
		List<List<SObject>> searchResults = [
				FIND :searchTerm
				IN ALL FIELDS
					RETURNING
					SVMXC__Service_Group_Members__c(Id, Name, SMAX_PS_Work_Center__c, SMAX_PS_Plant__c WHERE id NOT IN :selectedIds),
					SVMXC__Site__c(Id, Name, SMAX_PS_LocationCode__c WHERE id NOT IN :selectedIds)
				LIMIT :MAX_RESULTS
		];

		// Prepare results
		List<LookupSearchResult> results = new List<LookupSearchResult>();

		Set<String> plants = new Set<String>();
		// Extract Technicians & convert them into LookupSearchResult
		SVMXC__Service_Group_Members__c[] techs = (List<SVMXC__Service_Group_Members__c>) searchResults[0];
		for (SVMXC__Service_Group_Members__c tech : techs) {
			if (!plants.contains(tech.SMAX_PS_Plant__c))
			{
				plants.add(tech.SMAX_PS_Plant__c);
				results.add(
						new LookupSearchResult(
								tech.SMAX_PS_Plant__c,
								'PLANT',
								'custom:custom32',
								tech.SMAX_PS_Plant__c,
								'Plant'
						)
				);
			}

			results.add(
					new LookupSearchResult(
						tech.Id,
						'SVMXC__Service_Group_Members__c',
						'custom:custom15',
						tech.Name,
						'Technician • ' + tech.SMAX_PS_Work_Center__c
					)
			);
		}

		// Extract Locations & convert them into LookupSearchResult
		SVMXC__Site__c[] locations = (List<SVMXC__Site__c>) searchResults[1];
		for (SVMXC__Site__c location : locations) {
			results.add(
					new LookupSearchResult(
						location.Id,
						'SVMXC__Site__c',
						'custom:custom24',
						location.Name,
						'Location • ' + location.SMAX_PS_LocationCode__c
					)
			);
		}

		// Optionally sort all results on title
		results.sort();

		return results;
	}
}