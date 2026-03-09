import getWebstoreId from '@salesforce/apex/B2B_ShoppingListController.getWebstoreId';
import isGuest from '@salesforce/user/isGuest';
import communityId from '@salesforce/community/Id';
import promotionApi from '@salesforce/label/c.B2B_PDP_Promotion_Api';

export const fetchWebStoreId = () => {
    let mapParams = {
        'communityId': communityId
    };
    return getWebstoreId({ mapParams: mapParams });
};

// export const fetchProductPromotions = (webStoreId, productId, locale) => {
//     // const idsParam = Array.isArray(productIds) ? productIds.join(',') : productIds;
    
//     const url =
//         `/store/webruntime/api/services/data/v64.0/commerce/webstores/${webStoreId}/promotions/products?productIds=${productId}&language=${locale}&asGuest=${isGuest}&htmlEncode=false`;

//     return fetch(url, {
//         method: 'GET',
//         headers: { 'Content-Type': 'application/json' }
//     }).then(response => {
//         if (!response.ok) {
//             throw new Error(`HTTP error! status: ${response.status}`);
//         }
//         return response.json();
//     });
// };

export const fetchPromotionsForProductIds = async (webStoreId, productIds, locale) => {
    
    if (!Array.isArray(productIds) || productIds.length === 0) {
        throw new Error('fetchPromotionsForProductIds: productIds array is required and cannot be empty');
    }

    const idsParam = (Array.isArray(productIds) || productIds.length === 0)  ? productIds.join(',') : productIds;

    const url = promotionApi.replace('{0}', webStoreId)
                .replace('{1}', encodeURIComponent(idsParam))
                .replace('{2}', locale)
                .replace('{3}', isGuest);

    // const url =`/store/webruntime/api/services/data/v64.0/commerce/webstores/${webStoreId}/promotions/products?productIds=${encodeURIComponent(idsParam)}&language=${locale}&asGuest=${isGuest}&htmlEncode=false`;

    const response = await fetch(url, {
        method: 'GET',
        headers: { 'Content-Type': 'application/json' }
    });

    if (!response.ok) {
        throw new Error(`fetchPromotionsForProductIds: HTTP error! status: ${response.status}`);
    }

    console.log('response', response);
    return response.json();
};