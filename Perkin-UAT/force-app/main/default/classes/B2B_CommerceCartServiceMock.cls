@isTest
public class B2B_CommerceCartServiceMock {
    public static ConnectApi.CartSummary createCart(Map<String,Object> mapParams) {
        ConnectApi.CartSummary mockSummary = new ConnectApi.CartSummary();
        mockSummary.cartId = (String)mapParams.get('webCartId'); // fake Id
        return mockSummary;
    }
}