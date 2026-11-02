import { screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { useLocation, useNavigate } from 'react-router-dom'
import { describe, expect, it } from 'vitest'
import { mockFetch, renderWithProviders } from '../test/render'
import { EmployeesPage } from './EmployeesPage'

const options = {
  countries: ['India', 'Germany'],
  departments: ['Engineering'],
  job_titles: ['Software Engineer'],
  employment_types: ['full_time'],
}

const page = {
  employees: [
    {
      id: 1, full_name: 'Asha Rao', email: 'asha@acme.com', job_title: 'Software Engineer',
      department: 'Engineering', country: 'India', currency: 'INR', salary: 1200000,
      employment_type: 'full_time', hire_date: '2022-04-01',
    },
  ],
  meta: { page: 1, per_page: 25, total: 1, total_pages: 1 },
}

describe('EmployeesPage', () => {
  it('lists employees with their salary in local currency', async () => {
    mockFetch({ '/api/employees/options': options, '/api/employees': page })
    renderWithProviders(<EmployeesPage />)

    expect(await screen.findByRole('link', { name: 'Asha Rao' })).toHaveAttribute('href', '/employees/1')
    expect(screen.getByText('₹1,200,000')).toBeInTheDocument()
    expect(screen.getByText('1 employee')).toBeInTheDocument()
  })

  it('sends the search term to the API', async () => {
    const fetchMock = mockFetch({ '/api/employees/options': options, '/api/employees': page })
    renderWithProviders(<EmployeesPage />)

    await userEvent.type(screen.getByLabelText('Search'), 'asha')

    await waitFor(() => expect(fetchMock).toHaveBeenCalledWith(expect.stringContaining('q=asha'), expect.anything()))
  })

  it('sorts by salary when the header is clicked', async () => {
    const fetchMock = mockFetch({ '/api/employees/options': options, '/api/employees': page })
    renderWithProviders(<EmployeesPage />)

    await userEvent.click(await screen.findByRole('button', { name: /Salary/ }))

    await waitFor(() =>
      expect(fetchMock).toHaveBeenCalledWith(expect.stringContaining('sort=salary&direction=asc'), expect.anything()),
    )
  })

  it('shows an empty state', async () => {
    mockFetch({
      '/api/employees/options': options,
      '/api/employees': { employees: [], meta: { page: 1, per_page: 25, total: 0, total_pages: 0 } },
    })
    renderWithProviders(<EmployeesPage />)

    expect(await screen.findByText('No employees match these filters.')).toBeInTheDocument()
  })

  function History() {
    const navigate = useNavigate()
    const location = useLocation()
    return (
      <>
        <button onClick={() => navigate(-1)}>Back</button>
        <output aria-label="location">{location.pathname + location.search}</output>
      </>
    )
  }

  it('restores the previous search when going back', async () => {
    mockFetch({ '/api/employees/options': options, '/api/employees': page })
    renderWithProviders(<><EmployeesPage /><History /></>, { entries: ['/?q=one', '/?q=two'] })

    expect(screen.getByLabelText('Search')).toHaveValue('two')
    await userEvent.click(screen.getByRole('button', { name: 'Back' }))

    expect(screen.getByLabelText('Search')).toHaveValue('one')
  })

  it('does not add a history entry for every keystroke', async () => {
    mockFetch({ '/api/employees/options': options, '/api/employees': page })
    renderWithProviders(<><EmployeesPage /><History /></>, { entries: ['/insights', '/'] })

    await userEvent.type(screen.getByLabelText('Search'), 'abc')
    await userEvent.click(screen.getByRole('button', { name: 'Back' }))

    expect(screen.getByLabelText('location')).toHaveTextContent('/insights')
  })
})
