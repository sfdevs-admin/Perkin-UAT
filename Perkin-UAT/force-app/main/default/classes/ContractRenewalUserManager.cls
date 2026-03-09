public class ContractRenewalUserManager {

    // Container to cache queried User records
    private static UserByNameContainer userContainer = new UserByNameContainer();

    /**
     * Determines the appropriate user to assign ownership based on the provided userId
     * @param userName - The name of the user to check source SVMXC__Service_Contract__c.SMAX_PS_SalesRepName__c
     * @param territory - The territory to check source SVMXC__Service_Contract__c.SVMXC__Company__r.fxPKITerritory__c
     * @return Id - The ID of the user who should own the created records
     */
    public static Id getSalesRep(String userName, String territory) {
        User salesRep = getSalesRepByUser(getUserByName(userName));
        if (salesRep != null) {
            return salesRep.Id;
        }
        salesRep = getSalesRepByTerritory(getRenewalMetadata(territory));
        if (salesRep != null) {
            return salesRep.Id;
        }
        // Fallback: Return running user
        return UserInfo.getUserId();
    }

    private static User getSalesRepByUser(User user) {
        if (user != null) {
            if (user.IsActive) {
                return user;
            }
            User manager = getUserById(user.Direct_Manager__c);
            if (manager != null && manager.IsActive) {
                return manager;
            }
            if (String.isNotBlank(user.PKITerritory__c)) {
                return getSalesRepByTerritory(getRenewalMetadata(user.PKITerritory__c));
            }
        }
        return null;
    }

    private static User getSalesRepByTerritory(Renewal_Service_Ownership__mdt metadata) {
        if (metadata == null) {
            return null;
        }
        // Try Regional Director first
        User regionalDirector = getUserByName(metadata.Regional_Director__c);
        if (regionalDirector != null && regionalDirector.IsActive) {
            return regionalDirector;
        }
        // Try Escalation Point
        User escalationPoint = getUserByName(metadata.Escalation_Point__c);
        if (escalationPoint != null && escalationPoint.IsActive) {
            return escalationPoint;
        }
        // Try Final Point
        User finalPoint = getUserByName(metadata.Final_Point__c);
        if (finalPoint != null && finalPoint.IsActive) {
            return finalPoint;
        }
        return null;
    }

    /**
     * Retrieves metadata Renewal_Service_Ownership__mdt record for the given territory
     */
    private static Renewal_Service_Ownership__mdt getRenewalMetadata(String territory) {
        
        if (String.isBlank(territory)) {
            return null;
        }
        
        try {
            List<Renewal_Service_Ownership__mdt> metadataList = [
                SELECT Regional_Director__c, 
                       Fx_PKI_Territory__c, 
                       Final_Point__c, 
                       Escalation_Point__c
                FROM Renewal_Service_Ownership__mdt
                WHERE Fx_PKI_Territory__c = :territory
                LIMIT 1
            ];
            return metadataList.isEmpty() ? null : metadataList[0];
        } catch (Exception e) {
            System.debug('Error querying metadata: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * Retrieves user by ID with Id, Name, IsActive, Direct_Manager__c, PKITerritory__c fields
     */
    private static User getUserById(Id userId) {
        if (userId == null) {
            return null;
        }
        // Check User Container cache
        User user = userContainer.getById(userId);
        if (user != null) {
            return user;
        }
        try {
            List<User> users = [
                SELECT Id, Name, IsActive, Direct_Manager__c, PKITerritory__c
                FROM User
                WHERE Id = :userId
                LIMIT 1
            ];
            if (!users.isEmpty()) {
                user = users[0];
                // Store User to the container - the one was found by Id
                userContainer.put(user.Name, user);
            }
            return user;
        } catch (Exception e) {
            System.debug('Error querying user by ID: ' + e.getMessage());
            return null;
        }
    }
    
    /**
     * Retrieves user by Name with Id, Name, IsActive, Direct_Manager__c, PKITerritory__c fields
     */
    private static User getUserByName(String userName) {
        if (String.isBlank(userName)) {
            return null;
        }
        // Check User Container cache
        if (userContainer.contains(userName)) {
            return userContainer.getByName(userName);
        }
        try {
            List<User> users = [
                SELECT Id, Name, IsActive, Direct_Manager__c, PKITerritory__c
                FROM User
                WHERE Name = :userName
            ];
            User user = null;
            if (!users.isEmpty()) {
                if (users.size() == 1) {
                    user = users[0];
                } else {
                    // When there is more than one user with the same name checking first Active one
                    // Ignoring NOT active
                    for (User sameUser : users) {
                        if (sameUser.IsActive) {
                            user = sameUser;
                            break;
                        }
                    }
                }
            }
            // Put to the User container queried user name no mater if user was found or not
            // Need to cache information about every name especially for user names not in Salesforce
            // Register userName argument in the map - data for contract renewals may have capital letters
            // f.i. SMAX_PS_SalesRepName__c = KATHY BEITER, User.Name = Kathy Beiter
            userContainer.put(userName, user);
            return user;
        } catch (Exception e) {
            System.debug('Error querying user by name: ' + e.getMessage());
            return null;
        }
    }

    private class UserByNameContainer {
        final Map<Id, User> users = new Map<Id, User>();
        final Map<String, Id> usersByName = new Map<String, Id>();

        void put(String name, User user) {
            if (user != null) {
                users.put(user.Id, user);
                usersByName.put(name, user.Id);
            } else {
                usersByName.put(name, null);
            }
        }

        Boolean contains(String name) {
            return usersByName.containsKey(name);
        }

        User getByName(String name) {
            Id userId = usersByName.get(name);
            return (userId != null) ? users.get(userId) : null;
        }

        User getById(Id userId) {
            return users.get(userId);
        }
    }
}