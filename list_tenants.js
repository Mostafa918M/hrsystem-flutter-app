const mongoose = require('mongoose');

async function checkTenants() {
  await mongoose.connect('mongodb://localhost:27017/HrSystem');
  const db = mongoose.connection.db;
  const tenants = await db.collection('tenants').find({}).toArray();
  console.log(JSON.stringify(tenants, null, 2));
  process.exit(0);
}

checkTenants();
