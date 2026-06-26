const path = require('path');
require('dotenv').config({ path: path.join(__dirname, '.env') });
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

app.get('/health', (req, res) => {
  res.json({ status: 'ok', version: '1.0.1' });
});

const authRoutes = require('./routes/authRoutes');
const { protect, adminOrApprovedOnly } = require('./middleware/authMiddleware');

app.use('/api/auth', authRoutes);

/* ============================
   Transaction Schema
============================ */
const transactionSchema = new mongoose.Schema({
  item: String,
  qty: Number,
  price: Number,
  total: Number,
  isPayment: Boolean,
  date: {
    type: Date,
    default: Date.now
  },
  isDeleted: {
    type: Boolean,
    default: false
  }
});

/* ============================
   Customer Schema
============================ */
const customerSchema = new mongoose.Schema({
  name: {
    type: String,
    required: true
  },

  phone: {
    type: String,
    required: true
  },

  telegramChatId: {
    type: String,
    default: "0"
  },

  maxCreditLimit: {
    type: Number,
    default: 0
  },

  totalCredit: {
    type: Number,
    default: 0
  },

  transactions: [transactionSchema],

  isDeleted: {
    type: Boolean,
    default: false
  }
});

const Customer = mongoose.model('Customer', customerSchema);

/* ============================
   MongoDB Connection
============================ */
const uri = process.env.MONGO_URI;

mongoose.connect(uri)
  .then(() => {
    console.log("MongoDB Connected Successfully!");
  })
  .catch((err) => {
    console.log("MongoDB Error:", err);
  });

/* ============================
   1. ADD CUSTOMER
============================ */
app.post('/add-customer', protect, adminOrApprovedOnly, async (req, res) => {
  try {
    const customer = new Customer(req.body);

    await customer.save();

    res.status(201).json(customer);
  } catch (error) {
    res.status(500).json({
      error: error.message
    });
  }
});

/* ============================
   2. FETCH ALL CUSTOMERS
============================ */
app.get('/customers', protect, adminOrApprovedOnly, async (req, res) => {
  try {
    const customers = await Customer.find();

    res.json(customers);
  } catch (error) {
    res.status(500).json({
      error: error.message
    });
  }
});

/* ============================
   3. UPDATE CUSTOMER
============================ */
app.patch('/update-customer/:id', protect, adminOrApprovedOnly, async (req, res) => {
  try {
    const updatedCustomer =
      await Customer.findByIdAndUpdate(
        req.params.id,
        req.body,
        { new: true }
      );

    res.json(updatedCustomer);
  } catch (error) {
    res.status(500).json({
      error: error.message
    });
  }
});

/* ============================
   4. DELETE CUSTOMER
============================ */
app.delete('/delete-customer/:id', protect, adminOrApprovedOnly, async (req, res) => {
  try {
    await Customer.findByIdAndUpdate(
      req.params.id,
      { isDeleted: true },
      { new: true }
    );

    res.json({
      message: "Customer moved to recycle bin"
    });
  } catch (error) {
    res.status(500).json({
      error: error.message
    });
  }
});

/* ============================
   4.1 PERMANENT DELETE CUSTOMER
============================ */
app.delete('/permanent-delete-customer/:id', protect, adminOrApprovedOnly, async (req, res) => {
  try {
    await Customer.findByIdAndDelete(req.params.id);

    res.json({
      message: "Customer permanently deleted"
    });
  } catch (error) {
    res.status(500).json({
      error: error.message
    });
  }
});

/* ============================
   5. ADD ITEM (DEBT)
============================ */
app.post('/add-item/:id', protect, adminOrApprovedOnly, async (req, res) => {
  try {
    const customer = await Customer.findById(req.params.id);

    if (!customer) {
      return res.status(404).send("Customer not found");
    }

    const tx = req.body;

    // transaction list create if missing
    if (!customer.transactions) {
      customer.transactions = [];
    }

    customer.transactions.unshift(tx);

    // update debt
    if (tx.isPayment) {
      customer.totalCredit -= tx.total;
    } else {
      customer.totalCredit += tx.total;
    }

    await customer.save();

    res.status(200).json(customer);
  } catch (e) {
    res.status(500).send(e.message);
  }
});

/* ============================
   6. PAYMENT
============================ */
app.post('/payment/:id', protect, adminOrApprovedOnly, async (req, res) => {
  try {
    const customer =
      await Customer.findById(req.params.id);

    if (!customer) {
      return res.status(404).send("Customer not found");
    }

    customer.transactions.unshift(req.body);

    customer.totalCredit -= req.body.total;

    await customer.save();

    res.json(customer);

  } catch (error) {
    res.status(500).json({
      error: error.message
    });
  }
});

/* ============================
   7. DELETE TRANSACTION
============================ */
app.delete('/delete-transaction/:customerId/:transactionId', protect, adminOrApprovedOnly, async (req, res) => {
  try {
    const customer = await Customer.findById(req.params.customerId);
    if (!customer) {
      return res.status(404).send("Customer not found");
    }

    const tx = customer.transactions.id(req.params.transactionId);
    if (!tx) {
      return res.status(404).send("Transaction not found");
    }

    if (tx.isDeleted) {
      return res.status(400).send("Transaction already deleted");
    }

    tx.isDeleted = true;

    // Revert the totalCredit amount
    if (tx.isPayment) {
      customer.totalCredit += tx.total;
    } else {
      customer.totalCredit -= tx.total;
    }

    await customer.save();

    res.json(customer);
  } catch (error) {
    res.status(500).json({
      error: error.message
    });
  }
});

/* ============================
   7.1 RESTORE TRANSACTION
============================ */
app.post('/restore-transaction/:customerId/:transactionId', protect, adminOrApprovedOnly, async (req, res) => {
  try {
    const customer = await Customer.findById(req.params.customerId);
    if (!customer) {
      return res.status(404).send("Customer not found");
    }

    const tx = customer.transactions.id(req.params.transactionId);
    if (!tx) {
      return res.status(404).send("Transaction not found");
    }

    if (!tx.isDeleted) {
      return res.status(400).send("Transaction is not deleted");
    }

    tx.isDeleted = false;

    // Re-apply the totalCredit amount
    if (tx.isPayment) {
      customer.totalCredit -= tx.total;
    } else {
      customer.totalCredit += tx.total;
    }

    await customer.save();

    res.json(customer);
  } catch (error) {
    res.status(500).json({
      error: error.message
    });
  }
});

/* ============================
   7.2 PERMANENT DELETE TRANSACTION
============================ */
app.delete('/permanent-delete-transaction/:customerId/:transactionId', protect, adminOrApprovedOnly, async (req, res) => {
  try {
    const customer = await Customer.findById(req.params.customerId);
    if (!customer) {
      return res.status(404).send("Customer not found");
    }

    const tx = customer.transactions.id(req.params.transactionId);
    if (!tx) {
      return res.status(404).send("Transaction not found");
    }

    // Since it was soft-deleted, credit was already reverted.
    // Just pull it out of array.
    customer.transactions.pull(tx._id);
    await customer.save();

    res.json(customer);
  } catch (error) {
    res.status(500).json({
      error: error.message
    });
  }
});

/* ============================
   SERVER
============================ */
const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`Server running on port ${PORT}`);
});
