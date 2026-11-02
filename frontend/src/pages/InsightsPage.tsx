import { Card, Group, Select, SimpleGrid, Stack, Table, Tabs, Text, Title } from '@mantine/core'
import { useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { api, type SalaryStats, type UsdTotal } from '../api'
import { formatMoney } from '../format'

function StatsTable({ rows, groupLabel }: { rows: SalaryStats[]; groupLabel: string }) {
  return (
    <Table striped>
      <Table.Thead>
        <Table.Tr>
          <Table.Th>{groupLabel}</Table.Th>
          <Table.Th ta="right">Headcount</Table.Th>
          <Table.Th ta="right">Min</Table.Th>
          <Table.Th ta="right">Median</Table.Th>
          <Table.Th ta="right">Average</Table.Th>
          <Table.Th ta="right">Max</Table.Th>
        </Table.Tr>
      </Table.Thead>
      <Table.Tbody>
        {rows.map((row) => (
          <Table.Tr key={row.group}>
            <Table.Td>{row.group}</Table.Td>
            <Table.Td ta="right">{row.headcount.toLocaleString()}</Table.Td>
            <Table.Td ta="right">{formatMoney(row.min, row.currency)}</Table.Td>
            <Table.Td ta="right">{formatMoney(row.median, row.currency)}</Table.Td>
            <Table.Td ta="right">{formatMoney(row.average, row.currency)}</Table.Td>
            <Table.Td ta="right">{formatMoney(row.max, row.currency)}</Table.Td>
          </Table.Tr>
        ))}
      </Table.Tbody>
    </Table>
  )
}

function UsdTable({ rows, groupLabel }: { rows: UsdTotal[]; groupLabel: string }) {
  return (
    <Table striped>
      <Table.Thead>
        <Table.Tr>
          <Table.Th>{groupLabel}</Table.Th>
          <Table.Th ta="right">Headcount</Table.Th>
          <Table.Th ta="right">Payroll (USD)</Table.Th>
          <Table.Th ta="right">Average (USD)</Table.Th>
        </Table.Tr>
      </Table.Thead>
      <Table.Tbody>
        {rows.map((row) => (
          <Table.Tr key={row.group}>
            <Table.Td>{row.group}</Table.Td>
            <Table.Td ta="right">{row.headcount.toLocaleString()}</Table.Td>
            <Table.Td ta="right">{formatMoney(row.payroll_usd, 'USD')}</Table.Td>
            <Table.Td ta="right">{formatMoney(row.average_usd, 'USD')}</Table.Td>
          </Table.Tr>
        ))}
      </Table.Tbody>
    </Table>
  )
}

function Stat({ label, value }: { label: string; value: string }) {
  return (
    <Card withBorder>
      <Text size="xs" c="dimmed">{label}</Text>
      <Text fz="xl" fw={700}>{value}</Text>
    </Card>
  )
}

export function InsightsPage() {
  const [country, setCountry] = useState<string | null>(null)
  const { data: countryStats } = useQuery({ queryKey: ['insights', 'countries'], queryFn: api.countryStats })
  const { data: overview } = useQuery({ queryKey: ['insights', 'overview'], queryFn: api.overview })
  const { data: jobStats } = useQuery({
    queryKey: ['insights', 'job_titles', country],
    queryFn: () => api.jobTitleStats(country!),
    enabled: !!country,
  })

  return (
    <Stack>
      <Title order={2}>Insights</Title>

      {overview && (
        <SimpleGrid cols={{ base: 1, sm: 3 }}>
          <Stat label="Employees" value={overview.headcount.toLocaleString()} />
          <Stat label="Annual payroll (USD)" value={formatMoney(overview.payroll_usd, 'USD')} />
          <Stat
            label="Average salary (USD)"
            value={formatMoney(overview.headcount ? overview.payroll_usd / overview.headcount : 0, 'USD')}
          />
        </SimpleGrid>
      )}

      <Tabs defaultValue="countries">
        <Tabs.List>
          <Tabs.Tab value="countries">By country</Tabs.Tab>
          <Tabs.Tab value="job_titles">By job title</Tabs.Tab>
          <Tabs.Tab value="overview">Org overview (USD)</Tabs.Tab>
        </Tabs.List>

        <Tabs.Panel value="countries" pt="md">
          <Text size="sm" c="dimmed" mb="sm">Salaries in each country's local currency.</Text>
          {countryStats && <StatsTable rows={countryStats} groupLabel="Country" />}
        </Tabs.Panel>

        <Tabs.Panel value="job_titles" pt="md">
          <Group mb="sm">
            <Select placeholder="Choose a country" aria-label="Country for job titles" searchable
              data={countryStats?.map((row) => row.group) ?? []} value={country} onChange={setCountry} />
          </Group>
          {jobStats ? (
            <StatsTable rows={jobStats} groupLabel="Job title" />
          ) : (
            <Text c="dimmed">Pick a country to compare pay by job title.</Text>
          )}
        </Tabs.Panel>

        <Tabs.Panel value="overview" pt="md">
          <Text size="sm" c="dimmed" mb="sm">Converted to USD using the stored exchange rates.</Text>
          {overview && (
            <SimpleGrid cols={{ base: 1, lg: 2 }}>
              <UsdTable rows={overview.by_country} groupLabel="Country" />
              <UsdTable rows={overview.by_department} groupLabel="Department" />
            </SimpleGrid>
          )}
        </Tabs.Panel>
      </Tabs>
    </Stack>
  )
}
