const functions = require('firebase-functions');
const admin = require('firebase-admin');
const algoliasearch = require('algoliasearch');

// Initialize Firebase Admin
admin.initializeApp();

// Initialize Algolia
// IMPORTANT: Set these in Firebase Functions config
// Run: firebase functions:config:set algolia.app_id="B88BLR3WTX" algolia.admin_key="YOUR_ADMIN_KEY"
const algoliaClient = algoliasearch(
  functions.config().algolia.app_id,
  functions.config().algolia.admin_key
);
const algoliaIndex = algoliaClient.initIndex('products');

/**
 * Sync product to Algolia when created, updated, or deleted
 * Triggers on any write to products/{productId}
 */
exports.syncProductToAlgolia = functions.firestore
  .document('products/{productId}')
  .onWrite(async (change, context) => {
    const productId = context.params.productId;

    try {
      // Product was deleted
      if (!change.after.exists) {
        console.log(`Deleting product ${productId} from Algolia`);
        await algoliaIndex.deleteObject(productId);
        return null;
      }

      // Product was created or updated
      const product = change.after.data();

      // Only index approved products
      if (!product.isApproved) {
        console.log(`Product ${productId} not approved, skipping index`);
        // If it was previously approved and now unapproved, delete from Algolia
        if (change.before.exists && change.before.data().isApproved) {
          await algoliaIndex.deleteObject(productId);
        }
        return null;
      }

      // Prepare Algolia object
      const algoliaObject = {
        objectID: productId,
        title: product.title || '',
        description: product.description || '',
        price: product.price || 0,
        brand: product.brand || '',
        category: product.category || '',
        wilaya: product.wilaya || '',
        commune: product.commune || '',
        year: product.year || null,
        km: product.km || null,
        fuel: product.fuel || '',
        gearbox: product.gearbox || '',
        color: product.color || '',
        imageUrls: product.imageUrls || [],
        videoUrls: product.videoUrls || [],
        isBoosted: product.isBoosted || false,
        isApproved: product.isApproved || false,
        sellerId: product.sellerId || '',
        viewCount: product.viewCount || 0,
        createdAt: product.createdAt ? product.createdAt.toMillis() : Date.now(),
        
        // Add geo-location if available
        ...(product.latitude && product.longitude && {
          _geoloc: {
            lat: product.latitude,
            lng: product.longitude,
          },
        }),
      };

      console.log(`Indexing product ${productId} to Algolia`);
      await algoliaIndex.saveObject(algoliaObject);

      return null;
    } catch (error) {
      console.error(`Error syncing product ${productId} to Algolia:`, error);
      throw error;
    }
  });

/**
 * Bulk index all approved products to Algolia
 * Call this manually to migrate existing products
 * Usage: Call via Firebase Console or HTTP trigger
 */
exports.bulkIndexProductsToAlgolia = functions.https.onRequest(async (req, res) => {
  try {
    console.log('Starting bulk index of products to Algolia...');

    // Get all approved products
    const productsSnapshot = await admin.firestore()
      .collection('products')
      .where('isApproved', '==', true)
      .get();

    if (productsSnapshot.empty) {
      console.log('No approved products found');
      res.status(200).send({ message: 'No products to index', count: 0 });
      return;
    }

    // Prepare Algolia objects
    const algoliaObjects = [];
    productsSnapshot.forEach((doc) => {
      const product = doc.data();
      const productId = doc.id;

      algoliaObjects.push({
        objectID: productId,
        title: product.title || '',
        description: product.description || '',
        price: product.price || 0,
        brand: product.brand || '',
        category: product.category || '',
        wilaya: product.wilaya || '',
        commune: product.commune || '',
        year: product.year || null,
        km: product.km || null,
        fuel: product.fuel || '',
        gearbox: product.gearbox || '',
        color: product.color || '',
        imageUrls: product.imageUrls || [],
        videoUrls: product.videoUrls || [],
        isBoosted: product.isBoosted || false,
        isApproved: product.isApproved || false,
        sellerId: product.sellerId || '',
        viewCount: product.viewCount || 0,
        createdAt: product.createdAt ? product.createdAt.toMillis() : Date.now(),
        
        ...(product.latitude && product.longitude && {
          _geoloc: {
            lat: product.latitude,
            lng: product.longitude,
          },
        }),
      });
    });

    // Batch save to Algolia (max 1000 objects per batch)
    console.log(`Indexing ${algoliaObjects.length} products to Algolia...`);
    await algoliaIndex.saveObjects(algoliaObjects);

    console.log('Bulk index completed successfully');
    res.status(200).send({
      message: 'Products indexed successfully',
      count: algoliaObjects.length,
    });
  } catch (error) {
    console.error('Error during bulk index:', error);
    res.status(500).send({ error: error.message });
  }
});

/**
 * Clear all objects from Algolia index
 * Use with caution! This will delete all indexed products
 */
exports.clearAlgoliaIndex = functions.https.onRequest(async (req, res) => {
  try {
    // Add authentication check here in production!
    // Only allow admins to clear the index
    
    console.log('Clearing Algolia index...');
    await algoliaIndex.clearObjects();
    
    console.log('Algolia index cleared successfully');
    res.status(200).send({ message: 'Index cleared successfully' });
  } catch (error) {
    console.error('Error clearing index:', error);
    res.status(500).send({ error: error.message });
  }
});

/**
 * Get Algolia index statistics
 * Useful for monitoring
 */
exports.getAlgoliaStats = functions.https.onRequest(async (req, res) => {
  try {
    const settings = await algoliaIndex.getSettings();
    const stats = await algoliaIndex.search('', {
      hitsPerPage: 0,
      attributesToRetrieve: [],
    });

    res.status(200).send({
      indexName: 'products',
      totalRecords: stats.nbHits,
      settings: {
        searchableAttributes: settings.searchableAttributes,
        attributesForFaceting: settings.attributesForFaceting,
        customRanking: settings.customRanking,
      },
    });
  } catch (error) {
    console.error('Error getting stats:', error);
    res.status(500).send({ error: error.message });
  }
});
