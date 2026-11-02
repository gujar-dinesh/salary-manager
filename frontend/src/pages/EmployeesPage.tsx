import { Button, Group, Modal, Pagination, Select, Stack, Text, TextInput, Title } from '@mantine/core'
import { useDisclosure } from '@mantine/hooks'
import { notifications } from '@mantine/notifications'
import { keepPreviousData, useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api, type EmployeeInput } from '../api'
import { EmployeeForm } from '../components/EmployeeForm'
import { EmployeeTable } from '../components/EmployeeTable'
import { useEmployeeFilters } from '../hooks/useEmployeeFilters'

export function EmployeesPage() {
  const { filters, search, setSearch, setFilter, setPage, toggleSort } = useEmployeeFilters()
  const [formOpened, form] = useDisclosure(false)
  const queryClient = useQueryClient()

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
          onChange={(event) => setSearch(event.currentTarget.value)}
        />
        <Select placeholder="All countries" aria-label="Country" clearable searchable data={options?.countries ?? []}
          value={filters.country || null} onChange={(value) => setFilter('country', value)} />
        <Select placeholder="All departments" aria-label="Department" clearable searchable data={options?.departments ?? []}
          value={filters.department || null} onChange={(value) => setFilter('department', value)} />
        <Select placeholder="All job titles" aria-label="Job title" clearable searchable data={options?.job_titles ?? []}
          value={filters.job_title || null} onChange={(value) => setFilter('job_title', value)} />
      </Group>

      {isError && <Text c="red">Could not load employees.</Text>}

      <EmployeeTable employees={data?.employees ?? []} sort={filters.sort} direction={filters.direction}
        onSort={toggleSort} />

      {data && data.employees.length === 0 && <Text c="dimmed">No employees match these filters.</Text>}
      {isLoading && <Text c="dimmed">Loading...</Text>}

      {data && data.meta.total > 0 && (
        <Group justify="space-between">
          <Text size="sm" c="dimmed">
            {data.meta.total.toLocaleString()} {data.meta.total === 1 ? 'employee' : 'employees'}
          </Text>
          <Pagination total={data.meta.total_pages} value={filters.page} onChange={setPage} />
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
