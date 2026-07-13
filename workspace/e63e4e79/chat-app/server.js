const express = require('express');
const http = require('http');
const { WebSocketServer } = require('ws');

const app = express();
app.use(express.static('public'));

const server = http.createServer(app);
const wss = new WebSocketServer({ server });

let clientIdCounter = 1;

wss.on('connection', (ws) => {
  const clientId = clientIdCounter++;
  console.log(`Client connected (User ${clientId})`);

  // Send welcome message
  ws.send(JSON.stringify({ type: 'system', text: 'Welcome to the chat!' }));

  ws.on('message', (data) => {
    try {
      const message = JSON.parse(data.toString());
      if (message.type === 'chat' && message.text) {
        const broadcast = JSON.stringify({
          type: 'chat',
          text: message.text,
          sender: `User ${clientId}`
        });

        // Broadcast to all OTHER clients, not back to the sender
        wss.clients.forEach((client) => {
          if (client !== ws && client.readyState === client.OPEN) {
            client.send(broadcast);
          }
        });
      }
    } catch (err) {
      console.error('Invalid message received:', err.message);
    }
  });

  ws.on('close', () => {
    console.log(`Client disconnected (User ${clientId})`);
  });
});

server.listen(3000, () => {
  console.log('Chat server running on http://localhost:3000');
});
