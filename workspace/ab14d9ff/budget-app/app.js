const express = require('express');
const path = require('path');
const { initDb, db } = require('./db');

const app = express();

// View engine setup
app.set('view engine', 'ejs');
app.set('views', path.join(__dirname, 'views'));

// Static files
app.use(express.static(path.join(__dirname, 'public')));

// Body parser
app.use(express.urlencoded({ extended: true }));

// Dashboard route
app.get('/', (req, res) => {
  const month = req.query.month || new Date().toISOString().slice(0, 7);
  const dbInstance = db();

  // Summary
  const income = dbInstance.prepare(
    "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 'income' AND substr(date, 1, 7) = ?"
  ).get(month);
  const expense = dbInstance.prepare(
    "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 'expense' AND substr(date, 1, 7) = ?"
  ).get(month);

  // Recent transactions (last 10)
  const recentTransactions = dbInstance.prepare(
    'SELECT * FROM transactions ORDER BY date DESC, id DESC LIMIT 10'
  ).all();

  // Category breakdown for current month expenses
  const categoryBreakdown = dbInstance.prepare(`
    SELECT category, SUM(amount) as total
    FROM transactions
    WHERE type = 'expense' AND substr(date, 1, 7) = ?
    GROUP BY category
    ORDER BY total DESC
  `).all(month);

  // Budget progress
  const budgets = dbInstance.prepare('SELECT * FROM budgets WHERE month = ?').all(month);
  const budgetsWithProgress = budgets.map(b => {
    const spent = dbInstance.prepare(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE category = ? AND type = 'expense' AND substr(date, 1, 7) = ?"
    ).get(b.category, month);
    return { ...b, spent: spent.total, pct: b.limit > 0 ? Math.min(100, Math.round((spent.total / b.limit) * 100)) : 0 };
  });

  res.render('dashboard', {
    month,
    income: income.total,
    expense: expense.total,
    balance: income.total - expense.total,
    recentTransactions,
    categoryBreakdown,
    budgets: budgetsWithProgress
  });
});

// Reports page (HTML view)
app.get('/reports', (req, res) => {
  const month = req.query.month || new Date().toISOString().slice(0, 7);
  res.render('reports', { month });
});

// Initialize database BEFORE requiring routes
initDb();

// Routes
app.use('/transactions', require('./routes/transactions'));
app.use('/budgets', require('./routes/budgets'));
app.use('/api/reports', require('./routes/reports'));

const PORT = 3000;
app.listen(PORT, () => {
  console.log(`Budget Tracker app listening on http://localhost:${PORT}`);
});
