'use strict';

import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';

const APPS_DIR = 'apps';

/**
 * 言語ごとのテスト設定
 */
const LANGUAGES = {
  clojure: {
    shell: 'clojure',
    testCmd: 'clj -M:spec',
  },
  elixir: {
    shell: 'elixir',
    testCmd: 'mix deps.get && mix test',
  },
  fsharp: {
    shell: 'fsharp',
    testCmd: 'dotnet test',
  },
  haskell: {
    shell: 'haskell',
    testCmd: 'cabal update && cabal test',
  },
  rust: {
    shell: 'rust',
    testCmd: 'cargo test',
  },
  scala: {
    shell: 'scala',
    testCmd: 'sbt test',
  },
};

/**
 * Nix が利用可能か確認する
 * @returns {boolean}
 */
function isNixAvailable() {
  try {
    execSync('nix --version', { stdio: 'ignore' });
    return true;
  } catch {
    return false;
  }
}

/**
 * 指定言語の part ディレクトリ一覧を取得する
 * @param {string} lang - 言語名
 * @returns {string[]} part ディレクトリ名の配列（ソート済み）
 */
function getParts(lang) {
  const langDir = path.join(process.cwd(), APPS_DIR, lang);
  if (!fs.existsSync(langDir)) return [];
  return fs.readdirSync(langDir)
    .filter((d) => d.startsWith('part') && fs.statSync(path.join(langDir, d)).isDirectory())
    .sort();
}

/**
 * 指定言語・Part のテストを実行する
 * @param {string} lang - 言語名
 * @param {string} part - Part ディレクトリ名
 */
function runTest(lang, part) {
  const config = LANGUAGES[lang];
  const dir = `${APPS_DIR}/${lang}/${part}`;
  const cmd = `nix develop .#${config.shell} --command bash -c "cd ${dir} && ${config.testCmd}"`;
  console.log(`\n--- ${lang} ${part} ---`);
  execSync(cmd, { stdio: 'inherit' });
}

/**
 * 指定言語の全 Part テストを実行する
 * @param {string} lang - 言語名
 */
function runLanguageTests(lang) {
  const parts = getParts(lang);
  if (parts.length === 0) {
    console.log(`No parts found for ${lang}`);
    return;
  }
  console.log(`\n=== ${lang.toUpperCase()} Tests ===`);
  for (const part of parts) {
    runTest(lang, part);
  }
}

/**
 * テストタスクを gulp に登録する
 * @param {import('gulp').Gulp} gulp - Gulp インスタンス
 */
export default function (gulp) {
  // 言語別テストタスク
  for (const lang of Object.keys(LANGUAGES)) {
    gulp.task(`test:${lang}`, (done) => {
      if (!isNixAvailable()) {
        console.warn('Warning: Nix is not available. Skipping tests.');
        console.warn('Install Nix: https://nixos.org/download.html');
        done();
        return;
      }
      try {
        runLanguageTests(lang);
        done();
      } catch (error) {
        done(error);
      }
    });
  }

  // 全言語テストタスク
  gulp.task(
    'test',
    gulp.series(...Object.keys(LANGUAGES).map((lang) => `test:${lang}`))
  );
}
