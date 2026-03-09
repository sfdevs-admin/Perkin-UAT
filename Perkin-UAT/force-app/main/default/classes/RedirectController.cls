public with sharing class RedirectController {

public PageReference RedirectControllerInit() {
PageReference pageRef = new PageReference('http://go.perkinelmer.com/l/32222/2014-04-17/gcd7');
pageRef.setRedirect(true);
return pageRef;
}

}