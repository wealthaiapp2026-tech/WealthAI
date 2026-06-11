import { test, expect } from '@playwright/test';

test('Mutual Fund V11 Final Verification', async ({ page }) => {
  // 1. Load page
  await page.goto('http://localhost:8080/mutual-funds');
  await page.waitForTimeout(4000); // Wait for potential data load
  await page.screenshot({ path: 'v11_final_01_main.png', fullPage: true });

  // 2. Add Fund Modal
  await page.click('button:has-text("Add Fund")');
  await page.waitForTimeout(1000);
  await page.screenshot({ path: 'v11_final_02_add_modal.png' });

  // 3. Search Scheme
  await page.fill('input[placeholder*="Type fund name"]', 'mirae');
  await page.waitForTimeout(2000);
  await page.screenshot({ path: 'v11_final_03_search_results.png' });

  // 4. Close modal
  await page.click('button:has-text("Cancel")');
  await page.waitForTimeout(500);

  // 5. Check tabs
  await page.click('div:has-text("Holdings")');
  await page.waitForTimeout(1000);
  await page.screenshot({ path: 'v11_final_04_holdings_tab.png' });

  await page.click('div:has-text("SIP Manager")');
  await page.waitForTimeout(1000);
  await page.screenshot({ path: 'v11_final_05_sip_tab.png' });

  await page.click('div:has-text("Analytics")');
  await page.waitForTimeout(1000);
  await page.screenshot({ path: 'v11_final_06_analytics_tab.png' });
});
