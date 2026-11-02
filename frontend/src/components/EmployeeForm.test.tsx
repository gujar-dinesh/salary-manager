import { screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { ApiError, type EmployeeOptions } from '../api'
import { renderWithProviders } from '../test/render'
import { EmployeeForm } from './EmployeeForm'

const options: EmployeeOptions = {
  countries: ['India', 'Germany'],
  departments: ['Engineering'],
  job_titles: ['Software Engineer'],
  employment_types: ['full_time', 'part_time', 'contractor'],
}

const existing = {
  full_name: 'Asha Rao',
  email: 'asha@acme.com',
  job_title: 'Software Engineer',
  department: 'Engineering',
  country: 'India',
  salary: 1200000,
  employment_type: 'full_time' as const,
  hire_date: '2022-04-01',
  lock_version: 3,
}

describe('EmployeeForm', () => {
  it('shows validation errors and does not submit an empty form', async () => {
    const onSubmit = vi.fn()
    renderWithProviders(<EmployeeForm options={options} submitLabel="Add" onSubmit={onSubmit} onCancel={() => {}} />)

    await userEvent.click(screen.getByRole('button', { name: 'Add' }))

    expect(screen.getByText('Full name is required')).toBeInTheDocument()
    expect(screen.getByText('Enter a valid email')).toBeInTheDocument()
    expect(screen.getByText('Salary must be greater than 0')).toBeInTheDocument()
    expect(onSubmit).not.toHaveBeenCalled()
  })

  it('submits the edited values', async () => {
    const onSubmit = vi.fn().mockResolvedValue(undefined)
    renderWithProviders(
      <EmployeeForm options={options} initialValues={existing} submitLabel="Save" onSubmit={onSubmit} onCancel={() => {}} />,
    )

    const salary = screen.getByLabelText(/Annual salary/)
    await userEvent.clear(salary)
    await userEvent.type(salary, '1300000')
    await userEvent.click(screen.getByRole('button', { name: 'Save' }))

    expect(onSubmit).toHaveBeenCalledWith({ ...existing, salary: 1300000 })
  })

  it('shows errors returned by the server', async () => {
    const onSubmit = vi.fn().mockRejectedValue(new ApiError(422, { email: ['has already been taken'] }))
    renderWithProviders(
      <EmployeeForm options={options} initialValues={existing} submitLabel="Save" onSubmit={onSubmit} onCancel={() => {}} />,
    )

    await userEvent.click(screen.getByRole('button', { name: 'Save' }))

    expect(await screen.findByText('has already been taken')).toBeInTheDocument()
  })

  it('shows a message when the request fails for another reason', async () => {
    const onSubmit = vi.fn().mockRejectedValue(new ApiError(500))
    renderWithProviders(
      <EmployeeForm options={options} initialValues={existing} submitLabel="Save" onSubmit={onSubmit} onCancel={() => {}} />,
    )

    await userEvent.click(screen.getByRole('button', { name: 'Save' }))

    expect(await screen.findByText('Could not save the employee. Please try again.')).toBeInTheDocument()
  })

  it('explains when someone else changed the employee first', async () => {
    const onSubmit = vi.fn().mockRejectedValue(new ApiError(409))
    renderWithProviders(
      <EmployeeForm options={options} initialValues={existing} submitLabel="Save" onSubmit={onSubmit} onCancel={() => {}} />,
    )

    await userEvent.click(screen.getByRole('button', { name: 'Save' }))

    expect(
      await screen.findByText('Someone else changed this employee while you were editing. Reload the page to see their changes.'),
    ).toBeInTheDocument()
  })
})
