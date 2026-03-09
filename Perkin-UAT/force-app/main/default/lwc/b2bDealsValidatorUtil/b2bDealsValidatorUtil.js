import validateDealsOnAccount from '@salesforce/apex/B2B_DealValidator.validateDealsOnAccount';
import { getSessionContext } from 'commerce/contextApi';
import isGuest from '@salesforce/user/isGuest';

/**
 * Helper to get the effective account id from session context
 */
export async function getEffectiveAccountId() { 
    const sessionContext = await getSessionContext();
    const { effectiveAccountId } = sessionContext || {};
    // console.log('Effective Account Id:', effectiveAccountId);
    return String(effectiveAccountId);
}

/**
 * Validates if the account (if any) has deals.
 * For guest users, returns false immediately.
 * For logged-in users, fetches accountId and calls Apex.
 */
export async function validateDealsForAccount() {
    if (isGuest) {
        return false;
    }

    const effectiveAccountId = await getEffectiveAccountId();

    if (!effectiveAccountId) {
        console.warn('No effective account id found — assuming no deals.');
        return false;
    }

    const mapParams = { effectiveAccountId };
    // const effectiveAccountId = '001bc00000AAQtAAAX';
    
    try {
        const result = await validateDealsOnAccount({ mapParams: mapParams });
        const hasDeals = result?.hasDeals;
        // console.log('Deals check result:', hasDeals);
        return hasDeals;
    } catch (error) {
        console.error('Error checking deals:', error);
        return false;
    }
}