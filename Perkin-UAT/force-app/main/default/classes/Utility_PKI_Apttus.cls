/***************************************************************************************************
*Created By: Vijayakumar Dilli
*Purpose: For Apttus,Utility class for processing Apttus information and making it as reusable code
***************************************************************************************************/
public class Utility_PKI_Apttus {

    public class TerritoriesBatches {
    
        public String batch1;
        public String batch2;
        public String batch3;
        
        public TerritoriesBatches() {
            batch1 = '';
            batch2 = '';
            batch3 = '';
        }
        
    }
    
    public Static TerritoriesBatches splitTerritories(String territories) {

        TerritoriesBatches territoriesBatch = new TerritoriesBatches();
        
        if (territories == null) {
            return territoriesBatch;
        }

        String[] territoryList = territories.split(';');
        Integer territoriesCount = territoryList.size();
        System.debug('>>>  Before sorting' +   territoryList);
        territoryList.sort();
        System.debug('>>>  After sorting' +   territoryList);
        Integer batch1Count, batch2Count, batch3Count;
        
        batch1Count = territoriesCount / 3;
        batch2Count = territoriesCount / 3;
        batch3Count = territoriesCount / 3;
        
        if (math.mod(territoriesCount,3) == 1) {
            batch1Count++;
        }
        if (math.mod(territoriesCount,3) == 2) {
            batch1Count++;
            batch2Count++;
        }
        
        for (String territory : territoryList) {
            if (territoriesBatch.batch1.countMatches('\n') < batch1Count) {
                territoriesBatch.batch1 += territory + '\n';
            } else {
                if (territoriesBatch.batch2.countMatches('\n') < batch2Count) {
                    territoriesBatch.batch2 += territory + '\n';
                } else {
                    territoriesBatch.batch3 += territory + '\n';
                }
            }
        }
        
        return territoriesBatch;
    
    }
    

}