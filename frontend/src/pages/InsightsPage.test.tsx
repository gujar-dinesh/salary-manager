import { screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it } from 'vitest'
import { mockFetch, renderWithProviders } from '../test/render'
import { InsightsPage } from './InsightsPage'

const countries = [
  { group: 'India', currency: 'INR', headcount: 3000, min: 500000, max: 6000000, average: 2100000, median: 1900000 },
]

const overview = {
  headcount: 3000,
  payroll_usd: 75600000,
  by_country: [{ group: 'India', headcount: 3000, payroll_usd: 75600000, average_usd: 25200 }],
  by_department: [],
}

const jobTitles = [
  { group: 'Accountant', currency: 'INR', headcount: 250, min: 1250000, max: 1950000, average: 1590000, median: 1610000 },
]

describe('InsightsPage', () => {
  it('shows the org totals and stats by country', async () => {
    mockFetch({ '/api/insights/countries': countries, '/api/insights/overview': overview })
    renderWithProviders(<InsightsPage />)

    expect(await screen.findByText('Annual payroll (USD)')).toBeInTheDocument()
    expect(screen.getAllByText('$75,600,000').length).toBeGreaterThan(0)
    expect(screen.getAllByText('$25,200').length).toBeGreaterThan(0)
    expect(await screen.findByText('₹1,900,000')).toBeInTheDocument()
  })

  it('loads job title stats for the chosen country', async () => {
    const fetchMock = mockFetch({
      '/api/insights/countries': countries,
      '/api/insights/overview': overview,
      '/api/insights/job_titles': jobTitles,
    })
    renderWithProviders(<InsightsPage />)

    await userEvent.click(await screen.findByRole('tab', { name: 'By job title' }))
    await userEvent.click(screen.getByRole('combobox', { name: 'Country for job titles' }))
    await userEvent.click(await screen.findByRole('option', { name: 'India' }))

    expect(await screen.findByText('Accountant')).toBeInTheDocument()
    expect(fetchMock).toHaveBeenCalledWith('/api/insights/job_titles?country=India', expect.anything())
  })
})
