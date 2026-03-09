@IsTest
private class MergePDFControllerTest {

    @TestSetup
    static void setupTestData() {
        Document doc1 = new Document(
            Name = 'Test DOC1.txt',
            FolderId = UserInfo.getUserId(),
            Body = Blob.valueOf('ABCDEF')
        );
        insert doc1;

        Document doc2 = new Document(
            Name = 'Test DOC2.txt',
            FolderId = UserInfo.getUserId(),
            Body = Blob.valueOf('012345')
        );
        insert doc2;
    }

    @IsTest
    static void getPdfFilesAsBase64Test() {
        List<Document> documents = [
            SELECT Id, FolderId, Name, Type, Body, BodyLength
            FROM Document
            ORDER BY Name
        ];
        List<String> documentIds = new List<String>();
        for (Document doc : documents) {
            documentIds.add(doc.Id);
        }

        // Blob: "ABCDEF" => Base64Data: "QUJDREVG"
        // Blob: "012345" => Base64Data: "MDEyMzQ1"
        Set<String> expected = new Set<String>{
            EncodingUtil.base64Encode(Blob.valueOf('ABCDEF')),
            EncodingUtil.base64Encode(Blob.valueOf('012345'))
        };

        List<Map<String, String>> result = new List<Map<String, String>>();
        Test.startTest();
        result = MergePDFController.getPdfFilesAsBase64(documentIds);
        Test.stopTest();

        for (Map<String, String> docData : result) {
            String base64Data = docData.get('Base64Data');
            System.assert(expected.contains(base64Data), 'Should have Base64 encoded data');
        }
    }

    @IsTest
    static void savePdfFileAsBase64Test() {
        String documentName = 'SAVE Test.txt';
        String data = 'aaaaaa';
        String base64Data = EncodingUtil.base64Encode(Blob.valueOf(data));

        Test.startTest();
        MergePDFController.savePdfFileAsBase64(documentName, base64Data);
        Test.stopTest();

        List<Document> documents = [
            SELECT Id, FolderId, Name, Type, Body, BodyLength
            FROM Document
            WHERE Name LIKE :documentName
            ORDER BY Name
        ];

        System.assertEquals(1, documents.size(), 'Should have 1 document');
        System.assertEquals(6, documents[0].BodyLength, 'Should have 6 bytes');
        System.assertEquals(base64Data, EncodingUtil.base64Encode(documents[0].Body), 'Should have Base64 encoded data');
    }

}