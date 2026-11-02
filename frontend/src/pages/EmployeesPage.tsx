import { Anchor, Button, Group, Modal, Pagination, Select, Stack, Table, Text, TextInput, Title, UnstyledButton } from '@mantine/core'
import { useDebouncedValue, useDisclosure } from '@mantine/hooks'
import { notifications } from '@mantine/notifications'
import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { api, type EmployeeInput } from '../api'
import { EmployeeForm } from '../components/EmployeeForm'
import { formatMoney } from '../format'

const PER_PAGE = 25

export function EmployeesPage() {
  const [params, setParams] = useSearchParams()
  const [search, setSearch] = useState(params.get('q') ?? '')
  const [debouncedSearch] = useDebouncedValue(search, 300)
  const [formOpened, form] = useDisclosure(false)
  const queryClient = useQueryClient()

  const filters = {
    q: debouncedSearch,
    country: params.get('country') ?? '',
    department: params.get('department') ?? '',
    job_title: params.get('job_title') ?? '',
    sort: params.get('sort') ?? 'full_name',
    direction: params.get('direction') ?? 'asc',
    page: Number(params.get('page') ?? 1),
    per_page: PER_PAGE,
  }

  const { data: options } = useQuery({ queryKey: ['options'], queryFn: api.options })
  const { data, isLoading, isError } = useQuery({
    queryKey: ['employees', filters],
    queryFn: () => api.employees(filters),
    placeholderData: keepPreviousData,
  })

  const createEmployee = useMutation({
    mutationFn: (values: EmployeeInput) => api.createEmployee(values),
    onSuccess: (employee) => {
      queryClient.invalidateQueries({ queryKey: ['employees'] })
      queryClient.invalidateQueries({ queryKey: ['options'] })
      notifications.show({ message: `${employee.full_name} added` })
      form.close()
    },
  })

  const updateParam = (key: string, value: string | null) => {
    const next = new URLSearchParams(params)
    if (value) next.set(key, value)
    else next.delete(key)
    if (key !== 'page') next.delete('page')
    setParams(next)
  }

  const handleSearch = (value: string) => {
    setSearch(value)
    updateParam('q', value)
  }

  const toggleSort = (column: string) => {
    const next = new URLSearchParams(params)
    const direction = filters.sort === column && filters.direction === 'asc' ? 'desc' : 'asc'
    next.set('sort', column)
    next.set('direction', direction)
    next.delete('page')
    setParams(next)
  }

  const sortHeader = (column: string, label: string) => (
    <UnstyledButton fw={700} fz="sm" onClick={() => toggleSort(column)}>
      {label} {filters.sort === column ? (filters.direction === 'asc' ? '▲' : '▼') : ''}
    </UnstyledButton>
  )

  return (
    <Stack>
      <Group justify="space-between">
        <Title order={2}>Employees</Title>
        <Button onClick={form.open} disabled={!options}>
          Add employee
        </Button>
      </Group>

      <Group grow>
        <TextInput
          placeholder="Search by name or email"
          aria-label="Search"
          value={search}
          onChange={(event) => handleSearch(event.currentTarget.value)}
        />
        <Select placeholder="All countries" aria-label="Country" clearable searchable data={options?.countries ?? []}
          value={filters.country || null} onChange={(value) => updateParam('country', value)} />
        <Select placeholder="All departments" aria-label="Department" clearable searchable data={options?.departments ?? []}
          value={filters.department || null} onChange={(value) => updateParam('department', value)} />
        <Select placeholder="All job titles" aria-label="Job title" clearable searchable data={options?.job_titles ?? []}
          value={filters.job_title || null} onChange={(value) => updateParam('job_title', value)} />
      </Group>

      {isError && <Text c="red">Could not load employees.</Text>}

      <Table striped highlightOnHover>
        <Table.Thead>
          <Table.Tr>
            <Table.Th>{sortHeader('full_name', 'Name')}</Table.Th>
            <Table.Th>Job title</Table.Th>
            <Table.Th>Department</Table.Th>
            <Table.Th>Country</Table.Th>
            <Table.Th ta="right">{sortHeader('salary', 'Salary')}</Table.Th>
            <Table.Th>{sortHeader('hire_date', 'Hire date')}</Table.Th>
          </Table.Tr>
        </Table.Thead>
        <Table.Tbody>
          {data?.employees.map((employee) => (
            <Table.Tr key={employee.id}>
              <Table.Td>
                <Anchor component={Link} to={`/employees/${employee.id}`}>
                  {employee.full_name}
                </Anchor>
                <Text size="xs" c="dimmed">{employee.email}</Text>
              </Table.Td>
              <Table.Td>{employee.job_title}</Table.Td>
              <Table.Td>{employee.department}</Table.Td>
              <Table.Td>{employee.country}</Table.Td>
              <Table.Td ta="right">{formatMoney(employee.salary, employee.currency)}</Table.Td>
              <Table.Td style={{ whiteSpace: 'nowrap' }}>{employee.hire_date}</Table.Td>
            </Table.Tr>
          ))}
        </Table.Tbody>
      </Table>

      {data && data.employees.length === 0 && <Text c="dimmed">No employees match these filters.</Text>}
      {isLoading && <Text c="dimmed">Loading...</Text>}

      {data && data.meta.total > 0 && (
        <Group justify="space-between">
          <Text size="sm" c="dimmed">
            {data.meta.total.toLocaleString()} {data.meta.total === 1 ? 'employee' : 'employees'}
          </Text>
          <Pagination total={data.meta.total_pages} value={filters.page}
            onChange={(page) => updateParam('page', String(page))} />
        </Group>
      )}

      <Modal opened={formOpened} onClose={form.close} title="Add employee" size="lg">
        {options && (
          <EmployeeForm
            options={options}
            submitLabel="Add employee"
            onSubmit={(values) => createEmployee.mutateAsync(values)}
            onCancel={form.close}
          />
        )}
      </Modal>
    </Stack>
  )
}
