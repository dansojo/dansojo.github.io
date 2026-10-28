const { chromium } = require('playwright');
const fs = require('node:fs');
const assert = require('node:assert/strict');

const base = process.env.QA_BASE_URL || 'https://dansojo.github.io/';
const output = 'qa-results';
fs.mkdirSync(output, { recursive: true });
const report = { base, date: new Date().toISOString(), checks: [], errors: [], layouts: [] };
async function check(name, run) {
  try { const detail = await run(); report.checks.push({ name, pass: true, detail }); }
  catch (error) { report.checks.push({ name, pass: false, error: error.message }); }
}

(async () => {
  const browser = await chromium.launch({ headless: false, args: ['--use-angle=swiftshader', '--enable-unsafe-swiftshader'] });
  report.browser = `Headed Chromium ${browser.version()}`;
  const context = await browser.newContext({ viewport: { width: 1440, height: 1000 } });
  await context.addInitScript(() => {
    window.__draws = 0;
    const draw = WebGLRenderingContext.prototype.drawArrays;
    WebGLRenderingContext.prototype.drawArrays = function (...args) { window.__draws++; return draw.apply(this, args); };
  });
  const page = await context.newPage();
  page.on('pageerror', error => report.errors.push(error.message));
  const response = await page.goto(base, { waitUntil: 'networkidle' });
  await page.evaluate(() => document.fonts.ready);
  await check('Page loads over HTTP', () => assert.equal(response.status(), 200));
  await check('Liquid shader renders and motion can pause/resume', async () => {
    await page.locator('#liquid-canvas.ready').waitFor();
    const initial = await page.evaluate(() => window.__draws);
    await page.waitForTimeout(350);
    assert.ok(await page.evaluate(() => window.__draws) > initial);
    await page.locator('#motion-toggle').click();
    await page.waitForTimeout(100);
    const paused = await page.evaluate(() => window.__draws);
    await page.waitForTimeout(350);
    assert.equal(await page.evaluate(() => window.__draws), paused);
    assert.equal(await page.locator('#motion-toggle').innerText(), '모션 재생');
    await page.locator('#motion-toggle').click();
    await page.waitForTimeout(350);
    assert.ok(await page.evaluate(() => window.__draws) > paused);
    await page.locator('#motion-toggle').click();
  });
  for (const width of [1440, 1024, 768, 721, 720, 390, 320]) {
    await page.setViewportSize({ width, height: 1000 });
    await page.evaluate(() => window.scrollTo({ top: 0, behavior: 'instant' }));
    await page.waitForTimeout(120);
    const layout = await page.evaluate(() => ({
      width: innerWidth, scrollWidth: document.documentElement.scrollWidth,
      overflow: [...document.querySelectorAll('body *')].filter(e => {
        const r = e.getBoundingClientRect();
        return r.width > 0 && (r.right > innerWidth + 1 || r.left < -1) && getComputedStyle(e).position !== 'fixed';
      }).map(e => ({ tag: e.tagName, class: e.className, text: e.textContent.slice(0, 60) })).slice(0, 12)
    }));
    report.layouts.push(layout);
    await check(`No horizontal overflow at ${width}px`, () => assert.ok(layout.scrollWidth <= width + 1, JSON.stringify(layout)));
    if ([1440, 768, 390, 320].includes(width)) await page.screenshot({ path: `${output}/hero-${width}.jpg`, quality: 85 });
  }
  await page.setViewportSize({ width: 1440, height: 1000 });
  for (const selector of ['#work-ictc', '#work-fundus', '#work-money', '#work-rag', '#publication', '#experience', '#skills']) {
    await page.locator(selector).scrollIntoViewIfNeeded();
    await page.screenshot({ path: `${output}/${selector.slice(1)}-desktop.jpg`, quality: 80 });
  }
  await check('Project images load', async () => {
    const images = await page.locator('.work-visual img').evaluateAll(imgs => imgs.map(i => ({ src: i.src, loaded: i.complete && i.naturalWidth > 0 })));
    assert.equal(images.length, 4); assert.ok(images.every(i => i.loaded), JSON.stringify(images));
  });
  await check('All seven PDF documents respond with PDF content', async () => {
    const links = await page.locator('a[data-pdf]').evaluateAll(as => [...new Set(as.map(a => a.href))]);
    assert.equal(links.length, 7);
    for (const url of links) {
      const r = await context.request.get(url); assert.equal(r.status(), 200, url);
      assert.equal((await r.body()).subarray(0, 4).toString(), '%PDF', url);
    }
    return links;
  });
  await check('Resume link downloads PDF', async () => {
    const downloading = page.waitForEvent('download');
    await page.locator('.header-pdf').click();
    const download = await downloading;
    assert.equal(download.suggestedFilename(), '김태호_Resume_A4_1page.pdf');
    await download.saveAs(`${output}/downloaded-resume.pdf`);
    assert.equal(fs.readFileSync(`${output}/downloaded-resume.pdf`).subarray(0, 4).toString(), '%PDF');
  });
  for (const width of [1440, 390, 320]) {
    await page.setViewportSize({ width, height: 1000 });
    await check(`PDF dialog interaction at ${width}px`, async () => {
      const trigger = page.locator('#work-ictc .work-actions a[data-pdf]');
      await trigger.click();
      assert.equal(await page.locator('#pdf-viewer').evaluate(d => d.open), true);
      await page.locator('#pdf-frame').waitFor();
      await page.waitForTimeout(2500);
      report.pdfFrames = page.frames().map(f => f.url());
      await page.screenshot({ path: `${output}/pdf-${width}.jpg`, quality: 85 });
      assert.equal(await page.locator('#pdf-close').evaluate(e => e === document.activeElement), true);
      assert.equal(await page.locator('#pdf-viewer').evaluate(d => d.scrollWidth <= d.clientWidth + 1), true);
      assert.ok((await page.locator('#pdf-frame').getAttribute('src')).endsWith('ictc.pdf#view=FitH'));
      const downloadEvent = page.waitForEvent('download');
      await page.locator('#pdf-download').click();
      assert.equal((await downloadEvent).suggestedFilename(), 'ictc.pdf');
      await page.keyboard.press('Escape');
      await page.waitForFunction(() => !document.getElementById('pdf-viewer').open && !document.getElementById('pdf-frame').hasAttribute('src'));
      assert.equal(await page.locator('#pdf-viewer').evaluate(d => d.open), false);
      assert.equal(await trigger.evaluate(e => e === document.activeElement), true);
      assert.equal(await page.locator('#pdf-frame').getAttribute('src'), null);
      await page.locator('#publication a[data-pdf]').first().click();
      assert.ok((await page.locator('#pdf-title').innerText()).includes('발표 포스터'));
      await page.locator('#pdf-close').click();
      assert.equal(await page.locator('#pdf-viewer').evaluate(d => d.open), false);
    });
    if (await page.locator('#pdf-viewer').evaluate(d => d.open)) await page.locator('#pdf-close').click();
  }
  await page.setViewportSize({ width: 390, height: 844 });
  for (const selector of ['#work-ictc', '#work-rag', '#publication']) {
    await page.locator(selector).scrollIntoViewIfNeeded();
    await page.screenshot({ path: `${output}/${selector.slice(1)}-mobile.jpg`, quality: 85 });
  }
  await check('Expanded project details remain readable on mobile', async () => {
    await page.locator('#work-rag summary').click();
    assert.equal(await page.locator('#work-rag details').evaluate(d => d.open), true);
    assert.ok(await page.evaluate(() => document.documentElement.scrollWidth <= innerWidth + 1));
  });
  await check('Reduced motion is static and toggle is hidden', async () => {
    await page.emulateMedia({ reducedMotion: 'reduce' });
    await page.reload({ waitUntil: 'networkidle' });
    await page.evaluate(() => window.scrollTo({ top: 0, behavior: 'instant' }));
    await page.locator('#liquid-canvas.ready').waitFor();
    await page.waitForTimeout(150);
    const count = await page.evaluate(() => window.__draws);
    await page.waitForTimeout(400);
    assert.equal(await page.evaluate(() => window.__draws), count);
    assert.equal(await page.locator('#motion-toggle').isVisible(), false);
  });
  await check('No JavaScript runtime errors', () => assert.deepEqual(report.errors, []));
  await browser.close();
})().catch(error => report.errors.push(error.stack)).finally(() => {
  report.passed = report.checks.every(c => c.pass) && !report.errors.length;
  fs.writeFileSync(`${output}/report.json`, JSON.stringify(report, null, 2));
  console.log(JSON.stringify(report, null, 2));
  process.exitCode = report.passed ? 0 : 1;
});
