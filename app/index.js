const express = require('express');
const app = express();
const port = process.env.PORT || 3000;

app.get('/health', (req, res) => {
  res.send('✅ I am healthy!');
});

// Example PATCH point
app.get('/', (req, res) => {
  res.send('👋 Hello from ECS! This is the patched version.');
});

app.listen(port, () => {
  console.log(`Server running on port ${port}`);
});
