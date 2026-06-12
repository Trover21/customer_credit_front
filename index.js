
require('dotenv').config();
const express = require('express');
const mongoose = require('mongoose');
const cors = require('cors');
const app = express();

app.use(cors());
app.use(express.json());

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

  transactions: [transactionSchema]
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
app.post('/add-customer', async (req, res) => {
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
app.get('/customers', async (req, res) => {
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
app.patch('/update-customer/:id', async (req, res) => {
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
app.delete('/delete-customer/:id', async (req, res) => {
  try {
    await Customer.findByIdAndDelete(req.params.id);

    res.json({
      message: "Customer deleted"
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
app.post('/add-item/:id', async (req, res) => {
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
app.post('/payment/:id', async (req, res) => {
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
app.delete('/delete-transaction/:customerId/:transactionId', async (req, res) => {
  try {
    const customer = await Customer.findById(req.params.customerId);
    if (!customer) {
      return res.status(404).send("Customer not found");
    }

    const tx = customer.transactions.id(req.params.transactionId);
    if (!tx) {
      return res.status(404).send("Transaction not found");
    }

    // Revert the totalCredit amount
    if (tx.isPayment) {
      customer.totalCredit += tx.total;
    } else {
      customer.totalCredit -= tx.total;
    }

    // Remove the subdocument transaction
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

