import { test, expect } from '@playwright/test';

test('verify edit and delete modals', async ({ page }) => {
  await page.goto('http://localhost:8080/equity');

  // Click Action Menu (three dots) in the first row
  await page.locator('table').nth(0).locator('tbody tr').nth(0).locator('button').first().click();

  // Click "Edit"
  await page.click('text=Edit');

  // Verify Edit Modal is visible
  await expect(page.locator('h2:has-text("Edit Holding")')).toBeVisible();

  // Change quantity
  const qtyInput = page.locator('label:has-text("Quantity")').locator('xpath=./..').locator('input');
  await qtyInput.fill('300');

  // Check live calculations
  await expect(page.locator('div:has-text("Invested Amount") >> p').last()).toContainText('3,96,000');
  await expect(page.locator('div:has-text("Current Value") >> p').last()).toContainText('5,67,600');
  await expect(page.locator('div:has-text("Unrealised P&L") >> p').last()).toContainText('1,71,600');

  await page.screenshot({ path: 'edit_modal.png' });

  // Close edit modal
  await page.click('text=Cancel');

  // Open Delete confirmation
  await page.locator('table').nth(0).locator('tbody tr').nth(0).locator('button').first().click();
  await page.click('text=Delete');

  await expect(page.locator('h3:has-text("Delete Holding")')).toBeVisible();
  await expect(page.locator('text=Remove Infosys Ltd (INFY) from your portfolio?')).toBeVisible();

  await page.screenshot({ path: 'delete_confirm.png' });
});
