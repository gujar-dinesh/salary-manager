import { expect, test } from '@playwright/test'
import { createEmployee, parseMoney } from './helpers'

test.describe('Employee directory', () => {
  test('lists the seeded employees with pagination', async ({ page }) => {
    await page.goto('/')

    await expect(page.getByRole('heading', { name: 'Employees' })).toBeVisible()
    await expect(page.getByText(/^\d{2},\d{3} employees$/)).toBeVisible()
    await expect(page.locator('tbody tr')).toHaveCount(25)

    const firstOnPageOne = await page.locator('tbody tr').first().textContent()
    await page.getByRole('button', { name: '2', exact: true }).click()

    await expect(page).toHaveURL(/page=2/)
    await expect(page.locator('tbody tr').first()).not.toHaveText(firstOnPageOne!)
  })

  test('searches by name and email', async ({ page, request }) => {
    const employee = await createEmployee(request)
    await page.goto('/')

    await page.getByLabel('Search').fill(employee.full_name)
    await expect(page.locator('tbody tr')).toHaveCount(1)
    await expect(page.getByRole('link', { name: employee.full_name })).toBeVisible()

    await page.getByLabel('Search').fill(employee.email)
    await expect(page.locator('tbody tr')).toHaveCount(1)
    await expect(page.getByText('1 employee', { exact: true })).toBeVisible()
  })

  test('filters by country and keeps the filter after a reload', async ({ page }) => {
    await page.goto('/')

    await page.getByRole('combobox', { name: 'Country' }).click()
    await page.getByRole('option', { name: 'Japan' }).click()

    await expect(page).toHaveURL(/country=Japan/)
    const countryCells = page.locator('tbody tr td:nth-child(4)')
    await expect(countryCells.first()).toHaveText('Japan')
    expect(new Set(await countryCells.allTextContents())).toEqual(new Set(['Japan']))

    await page.reload()
    await expect(page.getByRole('combobox', { name: 'Country' })).toHaveValue('Japan')
    await expect(countryCells.first()).toHaveText('Japan')
  })

  test('sorts by salary in both directions', async ({ page }) => {
    await page.goto('/?country=India')
    const salaries = async () => (await page.locator('tbody tr td:nth-child(5)').allTextContents()).map(parseMoney)

    await page.getByRole('button', { name: /Salary/ }).click()
    await expect(page).toHaveURL(/sort=salary&direction=asc/)
    await expect(page.getByRole('button', { name: /Salary ▲/ })).toBeVisible()
    const ascending = await salaries()
    expect(ascending).toEqual([...ascending].sort((a, b) => a - b))

    await page.getByRole('button', { name: /Salary/ }).click()
    await expect(page).toHaveURL(/direction=desc/)
    await expect(page.getByRole('button', { name: /Salary ▼/ })).toBeVisible()
    const descending = await salaries()
    expect(descending).toEqual([...descending].sort((a, b) => b - a))
    expect(descending[0]).toBeGreaterThan(ascending[0])
  })

  test('shows an empty state when nothing matches', async ({ page }) => {
    await page.goto('/')

    await page.getByLabel('Search').fill('no-such-person-xyz')

    await expect(page.getByText('No employees match these filters.')).toBeVisible()
  })
})
