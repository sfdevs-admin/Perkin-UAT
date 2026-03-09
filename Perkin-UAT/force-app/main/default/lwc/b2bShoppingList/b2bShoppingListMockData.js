const mockData = [
  {
    Id: 'a001a000001XyzA',
    B2B_Name__c: 'Summer Favorites'
  },
  {
    Id: 'a001a000001XyzB',
    B2B_Name__c: 'Office Essentials'
  }
];

const mockListItemsMap = {
  a001a000001XyzA: [
    {
      id: 'a101a000002Pqrs',
      productId: '01t1a000001X123',
      // productId: '01tbc000004l5EgAAI',
      productName: 'Stainless Water Bottle',
      sku: 'N9306534',
      description: 'Supra-Clean<sup>®</sup> Silica (SI-S) SPE columns are packed with bare silica.',
      price: 693.36,
      quantity: 1
    },
    {
      id: 'a101a000002Pqrt',
      // productId: '01t1a000001X124',
      productId: '01tbc000004l5EgAAI',
      productName: 'Sunblock Lotion SPF 50',
      sku: 'N9306000',
      description: 'Supra-Clean® Silica (SI-S) SPE columns are pack...',
      price: 400.36,
      quantity: 10
    }
  ],
  a001a000001XyzB: [
    {
      id: 'a101a000002Pqru',
      productId: '01t1a000001X125',
      productName: 'Desk Organizer',
      sku: 'N93022222',
      description: 'Supra-Clean® Silica (SI-S) SPE columns are pack...',
      price: 100.36,
      quantity: 1
    }
  ]
};

export {
    mockData,
    mockListItemsMap
};