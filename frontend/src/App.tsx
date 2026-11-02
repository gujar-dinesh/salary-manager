import { AppShell, Group, NavLink, Title } from '@mantine/core'
import { NavLink as RouterNavLink, Route, Routes } from 'react-router-dom'
import { EmployeeDetailPage } from './pages/EmployeeDetailPage'
import { EmployeesPage } from './pages/EmployeesPage'
import { InsightsPage } from './pages/InsightsPage'

export default function App() {
  return (
    <AppShell header={{ height: 56 }} navbar={{ width: 200, breakpoint: 'sm' }} padding="lg">
      <AppShell.Header>
        <Group h="100%" px="lg">
          <Title order={3}>Salary Manager</Title>
        </Group>
      </AppShell.Header>
      <AppShell.Navbar p="sm">
        <NavLink component={RouterNavLink} to="/" end label="Employees" />
        <NavLink component={RouterNavLink} to="/insights" label="Insights" />
      </AppShell.Navbar>
      <AppShell.Main>
        <Routes>
          <Route path="/" element={<EmployeesPage />} />
          <Route path="/employees/:id" element={<EmployeeDetailPage />} />
          <Route path="/insights" element={<InsightsPage />} />
        </Routes>
      </AppShell.Main>
    </AppShell>
  )
}
