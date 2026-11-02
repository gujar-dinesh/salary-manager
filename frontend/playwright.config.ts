import { defineConfig, devices } from '@playwright/test'

const API_PORT = 3100
const WEB_PORT = 5180
// Set E2E_BASE_URL to test an already running app (e.g. the Docker container) instead of starting servers.
const externalBaseUrl = process.env.E2E_BASE_URL

export default defineConfig({
  testDir: './e2e',
  fullyParallel: false,
  workers: 1,
  retries: process.env.CI ? 1 : 0,
  reporter: 'list',
  use: {
    baseURL: externalBaseUrl ?? `http://localhost:${WEB_PORT}`,
    trace: 'retain-on-failure',
  },
  projects: [{ name: 'chromium', use: { ...devices['Desktop Chrome'] } }],
  webServer: externalBaseUrl ? undefined : [
    {
      command: `bin/rails db:prepare db:seed && bin/rails server -p ${API_PORT} -P tmp/pids/e2e.pid`,
      cwd: '../backend',
      env: { DATABASE_NAME: 'salary_manager_e2e' },
      url: `http://localhost:${API_PORT}/up`,
      timeout: 120_000,
    },
    {
      command: `npx vite --port ${WEB_PORT} --strictPort`,
      env: { API_URL: `http://localhost:${API_PORT}` },
      url: `http://localhost:${WEB_PORT}`,
    },
  ],
})
