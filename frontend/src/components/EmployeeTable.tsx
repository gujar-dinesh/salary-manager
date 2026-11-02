import { Anchor, Table, Text, UnstyledButton } from '@mantine/core'
import { Link } from 'react-router-dom'
import type { Employee } from '../api'
import { formatMoney } from '../format'
import type { SortColumn } from '../hooks/useEmployeeFilters'

interface Props {
  employees: Employee[]
  sort: SortColumn
  direction: string
  onSort: (column: SortColumn) => void
}

export function EmployeeTable({ employees, sort, direction, onSort }: Props) {
  const sortHeader = (column: SortColumn, label: string) => (
    <UnstyledButton fw={700} fz="sm" onClick={() => onSort(column)}>
      {label} {sort === column ? (direction === 'asc' ? '▲' : '▼') : ''}
    </UnstyledButton>
  )

  return (
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
        {employees.map((employee) => (
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
  )
}
