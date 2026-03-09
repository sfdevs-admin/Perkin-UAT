public with sharing class DupBlockAccountRedirectController
{
    /******************************************************************************/
    /* If you're modifying this for use with an object other than contact, change */
    /* the object type in the List<Contact> below to the object type you need to  */
    /* support.                                                                   */
    /******************************************************************************/
    public List<Account> dupes { get; set; }
    public Integer dupeCount { get { return dupes.size(); } }
    

    /******************************************************************************/
    /* If you change the name of the class, change the name of this constructor    */
    /* to match the class name.  The constructor will load the duplicate data for */
    /* display on the page.                                                       */
    /******************************************************************************/
    public DupBlockAccountRedirectController()
    {
        // Load our dupe ids from the dupes URL parameter.
        // The dupes parameter is actually a list of value pairs containing the ID URL and name
        // separated by special characters.  Split the parameter by \f then get the first
        // value of the pair by splitting by \b.
        String dupesParm = ApexPages.currentPage().getParameters().get( 'dupes' );
        // If the parameter is empty, exit.
        if ( dupesParm == null || dupesParm.trim().length() == 0 )
            return;
        List<String> dupePairs = dupesParm.split( '\f' );
        Set<Id> dupeIds = new Set<Id>();
        // Add just the ID from the ID URL/name pairs and remove the leading / from the ID
        // URL to convert it to an ID and then add it to the list of IDs to query.
        for ( String pair : dupePairs )
            dupeIds.add( pair.split( '\b' )[0].subString( 1 ) );
        
        /******************************************************************************/
        /* To add additional fields to display on the VF page, add them to both the   */
        /* page and this query.  Also, if you're copying the page for supporting a    */
        /* new object type, make sure to change the object name after the FROM in the */
        /* query.                                                                     */
        /******************************************************************************/
        dupes = [SELECT Id, Name, ShippingStreet,ShippingCity,ShippingState,ShippingCountry FROM Account WHERE Id IN :dupeIds];
        
        if ( dupes == null )
            /******************************************************************************/
            /* If you're modifying this for use with an object other than contact, change */
            /* the object type in the List<Contact> below to the object type you need to  */
            /* support.                                                                   */
            /******************************************************************************/
            dupes = new List<Account>();
    }
}