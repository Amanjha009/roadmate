/**
 * RoadMate India — Live Application Preview Logic & Interactive Engine
 * Supporting 9 Core MVP Pillars with real mapping, audio synthesis, and telemetry simulation.
 */

// ── Screen and Pillar Specifications ─────────────────────────────────────────
const PILLAR_SPECS = {
  'home': {
    title: 'Rider Community Feed & Social Hub',
    tech: 'Apple iOS Patterns • Instagram Warmth • Community Feed',
    desc: 'Curated motorcycle touring feed featuring high-pass stories with auto-progress bars, double-tap heart animations, telemetry ribbons, and contextual road safety radar alerts.',
    metrics: {
      contrast: '13.8 : 1 (High Vis)',
      touchTarget: '48 dp Minimum',
      query: 'Corridor Stream Fanout',
      offline: 'Cached in IndexedDB/Drift'
    }
  },
  'explore': {
    title: 'Route, Pass & Hazard Discovery Hub',
    tech: 'Leaflet 1.9.4 • PostGIS Spatial Bounding • OpenStreetMap',
    desc: 'Interactive map and list directory for high-altitude passes (Khardung La, Rohtang), scenic coastal routes, live PostGIS hazard clusters, and audited women-rider safe dhabas.',
    metrics: {
      contrast: '12.9 : 1 (High Vis)',
      touchTarget: '48 dp Minimum',
      query: 'ST_Contains(BBox, Points)',
      offline: 'Offline Vector Tiles'
    }
  },
  'clips': {
    title: 'Ride Clips (Short-Form Touring Video)',
    tech: 'HTML5 Video Engine • Vertical 9:16 Viewport • Safety Flagging',
    desc: 'Short-form reels experience for motorcycle touring with exhaust audio sync, tactile likes, and a safety innovation allowing riders to flag road hazards directly from video.',
    metrics: {
      contrast: '14.0 : 1 (Visor Safe)',
      touchTarget: '48 dp Minimum',
      query: 'Geo-Tagged Video Frame',
      offline: 'Adaptive HLS Streaming'
    }
  },
  'profile': {
    title: 'Rider Profile, Garage & Compliance Vault',
    tech: 'SQLAlchemy 2.0 • AES-256 Vault • Service Schedule Tracker',
    desc: 'Unified rider identity hub integrating multi-bike maintenance logs (Himalayan 450 & KTM 390), compliance document safe, and emergency contact dispatch settings.',
    metrics: {
      contrast: '13.2 : 1 (Matte Dark)',
      touchTarget: '52 dp Action Buttons',
      query: 'AES-256 GCM Client Encryption',
      offline: 'Local Mirror in SQLite'
    }
  },
  'hud': {
    title: 'Touring HUD & Map Navigation',
    tech: 'Flutter CustomPainter • WebSockets • PostGIS 3.4',
    desc: 'High-contrast rider cockpit display optimized for motorcycle handlebar mounts. Real-time telemetry broadcast with 14.2:1 contrast ratio readable through tinted helmet visors in bright sunlight.',
    metrics: {
      contrast: '14.2 : 1 (WCAG AAA)',
      touchTarget: '56 dp (Glove Ready)',
      query: 'ST_DWithin (POINT, 2000m)',
      offline: 'Drift (SQLite) Ready'
    }
  },
  'hazards': {
    title: 'Crowdsourced PostGIS Hazard Alerts',
    tech: 'PostGIS 3.4 Geography(Point, 4326) • Spatial Radar',
    desc: 'Crowdsourced road safety radar for Indian highways and mountain passes. Potholes, active landslides, black ice, and stray cattle reported by riders, verified via spatial cluster consensus.',
    metrics: {
      contrast: '12.8 : 1 (High Vis)',
      touchTarget: '48 dp Minimum',
      query: 'Cluster Consensus (R >= 3)',
      offline: 'Queued in Local SQLite'
    }
  },
  'convoy': {
    title: 'Live Group Convoy & Roll Call',
    tech: 'Redis 7 Pub/Sub • WebSockets • Mesh Keepalive',
    desc: 'Convoy coordination with distinct roles (Road Captain, Sweeper, Pack Members). Real-time distance separation tracking, fall-behind alerts, and mesh check-in.',
    metrics: {
      contrast: '13.5 : 1 (High Vis)',
      touchTarget: '56 dp Action Buttons',
      query: 'Geodesic Separation Range',
      offline: 'Last-Known Lat/Lng Cached'
    }
  },
  'ai-planner': {
    title: 'AI Route & High Pass Copilot',
    tech: 'FastAPI • OpenAI GPT-4o • High Altitude Elevation API',
    desc: 'Tailored expedition planning for high-altitude passes (Khardung La, Baralacha La, Rohtang). Generates fuel availability warnings (e.g. 365km dry zone from Tandi) and acclimatization schedules.',
    metrics: {
      contrast: '11.9 : 1 (Visor Safe)',
      touchTarget: '48 dp Targets',
      query: 'Terrain Gradient Analysis',
      offline: 'Offline PDF & GeoJSON Export'
    }
  },
  'sos': {
    title: 'Instant Emergency SOS & Crash Beacon',
    tech: 'Slide-to-Activate 80dp • Gyroscope Fall Detection • SMS Fallback',
    desc: 'Critical emergency beacon designed to prevent accidental triggers via an 80dp slide gesture. In crash events, captures 10-second pre-impact telemetry and dispatches coordinates to emergency contacts.',
    metrics: {
      contrast: '16.1 : 1 (Emergency Red)',
      touchTarget: '80 dp Slider Thumb',
      query: 'Telemetry Snapshot & SMS',
      offline: 'Local SMS & Satellite Relay'
    }
  },
  'garage': {
    title: 'Digital Garage & Maintenance Engine',
    tech: 'SQLAlchemy 2.0 • Dynamic Interval Tracker',
    desc: 'Tracks multi-motorcycle wear & tear under extreme touring conditions. Calculates dynamic maintenance due points for chain lubrication, brake pad wear, and engine oil breakdown.',
    metrics: {
      contrast: '12.4 : 1 (Matte)',
      touchTarget: '52 dp Action Bars',
      query: 'Odometer Interval Computation',
      offline: 'Fully Synced with Drift'
    }
  },
  'women-safety': {
    title: 'Women Rider Highway Safe Zones',
    tech: 'Community Safety Heatmap • Verified Audit Engine',
    desc: 'Crowd-audited network of highway dhabas, night halts, and fuel stations rated for women rider safety. Audited for guarded parking, clean western washrooms, CCTV, and verified on-duty staff.',
    metrics: {
      contrast: '13.1 : 1 (Purple Shield)',
      touchTarget: '48 dp Rating Touchpoints',
      query: 'Audited Safety Index >= 4.5',
      offline: 'Pre-downloaded Safe Corridors'
    }
  },
  'vault': {
    title: 'Document Vault & Compliance Shield',
    tech: 'AES-256 Client-Side • S3/MinIO • DigiLocker API',
    desc: 'Encrypted document safe for RC, Comprehensive Insurance, BS6 PUC, and Driving License. Built-in compliance alerts prevent hefty fines during inter-state border transit.',
    metrics: {
      contrast: '12.0 : 1 (Matte Dark)',
      touchTarget: '48 dp Cards',
      query: 'AES-GCM Encryption Key',
      offline: 'Offline Decrypted Local Mirror'
    }
  },
  'auth': {
    title: 'Rider Identity & Verified Onboarding',
    tech: 'JWT HS256 • Fast SMS OTP (Dev 123456) • Trust Score',
    desc: 'Quick 30-second rider authentication with phone OTP, developer bypass mode (123456), emergency contact pairing, and blood group verification.',
    metrics: {
      contrast: '14.2 : 1 (AAA Contrast)',
      touchTarget: '56 dp Primary Button',
      query: 'Stateless Bearer JWT',
      offline: 'Encrypted Token in SecureStorage'
    }
  }
};

// ── Web Audio Synthesizer (Zero External Audio Files Needed) ─────────────────
class SoundFX {
  constructor() {
    this.ctx = null;
    this.enabled = true;
  }

  init() {
    if (!this.ctx) {
      const AudioContext = window.AudioContext || window.webkitAudioContext;
      if (AudioContext) {
        this.ctx = new AudioContext();
      }
    }
    if (this.ctx && this.ctx.state === 'suspended') {
      this.ctx.resume();
    }
  }

  playHazardBeep() {
    if (!this.enabled) return;
    this.init();
    if (!this.ctx) return;

    const now = this.ctx.currentTime;
    const osc1 = this.ctx.createOscillator();
    const osc2 = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc1.type = 'triangle';
    osc1.frequency.setValueAtTime(880, now); // A5
    osc1.frequency.exponentialRampToValueAtTime(440, now + 0.15);

    osc2.type = 'square';
    osc2.frequency.setValueAtTime(1760, now);
    osc2.frequency.exponentialRampToValueAtTime(880, now + 0.15);

    gain.gain.setValueAtTime(0.2, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.25);

    osc1.connect(gain);
    osc2.connect(gain);
    gain.connect(this.ctx.destination);

    osc1.start(now);
    osc2.start(now);
    osc1.stop(now + 0.25);
    osc2.stop(now + 0.25);
  }

  playConvoyPing() {
    if (!this.enabled) return;
    this.init();
    if (!this.ctx) return;

    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'sine';
    osc.frequency.setValueAtTime(523.25, now); // C5
    osc.frequency.exponentialRampToValueAtTime(1046.50, now + 0.1); // C6

    gain.gain.setValueAtTime(0.15, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.3);

    osc.connect(gain);
    gain.connect(this.ctx.destination);

    osc.start(now);
    osc.stop(now + 0.3);
  }

  playSosAlarm() {
    if (!this.enabled) return;
    this.init();
    if (!this.ctx) return;

    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();

    osc.type = 'sawtooth';
    osc.frequency.setValueAtTime(700, now);
    osc.frequency.linearRampToValueAtTime(1200, now + 0.25);
    osc.frequency.linearRampToValueAtTime(700, now + 0.5);

    gain.gain.setValueAtTime(0.3, now);
    gain.gain.exponentialRampToValueAtTime(0.01, now + 0.55);

    osc.connect(gain);
    gain.connect(this.ctx.destination);

    osc.start(now);
    osc.stop(now + 0.55);
  }

  playTap() {
    if (!this.enabled) return;
    this.init();
    if (!this.ctx) return;
    const now = this.ctx.currentTime;
    const osc = this.ctx.createOscillator();
    const gain = this.ctx.createGain();
    osc.type = 'sine';
    osc.frequency.setValueAtTime(1400, now);
    osc.frequency.exponentialRampToValueAtTime(400, now + 0.04);
    gain.gain.setValueAtTime(0.08, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + 0.04);
    osc.connect(gain);
    gain.connect(this.ctx.destination);
    osc.start(now);
    osc.stop(now + 0.04);
  }
}

const sfx = new SoundFX();

// ── AI Voice Emergency Speech & Speech Recognition Engine ────────────────────
class AIVoiceEngine {
  constructor() {
    this.speechSynth = typeof window !== 'undefined' && 'speechSynthesis' in window ? window.speechSynthesis : null;
    this.speechRecognizer = null;
    this.isListening = false;
    this.onVoiceAbort = null;
    this.initRecognizer();
  }

  initRecognizer() {
    const SpeechRec = typeof window !== 'undefined' && (window.SpeechRecognition || window.webkitSpeechRecognition);
    if (SpeechRec) {
      try {
        this.speechRecognizer = new SpeechRec();
        this.speechRecognizer.continuous = true;
        this.speechRecognizer.interimResults = false;
        this.speechRecognizer.lang = 'en-IN';
        this.speechRecognizer.onresult = (event) => {
          for (let i = event.resultIndex; i < event.results.length; ++i) {
            const transcript = event.results[i][0].transcript.toLowerCase();
            console.log('[AI Voice Listener Heard]:', transcript);
            if (transcript.includes('okay') || transcript.includes('fine') || transcript.includes('cancel') || transcript.includes('abort') || transcript.includes('stop')) {
              if (this.onVoiceAbort) this.onVoiceAbort(`Voice response detected: "${transcript}"`);
            }
          }
        };
      } catch (e) {
        console.warn('Speech recognition setup error:', e);
      }
    }
  }

  startListening(onAbortCallback) {
    this.onVoiceAbort = onAbortCallback;
    if (this.speechRecognizer && !this.isListening) {
      try {
        this.speechRecognizer.start();
        this.isListening = true;
      } catch (e) {}
    }
  }

  stopListening() {
    if (this.speechRecognizer && this.isListening) {
      try {
        this.speechRecognizer.stop();
        this.isListening = false;
      } catch (e) {}
    }
  }

  speak(text, onStart = null, onEnd = null) {
    if (!this.speechSynth) return;
    this.speechSynth.cancel();
    const utterance = new SpeechSynthesisUtterance(text);
    utterance.rate = 1.05;
    utterance.pitch = 1.0;
    utterance.volume = 1.0;
    if (onStart) utterance.onstart = onStart;
    if (onEnd) utterance.onend = onEnd;
    this.speechSynth.speak(utterance);
  }

  cancel() {
    if (this.speechSynth) this.speechSynth.cancel();
    this.stopListening();
  }
}

const aiVoice = new AIVoiceEngine();

// ── Application Preview Controller ───────────────────────────────────────────
class AppPreview {
  constructor() {
    this.currentScreen = 'home';
    this.currentMode = 'device';
    this.devicePlatform = 'ios';
    this.isOffline = false;
    this.currentSpeed = 84;
    this.map = null;
    this.exploreMap = null;
    this.bikeMarker = null;
    this.routeCoords = [];
    this.routePolyline = null;
    this.sosCountdownInterval = null;
    this.sosCountdownSecs = 5;

    // Real-Time Live Map & Telemetry Engine State
    this.trackingMode = 'rideRoom'; // 'rideRoom' (3-5s GPS) or 'homeHub' (15-30s GPS)
    this.priyaReconnecting = false;
    this.priyaQueuedCount = 0;
    this.freshnessSeconds = 4;
    this.freshnessInterval = null;
    this.autoExpireSeconds = 15;
    this.autoExpireInterval = null;
    this.expiringHazardMarker = null;
    this.routeSegmentIndex = 2; // starting around Rohtang Pass
    this.routeSegmentProgress = 0.0;
    this.lastPositionUpdateTime = performance.now();
    this.teammates = {};

    // Social, Community & Content State
    this.activeCommentsPostId = null;
    this.exploreCategory = 'all';
    this.initStories();
    this.initClips();

    // Feature 1-4 Expansion State
    this.recordingState = 'IDLE'; // IDLE, ACTIVE, PAUSED, RESUMED, FINISHED
    this.recordingSeconds = 0;
    this.recordingInterval = null;
    this.recordedDistanceKm = 0.0;
    this.recordedElevationM = 0;
    this.offlineQueue = [];
    this.currentStoryTheme = 'Mountain Escape';
    this.storyPrivacyClipped = true;
    this.storyHideMaxSpeed = true;

    this.initElements();
    this.bindEvents();
    this.startClock();
    this.initMap();
    this.buildGridPreview();
  }

  initElements() {
    this.phoneFrame = document.getElementById('phone-frame');
    this.pillarButtons = document.querySelectorAll('.pillar-nav-item');
    this.bottomNavButtons = document.querySelectorAll('.phone-bottom-nav .nav-item');
    this.modeButtons = document.querySelectorAll('.mode-tab');
    this.audioToggle = document.getElementById('audio-toggle');
    this.connToggle = document.getElementById('conn-toggle');
    this.connText = document.getElementById('conn-status-text');
    this.screenConnIcon = document.getElementById('screen-conn-icon');
    this.speedSlider = document.getElementById('speed-slider');
    this.simSpeedVal = document.getElementById('sim-speed-val');
    this.hudSpeedDisplay = document.getElementById('hud-speed-display');
    this.specTitle = document.getElementById('spec-title');
    this.specTech = document.getElementById('spec-tech');
    this.specDesc = document.getElementById('spec-desc');
    this.specMetrics = document.getElementById('spec-metrics');

    // Phone App Header Action Buttons
    this.brandHomeBtn = document.getElementById('pah-brand-btn');
    this.quickHudBtn = document.getElementById('btn-quick-hud');
    this.quickSosBtn = document.getElementById('btn-quick-sos');
    this.headerNotifsBtn = document.getElementById('btn-header-notifs');
    this.headerMessagesBtn = document.getElementById('btn-header-messages');
    this.openCreateSheetBtn = document.getElementById('btn-open-create-sheet');

    // Live Map Status Bar & Alert Banners
    this.freshnessText = document.getElementById('freshness-text');
    this.modeBadgeText = document.getElementById('mode-badge-text');
    this.mapOfflineAlert = document.getElementById('map-offline-alert');
    this.mapReconnectAlert = document.getElementById('map-reconnect-alert');
    this.reconnectAlertText = document.getElementById('reconnect-alert-text');

    // Live Map Simulator Controls
    this.toggleTrackingBtn = document.getElementById('toggle-tracking-mode-btn');
    this.simTunnelBtn = document.getElementById('sim-tunnel-btn');
    this.simAutoExpireBtn = document.getElementById('sim-auto-expire-btn');
    this.simViewportPollBtn = document.getElementById('sim-viewport-poll-btn');

    // SOS Elements
    this.sosThumb = document.getElementById('sos-slider-thumb');
    this.sosTrack = document.getElementById('sos-slider-track');
    this.sosOverlay = document.getElementById('sos-active-countdown');
    this.sosValDisplay = document.getElementById('sos-countdown-val');
    this.sosAbortBtn = document.getElementById('sos-abort-btn');
  }

  bindEvents() {
    // Mode & Platform Switcher (iOS / Android / Responsive / Cockpit HUD / 9 Pillars Grid)
    this.modeButtons.forEach(btn => {
      btn.addEventListener('click', () => {
        if (btn.dataset.device) {
          this.setDevicePlatform(btn.dataset.device);
        }
        if (btn.dataset.mode) {
          this.setMode(btn.dataset.mode);
        }
      });
    });

    // Pillar Sidebar navigation
    this.pillarButtons.forEach(btn => {
      btn.addEventListener('click', () => {
        const screen = btn.dataset.screen;
        this.switchScreen(screen);
      });
    });

    // Bottom Navigation in Phone
    this.bottomNavButtons.forEach(btn => {
      btn.addEventListener('click', () => {
        const screen = btn.dataset.screen;
        if (screen) this.switchScreen(screen);
      });
    });

    // Header Quick Actions inside Phone
    if (this.brandHomeBtn) {
      this.brandHomeBtn.addEventListener('click', () => this.switchScreen('home'));
    }
    if (this.quickHudBtn) {
      this.quickHudBtn.addEventListener('click', () => {
        this.switchScreen(this.currentScreen === 'hud' ? 'home' : 'hud');
      });
    }
    if (this.quickSosBtn) {
      this.quickSosBtn.addEventListener('click', () => {
        this.switchScreen('sos');
        this.showToast('🚨 Critical Emergency SOS: Slide 80dp thumb to dispatch');
      });
    }
    if (this.headerNotifsBtn) {
      this.headerNotifsBtn.addEventListener('click', () => this.openNotifications());
    }
    if (this.headerMessagesBtn) {
      this.headerMessagesBtn.addEventListener('click', () => this.openMessages());
    }
    if (this.openCreateSheetBtn) {
      this.openCreateSheetBtn.addEventListener('click', () => this.openCreateSheet());
    }

    // Story Circle Clicks
    document.querySelectorAll('.story-circle-item').forEach(item => {
      item.addEventListener('click', () => {
        const id = parseInt(item.dataset.storyId, 10) || 0;
        this.openStory(id);
      });
    });

    // Feed Tabs Switcher
    document.querySelectorAll('.feed-tab-btn').forEach(btn => {
      btn.addEventListener('click', () => {
        this.setFeedTab(btn.dataset.feed);
      });
    });

    // Audio FX Toggle
    this.audioToggle.addEventListener('click', () => {
      sfx.enabled = !sfx.enabled;
      this.audioToggle.classList.toggle('active', sfx.enabled);
      this.audioToggle.querySelector('.label').textContent = sfx.enabled ? 'Sound FX On' : 'Muted';
      if (sfx.enabled) sfx.playConvoyPing();
    });

    // Connection Simulator (Offline Drift Sync)
    this.connToggle.addEventListener('click', () => this.toggleOfflineMode());
    document.getElementById('trigger-offline-btn').addEventListener('click', () => this.toggleOfflineMode());

    // Speed Slider
    this.speedSlider.addEventListener('input', (e) => {
      this.updateSpeed(parseInt(e.target.value, 10));
    });

    // Simulated Actions
    document.getElementById('trigger-hazard-btn').addEventListener('click', () => {
      this.triggerHazardAlert();
    });
    document.getElementById('btn-test-alert').addEventListener('click', () => {
      this.triggerHazardAlert();
    });
    document.getElementById('btn-test-speedup').addEventListener('click', () => {
      this.speedSlider.value = 105;
      this.updateSpeed(105);
    });
    document.getElementById('btn-test-sos-trigger').addEventListener('click', () => {
      this.switchScreen('sos');
      this.triggerSosCountdown('voice');
    });

    // Voice SOS Simulation Buttons
    const btnSimVoice = document.getElementById('btn-simulate-voice-sos');
    if (btnSimVoice) {
      btnSimVoice.addEventListener('click', () => {
        this.triggerSosCountdown('voice');
      });
    }

    const btnSimCrash = document.getElementById('btn-simulate-crash-sos');
    if (btnSimCrash) {
      btnSimCrash.addEventListener('click', () => {
        this.triggerSosCountdown('crash');
      });
    }

    const btnDial112 = document.getElementById('btn-dial-112-now');
    if (btnDial112) {
      btnDial112.addEventListener('click', () => {
        this.showToast('📞 Initiating Emergency Call to 112 (National Emergency Dispatch)...');
      });
    }

    const btnVoiceSetup = document.getElementById('btn-open-voice-setup');
    if (btnVoiceSetup) {
      btnVoiceSetup.addEventListener('click', () => {
        this.showToast('ℹ️ Voice SOS Privacy: 100% on-device wake model. Zero continuous audio streaming. 30s post-trigger audio auto-deleted after 30 days.');
      });
    }

    // Voice Abort Simulation button ("I am okay")
    const btnSimVoiceAbort = document.getElementById('btn-simulate-voice-abort');
    if (btnSimVoiceAbort) {
      btnSimVoiceAbort.addEventListener('click', () => {
        this.abortSos('Voice response detected: "I am okay"');
      });
    }

    // AI Emergency Voice Call Audio Playback buttons
    const btnPlayPolice = document.getElementById('btn-play-police-ai');
    if (btnPlayPolice) {
      btnPlayPolice.addEventListener('click', () => {
        this.speakPoliceCall();
      });
    }

    const btnPlayAmbulance = document.getElementById('btn-play-ambulance-ai');
    if (btnPlayAmbulance) {
      btnPlayAmbulance.addEventListener('click', () => {
        this.speakAmbulanceCall();
      });
    }

    // Convoy Buttons
    document.getElementById('btn-convoy-ping').addEventListener('click', () => {
      sfx.playConvoyPing();
      this.showToast('📡 Convoy Mesh Ping Sent to 5 Riders!');
    });
    document.getElementById('btn-convoy-regroup').addEventListener('click', () => {
      sfx.playHazardBeep();
      this.broadcastConvoyCheckIn('REGROUP');
    });
    const btnConvoyImOk = document.getElementById('btn-convoy-im-ok');
    if (btnConvoyImOk) {
      btnConvoyImOk.addEventListener('click', () => {
        this.broadcastConvoyCheckIn('IM_OK');
      });
    }

    // Ride Recording State Machine Buttons
    const btnHudRecToggle = document.getElementById('btn-hud-record-toggle');
    if (btnHudRecToggle) {
      btnHudRecToggle.addEventListener('click', () => this.toggleRideRecording());
    }
    const btnHudRecFinish = document.getElementById('btn-hud-record-finish');
    if (btnHudRecFinish) {
      btnHudRecFinish.addEventListener('click', () => this.finishRideRecording());
    }

    // Convoy Separation Hysteresis Action Buttons
    const btnHsaRegroup = document.getElementById('btn-hsa-regroup');
    if (btnHsaRegroup) {
      btnHsaRegroup.addEventListener('click', () => this.broadcastConvoyCheckIn('REGROUP'));
    }
    const btnHsaImOk = document.getElementById('btn-hsa-im-ok');
    if (btnHsaImOk) {
      btnHsaImOk.addEventListener('click', () => this.broadcastConvoyCheckIn('IM_OK'));
    }

    // OTP Demo Verify
    document.getElementById('btn-demo-verify-otp').addEventListener('click', () => {
      sfx.playConvoyPing();
      this.showToast('✓ OTP 123456 verified! JWT Token refreshed (Valid 30 days)');
    });

    // Add Service Log
    document.getElementById('btn-add-service-log').addEventListener('click', () => {
      const odoEl = document.querySelector('.odo-val');
      const curOdo = parseInt(odoEl.textContent.replace(',', ''), 10);
      const newOdo = curOdo + 150;
      odoEl.textContent = newOdo.toLocaleString();
      this.showToast(`🏍️ Odometer updated to ${newOdo.toLocaleString()} km! Chain lube timer reset.`);
    });

    // Live Map & WebSocket Simulator Controls
    if (this.toggleTrackingBtn) {
      this.toggleTrackingBtn.addEventListener('click', () => {
        this.toggleTrackingMode();
      });
    }
    if (this.simTunnelBtn) {
      this.simTunnelBtn.addEventListener('click', () => {
        this.simulateTunnelDropAndReconnect();
      });
    }
    if (this.simAutoExpireBtn) {
      this.simAutoExpireBtn.addEventListener('click', () => {
        this.simulateHazardPinAutoExpiry();
      });
    }
    if (this.simViewportPollBtn) {
      this.simViewportPollBtn.addEventListener('click', () => {
        this.triggerViewportPoll();
      });
    }

    // Expandable HUD Telemetry Drawer & Map Parallax
    const hudDrawer = document.getElementById('hud-drawer');
    const drawerExpanded = document.getElementById('hud-drawer-expanded');
    const drawerHint = document.getElementById('drawer-hint-text');
    const mapWrapper = document.querySelector('.hud-map-wrapper');

    if (hudDrawer) {
      hudDrawer.addEventListener('click', (e) => {
        // Prevent toggle if clicking on interactive buttons inside
        if (e.target.closest('button')) return;
        const isExp = hudDrawer.classList.toggle('expanded');
        if (drawerExpanded) drawerExpanded.style.display = isExp ? 'flex' : 'none';
        if (mapWrapper) mapWrapper.classList.toggle('parallax-compressed', isExp);
        if (drawerHint) drawerHint.textContent = isExp ? 'COLLAPSE TELEMETRY ▴' : 'EXPEDITION TELEMETRY ▾';
        sfx.playTap();
        if (this.map) {
          setTimeout(() => this.map.invalidateSize(), 350);
        }
      });
    }

    // Convoy Roster Floating Sheet Toggle
    const convoyStack = document.getElementById('convoy-avatar-stack');
    const rosterSheet = document.getElementById('convoy-roster-sheet');
    const btnCloseRoster = document.getElementById('btn-close-roster');

    if (convoyStack && rosterSheet) {
      convoyStack.addEventListener('click', () => {
        rosterSheet.classList.toggle('active');
        sfx.playTap();
      });
    }
    if (btnCloseRoster && rosterSheet) {
      btnCloseRoster.addEventListener('click', (e) => {
        e.stopPropagation();
        rosterSheet.classList.remove('active');
        sfx.playTap();
      });
    }

    // Attach subtle haptic click sound to all interactive squish elements
    document.querySelectorAll('.interactive-squish, .fab-btn, .mode-tab, .chip, .pillar-nav-item').forEach(el => {
      el.addEventListener('click', () => sfx.playTap());
    });

    // Slide-to-Activate SOS Slider Logic
    this.initSosSlider();
  }

  setDevicePlatform(platform) {
    this.devicePlatform = platform;
    if (this.phoneFrame) {
      this.phoneFrame.classList.toggle('device-ios', platform === 'ios');
      this.phoneFrame.classList.toggle('device-android', platform === 'android');
    }
    document.querySelectorAll('.mode-tab[data-device]').forEach(btn => {
      btn.classList.toggle('active', btn.dataset.device === platform);
    });
    sfx.playTap();
    this.showToast(`Switched to ${platform === 'ios' ? 'Apple iPhone iOS' : 'Android Flagship'} layout`);
  }

  setMode(mode) {
    this.currentMode = mode;
    this.modeButtons.forEach(b => {
      if (b.dataset.mode) {
        b.classList.toggle('active', b.dataset.mode === mode);
      }
    });
    document.body.classList.remove('mode-device', 'mode-cockpit', 'mode-grid', 'mode-responsive');
    document.body.classList.add(`mode-${mode}`);

    if (mode === 'cockpit') {
      this.switchScreen('hud');
    }

    if (this.map) {
      setTimeout(() => this.map.invalidateSize(), 300);
    }
    if (this.exploreMap) {
      setTimeout(() => this.exploreMap.invalidateSize(), 300);
    }
  }

  navigateTo(screenId) {
    this.switchScreen(screenId);
  }

  switchScreen(screenId) {
    this.currentScreen = screenId;

    // Update screen elements inside the phone
    document.querySelectorAll('.app-screen').forEach(el => {
      el.classList.toggle('active', el.id === `screen-${screenId}`);
    });

    // Update sidebar pillar active state
    this.pillarButtons.forEach(btn => {
      btn.classList.toggle('active', btn.dataset.screen === screenId);
    });

    // Update bottom navigation bar
    this.bottomNavButtons.forEach(btn => {
      btn.classList.toggle('active', btn.dataset.screen === screenId);
    });

    // Update specification card on right sidebar
    this.updateSpecCard(screenId);

    // If switching to HUD screen, resize map
    if (screenId === 'hud' && this.map) {
      setTimeout(() => this.map.invalidateSize(), 200);
    }

    // If switching to Explore screen, init/resize explore map
    if (screenId === 'explore') {
      this.initExploreMap();
      if (this.exploreMap) {
        setTimeout(() => this.exploreMap.invalidateSize(), 200);
      }
    }

    // If switching to Clips screen, render clip
    if (screenId === 'clips') {
      this.renderClip();
    }

    // Instagram-Style Story Trust Ring Proportional Fill Animation (0 -> 94%)
    if (screenId === 'auth') {
      const ring = document.getElementById('profile-trust-ring');
      if (ring) {
        ring.style.background = 'conic-gradient(#FF5C00 0deg, rgba(255,255,255,0.1) 0deg 360deg)';
        const targetDeg = 338.4; // 94% of 360 degrees
        const duration = 750;
        const startTimestamp = performance.now();
        const stepAnimation = (now) => {
          const progress = Math.min((now - startTimestamp) / duration, 1.0);
          // Ease-out cubic spring curve
          const ease = 1 - Math.pow(1 - progress, 3);
          const currentDeg = ease * targetDeg;
          ring.style.background = `conic-gradient(
            #FF5C00 0deg,
            #FFA726 ${currentDeg * 0.45}deg,
            #FF5C00 ${currentDeg}deg,
            rgba(255, 255, 255, 0.1) ${currentDeg}deg 360deg
          )`;
          if (progress < 1.0) {
            requestAnimationFrame(stepAnimation);
          }
        };
        requestAnimationFrame(stepAnimation);
      }
    }
  }

  updateSpecCard(screenId) {
    const spec = PILLAR_SPECS[screenId];
    if (!spec) return;

    this.specTitle.textContent = spec.title;
    this.specTech.textContent = spec.tech;
    this.specDesc.textContent = spec.desc;

    this.specMetrics.innerHTML = `
      <div class="sm-item">
        <span class="sm-lbl">Contrast Ratio</span>
        <strong class="sm-val text-green">${spec.metrics.contrast}</strong>
      </div>
      <div class="sm-item">
        <span class="sm-lbl">Min Touch Target</span>
        <strong class="sm-val text-orange">${spec.metrics.touchTarget}</strong>
      </div>
      <div class="sm-item">
        <span class="sm-lbl">Spatial Query</span>
        <strong class="sm-val">${spec.metrics.query}</strong>
      </div>
      <div class="sm-item">
        <span class="sm-lbl">Offline Cache</span>
        <strong class="sm-val text-green">${spec.metrics.offline}</strong>
      </div>
    `;
  }

  updateSpeed(speed) {
    this.currentSpeed = speed;
    this.simSpeedVal.textContent = `${speed} km/h`;
    this.hudSpeedDisplay.textContent = speed;

    const gearTag = document.querySelector('.gear-tag');
    if (gearTag) {
      if (speed === 0) gearTag.textContent = 'NEUTRAL';
      else if (speed < 25) gearTag.textContent = '1ST GEAR';
      else if (speed < 45) gearTag.textContent = '2ND GEAR';
      else if (speed < 65) gearTag.textContent = '3RD GEAR';
      else if (speed < 90) gearTag.textContent = '4TH GEAR';
      else if (speed < 110) gearTag.textContent = '5TH GEAR';
      else gearTag.textContent = '6TH GEAR';
    }

    // Accumulate recording distance if ride recording is active
    if (this.recordingState === 'ACTIVE' || this.recordingState === 'RESUMED') {
      this.recordedDistanceKm += (speed / 3600);
      const distEl = document.getElementById('hud-rec-dist');
      if (distEl) distEl.textContent = `${this.recordedDistanceKm.toFixed(1)} km`;

      if (!this.recordedPoints) this.recordedPoints = [];
      const step = this.recordedPoints.length;
      const baseLat = 32.2396 + (step * 0.0035);
      const baseLng = 77.1887 + (step * 0.0025);
      const alt = 2050 + Math.min(1930, step * 40);
      this.recordedPoints.push({
        lat: Number(baseLat.toFixed(5)),
        lng: Number(baseLng.toFixed(5)),
        altitude: alt,
        speed_kmh: speed,
        accuracy_m: 8.0,
        timestamp: new Date().toISOString(),
      });
    }

    // Queue fix if offline mode is engaged
    if (this.isOffline && speed > 0) {
      this.offlineQueue.push({
        eventId: `evt-${Date.now()}-${Math.floor(Math.random() * 10000)}`,
        speed: speed,
        timestamp: new Date().toISOString()
      });
      this.connText.textContent = `📴 Offline (${this.offlineQueue.length} queued)`;
    }
  }

  toggleOfflineMode() {
    this.isOffline = !this.isOffline;
    this.connToggle.classList.toggle('offline', this.isOffline);

    if (this.mapOfflineAlert) {
      this.mapOfflineAlert.style.display = this.isOffline ? 'flex' : 'none';
    }

    const youFreshness = document.getElementById('convoy-you-freshness');

    if (this.isOffline) {
      this.connText.textContent = `📴 Offline (${this.offlineQueue.length} queued)`;
      this.screenConnIcon.textContent = 'OFFLINE';
      this.screenConnIcon.style.color = '#FFC107';
      this.showToast('📴 Zero-Connectivity Mode: Telemetry queued in local SQLite buffer with UUID event keys');
      if (youFreshness) {
        youFreshness.className = 'freshness-tag freshness-delayed';
        youFreshness.textContent = '● OFFLINE (Local SQLite Queue)';
      }
    } else {
      const syncedCount = Math.max(1, this.offlineQueue.length);
      this.offlineQueue = [];
      this.connText.textContent = '4G Online';
      this.screenConnIcon.textContent = '4G';
      this.screenConnIcon.style.color = '';
      this.showToast(`🟢 4G Network Restored: Batch synced ${syncedCount} fixes to convoy (0 duplicates rejected).`);
      if (youFreshness) {
        youFreshness.className = 'freshness-tag freshness-live';
        youFreshness.textContent = '● LIVE (Local Fix)';
      }
      this.triggerViewportPoll(false);
    }
  }

  triggerHazardAlert() {
    this.switchScreen('hud');
    sfx.playHazardBeep();

    const banner = document.getElementById('active-hazard-banner');
    if (banner) {
      banner.style.display = 'flex';
      banner.style.animation = 'none';
      setTimeout(() => {
        banner.style.animation = 'shake 0.8s ease';
      }, 10);
    }

    this.showToast('⚠️ POSTGIS RADAR ALERT: Fresh Landslide reported 850m ahead on NH3!');
  }

  // ── SOS Slide to Activate Gestures ─────────────────────────────────────────
  initSosSlider() {
    let isDragging = false;
    let startX = 0;
    let currentX = 0;
    const maxDrag = 210; // track width minus thumb width

    const onPointerDown = (e) => {
      isDragging = true;
      startX = e.clientX || (e.touches && e.touches[0].clientX);
      this.sosThumb.style.transition = 'none';
    };

    const onPointerMove = (e) => {
      if (!isDragging) return;
      const clientX = e.clientX || (e.touches && e.touches[0].clientX);
      const deltaX = clientX - startX;
      currentX = Math.max(0, Math.min(deltaX, maxDrag));
      this.sosThumb.style.transform = `translateX(${currentX}px)`;

      if (currentX >= maxDrag - 10) {
        isDragging = false;
        this.sosThumb.style.transform = `translateX(${maxDrag}px)`;
        this.triggerSosCountdown();
      }
    };

    const onPointerUp = () => {
      if (!isDragging) return;
      isDragging = false;
      this.sosThumb.style.transition = 'transform 0.3s ease';
      this.sosThumb.style.transform = 'translateX(0px)';
    };

    this.sosThumb.addEventListener('mousedown', onPointerDown);
    window.addEventListener('mousemove', onPointerMove);
    window.addEventListener('mouseup', onPointerUp);

    this.sosThumb.addEventListener('touchstart', onPointerDown, { passive: true });
    window.addEventListener('touchmove', onPointerMove, { passive: true });
    window.addEventListener('touchend', onPointerUp);

    this.sosAbortBtn.addEventListener('click', () => {
      this.abortSos();
    });
  }

  triggerSosCountdown(triggerSource = 'manual') {
    sfx.playSosAlarm();
    this.sosOverlay.style.display = 'flex';
    this.sosCountdownSecs = 10;
    this.sosValDisplay.classList.remove('text-sm');
    this.sosValDisplay.textContent = this.sosCountdownSecs;

    // Smoothly scroll active emergency cockpit into view
    const scrollBody = this.sosOverlay.closest('.screen-scroll-body');
    if (scrollBody) {
      setTimeout(() => {
        scrollBody.scrollTo({ top: this.sosOverlay.offsetTop - 10, behavior: 'smooth' });
      }, 50);
    }

    const label = document.getElementById('sos-countdown-label');
    if (label) label.textContent = 'SECONDS TO DISPATCH';

    const challengeBanner = document.getElementById('sos-voice-challenge-banner');
    const unresponsivePanel = document.getElementById('sos-unresponsive-panel');
    if (unresponsivePanel) unresponsivePanel.style.display = 'none';

    const badge = document.getElementById('sos-active-trigger-badge');
    if (badge) {
      if (triggerSource === 'voice') {
        badge.textContent = '🎙️ VOICE TRIGGER: "Hey RoadMate, I need help"';
        badge.style.borderColor = 'var(--brand-orange)';
        badge.style.color = '#FF8A4C';
        if (challengeBanner) challengeBanner.style.display = 'none';
        this.showToast('🎙️ Voice wake-phrase matched! 10-second safety window started. GPS & Audio active.');
      } else if (triggerSource === 'crash') {
        badge.textContent = '💥 MAJOR CRASH DETECTED: 8.4G Impact Spike + Stillness';
        badge.style.borderColor = 'var(--status-red)';
        badge.style.color = '#FF8A80';
        if (challengeBanner) challengeBanner.style.display = 'flex';

        // Play loud audible vocal challenge
        const challengePrompt =
          "Attention! Major motorcycle crash detected. Are you responsive? Say 'I am okay' or tap cancel. Emergency services will be called in 10 seconds.";
        aiVoice.speak(challengePrompt);

        // Start listening for rider saying "I am okay"
        aiVoice.startListening((reason) => {
          this.abortSos(reason);
        });

        this.showToast('💥 Major crash detected! AI voice checking responsiveness for 10s.');
      } else {
        badge.textContent = '🚨 MANUAL SLIDER ACTIVATED';
        badge.style.borderColor = 'var(--status-red)';
        badge.style.color = '#FF8A80';
        if (challengeBanner) challengeBanner.style.display = 'none';
      }
    }

    clearInterval(this.sosCountdownInterval);
    this.sosCountdownInterval = setInterval(() => {
      this.sosCountdownSecs--;
      this.sosValDisplay.textContent = this.sosCountdownSecs;
      sfx.playSosAlarm();

      if (triggerSource === 'crash' && this.sosCountdownSecs === 5) {
        aiVoice.speak("5 seconds remaining. Confirm if you are conscious.");
      }

      if (this.sosCountdownSecs <= 0) {
        clearInterval(this.sosCountdownInterval);
        aiVoice.stopListening();

        if (triggerSource === 'crash') {
          // ── RIDER IS UNRESPONSIVE! Escalating automated AI voice calls ────
          this.sosValDisplay.classList.add('text-sm');
          this.sosValDisplay.textContent = 'AUTO-CALL';
          if (label) label.textContent = 'AI VOICE ACTIVE';
          if (challengeBanner) challengeBanner.style.display = 'none';
          if (unresponsivePanel) unresponsivePanel.style.display = 'flex';

          const transcriptEl = document.getElementById('sos-live-ai-transcript');
          if (transcriptEl) {
            transcriptEl.textContent =
              '"Emergency automated broadcast from RoadMate Indian Rider Safety Network. ' +
              'A critical motorcycle crash of 8.4G has occurred. The rider is completely UNRESPONSIVE after 10-second vocal checks. ' +
              'Rider Name: Aman Jha. Mobile: +91 98765 43200. Blood Group: O-Positive. ' +
              'Crash Location: Rohtang Pass Highway NH3 (32.3712° N, 77.2144° E). ' +
              'Live map transmitted. Dispatching Police (112) and Trauma Ambulance (108)..."';
          }

          // Speak initial escalation announcement
          aiVoice.speak(
            "Rider is unresponsive. Initiating emergency automated voice calls to Police Station 112 and Ambulance 108 with live GPS location.",
            null,
            () => {
              // After initial announcement, speak the police call script
              this.speakPoliceCall();
            }
          );

          this.showToast(
            '🚨 RIDER UNRESPONSIVE: Automated AI Calls dispatched to Police Station (112) & Ambulance (108) with coordinates.'
          );
        } else {
          this.sosValDisplay.textContent = 'DISPATCHED';
          this.showToast('🚨 SOS TRANSMITTED! Priority 1 & 2 Contacts alerted via Push, SMS & Telegram. 112 dialing ready.');
        }
      }
    }, 1000);
  }

  speakPoliceCall() {
    const policeScript =
      "Emergency automated report from RoadMate Safety. Severe motorcycle crash detected. " +
      "The rider is completely UNRESPONSIVE after 10-second checks. " +
      "Rider Name: Aman Jha. Phone: +91 98765 43200. Blood Group: O-Positive. " +
      "Emergency Contact: Aditi Sharma at +91 98765 43210. " +
      "Location: Rohtang Pass Highway NH3, coordinates 32.3712 North, 77.2144 East. " +
      "Live navigation map link has been sent. Please dispatch highway patrol and emergency rescue immediately.";

    const tag = document.getElementById('transcript-live-tag');
    if (tag) tag.textContent = 'POLICE (112)';
    const transcriptEl = document.getElementById('sos-live-ai-transcript');
    if (transcriptEl) transcriptEl.textContent = `[AI Speaking to Police 112]: "${policeScript}"`;

    this.showToast('🔊 Speaking AI Voice Call to Police Station (112)...');
    aiVoice.speak(policeScript);
  }

  speakAmbulanceCall() {
    const ambulanceScript =
      "Medical Emergency Priority One! RoadMate automated trauma ambulance dispatch. " +
      "Severe motorcycle impact crash with unconscious, unresponsive rider. " +
      "Rider: Aman Jha. Blood Group: O-Positive. Suspected high-G blunt force trauma. " +
      "Location: Rohtang Pass Highway NH3, coordinates 32.3712 North, 77.2144 East. " +
      "Dispatch Advanced Life Support ambulance and trauma response team immediately.";

    const tag = document.getElementById('transcript-live-tag');
    if (tag) tag.textContent = 'AMBULANCE (108)';
    const transcriptEl = document.getElementById('sos-live-ai-transcript');
    if (transcriptEl) transcriptEl.textContent = `[AI Speaking to Ambulance 108]: "${ambulanceScript}"`;

    this.showToast('🔊 Speaking AI Voice Call to Ambulance / EMS (108)...');
    aiVoice.speak(ambulanceScript);
  }

  abortSos(reason = 'Cancelled by rider within safety window') {
    clearInterval(this.sosCountdownInterval);
    aiVoice.cancel();

    this.sosOverlay.style.display = 'none';
    this.sosValDisplay.classList.remove('text-sm');
    const challengeBanner = document.getElementById('sos-voice-challenge-banner');
    if (challengeBanner) challengeBanner.style.display = 'none';
    const unresponsivePanel = document.getElementById('sos-unresponsive-panel');
    if (unresponsivePanel) unresponsivePanel.style.display = 'none';

    this.sosThumb.style.transition = 'transform 0.3s ease';
    this.sosThumb.style.transform = 'translateX(0px)';

    aiVoice.speak("Emergency aborted. False alarm logged.");
    this.showToast(`🛡️ False Alarm Aborted: ${reason}`);
  }

  // ── Leaflet Touring Map Initialization ─────────────────────────────────────
  initMap() {
    const mapEl = document.getElementById('real-leaflet-map');
    if (!mapEl || typeof L === 'undefined') return;

    // Center around Rohtang Pass / Keylong Highway NH3
    const center = [32.3712, 77.2144];
    this.map = L.map('real-leaflet-map', {
      zoomControl: false,
      attributionControl: false
    }).setView(center, 13);

    // 100% Free OpenStreetMap tiles rendered in high-contrast dark mode via CSS filter
    this.darkTiles = L.tileLayer('https://tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 18,
      attribution: '&copy; OpenStreetMap contributors'
    }).addTo(this.map);

    this.topoTiles = L.tileLayer('https://{s}.tile.opentopomap.org/{z}/{x}/{y}.png', {
      maxZoom: 17,
      attribution: '&copy; OpenStreetMap &copy; OpenTopoMap'
    });
    this.currentTileMode = 'dark';

    // Realistic Himalayan Touring Route: Manali -> Rohtang Pass -> Keylong -> Baralacha La
    this.routeCoords = [
      [32.2396, 77.1887], // 0: Manali
      [32.3012, 77.2050], // 1: Marhi
      [32.3712, 77.2144], // 2: Rohtang Pass Crest
      [32.4020, 77.1820], // 3: Gramphu Hairpin
      [32.4200, 77.1500], // 4: Koksar
      [32.4800, 77.0600], // 5: Sissu
      [32.5500, 77.0300], // 6: Keylong
      [32.6500, 77.1200], // 7: Jispa
      [32.7560, 77.3000]  // 8: Baralacha La
    ];

    this.routePolyline = L.polyline(this.routeCoords, {
      color: '#FF5C00',
      weight: 5,
      opacity: 0.9,
      dashArray: '8, 8'
    }).addTo(this.map);

    // 1. My Bike Marker (RE Himalayan 450 with live position lerp)
    const bikeIcon = L.divIcon({
      className: 'custom-bike-marker',
      html: `
        <div id="my-bike-marker-icon" style="background: #FF5C00; color: white; width: 36px; height: 36px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 18px; border: 3px solid white; box-shadow: 0 0 15px #FF5C00; transition: transform 0.2s ease;">
          🏍️
        </div>
      `,
      iconSize: [36, 36],
      iconAnchor: [18, 18]
    });
    this.bikeMarker = L.marker([32.3712, 77.2144], { icon: bikeIcon }).addTo(this.map);

    // 2. Squad Members (Live WebSocket Fan-out via Redis Pub/Sub)
    // Captain Vikram (Lead)
    const captainIcon = L.divIcon({
      className: 'custom-captain-marker',
      html: `
        <div class="custom-teammate-marker">
          <div class="teammate-avatar" style="background: #FFD700; color: black;">👑</div>
          <span class="teammate-tag">Vikram (Lead)</span>
        </div>
      `,
      iconSize: [60, 48],
      iconAnchor: [30, 24]
    });
    this.teammates.vikram = L.marker([32.3830, 77.2020], { icon: captainIcon })
      .addTo(this.map)
      .bindPopup("<b>Road Captain (Vikram)</b><br>BMW R1250 GS • +950m • 4G Live");

    // Rohit (Pack Member)
    const rohitIcon = L.divIcon({
      className: 'custom-rohit-marker',
      html: `
        <div class="custom-teammate-marker">
          <div class="teammate-avatar" style="background: #2196F3;">🏍️</div>
          <span class="teammate-tag">Rohit (390 ADV)</span>
        </div>
      `,
      iconSize: [60, 48],
      iconAnchor: [30, 24]
    });
    this.teammates.rohit = L.marker([32.3760, 77.2090], { icon: rohitIcon })
      .addTo(this.map)
      .bindPopup("<b>Rohit Verma</b><br>KTM 390 Adventure • +420m • 4G Live");

    // Priya (Pack Member - Subject to Tunnel Reconnect Simulation)
    this.priyaMarkerEl = null;
    const priyaIcon = L.divIcon({
      className: 'custom-priya-marker',
      html: `
        <div class="custom-teammate-marker" id="priya-marker-container">
          <div class="teammate-avatar" id="priya-avatar" style="background: #9C27B0;">🛵</div>
          <span class="teammate-tag" id="priya-status-tag">Priya (Scram)</span>
        </div>
      `,
      iconSize: [70, 48],
      iconAnchor: [35, 24]
    });
    this.teammates.priya = L.marker([32.3650, 77.2180], { icon: priyaIcon })
      .addTo(this.map)
      .bindPopup("<b>Priya Sundaram</b><br>Royal Enfield Scram 411 • -350m");

    // 3. PostGIS Hazard Pin (Landslide)
    const hazardIcon = L.divIcon({
      className: 'custom-hazard-marker',
      html: `
        <div style="background: #F44336; color: white; width: 32px; height: 32px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 16px; border: 2px solid white; animation: pulse-dot 1.2s infinite; box-shadow: 0 0 15px #F44336;">
          ⚠️
        </div>
      `,
      iconSize: [32, 32],
      iconAnchor: [16, 16]
    });
    L.marker([32.3920, 77.1950], { icon: hazardIcon })
      .addTo(this.map)
      .bindPopup("<b>PostGIS Hazard: Fresh Rockfall</b><br>Reported 12m ago • Verified by 14 riders");

    // Verified Touring Support POIs (Fuel, Repairs, Hospital, Safe Stay)
    const touringPois = [
      { name: "IndianOil Tandi", cat: "⛽ Fuel", pos: [32.5539, 76.9744], desc: "Last pump before Karu (365 km dry zone). Cash only." },
      { name: "Keylong Spoke Repair", cat: "🔧 Mechanic", pos: [32.5710, 77.0320], desc: "Royal Enfield spoke-tube specialist & plugs." },
      { name: "Civil Hospital Keylong", cat: "🏥 Medical O2", pos: [32.5745, 77.0341], desc: "24/7 Emergency high-altitude O2 support." },
      { name: "Jispa Safe Stay", cat: "🏨 Safe Stay", pos: [32.6393, 77.1873], desc: "Women-rider audited, guarded bike parking." }
    ];

    touringPois.forEach(p => {
      const poiIcon = L.divIcon({
        className: 'poi-custom-marker',
        html: `<div style="background: rgba(20,20,20,0.92); border: 1.5px solid #FFA726; border-radius: 8px; padding: 2px 6px; font-size: 11px; color: #FFF; font-weight: 700; white-space: nowrap; box-shadow: 0 4px 10px rgba(0,0,0,0.7);">${p.cat}</div>`,
        iconSize: [64, 24],
        iconAnchor: [32, 12]
      });
      L.marker(p.pos, { icon: poiIcon }).addTo(this.map).bindPopup(`<b>${p.name}</b><br><small>${p.desc}</small>`);
    });

    // Recenter map FAB
    const fabRecenter = document.getElementById('fab-recenter');
    if (fabRecenter) {
      fabRecenter.addEventListener('click', () => {
        if (this.bikeMarker) {
          this.map.panTo(this.bikeMarker.getLatLng(), { animate: true });
          this.showToast('📍 Map Recentered on RE Himalayan 450 GPS Fix');
        }
      });
    }

    // Toggle layer FAB (CartoDB Dark Matter vs OpenTopoMap)
    const fabLayer = document.getElementById('fab-layer');
    if (fabLayer) {
      fabLayer.addEventListener('click', () => {
        if (this.currentTileMode === 'dark') {
          this.map.removeLayer(this.darkTiles);
          this.map.addLayer(this.topoTiles);
          this.currentTileMode = 'topo';
          this.showToast('⛰️ Map Layer: OpenTopoMap Himalayan Topography active');
        } else {
          this.map.removeLayer(this.topoTiles);
          this.map.addLayer(this.darkTiles);
          this.currentTileMode = 'dark';
          this.showToast('🌙 Map Layer: CartoDB Dark Matter Night HUD active');
        }
      });
    }

    // Report hazard FAB
    const fabReport = document.getElementById('fab-report-hazard');
    if (fabReport) {
      fabReport.addEventListener('click', () => {
        this.openReportHazardModal();
      });
    }

    // Start Position Interpolator & Viewport Freshness Engine
    this.startSmoothInterpolation();
    this.startFreshnessTicker();
  }

  // ── Real-Time Position Interpolator (Smooth Animation without Snapping) ────
  startSmoothInterpolation() {
    let lastTick = performance.now();

    const interpolate = (now) => {
      const deltaMs = now - lastTick;
      lastTick = now;

      // Update segment duration based on battery mode:
      // Ride Room mode: moves across segment points smoothly every ~3.5 seconds
      // Home Hub mode: relaxed interval of ~20 seconds
      const segmentDurationMs = this.trackingMode === 'rideRoom' ? 3500 : 20000;
      this.routeSegmentProgress += deltaMs / segmentDurationMs;

      if (this.routeSegmentProgress >= 1.0) {
        this.routeSegmentProgress = 0.0;
        this.routeSegmentIndex++;
        if (this.routeSegmentIndex >= this.routeCoords.length - 1) {
          this.routeSegmentIndex = 1; // loop seamlessly along pass
        }

        // Viewport movement check: if rider moved forward in Ride Room, check 200m rule
        if (this.trackingMode === 'rideRoom' && this.freshnessSeconds >= 45) {
          this.triggerViewportPoll(false);
        }
      }

      // Smooth Cubic Easing for natural motorcycle flow
      const t = this.routeSegmentProgress;
      const easedT = t < 0.5 ? 2 * t * t : -1 + (4 - 2 * t) * t;

      const p0 = this.routeCoords[this.routeSegmentIndex];
      const p1 = this.routeCoords[this.routeSegmentIndex + 1];

      if (p0 && p1 && this.bikeMarker) {
        const curLat = p0[0] + (p1[0] - p0[0]) * easedT;
        const curLng = p0[1] + (p1[1] - p0[1]) * easedT;

        // Native coordinate update (zero map re-renders)
        this.bikeMarker.setLatLng([curLat, curLng]);

        // Move teammates smoothly in convoy formation
        if (this.teammates.vikram) {
          const vLat = curLat + 0.007;
          const vLng = curLng - 0.006;
          this.teammates.vikram.setLatLng([vLat, vLng]);
        }
        if (this.teammates.rohit) {
          const rLat = curLat + 0.003;
          const rLng = curLng - 0.003;
          this.teammates.rohit.setLatLng([rLat, rLng]);
        }
        if (this.teammates.priya && !this.priyaReconnecting) {
          // If online, Priya moves along
          const pLat = curLat - 0.005;
          const pLng = curLng + 0.004;
          this.teammates.priya.setLatLng([pLat, pLng]);
        }
      }

      requestAnimationFrame(interpolate);
    };

    requestAnimationFrame(interpolate);
  }

  // ── Layer Freshness & Viewport Polling Engine ──────────────────────────────
  startFreshnessTicker() {
    clearInterval(this.freshnessInterval);
    this.freshnessInterval = setInterval(() => {
      this.freshnessSeconds++;
      if (this.freshnessText) {
        if (this.freshnessSeconds < 60) {
          this.freshnessText.textContent = `Updated ${this.freshnessSeconds}s ago`;
        } else {
          const mins = Math.floor(this.freshnessSeconds / 60);
          this.freshnessText.textContent = `Updated ${mins}m ago`;
        }
      }

      // Auto-poll viewport every 75s (60-90s window) when map is open and online
      if (this.freshnessSeconds >= 75 && !this.isOffline) {
        this.triggerViewportPoll(false);
      }
    }, 1000);
  }

  // ── Live Map Interactive Simulator Controls ────────────────────────────────
  toggleTrackingMode() {
    if (this.trackingMode === 'rideRoom') {
      this.trackingMode = 'homeHub';
      this.modeBadgeText.textContent = '🏠 Home Hub (20s GPS)';
      this.toggleTrackingBtn.textContent = '🏠 Mode: Home Hub (15-30s GPS)';
      this.toggleTrackingBtn.style.background = 'rgba(33, 150, 243, 0.2)';
      this.toggleTrackingBtn.style.borderColor = '#2196F3';
      this.toggleTrackingBtn.style.color = '#90CAF9';
      this.showToast('🔋 Battery Optimization: Relaxed GPS interval to 20s for Home Hub browsing.');
    } else {
      this.trackingMode = 'rideRoom';
      this.modeBadgeText.textContent = '⚡ Ride Room (3s GPS)';
      this.toggleTrackingBtn.textContent = '⚡ Mode: Ride Room (3s GPS)';
      this.toggleTrackingBtn.style.background = 'rgba(255, 92, 0, 0.2)';
      this.toggleTrackingBtn.style.borderColor = 'var(--brand-orange)';
      this.toggleTrackingBtn.style.color = '#FF8A4C';
      this.showToast('⚡ Ride Room Engaged: Foreground GPS service active at 3-5s emission via WebSocket.');
    }
  }

  simulateTunnelDropAndReconnect() {
    this.priyaReconnecting = !this.priyaReconnecting;

    const priyaAvatar = document.getElementById('priya-avatar');
    const priyaTag = document.getElementById('priya-status-tag');

    if (this.priyaReconnecting) {
      // Disconnect Priya in Tunnel
      sfx.playHazardBeep();
      this.priyaQueuedCount = 4;

      if (priyaAvatar) priyaAvatar.classList.add('reconnecting');
      if (priyaTag) {
        priyaTag.className = 'teammate-tag reconnecting-pill';
        priyaTag.textContent = 'reconnecting...';
      }

      if (this.mapReconnectAlert) {
        this.mapReconnectAlert.style.display = 'flex';
        this.reconnectAlertText.textContent = 'Tunnel Dead-Zone: Priya disconnected • Queueing telemetry frames locally';
      }

      this.showToast('🚇 Priya entered Rohtang Tunnel: WebSocket dropped! UI displays "reconnecting..." on avatar (not frozen stale dot).');
    } else {
      // Reconnect Priya
      sfx.playConvoyPing();
      if (priyaAvatar) priyaAvatar.classList.remove('reconnecting');
      if (priyaTag) {
        priyaTag.className = 'teammate-tag';
        priyaTag.textContent = 'Priya (Scram 411)';
      }

      if (this.mapReconnectAlert) {
        this.mapReconnectAlert.style.display = 'none';
      }

      this.showToast(`🟢 Priya exited tunnel: Reconnected to /ws/rides/:id! Flushed ${this.priyaQueuedCount} queued telemetry frames. Gap recovered!`);
      this.priyaQueuedCount = 0;
    }
  }

  triggerViewportPoll(isManual = true) {
    this.freshnessSeconds = 0;
    if (this.freshnessText) {
      this.freshnessText.textContent = 'Updated 0s ago';
    }

    if (isManual) {
      sfx.playConvoyPing();
      this.showToast('📡 Viewport Query: Polled GET /hazards/nearby (lat: 32.37, lng: 77.21, radius: 5000m). PostGIS spatial index executed in 11ms.');
    }
  }

  simulateHazardPinAutoExpiry() {
    if (this.expiringHazardMarker && this.map) {
      this.map.removeLayer(this.expiringHazardMarker);
      this.expiringHazardMarker = null;
      clearInterval(this.autoExpireInterval);
    }

    this.autoExpireSeconds = 15;
    sfx.playHazardBeep();

    const createIconHtml = (sec) => `
      <div class="hazard-pin-wrap" id="expiring-pin-container">
        <div style="background: #E91E63; color: white; width: 34px; height: 34px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 16px; border: 2.5px solid white; box-shadow: 0 0 14px #E91E63;">
          🛑
        </div>
        <span class="hazard-expiry-badge" id="pin-timer-badge">Expires in ${sec}s</span>
      </div>
    `;

    const icon = L.divIcon({
      className: 'custom-expiring-marker',
      html: createIconHtml(this.autoExpireSeconds),
      iconSize: [80, 52],
      iconAnchor: [40, 26]
    });

    const pinPos = [32.3680, 77.2220];
    this.expiringHazardMarker = L.marker(pinPos, { icon }).addTo(this.map);
    this.expiringHazardMarker.bindPopup("<b>Temporary Obstacle (Auto-Expiring)</b><br>Will purge client-side the instant expires_at passes!");

    this.showToast(`⏱️ Added test hazard pin with expires_at set to +15s. Watch it purge automatically at 0s!`);

    clearInterval(this.autoExpireInterval);
    this.autoExpireInterval = setInterval(() => {
      this.autoExpireSeconds--;
      const badge = document.getElementById('pin-timer-badge');
      if (badge) {
        badge.textContent = `Expires in ${this.autoExpireSeconds}s`;
      }

      if (this.autoExpireSeconds <= 0) {
        clearInterval(this.autoExpireInterval);
        if (this.expiringHazardMarker && this.map) {
          const container = document.getElementById('expiring-pin-container');
          if (container) {
            container.style.transition = 'opacity 0.6s ease, transform 0.6s ease';
            container.style.opacity = '0';
            container.style.transform = 'scale(0.3)';
          }

          setTimeout(() => {
            if (this.expiringHazardMarker && this.map) {
              this.map.removeLayer(this.expiringHazardMarker);
              this.expiringHazardMarker = null;
            }
          }, 600);
        }
        sfx.playConvoyPing();
        this.showToast('⏱️ Hazard pin auto-expired client-side at exactly expires_at without waiting for next server poll!');
      }
    }, 1000);
  }

  // ── 9 Pillars Grid View Builder ─────────────────────────────────────────────
  buildGridPreview() {
    const stage = document.getElementById('device-stage');
    if (!stage) return;

    const gridContainer = document.createElement('div');
    gridContainer.className = 'grid-showcase-view';
    gridContainer.id = 'grid-showcase-container';

    Object.keys(PILLAR_SPECS).forEach((key, idx) => {
      const spec = PILLAR_SPECS[key];
      const card = document.createElement('div');
      card.className = 'grid-card-preview';
      card.innerHTML = `
        <div class="gcp-head">
          <strong>${String(idx + 1).padStart(2, '0')}. ${spec.title}</strong>
          <span class="gcp-tag badge-amber">${spec.tech.split('•')[0].trim()}</span>
        </div>
        <p class="gcp-body">${spec.desc}</p>
        <div class="gcp-metrics-mini" style="display: flex; gap: 8px; font-size: 10px; color: #888;">
          <span>🎯 ${spec.metrics.touchTarget}</span>
          <span>⚡ ${spec.metrics.query}</span>
        </div>
        <button class="sim-btn" style="margin-top: 6px; width: 100%;">Inspect in Mobile View →</button>
      `;

      card.addEventListener('click', () => {
        this.setMode('device');
        this.switchScreen(key);
      });

      gridContainer.appendChild(card);
    });

    stage.appendChild(gridContainer);
  }

  // ── Clock & UI Utility Functions ────────────────────────────────────────────
  startClock() {
    const clockEl = document.getElementById('status-clock');
    const updateTime = () => {
      const now = new Date();
      const hrs = String(now.getHours()).padStart(2, '0');
      const mins = String(now.getMinutes()).padStart(2, '0');
      if (clockEl) clockEl.textContent = `${hrs}:${mins}`;
    };
    updateTime();
    setInterval(updateTime, 30000);
  }

  showToast(msg) {
    let toast = document.getElementById('global-toast');
    if (!toast) {
      toast = document.createElement('div');
      toast.id = 'global-toast';
      toast.style.position = 'fixed';
      toast.style.bottom = '24px';
      toast.style.right = '24px';
      toast.style.background = '#1E1E1E';
      toast.style.color = '#FFFFFF';
      toast.style.border = '1px solid #FF5C00';
      toast.style.boxShadow = '0 8px 30px rgba(0, 0, 0, 0.8), 0 0 15px rgba(255, 92, 0, 0.3)';
      toast.style.borderRadius = '10px';
      toast.style.padding = '12px 18px';
      toast.style.fontSize = '12px';
      toast.style.fontWeight = '600';
      toast.style.zIndex = '9999';
      toast.style.transition = 'opacity 0.3s, transform 0.3s';
      toast.style.maxWidth = '360px';
      document.body.appendChild(toast);
    }

    toast.textContent = msg;
    toast.style.opacity = '1';
    toast.style.transform = 'translateY(0)';

    clearTimeout(this.toastTimeout);
    this.toastTimeout = setTimeout(() => {
      toast.style.opacity = '0';
      toast.style.transform = 'translateY(10px)';
    }, 4000);
  }
  // ── Stories Engine (Instagram-Style Ephemeral Passes & Weather) ───────────
  initStories() {
    this.storiesData = [
      {
        id: 0,
        author: '@vikram_adv',
        time: '2h ago • Khardung La',
        media: 'assets/images/himalayan_khardungla.jpg',
        caption: 'Khardung La weather advisory: Light snowfall near north pullu. Clear for all 450s and dual-sport tires. 🏔️🏍️'
      },
      {
        id: 1,
        author: '@roadmate_hq',
        time: '45m ago • PostGIS Radar',
        media: 'assets/images/hazard.jpg',
        caption: 'Baralacha La rockfall cleared by BRO team. Alternate lane open for motorcycles. Proceed with caution!'
      },
      {
        id: 2,
        author: '@priya_rides',
        time: '3h ago • Kunzum Pass',
        media: 'assets/images/spiti_water_crossing.jpg',
        caption: 'Mallig stream crossing depth 1.5 ft. Take the boulder line on the far left in 2nd gear. 🌊🏍️'
      },
      {
        id: 3,
        author: '@ladakh_pack',
        time: '1h ago • Sarchu Camp',
        media: 'assets/images/rider.jpg',
        caption: 'Convoy #07 roll call: 6/6 riders checked in at Sarchu tents. Zero casualties, crisp night skies!'
      },
      {
        id: 4,
        author: '@ananya_moto',
        time: '4h ago • NH44 Highway',
        media: 'assets/images/women_rider_priya.jpg',
        caption: 'Babu Dhaba safe halt verified: Guarded parking, clean western washrooms, 24/7 CCTV. Audited 4.9★! 🛡️'
      },
      {
        id: 5,
        author: '@dev_mechanic',
        time: '5h ago • Keylong',
        media: 'assets/images/hero.jpg',
        caption: 'Expedition tip: Lubricate chain immediately after glacial stream crossings to prevent rust and binding.'
      }
    ];
    this.currentStoryIndex = 0;
    this.storyTimer = null;
  }

  openStory(storyIndex) {
    this.currentStoryIndex = storyIndex;
    const modal = document.getElementById('story-viewer-modal');
    if (!modal) return;
    modal.classList.add('open');
    this.renderActiveStory();
    sfx.playTap();
  }

  closeStoryViewer() {
    const modal = document.getElementById('story-viewer-modal');
    if (modal) modal.classList.remove('open');
    this.stopStoryProgress();
  }

  renderActiveStory() {
    const story = this.storiesData[this.currentStoryIndex];
    if (!story) return;

    const authorEl = document.getElementById('sv-author-name');
    const timeEl = document.getElementById('sv-time');
    const mediaEl = document.getElementById('sv-media-img');
    const captionEl = document.getElementById('sv-caption');

    if (authorEl) authorEl.textContent = story.author;
    if (timeEl) timeEl.textContent = story.time;
    if (mediaEl) mediaEl.src = story.media;
    if (captionEl) captionEl.textContent = story.caption;

    // Update progress bars
    for (let i = 0; i < 6; i++) {
      const fill = document.getElementById(`sv-fill-${i}`);
      if (fill) {
        fill.classList.toggle('filled', i < this.currentStoryIndex);
        if (i === this.currentStoryIndex) {
          fill.style.width = '0%';
        } else if (i > this.currentStoryIndex) {
          fill.style.width = '0%';
        }
      }
    }

    this.startStoryProgress();
  }

  startStoryProgress() {
    this.stopStoryProgress();
    const fill = document.getElementById(`sv-fill-${this.currentStoryIndex}`);
    if (!fill) return;

    let progress = 0;
    this.storyTimer = setInterval(() => {
      progress += 1.25;
      fill.style.width = `${progress}%`;
      if (progress >= 100) {
        this.nextStory();
      }
    }, 50);
  }

  stopStoryProgress() {
    if (this.storyTimer) {
      clearInterval(this.storyTimer);
      this.storyTimer = null;
    }
  }

  nextStory() {
    if (this.currentStoryIndex < this.storiesData.length - 1) {
      this.currentStoryIndex++;
      this.renderActiveStory();
    } else {
      this.closeStoryViewer();
    }
  }

  prevStory() {
    if (this.currentStoryIndex > 0) {
      this.currentStoryIndex--;
      this.renderActiveStory();
    } else {
      this.renderActiveStory();
    }
  }

  // ── Feed Interactions & Micro-Animations ────────────────────────────────────
  handleDoubleTap(container, postId) {
    const heartBurst = container.querySelector('.heart-pop-burst');
    if (heartBurst) {
      heartBurst.classList.add('popping');
      setTimeout(() => heartBurst.classList.remove('popping'), 500);
    }
    sfx.playTap();
    const card = container.closest('.rider-feed-card');
    if (card) {
      const likeBtn = card.querySelector('.btn-like');
      if (likeBtn && !likeBtn.classList.contains('active-like')) {
        this.toggleLike(postId, likeBtn);
      }
    }
  }

  toggleLike(postId, btn) {
    const isLiked = btn.classList.contains('active-like');
    btn.classList.toggle('active-like', !isLiked);
    const icon = btn.querySelector('.icon-heart');
    if (icon) icon.textContent = !isLiked ? '❤️' : '🤍';
    const countEl = btn.querySelector('.like-count');
    if (countEl) {
      let count = parseInt(countEl.textContent, 10) || 0;
      count = !isLiked ? count + 1 : Math.max(0, count - 1);
      countEl.textContent = count;
    }
    sfx.playTap();
    this.showToast(!isLiked ? '❤️ Liked expedition log' : 'Unliked post');
  }

  toggleBookmark(postId, btn) {
    const isSaved = btn.classList.contains('active-save');
    btn.classList.toggle('active-save', !isSaved);
    sfx.playTap();
    this.showToast(!isSaved ? '🔖 Saved to Touring Bookmarks' : 'Removed from Bookmarks');
  }

  sharePost(postId) {
    sfx.playTap();
    this.showToast('🔗 Expedition route link copied to clipboard!');
  }

  toggleFollow(btn) {
    const isFollowing = btn.classList.contains('following');
    btn.classList.toggle('following', !isFollowing);
    btn.textContent = !isFollowing ? 'Following' : '+ Follow';
    sfx.playTap();
    this.showToast(!isFollowing ? '✓ Following rider for live updates' : 'Unfollowed rider');
  }

  setFeedTab(tabName) {
    document.querySelectorAll('.feed-tab-btn').forEach(b => {
      b.classList.toggle('active', b.dataset.feed === tabName);
    });
    sfx.playTap();
    this.renderFeedForTab(tabName);
  }

  renderFeedForTab(tabName) {
    const cards = document.querySelectorAll('#feed-stream .rider-feed-card');
    cards.forEach((card, idx) => {
      card.style.opacity = '0';
      card.style.transform = 'translateY(10px)';
      setTimeout(() => {
        card.style.transition = 'opacity 0.3s ease, transform 0.3s ease';
        card.style.opacity = '1';
        card.style.transform = 'translateY(0)';
      }, idx * 60);
    });

    if (tabName === 'following') {
      this.showToast('Showing posts from your Convoy & Followed Himalayan Riders');
    } else if (tabName === 'nearby') {
      this.showToast('Showing 2 expedition posts within 50km on NH3 Manali-Leh');
    } else {
      this.showToast('Showing trending motorcycle touring expeditions');
    }
  }

  // ── Comments Bottom Sheet Engine ────────────────────────────────────────────
  openComments(postId) {
    this.activeCommentsPostId = postId;
    const sheet = document.getElementById('comments-sheet');
    if (sheet) sheet.classList.add('open');
    sfx.playTap();
  }

  closeComments() {
    const sheet = document.getElementById('comments-sheet');
    if (sheet) sheet.classList.remove('open');
  }

  addComment() {
    const input = document.getElementById('cbs-new-comment-input');
    if (!input) return;
    const text = input.value.trim();
    if (!text) {
      this.showToast('Please enter a comment');
      return;
    }

    const list = document.getElementById('cbs-comments-list');
    if (list) {
      const item = document.createElement('div');
      item.className = 'cbs-comment-item';
      item.style.animation = 'fadeIn 0.3s ease';
      item.innerHTML = `
        <img src="assets/images/rider.jpg" class="cbs-comment-avatar" alt="Vikram">
        <div class="cbs-comment-content">
          <div>
            <span class="cbs-comment-author">vikram_singh</span>
            <span class="cbs-comment-text">${this.escapeHtml(text)}</span>
          </div>
          <div class="cbs-comment-time">Just now • Reply • 0 likes</div>
        </div>
        <button class="cbs-comment-like" onclick="this.textContent = this.textContent === '❤️' ? '🤍' : '❤️'">🤍</button>
      `;
      list.appendChild(item);
      list.scrollTop = list.scrollHeight;
    }

    if (this.activeCommentsPostId) {
      const card = document.querySelector(`.rider-feed-card[data-post-id="${this.activeCommentsPostId}"]`);
      if (card) {
        const countEl = card.querySelector('.comment-count');
        if (countEl) {
          let count = parseInt(countEl.textContent, 10) || 0;
          countEl.textContent = count + 1;
        }
      }
    }

    input.value = '';
    sfx.playConvoyPing();
    this.showToast('💬 Comment posted to expedition log');
  }

  // ── Explore Discovery & Map Engine ──────────────────────────────────────────
  initExploreMap() {
    if (this.exploreMap) return;
    const el = document.getElementById('explore-leaflet-map');
    if (!el || typeof L === 'undefined') return;

    this.exploreMap = L.map('explore-leaflet-map', {
      zoomControl: false,
      attributionControl: false
    }).setView([32.3712, 77.2144], 9);

    L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
      maxZoom: 18,
    }).addTo(this.exploreMap);

    const markers = [
      { pos: [34.2787, 77.6047], title: 'Khardung La Pass (5,359m)', icon: '🏔️', color: '#2196F3' },
      { pos: [32.3712, 77.2144], title: 'Rohtang Pass (3,980m)', icon: '🏔️', color: '#4CAF50' },
      { pos: [32.3850, 77.6350], title: 'Spiti Kunzum Circuit (518 km)', icon: '🌊', color: '#FF9800' },
      { pos: [32.5500, 76.9700], title: 'Tandi Fuel Stop (Last Petrol)', icon: '⛽', color: '#FF5722' },
      { pos: [32.7560, 77.3000], title: 'Baralacha Rockfall Hazard', icon: '⚠️', color: '#F44336' },
      { pos: [31.5000, 76.9000], title: 'Babu Dhaba NH44 (Women Safe)', icon: '🛡️', color: '#9C27B0' },
    ];

    markers.forEach(m => {
      const icon = L.divIcon({
        className: 'explore-marker-icon',
        html: `<div style="background: ${m.color}; color: #fff; width: 28px; height: 28px; border-radius: 50%; display: flex; align-items: center; justify-content: center; font-size: 14px; border: 2px solid white; box-shadow: 0 2px 8px rgba(0,0,0,0.4);">${m.icon}</div>`,
        iconSize: [28, 28],
        iconAnchor: [14, 14]
      });
      L.marker(m.pos, { icon }).addTo(this.exploreMap).bindPopup(`<b>${m.title}</b><br><small>Click for route guide</small>`);
    });
  }

  setExploreCategory(category, btn) {
    this.exploreCategory = category;
    document.querySelectorAll('.ef-chip').forEach(c => c.classList.remove('active'));
    btn.classList.add('active');

    const cards = document.querySelectorAll('#explore-cards-container .route-discovery-card');
    let visibleCount = 0;
    cards.forEach(card => {
      const matches = category === 'all' || card.dataset.cat === category;
      card.style.display = matches ? 'flex' : 'none';
      if (matches) visibleCount++;
    });

    const titleEl = document.getElementById('explore-count-title');
    if (titleEl) {
      titleEl.textContent = `DISCOVERING ${visibleCount} VERIFIED ${category.toUpperCase()} ROUTES`;
    }
    sfx.playTap();
  }

  filterExplore(query) {
    const q = query.toLowerCase().trim();
    const cards = document.querySelectorAll('#explore-cards-container .route-discovery-card');
    let visibleCount = 0;
    cards.forEach(card => {
      const text = card.textContent.toLowerCase();
      const matches = text.includes(q);
      card.style.display = matches ? 'flex' : 'none';
      if (matches) visibleCount++;
    });

    const titleEl = document.getElementById('explore-count-title');
    if (titleEl) {
      titleEl.textContent = `SEARCH RESULTS: ${visibleCount} FOUND`;
    }
  }

  toggleExploreView(mode) {
    document.getElementById('evt-btn-list').classList.toggle('active', mode === 'list');
    document.getElementById('evt-btn-map').classList.toggle('active', mode === 'map');
    const mapWrapper = document.getElementById('explore-map-wrapper');
    if (mapWrapper) {
      mapWrapper.style.display = mode === 'map' ? 'block' : 'none';
      if (mode === 'map') {
        this.initExploreMap();
        if (this.exploreMap) {
          setTimeout(() => this.exploreMap.invalidateSize(), 200);
        }
      }
    }
    sfx.playTap();
  }

  openRouteDetail(routeId) {
    sfx.playTap();
    this.showToast(`📍 Loaded Expedition Details: ${routeId.toUpperCase()} • Opening Cockpit HUD`);
    setTimeout(() => this.switchScreen('hud'), 400);
  }

  // ── Ride Clips (Reels-Style Short Form Video) ────────────────────────────────
  initClips() {
    this.clipsData = [
      {
        id: 0,
        author: '@priya_rides',
        avatar: 'assets/images/women_rider_priya.jpg',
        media: 'assets/images/spiti_water_crossing.jpg',
        caption: 'Glacial stream crossing on Kunzum Pass approach! Keep in 2nd gear and keep throttle smooth. 🌊🏍️',
        audio: 'RE Himalayan 450 Sherpa Exhaust Note',
        likes: '1.4k',
        location: 'Spiti Valley • Batal km marker 88'
      },
      {
        id: 1,
        author: '@vikram_adv',
        avatar: 'assets/images/rider.jpg',
        media: 'assets/images/himalayan_khardungla.jpg',
        caption: 'First light at 17,480 ft on Khardung La! Minus 4 degrees and pure Himalayan air. 🏔️✨',
        audio: 'High Altitude Wind & Exhaust Roar',
        likes: '2.8k',
        location: 'Khardung La Pass Crest • 5,359m'
      },
      {
        id: 2,
        author: '@rohit_adv',
        avatar: 'assets/images/hero.jpg',
        media: 'assets/images/hazard.jpg',
        caption: 'Loose shale on Rohtang Hairpin loop. Watch out for road clearing dozers! ⚠️🏍️',
        audio: 'KTM 390 Adventure Quickshifter',
        likes: '942',
        location: 'Rohtang Pass Hairpin #12'
      }
    ];
    this.currentClipIndex = 0;
  }

  renderClip() {
    const clip = this.clipsData[this.currentClipIndex];
    if (!clip) return;

    const bgImg = document.getElementById('clip-bg-img');
    const authorAvatar = document.getElementById('clip-author-avatar');
    const authorName = document.getElementById('clip-author-name');
    const captionText = document.getElementById('clip-caption-text');
    const audioTitle = document.getElementById('clip-audio-title');
    const likeCount = document.getElementById('clip-like-count');

    if (bgImg) bgImg.src = clip.media;
    if (authorAvatar) authorAvatar.src = clip.avatar;
    if (authorName) authorName.textContent = clip.author;
    if (captionText) captionText.textContent = clip.caption;
    if (audioTitle) audioTitle.textContent = clip.audio;
    if (likeCount) likeCount.textContent = clip.likes;
  }

  nextClip() {
    this.currentClipIndex = (this.currentClipIndex + 1) % this.clipsData.length;
    this.renderClip();
    sfx.playTap();
  }

  prevClip() {
    this.currentClipIndex = (this.currentClipIndex - 1 + this.clipsData.length) % this.clipsData.length;
    this.renderClip();
    sfx.playTap();
  }

  toggleClipLike(btn) {
    const isLiked = btn.classList.contains('active-like');
    btn.classList.toggle('active-like', !isLiked);
    sfx.playTap();
    this.showToast(!isLiked ? '❤️ Liked Ride Clip' : 'Unliked clip');
  }

  toggleClipSave(btn) {
    const isSaved = btn.classList.contains('active-save');
    btn.classList.toggle('active-save', !isSaved);
    sfx.playTap();
    this.showToast(!isSaved ? '🔖 Saved Clip to Collection' : 'Removed from Saved');
  }

  openReportHazardFromClip() {
    const clip = this.clipsData[this.currentClipIndex];
    const locInput = document.getElementById('rh-location');
    if (locInput && clip) {
      locInput.value = clip.location;
    }
    this.openReportHazardModal();
    this.showToast('⚠️ Pre-filled hazard report with coordinates from active clip');
  }

  // ── Unified Profile Sub-Tabs Engine ─────────────────────────────────────────
  switchProfileTab(tabName, btn) {
    document.querySelectorAll('.pst-tab').forEach(t => {
      const isMatch = btn ? t === btn : t.dataset.tab === tabName;
      t.classList.toggle('active', isMatch);
    });

    document.querySelectorAll('.profile-tab-pane').forEach(p => p.classList.remove('active'));
    const pane = document.getElementById(`pane-${tabName}`);
    if (pane) pane.classList.add('active');
    sfx.playTap();
  }

  openLogServiceModal() {
    const modal = document.getElementById('modal-log-service');
    if (modal) modal.classList.add('open');
    sfx.playTap();
  }

  submitLogService() {
    const odo = document.getElementById('ls-odo').value;
    const type = document.getElementById('ls-type').value;
    const notes = document.getElementById('ls-notes').value;

    this.closeModal('modal-log-service');
    sfx.playConvoyPing();
    this.showToast(`✓ Logged ${type} at ${odo} km: Intervals updated!`);
  }

  openUploadDocModal() {
    const modal = document.getElementById('modal-upload-doc');
    if (modal) modal.classList.add('open');
    sfx.playTap();
  }

  submitUploadDoc() {
    const type = document.getElementById('ud-type').value;
    const num = document.getElementById('ud-number').value;

    this.closeModal('modal-upload-doc');
    sfx.playConvoyPing();
    this.showToast(`🔒 Encrypted ${type} (${num}) with AES-256 and added to Vault!`);
  }

  // ── Create Publishing Sheet & Modals ────────────────────────────────────────
  openCreateSheet() {
    const sheet = document.getElementById('create-action-sheet');
    if (sheet) sheet.classList.add('open');
    sfx.playTap();
  }

  closeCreateSheet() {
    const sheet = document.getElementById('create-action-sheet');
    if (sheet) sheet.classList.remove('open');
  }

  openCreatePostModal() {
    this.closeCreateSheet();
    const modal = document.getElementById('modal-create-post');
    if (modal) modal.classList.add('open');
    sfx.playTap();
  }

  submitCreatePost() {
    const location = document.getElementById('cp-location').value;
    const bike = document.getElementById('cp-bike').value;
    const stats = document.getElementById('cp-stats').value;
    const caption = document.getElementById('cp-caption').value;

    this.closeModal('modal-create-post');

    // Create new card and prepend to feed
    const stream = document.getElementById('feed-stream');
    if (stream) {
      const card = document.createElement('article');
      card.className = 'rider-feed-card';
      card.style.animation = 'fadeIn 0.4s ease';
      card.innerHTML = `
        <div class="rfc-header">
          <div class="rfc-user-meta">
            <div class="rfc-avatar-wrap">
              <img src="assets/images/rider.jpg" class="rfc-avatar" alt="Vikram">
            </div>
            <div class="rfc-user-info">
              <div class="rfc-user-row">
                <span class="rfc-name">Vikram Singh</span>
                <span class="rfc-verified-badge">✓</span>
              </div>
              <div class="rfc-sub-row">
                <span class="rfc-bike-tag">${this.escapeHtml(bike)}</span>
                <span class="rfc-location">${this.escapeHtml(location)}</span>
              </div>
            </div>
          </div>
          <span style="font-size: 10px; color: #4CAF50; font-weight: 700;">JUST NOW</span>
        </div>
        <div class="rfc-media-container" ondblclick="window.appPreview && window.appPreview.handleDoubleTap(this, 'post-new')">
          <img src="assets/images/hero.jpg" class="rfc-media-img" alt="New Post">
          <div class="heart-pop-burst">❤️</div>
          <div class="rfc-telemetry-ribbon">
            <div class="rfc-tel-item"><span class="rfc-tel-lbl">Stats</span><span class="rfc-tel-val val-orange">${this.escapeHtml(stats)}</span></div>
          </div>
        </div>
        <div class="rfc-actions-bar">
          <div class="rfc-actions-left">
            <button class="rfc-action-btn btn-like" onclick="window.appPreview && window.appPreview.toggleLike('post-new', this)">
              <span class="icon-heart">🤍</span>
              <span class="rfc-count-text like-count">1</span>
            </button>
            <button class="rfc-action-btn btn-comment" onclick="window.appPreview && window.appPreview.openComments('post-new')">
              <span>💬</span>
              <span class="rfc-count-text comment-count">0</span>
            </button>
            <button class="rfc-action-btn btn-share" onclick="window.appPreview && window.appPreview.sharePost('post-new')">
              <span>↗️</span>
            </button>
          </div>
          <button class="rfc-action-btn btn-save" onclick="window.appPreview && window.appPreview.toggleBookmark('post-new', this)">
            <span>🔖</span>
          </button>
        </div>
        <div class="rfc-caption-box">
          <span class="rfc-caption-author">vikram_adv</span>
          ${this.escapeHtml(caption)}
        </div>
      `;
      stream.insertBefore(card, stream.firstChild);
    }

    sfx.playConvoyPing();
    this.showToast('🚀 Expedition post published to community!');
    this.switchScreen('home');
  }

  openReportHazardModal() {
    this.closeCreateSheet();
    const modal = document.getElementById('modal-report-hazard');
    if (modal) modal.classList.add('open');
    sfx.playTap();
  }

  submitReportHazard() {
    const cat = document.getElementById('rh-category').value;
    const loc = document.getElementById('rh-location').value;
    const sev = document.getElementById('rh-severity').value;
    const desc = document.getElementById('rh-desc').value;
    const idempotencyKey = `idemp-${Date.now()}-${Math.floor(Math.random() * 1000)}`;

    this.closeModal('modal-report-hazard');
    sfx.playHazardBeep();

    // Map category string to data-hz-type
    let hzType = 'landslide';
    if (cat.includes('Ice')) hzType = 'black_ice';
    else if (cat.includes('Pothole')) hzType = 'pothole';
    else if (cat.includes('Water')) hzType = 'water_crossing';
    else if (cat.includes('Closure')) hzType = 'road_closure';

    const list = document.getElementById('preview-hazards-list');
    if (list) {
      const card = document.createElement('div');
      card.className = 'hazard-card glass-surface interactive-squish';
      card.dataset.hzType = hzType;
      card.style.cssText = 'border-radius: 18px; padding: 14px; border-left: 3px solid #FF5C00 !important; animation: fadeIn 0.4s ease; margin-bottom: 10px;';
      card.innerHTML = `
        <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px;">
          <div style="display: flex; align-items: center; gap: 8px;">
            <div style="width: 32px; height: 32px; border-radius: 50%; background: #FF5C00; display: flex; align-items: center; justify-content: center; font-size: 14px; font-weight: 800; color: white;">🏍️</div>
            <div>
              <strong style="font-size: 13px; display: block;">You (Rider Report)</strong>
              <span style="font-size: 10px; color: var(--text-tertiary);">Reported Just Now • ${this.escapeHtml(loc)}</span>
            </div>
          </div>
          <div style="display: flex; flex-direction: column; align-items: flex-end; gap: 2px;">
            <span class="trust-badge" style="background: rgba(255, 92, 0, 0.15); border: 1px solid var(--brand-orange); color: #FF8A4C; font-size: 9px; padding: 2px 6px; border-radius: 6px; font-weight: 800;">Pending Consensus</span>
            <span style="font-size: 9px; color: #FFA726; font-family: var(--font-mono);">Key: ${idempotencyKey.slice(0, 10)}</span>
          </div>
        </div>
        <h4 style="font-size: 14px; font-weight: 700; margin-bottom: 4px; color: #FFF;">⚠️ ${this.escapeHtml(cat)} (${this.escapeHtml(sev)})</h4>
        <p style="font-size: 12px; color: var(--text-secondary); line-height: 1.4; margin-bottom: 10px;">${this.escapeHtml(desc)}</p>
        <div style="display: flex; justify-content: space-between; align-items: center; padding-top: 8px; border-top: 1px solid rgba(255, 255, 255, 0.06);">
          <span class="hz-confirm-count" style="font-size: 11px; color: var(--brand-orange); font-weight: 700;">Under Review (1 Confirmation)</span>
          <div style="display: flex; gap: 6px;">
            <button class="hz-btn interactive-squish" style="background: rgba(255, 255, 255, 0.08); border: 1px solid var(--glass-edge); color: white; padding: 4px 10px; border-radius: 8px; font-size: 11px; font-weight: 600;" onclick="window.appPreview && window.appPreview.verifyHazardCard('hz-new', 'CONFIRM', 0.2)">Confirm Active (0.2km)</button>
          </div>
        </div>
      `;
      list.insertBefore(card, list.firstChild);
    }

    this.showToast(`⚠️ Broadcasted PostGIS Hazard: ${cat} with idempotency key ${idempotencyKey.slice(0, 12)}!`);
    this.switchScreen('hazards');
  }

  openCreateClipModal() {
    this.closeCreateSheet();
    sfx.playTap();
    this.showToast('🎬 Clip camera recorder opened: Ready to capture vertical video');
    this.switchScreen('clips');
  }

  openCreateConvoyModal() {
    this.closeCreateSheet();
    sfx.playTap();
    this.showToast('👥 Convoy ride creation wizard: Configure Lead & Sweep');
    this.switchScreen('convoy');
  }

  openAiPlannerFromCreate() {
    this.closeCreateSheet();
    sfx.playTap();
    this.switchScreen('ai-planner');
  }

  closeModal(modalId) {
    const modal = document.getElementById(modalId);
    if (modal) modal.classList.remove('open');
  }

  // ── Notifications & Comms Radio Sheets ──────────────────────────────────────
  openNotifications() {
    const sheet = document.getElementById('notifications-sheet');
    if (sheet) sheet.classList.add('open');
    sfx.playTap();
  }

  closeNotifications() {
    const sheet = document.getElementById('notifications-sheet');
    if (sheet) sheet.classList.remove('open');
  }

  openMessages() {
    const sheet = document.getElementById('messages-sheet');
    if (sheet) sheet.classList.add('open');
    sfx.playTap();
  }

  closeMessages() {
    const sheet = document.getElementById('messages-sheet');
    if (sheet) sheet.classList.remove('open');
  }

  sendCommsMessage() {
    const input = document.getElementById('comms-input');
    if (!input) return;
    const text = input.value.trim();
    if (!text) return;

    const list = document.getElementById('convoy-chat-list');
    if (list) {
      const item = document.createElement('div');
      item.className = 'cbs-comment-item';
      item.innerHTML = `
        <img src="assets/images/rider.jpg" class="cbs-comment-avatar" alt="Vikram">
        <div class="cbs-comment-content">
          <div style="font-size: 11px; font-weight: 700; color: #FF8A4C;">Vikram (Captain)</div>
          <div class="cbs-comment-text">${this.escapeHtml(text)}</div>
          <div class="cbs-comment-time">Just now</div>
        </div>
      `;
      list.appendChild(item);
      list.scrollTop = list.scrollHeight;
    }

    input.value = '';
    sfx.playConvoyPing();
  }

  escapeHtml(str) {
    return str
      .replace(/&/g, '&amp;')
      .replace(/</g, '&lt;')
      .replace(/>/g, '&gt;')
      .replace(/"/g, '&quot;')
      .replace(/'/g, '&#039;');
  }

  // ─────────────────────────────────────────────────────────────
  // FEATURE 1: RIDESTORY RECORDING LIFECYCLE & 9:16 SUMMARY EXPORT
  // ─────────────────────────────────────────────────────────────

  toggleRideRecording() {
    const btnToggle = document.getElementById('btn-hud-record-toggle');
    const btnFinish = document.getElementById('btn-hud-record-finish');
    const dot = document.getElementById('hud-rec-dot');
    const label = document.getElementById('hud-rec-state-label');
    const timerEl = document.getElementById('hud-rec-timer');
    const distEl = document.getElementById('hud-rec-dist');
    const elevEl = document.getElementById('hud-rec-elev');

    if (this.recordingState === 'IDLE') {
      this.recordingState = 'ACTIVE';
      this.recordingSeconds = 0;
      this.recordedDistanceKm = 0.0;
      this.recordedElevationM = 0;

      if (btnToggle) btnToggle.textContent = '⏸️ Pause';
      if (btnFinish) btnFinish.style.display = 'inline-block';
      if (dot) dot.className = 'rec-dot active';
      if (label) label.textContent = 'ACTIVE';

      this.recordingInterval = setInterval(() => {
        this.recordingSeconds++;
        const mins = Math.floor(this.recordingSeconds / 60);
        const secs = this.recordingSeconds % 60;
        if (timerEl) timerEl.textContent = `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;

        // Accumulate realistic mountain distance & elevation
        if (this.currentSpeed > 0) {
          this.recordedDistanceKm += (this.currentSpeed / 3600);
          if (distEl) distEl.textContent = `${this.recordedDistanceKm.toFixed(1)} km`;
          if (Math.random() > 0.6) {
            this.recordedElevationM += Math.floor(Math.random() * 4) + 1;
            if (elevEl) elevEl.textContent = `+${this.recordedElevationM}m`;
          }
        }
      }, 1000);

      this.showToast('🔴 Ride Recording Active: Filtering GPS fixes with Haversine velocity spike guard.');
      sfx.playHazardBeep();
    } else if (this.recordingState === 'ACTIVE') {
      this.recordingState = 'PAUSED';
      clearInterval(this.recordingInterval);
      if (btnToggle) btnToggle.textContent = '▶️ Resume';
      if (dot) dot.className = 'rec-dot paused';
      if (label) label.textContent = 'PAUSED';
      this.showToast('❚❚ Ride Recording Paused.');
    } else if (this.recordingState === 'PAUSED') {
      this.recordingState = 'RESUMED';
      if (btnToggle) btnToggle.textContent = '⏸️ Pause';
      if (dot) dot.className = 'rec-dot active';
      if (label) label.textContent = 'ACTIVE';

      this.recordingInterval = setInterval(() => {
        this.recordingSeconds++;
        const mins = Math.floor(this.recordingSeconds / 60);
        const secs = this.recordingSeconds % 60;
        if (timerEl) timerEl.textContent = `${mins.toString().padStart(2, '0')}:${secs.toString().padStart(2, '0')}`;

        if (this.currentSpeed > 0) {
          this.recordedDistanceKm += (this.currentSpeed / 3600);
          if (distEl) distEl.textContent = `${this.recordedDistanceKm.toFixed(1)} km`;
          if (Math.random() > 0.6) {
            this.recordedElevationM += Math.floor(Math.random() * 4) + 1;
            if (elevEl) elevEl.textContent = `+${this.recordedElevationM}m`;
          }
        }
      }, 1000);

      this.showToast('▶️ Ride Recording Resumed.');
    }
  }

  finishRideRecording() {
    this.recordingState = 'FINISHED';
    clearInterval(this.recordingInterval);

    const btnToggle = document.getElementById('btn-hud-record-toggle');
    const btnFinish = document.getElementById('btn-hud-record-finish');
    const dot = document.getElementById('hud-rec-dot');
    const label = document.getElementById('hud-rec-state-label');

    if (btnToggle) btnToggle.textContent = '🔴 Start Ride';
    if (btnFinish) btnFinish.style.display = 'none';
    if (dot) dot.className = 'rec-dot';
    if (label) label.textContent = 'IDLE';

    // Set stats in RideStory Studio
    const finalDist = this.recordedDistanceKm > 0 ? this.recordedDistanceKm.toFixed(1) : '42.8';
    const finalElev = this.recordedElevationM > 0 ? `+${this.recordedElevationM}m` : '+1,280m';
    const mins = Math.max(1, Math.floor(this.recordingSeconds / 60));
    const finalTime = this.recordingSeconds > 0 ? `${mins}m` : '1h 14m';

    const statDist = document.getElementById('rs-stat-dist');
    const statElev = document.getElementById('rs-stat-elev');
    const statTime = document.getElementById('rs-stat-time');
    if (statDist) statDist.textContent = `${finalDist} km`;
    if (statElev) statElev.textContent = finalElev;
    if (statTime) statTime.textContent = finalTime;

    this.showToast('🏁 Ride Recording Finished! Generated RideStory 9:16 recap card.');
    sfx.playConvoyPing();

    setTimeout(() => {
      this.openRideStoryModal();
    }, 400);

    this.recordingState = 'IDLE';
  }

  openRideStoryModal() {
    const modal = document.getElementById('modal-ridestory');
    if (modal) modal.classList.add('active');

    // Reset scrubber & bike marker
    this.scrubElevationProfile(0);
  }

  closeRideStoryModal() {
    const modal = document.getElementById('modal-ridestory');
    if (modal) modal.classList.remove('active');
  }

  setRideStoryTheme(theme, el) {
    this.currentStoryTheme = theme;
    document.querySelectorAll('.theme-pill').forEach(btn => btn.classList.remove('active'));
    if (el) el.classList.add('active');
    this.showToast(`🎨 Story Theme: ${theme}`);
  }

  scrubElevationProfile(pct) {
    const path = document.getElementById('rs-route-path');
    const bikeMarker = document.getElementById('rsc-bike-marker');
    const statusText = document.getElementById('rs-scrubber-status');

    if (path && bikeMarker) {
      const len = path.getTotalLength ? path.getTotalLength() : 300;
      const point = path.getPointAtLength ? path.getPointAtLength((pct / 100) * len) : { x: 10 + (pct * 3), y: 130 - (pct * 0.8) };
      bikeMarker.style.left = `${point.x}px`;
      bikeMarker.style.top = `${point.y}px`;
    }

    if (statusText) {
      const approxAlt = Math.round(2050 + (pct / 100) * (3980 - 2050));
      statusText.textContent = `${pct}% (${approxAlt}m)`;
    }
  }

  toggleStoryPrivacy(enabled) {
    this.storyPrivacyClipped = enabled;
    const statDist = document.getElementById('rs-stat-dist');
    if (statDist) {
      statDist.textContent = enabled ? '42.8 km' : '43.8 km';
    }
    this.showToast(enabled
      ? '🛡️ Privacy Geofence Enabled: Stripped first and last 500m of polyline.'
      : '⚠️ Privacy Geofence Disabled: Full unclipped polyline exposed.');
  }

  exportRideStoryImage() {
    const canvas = document.getElementById('offscreen-story-canvas');
    const statusEl = document.getElementById('rs-export-status');
    const btnExport = document.getElementById('btn-export-story-png');

    if (!canvas) return;
    if (statusEl) statusEl.style.display = 'block';
    if (btnExport) btnExport.disabled = true;

    setTimeout(() => {
      const ctx = canvas.getContext('2d');
      const w = 1080;
      const h = 1920;

      // 1. Background: Deep Matte Charcoal Gradient
      const bgGrad = ctx.createLinearGradient(0, 0, 0, h);
      bgGrad.addColorStop(0, '#0D1017');
      bgGrad.addColorStop(0.5, '#131822');
      bgGrad.addColorStop(1, '#0A0C10');
      ctx.fillStyle = bgGrad;
      ctx.fillRect(0, 0, w, h);

      // Subtle Top Orange Radial Glow
      const glowGrad = ctx.createRadialGradient(w * 0.85, 200, 10, w * 0.85, 200, 450);
      glowGrad.addColorStop(0, 'rgba(255, 92, 0, 0.35)');
      glowGrad.addColorStop(1, 'rgba(255, 92, 0, 0)');
      ctx.fillStyle = glowGrad;
      ctx.fillRect(0, 0, w, 800);

      // 2. Top Header Brand Pill
      ctx.fillStyle = '#FF5C00';
      ctx.font = 'bold 32px sans-serif';
      ctx.fillText('🏍️ ROADMATE INDIA', 80, 120);

      ctx.fillStyle = 'rgba(255, 255, 255, 0.5)';
      ctx.font = '600 24px monospace';
      ctx.fillText('VIRAL 9:16 EXPEDITION RECAP • 23 OCT 2026', 80, 160);

      // Theme Pill
      ctx.fillStyle = 'rgba(255, 92, 0, 0.2)';
      ctx.strokeStyle = '#FF5C00';
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.roundRect(80, 200, 360, 56, 28);
      ctx.fill();
      ctx.stroke();

      ctx.fillStyle = '#FFB300';
      ctx.font = 'bold 24px sans-serif';
      ctx.fillText(`🏔️ ${this.currentStoryTheme.toUpperCase()}`, 110, 237);

      // 3. Main Title & Region
      ctx.fillStyle = '#FFFFFF';
      ctx.font = 'bold 58px sans-serif';
      ctx.fillText('Manali to Keylong Run', 80, 330);

      ctx.fillStyle = '#FFA726';
      ctx.font = '600 32px sans-serif';
      ctx.fillText('Manali (2,050m) → Rohtang Crest → Keylong (3,080m)', 80, 385);

      // 4. Route Map Box
      const mapBoxY = 440;
      const mapBoxH = 540;
      ctx.fillStyle = '#161B26';
      ctx.strokeStyle = 'rgba(255, 255, 255, 0.12)';
      ctx.lineWidth = 3;
      ctx.beginPath();
      ctx.roundRect(80, mapBoxY, w - 160, mapBoxH, 32);
      ctx.fill();
      ctx.stroke();

      // Mountain Contour Fill inside map box
      ctx.save();
      ctx.beginPath();
      ctx.roundRect(80, mapBoxY, w - 160, mapBoxH, 32);
      ctx.clip();

      const hillGrad = ctx.createLinearGradient(0, mapBoxY + 200, 0, mapBoxY + mapBoxH);
      hillGrad.addColorStop(0, 'rgba(255, 92, 0, 0.35)');
      hillGrad.addColorStop(1, 'rgba(0, 0, 0, 0)');
      ctx.fillStyle = hillGrad;
      ctx.beginPath();
      ctx.moveTo(80, mapBoxY + 380);
      ctx.bezierCurveTo(300, mapBoxY + 120, 600, mapBoxY + 80, w - 80, mapBoxY + 300);
      ctx.lineTo(w - 80, mapBoxY + mapBoxH);
      ctx.lineTo(80, mapBoxY + mapBoxH);
      ctx.closePath();
      ctx.fill();

      // Route Path Stroke
      ctx.strokeStyle = '#FF5C00';
      ctx.lineWidth = 10;
      ctx.lineCap = 'round';
      ctx.beginPath();
      ctx.moveTo(120, mapBoxY + 380);
      ctx.bezierCurveTo(320, mapBoxY + 140, 580, mapBoxY + 90, w - 120, mapBoxY + 300);
      ctx.stroke();

      // Start, Crest, Finish Pins
      ctx.fillStyle = '#FF5C00';
      ctx.beginPath();
      ctx.arc(120, mapBoxY + 380, 14, 0, Math.PI * 2);
      ctx.fill();

      ctx.fillStyle = '#FFD700';
      ctx.beginPath();
      ctx.arc(520, mapBoxY + 115, 18, 0, Math.PI * 2);
      ctx.fill();

      ctx.fillStyle = '#4CAF50';
      ctx.beginPath();
      ctx.arc(w - 120, mapBoxY + 300, 14, 0, Math.PI * 2);
      ctx.fill();

      // Crest Flag
      ctx.fillStyle = '#FFE082';
      ctx.font = 'bold 26px monospace';
      ctx.fillText('Rohtang Crest 3,980m', 420, mapBoxY + 75);

      ctx.restore();

      // 5. Telemetry Metrics 2x2 Grid
      const statGridY = 1030;
      const cardW = (w - 160 - 30) / 2;
      const cardH = 150;

      const drawMetricCard = (x, y, value, label, accentColor = '#FFF') => {
        ctx.fillStyle = 'rgba(255, 255, 255, 0.04)';
        ctx.strokeStyle = 'rgba(255, 255, 255, 0.1)';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.roundRect(x, y, cardW, cardH, 20);
        ctx.fill();
        ctx.stroke();

        ctx.fillStyle = accentColor;
        ctx.font = 'bold 46px monospace';
        ctx.fillText(value, x + 30, y + 70);

        ctx.fillStyle = 'rgba(255, 255, 255, 0.6)';
        ctx.font = '600 22px sans-serif';
        ctx.fillText(label, x + 30, y + 115);
      };

      drawMetricCard(80, statGridY, document.getElementById('rs-stat-dist')?.textContent || '42.8 KM', 'VERIFIED FILTERED DISTANCE', '#FF8A4C');
      drawMetricCard(80 + cardW + 30, statGridY, document.getElementById('rs-stat-time')?.textContent || '1H 14M', 'MOVING TIME (1H 32M ELAPSED)');
      drawMetricCard(80, statGridY + cardH + 20, document.getElementById('rs-stat-elev')?.textContent || '+1,280 M', 'ELEVATION GAIN (CLIMB)', '#81C784');
      drawMetricCard(80 + cardW + 30, statGridY + cardH + 20, 'VERIFIED', 'SAFE SPEED POLICY (NO RACING)', '#64B5F6');

      // 6. Safe Exploration Achievements Section
      const achY = 1410;
      ctx.fillStyle = '#FFA726';
      ctx.font = 'bold 28px sans-serif';
      ctx.fillText('SAFE EXPLORATION ACHIEVEMENTS', 80, achY);

      const badges = [
        '🎖️ First Ride Logged',
        '⛰️ Mountain Route (≥500m)',
        '🏁 100 km in a Day',
        '👥 Group Ride Finisher'
      ];

      let badgeX = 80;
      let badgeY = achY + 30;
      badges.forEach((b, i) => {
        ctx.fillStyle = 'rgba(255, 215, 0, 0.12)';
        ctx.strokeStyle = 'rgba(255, 215, 0, 0.4)';
        ctx.lineWidth = 2;
        ctx.beginPath();
        ctx.roundRect(badgeX, badgeY, 430, 60, 16);
        ctx.fill();
        ctx.stroke();

        ctx.fillStyle = '#FFE082';
        ctx.font = 'bold 24px sans-serif';
        ctx.fillText(b, badgeX + 20, badgeY + 40);

        badgeX += 460;
        if (i === 1) {
          badgeX = 80;
          badgeY += 80;
        }
      });

      // 7. Footer Disclaimer & Watermark
      const footerY = 1750;
      ctx.strokeStyle = 'rgba(255, 255, 255, 0.1)';
      ctx.lineWidth = 2;
      ctx.beginPath();
      ctx.moveTo(80, footerY);
      ctx.lineTo(w - 80, footerY);
      ctx.stroke();

      ctx.fillStyle = 'rgba(255, 255, 255, 0.5)';
      ctx.font = '20px sans-serif';
      ctx.fillText('Verified on RoadMate India • Indian Motorcycle Touring & Convoy Safety Network', 80, footerY + 50);

      ctx.fillStyle = '#FF5C00';
      ctx.font = 'bold 22px monospace';
      ctx.fillText('Privacy Geofenced (500m clipped) • Zero Street Racing Incentives', 80, footerY + 85);

      // Trigger high-res PNG download
      try {
        const link = document.createElement('a');
        link.download = 'ridestory_manali_keylong_1080x1920.png';
        link.href = canvas.toDataURL('image/png');
        link.click();
        this.showToast('🎉 1080x1920 9:16 RideStory downloaded! Ready for Instagram & WhatsApp Status.');
        sfx.playConvoyPing();
      } catch (err) {
        console.error('Canvas export error:', err);
        this.showToast('⚠️ Export completed in buffer.');
      }

      if (statusEl) statusEl.style.display = 'none';
      if (btnExport) btnExport.disabled = false;
    }, 600);
  }

  exportGPXTrack() {
    sfx.playTap();
    const points = (this.recordedPoints && this.recordedPoints.length >= 2) ? this.recordedPoints : [
      { lat: 32.2396, lng: 77.1887, altitude: 2050, speed_kmh: 42, timestamp: "2026-10-23T06:00:00Z" },
      { lat: 32.3012, lng: 77.2050, altitude: 2560, speed_kmh: 48, timestamp: "2026-10-23T06:30:00Z" },
      { lat: 32.3712, lng: 77.2144, altitude: 3980, speed_kmh: 38, timestamp: "2026-10-23T07:15:00Z" },
      { lat: 32.4800, lng: 77.0600, altitude: 3120, speed_kmh: 55, timestamp: "2026-10-23T07:50:00Z" },
      { lat: 32.5500, lng: 77.0300, altitude: 3080, speed_kmh: 50, timestamp: "2026-10-23T08:20:00Z" }
    ];

    const title = document.getElementById('rs-title-display')?.textContent || 'Manali to Keylong Expedition';
    const gpxLines = [
      '<?xml version="1.0" encoding="UTF-8"?>',
      '<gpx version="1.1" creator="RoadMate India — Touring Safety Platform" xmlns="http://www.topografix.com/GPX/1/1">',
      `  <metadata><name>${title}</name><time>${new Date().toISOString()}</time></metadata>`,
      `  <trk><name>${title}</name><type>Motorcycle Touring</type><trkseg>`,
    ];

    points.forEach(p => {
      const lat = p.lat || 32.2396;
      const lng = p.lng || 77.1887;
      const ele = p.altitude || 2050.0;
      const t = p.timestamp || new Date().toISOString();
      gpxLines.push(`    <trkpt lat="${lat}" lon="${lng}"><ele>${ele}</ele><time>${t}</time></trkpt>`);
    });

    gpxLines.push('  </trkseg></trk>');
    gpxLines.push('</gpx>');

    const gpxText = gpxLines.join('\n');
    const blob = new Blob([gpxText], { type: 'application/gpx+xml' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'roadmate_manali_keylong.gpx';
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);

    this.showToast('🗺️ Downloaded valid GPX 1.1 file! Ready for OsmAnd, Garmin & GPS viewers.');
    sfx.playConvoyPing();
  }

  exportGeoJSONTrack() {
    sfx.playTap();
    const points = (this.recordedPoints && this.recordedPoints.length >= 2) ? this.recordedPoints : [
      { lat: 32.2396, lng: 77.1887, altitude: 2050 },
      { lat: 32.3012, lng: 77.2050, altitude: 2560 },
      { lat: 32.3712, lng: 77.2144, altitude: 3980 },
      { lat: 32.4800, lng: 77.0600, altitude: 3120 },
      { lat: 32.5500, lng: 77.0300, altitude: 3080 }
    ];

    const title = document.getElementById('rs-title-display')?.textContent || 'Manali to Keylong Expedition';
    const coords = points.map(p => [p.lng, p.lat, p.altitude || 0]);

    const geojson = {
      type: "FeatureCollection",
      features: [
        {
          type: "Feature",
          properties: {
            title: title,
            distance_km: 42.8,
            elevation_gain_m: 1280,
            exported_at: new Date().toISOString(),
            platform: "RoadMate India"
          },
          geometry: {
            type: "LineString",
            coordinates: coords
          }
        }
      ]
    };

    const blob = new Blob([JSON.stringify(geojson, null, 2)], { type: 'application/geo+json' });
    const url = URL.createObjectURL(blob);
    const a = document.createElement('a');
    a.href = url;
    a.download = 'roadmate_manali_keylong.geojson';
    document.body.appendChild(a);
    a.click();
    document.body.removeChild(a);
    URL.revokeObjectURL(url);

    this.showToast('📐 Downloaded GeoJSON track! Ready for QGIS, Mapbox & Web GIS tools.');
    sfx.playConvoyPing();
  }

  shareOrPublishStory() {
    sfx.playTap();
    const title = document.getElementById('rs-title-display')?.textContent || 'Manali to Keylong Expedition';
    const text = `Check out my verified motorcycle tour "${title}" on RoadMate India! +1,280m climbing across Rohtang Pass.`;

    if (navigator.share) {
      navigator.share({
        title: title,
        text: text,
        url: window.location.href
      }).then(() => {
        this.showToast('🚀 Story shared successfully via Native Share!');
      }).catch(() => {
        this.copyStoryLink(text);
      });
    } else {
      this.copyStoryLink(text);
    }

    // Publish to local community feed in UI
    const feed = document.querySelector('.feed-posts-stack');
    if (feed) {
      const card = document.createElement('div');
      card.className = 'post-card glass-surface interactive-squish';
      card.style.cssText = 'border-radius: 20px; padding: 16px; margin-bottom: 16px; border: 1.5px solid #FF5C00; animation: fadeIn 0.4s ease;';
      card.innerHTML = `
        <div style="display: flex; align-items: center; justify-content: space-between; margin-bottom: 10px;">
          <div style="display: flex; align-items: center; gap: 8px;">
            <div style="width: 36px; height: 36px; border-radius: 50%; background: #FF5C00; display: flex; align-items: center; justify-content: center; font-size: 16px;">🏍️</div>
            <div>
              <strong style="font-size: 14px; color: #FFF;">You (Aman Jha)</strong>
              <span style="font-size: 11px; color: #FFA726; display: block;">Just Published • RideStory Recap</span>
            </div>
          </div>
          <span class="pillar-badge badge-orange" style="font-size: 9px;">9:16 RECAP</span>
        </div>
        <h4 style="font-size: 15px; font-weight: 800; color: #FFF; margin-bottom: 4px;">${this.escapeHtml(title)}</h4>
        <p style="font-size: 12px; color: var(--text-secondary); margin-bottom: 10px;">42.8 km • 1h 14m moving • +1,280m climb across Rohtang Crest (3,980m) • Safe Speed Policy Active</p>
        <div style="display: flex; gap: 6px; margin-bottom: 10px;">
          <span class="rsc-badge-chip">🎖️ First Ride</span>
          <span class="rsc-badge-chip">⛰️ Mountain Route</span>
        </div>
        <div style="display: flex; justify-content: space-between; align-items: center; padding-top: 10px; border-top: 1px solid rgba(255,255,255,0.08);">
          <span style="font-size: 12px; color: #FF5C00; font-weight: 700;">❤️ 1 Like • 🔖 Saved</span>
          <button class="cta-blaze-btn interactive-squish" style="padding: 4px 10px; font-size: 10px;" onclick="window.appPreview && window.appPreview.openRideStoryModal()">View 9:16 Story</button>
        </div>
      `;
      feed.insertBefore(card, feed.firstChild);
    }
  }

  copyStoryLink(text) {
    if (navigator.clipboard) {
      navigator.clipboard.writeText(text).then(() => {
        this.showToast('📋 Story link & summary copied to clipboard! Ready to paste in WhatsApp.');
      });
    } else {
      this.showToast('🚀 Story published to your RoadMate touring feed!');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // FEATURE 2: TRUSTED ROAD INTELLIGENCE (HAZARD VERIFY & PROXIMITY)
  // ─────────────────────────────────────────────────────────────

  verifyHazardCard(hazardId, action, distanceKm) {
    // 5 km Anti-Spam Proximity Guard
    if (distanceKm > 5.0) {
      sfx.playHazardBeep();
      this.showToast(`⚠️ Anti-Spam Guard: Voter is ${distanceKm} km away. Proximity verification requires being within 5.0 km of the hazard.`);
      return;
    }

    sfx.playConvoyPing();
    this.showToast(`✓ Verified! Recorded ${action} vote at ${distanceKm} km distance. Confidence score updated.`);

    const card = document.querySelector(`.hazard-card[data-hz-type]`);
    if (card) {
      const confirmLabel = card.querySelector('.hz-confirm-count');
      const trustBadge = card.querySelector('.trust-badge');
      if (confirmLabel) {
        confirmLabel.textContent = `✓ 15 Rider Confirmations (${action === 'CONFIRM' ? 'CONFIRMED' : 'UPDATED'})`;
        confirmLabel.style.color = '#81C784';
      }
      if (trustBadge) {
        trustBadge.textContent = '99% Trust • High Consensus';
      }
    }
  }

  filterHazards(category, el) {
    document.querySelectorAll('.hazard-filter-chips .chip').forEach(btn => btn.classList.remove('active'));
    if (el) el.classList.add('active');

    const cards = document.querySelectorAll('#preview-hazards-list .hazard-card');
    cards.forEach(card => {
      if (category === 'all' || card.dataset.hzType === category) {
        card.style.display = 'block';
      } else {
        card.style.display = 'none';
      }
    });

    this.showToast(`🔍 Filtered hazards: ${category.replace('_', ' ').toUpperCase()}`);
  }

  // ─────────────────────────────────────────────────────────────
  // FEATURE 3: FUEL-RANGE PLANNER & TOURING CORRIDOR SERVICES
  // ─────────────────────────────────────────────────────────────

  applyFuelPreset(tank, eff, fuel, reserve, dist, isAlt, el) {
    document.querySelectorAll('.fpc-preset-chip').forEach(btn => btn.classList.remove('active'));
    if (el) el.classList.add('active');

    const tankInput = document.getElementById('fp-tank-capacity');
    const effInput = document.getElementById('fp-efficiency');
    const fuelInput = document.getElementById('fp-current-fuel');
    const resInput = document.getElementById('fp-reserve');
    const distInput = document.getElementById('fp-distance');
    const altChk = document.getElementById('fp-altitude-chk');

    if (tankInput) tankInput.value = tank;
    if (effInput) effInput.value = eff;
    if (fuelInput) fuelInput.value = fuel;
    if (resInput) resInput.value = reserve;
    if (distInput) distInput.value = dist;
    if (altChk) altChk.checked = isAlt;

    this.recalculateFuelPlanner();
  }

  recalculateFuelPlanner() {
    const tank = parseFloat(document.getElementById('fp-tank-capacity')?.value) || 17.0;
    let eff = parseFloat(document.getElementById('fp-efficiency')?.value) || 28.0;
    const fuel = parseFloat(document.getElementById('fp-current-fuel')?.value) || 6.5;
    const reserve = parseFloat(document.getElementById('fp-reserve')?.value) || 2.0;
    const dist = parseFloat(document.getElementById('fp-distance')?.value) || 365.0;
    const isAlt = document.getElementById('fp-altitude-chk')?.checked || false;

    if (isAlt) {
      eff *= 0.82; // 18% altitude loss above 3,000m
    }

    const usableFuel = Math.max(0.0, fuel - reserve);
    const usableRange = Math.round(usableFuel * eff);
    const totalRange = Math.round(fuel * eff);
    const margin = usableRange - dist;

    const resultBox = document.getElementById('fp-result-box');
    const statusLabel = document.getElementById('fp-status-label');
    const usableBadge = document.getElementById('fp-usable-badge');
    const advisoryText = document.getElementById('fp-advisory-text');

    if (usableBadge) usableBadge.textContent = `Usable: ${usableRange} km`;

    if (margin >= 0) {
      if (resultBox) {
        resultBox.className = 'fpc-result-box safe';
      }
      if (statusLabel) {
        statusLabel.textContent = `🟢 SAFE: +${margin} km Buffer Available`;
        statusLabel.style.color = '#81C784';
      }
      if (advisoryText) {
        advisoryText.textContent = `Range is adequate. You have a ${margin} km buffer beyond the ${reserve}L reserve. Next pump is within safe reach!`;
      }
    } else {
      const shortageKm = Math.abs(margin);
      const deficitL = (shortageKm / eff).toFixed(1);
      const jerryCanL = Math.ceil(deficitL / 5.0) * 5;

      if (resultBox) {
        resultBox.className = 'fpc-result-box deficit';
      }
      if (statusLabel) {
        statusLabel.textContent = `🚨 DEFICIT WARNING: Short by ${shortageKm} km`;
        statusLabel.style.color = '#FF5252';
      }
      if (advisoryText) {
        advisoryText.textContent = `Critical deficit: Short by ${shortageKm} km to next pump. Minimum ${deficitL}L extra fuel required — carry ${jerryCanL}L auxiliary jerry can!`;
      }
    }
  }

  confirmTouringService(serviceId, serviceName) {
    sfx.playConvoyPing();
    const el = document.getElementById(serviceId === 'srv-01' ? 'srv-tandi-confirm' : 'srv-jispa-confirm');
    if (el) {
      const cur = parseInt(el.textContent.match(/\d+/)?.[0] || '84', 10);
      el.textContent = `✓ ${cur + 1} Rider Audits`;
    }
    this.showToast(`✓ Verified status for ${serviceName}! Intel updated.`);
  }

  reportTouringClosed(serviceId, serviceName) {
    this.showToast(`⚠️ ${serviceName} reported closed. Flagged for community audit.`);
  }

  // ─────────────────────────────────────────────────────────────
  // FEATURE 4: SMART CONVOY CHECK-IN & REGROUP BROADCASTS
  // ─────────────────────────────────────────────────────────────

  broadcastConvoyCheckIn(type) {
    if (type === 'REGROUP') {
      sfx.playHazardBeep();
      this.showToast('📍 SQUAD REGROUP BEACON: Calling pack regroup at next safe pullout!');
      const alertBanner = document.getElementById('hud-separation-alert');
      if (alertBanner) alertBanner.style.display = 'none';
    } else if (type === 'IM_OK') {
      sfx.playConvoyPing();
      this.showToast("📸 Broadcast to Squad: I'm OK / Stopping for Photo at Rohtang Pass.");
      const alertBanner = document.getElementById('hud-separation-alert');
      if (alertBanner) alertBanner.style.display = 'none';
    }
  }
}

// Instantiate on DOM Loaded
document.addEventListener('DOMContentLoaded', () => {
  window.appPreview = new AppPreview();
  window.app = window.appPreview;

  // Register PWA Service Worker for standalone install & offline caching
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker.register('/sw.js')
      .then(reg => console.log('⚡ [RoadMate PWA] Service Worker registered:', reg.scope))
      .catch(err => console.debug('[RoadMate PWA] Service Worker note:', err));
  }
  // URL query parameter router for deep linking and screenshot testing
  try {
    const urlParams = new URLSearchParams(window.location.search);
    const modeParam = urlParams.get('mode');
    const screenParam = urlParams.get('screen');
    const modalParam = urlParams.get('modal');

    if (modeParam) window.appPreview.setMode(modeParam);
    if (screenParam) window.appPreview.switchScreen(screenParam);
    if (modalParam === 'ridestory') window.appPreview.openRideStoryModal();
    if (modalParam === 'hazard') window.appPreview.openReportHazardModal();
  } catch (err) {
    console.debug('URL params navigation note:', err);
  }
});



