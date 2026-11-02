import { screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { Route, Routes } from 'react-router-dom'
import { describe, expect, it } from 'vitest'
import { mockFetch, renderWithProviders } from '../test/render'
import { EmployeeDetailPage } from './EmployeeDetailPage'

const employee = {
  id: 7, full_name: 'Lena Fischer', email: 'lena@acme.com', job_title: 'Product Manager',
  department: 'Product', country: 'Germany', currency: 'EUR', salary: 88000,
  employment_type: 'full_time', hire_date: '2020-02-03',
  salary_changes: [
    { old_salary: 80000, new_salary: 88000, old_currency: 'EUR', new_currency: 'EUR', created_at: '2026-03-01T10:00:00Z' },
  ],
}

function renderPage() {
  return renderWithProviders(
    <Routes>
      <Route path="/employees/:id" element={<EmployeeDetailPage />} />
    </Routes>,
    { route: '/employees/7' },
  )
}

describe('EmployeeDetailPage', () => {
  it('shows the employee and their salary history', async () => {
    mockFetch({ '/api/employees/options': {}, '/api/employees/7': employee })
    renderPage()

    expect(await screen.findByRole('heading', { name: 'Lena Fischer' })).toBeInTheDocument()
    expect(screen.getAllByText('€88,000')).toHaveLength(2)
    expect(screen.getByText('€80,000')).toBeInTheDocument()
    expect(screen.getByText('+10.0%')).toBeInTheDocument()
  })

  it('shows both currencies instead of a percentage when the currency changed', async () => {
    const moved = {
      ...employee,
      salary_changes: [
        { old_salary: 2000000, new_salary: 88000, old_currency: 'INR', new_currency: 'EUR', created_at: '2026-03-01T10:00:00Z' },
      ],
    }
    mockFetch({ '/api/employees/options': {}, '/api/employees/7': moved })
    renderPage()

    expect(await screen.findByText('₹2,000,000')).toBeInTheDocument()
    expect(screen.getByText('INR to EUR')).toBeInTheDocument()
  })

  it('says when there is no salary history', async () => {
    mockFetch({ '/api/employees/options': {}, '/api/employees/7': { ...employee, salary_changes: [] } })
    renderPage()

    expect(await screen.findByText('No salary changes recorded yet.')).toBeInTheDocument()
  })

  it('does not fetch the employee again after deleting them', async () => {
    const fetchMock = mockFetch({ '/api/employees/options': {}, '/api/employees/7': employee })
    renderPage()

    await userEvent.click(await screen.findByRole('button', { name: 'Delete' }))
    await userEvent.click(screen.getAllByRole('button', { name: 'Delete' }).at(-1)!)
    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith('/api/employees/7', expect.objectContaining({ method: 'DELETE' })))
    await new Promise((resolve) => setTimeout(resolve, 50))

    const reads = fetchMock.mock.calls.filter(([url, options]) => url === '/api/employees/7' && !options?.method)
    expect(reads).toHaveLength(1)
  })
})
