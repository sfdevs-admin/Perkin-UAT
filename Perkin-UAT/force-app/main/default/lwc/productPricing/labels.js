/*
 * Copyright (c) 2023, salesforce.com, inc.
 * All rights reserved.
 * SPDX-License-Identifier: Apache-2.0
 * For full license text, see the LICENSE file in the repo
 * root or https://opensource.org/licenses/apache-2-0/
 */
import strikethroughAssistiveText from '@salesforce/label/c.Product_Pricing_strikethroughAssistiveText';
import saved from '@salesforce/label/c.B2B_PDP_Saved';
export const Labels = {
    /**
     * Assistive text, required because screenreaders do not read out strikethrough styling - reads "(crossed out)"
     * @type {string}
     */
    strikethroughAssistiveText,
    saved
};