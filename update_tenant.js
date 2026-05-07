const mongoose = require('mongoose');

async function updateTenant() {
  await mongoose.connect('mongodb://localhost:27017/HrSystem');
  const db = mongoose.connection.db;
  const result = await db.collection('tenants').updateOne(
    { slug: 'fairdirection' },
    { $set: { staticQrToken: 'QR_fairdirection_yuq3ql5n' } }
  );
  console.log('Update result:', result);
  process.exit(0);
}

updateTenant();
