@isTest(seeallData = true)
Public Class TestClassForLeadAge
{
  public static Testmethod void TestLeadAge()
  {
    User testUser1 = [SELECT Id, Name FROM User WHERE IsActive=true  LIMIT 1];
    Lead l =new Lead(Status='open',LastName='Temp',Company='Temp Company',Country='US');
    insert l;
    l.Ownerid=testUser1.id;
    update l;
  } 
}