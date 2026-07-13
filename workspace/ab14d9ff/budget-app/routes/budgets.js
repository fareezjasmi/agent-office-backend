const express = require('express');
const router = express.Router();

// Lazy db access — get the current db instance on each call
function db() {
  return require('../db').db();
}

// GET /budgets — list budgets with spending progress
router.get('/', (req, res) => {
  const month = req.query.month || new Date().toISOString().slice(0, 7);

  const budgets = db().prepare('SELECT * FROM budgets WHERE month = ? ORDER BY category').all(month);

  // For each budget, calculate how much has been spent
  const budgetsWithSpending = budgets.map(budget => {
    const spent = db().prepare(
      "SELECT COALESCE(SUM(amount), 0) as total FROM transactions WHERE category = ? AND type = 'expense' AND substr(date, 1, 7) = ?"
    ).get(budget.category, month);

    return {
      ...budget,
      spent: spent.total,
      remaining: budget.limit - spent.total,
      percentage: budget.limit > 0 ? Math.min(100, Math.round((spent.total / budget.limit) * 100)) : 0
    };
  });

  // Get all categories that have expenses this month (for suggesting new budgets)
  const activeCategories = db().prepare(
    "SELECT DISTINCT category FROM transactions WHERE type = 'expense' AND substr(date, 1, 7) = ? ORDER BY category"
  ).all(month);

  res.render('budgets', {
    budgets: budgetsWithSpending,
    activeCategories: activeCategories.map(c => c.category),
    currentMonth: month
  });
});

// POST /budgets — create or update a budget
router.post('/', (req, res) => {
  const { category, limit, month } = req.body;

  const errors = [];
  if (!category || category.trim() === '') errors.push('Category is required');
  if (!limit || isNaN(limit) || Number(limit) <= 0) errors.push('Budget limit must be a positive number');

  const targetMonth = month || new Date().toISOString().slice(0, 7);

  if (errors.length > 0) {
    const errorMsg = encodeURIComponent(errors.join(', '));
    return res.redirect(`/budgets?month=${targetMonth}&error=${errorMsg}`);
  }

  // Upsert: insert or update if exists
  const existing = db().prepare('SELECT id FROM budgets WHERE category = ? AND month = ?').get(category.trim(), targetMonth);

  if (existing) {
    db().prepare('UPDATE budgets SET "limit" = ? WHERE id = ?').run(Number(limit), existing.id);
  } else {
    db().prepare('INSERT INTO budgets (category, "limit", month) VALUES (?, ?, ?)').run(category.trim(), Number(limit), targetMonth);
  }

  res.redirect('/budgets?month=' + targetMonth);
});

// POST /budgets/:id/delete — delete a budget
router.post('/:id/delete', (req, res) => {
  const budget = db().prepare('SELECT month FROM budgets WHERE id = ?').get(req.params.id);
  const month = budget ? budget.month : new Date().toISOString().slice(0, 7);
  db().prepare('DELETE FROM budgets WHERE id = ?').run(req.params.id);
  res.redirect('/budgets?month=' + month);
});

module.exports = router;
