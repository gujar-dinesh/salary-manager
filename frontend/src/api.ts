export type EmploymentType = 'full_time' | 'part_time' | 'contractor'

export interface SalaryChange {
  old_salary: number
  new_salary: number
  currency: string
  created_at: string
}

export interface Employee {
  id: number
  full_name: string
  email: string
  job_title: string
  department: string
  country: string
  currency: string
  salary: number
  employment_type: EmploymentType
  hire_date: string
  salary_changes?: SalaryChange[]
}

export type EmployeeInput = Omit<Employee, 'id' | 'currency' | 'salary_changes'>

export interface EmployeePage {
  employees: Employee[]
  meta: { page: number; per_page: number; total: number; total_pages: number }
}

export interface EmployeeOptions {
  countries: string[]
  departments: string[]
  job_titles: string[]
  employment_types: EmploymentType[]
}

export interface SalaryStats {
  group: string
  currency: string
  headcount: number
  min: number
  max: number
  average: number
  median: number
}

export interface UsdTotal {
  group: string
  headcount: number
  payroll_usd: number
  average_usd: number
}

export interface Overview {
  headcount: number
  payroll_usd: number
  by_country: UsdTotal[]
  by_department: UsdTotal[]
}

export type ValidationErrors = Record<string, string[]>

export class ApiError extends Error {
  status: number
  errors: ValidationErrors

  constructor(status: number, errors: ValidationErrors = {}) {
    super(`Request failed with status ${status}`)
    this.status = status
    this.errors = errors
  }
}

async function request<T>(path: string, options: RequestInit = {}): Promise<T> {
  const response = await fetch(`/api${path}`, {
    ...options,
    headers: { 'Content-Type': 'application/json', Accept: 'application/json' },
  })

  if (!response.ok) {
    const body = await response.json().catch(() => ({}))
    throw new ApiError(response.status, body.errors)
  }

  return response.status === 204 ? (undefined as T) : response.json()
}

export const api = {
  employees: (params: Record<string, string | number>) => {
    const query = new URLSearchParams()
    Object.entries(params).forEach(([key, value]) => {
      if (value !== '') query.set(key, String(value))
    })
    return request<EmployeePage>(`/employees?${query}`)
  },
  employee: (id: number) => request<Employee>(`/employees/${id}`),
  createEmployee: (employee: EmployeeInput) =>
    request<Employee>('/employees', { method: 'POST', body: JSON.stringify({ employee }) }),
  updateEmployee: (id: number, employee: EmployeeInput) =>
    request<Employee>(`/employees/${id}`, { method: 'PATCH', body: JSON.stringify({ employee }) }),
  deleteEmployee: (id: number) => request<void>(`/employees/${id}`, { method: 'DELETE' }),
  options: () => request<EmployeeOptions>('/employees/options'),
  countryStats: () => request<SalaryStats[]>('/insights/countries'),
  jobTitleStats: (country: string) =>
    request<SalaryStats[]>(`/insights/job_titles?country=${encodeURIComponent(country)}`),
  overview: () => request<Overview>('/insights/overview'),
}
