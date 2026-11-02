import { expect, test } from '@playwright/test'

test.describe('Salary insights', () => {
  test('shows org totals and stats for every country', async ({ page }) => {
    await page.goto('/insights')

    const main = page.getByRole('main')
    await expect(main.getByText('Employees', { exact: true })).toBeVisible()
    await expect(main.getByText(/^\d{2},\d{3}$/).first()).toBeVisible()

    const countryPanel = page.getByRole('tabpanel', { name: 'By country' })
    await expect(countryPanel.locator('tbody tr')).toHaveCount(10)
    await expect(countryPanel.getByRole('row', { name: /^India/ })).toContainText('₹')
    await expect(countryPanel.getByRole('row', { name: /^Germany/ })).toContainText('€')
  })

  test('compares pay by job title within a country', async ({ page }) => {
    await page.goto('/insights')

    await page.getByRole('tab', { name: 'By job title' }).click()
    const panel = page.getByRole('tabpanel', { name: 'By job title' })
    await expect(panel.getByText('Pick a country to compare pay by job title.')).toBeVisible()

    await panel.getByRole('combobox', { name: 'Country for job titles' }).click()
    await page.getByRole('option', { name: 'United Kingdom' }).click()

    await expect(panel.getByRole('row', { name: /^Software Engineer/ })).toBeVisible()
    await expect(panel.locator('tbody tr').first()).toContainText('£')
  })

  test('shows payroll in USD by country and department', async ({ page }) => {
    await page.goto('/insights')

    await page.getByRole('tab', { name: 'Org overview (USD)' }).click()
    const panel = page.getByRole('tabpanel', { name: 'Org overview (USD)' })

    await expect(panel.getByRole('columnheader', { name: 'Payroll (USD)' })).toHaveCount(2)
    await expect(panel.getByRole('row', { name: /^Engineering/ })).toContainText('$')
    await expect(panel.getByRole('row', { name: /^Japan/ })).toContainText('$')
  })
})
