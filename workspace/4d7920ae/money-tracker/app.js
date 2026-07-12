// ===== STORAGE =====

const STORAGE_KEY = 'money-tracker-transactions';

function getTransactions() {
  try {
    const data = localStorage.getItem(STORAGE_KEY);
    return data ? JSON.parse(data) : [];
  } catch {
    return [];
  }
}

function saveTransactions(transactions) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(transactions));
}

// ===== STATE =====

let transactions = [];
let currentFilter = {
  search: '',
  type: 'all',
  category: 'all',
  sort: 'newest'
};

// ===== CATEGORIES =====

const CATEGORIES = {
  expense: ['Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 'Health', 'Other'],
  income: ['Salary', 'Freelance', 'Investment', 'Gift', 'Refund', 'Other']
};

const ALL_CATEGORIES = [...new Set([...CATEGORIES.expense, ...CATEGORIES.income])];

// ===== DOM REFS =====

const $ = (sel) => document.querySelector(sel);
const $$ = (sel) => document.querySelectorAll(sel);

const form = $('#transaction-form');
const descInput = $('#description');
const amountInput = $('#amount');
const typeSelect = $('#type');
const categorySelect = $('#category');
const dateInput = $('#date');
const searchInput = $('#search-input');
const filterType = $('#filter-type');
const filterCategory = $('#filter-category');
const sortOrder = $('#sort-order');
const transactionsContainer = $('#transactions-container');
const totalBalanceEl = $('#total-balance');
const totalIncomeEl = $('#total-income');
const totalExpensesEl = $('#total-expenses');
const chartEmpty = $('#chart-empty');

// ===== FORMATTING HELPERS =====

function formatCurrency(amount) {
  if (amount < 0) {
    return '-$' + Math.abs(amount).toFixed(2);
  }
  return '$' + amount.toFixed(2);
}

function formatDate(dateString) {
  const date = new Date(dateString + 'T00:00:00');
  return date.toLocaleDateString('en-US', { month: 'short', day: 'numeric', year: 'numeric' });
}

function generateId() {
  return Date.now().toString(36) + '-' + Math.random().toString(36).substring(2, 9);
}

// ===== CATEGORY DROPDOWN =====

function updateCategoryOptions(type) {
  const categories = CATEGORIES[type] || CATEGORIES.expense;
  categorySelect.innerHTML = '';
  categories.forEach(cat => {
    const opt = document.createElement('option');
    opt.value = cat;
    opt.textContent = cat;
    categorySelect.appendChild(opt);
  });
}

function populateFilterCategoryDropdown() {
  filterCategory.innerHTML = '<option value="all">All Categories</option>';
  ALL_CATEGORIES.forEach(cat => {
    const opt = document.createElement('option');
    opt.value = cat;
    opt.textContent = cat;
    filterCategory.appendChild(opt);
  });
}

// ===== CRUD =====

function addTransaction(transaction) {
  const newTransaction = {
    id: generateId(),
    description: transaction.description.trim(),
    amount: parseFloat(transaction.amount),
    type: transaction.type,
    category: transaction.category,
    date: transaction.date
  };
  transactions.push(newTransaction);
  saveTransactions(transactions);
  render();
}

function deleteTransaction(id) {
  transactions = transactions.filter(t => t.id !== id);
  saveTransactions(transactions);
  render();
}

// ===== FILTERING & SORTING =====

function getFilteredTransactions() {
  let filtered = [...transactions];

  // Search filter
  if (currentFilter.search) {
    const query = currentFilter.search.toLowerCase();
    filtered = filtered.filter(t =>
      t.description.toLowerCase().includes(query) ||
      t.category.toLowerCase().includes(query)
    );
  }

  // Type filter
  if (currentFilter.type !== 'all') {
    filtered = filtered.filter(t => t.type === currentFilter.type);
  }

  // Category filter
  if (currentFilter.category !== 'all') {
    filtered = filtered.filter(t => t.category === currentFilter.category);
  }

  // Sort
  switch (currentFilter.sort) {
    case 'newest':
      filtered.sort((a, b) => b.date.localeCompare(a.date) || b.id.localeCompare(a.id));
      break;
    case 'oldest':
      filtered.sort((a, b) => a.date.localeCompare(b.date) || a.id.localeCompare(b.id));
      break;
    case 'highest':
      filtered.sort((a, b) => b.amount - a.amount);
      break;
    case 'lowest':
      filtered.sort((a, b) => a.amount - b.amount);
      break;
  }

  return filtered;
}

// ===== SUMMARY =====

function updateSummary() {
  const totalIncome = transactions
    .filter(t => t.type === 'income')
    .reduce((sum, t) => sum + t.amount, 0);

  const totalExpenses = transactions
    .filter(t => t.type === 'expense')
    .reduce((sum, t) => sum + t.amount, 0);

  const balance = totalIncome - totalExpenses;

  totalBalanceEl.textContent = formatCurrency(balance);
  totalIncomeEl.textContent = formatCurrency(totalIncome);
  totalExpensesEl.textContent = formatCurrency(totalExpenses);
}

// ===== RENDER =====

function renderTransactionList() {
  const filtered = getFilteredTransactions();

  if (filtered.length === 0) {
    const noResults = transactions.length === 0
      ? 'No transactions yet. Add your first one above!'
      : 'No transactions match your filters.';
    transactionsContainer.innerHTML = `<p class="empty-state">${noResults}</p>`;
    return;
  }

  transactionsContainer.innerHTML = '';

  filtered.forEach(t => {
    const item = document.createElement('div');
    item.className = `transaction-item ${t.type}`;

    const sign = t.type === 'income' ? '+' : '-';

    item.innerHTML = `
      <span class="transaction-icon ${t.type}"></span>
      <div class="transaction-info">
        <div class="transaction-description">${escapeHtml(t.description)}</div>
        <div class="transaction-meta">
          <span class="category-badge">${escapeHtml(t.category)}</span>
          <span>${formatDate(t.date)}</span>
        </div>
      </div>
      <span class="transaction-amount ${t.type}">${sign}${formatCurrency(t.amount)}</span>
      <button class="btn-delete" data-id="${t.id}" aria-label="Delete transaction">&times;</button>
    `;

    transactionsContainer.appendChild(item);
  });

  // Attach delete handlers
  document.querySelectorAll('.btn-delete').forEach(btn => {
    btn.addEventListener('click', (e) => {
      const id = e.currentTarget.getAttribute('data-id');
      deleteTransaction(id);
    });
  });
}

function escapeHtml(text) {
  const div = document.createElement('div');
  div.textContent = text;
  return div.innerHTML;
}

function updateChartVisibility() {
  const hasTransactions = transactions.length > 0;
  chartEmpty.style.display = hasTransactions ? 'none' : 'block';
  const canvas = $('#categoryChart');
  if (canvas) {
    canvas.style.display = hasTransactions ? 'block' : 'none';
  }
}

function render() {
  updateSummary();
  renderTransactionList();
  updateChartVisibility();
}

// ===== EVENT LISTENERS =====

// Form submit
form.addEventListener('submit', (e) => {
  e.preventDefault();

  const description = descInput.value.trim();
  const amount = parseFloat(amountInput.value);
  const type = typeSelect.value;
  const category = categorySelect.value;
  const date = dateInput.value;

  if (!description) {
    alert('Please enter a description.');
    return;
  }

  if (!amount || amount <= 0) {
    alert('Please enter a valid amount greater than 0.');
    return;
  }

  if (!date) {
    alert('Please select a date.');
    return;
  }

  addTransaction({ description, amount, type, category, date });

  form.reset();
  // Reset category dropdown based on current type
  updateCategoryOptions(typeSelect.value);
  // Reset date to today
  setTodayDate();
  descInput.focus();
});

// Type change updates category dropdown
typeSelect.addEventListener('change', () => {
  updateCategoryOptions(typeSelect.value);
});

// Search input
searchInput.addEventListener('input', () => {
  currentFilter.search = searchInput.value;
  renderTransactionList();
});

// Filter type
filterType.addEventListener('change', () => {
  currentFilter.type = filterType.value;
  renderTransactionList();
});

// Filter category
filterCategory.addEventListener('change', () => {
  currentFilter.category = filterCategory.value;
  renderTransactionList();
});

// Sort order
sortOrder.addEventListener('change', () => {
  currentFilter.sort = sortOrder.value;
  renderTransactionList();
});

// ===== INIT =====

function setTodayDate() {
  const today = new Date();
  const year = today.getFullYear();
  const month = String(today.getMonth() + 1).padStart(2, '0');
  const day = String(today.getDate()).padStart(2, '0');
  dateInput.value = `${year}-${month}-${day}`;
}

function init() {
  transactions = getTransactions();
  setTodayDate();
  updateCategoryOptions(typeSelect.value);
  populateFilterCategoryDropdown();
  render();
}

document.addEventListener('DOMContentLoaded', init);
