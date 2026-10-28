const { chromium } = require('playwright');
const fs = require('node:fs');
(async () => {
  const context = await chromium.launchPersistentContext('/tmp/portfolio-pdf-browser', { headless: false, viewport: {width: 1440, height: 1000} });
  const page = await context.newPage();
  const evidence = {console: [], failed: [], frames: []};
  page.on('console', m => evidence.console.push(m.text()));
  page.on('requestfailed', r => evidence.failed.push({url:r.url(), failure:r.failure()}));
  await page.goto('https://dansojo.github.io/', {waitUntil:'networkidle'});
  await page.locator('#work-ictc a[data-pdf]').first().click();
  await page.waitForTimeout(15000);
  for (const frame of page.frames()) {
    evidence.frames.push({url:frame.url(), html: await frame.evaluate(() => document.documentElement.outerHTML).catch(e => e.message)});
  }
  await page.screenshot({path:'qa-results/pdf-persistent-desktop.jpg',quality:85});
  await page.setViewportSize({width:390,height:844});
  await page.waitForTimeout(3000);
  await page.screenshot({path:'qa-results/pdf-persistent-mobile.jpg',quality:85});
  fs.writeFileSync('qa-results/pdf-diagnostic.json',JSON.stringify(evidence,null,2));
  await context.close();
})();
