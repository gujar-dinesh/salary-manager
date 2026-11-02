import { defineConfig } from '@playwright/test'

// Records the narrated walkthrough. Run through demo/make-video.sh, which starts a fresh app first.
export default defineConfig({
  testDir: '.',
  testMatch: 'walkthrough.ts',
  timeout: 10 * 60_000,
  workers: 1,
  reporter: 'list',
  outputDir: './output/playwright',
  use: {
    baseURL: process.env.DEMO_BASE_URL ?? 'http://localhost:8082',
    actionTimeout: 15_000,
    viewport: { width: 1280, height: 720 },
    video: { mode: 'on', size: { width: 1280, height: 720 } },
  },
})
