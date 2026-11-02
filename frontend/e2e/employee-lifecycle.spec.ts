import { expect, test } from '@playwright/test'
import { createEmployee, uniqueName } from './helpers'

test.describe('Managing employees', () => {
  test('adds a new employee', async ({ page }) => {
    const name = uniqueName('Lena Fischer')
    await page.goto('/')

    await page.getByRole('button', { name: 'Add employee' }).click()
    const dialog = page.getByRole('dialog', { name: 'Add employee' })

    await dialog.getByRole('button', { name: 'Add employee' }).click()
    await expect(dialog.getByText('Full name is required')).toBeVisible()
    await expect(dialog.getByText('Enter a valid email')).toBeVisible()

    await dialog.getByLabel('Full name').fill(name)
    await dialog.getByLabel('Email').fill(`${name.replace(/\s+/g, '.').toLowerCase()}@acme.test`)
    await dialog.getByLabel('Job title').fill('Product Manager')
    await dialog.getByLabel('Department').fill('Product')
    await dialog.getByRole('combobox', { name: 'Country' }).click()
    await page.getByRole('option', { name: 'Germany' }).click()
    await dialog.getByLabel('Annual salary').fill('92000')
    await dialog.getByLabel('Hire date').fill('2024-05-01')
    await dialog.getByRole('button', { name: 'Add employee' }).click()

    await expect(page.getByText(`${name} added`)).toBeVisible()
    await expect(dialog).toBeHidden()

    await page.getByLabel('Search').fill(name)
    await page.getByRole('link', { name }).click()

    await expect(page.getByRole('heading', { name })).toBeVisible()
    await expect(page.getByText('€92,000')).toBeVisible()
    await expect(page.getByText('No salary changes recorded yet.')).toBeVisible()
  })

  test('rejects a duplicate email', async ({ page, request }) => {
    const existing = await createEmployee(request)
    await page.goto('/')

    await page.getByRole('button', { name: 'Add employee' }).click()
    const dialog = page.getByRole('dialog', { name: 'Add employee' })
    await dialog.getByLabel('Full name').fill('Someone Else')
    await dialog.getByLabel('Email').fill(existing.email)
    await dialog.getByLabel('Job title').fill('Recruiter')
    await dialog.getByLabel('Department').fill('People')
    await dialog.getByRole('combobox', { name: 'Country' }).click()
    await page.getByRole('option', { name: 'India' }).click()
    await dialog.getByLabel('Annual salary').fill('900000')
    await dialog.getByLabel('Hire date').fill('2024-01-10')
    await dialog.getByRole('button', { name: 'Add employee' }).click()

    await expect(dialog.getByText('has already been taken')).toBeVisible()
  })

  test('updates a salary and records the change in the history', async ({ page, request }) => {
    const employee = await createEmployee(request, { salary: 80000 })
    await page.goto(`/employees/${employee.id}`)

    await page.getByRole('button', { name: 'Edit' }).click()
    const dialog = page.getByRole('dialog', { name: 'Edit employee' })
    await dialog.getByLabel('Annual salary').fill('88000')
    await dialog.getByRole('button', { name: 'Save changes' }).click()

    await expect(page.getByText('Employee updated')).toBeVisible()
    const history = page.locator('table').last()
    await expect(history.getByText('€80,000')).toBeVisible()
    await expect(history.getByText('€88,000')).toBeVisible()
    await expect(history.getByText('+10.0%')).toBeVisible()
  })

  test('deletes an employee after confirmation', async ({ page, request }) => {
    const employee = await createEmployee(request)
    await page.goto(`/employees/${employee.id}`)

    await page.getByRole('button', { name: 'Delete' }).click()
    const dialog = page.getByRole('dialog', { name: 'Delete employee' })
    await dialog.getByRole('button', { name: 'Cancel' }).click()
    await expect(dialog).toBeHidden()
    await expect(page.getByRole('heading', { name: employee.full_name })).toBeVisible()

    await page.getByRole('button', { name: 'Delete' }).click()
    await dialog.getByRole('button', { name: 'Delete' }).click()

    await expect(page).toHaveURL('/')
    await page.getByLabel('Search').fill(employee.full_name)
    await expect(page.getByText('No employees match these filters.')).toBeVisible()

    await page.goto(`/employees/${employee.id}`)
    await expect(page.getByText('Employee not found.')).toBeVisible()
  })

  test('stops a stale edit from overwriting a newer change', async ({ page, context, request }) => {
    const employee = await createEmployee(request, { salary: 80000 })
    const otherTab = await context.newPage()
    await page.goto(`/employees/${employee.id}`)
    await otherTab.goto(`/employees/${employee.id}`)

    await otherTab.getByRole('button', { name: 'Edit' }).click()
    const otherDialog = otherTab.getByRole('dialog', { name: 'Edit employee' })
    await otherDialog.getByLabel('Annual salary').fill('90000')
    await otherDialog.getByRole('button', { name: 'Save changes' }).click()
    await expect(otherTab.getByText('Employee updated')).toBeVisible()

    await page.getByRole('button', { name: 'Edit' }).click()
    const dialog = page.getByRole('dialog', { name: 'Edit employee' })
    await dialog.getByLabel('Department').fill('Operations')
    await dialog.getByRole('button', { name: 'Save changes' }).click()

    await expect(dialog.getByText(/Someone else changed this employee/)).toBeVisible()
    await page.reload()
    await expect(page.getByText('€90,000').first()).toBeVisible()
  })
})
