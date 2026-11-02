import { Autocomplete, Button, Group, NumberInput, Select, SimpleGrid, TextInput } from '@mantine/core'
import { useForm } from '@mantine/form'
import { useState } from 'react'
import { ApiError, type EmployeeInput, type EmployeeOptions } from '../api'
import { formatEmploymentType } from '../format'

const emptyEmployee: EmployeeInput = {
  full_name: '',
  email: '',
  job_title: '',
  department: '',
  country: '',
  salary: 0,
  employment_type: 'full_time',
  hire_date: '',
}

interface Props {
  options: EmployeeOptions
  initialValues?: EmployeeInput
  submitLabel: string
  onSubmit: (values: EmployeeInput) => Promise<unknown>
  onCancel: () => void
}

const required = (label: string) => (value: string) => (value.trim() ? null : `${label} is required`)

export function EmployeeForm({ options, initialValues = emptyEmployee, submitLabel, onSubmit, onCancel }: Props) {
  const [saving, setSaving] = useState(false)
  const form = useForm<EmployeeInput>({
    initialValues,
    validate: {
      full_name: required('Full name'),
      email: (value) => (/^\S+@\S+\.\S+$/.test(value) ? null : 'Enter a valid email'),
      job_title: required('Job title'),
      department: required('Department'),
      country: (value) => (value ? null : 'Country is required'),
      salary: (value) => (value > 0 ? null : 'Salary must be greater than 0'),
      hire_date: (value) => (value ? null : 'Hire date is required'),
    },
  })

  const handleSubmit = async (values: EmployeeInput) => {
    setSaving(true)
    try {
      await onSubmit(values)
    } catch (error) {
      if (error instanceof ApiError) {
        form.setErrors(Object.fromEntries(Object.entries(error.errors).map(([field, messages]) => [field, messages[0]])))
      } else {
        throw error
      }
    } finally {
      setSaving(false)
    }
  }

  return (
    <form onSubmit={form.onSubmit(handleSubmit)}>
      <SimpleGrid cols={{ base: 1, sm: 2 }}>
        <TextInput label="Full name" withAsterisk {...form.getInputProps('full_name')} />
        <TextInput label="Email" withAsterisk {...form.getInputProps('email')} />
        <Autocomplete label="Job title" withAsterisk data={options.job_titles} {...form.getInputProps('job_title')} />
        <Autocomplete label="Department" withAsterisk data={options.departments} {...form.getInputProps('department')} />
        <Select label="Country" withAsterisk searchable data={options.countries} {...form.getInputProps('country')} />
        <NumberInput label="Annual salary (local currency)" withAsterisk min={0} thousandSeparator="," {...form.getInputProps('salary')} />
        <Select
          label="Employment type"
          data={options.employment_types.map((type) => ({ value: type, label: formatEmploymentType(type) }))}
          allowDeselect={false}
          {...form.getInputProps('employment_type')}
        />
        <TextInput label="Hire date" type="date" withAsterisk {...form.getInputProps('hire_date')} />
      </SimpleGrid>
      <Group justify="flex-end" mt="lg">
        <Button variant="default" onClick={onCancel}>
          Cancel
        </Button>
        <Button type="submit" loading={saving}>
          {submitLabel}
        </Button>
      </Group>
    </form>
  )
}
