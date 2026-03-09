@IsTest
public with sharing class B2BTaxCartCalculatorExtensionTest {
  @testSetup
  static void setup() {
    Account account = new Account(Name = 'TestAccount');
    insert account;
    WebStore webStore = new WebStore(
      Name = 'Training',
      SupportedLanguages = 'en_US',
      DefaultLanguage = 'en_US'
      // Tax_Document_Type__c = 'INVOICE',
      // Tax_Transaction_Type__c = 'SALE'
    );
    insert webStore;
    WebCart cart = new WebCart(
      Name = 'Cart',
      WebStoreId = webStore.Id,
      AccountId = account.Id,
      CurrencyIsoCode = 'USD'
    );
      insert cart;
      OrderDeliveryMethod odm = B2B_TestDataFactory.createOrderDeliveryMethod(true);
      CartDeliveryGroup cartDeliveryGroup = B2B_TestDataFactory.createCartDeliveryGroup(cart.Id, odm.Id, false);
	  cartDeliveryGroup.DeliverToCountry = 'DE';
      insert cartDeliveryGroup;
    /*CartDeliveryGroup cartDeliveryGroup = new CartDeliveryGroup(
      CartId = cart.Id,
      Name = 'Default Delivery'
    );
    insert cartDeliveryGroup;*/
    CartItem cartItem = new CartItem(
      CartId = cart.Id,
      Sku = 'SKU_Test1',
      Quantity = 3.0,
      Type = 'Product',
      Name = 'TestProduct',
      NetUnitPrice = 100.00,
      UnitAdjustedPrice = 100.00,
      TotalLineAmount = 100.00,
      CartDeliveryGroupId = cartDeliveryGroup.Id
    );
    insert cartItem;
  }

  @isTest
  static void testCalculate() {
    CartExtension.Cart cart = arrangeCart();
    String name = 'Training';
    CartExtension.BuyerActionsMock buyerActions = getBuyerActionsForDeleteFromCart(
      cart
    );
    CartExtension.BuyerActionDetails buyerActionDetails = getBuyerActionDetailsForQuantityIncrease(
      cart.getCartItems().get(0)
    );
    CartExtension.OptionalBuyerActionDetails optionalBuyerActionDetails = CartExtension.OptionalBuyerActionDetails.of(
      buyerActionDetails
    );
    CartExtension.CartCalculateCalculatorRequest Cartrequest = new CartExtension.CartCalculateCalculatorRequest(
      cart,
      optionalBuyerActionDetails
    );
    // Mock Tax Authentication Response
    // Test.setMock(HttpCalloutMock.class, new B2BTaxAuthMock());
    try {
      Test.startTest();
      B2BTaxCartCalculatorExtension taxCaluculate = new B2BTaxCartCalculatorExtension();

      taxCaluculate.calculate(Cartrequest);
      Test.stopTest();
    } catch (Exception e) {
      System.debug('exception test :: ' + e);
    }
  }

  private static CartExtension.BuyerActionsMock getBuyerActionsForDeleteFromCart(
    CartExtension.Cart cart
  ) {
    return getCartItemChangedBuyerActions(cart);
  }
  private static CartExtension.BuyerActionDetails getBuyerActionDetailsForQuantityIncrease(
    CartExtension.CartItem cartItemWithIncreasedQuantity
  ) {
    CartExtension.CartItemChange cartItemChange = new CartExtension.CartItemChange.Builder()
      .withChangedItem(
        CartExtension.OptionalCartItem.of(cartItemWithIncreasedQuantity)
      )
      .withQuantityIncreased(true)
      .build();
    List<CartExtension.CartItemChange> changedCartItems = new List<CartExtension.CartItemChange>{
      cartItemChange
    };
    CartExtension.BuyerActionDetails buyerActionDetails = new CartExtension.BuyerActionDetails.Builder()
      .withCartItemChanges(changedCartItems)
      .build();
    return buyerActionDetails;
  }
  private static CartExtension.BuyerActionsMock getCartItemChangedBuyerActions(
    CartExtension.Cart cart
  ) {
    CartExtension.BuyerActionsMock buyerActions = new CartExtension.BuyerActionsMock(
      cart
    );
    buyerActions.setCartItemChanged(true);
    return buyerActions;
  }

  @IsTest
  static void testTaxCartCalculator() {
    // Arrange
    WebCart cart = [
      SELECT Id, WebStoreId, AccountId
      FROM WebCart
      WHERE Name = 'Cart'
      LIMIT 1
    ];
    CartItem cartItem = [
      SELECT Id, CartId, Name, Sku, NetUnitPrice, UnitAdjustedPrice
      FROM CartItem
      WHERE CartId = :cart.Id
      LIMIT 1
    ];

    // Mock Tax Authentication Response
    // Test.setMock(HttpCalloutMock.class, new B2BTaxAuthMock());

    CartExtension.Cart cartObject = CartExtension.CartTestUtil.getCart(cart.Id);
    CartExtension.OptionalBuyerActionDetails buyerDetails = CartExtension.OptionalBuyerActionDetails.empty();

    // Mock Tax Calculation Response
    Test.setMock(HttpCalloutMock.class, new B2BTaxCalcMock(cartObject));

    // Retrieve the latest cart items
    CartExtension.CartItemList cartItemCollection = cartObject.getCartItems();

    // Find the matching cart item
    CartExtension.CartItem cartItemObject;

    for (Integer i = 0; i < cartItemCollection.size(); i++) {
      if (cartItemCollection.get(i).getId() == cartItem.Id) {
        // Ensure we're working with the correct item
        cartItemObject = cartItemCollection.get(i);
        break;
      }
    }

    Map<String, CartExtension.CartItem> cartItemById = new Map<String, CartExtension.CartItem>{
      cartItem.Id => cartItemObject
    };

    // Act
    Test.startTest();
    CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(
      cartObject,
      buyerDetails
    );
    B2BTaxCartCalculatorExtension calculator = new B2BTaxCartCalculatorExtension();
    Map<String, B2BTaxResponseWrapper.LineResult> taxResponse = B2BTaxService.getResponseFromExternalService(
      cartObject,
      cartItemById
    );
    calculator.calculate(request);
    Test.stopTest();

    // Assert
    CartExtension.CartValidationOutputList cartValidationOutputs = cartObject.getCartValidationOutputs();
    System.assertEquals(
      0,
      cartValidationOutputs.size(),
      'Validation errors returned'
    );
  }

  @IsTest
  static void testTaxCartCalculatorOtherCountries() {
    // Arrange
    WebCart cart = [
      SELECT Id, WebStoreId, AccountId, CurrencyIsoCode
      FROM WebCart
      WHERE Name = 'Cart'
      LIMIT 1
    ];
    cart.CurrencyIsoCode = 'EUR';
    update cart;

    CartItem cartItem = [
      SELECT Id, CartId, Name, Sku, NetUnitPrice, UnitAdjustedPrice
      FROM CartItem
      WHERE CartId = :cart.Id
      LIMIT 1
    ];

    // Mock Tax Authentication Response
    // Test.setMock(HttpCalloutMock.class, new B2BTaxAuthMock());

    CartExtension.Cart cartObject = CartExtension.CartTestUtil.getCart(cart.Id);
    CartExtension.OptionalBuyerActionDetails buyerDetails = CartExtension.OptionalBuyerActionDetails.empty();

    // Mock Tax Calculation Response
    Test.setMock(HttpCalloutMock.class, new B2BTaxCalcMock(cartObject));

    // Retrieve the latest cart items
    CartExtension.CartItemList cartItemCollection = cartObject.getCartItems();

    // Find the matching cart item
    CartExtension.CartItem cartItemObject;

    for (Integer i = 0; i < cartItemCollection.size(); i++) {
      if (cartItemCollection.get(i).getId() == cartItem.Id) {
        // Ensure we're working with the correct item
        cartItemObject = cartItemCollection.get(i);
        break;
      }
    }

    Map<String, CartExtension.CartItem> cartItemById = new Map<String, CartExtension.CartItem>{
      cartItem.Id => cartItemObject
    };

    // Act
    Test.startTest();
    CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(
      cartObject,
      buyerDetails
    );
    B2BTaxCartCalculatorExtension calculator = new B2BTaxCartCalculatorExtension();
    Map<String, B2BTaxResponseWrapper.LineResult> taxResponse = B2BTaxService.getResponseFromExternalService(
      cartObject,
      cartItemById
    );
    calculator.calculate(request);
    Test.stopTest();

    // Assert
    CartExtension.CartValidationOutputList cartValidationOutputs = cartObject.getCartValidationOutputs();
    System.assertEquals(
      0,
      cartValidationOutputs.size(),
      'Validation errors returned'
    );
  }

  private static CartExtension.Cart arrangeCart() {
    Account testAccount = new Account(Name = 'My Account');
    insert testAccount;

    WebStore testWebStore = new WebStore(
      Name = 'Training'
      // Tax_Document_Type__c = 'INVOICE',
      // Tax_Transaction_Type__c = 'SALE'
    );
    insert testWebStore;

    WebCart testCart = new WebCart(
      Name = 'My Cart',
      WebStoreId = testWebStore.Id,
      AccountId = testAccount.Id
    );
    insert testCart;

    CartDeliveryGroup testDeliveryGroup = new CartDeliveryGroup(
      Name = 'My Delivery Group',
      CartId = testCart.Id,
      DeliverToStreet = '415 Mission St',
      DeliverToCity = 'San Francisco',
      DeliverToCountry = 'United States',
      DeliverToPostalCode = '11098',
      DeliverToState = 'Maryland'
    );
    insert testDeliveryGroup;
    Product2 testProduct2 = new Product2(
      name = 'My Product2',
      Tax_Class_Id__c = 'Test',
      Taxable__c = false
    );
    insert (testProduct2);

    Product2 testProduct = new Product2(
      name = 'My Product35',
      Tax_Class_Id__c = 'Test',
      Taxable__c = true
    );
    insert (testProduct);
    Product2 testProduct3 = new Product2(
      name = 'My Products',
      Taxable__c = true
    );
    insert (testProduct3);

    CartItem testCartItem = new CartItem(
      Name = 'My Cart Item',
      Product2Id = testProduct.Id,
      Type = 'Charge',
      CartId = testCart.Id,
      CartDeliveryGroupId = testDeliveryGroup.Id
    );
    insert testCartItem;
    CartItem testCartItemed = new CartItem(
      Name = 'My Cart Item',
      Product2Id = testProduct3.Id,
      Type = 'Charge',
      CartId = testCart.Id,
      CartDeliveryGroupId = testDeliveryGroup.Id
    );
    insert testCartItemed;
    CartItem testCartItem2 = new CartItem(
      Name = 'My Cart Item 2',
      Product2Id = testProduct2.Id,
      Type = 'Product',
      CartId = testCart.Id,
      CartDeliveryGroupId = testDeliveryGroup.Id
    );
    insert testCartItem2;
    CartItem testCartItem3 = new CartItem(
      Name = 'My Cart Item 2',
      Product2Id = testProduct.Id,
      Type = 'Product',
      CartId = testCart.Id,
      CartDeliveryGroupId = testDeliveryGroup.Id
    );
    insert testCartItem3;
    CartItem testCartItem4 = new CartItem(
      Name = 'My Cart Item 2',
      Product2Id = testProduct3.Id,
      Type = 'Product',
      CartId = testCart.Id,
      CartDeliveryGroupId = testDeliveryGroup.Id
    );
    insert testCartItem4;
    CartTax cartTax = new CartTax(
      CartItemId = testCartItem.Id,
      Name = 'CartTax',
      Amount = 20.00,
      TaxType = 'Actual',
      TaxCalculationDate = date.newInstance(2023, 10, 21)
    );
    insert cartTax;
    CartValidationOutput cartValidate = new CartValidationOutput(
      Name = 'cartValidate',
      Type = 'Taxes',
      CartId = testCart.Id,
      Level = 'Info',
      RelatedEntityId = testCartItem.Id
    );
    insert cartValidate;
    Promotion promotion = new Promotion(
      Name = 'Promotion',
      IsActive = true,
      IsCommercePromotion = true,
      IsAutomatic = false
    );
    insert promotion;
    CartItemPriceAdjustment cartItemAdj = new CartItemPriceAdjustment(
      PriceAdjustmentCauseId = promotion.id,
      CartId = testCart.Id,
      CartItemId = testCartItem.Id,
      Name = 'cartItemAdj',
      TotalAmount = 45.00,
      AdjustmentSource = 'Rule',
      AdjustmentType = 'AdjustmentPercentage',
      AdjustmentValue = 90.00,
      AdjustmentTargetType = 'Cart'
    );
    insert cartItemAdj;
    WebCartAdjustmentBasis testCartAdjustmentBasis = new WebCartAdjustmentBasis(
      Name = 'My Coupon',
      WebCartId = testCart.Id
    );
    insert testCartAdjustmentBasis;

    return CartExtension.CartTestUtil.getCart(testCart.Id);
  }

  //

  @IsTest
  static void testTaxCartCalculatorStripe() {
    // Arrange
    WebCart cart = [
      SELECT Id, WebStoreId, AccountId
      FROM WebCart
      WHERE Name = 'Cart'
      LIMIT 1
    ];
    CartItem cartItem = [
      SELECT Id, CartId, Name, Sku, NetUnitPrice, UnitAdjustedPrice
      FROM CartItem
      WHERE CartId = :cart.Id
      LIMIT 1
    ];

    // Mock Tax Authentication Response
    // Test.setMock(HttpCalloutMock.class, new B2BTaxAuthMock());

    CartExtension.Cart cartObject = CartExtension.CartTestUtil.getCart(cart.Id);
    CartExtension.OptionalBuyerActionDetails buyerDetails = CartExtension.OptionalBuyerActionDetails.empty();

    // Mock Tax Calculation Response
    Test.setMock(HttpCalloutMock.class, new B2BStripeTaxMock(cartObject));

    // Retrieve the latest cart items
    CartExtension.CartItemList cartItemCollection = cartObject.getCartItems();

    // Find the matching cart item
    CartExtension.CartItem cartItemObject;

    for (Integer i = 0; i < cartItemCollection.size(); i++) {
      if (cartItemCollection.get(i).getId() == cartItem.Id) {
        // Ensure we're working with the correct item
        cartItemObject = cartItemCollection.get(i);
        break;
      }
    }

    Map<String, CartExtension.CartItem> cartItemById = new Map<String, CartExtension.CartItem>{
      cartItem.Id => cartItemObject
    };

    // Act
    Test.startTest();
    CartExtension.CartCalculateCalculatorRequest request = new CartExtension.CartCalculateCalculatorRequest(
      cartObject,
      buyerDetails
    );
    B2BTaxCartCalculatorExtension calculator = new B2BTaxCartCalculatorExtension();
    B2BStripeTaxResponseWrapper taxResponse = B2BStripeTaxCalculatorService.getStripeTax(
      cartObject,
      cartItemById
    );
    calculator.calculate(request);
    Test.stopTest();

    // Assert
    CartExtension.CartValidationOutputList cartValidationOutputs = cartObject.getCartValidationOutputs();
    System.assertEquals(
      0,
      cartValidationOutputs.size(),
      'Validation errors returned'
    );
  }
}