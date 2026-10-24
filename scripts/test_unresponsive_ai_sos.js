// Headless browser validation for AI Voice Unresponsive Crash SOS feature
const http = require('http');
const fs = require('fs');
const path = require('path');
const { spawn } = require('child_process');

// 1. Simple HTTP server for preview/
const PREVIEW_DIR = path.resolve(__dirname, '../preview');
const server = http.createServer((req, res) => {
  let filePath = path.join(PREVIEW_DIR, req.url === '/' ? 'index.html' : req.url.split('?')[0]);
  fs.readFile(filePath, (err, data) => {
    if (err) {
      res.writeHead(404);
      res.end('Not found');
      return;
    }
    const ext = path.extname(filePath);
    const mimeTypes = {
      '.html': 'text/html',
      '.js': 'application/javascript',
      '.css': 'text/css',
      '.json': 'application/json',
      '.png': 'image/png',
      '.jpg': 'image/jpeg',
      '.svg': 'image/svg+xml'
    };
    res.writeHead(200, { 'Content-Type': mimeTypes[ext] || 'text/plain' });
    res.end(data);
  });
});

async function getJson(url) {
  return new Promise((resolve, reject) => {
    http.get(url, (res) => {
      let data = '';
      res.on('data', chunk => data += chunk);
      res.on('end', () => resolve(JSON.parse(data)));
    }).on('error', reject);
  });
}

class CDPClient {
  constructor(wsUrl) {
    this.ws = new WebSocket(wsUrl);
    this.msgId = 0;
    this.pending = new Map();
    this.logs = [];
    this.errors = [];

    this.ws.onmessage = (event) => {
      const msg = JSON.parse(event.data);
      if (msg.id && this.pending.has(msg.id)) {
        const { resolve, reject } = this.pending.get(msg.id);
        this.pending.delete(msg.id);
        if (msg.error) reject(msg.error);
        else resolve(msg.result);
      } else if (msg.method === 'Runtime.consoleAPICalled') {
        const text = msg.params.args.map(a => a.value || a.description || '').join(' ');
        this.logs.push(`[${msg.params.type}] ${text}`);
      } else if (msg.method === 'Runtime.exceptionThrown') {
        const desc = msg.params.exceptionDetails.exception?.description || msg.params.exceptionDetails.text;
        this.errors.push(desc);
      }
    };
  }

  async ready() {
    if (this.ws.readyState === WebSocket.OPEN) return;
    return new Promise(resolve => { this.ws.onopen = resolve; });
  }

  send(method, params = {}) {
    return new Promise((resolve, reject) => {
      const id = ++this.msgId;
      this.pending.set(id, { resolve, reject });
      this.ws.send(JSON.stringify({ id, method, params }));
    });
  }

  async eval(expr) {
    const res = await this.send('Runtime.evaluate', { expression: expr, returnByValue: true, awaitPromise: true });
    if (res.exceptionDetails) {
      throw new Error(res.exceptionDetails.exception?.description || res.exceptionDetails.text);
    }
    return res.result?.value;
  }

  async screenshot(filename) {
    const res = await this.send('Page.captureScreenshot', { format: 'png' });
    fs.writeFileSync(filename, Buffer.from(res.data, 'base64'));
    console.log(`  📸 Screenshot saved: ${filename}`);
  }
}

async function run() {
  await new Promise(r => server.listen(3456, r));
  console.log('🌐 Local preview server running on port 3456');

  console.log('🚀 Spawning headless Chrome on port 9223...');
  const chrome = spawn('google-chrome', [
    '--headless=new',
    '--no-sandbox',
    '--disable-gpu',
    '--window-size=1200,900',
    '--remote-debugging-port=9223',
    'http://127.0.0.1:3456/'
  ]);

  try {
    let targets = null;
    for (let i = 0; i < 20; i++) {
      await new Promise(r => setTimeout(r, 250));
      try {
        targets = await getJson('http://127.0.0.1:9223/json');
        if (targets && targets.length > 0) break;
      } catch (e) {}
    }

    if (!targets || targets.length === 0) throw new Error('Could not connect to Chrome CDP');

    const pageTarget = targets.find(t => t.type === 'page') || targets[0];
    const client = new CDPClient(pageTarget.webSocketDebuggerUrl);
    await client.ready();
    await client.send('Page.enable');
    await client.send('Runtime.enable');
    await client.send('DOM.enable');

    console.log('✅ Connected to Page. Checking window.app initialization...');
    await new Promise(r => setTimeout(r, 1200));

    // Navigate to SOS Screen
    await client.eval("window.app.switchScreen('sos')");
    console.log('📱 Navigated to SOS Cockpit screen');

    // Verify trigger button exists
    const crashBtnText = await client.eval("document.getElementById('btn-simulate-crash-sos').textContent");
    console.log(`🔘 Crash button found: "${crashBtnText.replace(/\\s+/g, ' ').trim()}"`);

    // Trigger Major Crash
    console.log('\n💥 Triggering Major Crash Simulation...');
    await client.eval("document.getElementById('btn-simulate-crash-sos').click()");

    // Check that vocal challenge banner is visible
    const isBannerVisible = await client.eval("document.getElementById('sos-voice-challenge-banner').style.display !== 'none'");
    const secondsInitial = await client.eval("document.getElementById('sos-countdown-val').textContent");
    console.log(`📢 Vocal Challenge Banner Visible: ${isBannerVisible}`);
    console.log(`⏱️ Initial Countdown Seconds: ${secondsInitial}`);

    if (!isBannerVisible) throw new Error('Vocal challenge banner did not display!');

    // Take screenshot during 10s countdown
    await client.screenshot('preview/assets/screenshots/ai_voice_crash_countdown.png');

    // Wait for the 10s countdown to complete without response (unresponsive test)
    console.log('\n⏳ Waiting 11 seconds for rider unresponsiveness timeout...');
    await new Promise(r => setTimeout(r, 11000));

    // Check unresponsive panel and call cards
    const isUnresponsivePanelVisible = await client.eval("document.getElementById('sos-unresponsive-panel').style.display !== 'none'");
    const transcriptText = await client.eval("document.getElementById('sos-live-ai-transcript').textContent");
    const countdownValFinal = await client.eval("document.getElementById('sos-countdown-val').textContent");

    console.log(`🚨 Unresponsive Panel Visible: ${isUnresponsivePanelVisible}`);
    console.log(`📞 Countdown Final State: "${countdownValFinal}"`);
    console.log(`🎙️ Spoken Transcript: "${transcriptText.substring(0, 90)}..."`);

    if (!isUnresponsivePanelVisible) throw new Error('Unresponsive panel failed to appear!');
    if (!transcriptText.includes('UNRESPONSIVE')) throw new Error('Transcript does not mention UNRESPONSIVE!');

    // Take screenshot of unresponsive dispatch HUD
    await client.screenshot('preview/assets/screenshots/ai_voice_unresponsive_dispatch.png');

    // Test speaking police call
    console.log('\n🔊 Testing Police Call AI speech trigger...');
    await client.eval("document.getElementById('btn-play-police-ai').click()");
    await new Promise(r => setTimeout(r, 500));
    const transcriptAfterPolice = await client.eval("document.getElementById('sos-live-ai-transcript').textContent");
    console.log(`🚓 Police Transcript: "${transcriptAfterPolice.substring(0, 80)}..."`);

    // Test Voice Abort Simulation ("I am okay")
    console.log('\n🛡️ Testing Voice Abort ("I am okay")...');
    // Re-trigger crash
    await client.eval("window.app.triggerSosCountdown('crash')");
    await new Promise(r => setTimeout(r, 1000));
    // Click "I am okay" voice abort chip
    await client.eval("document.getElementById('btn-simulate-voice-abort').click()");
    await new Promise(r => setTimeout(r, 500));

    const isOverlayHidden = await client.eval("document.getElementById('sos-active-countdown').style.display === 'none'");
    console.log(`🛡️ Emergency Overlay Aborted cleanly: ${isOverlayHidden}`);

    if (!isOverlayHidden) throw new Error('Voice abort did not hide emergency overlay!');

    console.log('\n🎉 ALL AI VOICE UNRESPONSIVE CRASH SOS VALIDATIONS PASSED SUCCESSFULLY!');
  } finally {
    chrome.kill();
    server.close();
  }
}

run().catch(err => {
  console.error('❌ Validation failed:', err);
  process.exit(1);
});
