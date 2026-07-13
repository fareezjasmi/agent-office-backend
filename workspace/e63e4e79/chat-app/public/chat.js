(() => {
  const messagesEl = document.getElementById('messages');
  const formEl = document.getElementById('chat-form');
  const inputEl = document.getElementById('message-input');

  // ------------------------------------------------------------------
  // WebSocket connection
  // ------------------------------------------------------------------
  const socket = new WebSocket('ws://localhost:3000');

  socket.addEventListener('open', () => {
    console.log('Connected to chat server');
  });

  socket.addEventListener('message', (event) => {
    try {
      const message = JSON.parse(event.data);

      if (message.type === 'system') {
        addSystemMessage(message.text || message.message || '');
      } else if (message.type === 'chat') {
        const sender = message.sender || 'Unknown';
        const text = message.text || '';
        const isSelf = sender === 'You';
        addChatMessage(sender, text, isSelf);
      }
    } catch (err) {
      console.error('Failed to parse message:', err);
    }
  });

  socket.addEventListener('error', (err) => {
    console.error('WebSocket error:', err);
  });

  socket.addEventListener('close', (event) => {
    console.log('WebSocket closed:', event.code, event.reason);
  });

  // ------------------------------------------------------------------
  // Form submit — send message
  // ------------------------------------------------------------------
  formEl.addEventListener('submit', (e) => {
    e.preventDefault();

    const text = inputEl.value.trim();
    if (!text) return;

    // Send over WebSocket
    socket.send(JSON.stringify({ type: 'chat', text }));

    // Optimistically add as self message
    addChatMessage('You', text, true);

    // Clear input
    inputEl.value = '';
    inputEl.focus();
  });

  // ------------------------------------------------------------------
  // Helpers
  // ------------------------------------------------------------------

  function addSystemMessage(text) {
    if (!text) return;

    const div = document.createElement('div');
    div.className = 'message system';
    div.textContent = text;
    messagesEl.appendChild(div);
    scrollToBottom();
  }

  function addChatMessage(sender, text, isSelf) {
    if (!text) return;

    const div = document.createElement('div');
    div.className = 'message';

    if (isSelf) {
      div.classList.add('self');
    }

    // Sender name (bold)
    const senderSpan = document.createElement('div');
    senderSpan.className = 'sender';
    senderSpan.textContent = sender;

    // Message text
    const textSpan = document.createElement('div');
    textSpan.textContent = text;

    div.appendChild(senderSpan);
    div.appendChild(textSpan);
    messagesEl.appendChild(div);
    scrollToBottom();
  }

  function scrollToBottom() {
    messagesEl.scrollTop = messagesEl.scrollHeight;
  }
})();
