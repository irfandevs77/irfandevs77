const { spawnSync } = require('node:child_process');
const fs = require('node:fs');
const path = require('node:path');
const yazl = require('yazl');

const projectRoot = path.resolve(__dirname, '..');
const apkSource = path.join(projectRoot, 'Synora', 'apks');
const webOutput = path.join(projectRoot, 'build', 'web');
const apkOutput = path.join(webOutput, 'Synora', 'apks');

if (!process.argv.includes('--skip-build')) {
  const isWindows = process.platform === 'win32';
  const build = spawnSync(
    isWindows ? process.env.ComSpec || 'cmd.exe' : 'flutter',
    isWindows
      ? ['/d', '/s', '/c', 'flutter build web --release --no-pub']
      : ['build', 'web', '--release', '--no-pub'],
    { cwd: projectRoot, stdio: 'inherit' },
  );

  if (build.error) {
    throw build.error;
  }
  if (build.status !== 0) {
    process.exit(build.status ?? 1);
  }
}

if (!fs.existsSync(apkSource)) {
  throw new Error(`Synora APK folder does not exist: ${apkSource}`);
}
if (!fs.existsSync(webOutput)) {
  throw new Error(`Flutter web build output does not exist: ${webOutput}`);
}

async function createZip(source, destination, apkName) {
  await new Promise((resolve, reject) => {
    const archive = new yazl.ZipFile();
    const output = fs.createWriteStream(destination);
    archive.outputStream.on('error', reject);
    output.on('error', reject);
    output.on('close', resolve);
    archive.addFile(source, apkName, { compress: false });
    archive.end();
    archive.outputStream.pipe(output);
  });
}

async function syncApks() {
  fs.mkdirSync(apkOutput, { recursive: true });

  const apkFiles = [];
  for (const entry of fs.readdirSync(apkSource, { withFileTypes: true })) {
    if (!entry.isFile() || path.extname(entry.name).toLowerCase() !== '.apk') {
      continue;
    }
    if (
      !/^[A-Za-z0-9][A-Za-z0-9._ -]*\.apk$/i.test(entry.name) ||
      entry.name.includes('..')
    ) {
      throw new Error(`Unsupported APK filename: ${entry.name}`);
    }
    const source = path.join(apkSource, entry.name);
    const details = fs.statSync(source);
    const fileBase = path.basename(entry.name, path.extname(entry.name));
    const zipFileName = `${fileBase}.zip`;
    const zipPath = path.join(apkOutput, zipFileName);
    await createZip(source, zipPath, entry.name);
    const version = fileBase.replace(/^synora[-_ ]?v?/i, '');
    apkFiles.push({
      fileName: zipFileName,
      apkFileName: entry.name,
      version,
      sizeBytes: details.size,
      downloadBytes: fs.statSync(zipPath).size,
      updatedAt: details.mtime.toISOString(),
    });
  }
  apkFiles.sort((left, right) => right.updatedAt.localeCompare(left.updatedAt));

  const activeFiles = new Set(apkFiles.map((apk) => apk.fileName));
  for (const entry of fs.readdirSync(apkOutput, { withFileTypes: true })) {
    if (
      entry.isFile() &&
      ['.apk', '.zip'].includes(path.extname(entry.name).toLowerCase()) &&
      !activeFiles.has(entry.name)
    ) {
      fs.unlinkSync(path.join(apkOutput, entry.name));
    }
  }

  fs.writeFileSync(
    path.join(apkOutput, 'versions.json'),
    `${JSON.stringify(apkFiles, null, 2)}\n`,
  );
  console.log(
    `Packaged ${apkFiles.length} Synora APK version(s) for Firebase Hosting.`,
  );
}

syncApks().catch((error) => {
  console.error('Could not package Synora APK releases:', error);
  process.exitCode = 1;
});
