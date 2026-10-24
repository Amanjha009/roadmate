// Automated Chrome DevTools Protocol tester for RoadMate India preview
const http = require('http');
const fs = require('fs');
const { spawn } = require('child_process');

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
    this.events = [];
    this.errors = [];
    this.logs = [];

    this.ws.onmessage = (event) => {
      const msg = JSON.parse(event.data);
      if (msg.id && this.pending.has(msg.id)) {
        const { resolve, reject } = this.pending.get(msg.id);
        this.pending.delete(msg.id);
        if (msg.error) reject(msg.error);
        else resolve(msg.result);
      } else if (msg.method) {
        if (msg.method === 'Runtime.consoleAPICalled') {
          const text = msg.params.args.map(a => a.value || a.description || '').join(' ');
          this.logs.push(`[${msg.params.type}] ${text}`);
          console.log(`  [Browser Console] ${msg.params.type}: ${text}`);
        } else if (msg.method === 'Runtime.exceptionThrown') {
          const desc = msg.params.exceptionDetails.exception?.description || msg.params.exceptionDetails.text;
          this.errors.push(desc);
          console.error(`  [Browser Error]:`, desc);
        }
      }
    };
  }

  async ready() {
    if (this.ws.readyState === WebSocket.OPEN) return;
    return new Promise(resolve => {
      this.ws.onopen = resolve;
    });
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
    console.log(`  📸 Saved screenshot: ${filename}`);
  }
}

async function run() {
  console.log('🚀 Starting Chrome in headless mode with CDP on port 9222...');
  const chrome = spawn('google-chrome', [
    '--headless=new',
    '--no-sandbox',
    '--disable-gpu',
    '--window-size=1440,900',
    '--remote-debugging-port=9222',
    'http://localhost:3000/'
  ]);

  // Wait for Chrome to initialize
  let targets = null;
  for (let i = 0; i < 20; i++) {
    await new Promise(r => setTimeout(r, 300));
    try {
      targets = await getJson('http://127.0.0.1:9222/json');
      if (targets && targets.length > 0) break;
    } catch (e) {}
  }

  if (!targets || targets.length === 0) {
    chrome.kill();
    throw new Error('Failed to connect to Chrome CDP targets');
  }

  const pageTarget = targets.find(t => t.type === 'page') || targets[0];
  console.log(`Connected to page target: ${pageTarget.title} (${pageTarget.url})`);

  const client = new CDPClient(pageTarget.webSocketDebuggerUrl);
  await client.ready();

  // Enable necessary domains
  await client.send('Page.enable');
  await client.send('Runtime.enable');
  await client.send('DOM.enable');

  console.log('\n--- 1. Checking Page Load & Baseline ---');
  let appExists = false;
  for (let i = 0; i < 30; i++) {
    await new Promise(r => setTimeout(r, 200));
    try {
      appExists = await client.eval('typeof window.app !== "undefined"');
      if (appExists) break;
    } catch (e) {}
  }

  const title = await client.eval('document.title');
  console.log(`Page title: "${title}"`);
  console.log(`window.app initialized: ${appExists}`);

  const activeScreen = await client.eval('window.app.currentScreen');
  console.log(`Initial active screen: ${activeScreen}`);

  // Test 1: iOS Screenshot
  console.log('\n--- 2. Testing iOS Device Layout ---');
  await client.eval('window.app.setDevicePlatform("ios")');
  await new Promise(r => setTimeout(r, 500));
  await client.screenshot('preview/assets/screenshots/screenshot_ios_home.png');

  // Test 2: Android Device Layout
  console.log('\n--- 3. Testing Android Device Layout ---');
  await client.eval('window.app.setDevicePlatform("android")');
  await new Promise(r => setTimeout(r, 500));
  const isAndroidClass = await client.eval('document.getElementById("phone-frame").classList.contains("device-android")');
  console.log(`Frame has .device-android class: ${isAndroidClass}`);
  await client.screenshot('preview/assets/screenshots/screenshot_android_home.png');

  // Switch back to iOS for remainder
  await client.eval('window.app.setDevicePlatform("ios")');

  // Test 3: Stories Carousel & Modal
  console.log('\n--- 4. Testing Story Viewer Interaction ---');
  const storiesCount = await client.eval('document.querySelectorAll(".story-circle-item").length');
  console.log(`Found ${storiesCount} story items.`);
  await client.eval('window.app.openStory(0)');
  await new Promise(r => setTimeout(r, 400));
  const storyViewerOpen = await client.eval('document.getElementById("story-viewer-modal").classList.contains("open")');
  console.log(`Story viewer modal is open: ${storyViewerOpen}`);
  const activeStoryAuthor = await client.eval('document.getElementById("sv-author-name").textContent');
  console.log(`Active story author: "${activeStoryAuthor}"`);
  await client.screenshot('preview/assets/screenshots/screenshot_story_viewer.png');
  // Close story viewer
  await client.eval('window.app.closeStoryViewer()');
  await new Promise(r => setTimeout(r, 300));

  // Test 4: Feed Interactions (Like & Double Tap & Comments)
  console.log('\n--- 5. Testing Feed Post Interactions ---');
  const initialLikes = await client.eval('parseInt(document.querySelector(".rider-feed-card[data-post-id=\'post-1\'] .like-count").textContent, 10)');
  console.log(`Post 1 initial likes: ${initialLikes}`);
  await client.eval('document.querySelector(".rider-feed-card[data-post-id=\'post-1\'] .btn-like").click()');
  const newLikes = await client.eval('parseInt(document.querySelector(".rider-feed-card[data-post-id=\'post-1\'] .like-count").textContent, 10)');
  const isLiked = await client.eval('document.querySelector(".rider-feed-card[data-post-id=\'post-1\'] .btn-like").classList.contains("active-like")');
  console.log(`Post 1 toggled like: count=${newLikes}, isLiked=${isLiked}`);

  // Test Comments Sheet
  console.log('\n--- 6. Testing Comments Sheet ---');
  await client.eval('window.app.openComments("post-1")');
  await new Promise(r => setTimeout(r, 400));
  const commentsSheetOpen = await client.eval('document.getElementById("comments-sheet").classList.contains("open")');
  console.log(`Comments sheet is open: ${commentsSheetOpen}`);
  const initialComments = await client.eval('document.querySelectorAll("#cbs-comments-list .cbs-comment-item").length');
  console.log(`Initial comments count: ${initialComments}`);
  // Add a test comment
  await client.eval('document.getElementById("cbs-new-comment-input").value = "Incredible route! Is Khardung La open today?"');
  await client.eval('window.app.addComment()');
  const commentCountAfter = await client.eval('document.querySelectorAll("#cbs-comments-list .cbs-comment-item").length');
  console.log(`Comments count after adding: ${commentCountAfter}`);
  await client.screenshot('preview/assets/screenshots/screenshot_comments_sheet.png');
  await client.eval('window.app.closeComments()');
  await new Promise(r => setTimeout(r, 300));

  // Test 5: Explore Screen & Leaflet Map
  console.log('\n--- 7. Testing Explore Screen & Discovery Map ---');
  await client.eval('window.app.navigateTo("explore")');
  await new Promise(r => setTimeout(r, 600));
  const exploreMapRendered = await client.eval('!!window.app.exploreMap');
  console.log(`Explore Leaflet map initialized: ${exploreMapRendered}`);
  const exploreCards = await client.eval('document.querySelectorAll(".route-discovery-card").length');
  console.log(`Explore discovery cards rendered: ${exploreCards}`);
  await client.screenshot('preview/assets/screenshots/screenshot_explore_screen.png');

  // Test 6: Ride Clips (Vertical Video Layout)
  console.log('\n--- 8. Testing Ride Clips (Short-form Reels) ---');
  await client.eval('window.app.navigateTo("clips")');
  await new Promise(r => setTimeout(r, 500));
  const activeClipTitle = await client.eval('document.getElementById("clip-caption-text").textContent.trim()');
  console.log(`Active clip caption: "${activeClipTitle}"`);
  await client.screenshot('preview/assets/screenshots/screenshot_clips_screen.png');

  // Test 7: Profile & Sub-tabs (Garage, Vault, Settings)
  console.log('\n--- 9. Testing Profile & Unified Sub-Tabs ---');
  await client.eval('window.app.navigateTo("profile")');
  await new Promise(r => setTimeout(r, 500));
  console.log('Testing Garage tab in Profile:');
  await client.eval('window.app.switchProfileTab("garage")');
  await new Promise(r => setTimeout(r, 300));
  const garagePaneActive = await client.eval('document.getElementById("pane-garage").classList.contains("active")');
  console.log(`Garage pane active: ${garagePaneActive}`);

  console.log('Testing Document Vault tab in Profile:');
  await client.eval('window.app.switchProfileTab("vault")');
  await new Promise(r => setTimeout(r, 300));
  const vaultPaneActive = await client.eval('document.getElementById("pane-vault").classList.contains("active")');
  console.log(`Vault pane active: ${vaultPaneActive}`);
  await client.screenshot('preview/assets/screenshots/screenshot_profile_screen.png');

  // Test 8: Create Publishing Action Sheet & Form
  console.log('\n--- 10. Testing Create Unified Publishing Flow ---');
  await client.eval('window.app.openCreateSheet()');
  await new Promise(r => setTimeout(r, 400));
  const createSheetActive = await client.eval('document.getElementById("create-action-sheet").classList.contains("open")');
  console.log(`Create action sheet open: ${createSheetActive}`);
  await client.screenshot('preview/assets/screenshots/screenshot_create_sheet.png');
  await client.eval('window.app.closeCreateSheet()');

  // Test 9: Quick Emergency SOS Header Button
  console.log('\n--- 11. Testing Safety Emergency SOS ---');
  await client.eval('window.app.navigateTo("sos")');
  await new Promise(r => setTimeout(r, 500));
  const sosActive = await client.eval('window.app.currentScreen === "sos"');
  console.log(`Navigated to Emergency SOS: ${sosActive}`);
  await client.screenshot('preview/assets/screenshots/screenshot_sos_screen.png');

  // Test 10: Quick Cockpit HUD Navigation
  console.log('\n--- 12. Testing Cockpit HUD ---');
  await client.eval('window.app.navigateTo("hud")');
  await new Promise(r => setTimeout(r, 500));
  const hudActive = await client.eval('window.app.currentScreen === "hud"');
  console.log(`Navigated to Cockpit HUD: ${hudActive}`);
  await client.screenshot('preview/assets/screenshots/screenshot_hud_screen.png');

  // Clean up
  chrome.kill();

  console.log('\n=============================================');
  console.log(`TEST SUMMARY:`);
  console.log(`Total Errors Encountered: ${client.errors.length}`);
  if (client.errors.length > 0) {
    console.error('Errors list:', client.errors);
    process.exit(1);
  } else {
    console.log('✅ ALL TEST SUITES PASSED WITH ZERO JAVASCRIPT ERRORS!');
    process.exit(0);
  }
}

run().catch(err => {
  console.error('Runner failed:', err);
  process.exit(1);
});
