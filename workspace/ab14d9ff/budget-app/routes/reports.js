const express = require('express');
const router = express.Router();

// Lazy db access — get the current db instance on each call
function db() {
  return require('../db').db();
}

// GET /api/reports/monthly?month=2026-07 — monthly summary
router.get('/monthly', (req, res) => {
  const month = req.query.month || new Date().toISOString().slice(0, 7);

  const income = db().prepare(
    "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 'income' AND substr(date, 1, 7) = ?"
  ).get(month);

  const expense = db().prepare(
    "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE type = 'expense' AND substr(date, 1, 7) = ?"
  ).get(month);

  // Daily totals for the month (for trend chart)
  const dailyTotals = db().prepare(`
    SELECT date,
           SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as income,
           SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) as expense
    FROM transactions
    WHERE substr(date, 1, 7) = ?
    GROUP BY date
    ORDER BY date
  `).all(month);

  res.json({
    month,
    income: income.total,
    expense: expense.total,
    balance: income.total - expense.total,
    dailyTotals
  });
});

// GET /api/reports/categories?month=2026-07 — category breakdown
router.get('/categories', (req, res) => {
  const month = req.query.month || new Date().toISOString().slice(0, 7);
  const type = req.query.type || 'expense';

  const breakdown = db().prepare(`
    SELECT category, SUM(amount) as total, COUNT(*) as count
    FROM transactions
    WHERE type = ? AND substr(date, 1, 7) = ?
    GROUP BY category
    ORDER BY total DESC
  `).all(type, month);

  const grandTotal = breakdown.reduce((sum, row) => sum + row.total, 0);

  res.json({
    month,
    type,
    breakdown: breakdown.map(row => ({
      ...row,
      percentage: grandTotal > 0 ? Math.round((row.total / grandTotal) * 100) : 0
    })),
    grandTotal
  });
});

// GET /api/reports/trends?months=6 — multi-month trends (last N months)
router.get('/trends', (req, res) => {
  const months = parseInt(req.query.months) || 6;

  const monthlyData = db().prepare(`
    SELECT substr(date, 1, 7) as month,
           SUM(CASE WHEN type = 'income' THEN amount ELSE 0 END) as income,
           SUM(CASE WHEN type = 'expense' THEN amount ELSE 0 END) as expense
    FROM transactions
    GROUP BY substr(date, 1, 7)
    ORDER BY month DESC
    LIMIT ?
  `).all(months);

  res.json({
    months: monthlyData.map(row => ({
      ...row,
      balance: row.income - row.expense
    }))
  });
});

module.exports = router;
