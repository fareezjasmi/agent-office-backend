const express = require('express');
const router = express.Router();

// Lazy db access — get the current db instance on each call
function db() {
  return require('../db').db();
}

// GET /transactions — list transactions (with optional filtering)
router.get('/', (req, res) => {
  const { month, category, type, sort } = req.query;
  let sql = 'SELECT * FROM transactions WHERE 1=1';
  const params = [];

  if (month) {
    sql += ' AND substr(date, 1, 7) = ?';
    params.push(month);
  }
  if (category) {
    sql += ' AND category = ?';
    params.push(category);
  }
  if (type) {
    sql += ' AND type = ?';
    params.push(type);
  }

  // Sort: default newest first
  const order = sort === 'oldest' ? 'ASC' : 'DESC';
  sql += ` ORDER BY date ${order}, id ${order}`;

  const transactions = db().prepare(sql).all(...params);

  // Also get all categories and current month for filter dropdowns
  const categories = db().prepare('SELECT DISTINCT category FROM transactions ORDER BY category').all();
  const currentMonth = month || new Date().toISOString().slice(0, 7);

  // Calculate summary
  const income = db().prepare("SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 'income' AND substr(date, 1, 7) = ?").get(currentMonth);
  const expense = db().prepare("SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 'expense' AND substr(date, 1, 7) = ?").get(currentMonth);

  res.render('transactions', {
    transactions,
    categories: categories.map(c => c.category),
    filters: { month: currentMonth, category: category || '', type: type || '' },
    summary: { income: income.total, expense: expense.total },
    currentMonth
  });
});

// GET /transactions/add — show add form
router.get('/add', (req, res) => {
  const categories = db().prepare('SELECT DISTINCT category FROM transactions ORDER BY category').all();
  res.render('add-transaction', {
    categories: categories.map(c => c.category),
    today: new Date().toISOString().slice(0, 10),
    editing: false,
    errors: [],
    transaction: null
  });
});

// POST /transactions — create a transaction
router.post('/', (req, res) => {
  const { type, category, amount, description, date } = req.body;

  const errors = [];
  if (!type || !['income', 'expense'].includes(type)) errors.push('Type must be income or expense');
  if (!category || category.trim() === '') errors.push('Category is required');
  if (!amount || isNaN(amount) || Number(amount) <= 0) errors.push('Amount must be a positive number');
  if (!date) errors.push('Date is required');

  if (errors.length > 0) {
    const categories = db().prepare('SELECT DISTINCT category FROM transactions ORDER BY category').all();
    return res.status(400).render('add-transaction', {
      errors,
      transaction: { type, category, amount, description, date },
      categories: categories.map(c => c.category),
      today: new Date().toISOString().slice(0, 10),
      editing: false
    });
  }

  db().prepare(
    'INSERT INTO transactions (type, category, amount, description, date) VALUES (?, ?, ?, ?, ?)'
  ).run(type, category.trim(), Number(amount), description || '', date);

  res.redirect('/transactions');
});

// POST /transactions/:id/delete — delete a transaction
router.post('/:id/delete', (req, res) => {
  db().prepare('DELETE FROM transactions WHERE id = ?').run(req.params.id);
  res.redirect('/transactions');
});

// GET /transactions/:id/edit — show edit form
router.get('/:id/edit', (req, res) => {
  const transaction = db().prepare('SELECT * FROM transactions WHERE id = ?').get(req.params.id);
  if (!transaction) return res.status(404).send('Transaction not found');

  const categories = db().prepare('SELECT DISTINCT category FROM transactions ORDER BY category').all();
  res.render('add-transaction', {
    transaction,
    categories: categories.map(c => c.category),
    editing: true,
    today: new Date().toISOString().slice(0, 10)
  });
});

// POST /transactions/:id — update a transaction
router.post('/:id', (req, res) => {
  const { type, category, amount, description, date } = req.body;

  const errors = [];
  if (!type || !['income', 'expense'].includes(type)) errors.push('Type must be income or expense');
  if (!category || category.trim() === '') errors.push('Category is required');
  if (!amount || isNaN(amount) || Number(amount) <= 0) errors.push('Amount must be a positive number');
  if (!date) errors.push('Date is required');

  if (errors.length > 0) {
    const categories = db().prepare('SELECT DISTINCT category FROM transactions ORDER BY category').all();
    return res.status(400).render('add-transaction', {
      errors,
      transaction: { id: req.params.id, type, category, amount, description, date },
      categories: categories.map(c => c.category),
      editing: true,
      today: new Date().toISOString().slice(0, 10)
    });
  }

  db().prepare(
    'UPDATE transactions SET type = ?, category = ?, amount = ?, description = ?, date = ? WHERE id = ?'
  ).run(type, category.trim(), Number(amount), description || '', date, req.params.id);

  res.redirect('/transactions');
});

module.exports = router;
