import { expect, test, type Locator, type Page } from '@playwright/test'
import { readFileSync, writeFileSync } from 'node:fs'
import narration from './narration.json' with { type: 'json' }

// Seconds of narration per scene, written by make-video.sh after generating the voice clips.
const durations: Record<string, number> = JSON.parse(readFileSync(new URL('./output/durations.json', import.meta.url), 'utf8'))
const PAUSE_MS = 700

const pause = (page: Page, ms = 600) => page.waitForTimeout(ms)

// Options render in a portal at page level, while the input may sit inside a dialog.
async function chooseOption(page: Page, label: string, option: string, within: Page | Locator = page) {
  await within.getByRole('combobox', { name: label }).click()
  await page.getByRole('option', { name: option, exact: true }).click()
}

const scenes: Record<string, (page: Page) => Promise<void>> = {
  intro: async (page) => {
    await expect(page.getByText(/employees$/)).toBeVisible()
  },
  search: async (page) => {
    await page.getByLabel('Search').pressSequentially('nakamura', { delay: 120 })
    await pause(page, 4000)
    await page.getByLabel('Search').fill('')
  },
  filter: async (page) => {
    await chooseOption(page, 'Country', 'Japan')
    await pause(page, 1200)
    await page.getByRole('button', { name: /Salary/ }).click()
    await pause(page, 600)
    await page.getByRole('button', { name: /Salary/ }).click()
    await pause(page, 2500)
    await page.goto('/?sort=salary&direction=desc')
  },
  add: async (page) => {
    await page.getByRole('button', { name: 'Add employee' }).click()
    const dialog = page.getByRole('dialog', { name: 'Add employee' })
    await dialog.getByRole('button', { name: 'Add employee' }).click()
    await pause(page, 1200)
    await dialog.getByLabel('Full name').pressSequentially('Meera Joshi', { delay: 60 })
    await dialog.getByLabel('Email').pressSequentially('meera.joshi@acme.com', { delay: 40 })
    await dialog.getByLabel('Job title').fill('Product Manager')
    await dialog.getByLabel('Department').fill('Product')
    await chooseOption(page, 'Country', 'India', dialog)
    await dialog.getByLabel('Annual salary').fill('2400000')
    await dialog.getByLabel('Hire date').fill('2024-06-03')
    await pause(page)
    await dialog.getByRole('button', { name: 'Add employee' }).click()
    await expect(page.getByText('Meera Joshi added')).toBeVisible()
  },
  history: async (page) => {
    await page.getByLabel('Search').fill('Meera Joshi')
    await page.getByRole('link', { name: 'Meera Joshi' }).click()
    await pause(page, 1200)
    await page.getByRole('button', { name: 'Edit' }).click()
    const dialog = page.getByRole('dialog', { name: 'Edit employee' })
    await dialog.getByLabel('Annual salary').fill('2640000')
    await pause(page)
    await dialog.getByRole('button', { name: 'Save changes' }).click()
    await expect(page.getByText('+10.0%')).toBeVisible()
  },
  countries: async (page) => {
    await page.getByRole('link', { name: 'Insights' }).click()
    await expect(page.getByRole('tabpanel', { name: 'By country' }).locator('tbody tr')).toHaveCount(10)
  },
  job_titles: async (page) => {
    await page.getByRole('tab', { name: 'By job title' }).click()
    await chooseOption(page, 'Country for job titles', 'India')
    await expect(page.getByRole('row', { name: /^Software Engineer/ })).toBeVisible()
  },
  overview: async (page) => {
    await page.getByRole('tab', { name: 'Org overview (USD)' }).click()
  },
  closing: async (page) => {
    await pause(page, 2500)
    await page.getByRole('link', { name: 'Employees' }).click()
  },
}

test('narrated walkthrough', async ({ page }) => {
  // The video starts with the page, so scene offsets are measured from before the first load.
  const started = Date.now()
  await page.goto('/')
  const timeline: { id: string; startMs: number }[] = []

  for (const { id } of narration) {
    const sceneStart = Date.now()
    timeline.push({ id, startMs: sceneStart - started })
    await scenes[id](page)
    const remaining = durations[id] * 1000 + PAUSE_MS - (Date.now() - sceneStart)
    if (remaining > 0) await page.waitForTimeout(remaining)
  }

  writeFileSync(new URL('./output/timeline.json', import.meta.url), JSON.stringify(timeline, null, 2))
})
