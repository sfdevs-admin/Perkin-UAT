@IsTest
public class B2B_ShoppingListControllerTest {

    static User testUser;
    // static Account testAccount;
    static B2B_Shopping_List__c shoppingList;
    static B2B_Shopping_List_Item__c shoppingListItem;
    static Product2 testProduct;
    static Product2 testProduct2;

    @TestSetup
    static void setupTestData() {
        // Create Test Account
        // testAccount = new Account(Name = 'Test Account');
        // insert testAccount;

        // // Create Test User linked to Account
        // Profile p = [SELECT Id FROM Profile WHERE Name = 'Standard User' LIMIT 1];
        // testUser = new User(
        //     FirstName = 'Test',
        //     LastName = 'User',
        //     Email = 'testuser@example.com',
        //     Username = 'testuser' + DateTime.now().getTime() + '@example.com',
        //     Alias = 'tuser',
        //     TimeZoneSidKey = 'America/New_York',
        //     LocaleSidKey = 'en_US',
        //     EmailEncodingKey = 'UTF-8',
        //     ProfileId = p.Id,
        //     LanguageLocaleKey = 'en_US'
        // );
        // insert testUser;

        Account account = B2B_TestDataFactory.createAccount('Test Account', true);
        Contact contact = B2B_TestDataFactory.createContact('Test Contact', account.Id, true);
        User user = B2B_TestDataFactory.createUser('test', 'test@gmail.com', contact.Id, true);

        // Create Test Product
        testProduct = new Product2(
            Name = 'Test Product',
            IsActive = true,
            B2B_Part_Number__c = 'SKU1234',
            B2B_Short_Description__c = 'Test Short Description'
        );
        insert testProduct;

        // Create Test Product 2
        testProduct2 = new Product2(
            Name = 'Test Product 2',
            IsActive = true,
            B2B_Part_Number__c = 'SKU5678',
            B2B_Short_Description__c = 'Test 2 Short Description'
        );
        insert testProduct2;

        // Create Shopping List
        shoppingList = new B2B_Shopping_List__c(
            B2B_Name__c = 'Test List',
            B2B_Description__c = 'Test Description',
            B2B_Active__c = true,
            B2B_Account__c = account.Id,
            B2B_Default__c = true
        );
        insert shoppingList;

        // Create Shopping List Item
        shoppingListItem = new B2B_Shopping_List_Item__c(
            B2B_Shopping_List__c = shoppingList.Id,
            B2B_Product__c = testProduct.Id,
            B2B_Quantity__c = 5
        );
        insert shoppingListItem;

        //public list data 
        Product2 prod = new Product2(
            Name = 'HelperTest Product',
            IsActive = true,
            B2B_Part_Number__c = 'SKU-H123',
            B2B_Short_Description__c = 'HelperTest Short Desc'
        );
        insert prod;

        B2B_Shopping_List__c pubList = new B2B_Shopping_List__c(
            B2B_Name__c = 'Public List',
            B2B_Description__c = 'Public Description',
            B2B_Active__c = true,
            B2B_Default__c = false,
            B2B_Public__c = true
        );
        insert pubList;

        B2B_Shopping_List_Item__c pubItem = new B2B_Shopping_List_Item__c(
            B2B_Shopping_List__c = pubList.Id,
            B2B_Product__c = prod.Id,
            B2B_Quantity__c = 2
        );
        insert pubItem;
    }

    @IsTest
    static void testGetShoppingLists() {
        Test.startTest();
        User testUser = [SELECT Id FROM User WHERE Email = 'test@gmail.com' LIMIT 1];
        System.runAs(testUser) {
            Map<String, Object> params = new Map<String, Object>();
            Map<String, Object> result = B2B_ShoppingListController.getShoppingLists(params);

            System.assertEquals(true, result.get('isSuccess'));
            System.assert(((List<B2B_Shopping_List__c>)result.get('shoppingLists')).size() > 0, 'Shopping list should be returned');
        }
        Test.stopTest();
    }

    @IsTest
    static void testGetShoppingListItems() {
        String selectedShoppingListId = [SELECT Id FROM B2B_Shopping_List__c WHERE B2B_Name__c = 'Test List' LIMIT 1].Id;
        Test.startTest();
        Map<String, Object> params = new Map<String, Object>{
            'shoppingListId' => selectedShoppingListId
        };
        Map<String, Object> result = B2B_ShoppingListController.getShoppingListItems(params);

        System.assertEquals(true, result.get('isSuccess'));
        System.assert(((List<Map<String, Object>>)result.get('shoppingListItems')).size() > 0, 'Shopping list items should be returned');
        Test.stopTest();
    }

    @IsTest
    static void testGetNullShoppingListItems() {
        Test.startTest();
        Map<String, Object> params = new Map<String, Object>{
            'shoppingListId' => null
        };
        Map<String, Object> result = B2B_ShoppingListController.getShoppingListItems(params);

        System.assertEquals(false, result.get('isSuccess'));
        Test.stopTest();
    }

    @IsTest
    static void testUpdateShoppingListItemQty() {
        String selectedShoppingListItemId = [SELECT Id FROM B2B_Shopping_List_Item__c LIMIT 1].Id;

        Test.startTest();
        Map<String, Object> params = new Map<String, Object>{
            'shoppingListItemId' => selectedShoppingListItemId,
            'quantity' => 10
        };
        Map<String, Object> result = B2B_ShoppingListController.updateShoppingListItemQty(params);

        System.assertEquals(true, result.get('isSuccess'));
        B2B_Shopping_List_Item__c updatedItem = [SELECT B2B_Quantity__c FROM B2B_Shopping_List_Item__c WHERE Id = :selectedShoppingListItemId];
        System.assertEquals(10, updatedItem.B2B_Quantity__c, 'Quantity should be updated');
        Test.stopTest();
    }

    @IsTest
    static void testUpdateNullShoppingListItemQty() {
        Test.startTest();
        Map<String, Object> params = new Map<String, Object>{
            'shoppingListItemId' => null,
            'quantity' => 10
        };
        Map<String, Object> result = B2B_ShoppingListController.updateShoppingListItemQty(params);

        System.assertEquals(false, result.get('isSuccess'));
        Test.stopTest();
    }

    @IsTest
    static void testDeleteShoppingListItem() {
        String selectedShoppingListItemId = [SELECT Id FROM B2B_Shopping_List_Item__c LIMIT 1].Id;

        Test.startTest();
        Map<String, Object> params = new Map<String, Object>{
            'shoppingListItemId' => selectedShoppingListItemId
        };
        Map<String, Object> result = B2B_ShoppingListController.deleteShoppingListItem(params);

        System.assertEquals(true, result.get('isSuccess'));

        Integer countItems = [SELECT COUNT() FROM B2B_Shopping_List_Item__c WHERE Id = :selectedShoppingListItemId];
        System.assertEquals(0, countItems, 'Item should be deleted');
        Test.stopTest();
    }

    @IsTest
    static void testDeleteNullShoppingListItem() {
        Test.startTest();
        Map<String, Object> params = new Map<String, Object>{
            'shoppingListItemId' => null
        };
        Map<String, Object> result = B2B_ShoppingListController.deleteShoppingListItem(params);

        System.assertEquals(false, result.get('isSuccess'));
        Test.stopTest();
    }

    @IsTest
    static void testDeleteShoppingList() {
        String selectedShoppingListId = [SELECT Id FROM B2B_Shopping_List__c WHERE B2B_Name__c = 'Test List' LIMIT 1].Id;

        Test.startTest();
        Map<String, Object> params = new Map<String, Object>{
            'shoppingListId' => selectedShoppingListId
        };
        Map<String, Object> result = B2B_ShoppingListController.deleteShoppingList(params);

        System.assertEquals(true, result.get('isSuccess'));

        Integer countList = [SELECT COUNT() FROM B2B_Shopping_List__c WHERE Id = :selectedShoppingListId];
        System.assertEquals(0, countList, 'Shopping list should be deleted');
        Test.stopTest();    
    }

    @IsTest
    static void testDeleteNullShoppingList() {
        Test.startTest();
        Map<String, Object> params = new Map<String, Object>{
            'shoppingListId' => null
        };
        Map<String, Object> result = B2B_ShoppingListController.deleteShoppingList(params);

        System.assertEquals(false, result.get('isSuccess'));
        Test.stopTest();    
    }

    @IsTest
    static void testCreateShoppingListHelper() {
        Test.startTest();
        User testUser = [SELECT Id FROM User WHERE Email = 'test@gmail.com' LIMIT 1];
        System.runAs(testUser) {
            Map<String, Object> params = new Map<String, Object>{
                'name' => 'New List From Helper',
                'description' => 'Created from test',
                'isDefault' => true
            };

            Map<String, Object> result = B2B_ShoppingListController.createShoppingList(params);

            System.assertEquals(true, result.get('isSuccess'));
            System.assertNotEquals(null, result.get('shoppingList'));
        }
        Test.stopTest();
    }

    @IsTest
    static void testAddItemToShoppingListHelper() {
        Id listId = [SELECT Id FROM B2B_Shopping_List__c LIMIT 1].Id;
        Id productId = [SELECT Id FROM Product2 WHERE Name =: 'Test Product 2' LIMIT 1].Id;

        Test.startTest();
        Map<String, Object> params = new Map<String, Object>{
            'shoppingListId' => listId,
            'productId' => productId,
            'quantity' => 3
        };

        Map<String, Object> result = B2B_ShoppingListController.addItemToShoppingList(params);

        System.assertEquals(true, result.get('isSuccess'));
        System.assertNotEquals(null, result.get('shoppingListItem'));
        Test.stopTest();
    }

    @IsTest
    static void testGetShoppingListByIdHelper() {
        Id listId = [SELECT Id FROM B2B_Shopping_List__c LIMIT 1].Id;

        Test.startTest();
        Map<String, Object> params = new Map<String, Object>{
            'shoppingListId' => listId
        };

        Map<String, Object> result = B2B_ShoppingListController.getShoppingListById(params);

        System.assertEquals(true, result.get('isSuccess'));
        List<B2B_Shopping_List__c> lists = (List<B2B_Shopping_List__c>) result.get('shoppingLists');
        System.assert(lists != null && !lists.isEmpty());
        Test.stopTest();
    }

    @IsTest
    static void testGetPublicShoppingListByIdHelper() {
        Id publicListId = [SELECT Id FROM B2B_Shopping_List__c WHERE B2B_Public__c = TRUE LIMIT 1].Id;

        Test.startTest();
        Map<String, Object> params = new Map<String, Object>{
            'shoppingListId' => publicListId
        };

        Map<String, Object> result = B2B_ShoppingListController.getPublicShoppingListById(params);

        System.assertEquals(true, result.get('isSuccess'));
        List<B2B_Shopping_List__c> publicLists = (List<B2B_Shopping_List__c>) result.get('publicShoppingList');
        System.assert(publicLists != null && !publicLists.isEmpty());
        Test.stopTest();
    }

    @IsTest
    static void testGetNullPublicShoppingListByIdHelper() {

        Test.startTest();
        Map<String, Object> params = new Map<String, Object>{
            'shoppingListId' => null
        };

        Map<String, Object> result = B2B_ShoppingListController.getPublicShoppingListById(params);

        System.assertEquals(false, result.get('isSuccess'));
        Test.stopTest();
    }

    @IsTest
    static void testCloneShoppingListHelper() {
        Id publicListId = [SELECT Id FROM B2B_Shopping_List__c WHERE B2B_Public__c = TRUE LIMIT 1].Id;

        Test.startTest();
        User testUser = [SELECT Id FROM User WHERE Email = 'test@gmail.com' LIMIT 1];
        System.runAs(testUser) {
            Map<String, Object> params = new Map<String, Object>{
                'publicListId' => publicListId,
                'newName' => 'Cloned List',
                'newDescription' => 'Cloned from public',
                'makeDefault' => false
            };

            Map<String, Object> result = B2B_ShoppingListController.cloneShoppingList(params);

            System.assertEquals(true, result.get('isSuccess'));
            System.assertNotEquals(null, result.get('newShoppingListId'));
        }
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateShoppingListDetailsHelper() {
        Id listId = [SELECT Id FROM B2B_Shopping_List__c LIMIT 1].Id;

        Test.startTest();
         Map<String, Object> params = new Map<String, Object>{
            'shoppingListId' => listId,
            'newName' => 'Updated Name',
            'newDescription' => 'Updated Description',
            'makeDefault' => false
        };

        Map<String, Object> result = B2B_ShoppingListController.updateShoppingListDetails(params);

        System.assertEquals(true, result.get('isSuccess'));
        Test.stopTest();
    }
    
    @IsTest
    static void testUpdateShoppingListDetailsDefaultHelper() {
        Id listId = [SELECT Id FROM B2B_Shopping_List__c LIMIT 1].Id;

        Test.startTest();
         Map<String, Object> params = new Map<String, Object>{
            'shoppingListId' => listId,
            'newName' => 'Updated Name',
            'newDescription' => 'Updated Description',
            'makeDefault' => true
        };

        Map<String, Object> result = B2B_ShoppingListController.updateShoppingListDetails(params);

        System.assertEquals(true, result.get('isSuccess'));
        Test.stopTest();
    }
}