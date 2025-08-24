db.products.find().forEach(function(doc) {
  if (!doc.imageUrls || !Array.isArray(doc.imageUrls)) {
    print(`Skipping product ${doc._id}: No imageUrls or invalid format`);
    return;
  }
  
  let updatedImageUrls = doc.imageUrls.map(url => {
    // Skip if URL is already correct (contains product ID)
    if (url.includes(doc._id.toString())) {
      return url;
    }
    // Fix URLs missing the product ID (e.g., /uploads/filename.png)
    if (url.startsWith('/uploads/') && !url.includes(doc._id.toString())) {
      let filename = url.split('/').pop();
      return `/uploads/${doc._id}/${filename}`;
    }
    return url;
  });
  
  // Update only if changes are needed
  if (JSON.stringify(doc.imageUrls) !== JSON.stringify(updatedImageUrls)) {
    db.products.updateOne(
      { _id: doc._id },
      { $set: { imageUrls: updatedImageUrls } }
    );
    print(`Updated imageUrls for product ${doc._id}: ${updatedImageUrls}`);
  } else {
    print(`No changes needed for product ${doc._id}`);
  }
});