import { test, expect } from '@playwright/test';

test('verify mutual funds page and modals', async ({ page }) => {
  await page.goto('http://localhost:8080/mutual-funds');
  await page.waitForTimeout(3000);
  await page.screenshot({ path: 'v11_mf_main.png', fullPage: true });

  // Click Add Fund button
  await page.click('button:has-text("Add Fund")');
  await page.waitForTimeout(1000);
  await page.screenshot({ path: 'v11_add_fund_modal.png' });

  // Type in search
  await page.fill('input[placeholder*="Type fund name"]', 'mirae');
  await page.waitForTimeout(2000);
  await page.screenshot({ path: 'v11_add_fund_search.png' });
});
