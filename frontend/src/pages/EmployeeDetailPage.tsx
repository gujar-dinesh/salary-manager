import { Anchor, Badge, Button, Card, Group, Modal, SimpleGrid, Stack, Table, Text, Title } from '@mantine/core'
import { useDisclosure } from '@mantine/hooks'
import { notifications } from '@mantine/notifications'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { api, type Employee, type EmployeeInput, type SalaryChange } from '../api'
import { refreshEmployeeData } from '../cache'
import { EmployeeForm } from '../components/EmployeeForm'
import { formatEmploymentType, formatMoney } from '../format'

function toInput(employee: Employee): EmployeeInput {
  const { full_name, email, job_title, department, country, salary, employment_type, hire_date, lock_version } = employee
  return { full_name, email, job_title, department, country, salary, employment_type, hire_date, lock_version }
}

function describeChange({ old_salary, new_salary, old_currency, new_currency }: SalaryChange) {
  if (old_currency !== new_currency) return `${old_currency} to ${new_currency}`
  const change = ((new_salary - old_salary) / old_salary) * 100
  return `${change > 0 ? '+' : ''}${change.toFixed(1)}%`
}

export function EmployeeDetailPage() {
  const id = Number(useParams().id)
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const [editOpened, edit] = useDisclosure(false)
  const [deleteOpened, confirmDelete] = useDisclosure(false)

  // Once deleted, stop asking for the employee so removing it from the cache cannot trigger a refetch (404).
  const [deleted, setDeleted] = useState(false)
  const { data: employee, isError } = useQuery({
    queryKey: ['employee', id],
    queryFn: () => api.employee(id),
    enabled: !deleted,
  })
  const { data: options } = useQuery({ queryKey: ['options'], queryFn: api.options })

  const updateEmployee = useMutation({
    mutationFn: (values: EmployeeInput) => api.updateEmployee(id, values),
    onSuccess: (updated) => {
      queryClient.setQueryData(['employee', id], updated)
      refreshEmployeeData(queryClient)
      notifications.show({ message: 'Employee updated' })
      edit.close()
    },
  })

  const deleteEmployee = useMutation({
    mutationFn: () => api.deleteEmployee(id),
    onSuccess: () => {
      setDeleted(true)
      notifications.show({ message: `${employee?.full_name} deleted` })
      navigate('/')
      refreshEmployeeData(queryClient, { deletedId: id })
    },
  })

  if (isError) return <Text c="red">Employee not found.</Text>
  if (!employee) return <Text c="dimmed">Loading...</Text>

  const details = [
    ['Email', employee.email],
    ['Job title', employee.job_title],
    ['Department', employee.department],
    ['Country', employee.country],
    ['Annual salary', formatMoney(employee.salary, employee.currency)],
    ['Hire date', employee.hire_date],
  ]

  return (
    <Stack>
      <Anchor component={Link} to="/" size="sm">
        Back to employees
      </Anchor>

      <Group justify="space-between">
        <Group>
          <Title order={2}>{employee.full_name}</Title>
          <Badge variant="light">{formatEmploymentType(employee.employment_type)}</Badge>
        </Group>
        <Group>
          <Button variant="default" onClick={edit.open} disabled={!options}>
            Edit
          </Button>
          <Button color="red" variant="light" onClick={confirmDelete.open}>
            Delete
          </Button>
        </Group>
      </Group>

      <Card withBorder>
        <SimpleGrid cols={{ base: 1, sm: 3 }}>
          {details.map(([label, value]) => (
            <div key={label}>
              <Text size="xs" c="dimmed">{label}</Text>
              <Text>{value}</Text>
            </div>
          ))}
        </SimpleGrid>
      </Card>

      <Title order={4}>Salary history</Title>
      {employee.salary_changes?.length ? (
        <Table>
          <Table.Thead>
            <Table.Tr>
              <Table.Th>Changed on</Table.Th>
              <Table.Th ta="right">From</Table.Th>
              <Table.Th ta="right">To</Table.Th>
              <Table.Th ta="right">Change</Table.Th>
            </Table.Tr>
          </Table.Thead>
          <Table.Tbody>
            {employee.salary_changes.map((change) => (
              <Table.Tr key={change.created_at}>
                <Table.Td>{new Date(change.created_at).toLocaleString()}</Table.Td>
                <Table.Td ta="right">{formatMoney(change.old_salary, change.old_currency)}</Table.Td>
                <Table.Td ta="right">{formatMoney(change.new_salary, change.new_currency)}</Table.Td>
                <Table.Td ta="right">{describeChange(change)}</Table.Td>
              </Table.Tr>
            ))}
          </Table.Tbody>
        </Table>
      ) : (
        <Text c="dimmed">No salary changes recorded yet.</Text>
      )}

      <Modal opened={editOpened} onClose={edit.close} title="Edit employee" size="lg">
        {options && (
          <EmployeeForm
            options={options}
            initialValues={toInput(employee)}
            submitLabel="Save changes"
            onSubmit={(values) => updateEmployee.mutateAsync(values)}
            onCancel={edit.close}
          />
        )}
      </Modal>

      <Modal opened={deleteOpened} onClose={confirmDelete.close} title="Delete employee">
        <Text>Delete {employee.full_name}? This also removes their salary history.</Text>
        <Group justify="flex-end" mt="lg">
          <Button variant="default" onClick={confirmDelete.close}>
            Cancel
          </Button>
          <Button color="red" loading={deleteEmployee.isPending} onClick={() => deleteEmployee.mutate()}>
            Delete
          </Button>
        </Group>
      </Modal>
    </Stack>
  )
}
