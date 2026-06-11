import { test, expect } from '@playwright/test';

test('verify mutual fund actions', async ({ page }) => {
  await page.goto('http://localhost:8080/mutual-funds');
  await page.waitForTimeout(3000);

  // Check if we have any holdings to interact with
  const actionMenu = page.locator('button[aria-haspopup="menu"]').first();
  if (await actionMenu.isVisible()) {
    await actionMenu.click();
    await page.waitForTimeout(500);
    await page.screenshot({ path: 'v11_action_menu.png' });

    // Click View Details
    await page.click('div[role="menuitem"]:has-text("View Details")');
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'v11_view_details.png', fullPage: true });

    // Back to holdings
    await page.click('button:has-text("Back to Holdings")');
    await page.waitForTimeout(500);

    // Click Edit Holding
    await actionMenu.click();
    await page.waitForTimeout(500);
    await page.click('div[role="menuitem"]:has-text("Edit Holding")');
    await page.waitForTimeout(1000);
    await page.screenshot({ path: 'v11_edit_modal.png' });
  } else {
    console.log('No holdings found to test actions');
  }
});
