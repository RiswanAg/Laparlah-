// ============================================================
//  LAPAR LAH!
//  BITE3523 Game Physics — Processing 4
//  Feed Oyen the orange cat his fish!
// ============================================================

// ── GAME STATES ──────────────────────────────────────────────
final int MENU   = 0;
final int LEVEL1 = 1;
final int LEVEL2 = 2;
final int LEVEL3 = 3;
final int WIN    = 4;
final int LOSE   = 5;

int gameState    = MENU;
int currentLevel = 1;

// ── PHYSICS CONSTANTS ─────────────────────────────────────────
float GRAVITY      = 0.35;
float STIFFNESS    = 0.85;   // Hooke's Law k for rope segments
float DAMPING      = 0.98;
float ROPE_SEG_LEN = 20;     // natural length of each rope segment
int   SOLVER_ITERS = 15;     // constraint iterations per frame

// ── COLOURS ──────────────────────────────────────────────────
color COL_BG      = color(135, 206, 235);
color COL_ROPE    = color(139, 90,  43);
color COL_FISH    = color(192, 192, 192);
color COL_OYEN    = color(255, 140,   0);
color COL_SPIKE   = color(220,  40,  40);
color COL_BTN     = color( 30,  80, 160);
color COL_BTN_TXT = color(255, 255, 255);
color COL_HUD     = color(255, 255, 255);

// ── GAME OBJECTS ─────────────────────────────────────────────
ArrayList<Rope>  ropes  = new ArrayList<Rope>();
ArrayList<Spike> spikes = new ArrayList<Spike>();
Fish fish;
Oyen oyen;

// ── WIN TRACKING ─────────────────────────────────────────────
boolean showWinAnim = false;
int     winTimer    = 0;

// ── ROPE SLICING ─────────────────────────────────────────────
boolean slicing  = false;
float   sliceX1, sliceY1, sliceX2, sliceY2;
ArrayList<float[]> slashTrails = new ArrayList<float[]>(); // [x1,y1,x2,y2,life]

// ============================================================
//  SETUP
// ============================================================
void setup() {
  size(900, 600);
  frameRate(60);
  textFont(createFont("Arial Bold", 16));
  gameState = MENU;
}

// ============================================================
//  DRAW
// ============================================================
void draw() {
  switch (gameState) {
    case MENU:   drawMenu();  break;
    case LEVEL1:
    case LEVEL2:
    case LEVEL3: drawGame();  break;
    case WIN:    drawWin();   break;
    case LOSE:   drawLose();  break;
  }
}

// ============================================================
//  MENU SCREEN
// ============================================================
void drawMenu() {
  background(COL_BG);

  // Floor
  fill(200, 160, 100); noStroke();
  rect(0, height - 60, width, 60);

  // Decorative Oyen
  drawOyenAt(width/2, height - 100, 60, false);

  // Dangling fish
  fill(COL_FISH); stroke(150); strokeWeight(2);
  ellipse(width/2, height - 220, 30, 18);
  stroke(COL_ROPE); strokeWeight(2);
  line(width/2, height - 220, width/2, height - 280);

  // Title box
  noStroke();
  fill(30, 80, 160);
  rect(width/2 - 200, 60, 400, 100, 14);
  fill(255);
  textAlign(CENTER, CENTER);
  textSize(42);
  text("Lapar Lah!", width/2, 95);
  textSize(15);
  text("Help Oyen get his fish!", width/2, 138);

  drawButton("Play Level 1", width/2, 260, 200, 46);
  drawButton("Play Level 2", width/2, 320, 200, 46);
  drawButton("Play Level 3", width/2, 380, 200, 46);
  drawButton("Quit",         width/2, 440, 200, 46);

  fill(60); textSize(12); textAlign(CENTER, CENTER);
  text("Slice across ropes to cut them  |  R = reset  |  ESC = menu", width/2, 560);
}

// ============================================================
//  GAME SCREEN
// ============================================================
void drawGame() {
  background(COL_BG);

  // Floor
  fill(200, 160, 100); noStroke();
  rect(0, height - 60, width, 60);

  // Ceiling
  fill(180, 140, 80); noStroke();
  rect(0, 0, width, 20);

  // Draw spikes
  for (Spike s : spikes) s.draw();

  // Draw ropes
  for (Rope r : ropes) r.draw();

  // Draw fish
  if (fish != null) fish.draw();

  // Draw Oyen
  if (oyen != null) oyen.draw(showWinAnim);

  // Draw slash trails — fade out over 10 frames
  for (int i = slashTrails.size() - 1; i >= 0; i--) {
    float[] t = slashTrails.get(i);
    float alpha = map(t[4], 0, 10, 0, 255);
    stroke(255, 255, 255, alpha); strokeWeight(3); noFill();
    line(t[0], t[1], t[2], t[3]);
    t[4]--;
    if (t[4] <= 0) slashTrails.remove(i);
  }

  // Draw active slice line
  if (slicing) {
    stroke(255, 255, 200, 160); strokeWeight(2);
    line(sliceX1, sliceY1, sliceX2, sliceY2);
  }

  // HUD
  drawHUD();

  // Update physics
  updatePhysics();
  checkWinLose();

  // Win animation timer
  if (showWinAnim) {
    winTimer++;
    if (winTimer > 90) {
      gameState = WIN;
      showWinAnim = false;
      winTimer = 0;
    }
  }
}

// ── HUD ───────────────────────────────────────────────────────
void drawHUD() {
  fill(0, 0, 0, 120); noStroke();
  rect(0, 0, width, 50);
  fill(COL_HUD);
  textAlign(LEFT, CENTER); textSize(14);
  text("Level " + currentLevel, 16, 26);
  textAlign(CENTER, CENTER);
  text("Slice ropes to cut  |  R = reset  |  ESC = menu", width/2, 26);
}

// ============================================================
//  WIN SCREEN
// ============================================================
void drawWin() {
  background(255, 200, 50);
  fill(180, 80, 0);
  textAlign(CENTER, CENTER);
  textSize(52);
  text("Sedap!", width/2, 160);
  fill(80, 40, 0);
  textSize(22);
  text("Oyen dapat ikan dia!", width/2, 230);

  drawOyenAt(width/2, 340, 80, true);

  int btnY = 430;
  if (currentLevel < 3) {
    drawButton("Next Level", width/2, btnY, 200, 46);
    btnY += 60;
  }
  drawButton("Retry",     width/2, btnY,      200, 46);
  drawButton("Main Menu", width/2, btnY + 60, 200, 46);
}

// ============================================================
//  LOSE SCREEN
// ============================================================
void drawLose() {
  background(80, 50, 30);
  fill(255, 160, 50);
  textAlign(CENTER, CENTER);
  textSize(52);
  text("Lapar Lagi!", width/2, 160);
  fill(220, 180, 100);
  textSize(20);
  text("Ikan jatuh tak kena mulut Oyen...", width/2, 230);

  drawOyenAt(width/2, 340, 80, false);

  drawButton("Cuba Lagi",  width/2, 430, 200, 46);
  drawButton("Main Menu",  width/2, 490, 200, 46);
}

// ============================================================
//  PHYSICS UPDATE
// ============================================================
void updatePhysics() {
  if (showWinAnim) return;

  // Multiple constraint solver passes for stability
  for (int iter = 0; iter < SOLVER_ITERS; iter++) {
    for (Rope r : ropes) r.solveConstraints();
  }

  // Integrate rope joint positions
  for (Rope r : ropes) r.update();

  // Integrate fish
  if (fish != null) fish.update(ropes);
}

// ============================================================
//  WIN / LOSE CHECK
// ============================================================
void checkWinLose() {
  if (fish == null || showWinAnim) return;

  // Win: fish enters Oyen's mouth
  if (oyen != null) {
    float d = dist(fish.x, fish.y, oyen.mouthX(), oyen.mouthY());
    if (d < oyen.mouthR + fish.r) {
      showWinAnim = true;
      winTimer = 0;
      return;
    }
  }

  // Lose: fish hits spike — circle vs line segment
  for (Spike s : spikes) {
    if (s.hits(fish)) { gameState = LOSE; return; }
  }

  // Lose: fish leaves screen
  if (fish.y > height + 50)               { gameState = LOSE; return; }
  if (fish.x < -50 || fish.x > width + 50) { gameState = LOSE; }
}

// ============================================================
//  LOAD LEVELS
// ============================================================
void loadLevel(int lvl) {
  currentLevel = lvl;
  ropes.clear();
  spikes.clear();
  slashTrails.clear();
  slicing = false;
  showWinAnim = false;
  winTimer = 0;

  if (lvl == 1) {
    // ── LEVEL 1: Straight Drop ────────────────────────────────
    // One rope directly above Oyen. Cut it, fish falls straight down.
    oyen = new Oyen(width/2, height - 65);
    fish = new Fish(width/2, 180);
    ropes.add(new Rope(width/2, 20, fish, 8));

  } else if (lvl == 2) {
    // ── LEVEL 2: The Pendulum ─────────────────────────────────
    // Two ropes. Cut left rope → fish pendulums right into Oyen.
    // Right anchor is far right so the arc carries fish to Oyen.
    oyen = new Oyen(700, height - 65);
    fish = new Fish(200, 200);
    ropes.add(new Rope( 80, 20, fish,  9)); // left rope
    ropes.add(new Rope(480, 20, fish, 14)); // right rope — longer for wide arc
    // Spike on left wall punishes cutting wrong rope first
    spikes.add(new Spike(60, height - 200, 60, height - 80));

  } else {
    // ── LEVEL 3: Triple Rope Challenge ───────────────────────
    // Three ropes hold the fish. Center rope locks it in place.
    // Cut center first (releases vertical hold), then left → wide right swing.
    // Floor spike blocks a straight fall; left spike punishes wrong order.
    oyen = new Oyen(820, height - 65);
    fish = new Fish(310, 170);
    ropes.add(new Rope(100, 20, fish, 11)); // left
    ropes.add(new Rope(310, 20, fish,  8)); // center (straight up)
    ropes.add(new Rope(570, 20, fish, 13)); // right
    // Left wall spike
    spikes.add(new Spike(60, height - 220, 60, height - 80));
    // Center floor spike — punishes uncontrolled fall
    spikes.add(new Spike(300, height - 70, 530, height - 70));
  }
}

// ============================================================
//  SLICING — line vs line intersection (Cramer's rule)
// ============================================================
boolean lineIntersects(float ax, float ay, float bx, float by,
                       float cx, float cy, float dx, float dy) {
  float d1x = bx - ax, d1y = by - ay;
  float d2x = dx - cx, d2y = dy - cy;
  float cross = d1x * d2y - d1y * d2x;
  if (abs(cross) < 0.001) return false; // parallel
  float t = ((cx - ax) * d2y - (cy - ay) * d2x) / cross;
  float u = ((cx - ax) * d1y - (cy - ay) * d1x) / cross;
  return t >= 0 && t <= 1 && u >= 0 && u <= 1;
}

void checkSlice() {
  for (Rope r : ropes) {
    if (r.cut) continue;
    for (int i = 0; i < r.joints.size() - 1; i++) {
      RopeJoint a = r.joints.get(i);
      RopeJoint b = r.joints.get(i + 1);
      if (lineIntersects(sliceX1, sliceY1, sliceX2, sliceY2,
                         a.x, a.y, b.x, b.y)) {
        r.cut = true;
        slashTrails.add(new float[]{ sliceX1, sliceY1, sliceX2, sliceY2, 10 });
        break;
      }
    }
  }
}

// ============================================================
//  MOUSE INPUT
// ============================================================
void mousePressed() {
  // ── MENU ──
  if (gameState == MENU) {
    if (overButton(width/2, 260, 200, 46)) { loadLevel(1); gameState = LEVEL1; }
    if (overButton(width/2, 320, 200, 46)) { loadLevel(2); gameState = LEVEL2; }
    if (overButton(width/2, 380, 200, 46)) { loadLevel(3); gameState = LEVEL3; }
    if (overButton(width/2, 440, 200, 46)) exit();
    return;
  }

  // ── WIN ──
  if (gameState == WIN) {
    int btnY = 430;
    if (currentLevel < 3) {
      if (overButton(width/2, btnY, 200, 46)) {
        int next = currentLevel + 1;
        loadLevel(next);
        gameState = next == 2 ? LEVEL2 : LEVEL3;
        return;
      }
      btnY += 60;
    }
    if (overButton(width/2, btnY, 200, 46)) {
      loadLevel(currentLevel);
      gameState = currentLevel == 1 ? LEVEL1 : currentLevel == 2 ? LEVEL2 : LEVEL3;
      return;
    }
    if (overButton(width/2, btnY + 60, 200, 46)) { gameState = MENU; }
    return;
  }

  // ── LOSE ──
  if (gameState == LOSE) {
    if (overButton(width/2, 430, 200, 46)) {
      loadLevel(currentLevel);
      gameState = currentLevel == 1 ? LEVEL1 : currentLevel == 2 ? LEVEL2 : LEVEL3;
      return;
    }
    if (overButton(width/2, 490, 200, 46)) { gameState = MENU; }
    return;
  }

  // ── GAME: begin slice drag ──
  if (!showWinAnim) {
    slicing = true;
    sliceX1 = sliceX2 = mouseX;
    sliceY1 = sliceY2 = mouseY;
  }
}

void mouseDragged() {
  if (!slicing) return;
  sliceX2 = mouseX;
  sliceY2 = mouseY;
  checkSlice();
}

void mouseReleased() {
  slicing = false;
}

// ============================================================
//  KEYBOARD INPUT
// ============================================================
void keyPressed() {
  if (key == 'r' || key == 'R') {
    if (gameState == LEVEL1 || gameState == LEVEL2 || gameState == LEVEL3 ||
        gameState == WIN    || gameState == LOSE) {
      loadLevel(currentLevel);
      gameState = currentLevel == 1 ? LEVEL1 : currentLevel == 2 ? LEVEL2 : LEVEL3;
    }
  }
  if (keyCode == ESC) {
    key = 0; // suppress Processing's default ESC-quit behaviour
    gameState = MENU;
  }
}

// ============================================================
//  DRAW OYEN (reusable helper)
// ============================================================
void drawOyenAt(float x, float y, float sz, boolean eating) {
  // Body
  fill(COL_OYEN); noStroke();
  ellipse(x, y, sz, sz * 0.85);

  // Ears
  fill(COL_OYEN);
  triangle(x - sz*0.35, y - sz*0.35, x - sz*0.15, y - sz*0.55, x - sz*0.05, y - sz*0.3);
  triangle(x + sz*0.35, y - sz*0.35, x + sz*0.15, y - sz*0.55, x + sz*0.05, y - sz*0.3);

  // Inner ears
  fill(255, 180, 180);
  triangle(x - sz*0.28, y - sz*0.35, x - sz*0.15, y - sz*0.5, x - sz*0.1, y - sz*0.32);
  triangle(x + sz*0.28, y - sz*0.35, x + sz*0.15, y - sz*0.5, x + sz*0.1, y - sz*0.32);

  // Eyes
  fill(50); noStroke();
  if (eating) {
    stroke(50); strokeWeight(2); noFill();
    arc(x - sz*0.18, y - sz*0.08, sz*0.18, sz*0.12, PI, TWO_PI);
    arc(x + sz*0.18, y - sz*0.08, sz*0.18, sz*0.12, PI, TWO_PI);
  } else {
    ellipse(x - sz*0.18, y - sz*0.08, sz*0.13, sz*0.15);
    ellipse(x + sz*0.18, y - sz*0.08, sz*0.13, sz*0.15);
    fill(0);
    ellipse(x - sz*0.18, y - sz*0.06, sz*0.07, sz*0.1);
    ellipse(x + sz*0.18, y - sz*0.06, sz*0.07, sz*0.1);
  }

  // Nose
  fill(255, 100, 120); noStroke();
  triangle(x - sz*0.04, y + sz*0.05, x + sz*0.04, y + sz*0.05, x, y + sz*0.1);

  // Whiskers
  stroke(80); strokeWeight(1);
  line(x - sz*0.45, y + sz*0.04, x - sz*0.1, y + sz*0.06);
  line(x - sz*0.45, y + sz*0.1,  x - sz*0.1, y + sz*0.1);
  line(x + sz*0.45, y + sz*0.04, x + sz*0.1, y + sz*0.06);
  line(x + sz*0.45, y + sz*0.1,  x + sz*0.1, y + sz*0.1);

  // Mouth — open wide when waiting, closed smile when eating
  noFill(); stroke(50); strokeWeight(2);
  if (eating) {
    arc(x, y + sz*0.2, sz*0.4, sz*0.2, 0, PI);
  } else {
    arc(x, y + sz*0.18, sz*0.45, sz*0.28, 0, PI);
  }
}

// ============================================================
//  UI HELPERS
// ============================================================
void drawButton(String label, float cx, float cy, float w, float h) {
  boolean hover = overButton(cx, cy, w, h);
  fill(hover ? color(50, 120, 220) : COL_BTN);
  noStroke();
  rect(cx - w/2, cy - h/2, w, h, 10);
  fill(COL_BTN_TXT);
  textAlign(CENTER, CENTER); textSize(15);
  text(label, cx, cy);
}

boolean overButton(float cx, float cy, float w, float h) {
  return mouseX > cx - w/2 && mouseX < cx + w/2 &&
         mouseY > cy - h/2 && mouseY < cy + h/2;
}

// ============================================================
//  ROPE CLASS — Verlet chain with Hooke's Law springs
// ============================================================
class RopeJoint {
  float x, y, px, py; // current and previous position (Verlet)
  boolean pinned;      // true = fixed ceiling anchor

  RopeJoint(float x, float y, boolean pinned) {
    this.x = x; this.y = y;
    this.px = x; this.py = y;
    this.pinned = pinned;
  }

  void update() {
    if (pinned) return;
    // Verlet integration: velocity implicit in (x - px)
    float vx = (x - px) * DAMPING;
    float vy = (y - py) * DAMPING;
    px = x; py = y;
    x += vx;
    y += vy + GRAVITY;
  }
}

class Rope {
  ArrayList<RopeJoint> joints = new ArrayList<RopeJoint>();
  Fish attachedFish;
  boolean cut = false;
  float anchorX, anchorY;

  Rope(float ax, float ay, Fish f, int segments) {
    anchorX = ax; anchorY = ay;
    attachedFish = f;

    // Space joints evenly from anchor down to fish
    for (int i = 0; i <= segments; i++) {
      float t = (float) i / segments;
      float jx = lerp(ax, f.x, t);
      float jy = lerp(ay, f.y, t);
      joints.add(new RopeJoint(jx, jy, i == 0));
    }
  }

  void update() {
    if (cut) return;
    for (RopeJoint j : joints) j.update();
    // Pin last joint to fish position
    RopeJoint last = joints.get(joints.size() - 1);
    last.x = attachedFish.x;
    last.y = attachedFish.y;
  }

  void solveConstraints() {
    if (cut) return;

    // Hooke's Law: keep adjacent joints at rest length
    // F = k * (currentLength - restLength)
    for (int i = 0; i < joints.size() - 1; i++) {
      RopeJoint a = joints.get(i);
      RopeJoint b = joints.get(i + 1);
      float dx = b.x - a.x;
      float dy = b.y - a.y;
      float len = sqrt(dx*dx + dy*dy);
      if (len == 0) continue;

      float stretch = len - ROPE_SEG_LEN;  // F = k * stretch
      float nx = dx / len;
      float ny = dy / len;
      float corr = stretch * STIFFNESS * 0.5;

      if (!a.pinned) { a.x += nx * corr; a.y += ny * corr; }
      if (!b.pinned) { b.x -= nx * corr; b.y -= ny * corr; }
    }

    // Pendulum constraint: apply tension from rope end to fish.
    // This is the key to making the swing work correctly.
    // Uses rigid constraint (position + velocity correction) so fish
    // arcs naturally rather than just getting a weak spring nudge.
    if (joints.size() >= 2) {
      RopeJoint secondLast = joints.get(joints.size() - 2);
      float dx = attachedFish.x - secondLast.x;
      float dy = attachedFish.y - secondLast.y;
      float d  = sqrt(dx*dx + dy*dy);

      if (d > ROPE_SEG_LEN && d > 0) {
        float nx = dx / d;
        float ny = dy / d;
        float excess = d - ROPE_SEG_LEN;

        // Position correction — pull fish back to rope rest length
        attachedFish.x -= nx * excess * STIFFNESS;
        attachedFish.y -= ny * excess * STIFFNESS;

        // Velocity correction — remove radial (stretching) component.
        // This redirects fish velocity along the pendulum arc (F=ma centripetal).
        float radial = attachedFish.vx * nx + attachedFish.vy * ny;
        if (radial > 0) {
          attachedFish.vx -= nx * radial;
          attachedFish.vy -= ny * radial;
        }
      }
    }

    // Sync last joint to fish after corrections
    RopeJoint last = joints.get(joints.size() - 1);
    last.x = attachedFish.x;
    last.y = attachedFish.y;
  }

  void draw() {
    if (cut) return;
    for (int i = 0; i < joints.size() - 1; i++) {
      RopeJoint a = joints.get(i);
      RopeJoint b = joints.get(i + 1);
      stroke(COL_ROPE); strokeWeight(4);
      line(a.x, a.y, b.x, b.y);
    }
    // Ceiling anchor dot
    fill(100); noStroke();
    ellipse(joints.get(0).x, joints.get(0).y, 12, 12);
  }
}

// ============================================================
//  FISH CLASS — rigid body with F = ma dynamics
// ============================================================
class Fish {
  float x, y;
  float vx, vy;
  float r = 18; // collision radius
  float angle = 0;

  Fish(float x, float y) {
    this.x = x; this.y = y;
    this.vx = 0; this.vy = 0;
  }

  void update(ArrayList<Rope> ropes) {
    boolean allCut = true;
    for (Rope rope : ropes) {
      if (!rope.cut) { allCut = false; break; }
    }

    // Gravity always applied — critical for pendulum swing.
    // When on a rope the constraint solver cancels the radial component,
    // leaving only tangential velocity that drives the arc (F = ma).
    vy += GRAVITY;

    // Air damping (slightly stronger when attached so rope energy decays)
    float damp = allCut ? 0.995 : 0.992;
    vx *= damp;
    vy *= (allCut ? 0.999 : damp);

    x += vx;
    y += vy;

    // Rotate with horizontal motion
    angle += vx * 0.04;

    // Bounce off walls
    if (x < r)         { x = r;         vx *= -0.5; }
    if (x > width - r) { x = width - r; vx *= -0.5; }
    if (y < 20 + r)    { y = 20 + r;    vy *= -0.3; }
  }

  void draw() {
    pushMatrix();
    translate(x, y);
    rotate(angle);

    // Body
    fill(COL_FISH); stroke(150); strokeWeight(1.5);
    ellipse(0, 0, r*2.4, r*1.4);

    // Tail
    fill(170); noStroke();
    triangle(r*0.8, 0, r*1.5, -r*0.6, r*1.5, r*0.6);

    // Eye
    fill(30); noStroke();
    ellipse(-r*0.4, -r*0.15, r*0.28, r*0.28);
    fill(255);
    ellipse(-r*0.44, -r*0.18, r*0.1, r*0.1);

    // Shine
    fill(255, 255, 255, 120); noStroke();
    ellipse(-r*0.2, -r*0.3, r*0.5, r*0.25);

    popMatrix();
  }
}

// ============================================================
//  OYEN CLASS — the hungry cat
// ============================================================
class Oyen {
  float x, y;
  float sz    = 70;
  float mouthR = 32; // enlarged mouth hitbox for satisfying catches

  Oyen(float x, float y) {
    this.x = x;
    this.y = y;
  }

  // Mouth sits at the open bottom arc of the drawn mouth
  float mouthX() { return x; }
  float mouthY() { return y + sz * 0.22; }

  void draw(boolean eating) {
    drawOyenAt(x, y, sz, eating);
  }
}

// ============================================================
//  SPIKE CLASS — line-segment obstacle
// ============================================================
class Spike {
  float x1, y1, x2, y2;

  Spike(float x1, float y1, float x2, float y2) {
    this.x1 = x1; this.y1 = y1;
    this.x2 = x2; this.y2 = y2;
  }

  // Circle vs line segment — standard closest-point test
  boolean hits(Fish f) {
    float dx = x2 - x1, dy = y2 - y1;
    float len2 = dx*dx + dy*dy;
    if (len2 == 0) return false;
    float t  = constrain(((f.x - x1)*dx + (f.y - y1)*dy) / len2, 0, 1);
    float cx = x1 + t*dx;
    float cy = y1 + t*dy;
    return dist(f.x, f.y, cx, cy) < f.r + 6;
  }

  void draw() {
    // Base line
    stroke(COL_SPIKE); strokeWeight(6);
    line(x1, y1, x2, y2);

    // Spike tips perpendicular to the line
    float dx  = x2 - x1, dy = y2 - y1;
    float len = sqrt(dx*dx + dy*dy);
    if (len == 0) return;
    int tips = max(1, int(len / 22));
    // Perpendicular unit vector (normal)
    float nx = -dy / len, ny = dx / len;

    fill(COL_SPIKE); noStroke();
    for (int i = 0; i <= tips; i++) {
      float t  = (float) i / tips;
      float bx = lerp(x1, x2, t);
      float by = lerp(y1, y2, t);
      // Triangle: base on the line, tip pointing along normal
      triangle(bx - 5, by, bx + 5, by,
               bx + nx * 16, by + ny * 16);
    }
  }
}
