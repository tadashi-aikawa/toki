import { defineConfig, devices } from "@playwright/test";

/**
 * See https://playwright.dev/docs/test-configuration.
 */
export default defineConfig({
  testDir: "./tests",
  reporter: "html",

  // 全体でシーケンシャル(更新系があるため)
  fullyParallel: false,
  // ファイル内もシーケンシャル(更新系があるため)
  workers: 1,
  // リトライはしない(データに冪等性がなければテストできないから)
  retries: 0,
  // test.onlyやdescribe.onlyが残っていたときCIでエラーを吐く(消し忘れ防止)
  forbidOnly: !!process.env.CI,

  projects: [
    {
      // 付属Chromiumではなく手元のGoogle Chromeを使う(付属Chromiumは脆弱性修正の反映が遅れる)
      name: "chrome",
      use: { ...devices["Desktop Chrome"], channel: "chrome" },
    },
  ],
});
