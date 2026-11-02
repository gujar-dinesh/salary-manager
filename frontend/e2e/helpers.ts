import type { APIRequestContext } from '@playwright/test'

let counter = 0

export function uniqueName(prefix: string) {
  counter += 1
  return `${prefix} ${Date.now().toString(36)}${counter}`
}

export async function createEmployee(request: APIRequestContext, overrides: Record<string, unknown> = {}) {
  const fullName = uniqueName('Test Person')
  const response = await request.post('/api/employees', {
    data: {
      employee: {
        full_name: fullName,
        email: `${fullName.replace(/\s+/g, '.').toLowerCase()}@acme.test`,
        job_title: 'Software Engineer',
        department: 'Engineering',
        country: 'Germany',
        salary: 80000,
        employment_type: 'full_time',
        hire_date: '2023-03-01',
        ...overrides,
      },
    },
  })
  if (!response.ok()) throw new Error(`Could not create employee: ${response.status()}`)
  return response.json()
}

export function parseMoney(text: string) {
  return Number(text.replace(/[^\d.]/g, ''))
}
