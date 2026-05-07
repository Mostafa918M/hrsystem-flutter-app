const mongoose = require('mongoose');

async function checkTenant() {
  await mongoose.connect('mongodb://localhost:27017/hr_system');
  const db = mongoose.connection.db;
  const tenants = await db.collection('tenants').find({ slug: 'fairdirection' }).toArray();
  console.log(JSON.stringify(tenants, null, 2));
  process.exit(0);
}

checkTenant();
